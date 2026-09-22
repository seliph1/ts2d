local loveframes = require "lib.loveframes"
local client = require "core.client"
local Entities = require "core.entities"
local editor = {}

local ENTITY_TYPE = Entities.dump()

editor.resolution_option = {
	["640x480"] = { 640, 480 },
	["850x480"] = { 850, 480 },
	["800x600"] = { 800, 600 },
	["1060x600"] = { 1060, 600 },
	["1024x768"] = { 1024, 768 },
	["1280x720"] = { 1280, 720 },
	["1280x960"] = { 1280, 960 },
	["1360x768"] = { 1360, 768 },
	["1440x900"] = { 1440, 900 },
	["1600x900"] = { 1600, 900 },
	["1920x1080"] = { 1920, 1080 },
}

editor.default_size = 600
editor.default_width = 32 * 6

editor.tool_option = {
	["Rectangle"] = "rectangle",
	["Pencil"] = "pencil",
	["Color Fill"] = "colorfill",
	["Select"] = "select",
	["Measure"] = "measure",
	["Pathfinder"] = "path",
	["Blend"] = "blend",
}

-- Widgets
-------------------------------------------------------------------
editor.frame = loveframes.Create("frame")
editor.frame:SetName("Editor")
editor.frame:SetState("editor")
editor.frame:SetSize(editor.default_width + 10, editor.default_size)
editor.frame:SetResizable(false)
editor.frame:ShowCloseButton(false)
editor.frame:SetScreenLocked(true)
editor.tabs = loveframes.Create("tabs", editor.frame)
editor.tabs:SetPos(5, 150)
editor.tabs:SetSize(editor.default_width, editor.default_size - 150)

editor.entity_scrollable = loveframes.Create("scrollpanel"):SetSize(190, 423)
editor.entity_panel = loveframes.Create("droplist", editor.entity_scrollable):SetWidth(190)
for id, data in pairs(ENTITY_TYPE) do
	editor.entity_panel:AddItem(data.name)
end
editor.entity_panel:Sort()

editor.tools = loveframes.Create("panel")
--editor.tabs:AddTab("Tileset", editor.tile_panel, "Tileset containing all individual tiles\nto paint into the map")
-- , "Entity list containing all objects, buildings and NPCs\nthat can be added in the map"
-- , "Map editor tools for measuring and changing terrain"
editor.tabs:AddTab("Entity", editor.entity_scrollable)
editor.tabs:AddTab("Tools", editor.tools)

editor.open_map_dialog = function()
	loveframes.CreateFileDialog(
		"Selecionar Mapa",
		"open",
		{ "Mapas (*.map)" },
		function(filepath)
			editor.map_path:SetText(filepath)
			if client.map then
				local status = client.map:read(filepath)
				if status then
					print(status)
				else
					client.camera_snap(0, 0)
					client.map:shiftRender()
				end
			end
		end,
		function()
			-- Diálogo cancelado
		end,
		"maps"
	)
end

editor.map_path = loveframes.Create("textbox", editor.frame)
editor.map_path:SetText("maps/fun_roleplay.map")
editor.map_path:SetPos(5, 30):SetWidth(155)

editor.browsebutton = loveframes.Create("button", editor.frame)
editor.browsebutton:SetText("...")
editor.browsebutton:SetPos(164, 30):SetSize(33, 20)
editor.browsebutton:SetTooltip("Selecionar mapa...")
editor.browsebutton.OnClick = function(object)
	editor.open_map_dialog()
end

editor.loadbutton = loveframes.Create("button", editor.frame)
editor.loadbutton:SetText("Load")
editor.loadbutton:SetWidth(58)
editor.loadbutton:SetPos(5, 58)
editor.loadbutton.OnClick = function(object)
	local path = editor.map_path:GetText()
	if client.map then
		local status = client.map:read(path)
		if status then
			print(status)
		else
			client.camera_snap(0, 0)
			client.map:shiftRender()
		end
	end
end

editor.savebutton = loveframes.Create("button", editor.frame)
editor.savebutton:SetText("Save")
editor.savebutton:SetWidth(58)
editor.savebutton:SetPos(68, 58)
editor.savebutton:SetEnabled(false)
editor.savebutton.OnClick = function(object)
	--tile_panel.refresh()
end

