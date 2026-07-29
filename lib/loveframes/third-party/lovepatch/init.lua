--[[
  ninepatch.lua — 9-Patch (9-slice) image rendering for LÖVE2D
  -------------------------------------------------------------

  API
  ----
  local NinePatch = require("ninepatch")

  NinePatch.new(image, borders)                    -- 2 args: mesma borda em tudo
  NinePatch.new(image, leftRight, topBottom)        -- 3 args: horizontal / vertical
  NinePatch.new(image, left, right, top, bottom)    -- 5 args: cada borda individual

  `image` pode ser uma string (caminho) ou um love.graphics.Image já carregado.

  np:drawStretch(x, y, w, h)     -- desenha esticando as bordas/meio
  np:drawTiled(x, y, w, h)       -- desenha repetindo (tile) as bordas/meio
  np:draw(x, y, w, h, mode)      -- mode = "stretch" (padrão) ou "tile"/"repeat"

  Regras implementadas
  ---------------------
  * Os CANTOS nunca são escalados. Eles são sempre desenhados em escala 1:1
    (um pixel da imagem = um pixel na tela).
  * Se o retângulo de destino for menor que a soma dos cantos numa dada
    dimensão, os cantos são "cortados" (não escalados) de dentro pra fora:
    o pixel colado na quina real do retângulo nunca some, o que é cortado é
    sempre a parte voltada para o centro. Isso garante que os dois cantos
    de um mesmo eixo se encontrem de forma perfeita, sem sobreposição.
  * As bordas (topo/baixo/esquerda/direita) têm seu eixo curto (a espessura)
    sujeito à mesma regra de corte dos cantos (elas estão na mesma
    "linha"/"coluna" que os cantos). O eixo longo é o único que pode ser
    esticado (modo stretch) ou repetido (modo tile).
  * Se não sobrar espaço na dimensão perpendicular às bordas (ex.: largura
    <= esquerda+direita), essas bordas não são desenhadas.
  * Se não sobrar espaço para o meio (miolo) em qualquer um dos dois eixos,
    o miolo não é desenhado.

  Sobre o corte dos cantos (por que não usamos scissor/stencil)
  ---------------------------------------------------------------
  Como os cantos NUNCA são escalados, "cortar" um canto é equivalente a
  amostrar uma sub-região menor da imagem original (um love.graphics.Quad
  com viewport reduzido), desenhada 1:1. Isso dá exatamente o mesmo
  resultado visual de um scissor/stencil, só que:
    - não exige calcular a transformação corrente para coordenadas de tela
      (scissor em LÖVE não é afetado pela CTM, então teria que ser
      convertido manualmente);
    - funciona nativamente dentro de um SpriteBatch (todas as peças, mesmo
      cortadas, continuam sendo um único "add" no batch, então tudo sai
      num único draw call).
  Por isso a técnica usada aqui é: ajustar o viewport do Quad por peça.

  Eficiência
  -----------
  Cada NinePatch mantém seu próprio love.graphics.SpriteBatch. A cada
  chamada de draw, o batch é limpo e as peças visíveis (cantos, bordas,
  miolo) são adicionadas a ele; o desenho real na tela é um único
  love.graphics.draw(batch) — uma única draw call/bind de textura,
  independente de quantas peças (inclusive quantos tiles) existam.
]]

local NinePatch = {}
NinePatch.__index = NinePatch

--------------------------------------------------------------------------
-- Parsing dos argumentos do construtor
--------------------------------------------------------------------------

local function parseArgs(...)
	local n = select("#", ...)
	local image = (...)
	local l, r, t, b

	if n == 2 then
		-- (image, borders)
		local border = select(2, ...)
		l, r, t, b = border, border, border, border
	elseif n == 3 then
		-- (image, leftRight, topBottom)
		local lr, tb = select(2, ...), select(3, ...)
		l, r, t, b = lr, lr, tb, tb
	elseif n == 5 then
		-- (image, left, right, top, bottom)
		l, r, t, b = select(2, ...), select(3, ...), select(4, ...), select(5, ...)
	else
		error(("NinePatch.new: número de argumentos inválido (%d). Use:\n"
			.. "  NinePatch.new(image, borders)\n"
			.. "  NinePatch.new(image, leftRight, topBottom)\n"
			.. "  NinePatch.new(image, left, right, top, bottom)"):format(n), 3)
	end

	assert(type(l) == "number" and type(r) == "number"
		and type(t) == "number" and type(b) == "number",
		"NinePatch.new: os valores de borda precisam ser números")

	return image, l, r, t, b
