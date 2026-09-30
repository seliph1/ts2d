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
	caption(page, 20, 20, "textbutton")
	local tbtn = loveframes.Create("textbutton", page)
	tbtn:SetPos(20, 50)
	tbtn:SetSize(150, 30)
	tbtn:SetText("Click-me"):SetHoverText("Click-me/Hovered")
	tbtn.OnClick = function(obj)
		widgets.status:SetText("textbutton clicado!")
	end

	-- button (botao basico) -----------------------------------------------
	caption(page, 20, 100, "button")
	local btn = loveframes.Create("button", page)
	btn:SetPos(20, 130)
	btn:SetSize(150, 30)
	btn:SetText("Botao basico")
	btn.OnClick = function(obj)
		widgets.status:SetText("button clicado!")
	end
	btn:SetTooltip("Hello, i'm a tooltip!")

	-- button toggle --------------------------------------------------------
	caption(page, 20, 180, "button (toggle)")
	local toggle = loveframes.Create("button", page)
	toggle:SetPos(20, 210)
	toggle:SetSize(150, 30)
	toggle:SetText("Toggle: OFF")
	toggle:SetToggleable(true)
	toggle.OnToggle = function(obj, state)
		obj:SetText("Toggle: " .. (state and "ON" or "OFF"))
	end

	-- button disabled ------------------------------------------------------
	caption(page, 20, 260, "button (disabled)")
	local disablebtn = loveframes.Create("button", page)
	disablebtn:SetPos(20, 290)
	disablebtn:SetSize(150, 30)
	disablebtn:SetEnabled(false)
	disablebtn:SetText("Disabled")

	-- textbutton disabled ------------------------------------------------------
	caption(page, 20, 340, "textbutton (disabled)")
	local textdisablebtn = loveframes.Create("textbutton", page)
	textdisablebtn:SetPos(20, 370)
	textdisablebtn:SetSize(150, 30)
	textdisablebtn:SetEnabled(false)
	textdisablebtn:SetText("Disabled"):SetHoverText("Disabled/Hovered")

	-- imagebutton ----------------------------------------------------------
	caption(page, 240, 20, "imagebutton")
	local ibtn = loveframes.Create("imagebutton", page)
	ibtn:SetPos(240, 50)
	ibtn:SetImage(img.blue)
	ibtn:SizeToImage()
	ibtn.OnClick = function()
		widgets.status:SetText("imagebutton clicado!")
	end

	-- imagelink ------------------------------------------------------------
	caption(page, 340, 20, "imagelink")
	local ilink = loveframes.Create("imagelink", page)
	ilink:SetPos(340, 50)
	ilink:SetImage(img.green)
	ilink.OnClick = function()
		widgets.status:SetText("imagelink clicado!")
	end

	-- checkbox -------------------------------------------------------------
	caption(page, 240, 140, "checkbox")
	local chk = loveframes.Create("checkbox", page)
	chk:SetPos(240, 170)
	chk:SetText("Habilitar algo")
	chk.OnChanged = function(obj, checked)
		widgets.status:SetText("checkbox: " .. tostring(checked))
	end

	local chk_disabled = loveframes.Create("checkbox", page)
	chk_disabled:SetPos(240, 200)
	chk_disabled:SetText("Desativado")
	chk_disabled:SetEnabled(false)

	-- toggle ---------------------------------------------------------------
	caption(page, 240, 250, "toggle")

	local sw = loveframes.Create("toggle", page)
	sw:SetPos(240, 280)
	sw:SetText("Modo alternativo")
	local sw_disabled = loveframes.Create("toggle", page)
	sw_disabled:SetPos(240, 315)
	sw_disabled:SetText("Desativado")
	sw_disabled:SetEnabled(false)

	local sw_vertical = loveframes.Create("toggle", page)
	sw_vertical:SetPos(240, 350)
	sw_vertical:SetText("Vertical")
	function sw:OnChanged(checked)
		widgets.status:SetText("toggle: " .. tostring(checked))
		if checked then
			sw_vertical:SetDirection("vertical")
		else
			sw_vertical:SetDirection("horizontal")
		end
	end

	-- radiobutton (grupo) --------------------------------------------------
	caption(page, 460, 340, "radiobutton (grupo)")
	for i = 1, 4 do
		local radio = loveframes.Create("radiobutton", page)
		radio:SetPos(460, 340 + i * 30)
		radio:SetText("Opcao " .. i)
		radio:SetGroup(debug_radios)
		if i == 1 then radio:SetChecked(true) end
		radio.OnChanged = function(obj, checked)
			if checked then
				widgets.status:SetText("radio: Opcao " .. i)
			end
		end

		if i == 4 then
			radio:SetText("Desativado")
			radio:SetEnabled(false)
		end
	end


	-- multichoice ----------------------------------------------------------
	caption(page, 460, 20, "multichoice"):SetTooltip("Test")
	local mc = loveframes.Create("multichoice", page)
	mc:SetPos(460, 50)
	mc:SetWidth(180)
	for _, choice in ipairs({ "Vermelho", "Verde", "Azul", "Amarelo" }) do
		mc:AddChoice(choice)
	end
	mc:SetChoice("Escolha uma cor")
	mc.OnChoiceSelected = function(obj, choice)
		widgets.status:SetText("multichoice: " .. choice)
	end

	-- droplist -------------------------------------------------------------
	caption(page, 460, 100, "droplist")
	local dl = loveframes.Create("droplist", page)
	dl:SetPos(460, 130)
	dl:SetSize(180, 110)
	dl:AddElementsFromTable({ "Item A", "Item B", "Item C", "Item D", "Item E" })

	-- multichoice disabled -------------------------------------------------
	caption(page, 460, 260, "multichoice (disabled)")
	local mc_dis = loveframes.Create("multichoice", page)
	mc_dis:SetPos(460, 290)
	mc_dis:SetWidth(180)
	mc_dis:SetChoice("Indisponivel")
	mc_dis:SetEnabled(false)