editor.settingsbutton = loveframes.Create("button", editor.frame)
editor.settingsbutton:SetWidth(66)
editor.settingsbutton:SetText("Settings")
editor.settingsbutton:SetPos(131, 58)
editor.settingsbutton:SetProperty("target", editor.settings_panel)
editor.settingsbutton.OnClick = function(object)
	--local target = object:GetProperty("target")
	--target:SetVisible(true)
	--target:Center()
end

editor.exitbutton = loveframes.Create("button", editor.frame)
editor.exitbutton:SetText("Exit")
editor.exitbutton:SetWidth(58)
editor.exitbutton:SetPos(5, 85)
function editor.exitbutton:OnClick()
	client.scene.switch("lobby")
end

-- ===================================================================
-- Inspetor de Entidades & Seleção no Editor (Singleton)
-- ===================================================================

-- Entidade atualmente selecionada no editor (referência direta do mapa)
editor.selected_entity = nil

-- Referências singleton para a janela e o painel de rolagem do LoveFrames
editor.inspector_frame = nil
editor.inspector_scroll = nil

-- Dicionários auxiliares para exibir nomes amigáveis em vez de IDs numéricos brutos
local BUTTON_TYPES = {
	[0] = "None/Invisible",
	[1] = "Gray+Broad",
	[2] = "Gray+Small",
	[3] = "Black",
	[4] = "Knob",
	[5] = "Red+Small",
	[6] = "Pipe+Valve",
	[7] = "Glass Covered",
	[8] = "Valve",
	[9] = "Lever A",
	[10] = "Lever B",
	[11] = "Lighted Red",
	[12] = "Lighted Green",
	[13] = "Lighted Blue",
	[14] = "Lighted Yellow",
	[15] = "Lighted White",
	[16] = "Red Lighted Alarm",
	[17] = "Green Lighted Alarm",
}

local ALIGNMENT_NAMES = {
	[0] = "Top (0)",
	[1] = "Bottom (1)",
	[2] = "Left (2)",
	[3] = "Right (3)",
}

local TEAM_NAMES = {
	[0] = "Everyone (0)",
	[1] = "Terrorists (1)",
	[2] = "Counter-Terrorists (2)",
}

local DYNWALL_BEHAVIORS = {
	[0] = "Wall (0)",
	[1] = "Obstacle (1)",
	[2] = "Wall w/o Shdw. (2)",
	[3] = "Obstacle w/o Shdw. (3)",
	[4] = "Floor+Tile Behavior (4)",
}

--- Garante que a janela do inspetor exista como Singleton.
--- Cria o frame e o scrollpanel apenas uma vez durante a execução.
--- Ao fechar (OnClose), a janela apenas é ocultada (SetVisible(false)),
--- preservando sua posição e evitando a criação de múltiplas janelas na tela.
---@return table frame O objeto frame do LoveFrames
---@return table scroll O objeto scrollpanel filho do frame
local function ensure_inspector_frame()
	-- Se já foi instanciada anteriormente, retorna a mesma janela e scrollpanel
	if editor.inspector_frame then
		return editor.inspector_frame, editor.inspector_scroll
	end

	-- Dimensões e posicionamento inicial padrão (canto superior direito)
	local frame_w = 330
	local frame_h = math.min(520, love.graphics.getHeight() - 40)
	local pos_x = math.max(215, love.graphics.getWidth() - frame_w - 15)
	local pos_y = 25

	-- Cria a janela principal do LoveFrames
	local frame = loveframes.Create("frame")
	frame:SetName("Entity Inspector")
	frame:SetSize(frame_w, frame_h)
	frame:SetPos(pos_x, pos_y)
	frame:SetDraggable(true)
	frame:ShowCloseButton(true)
	frame:SetState("editor") -- Só desenha no estado "editor" do LoveFrames
	frame:SetVisible(false)  -- Inicia oculta até o primeiro clique em uma entidade

	-- Callback ao clicar no botão "X" de fechar a janela:
	-- Retornar `false` avisa o LoveFrames para NÃO destruir o objeto, apenas ocultamos
	frame.OnClose = function(self)
		self:SetVisible(false)
		editor.selected_entity = nil
		return false
	end

	-- Cria a área de rolagem interna para acomodar todos os campos de atributos
	local scroll = loveframes.Create("scrollpanel", frame)
	scroll:SetPos(5, 30)
	scroll:SetSize(frame_w - 10, frame_h - 35)

	-- Guarda as referências no módulo editor
	editor.inspector_frame = frame
	editor.inspector_scroll = scroll
	return frame, scroll
end