end

--------------------------------------------------------------------------
-- Construtor
--------------------------------------------------------------------------

function NinePatch.new(...)
	local image, l, r, t, b = parseArgs(...)

	if type(image) == "string" then
		image = love.graphics.newImage(image)
	end
	assert(image ~= nil and image.getDimensions ~= nil,
		"NinePatch.new: 'image' precisa ser um caminho (string) ou um love.graphics.Image")

	local iw, ih = image:getDimensions()

	-- limita as bordas ao tamanho da imagem para evitar viewports inválidos
	l = math.max(0, math.min(l, iw))
	r = math.max(0, math.min(r, iw))
	t = math.max(0, math.min(t, ih))
	b = math.max(0, math.min(b, ih))

	local self = setmetatable({}, NinePatch)
	self.image = image
	self.iw, self.ih = iw, ih
	self.left, self.right, self.top, self.bottom = l, r, t, b

	-- tamanho nativo (na imagem) do miolo, em cada eixo
	self.midWOrig = math.max(0, iw - l - r)
	self.midHOrig = math.max(0, ih - t - b)

	-- Quad único e reutilizável: seu viewport é reescrito antes de cada
	-- "add" no batch (o batch já copia os dados de UV no momento do add,
	-- então é seguro mudar o viewport em seguida para a próxima peça).
	self.quad = love.graphics.newQuad(0, 0, iw, ih, iw, ih)

	-- SpriteBatch próprio desta instância. Começa com uma capacidade
	-- pequena e cresce sob demanda (ver _ensureCapacity).
	self.batchCapacity = 16
	self.batch = love.graphics.newSpriteBatch(image, self.batchCapacity, "stream")

	return self
end

--------------------------------------------------------------------------
-- Helpers internos
--------------------------------------------------------------------------

-- Dado o tamanho total disponível `size` num eixo, e os dois cantos desse
-- eixo (`a` = esquerda/topo, `b` = direita/baixo), devolve os tamanhos de
-- canto REALMENTE desenhados. Se houver espaço (size >= a+b), os cantos
-- saem no tamanho nativo. Caso contrário, são cortados proporcionalmente
-- (corte "de dentro pra fora": o lado colado na quina do retângulo nunca
-- é afetado, o que encolhe é sempre o lado voltado ao centro).
local function computeAxis(size, a, b)
	local sum = a + b
	if sum > 0 and size < sum then
		local ca = size * (a / sum)
		local cb = size - ca
		return ca, cb
	end
	return a, b
end

function NinePatch:_layout(w, h)
	local cl, cr = computeAxis(w, self.left, self.right)
	local ct, cb = computeAxis(h, self.top, self.bottom)
	local midW = math.max(0, w - cl - cr)
	local midH = math.max(0, h - ct - cb)
	return cl, cr, ct, cb, midW, midH
end

-- Garante que o SpriteBatch tenha capacidade para pelo menos `n` sprites.
function NinePatch:_ensureCapacity(n)
	if n > self.batchCapacity then
		local newCap = math.max(n, self.batchCapacity * 2)
		--self.batch:setBufferSize(newCap)
		self.batchCapacity = newCap
	end
end

-- Adiciona uma peça ao batch: `sx,sy,sw,sh` é a região de origem (na
-- imagem), `dx,dy,dw,dh` é onde/tamanho que ela deve ocupar no destino.
-- Quando dw == sw (e dh == sh) o desenho sai em escala 1:1 (usado pelos
-- cantos e pelo eixo curto das bordas). Quando dw/dh diferem de sw/sh,
-- o resultado é esticado (usado no modo stretch para o eixo longo das
-- bordas e para o miolo).
function NinePatch:_addPiece(sx, sy, sw, sh, dx, dy, dw, dh)
	if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0 then return end
	self.quad:setViewport(sx, sy, sw, sh, self.iw, self.ih)
	local scaleX = dw / sw
	local scaleY = dh / sh
	self.batch:add(self.quad, dx, dy, 0, scaleX, scaleY)