end

--[[--------------------------------------------------------------------------
	Aba 2: Entradas de texto e numeros
----------------------------------------------------------------------------]]
local function buildInputsTab(tabs)
	local page = newTabPage(tabs, "Entradas")

	-- input de linha unica -------------------------------------------------
	caption(page, 20, 20, "textbox (linha unica)")
	local input = loveframes.Create("textbox", page)
	input:SetPos(20, 50)
	input:SetWidth(250)
	input:SetPlaceholderText("Digite seu nome...")

	-- input de senha -------------------------------------------------------
	caption(page, 20, 100, "textbox (senha)")
	local pass = loveframes.Create("textbox", page)
	pass:SetPos(20, 130)
	pass:SetWidth(250)
	pass:SetType("password")
	pass:SetPasswordCharacter("*")

	-- input multilinha -----------------------------------------------------
	caption(page, 20, 180, "textbox (multilinha)")
	local multi = loveframes.Create("textbox", page)
	multi:SetPos(20, 210)
	multi:SetSize(250, 120)
	multi:SetType("multiwrap")
	multi:SetText("Texto de varias linhas.\nEdite a vontade!")

	local btn_left = loveframes.Create("button", page)
	btn_left:SetPos(20, 350)
	btn_left:SetSize(60, 20)
	btn_left:SetText("Esq")
	btn_left.OnClick = function() multi:SetAlignment("left") end

	local btn_center = loveframes.Create("button", page)
	btn_center:SetPos(100, 350)
	btn_center:SetSize(60, 20)
	btn_center:SetText("Centro")
	btn_center.OnClick = function() multi:SetAlignment("center") end

	local btn_right = loveframes.Create("button", page)
	btn_right:SetPos(180, 350)
	btn_right:SetSize(60, 20)
	btn_right:SetText("Dir")
	btn_right.OnClick = function() multi:SetAlignment("right") end

	local btn_top = loveframes.Create("button", page)
	btn_top:SetPos(20, 380)
	btn_top:SetSize(60, 20)
	btn_top:SetText("Topo")
	btn_top.OnClick = function() multi:SetVerticalAlignment("top") end

	local btn_vcenter = loveframes.Create("button", page)
	btn_vcenter:SetPos(100, 380)
	btn_vcenter:SetSize(60, 20)
	btn_vcenter:SetText("Meio")
	btn_vcenter.OnClick = function() multi:SetVerticalAlignment("center") end

	local btn_bottom = loveframes.Create("button", page)
	btn_bottom:SetPos(180, 380)
	btn_bottom:SetSize(60, 20)
	btn_bottom:SetText("Fundo")
	btn_bottom.OnClick = function() multi:SetVerticalAlignment("bottom") end

	-- numberbox ------------------------------------------------------------
	caption(page, 330, 20, "numberbox")
	local nb = loveframes.Create("numberbox", page)
	nb:SetPos(330, 50)
	nb:SetSize(120, 25)
	nb:SetMinMax(0, 100)
	nb:SetValue(42)
	nb.OnValueChanged = function(obj, value)
		widgets.status:SetText("numberbox: " .. value)
	end

	-- numberbox disabled ---------------------------------------------------
	caption(page, 330, 100, "numberbox (disabled)")
	local nb_dis = loveframes.Create("numberbox", page)
	nb_dis:SetPos(330, 130)
	nb_dis:SetSize(120, 25)
	nb_dis:SetValue(42)
	nb_dis:SetEnabled(false)

	-- stepper (horizontal) -------------------------------------------------
	caption(page, 510, 20, "stepper")
	local stp1 = loveframes.Create("stepper", page)
	stp1:SetPos(510, 50)
	stp1:SetSize(80, 25)
	stp1:SetMinMax(0, 100)
	stp1:SetValue(15)

	-- stepper (vertical) ---------------------------------------------------
	caption(page, 640, 20, "stepper (v)")
	local stp2 = loveframes.Create("stepper", page)
	stp2:SetPos(640, 50)
	stp2:SetSize(25, 80)
	stp2:SetVertical(true)
	stp2:SetMinMax(0, 100)
	stp2:SetValue(15)

	-- codebox --------------------------------------------------------------
	caption(page, 330, 180, "codebox (editor de lua)")
	local cbox = loveframes.Create("codebox", page)
	cbox:SetPos(330, 210)
	cbox:SetSize(340, 200)
	cbox:SetText(
		"local function sum(a, b)\n\t-- soma de valores\n\treturn a + b\nend\n\nlocal num = 50\nprint(\"Total: \", sum(10, num))")