--- Oculta a janela de inspeção e desmarca a entidade selecionada (ex: ao sair da cena do editor)
function editor.close_inspector()
	if editor.inspector_frame then
		editor.inspector_frame:SetVisible(false)
	end
	editor.selected_entity = nil
end

--- Renderiza o feedback visual da entidade selecionada no canvas do mapa.
--- Desenha uma borda ciano pulsante com cantoneiras destacadas ao redor do tile da entidade.
---@param client table Instância do cliente do jogo
function editor.draw_selection(client)
	local e = editor.selected_entity
	if not e or not client or not client.map then return end

	-- Considera o deslocamento da câmera do mapa no modo editor
	local cx, cy = client.map:getCameraOffset()
	love.graphics.push()
	love.graphics.translate(cx, cy)

	-- Efeito de pulso ciano animado via seno do tempo decorrido
	local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 8)
	love.graphics.setColor(1, 1, 0, pulse)
	love.graphics.setLineWidth(2)

	local x1 = e.x * 32 - 2
	local y1 = e.y * 32 - 2
	local size = 36
	
	-- Cantoneiras nos quatro cantos da caixa de seleção
	local c = 6
	local x2, y2 = x1 + size, y1 + size
	love.graphics.line(x1, y1, x1 + c, y1)
	love.graphics.line(x1, y1, x1, y1 + c)
	love.graphics.line(x2, y1, x2 - c, y1)
	love.graphics.line(x2, y1, x2, y1 + c)
	love.graphics.line(x1, y2, x1 + c, y2)
	love.graphics.line(x1, y2, x1, y2 - c)
	love.graphics.line(x2, y2, x2 - c, y2)
	love.graphics.line(x2, y2, x2, y2 - c)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
end