end

-- Repete (tile) uma tira 1D (borda) preenchendo `dw` (se horizontal) ou
-- `dh` (se vertical) com cópias de tamanho nativo `sw`x`sh`; a última
-- cópia é cortada (não espremida) para caber no espaço restante.
function NinePatch:_addTiledStrip(sx, sy, sw, sh, dx, dy, dw, dh, horizontal)
	if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0 then return end

	if horizontal then
		local tile = sw
		local count = math.floor(dw / tile)
		local rest = dw - count * tile
		local px = dx
		for _ = 1, count do
			self:_addPiece(sx, sy, sw, sh, px, dy, sw, sh)
			px = px + sw
		end
		if rest > 0.001 then
			self:_addPiece(sx, sy, rest, sh, px, dy, rest, sh)
		end
	else
		local tile = sh
		local count = math.floor(dh / tile)
		local rest = dh - count * tile
		local py = dy
		for _ = 1, count do
			self:_addPiece(sx, sy, sw, sh, dx, py, sw, sh)
			py = py + sh
		end
		if rest > 0.001 then
			self:_addPiece(sx, sy, sw, rest, dx, py, sw, rest)
		end
	end
end

-- Repete (tile) o miolo nas duas dimensões; a última coluna e a última
-- linha (e o canto delas) são cortadas para caber no espaço restante.
function NinePatch:_addTiledCenter(sx, sy, sw, sh, dx, dy, dw, dh)
	if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0 then return end

	local nx = math.floor(dw / sw)
	local remX = dw - nx * sw
	local ny = math.floor(dh / sh)
	local remY = dh - ny * sh

	local py = dy
	for _ = 1, ny do
		local px = dx
		for _ = 1, nx do
			self:_addPiece(sx, sy, sw, sh, px, py, sw, sh)
			px = px + sw
		end
		if remX > 0.001 then
			self:_addPiece(sx, sy, remX, sh, px, py, remX, sh)
		end
		py = py + sh
	end
	if remY > 0.001 then
		local px = dx
		for _ = 1, nx do
			self:_addPiece(sx, sy, sw, remY, px, py, sw, remY)
			px = px + sw
		end
		if remX > 0.001 then
			self:_addPiece(sx, sy, remX, remY, px, py, remX, remY)
		end
	end
end

--------------------------------------------------------------------------
-- Estimativa de quantas peças serão necessárias (para dimensionar o
-- batch antes de preenchê-lo, evitando realocações no meio do processo)
--------------------------------------------------------------------------

local function tileCount(len, tile)
	if tile <= 0 or len <= 0 then return 0 end
	return math.ceil(len / tile)
end

--------------------------------------------------------------------------
-- Desenho: modo "stretch" (esticando bordas e miolo)
--------------------------------------------------------------------------

function NinePatch:drawStretch(x, y, w, h)
	x, y = x or 0, y or 0
	w, h = w or self.iw, h or self.ih
	if w <= 0 or h <= 0 then return end

	local iw, ih = self.iw, self.ih
	local l, r, t, b = self.left, self.right, self.top, self.bottom
	local cl, cr, ct, cb, midW, midH = self:_layout(w, h)

	self:_ensureCapacity(9) -- 4 cantos + 4 bordas + 1 miolo, no máximo
	self.batch:clear()

	-- cantos: nunca escalados; cortados (viewport menor) quando necessário
	self:_addPiece(0, 0, cl, ct, x, y, cl, ct)                            -- topo-esquerda
	self:_addPiece(iw - cr, 0, cr, ct, x + w - cr, y, cr, ct)             -- topo-direita
	self:_addPiece(0, ih - cb, cl, cb, x, y + h - cb, cl, cb)             -- baixo-esquerda
	self:_addPiece(iw - cr, ih - cb, cr, cb, x + w - cr, y + h - cb, cr, cb) -- baixo-direita

	-- bordas horizontais (topo/baixo): eixo curto cortado, eixo longo esticado
	if midW > 0 then
		self:_addPiece(l, 0, self.midWOrig, ct, x + cl, y, midW, ct)
		self:_addPiece(l, ih - cb, self.midWOrig, cb, x + cl, y + h - cb, midW, cb)
	end

	-- bordas verticais (esquerda/direita): eixo curto cortado, eixo longo esticado
	if midH > 0 then
		self:_addPiece(0, t, cl, self.midHOrig, x, y + ct, cl, midH)
		self:_addPiece(iw - cr, t, cr, self.midHOrig, x + w - cr, y + ct, cr, midH)
	end

	-- miolo: só desenhado se sobrar espaço nos dois eixos
	if midW > 0 and midH > 0 then
		self:_addPiece(l, t, self.midWOrig, self.midHOrig, x + cl, y + ct, midW, midH)
	end

	love.graphics.draw(self.batch)