end

--[[--------------------------------------------------------------------------
	Aba 3: Sliders, progresso e rotulos
----------------------------------------------------------------------------]]
local function buildSlidersTab(tabs)
	local page = newTabPage(tabs, "Sliders")

	local toast = loveframes.Create("toast", page)
	local joystick = loveframes.Create("joystick", page)
		:SetPos(20, 250)

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

	-- slider horizontal + progressbar acoplada -----------------------------
	caption(page, 20, 20, "slider (horizontal) -> progressbar")
	local hslider = loveframes.Create("slider", page)
	hslider:SetPos(20, 50)
	hslider:SetWidth(300)
	hslider:SetMinMax(0, 100)
	hslider:SetValue(50)

	local pbar = loveframes.Create("progressbar", page)
	pbar:SetPos(20, 90)
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
	caption(page, 350, 20, "slider (vertical)")
	local vslider = loveframes.Create("slider", page)
	vslider:SetSlideType("vertical")
	vslider:SetPos(350, 50)
	vslider:SetSize(25, 150)
	vslider:SetMinMax(0, 20)
	vslider:SetValue(5)

	-- progressbar animada --------------------------------------------------
	caption(page, 20, 140, "progressbar (animada)")
	local autobar = loveframes.Create("progressbar", page)
	autobar:SetPos(20, 160)
	autobar:SetSize(300, 25)
	autobar:SetMinMax(0, 100)
	autobar:SetValue(0)
	function autobar:Update(dt)
		local v = self.value
		local max = self.max
		v = v + dt * vslider:GetValue()
		if v > 100 then v = 0 end
		self:SetValue(v)
		self:SetText(string.format(" %.2f%% | %s", v, max))
	end

	local lerpbox = loveframes.Create("checkbox", page)
	lerpbox:SetPos(20, 195)
	lerpbox:SetText("Usar Lerp")
	lerpbox:SetChecked(true)
	autobar:SetLerp(true)
	lerpbox.OnChanged = function(obj, checked)
		pbar:SetLerp(checked)
		autobar:SetLerp(checked)
	end

	-- dial -----------------------------------------------------------------
	caption(page, 500, 20, "dial (clique e arraste)")
	local dial = loveframes.Create("dial", page)
	dial:SetPos(500, 50)
	dial:SetSize(100, 100)
	dial:SetAngle(45)
	dial.OnValueChanged = function(obj, angle)
		widgets.status:SetText("dial: " .. math.floor(angle) .. " graus")
	end
	local snap = loveframes.Create("checkbox", page)
		:SetPos(460, 170)
		:SetText("Enable snap")
	function snap:OnChanged(toggle)
		print(toggle)
		if toggle then
			dial:SetSnap(15)
		else
			dial:SetSnap(1)
		end
	end
end

