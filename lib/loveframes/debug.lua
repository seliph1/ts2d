---@diagnostic disable: duplicate-set-field
--[[--------------------------------------------------------------------------
	LoveFrames - Banco de testes de UI (debug)

	Este arquivo cria uma janela que demonstra TODOS os objetos de UI da
	biblioteca LoveFrames e algumas combinacoes entre eles, organizados em abas.

	Como executar:
	  love . loveframes_debug
	(veja main.lua, que faz `require "lib.loveframes.debug"` quando o modo de
	 programa e "loveframes_debug" e entao retorna, deixando este arquivo dono
	 de todos os callbacks do LOVE).

	Tudo aqui e auto-contido: nenhum asset externo e necessario, as imagens
	usadas pelos objetos baseados em imagem sao geradas em tempo de execucao.
----------------------------------------------------------------------------]]

local loveframes = require "lib.loveframes"

-- Ativa o modo de debug interno da biblioteca (mostra contadores e permite
-- remover objetos com DELETE ao passar o mouse sobre eles).
loveframes.config["DEBUG"] = true

local debug = {}

-- Referencias que precisamos consultar/atualizar a cada frame.
local widgets = {}

--[[--------------------------------------------------------------------------
	Helpers
----------------------------------------------------------------------------]]
local function randomString(size)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local result = {}
	for i = 1, size do
		local index = math.random(1, #chars)
		result[i] = chars:sub(index, index)
	end
	return table.concat(result)
end


-- Gera uma imagem colorida em tempo de execucao para os objetos que precisam
-- de uma (image, imagebutton, imagelink, slideshow), evitando depender de
-- arquivos de asset.
local function makeImage(w, h, r, g, b)
	local data = love.image.newImageData(w, h)
	data:mapPixel(function(x, y)
		-- Uma borda escura + um tabuleiro suave para algo visivel.
		local border = (x < 2 or y < 2 or x >= w - 2 or y >= h - 2)
		local checker = ((math.floor(x / 8) + math.floor(y / 8)) % 2 == 0)
		if border then
			return 0, 0, 0, 1
		elseif checker then
			return r, g, b, 1
		else
			return r * 0.6, g * 0.6, b * 0.6, 1
		end
	end)
	return love.graphics.newImage(data)
end

-- Cria um label simples acima de um objeto, para identificar o que esta sendo
-- demonstrado.
local function caption(parent, x, y, text)
	local lbl = loveframes.Create("label", parent)
	lbl:SetPos(x, y)
	lbl:SetText(text)
	return lbl
end

-- Cria um painel (aba) e ja o registra; retorna o painel para preenchermos.
local function newTabPage(tabs, name)
	local page = loveframes.Create("panel")
	tabs:AddTab(name, page)
	return page
end

-- Imagens compartilhadas (geradas uma vez).
local img = {}
local debug_radios = {}

--[[--------------------------------------------------------------------------
	Aba 1: Botoes e alternaveis
----------------------------------------------------------------------------]]
local function buildButtonsTab(tabs)
	local page = newTabPage(tabs, "Botoes")

	-- textbutton -----------------------------------------------------------
	caption(page, 10, 10, "textbutton")
	local tbtn = loveframes.Create("textbutton", page)
	tbtn:SetPos(10, 30)
	tbtn:SetSize(150, 30)
	tbtn:SetText("Click-me"):SetHoverText("Click-me/Hovered")
	tbtn.OnClick = function(obj)
		widgets.status:SetText("textbutton clicado!")
	end

	-- button (botao basico) -----------------------------------------------
	caption(page, 10, 75, "button")
	local btn = loveframes.Create("button", page)
	btn:SetPos(10, 95)
	btn:SetSize(150, 30)
	btn:SetText("Botao basico")
	btn.OnClick = function(obj)
		widgets.status:SetText("button clicado!")
	end

	-- button toggle --------------------------------------------------------
	caption(page, 10, 140, "button (toggle)")
	local toggle = loveframes.Create("button", page)
	toggle:SetPos(10, 160)
	toggle:SetSize(150, 30)
	toggle:SetText("Toggle: OFF")
	toggle:SetToggleable(true)
	toggle.OnToggle = function(obj, state)
		obj:SetText("Toggle: " .. (state and "ON" or "OFF"))
	end

	-- button disabled ------------------------------------------------------
	caption(page, 10, 200, "button (disabled)")
	local disablebtn = loveframes.Create("button", page)
	disablebtn:SetPos(10, 220)
	disablebtn:SetSize(150, 30)
	disablebtn:SetEnabled(false)
	disablebtn:SetText("Disabled")

	-- textbutton disabled ------------------------------------------------------
	caption(page, 10, 260, "textbutton (disabled)")
	local textdisablebtn = loveframes.Create("textbutton", page)
	textdisablebtn:SetPos(10, 280)
	textdisablebtn:SetSize(150, 30)
	textdisablebtn:SetEnabled(false)
	textdisablebtn:SetText("Disabled"):SetHoverText("Disabled/Hovered")

	-- imagebutton ----------------------------------------------------------
	caption(page, 200, 10, "imagebutton")
	local ibtn = loveframes.Create("imagebutton", page)
	ibtn:SetPos(200, 30)
	ibtn:SetImage(img.blue)
	ibtn:SizeToImage()
	ibtn:SetText("img")
	ibtn.OnClick = function()
		widgets.status:SetText("imagebutton clicado!")
	end

	-- checkbox -------------------------------------------------------------
	caption(page, 200, 110, "checkbox")
	local chk = loveframes.Create("checkbox", page)
	chk:SetPos(200, 130)
	chk:SetText("Habilitar algo")
	chk.OnChanged = function(obj, checked)
		widgets.status:SetText("checkbox: " .. tostring(checked))
	end

	local chk_disabled = loveframes.Create("checkbox", page)
	chk_disabled:SetPos(200, 150)
	chk_disabled:SetText("Desativado")
	chk_disabled:SetEnabled(false)


	-- radiobutton (grupo) --------------------------------------------------
	caption(page, 200, 180, "radiobutton (grupo)")
	for i = 1, 4 do
		local radio = loveframes.Create("radiobutton", page)
		radio:SetPos(200, 180 + i * 22)
		radio:SetText("Opcao " .. i)
		radio:SetGroup(debug_radios)
		if i == 1 then radio:SetChecked(true) end
		radio.OnChanged = function(obj, checked)
			if checked then
				widgets.status:SetText("radio: Opcao " .. i)
			end
		end

		if i==4 then
			radio:SetText("Desativado")
			radio:SetEnabled(false)
		end
	end


	-- multichoice ----------------------------------------------------------
	caption(page, 400, 10, "multichoice"):SetTooltip("Test")
	local mc = loveframes.Create("multichoice", page)
	mc:SetPos(400, 30)
	mc:SetWidth(180)
	for _, choice in ipairs({"Vermelho", "Verde", "Azul", "Amarelo"}) do
		mc:AddChoice(choice)
	end
	mc:SetChoice("Escolha uma cor")
	mc.OnChoiceSelected = function(obj, choice)
		widgets.status:SetText("multichoice: " .. choice)
	end

	-- droplist -------------------------------------------------------------
	caption(page, 400, 80, "droplist")
	local dl = loveframes.Create("droplist", page)
	dl:SetPos(400, 100)
	dl:SetSize(180, 110)
	dl:AddElementsFromTable({"Item A", "Item B", "Item C", "Item D", "Item E"})
end

--[[--------------------------------------------------------------------------
	Aba 2: Entradas de texto e numeros
----------------------------------------------------------------------------]]
local function buildInputsTab(tabs)
	local page = newTabPage(tabs, "Entradas")

	-- input de linha unica -------------------------------------------------
	caption(page, 10, 10, "textbox (linha unica)")
	local input = loveframes.Create("textbox", page)
	input:SetPos(10, 30)
	input:SetWidth(250)
	input:SetPlaceholderText("Digite seu nome...")

	-- input de senha -------------------------------------------------------
	caption(page, 10, 70, "textbox (senha)")
	local pass = loveframes.Create("textbox", page)
	pass:SetPos(10, 90)
	pass:SetWidth(250)
	pass:SetType("password")
	pass:SetPasswordCharacter("*")

	-- input multilinha -----------------------------------------------------
	caption(page, 10, 130, "textbox (multilinha)")
	local multi = loveframes.Create("textbox", page)
	multi:SetPos(10, 150)
	multi:SetSize(250, 120)
	multi:SetMultiline(true)
	multi:SetText("Texto de varias linhas.\nEdite a vontade!")

	-- numberbox ------------------------------------------------------------
	caption(page, 300, 10, "numberbox")
	local nb = loveframes.Create("numberbox", page)
	nb:SetPos(300, 30)
	nb:SetSize(120, 30)
	nb:SetMinMax(0, 100)
	nb:SetValue(42)
	nb.OnValueChanged = function(obj, value)
		widgets.status:SetText("numberbox: " .. value)
	end

	-- textbox (rich/somente leitura tipico) --------------------------------
	caption(page, 300, 80, "textbox")
	local tbox = loveframes.Create("textbox", page)
	tbox:SetPos(300, 100)
	tbox:SetSize(280, 170)
	tbox:SetText(
		"O textbox exibe blocos de texto com quebra automatica de linha. " ..
		"Util para descricoes longas, caixas de dialogo e ajuda contextual " ..
		"dentro da interface."
	)
end

--[[--------------------------------------------------------------------------
	Aba 3: Sliders, progresso e rotulos
----------------------------------------------------------------------------]]
local function buildSlidersTab(tabs)
	local page = newTabPage(tabs, "Sliders")

	-- slider horizontal + progressbar acoplada -----------------------------
	caption(page, 10, 10, "slider (horizontal) -> progressbar")
	local hslider = loveframes.Create("slider", page)
	hslider:SetPos(10, 35)
	hslider:SetWidth(300)
	hslider:SetMinMax(0, 100)
	hslider:SetValue(50)

	local pbar = loveframes.Create("progressbar", page)
	pbar:SetPos(10, 70)
	pbar:SetSize(300, 25)
	pbar:SetMinMax(0, 100)
	pbar:SetValue(50)
	pbar:SetLerp(true)
	pbar:SetText("50%")

	hslider.OnValueChanged = function(obj, value)
		value = math.floor(value)
		pbar:SetValue(value)
		pbar:SetText(value .. "%")
		widgets.status:SetText("slider: " .. value)
	end

	-- slider vertical ------------------------------------------------------
	caption(page, 10, 110, "slider (vertical)")
	local vslider = loveframes.Create("slider", page)
	vslider:SetSlideType("vertical")
	vslider:SetPos(10, 130)
	vslider:SetSize(25,150)
	vslider:SetMinMax(0, 10)
	vslider:SetValue(5)

	-- progressbar animada --------------------------------------------------
	caption(page, 100, 130, "progressbar (animada)")
	local autobar = loveframes.Create("progressbar", page)
	autobar:SetPos(100, 150)
	autobar:SetSize(280, 25)
	autobar:SetMinMax(0, 100)
	autobar:SetValue(0)
	function autobar:Update(dt)
		local v = self.value
		local max = self.max
		v = v + dt * 20
		if v > 100 then v = 0 end
		self:SetValue(v)
		self:SetText(v.."|"..max)
	end

	-- label ----------------------------------------------------------------
	caption(page, 100, 200, "label (com objeto interno)")
	local lbl = loveframes.Create("label", page)
	lbl:SetPos(100, 220)
	lbl:SetText("Um label pode formatar texto e ainda conter outros objetos.")

	-- dial -----------------------------------------------------------------
	caption(page, 420, 10, "dial (clique e arraste)")
	local dial = loveframes.Create("dial", page)
	dial:SetPos(420, 35)
	dial:SetSize(40, 40)
	--dial:SetSnap(15)
	dial:SetAngle(45)
	dial.OnValueChanged = function(obj, angle)
		widgets.status:SetText("dial: " .. math.floor(angle) .. " graus")
	end
end

--[[--------------------------------------------------------------------------
	Aba 4: Listas, arvores e categorias
----------------------------------------------------------------------------]]
local function buildListsTab(tabs)
	local page = newTabPage(tabs, "Listas")

	-- columnlist -----------------------------------------------------------
	caption(page, 10, 10, "columnlist")
	local clist = loveframes.Create("columnlist", page)
	clist:SetPos(10, 30)
	clist:SetSize(330, 200)
	clist:AddColumn("Nome")
	clist:AddColumn("Funcao")
	clist:AddColumn("Nivel")
	clist:AddRow("Maxim", "Heroi", "12")
	clist:AddRow("Selan", "Maga", "11")
	clist:AddRow("Guy", "Lutador", "13")
	clist:AddRow("Artea", "Arqueiro", "10")
	clist:AddRow("Tia", "Mercadora", "9")
	for i=1,1000 do
		clist:AddRow(randomString(10), randomString(10), math.random(1,10))
	end
	clist.OnRowClicked = function(obj, row, data)
		widgets.status:SetText("Linha selecionada: " .. tostring(data[1]))
	end

	-- tree -----------------------------------------------------------------
	caption(page, 360, 10, "tree")
	local tree = loveframes.Create("tree", page)
	tree:SetPos(360, 30)
	tree:SetSize(230, 200)
	local n1 = tree:AddNode("Personagens")
	n1:AddNode("Maxim")
	n1:AddNode("Selan")
	local n2 = tree:AddNode("Itens")
	n2:AddNode("Pocao")
	n2:AddNode("Espada")
	tree:AddNode("Configuracoes")

	-- collapsiblecategory --------------------------------------------------
	caption(page, 10, 240, "collapsiblecategory")
	local cat = loveframes.Create("collapsiblecategory", page)
	cat:SetPos(10, 260)
	cat:SetSize(330, 30)
	local catpanel = loveframes.Create("panel")
	catpanel:SetSize(330, 80)
	local insideBtn = loveframes.Create("textbutton", catpanel)
	insideBtn:SetPos(10, 10)
	insideBtn:SetSize(150, 25)
	insideBtn:SetText("Botao interno")
	cat:SetText("Clique para abrir/fechar")
	cat:SetObject(catpanel)
end

--[[--------------------------------------------------------------------------
	Aba 5: Layout (grid, scrollpanel, imagens)
----------------------------------------------------------------------------]]
local function buildLayoutTab(tabs)
	local page = newTabPage(tabs, "Layout")

	-- grid -----------------------------------------------------------------
	caption(page, 10, 10, "grid (3x3 de botoes)")
	local grid = loveframes.Create("grid", page)
	grid:SetPos(10, 30)
	grid:SetRows(3)
	grid:SetColumns(3)
	grid:SetCellSize(70, 40)
	grid:SetCellPadding(4)
	for r = 1, 3 do
		for c = 1, 3 do
			local cell = loveframes.Create("textbutton")
			cell:SetText(r .. "," .. c)
			grid:AddItem(cell, r, c)
		end
	end

	-- skin -----------------------------------------------------------------
	caption(page, 260, 10, "skin")
	local skinpick = loveframes.Create("multichoice", page)
	:SetPos(10, 200)
	:AddChoice("CS2D")
	:AddChoice("moon")
	function skinpick:OnChoiceSelected(choice)
		--loveframes.config["ACTIVESKIN"] = choice
		loveframes.base:SetSkin(choice)
	end

	-- scrollpanel ----------------------------------------------------------
	caption(page, 260, 10, "scrollpanel")
	local sp = loveframes.Create("scrollpanel", page)
	sp:SetPos(260, 30)
	sp:SetSize(200, 200)
	for i = 1, 20 do
		local item = loveframes.Create("textbutton")
		item:SetSize(170, 25)
		item:SetText("Item rolavel " .. i)
		item:SetPos(0, (i-1)*20)
		sp:AddItem(item)
	end

	-- image ----------------------------------------------------------------
	caption(page, 480, 10, "image")
	local image = loveframes.Create("image", page)
	image:SetPos(480, 30)
	image:SetImage(img.green)

	-- imagelink ------------------------------------------------------------
	caption(page, 480, 110, "imagelink")
	local ilink = loveframes.Create("imagelink", page)
	ilink:SetPos(480, 130)
	ilink:SetImage(img.blue)
	ilink.OnClick = function()
		widgets.status:SetText("imagelink clicado!")
	end
end

--[[--------------------------------------------------------------------------
	Aba 6: Combinacoes / objetos compostos
----------------------------------------------------------------------------]]
local function buildComboTab(tabs)
	local page = loveframes.Create("scrollpanel")
	tabs:AddTab("Combinacoes", page)

	-- abas aninhadas dentro da aba ----------------------------------------
	caption(page, 10, 10, "tabs dentro de tabs")
	local inner = loveframes.Create("tabs", page)
	inner:SetPos(10, 30)
	inner:SetSize(300, 180)
	for i = 1, 3 do
		local innerPage = loveframes.Create("panel")
		local lbl = loveframes.Create("label", innerPage)
		lbl:SetPos(10, 10)
		lbl:SetText("Conteudo da sub-aba " .. i)
		local chk = loveframes.Create("checkbox", innerPage)
		chk:SetPos(10, 40)
		chk:SetText("Marcador da aba " .. i)
		inner:AddTab("Aba " .. i, innerPage)
	end

	-- botao que abre um Frame filho (janela modal opcional) ----------------
	caption(page, 340, 10, "Frame filho + messagebox")
	local openFrame = loveframes.Create("textbutton", page)
	openFrame:SetPos(340, 30)
	openFrame:SetSize(200, 30)
	openFrame:SetText("Abrir Frame")
	openFrame.OnClick = function()
		debug.openChildFrame()
	end

	local openMsg = loveframes.Create("textbutton", page)
	openMsg:SetPos(340, 70)
	openMsg:SetSize(200, 30)
	openMsg:SetText("Abrir messagebox")
	openMsg.OnClick = function()
		debug.openMessageBox()
	end

	-- log dinamico ---------------------------------------------------------
	caption(page, 10, 220, "log (clique no botao para adicionar)")
	local log = loveframes.Create("log", page)
	log:SetPos(10, 240)
	log:SetSize(300, 100)
	widgets.log = log
	local addLog = loveframes.Create("textbutton", page)
	addLog:SetPos(320, 240)
	addLog:SetSize(120, 25)
	addLog:SetText("Adicionar log")
	local logcount = 0
	addLog.OnClick = function()
		logcount = logcount + 1
		log:AddElement("Mensagem de log #" .. logcount)
	end

	-- dica: menu de contexto com clique direito ----------------------------
	caption(page, 340, 120, "Clique DIREITO na area cinza = menu de contexto")

	-- slideshow ------------------------------------------------------------
	caption(page, 340, 650, "slideshow (auto 3s, clique nos circulos)")
	local slides = loveframes.Create("slideshow", page)
	slides:SetPos(340, 450)
	slides:SetSize(300, 170)
	slides:SetInterval(3)
	local slidecolors = {{0.2,0.3,0.5}, {0.5,0.25,0.3}, {0.25,0.45,0.3}}
	for i = 1, 3 do
		local slide = loveframes.Create("panel")
		local lbl = loveframes.Create("label", slide)
		lbl:SetPos(20, 20)
		lbl:SetText("Slide " .. i .. " de 3")
		local c = slidecolors[i]
		slide.Draw = function(obj)
			love.graphics.setColor(c[1], c[2], c[3], 1)
			love.graphics.rectangle("fill", obj.x, obj.y, obj.width, obj.height)
		end
		slides:AddTab(slide)
	end
	slides.OnTabChange = function(obj, n)
		widgets.status:SetText("slideshow: slide " .. n)
	end
end

local function buildJoystickTab(tabs)
	local page = newTabPage(tabs, "Joystick")
	local toast = loveframes.Create("toast", page)
	local joystick = loveframes.Create("joystick", page)
	:SetPos(20, 20)

	local joystickPos = loveframes.Create("label", page)
	:Stack(10, joystick)
	:SetText("Posição: []")

	local joystickDir = loveframes.Create("label", page)
	:Stack(10, joystickPos)
	:SetText("Direção []")

	function joystick:OnValueChanged(vx, vy)
		local dir4 = self:GetDirection4()
		local dir8 = self:GetDirection8()
		joystickPos:SetText(string.format("Posição: [%s %s]", vx, vy))
		joystickDir:SetText(string.format("Direção: [%s %s]", dir4, dir8))

	end
	function joystick:OnRelease(vx, vy)
		toast:PushMessage("Solto!")
	end
end

--[[--------------------------------------------------------------------------
	Frame filho / messagebox (criados sob demanda)
----------------------------------------------------------------------------]]
function debug.openChildFrame()
	local frame = loveframes.Create("frame")
	frame:SetName("Frame filho")
	frame:SetSize(320, 200)
	frame:Center()
	frame:SetDraggable(true)
	frame:SetResizable(true)

	local lbl = loveframes.Create("label", frame)
	lbl:SetPos(15, 40)
	lbl:SetText("Este Frame e arrastavel e redimensionavel.")

	local makeModal = loveframes.Create("checkbox", frame)
	makeModal:SetPos(15, 70)
	makeModal:SetText("Modal")
	makeModal.OnChanged = function(obj, checked)
		frame:SetModal(checked)
	end

	local close = loveframes.Create("textbutton", frame)
	close:SetPos(15, 110)
	close:SetSize(120, 30)
	close:SetText("Fechar")
	close.OnClick = function()
		frame:Remove()
	end
end

function debug.openMessageBox()
	-- Um messagebox simples montado dentro de um Frame centralizado.
	local frame = loveframes.Create("frame")
	frame:SetName("Aviso")
	frame:SetSize(300, 150)
	frame:Center()
	frame:SetModal(true)

	local mb = loveframes.Create("messagebox", frame)
	mb:SetPos(15, 40)
	mb:SetMaxWidth(270)
	mb:SetText("Isto e um messagebox.\nUse para alertas e confirmacoes.")

	local ok = loveframes.Create("textbutton", frame)
	ok:SetPos(15, 105)
	ok:SetSize(100, 30)
	ok:SetText("OK")
	ok.OnClick = function()
		frame:Remove()
	end
end

-- Menu de contexto (clique direito).
function debug.createContextMenu()
	local menu = loveframes.Create("menu")
	menu:AddOption("Status: ok", nil, function()
		widgets.status:SetText("menu -> Status")
	end)
	menu:AddOption("Abrir Frame", nil, function()
		debug.openChildFrame()
	end)
	local sub = loveframes.Create("menu")
	sub:AddOption("Sub-acao 1", nil, function()
		widgets.status:SetText("menu -> sub 1")
	end)
	sub:AddOption("Sub-acao 2", nil, function()
		widgets.status:SetText("menu -> sub 2")
	end)
	menu:AddSubMenu("Submenu", nil, sub)
	menu:AddDivider()
	menu:AddOption("Fechar", nil, function() end)
	return menu
end

--[[--------------------------------------------------------------------------
	Construcao da UI
----------------------------------------------------------------------------]]
local function build()
	-- Imagens procedurais usadas pelos objetos baseados em imagem.
	img.red = makeImage(64, 64, 0.85, 0.2, 0.2)
	img.green = makeImage(64, 64, 0.2, 0.8, 0.3)
	img.blue = makeImage(64, 64, 0.3, 0.5, 0.95)

	-- Frame principal que hospeda todas as abas de teste.
	local frame = loveframes.Create("frame")
	frame:SetName("LoveFrames - Banco de testes de UI")
	frame:SetSize(680, 460)
	frame:Center()
	frame:SetDraggable(true)
	frame:SetResizable(false)

	local tabs = loveframes.Create("tabs", frame)
	tabs:SetPos(5, 30)
	tabs:SetSize(670, 390)

	buildButtonsTab(tabs)
	buildInputsTab(tabs)
	buildSlidersTab(tabs)
	buildListsTab(tabs)
	buildLayoutTab(tabs)
	buildComboTab(tabs)
	buildJoystickTab(tabs)

	-- Barra de status compartilhada (mostra a ultima interacao).
	widgets.status = loveframes.Create("label")
	widgets.status:SetPos(10, love.graphics.getHeight() - 24)
	widgets.status:SetText("Pronto. Interaja com os elementos acima.")
end

--[[--------------------------------------------------------------------------
	Callbacks do LOVE
	(main.lua retorna logo apos requerer este arquivo, entao definimos todos
	 os callbacks necessarios para a biblioteca funcionar de forma autonoma.)
----------------------------------------------------------------------------]]
function love.load()
	love.keyboard.setKeyRepeat(true)
	love.keyboard.setTextInput(true)
	build()
end

function love.update(dt)
	loveframes.update(dt)
end

function love.draw()
	love.graphics.clear(0.12, 0.12, 0.14)
	loveframes.draw()

	-- Pequena ajuda no rodape.
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	love.graphics.print(
		"F1: alterna debug interno  |  DELETE (sobre objeto): remove  |  botao direito: menu",
		10, love.graphics.getHeight() - 44
	)
	love.graphics.setColor(1, 1, 1, 1)
end

function love.mousepressed(x, y, button, istouch, presses)
	loveframes.mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	loveframes.mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
	loveframes.mousemoved(x, y, dx, dy, istouch)
end

function love.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
end

function love.keypressed(key, scancode, isrepeat)
	loveframes.keypressed(key, isrepeat)
end

function love.keyreleased(key)
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end

return debug