end

--------------------------------------------------------------------------
-- Desenho: modo "tile" (repetindo bordas e miolo)
--------------------------------------------------------------------------

function NinePatch:drawTiled(x, y, w, h)
	x, y = x or 0, y or 0
	w, h = w or self.iw, h or self.ih
	if w <= 0 or h <= 0 then return end

	local iw, ih = self.iw, self.ih
	local l, r, t, b = self.left, self.right, self.top, self.bottom
	local cl, cr, ct, cb, midW, midH = self:_layout(w, h)

	-- estima a quantidade de peças para dimensionar o batch de uma vez
	local hTiles = (midW > 0) and tileCount(midW, self.midWOrig) or 0
	local vTiles = (midH > 0) and tileCount(midH, self.midHOrig) or 0
	local needed = 4                                 -- cantos
		+ (midW > 0 and 2 * hTiles or 0)             -- borda topo + baixo
		+ (midH > 0 and 2 * vTiles or 0)             -- borda esquerda + direita
		+ (midW > 0 and midH > 0 and hTiles * vTiles or 0) -- miolo
	self:_ensureCapacity(math.max(9, needed))

	self.batch:clear()

	-- cantos: idêntico ao modo stretch — nunca escalam nem repetem
	self:_addPiece(0, 0, cl, ct, x, y, cl, ct)
	self:_addPiece(iw - cr, 0, cr, ct, x + w - cr, y, cr, ct)
	self:_addPiece(0, ih - cb, cl, cb, x, y + h - cb, cl, cb)
	self:_addPiece(iw - cr, ih - cb, cr, cb, x + w - cr, y + h - cb, cr, cb)

	-- bordas horizontais: eixo curto cortado, eixo longo repetido (tile)
	if midW > 0 and self.midWOrig > 0 then
		self:_addTiledStrip(l, 0, self.midWOrig, ct, x + cl, y, midW, ct, true)
		self:_addTiledStrip(l, ih - cb, self.midWOrig, cb, x + cl, y + h - cb, midW, cb, true)
	end

	-- bordas verticais: eixo curto cortado, eixo longo repetido (tile)
	if midH > 0 and self.midHOrig > 0 then
		self:_addTiledStrip(0, t, cl, self.midHOrig, x, y + ct, cl, midH, false)
		self:_addTiledStrip(iw - cr, t, cr, self.midHOrig, x + w - cr, y + ct, cr, midH, false)
	end

	-- miolo: repetido nos dois eixos, cortado nas bordas do ladrilhamento
	if midW > 0 and midH > 0 and self.midWOrig > 0 and self.midHOrig > 0 then
		self:_addTiledCenter(l, t, self.midWOrig, self.midHOrig, x + cl, y + ct, midW, midH)
	end

	love.graphics.draw(self.batch)
end

--------------------------------------------------------------------------
-- Desenho genérico
--------------------------------------------------------------------------

-- mode: "stretch" (padrão) ou "tile"/"repeat"
function NinePatch:draw(x, y, w, h, mode)
	if mode == "tile" or mode == "repeat" then
		return self:drawTiled(x, y, w, h)
	end
	return self:drawStretch(x, y, w, h)
end

--------------------------------------------------------------------------
-- Acessores utilitários
--------------------------------------------------------------------------

function NinePatch:getImage()
	return self.image
end

function NinePatch:getBorders()
	return self.left, self.right, self.top, self.bottom
end

function NinePatch:getImageDimensions()
	return self.iw, self.ih
end

return NinePatch