--[[--------------------------------------------------------------------------
	Aba 4: Listas, arvores e categorias
----------------------------------------------------------------------------]]
local function buildListsTab(tabs)
	local page = newTabPage(tabs, "Listas")

	-- radialmenu test ----------------------------------------------------------
	caption(page, 380, 420, "radialmenu")
	local rmbtn = loveframes.Create("button", page)
	rmbtn:SetPos(380, 440)
	rmbtn:SetSize(150, 30)
	rmbtn:SetText("Abrir Menu Radial")
	rmbtn.OnClick = function(obj)
		local rmenu = loveframes.Create("radialmenu")
		rmenu:AddOption("Inventario", nil, function() widgets.status:SetText("Inventario!") end)
		rmenu:AddOption("Magias", nil, function() widgets.status:SetText("Magias!") end)
		rmenu:AddOption("Social", nil, function() widgets.status:SetText("Social!") end)
		rmenu:AddOption("Mapa", nil, function() widgets.status:SetText("Mapa!") end)
		rmenu:AddOption("Opcoes", nil, function() widgets.status:SetText("Opcoes!") end)
		rmenu:Open()
	end

	-- columnlist -----------------------------------------------------------
	caption(page, 20, 20, "columnlist")
	local clist = loveframes.Create("columnlist", page)
	clist:SetPos(20, 50)
	clist:SetSize(330, 120)
	clist:AddColumn("Nome")
	clist:AddColumn("Funcao")
	clist:AddColumn("Nivel")
	clist:AddRow("Maxim", "Heroi", "12")
	clist:AddRow("Selan", "Maga", "11")
	clist:AddRow("Guy", "Lutador", "13")
	clist:AddRow("Artea", "Arqueiro", "10")
	clist:AddRow("Tia", "Mercadora", "9")
	for i = 1, 1000 do
		clist:AddRow(randomString(10), randomString(10), math.random(1, 10))
	end
	clist.OnRowClicked = function(obj, row, data)
		widgets.status:SetText("Linha selecionada: " .. tostring(data[1]))
	end

	-- tree -----------------------------------------------------------------
	caption(page, 380, 20, "tree")
	local scroll = loveframes.Create("scrollpanel", page):SetSize(300, 120):SetPos(380, 50)
	local tree = loveframes.Create("tree", scroll):SetPos(0, 0)

	tree:SetPos(0, 0)
	tree:SetSize(230, 200)
	local n1 = tree:AddNode("Personagens")
	n1:AddNode("Maxim")
	n1:AddNode("Selan")
	local n2 = tree:AddNode("Itens")
	n2:AddNode("Pocao")
	n2:AddNode("Espada")
	tree:AddNode("Configuracoes")
	local n3 = tree:AddNode("Outros")
	for i = 1, 1000 do
		n3:AddNode(randomString(10))
	end

	local stackingCheckbox = loveframes.Create("checkbox", page)
		:SetText("Allow Nesting"):Stack(10, scroll)
	function stackingCheckbox:OnChanged(state)
		tree:SetNesting(state)
	end

	-- log dinamico ---------------------------------------------------------
	caption(page, 20, 190, "log (clique no botao para adicionar)")
	local log = loveframes.Create("log", page)
	log:SetPos(20, 250)
	log:SetSize(330, 110)
	widgets.log = log
	local addLog = loveframes.Create("button", page)
	addLog:SetPos(20, 210)
	addLog:SetSize(120, 25)
	addLog:SetText("Adicionar log")
	local logcount = 0
	addLog.OnClick = function()
		logcount = logcount + 1
		log:AddElement("Mensagem de log #" .. logcount)
	end

	-- collapsiblecategory --------------------------------------------------
	caption(page, 20, 380, "collapsiblecategory")
	local cat = loveframes.Create("collapsiblecategory", page)
	cat:SetPos(20, 400)
	cat:SetSize(330, 30)
	local catpanel = loveframes.Create("panel")
	catpanel:SetSize(320, 80)
	local insideBtn = loveframes.Create("button", catpanel)
	insideBtn:SetPos(10, 10)
	insideBtn:SetSize(150, 25)
	insideBtn:SetText("Botao interno")
	cat:SetText("Clique para abrir/fechar")
	cat:SetObject(catpanel)


	caption(page, 380, 240, "menu")
	local panel = loveframes.Create("panel", page)
		:SetPos(380, 270)
		:SetSize(200, 100)

	local alert = loveframes.Create("messagebox", panel)
		:SetMaxWidth(1)
		:SetCollidable(false)
		:SetText("Clique em qualquer lugar dentro desse retângulo")

	local menu_opcoes = {
		{
			text = "Ver Perfil",
			func = function()
				widgets.status:SetText("Menu selecionado: Ver Perfil")
			end
		},
		{ type = "divider" },
		{
			text = "Preferências",
			sub_menu = {
				{
					text = "Áudio",
					func = function()
						widgets.status:SetText("Menu selecionado: Audio")
					end
				},
				{
					text = "Vídeo",
					func = function()
						widgets.status:SetText("Menu selecionado: Video")
					end
				}
			}
		},
		{ text = "Strings Aleatórias: ", sub_menu = {} },
		{ text = "Sair",                 func = function() os.exit() end }
	}

	local sub = {}
	for i = 1, 20 do
		local r = randomString(10)
		sub[#sub + 1] = {
			text = r,
			func = function()
				widgets.status:SetText("Menu selecionado: " .. r)
			end
		}
	end
	menu_opcoes[4].sub_menu = sub
	panel:SetContextMenu(menu_opcoes)
end

