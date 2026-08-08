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

--[[
editor.resolution_picker = loveframes.Create("multichoice", editor.settings_panel)
editor.resolution_picker:SetPos(80, 30)
editor.resolution_picker:SetWidth(80)
for k, v in pairs(editor.resolution_option) do
	editor.resolution_picker:AddChoice(k)
end
editor.resolution_picker:SetChoice("800x600")
editor.resolution_picker.OnChoiceSelected = function(object, choice)
	local width, height = unpack(editor.resolution_option[choice])
	love.window.setMode(width, height)
	editor.frame:SetMaxHeight(height)
	editor.frame:SetHeight(height)
	editor.frame:SetPos(0, 0)
end
editor.resolution_label = loveframes.Create("label", editor.settings_panel)
editor.resolution_label:SetText("Resolution: ")
editor.resolution_label:SetPos(10, 35)
]]


editor.frame:SetState("editor")
return editor