--- Localiza uma entidade nas coordenadas do mundo clicadas.
--- Valida tanto o tile exato (32x32) quanto uma distância radial de até 24px do centro do ícone.
--- Se houver entidades sobrepostas no mesmo tile, cliques repetidos alternam entre elas.
---@param client table
---@param world_x number Coordenada X no espaço do mapa
---@param world_y number Coordenada Y no espaço do mapa
---@return table? entity A entidade encontrada ou nil
function editor.find_entity_at(client, world_x, world_y)
	if not client or not client.map then return nil end
	local entities = client.map:getEntities()
	if not entities or #entities == 0 then return nil end

	local tx = math.floor(world_x / 32)
	local ty = math.floor(world_y / 32)

	-- Coleta todas as entidades candidatas sob o cursor
	local candidates = {}
	for i = 1, #entities do
		local e = entities[i]
		local icon_cx = e.x * 32 + 16
		local icon_cy = e.y * 32 + 16
		local dx = world_x - icon_cx
		local dy = world_y - icon_cy
		local dist = math.sqrt(dx * dx + dy * dy)

		if (e.x == tx and e.y == ty) or dist <= 24 then
			table.insert(candidates, { entity = e, dist = dist })
		end
	end

	if #candidates == 0 then return nil end
	-- Ordena candidatos pela menor distância em relação ao cursor
	table.sort(candidates, function(a, b) return a.dist < b.dist end)

	-- Se a entidade já selecionada estiver entre as candidatas, alterna para a próxima entidade da lista
	if #candidates > 1 and editor.selected_entity then
		for idx, cand in ipairs(candidates) do
			if cand.entity == editor.selected_entity then
				local next_idx = (idx % #candidates) + 1
				return candidates[next_idx].entity
			end
		end
	end

	return candidates[1].entity
end

--- Manipulador de clique do mouse na cena do editor de mapas.
--- Converte coordenadas de tela/canvas para coordenadas de mapa e processa a seleção.
---@param client table
---@param x number
---@param y number
---@param button number Botão do mouse pressionado (1 = esquerdo)
---@return boolean handled Retorna true se o clique selecionou uma entidade
function editor.mousepressed(client, x, y, button, istouch, presses)
	if not client or not client.map then return false end

	local mx, my = x, y
	-- Aplica correção de aspect ratio/escala de tela quando o canvas do cliente estiver escalado
	if client.scale then
		local ox = 0.5 * (love.graphics.getWidth() - client.width)
		local oy = 0.5 * (love.graphics.getHeight() - client.height)
		local sx = love.graphics.getWidth() / client.width
		local sy = love.graphics.getHeight() / client.height
		mx = (x + ox) / sx
		my = (y + oy) / sy
	end

	-- Converte coordenadas de mouse na janela para coordenadas absolutas no mapa
	local world_x, world_y = client.map:mouseToMap(mx, my)
	local clicked = editor.find_entity_at(client, world_x, world_y)
	if clicked then
		-- Se clicou na mesma entidade e o inspetor já está visível com seus dados, evita reconstruir a UI desnecessariamente
		if clicked == editor.selected_entity and editor.inspector_frame and editor.inspector_frame.visible then
			return true
		end
		editor.selected_entity = clicked
		editor.open_inspector(clicked)
		return true
	end
	return false
end

--- Abre ou atualiza a janela Singleton do inspetor com os atributos da entidade especificada.
--- Reutiliza o frame existente, mantendo sua posição na tela, e recria apenas os widgets de dados.
---@param e table Tabela da entidade a inspecionar
function editor.open_inspector(e)
	if not e then return end

	-- Garante que a janela singleton e seu scrollpanel existam
	local frame, scroll = ensure_inspector_frame()

	-- Limpa os filhos anteriores do painel de rolagem para evitar vazamento de memória e sobreposição
	if scroll.children then
		for i = #scroll.children, 1, -1 do
			local child = scroll.children[i]
			if child and child.Remove then
				child:Remove()
			end
		end
	end
	scroll:Clear()
	scroll.offsety = 0 -- Retorna a rolagem para o início

	-- Consulta os metadados cadastrados no banco de dados de entidades
	local db_info = Entities.Database.get(e.type)
	local type_name = db_info.name or ("Type " .. tostring(e.type))
	local type_desc = db_info.description or ""
	local type_cat = db_info.category or "unknown"
	local title_text = string.format("Entity: %s (#%d)", type_name, e.index or 0)

	-- Atualiza o título do frame para a nova entidade
	frame:SetName(title_text)
	if not frame.visible then
		frame:SetVisible(true)
		frame:MakeTop()
	end
	frame:SetState("editor")

	-- Tabela acumuladora para adicionar todos os novos widgets em lote
	local items_to_add = {}

	-- Controle do cursor vertical dentro do painel de rolagem
	local curr_y = 5

	-- Helper para adicionar cabeçalhos visuais de seção
	local function add_section(title)
		local l = loveframes.Create("label")
		l:SetText("--- " .. title .. " ---")
		l:SetPos(10, curr_y)
		table.insert(items_to_add, l)
		curr_y = curr_y + 20
	end

	-- Helper para adicionar linhas de texto informativas (somente leitura)
	local function add_info(title, val)
		local l = loveframes.Create("label")
		l:SetText(title .. ": " .. tostring(val or ""))
		l:SetPos(10, curr_y)
		table.insert(items_to_add, l)
		curr_y = curr_y + 18
	end

	-- Helper para adicionar campos editáveis com caixa de texto e callback OnTextChanged
	local function add_field(title, val, on_change)
		local l = loveframes.Create("label")
		l:SetText(title .. ":")
		l:SetPos(10, curr_y)
		table.insert(items_to_add, l)
		curr_y = curr_y + 16

		local tb = loveframes.Create("textbox")
		tb:SetPos(10, curr_y)
		tb:SetSize(scroll:GetWidth() - 30, 22)
		tb:SetText(tostring(val or ""))
		tb.OnTextChanged = function(object, text)
			if on_change then on_change(text) end
		end
		table.insert(items_to_add, tb)
		curr_y = curr_y + 28
	end

	-- 1. Seção: Identidade & Localização no Mapa
	add_section("Identity & Location")
	add_info("Type", string.format("%d (%s)", e.type, type_name))
	add_info("Category", type_cat)
	if type_desc ~= "" then
		add_info("Description", type_desc)
	end
	add_info("Tile Position", string.format("X: %d, Y: %d", e.x, e.y))
	add_info("Pixel Position", string.format("X: %d, Y: %d", e.x * 32, e.y * 32))

	-- 2. Seção: Atributos Principais (Name, Trigger alvo e Status)
	add_section("Core Attributes")
	add_field("Name (Identifier)", e.name, function(val)
		e.name = val
		-- Sincroniza o novo identificador no índice de busca por nome do mapa
		if client.map and client.map._mapdata and client.map._mapdata.trigger_index then
			local t_idx = client.map._mapdata.trigger_index
			t_idx[val] = t_idx[val] or {}
			local already = false
			for _, obj in ipairs(t_idx[val]) do
				if obj == e then already = true; break end
			end
			if not already then table.insert(t_idx[val], e) end
		end
	end)

	add_field("Trigger (Target Name)", e.trigger, function(val)
		e.trigger = val
	end)

	add_info("Status", string.format("state=%s, disabled=%s", tostring(e.state), tostring(e.disabled)))

	-- 3. Seção: Parâmetros definidos pelo Schema da entidade
	local schema = db_info
	if schema and (schema.int_schema or schema.str_schema) then
		add_section("Parameters")
		-- Itera os parâmetros inteiros (int[1..10])
		if schema.int_schema then
			for idx = 1, 10 do
				local param_name = schema.int_schema[idx]
				if param_name then
					local current_num = (e.number_settings and e.number_settings[idx]) or 0
					local hint = ""
					-- Dicas amigáveis para botões de Trigger_Use
					if e.type == 93 then
						if idx == 1 then
							hint = " [" .. (BUTTON_TYPES[current_num] or tostring(current_num)) .. "]"
						elseif idx == 2 then
							hint = " [" .. (ALIGNMENT_NAMES[current_num] or tostring(current_num)) .. "]"
						elseif idx == 3 then
							hint = " [" .. (TEAM_NAMES[current_num] or tostring(current_num)) .. "]"
						end
					-- Dicas amigáveis de times para Trigger_Move / Trigger_Hit
					elseif e.type == 91 or e.type == 92 then
						if idx == 1 then
							hint = " [" .. (TEAM_NAMES[current_num] or tostring(current_num)) .. "]"
						end
					-- Dicas amigáveis para Func_DynWall
					elseif e.type == 71 then
						if idx == 2 then
							hint = " [" .. (DYNWALL_BEHAVIORS[current_num] or tostring(current_num)) .. "]"
						elseif idx == 3 then
							hint = " [" .. (current_num == 1 and "Close only if not blocked" or "Crush/Force Close") .. "]"
						end
					end

					add_field(param_name .. hint .. " (int[" .. idx .. "])", current_num, function(val)
						e.number_settings[idx] = tonumber(val) or 0
					end)
				end
			end
		end

		-- Itera os parâmetros de texto (str[1..10])
		if schema.str_schema then
			for idx = 1, 10 do
				local param_name = schema.str_schema[idx]
				if param_name then
					local current_str = (e.string_settings and e.string_settings[idx]) or ""
					add_field(param_name .. " (str[" .. idx .. "])", current_str, function(val)
						e.string_settings[idx] = val
					end)
				end
			end
		end
	end

	-- 4. Seção: Configurações Numéricas Adicionais (int[1..10] que não estão no schema mas têm valor)
	local has_raw_ints = false
	for idx = 1, 10 do
		if not (schema and schema.int_schema and schema.int_schema[idx]) and (e.number_settings and e.number_settings[idx] and e.number_settings[idx] ~= 0) then
			has_raw_ints = true
			break
		end
	end
	if has_raw_ints then
		add_section("Other Number Settings")
		for idx = 1, 10 do
			if not (schema and schema.int_schema and schema.int_schema[idx]) then
				local val = e.number_settings[idx] or 0
				if val ~= 0 then
					add_field("int[" .. idx .. "]", val, function(v)
						e.number_settings[idx] = tonumber(v) or 0
					end)
				end
			end
		end
	end

	-- 5. Seção: Configurações de String Adicionais (str[1..10] não mapeadas mas com texto preenchido)
	local has_raw_strs = false
	for idx = 1, 10 do
		if not (schema and schema.str_schema and schema.str_schema[idx]) and (e.string_settings and e.string_settings[idx] and e.string_settings[idx] ~= "") then
			has_raw_strs = true
			break
		end
	end
	if has_raw_strs then
		add_section("Other String Settings")
		for idx = 1, 10 do
			if not (schema and schema.str_schema and schema.str_schema[idx]) then
				local val = e.string_settings[idx] or ""
				if val ~= "" then
					add_field("str[" .. idx .. "]", val, function(v)
						e.string_settings[idx] = v
					end)
				end
			end
		end
	end

	-- Adiciona todos os widgets em lote no scrollpanel (garante que todos os itens fiquem dentro do scroll)
	if #items_to_add > 0 then
		if scroll.AddItemsFromTable then
			scroll:AddItemsFromTable(items_to_add)
		else
			for _, item in ipairs(items_to_add) do
				scroll:AddItem(item)
			end
		end
	end

	-- Força uma atualização imediata das posições e cache do scrollpanel
	-- Isso elimina qualquer frame intermediário sem layout, prevenindo qualquer 'flicker' visual
	scroll:update(0)
end

editor.frame:SetState("editor")
return editor