--[[--------------------------------------------------------------------------
	Aba 5: Layout (grid, scrollpanel, imagens)
----------------------------------------------------------------------------]]
local function buildLayoutTab(tabs)
	local page = newTabPage(tabs, "Layout")

	-- dockzone -------------------------------------------------------------
	caption(page, 20, 270, "dockzones (arraste as janelas abaixo para estas areas)")
	local framesize = 250
	local dz1 = loveframes.Create("dockzone", page)
	dz1:SetPos(20, 300)
	dz1:SetSize(framesize, framesize)

	local dz2 = loveframes.Create("dockzone", page)
	dz2:SetPos(framesize + 50, 300)
	dz2:SetSize(framesize, framesize)

	local dframe1 = loveframes.Create("frame")
	dframe1:SetPos(20, 560)
	dframe1:SetSize(framesize, framesize)
	dframe1:SetName("Janela Ancorável 1")
	dframe1:SetDockable(true)
	dframe1:SetDraggable(true)
	dframe1:SetProperty("ticks", 0)
	function dframe1:DrawOver()
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.printf(string.format("ticks: %s", self.ticks), self.x + 5, self.y + 20, self.width)
		love.graphics.printf(tostring(self.parent), self.x + 5, self.y + 40, self.width)
	end

	function dframe1:Update(dt)
		self.accumulator = self.accumulator or 0
		self.accumulator = self.accumulator + dt
		local tickStep = 1 --1 / 35
		while self.accumulator >= tickStep do
			self.ticks = self.ticks + 1
			self.accumulator = self.accumulator - tickStep
		end
	end

	local dframe2 = loveframes.Create("frame")
	dframe2:SetPos(190, 560)
	dframe2:SetSize(framesize, framesize)
	dframe2:SetName("Janela Ancorável 2")
	dframe2:SetDockable(true)
	dframe2:SetDraggable(true)

	dz1:Dock(dframe1)
	dz2:Dock(dframe2)

	-- grid -----------------------------------------------------------------
	caption(page, 20, 20, "grid (3x3 de botoes)")
	local grid = loveframes.Create("grid", page)
	grid:SetPos(20, 50)
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
	caption(page, 20, 200, "skin")
	local skinpick = loveframes.Create("multichoice", page)
		:SetPos(20, 230)
		:AddChoice("CS2D")
		:AddChoice("moon")
	function skinpick:OnChoiceSelected(choice)
		--loveframes.config["ACTIVESKIN"] = choice
		loveframes.base:SetSkin(choice)
	end

	-- scrollpanel ----------------------------------------------------------
	caption(page, 290, 20, "scrollpanel")
	local sp = loveframes.Create("scrollpanel", page)
	sp:SetPos(290, 50)
	sp:SetSize(200, 200)
	for i = 1, 20 do
		local item = loveframes.Create("textbutton")
		item:SetSize(170, 25)
		item:SetText("Item rolavel " .. i)
		item:SetPos(0, (i - 1) * 20)
		sp:AddItem(item)
	end

	-- panel ----------------------------------------------------------
	caption(page, 520, 20, "panel")
	local p = loveframes.Create("panel", page)
	p:SetPos(520, 50)
	p:SetSize(200, 200)
end

--[[--------------------------------------------------------------------------
	Aba 6: Combinacoes / objetos compostos
----------------------------------------------------------------------------]]
local function buildComboTab(tabs)
	local pagef = newTabPage(tabs, "Combinações")
	local page = loveframes.Create("scrollpanel", pagef)
		:Expand():SetBackground(false)

	-- abas aninhadas dentro da aba ----------------------------------------
	caption(page, 20, 20, "tabs dentro de tabs")
	local inner = loveframes.Create("tabs", page)
	inner:SetPos(20, 50)
	inner:SetSize(300, 180)
	for i = 1, 3 do
		local innerPage = loveframes.Create("panel")
		local lbl = loveframes.Create("label", innerPage)
		lbl:SetPos(20, 20)
		lbl:SetText("Conteudo da sub-aba " .. i)
		local chk = loveframes.Create("checkbox", innerPage)
		chk:SetPos(20, 60)
		chk:SetText("Marcador da aba " .. i)
		inner:AddTab("Aba " .. i, innerPage)
	end

	-- loading -------------------------------------------------------------
	caption(page, 20, 270, "loading (spinner procedural)")
	local load = loveframes.Create("loading", page)
	load:SetPos(20, 310)
	load:SetRadius(25)
	load:SetSpeed(math.pi * 3)

	-- botao que abre um Frame filho (janela modal opcional) ----------------
	caption(page, 380, 20, "Frame filho + messagebox")
	local openFrame = loveframes.Create("textbutton", page)
	openFrame:SetPos(380, 50)
	openFrame:SetSize(220, 40)
	openFrame:SetText("> Abrir Frame")
	openFrame.OnClick = function()
		debug.openChildFrame()
	end

	local openMsg = loveframes.Create("textbutton", page)
	openMsg:SetPos(380, 80)
	openMsg:SetSize(220, 40)
	openMsg:SetText("> Abrir messagebox")
	openMsg.OnClick = function()
		debug.openMessageBox()
	end

	-- slideshow ------------------------------------------------------------
	caption(page, 380, 190, "slideshow (auto 3s, clique nos circulos)")
	local slides = loveframes.Create("slideshow", page)
	slides:SetPos(380, 220)
	slides:SetSize(320, 180)
	slides:SetInterval(3)
	local slidecolors = { { 0.2, 0.3, 0.5 }, { 0.5, 0.25, 0.3 }, { 0.25, 0.45, 0.3 } }
	for i = 1, 3 do
		local slide = loveframes.Create("panel")
		local lbl = loveframes.Create("label", slide)
		lbl:SetPos(130, 80)
		lbl:SetText("Slide " .. i)
		slide.Draw = function(s)
			love.graphics.setColor(slidecolors[i])
			love.graphics.rectangle("fill", s.x, s.y, s.width, s.height)
		end
		slides:AddSlide(slide)
	end

	-- carousel -------------------------------------------------------------
	caption(page, 380, 440, "carousel (arraste lateralmente para navegar)")
	local carousel = loveframes.Create("carousel", page)
	carousel:SetPos(380, 470)
	carousel:SetSize(320, 160)
	local carcolors = { { 0.5, 0.2, 0.2 }, { 0.2, 0.5, 0.2 }, { 0.2, 0.2, 0.5 }, { 0.5, 0.5, 0.2 }, { 0.5, 0.2, 0.5 } }
	for i = 1, 5 do
		local item = loveframes.Create("panel")
		local lbl = loveframes.Create("label", item)
		lbl:SetPos(80, 50)
		lbl:SetText("Item " .. i)
		item.Draw = function(s)
			love.graphics.setColor(carcolors[i])
			love.graphics.rectangle("fill", s.x, s.y, s.width, s.height)
		end
		carousel:AddItem(item)
	end
	slides.OnTabChange = function(obj, n)
		widgets.status:SetText("slideshow: slide " .. n)
	end
end


local function buildColorPickerTab(tabs)
	local page = newTabPage(tabs, "ColorPicker")
	caption(page, 10, 10, "colorpicker avancado")

	local cp = loveframes.Create("colorpicker", page)
	cp:SetPos(10, 35)
	cp:SetSize(330, 150)

	caption(page, 360, 10, "Demonstracao de cor do callback")
	local feedback = loveframes.Create("panel", page)
	feedback:SetPos(360, 35)
	feedback:SetSize(280, 135)

	feedback.Draw = function(object)
		if object.drawfunc then
			object.drawfunc(object)
		end
		local x, y = object:GetPos()
		local w, h = object:GetSize()
		local r, g, b, a = cp:GetColor()
		love.graphics.setColor(r, g, b, a)
		love.graphics.rectangle("fill", x + 4, y + 4, w - 8, h - 8)
	end

	cp.OnColorChanged = function(object, r, g, b, a)
		widgets.status:SetText(string.format("Cor selecionada: R=%.2f, G=%.2f, B=%.2f, A=%.2f", r, g, b, a))
	end

	local randbtn = loveframes.Create("button", page)
	randbtn:SetPos(10, 190)
	randbtn:SetSize(160, 30)
	randbtn:SetText("Cor Aleatoria")
	randbtn.OnClick = function()
		cp:SetColor(math.random(), math.random(), math.random(), math.random())
	end

	local resetbtn = loveframes.Create("button", page)
	resetbtn:SetPos(180, 190)
	resetbtn:SetSize(160, 30)
	resetbtn:SetText("Resetar (Branco)")
	resetbtn.OnClick = function()
		cp:SetColor(1, 1, 1, 1)
	end
end

local function buildFileBrowserTab(tabs)
	local page = newTabPage(tabs, "FileBrowser")
	caption(page, 10, 10, "Componente FileBrowser incorporável e Dialogs de Arquivo")

	-- Button to open dialog version
	local btn_open_dlg = loveframes.Create("button", page)
	btn_open_dlg:SetPos(10, 35)
	btn_open_dlg:SetSize(200, 30)
	btn_open_dlg:SetText("Abrir File Dialog (Abrir)")
	btn_open_dlg.OnClick = function()
		loveframes.CreateFileDialog("Selecione um script LUA", "open", { "*.lua" },
			function(filepath)
				widgets.status:SetText("Arquivo selecionado para abrir: " .. filepath)
			end,
			function()
				widgets.status:SetText("Cancelado diálogo de abrir arquivo")
			end
		)
	end

	local btn_save_dlg = loveframes.Create("button", page)
	btn_save_dlg:SetPos(220, 35)
	btn_save_dlg:SetSize(200, 30)
	btn_save_dlg:SetText("Abrir File Dialog (Salvar)")
	btn_save_dlg.OnClick = function()
		loveframes.CreateFileDialog("Salvar como...", "save", { "*.lua", "*.png" },
			function(filepath)
				widgets.status:SetText("Arquivo selecionado para salvar: " .. filepath)
			end,
			function()
				widgets.status:SetText("Cancelado diálogo de salvar arquivo")
			end
		)
	end

	-- Inline file browser demonstration inside a frame
	caption(page, 10, 80, "Instância de FileBrowser incorporada:")
	local fb = loveframes.Create("filebrowser", page)
	fb:SetPos(5, 100)
	fb:SetSize(635, 235)
	fb:SetFilter({ "*.lua", "*.png", "*.ogg" })
	fb:SetOnSelect(function(filepath)
		widgets.status:SetText("Selecionado arquivo no browser incorporado: " .. filepath)
		local parts = loveframes.SplitString(filepath, "([.])")
		local ext = #parts > 1 and parts[#parts]:lower() or ""
		local text_extensions = { lua = true, txt = true, json = true, xml = true, tmx = true, tsx = true, md = true }

		if text_extensions[ext] then
			local content = love.filesystem.read(filepath)
			if content then
				local frame = loveframes.Create("frame"):SetSize(0.8, 0.8):Center()
				local codebox = loveframes.Create("codebox", frame)
					:SetPos(5, 35):ExpandDown(5):ExpandRight(5)
					:SetText(content)
			end
		end
	end)
	fb:SetOnCancel(function()
		widgets.status:SetText("Cancelada ação no browser incorporado")
	end)
end

local function buildGraphTab(tabs)
	local page = newTabPage(tabs, "Nós (Graph)")

	-- Create graphfield
	local gf = loveframes.Create("graphfield", page)
	gf:SetPos(10, 10)
	gf:SetSize(650, 310)

	-- Create Node 1: Texture Input
	local n1 = loveframes.Create("graphnode", gf)
	n1.name = "Texture Input"
	n1.graphx = 30
	n1.graphy = 40
	n1:SetWidth(150)
	local s_rgb = n1:AddOutput("RGB", { 1, 1, 0, 1 }, "color")
	local s_a = n1:AddOutput("Alpha", { 0, 1, 0, 1 }, "float")

	-- Create Node 2: Brightness
	local n2 = loveframes.Create("graphnode", gf)
	n2.name = "Brightness"
	n2.graphx = 220
	n2.graphy = 80
	n2:SetWidth(160)
	local s_in_color = n2:AddInput("Image", { 1, 1, 0, 1 }, "color")
	local s_in_val = n2:AddInput("Factor", { 0, 1, 0, 1 }, "float")
	local s_out_color = n2:AddOutput("Result", { 1, 1, 0, 1 }, "color")
	local t = loveframes.Create("textbox", n2)
	t:SetText("Opções:")
	t:SetPos(10, 80)
	n2:Wrap(10)


	-- Create Node 3: Viewer Output
	local n3 = loveframes.Create("graphnode", gf)
	n3.name = "Viewer Output"
	n3.graphx = 440
	n3.graphy = 100
	n3:SetWidth(150)
	local s_viewer_in = n3:AddInput("Surface", { 1, 1, 0, 1 }, "color")

	-- Pre-connect some sockets for demo purposes!
	gf:Connect(s_rgb, s_in_color)
	gf:Connect(s_out_color, s_viewer_in)

	-- Register updates to status bar on drag/connections changes
	local old_Connect = gf.Connect
	gf.Connect = function(self, from, to)
		old_Connect(self, from, to)
		widgets.status:SetText(string.format("Conectado: %s (%s) -> %s (%s)",
			from.parent.name, from.name, to.parent.name, to.name))
	end

	local old_DisconnectInput = gf.DisconnectInput
	gf.DisconnectInput = function(self, socket)
		local from = nil
		for _, conn in ipairs(self.connections) do
			if conn.to == socket then
				from = conn.from
				break
			end
		end
		old_DisconnectInput(self, socket)
		if from then
			widgets.status:SetText(string.format("Desconectado: %s (%s) -> %s (%s)",
				from.parent.name, from.name, socket.parent.name, socket.name))
		end
	end

	local old_DisconnectOutput = gf.DisconnectOutput
	gf.DisconnectOutput = function(self, socket)
		local targets = {}
		for _, conn in ipairs(self.connections) do
			if conn.from == socket then
				table.insert(targets, conn.to)
			end
		end
		old_DisconnectOutput(self, socket)
		if #targets > 0 then
			widgets.status:SetText(string.format("Desconectado %d ligação(ões) de %s (%s)",
				#targets, socket.parent.name, socket.name))
		end
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

	local numberBox = loveframes.Create("numberbox", frame)
	numberBox:SetPos(15, 95)
	local close = loveframes.Create("textbutton", frame)
	close:SetText("Fechar")
	close:SetPos(-10, -10)
	close.OnClick = function()
		frame:Remove()
	end
end

function debug.openMessageBox()
	-- Um messagebox simples montado dentro de um Frame centralizado.
	local f = loveframes.Create("frame")
	f:SetName("Aviso")
	f:SetSize(300, 150)
	f:Center()
	f:SetModal(true)

	local mb = loveframes.Create("messagebox", f)
	mb:SetPos(15, 40)
	mb:SetMaxWidth(270)
	mb:SetText("Isto e um messagebox.\nUse para alertas e confirmacoes.")

	local ok = loveframes.Create("textbutton", f)
	ok:SetPos(15, 105)
	ok:SetSize(100, 30)
	ok:SetText("OK")
	ok.OnClick = function()
		f:Remove()
	end
end

--[[--------------------------------------------------------------------------
	Construcao da UI
----------------------------------------------------------------------------]]
local function build()
	-- Imagens procedurais usadas pelos objetos baseados em imagem.
	img.red = makeImage(64, 64, 0.85, 0.2, 0.2)
	img.green = makeImage(64, 64, 0.2, 0.8, 0.3)
	img.blue = makeImage(64, 64, 0.3, 0.5, 0.95)

	-- Menubar de exemplo
	local menubar = loveframes.Create("menubar")

	local file_menu = menubar:AddMenu("Arquivo")
	file_menu:ConstructFromTable({
		{
			text = "Novo",
			icon = "assets/icons/16x16/add.png",
			func = function()
				widgets.status:SetText(
					"Arquivo -> Novo clicado")
			end
		},
		{
			text = "Salvar",
			icon = "assets/icons/16x16/diskette.png",
			func = function()
				widgets.status:SetText(
					"Arquivo -> Salvar clicado")
			end
		},
		{
			text = "Recentes",
			icon = "assets/icons/16x16/folder.png",
			submenu = {
				{
					text = "projeto1.lua",
					icon = "assets/icons/16x16/page_white_code.png",
					func = function()
						widgets
							.status:SetText("Abrindo projeto 1")
					end
				},
				{
					text = "projeto2.lua",
					icon = "assets/icons/16x16/page_white_code.png",
					func = function()
						widgets
							.status:SetText("Abrindo projeto 2")
					end
				},
			}
		},
		{ type = "divider" },
		{ text = "Sair",   icon = "assets/icons/16x16/door_out.png", func = function() love.event.quit() end },
	})

	local edit_menu = menubar:AddMenu("Editar")
	edit_menu:ConstructFromTable({
		{
			text = "Desfazer",
			icon = "assets/icons/16x16/arrow_undo.png",
			func = function()
				widgets.status:SetText(
					"Editar -> Desfazer")
			end
		},
		{
			text = "Refazer",
			icon = "assets/icons/16x16/arrow_redo.png",
			func = function()
				widgets.status:SetText(
					"Editar -> Refazer")
			end
		},
		{ type = "divider" },
		{
			text = "Recortar",
			icon = "assets/icons/16x16/cut.png",
			func = function()
				widgets.status:SetText(
					"Editar -> Recortar")
			end
		},
		{
			text = "Copiar",
			icon = "assets/icons/16x16/page_white_copy.png",
			enabled = false,
			func = function()
				widgets.status:SetText(
					"Editar -> Copiar")
			end
		},
		{
			text = "Colar",
			icon = "assets/icons/16x16/page_white_paste.png",
			enabled = false,
			func = function()
				widgets.status:SetText(
					"Editar -> Colar")
			end
		},
		{
			text = "Preferências",
			icon = "assets/icons/16x16/cog.png",
			submenu = {
				{
					text = "Tema Escuro",
					icon = "assets/icons/16x16/contrast.png",
					func = function()
						widgets.status
							:SetText("Ativando tema escuro")
					end
				},
				{
					text = "Tema Claro",
					icon = "assets/icons/16x16/contrast_high.png",
					func = function()
						widgets.status
							:SetText("Ativando tema claro")
					end
				},
			}
		},
	})

	local help_menu = menubar:AddMenu("Ajuda")
	help_menu:ConstructFromTable({
		{
			text = "Sobre",
			icon = "assets/icons/16x16/information.png",
			func = function()
				local frame_sobre = loveframes.Create("frame")
				frame_sobre:SetName("Sobre"):SetSize(300, 150):Center():MakeTop()
				local text_sobre = loveframes.Create("label", frame_sobre)
				text_sobre:SetText("Lufia UI Menubar Demo\nCriado com sucesso!")
				text_sobre:SetPos(15, 45)
			end
		},
	})

	-- Frame principal que hospeda todas as abas de teste.
	local frame = loveframes.Create("frame")
	frame:SetName("LoveFrames - Banco de testes de UI")
	frame:SetSize(850, 650)
	frame:Center()
	frame:SetDraggable(true)
	frame:SetResizable(false)

	local tabs = loveframes.Create("tabs", frame)
	tabs:SetPos(5, 30)
	tabs:SetSize(840, 610)

	buildButtonsTab(tabs)
	buildInputsTab(tabs)
	buildSlidersTab(tabs)
	buildListsTab(tabs)
	buildLayoutTab(tabs)
	buildComboTab(tabs)
	buildColorPickerTab(tabs)
	buildGraphTab(tabs)
	buildFileBrowserTab(tabs)

	--tabs:SwitchToTab(6)

	-- Barra de status compartilhada (mostra a ultima interacao).
	widgets.status = loveframes.Create("label")
	widgets.status:SetPos(10, love.graphics.getHeight() - 24)
	widgets.status.defs = {
		color = { 0.0, 0.0, 0.0, 1.0 },
		padding = 2,
		spacing = 4,
	}
	widgets.status.OldSetText = widgets.status.SetText
	widgets.status.SetText = function(obj, message)
		loveframes.PushMessage(message, widgets.status.defs)
		widgets.status:OldSetText(message)
	end
	widgets.status:OldSetText("Pronto. Interaja com os elementos acima.")
	loveframes.toast:SetRelativeBoxWidth(0.3)
	loveframes.toast:SetMessageOrder("descending")
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
