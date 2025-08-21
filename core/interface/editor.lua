local loveframes = require "lib.loveframes"
local client = require "client"
local editor = {}

	local ENTITY_TYPE={};
	ENTITY_TYPE[0]="Info_T";
	ENTITY_TYPE[1]="Info_CT";
	ENTITY_TYPE[2]="Info_VIP";
	ENTITY_TYPE[3]="Info_Hostage";
	ENTITY_TYPE[4]="Info_RescuePoint";
	ENTITY_TYPE[5]="Info_BombSpot";
	ENTITY_TYPE[6]="Info_EscapePoint";
	ENTITY_TYPE[7]="Info_Target";
	ENTITY_TYPE[8]="Info_Animation";
	ENTITY_TYPE[9]="Info_Storm";
	ENTITY_TYPE[10]="Info_TileFX";
	ENTITY_TYPE[11]="Info_NoBuying";
	ENTITY_TYPE[12]="Info_NoWeapons";
	ENTITY_TYPE[13]="Info_NoFOW";
	ENTITY_TYPE[14]="Info_Quake";
	ENTITY_TYPE[15]="Info_CTF_Flag";
	ENTITY_TYPE[16]="Info_OldRender";
	ENTITY_TYPE[17]="Info_Dom_Point";
	ENTITY_TYPE[18]="Info_NoBuildings";
	ENTITY_TYPE[19]="Info_BotNode";
	ENTITY_TYPE[20]="Info_TeamGate";
	ENTITY_TYPE[21]="Env_Item";
	ENTITY_TYPE[22]="Env_Sprite";
	ENTITY_TYPE[23]="Env_Sound";
	ENTITY_TYPE[24]="Env_Decal";
	ENTITY_TYPE[25]="Env_Breakable";
	ENTITY_TYPE[26]="Env_Explode";
	ENTITY_TYPE[27]="Env_Hurt";
	ENTITY_TYPE[28]="Env_Image";
	ENTITY_TYPE[29]="Env_Object";
	ENTITY_TYPE[30]="Env_Building";
	ENTITY_TYPE[31]="Env_NPC";
	ENTITY_TYPE[32]="Env_Room";
	ENTITY_TYPE[33]="Env_Light";
	ENTITY_TYPE[34]="Env_LightStripe";
	ENTITY_TYPE[35]="Env_Cube3D";
	ENTITY_TYPE[50]="Gen_Particles";
	ENTITY_TYPE[51]="Gen_Sprites";
	ENTITY_TYPE[52]="Gen_Weather";
	ENTITY_TYPE[53]="Gen_FX";
	ENTITY_TYPE[70]="Func_Teleport";
	ENTITY_TYPE[71]="Func_DynWall";
	ENTITY_TYPE[72]="Func_Message";
	ENTITY_TYPE[73]="Func_GameAction";
	ENTITY_TYPE[80]="Info_NoWeather";
	ENTITY_TYPE[81]="Info_RadarIcon";
	ENTITY_TYPE[90]="Trigger_Start";
	ENTITY_TYPE[91]="Trigger_Move";
	ENTITY_TYPE[92]="Trigger_Hit";
	ENTITY_TYPE[93]="Trigger_Use";
	ENTITY_TYPE[94]="Trigger_Delay";
	ENTITY_TYPE[95]="Trigger_Once";
	ENTITY_TYPE[96]="Trigger_If"


	editor.resolution_option = {
		["640x480"] = {640, 480};
		["850x480"] = {850, 480};
		["800x600"] = {800, 600};
		["1060x600"] = {1060, 600};
		["1024x768"] = {1024, 768};
		["1280x720"] = {1280, 720};
		["1280x960"] = {1280, 960};
		["1360x768"] = {1360, 768};
		["1440x900"] = {1440, 900};
		["1600x900"] = {1600, 900};
		["1920x1080"] = {1920, 1080};
	}
	
	editor.default_size = 600
	editor.default_width = 32*6
	
	editor.tool_option = {
		["Rectangle"] = "rectangle";
		["Pencil"] = "pencil";
		["Color Fill"] = "colorfill";
		["Select"] = "select";
		["Measure"] = "measure";
		["Pathfinder"] = "path";
		["Blend"] = "blend";
	}

-- Widgets
-------------------------------------------------------------------
	editor.frame = loveframes.Create("frame")
	editor.frame:SetName("Editor")
	editor.frame:SetSize(editor.default_width + 10, editor.default_size)
	editor.frame:SetResizable(false)
	editor.frame:ShowCloseButton(false)
	editor.frame:SetScreenLocked(true)
		editor.tabs = loveframes.Create("tabs",editor.frame)
		editor.tabs:SetPos(5, 150)
		editor.tabs:SetSize(editor.default_width, editor.default_size-150)
			editor.tile_panel = loveframes.Create("list")
			editor.tile_panel:EnableHorizontalStacking(true)
			editor.tile_panel.Select = function(object)
				local tile_id = object:GetProperty("tile_id")
				if tile_id then
					--mapdata_setpencil(tile_id)
					print(string.format("Tile ID selected: %s ", tile_id))
				end
			end
			editor.tile_panel.Hovering = function(object)
				if object.hover then
					love.graphics.setColor(1, 1, 1, 0.2)
					love.graphics.rectangle("fill", object.x, object.y, 32, 32)
				end
			end
			editor.tile_panel.Fill = function(object)
				for i = 0, 255 do
                    local map = client.map
                    local gfx = map._mapdata.gfx.tile[i]
                    if gfx then
                        local tile = loveframes.Create("imagelink")
                        tile:SetProperty("tile_id", i)
                        tile:SetImage(gfx)
                        tile.OnClick = editor.tile_panel.Select
                        tile.DrawOver = editor.tile_panel.Hovering

                        editor.tile_panel:AddItem(tile)
                    end
				end
			end
			editor.tile_panel:Fill()
			editor.entity_panel = loveframes.Create("columnlist")
			editor.entity_panel:AddColumn("ID")
			editor.entity_panel:AddColumn("Typename")
			editor.entity_panel:SetColumnWidth(1, 20)
			editor.entity_panel:SetColumnWidth(2, editor.default_width-40)
			editor.entity_panel:SetColumnResizeEnabled(false)
			for k,v in pairs(ENTITY_TYPE) do
				editor.entity_panel:AddRow(k,v)
			end
			editor.tools = loveframes.Create("panel")
		editor.tabs:AddTab("Tileset", editor.tile_panel, "Tileset containing all individual tiles\nto paint into the map")
		editor.tabs:AddTab("Entity", editor.entity_panel, "Entity list containing all objects, buildings and NPCs\nthat can be added in the map")
		editor.tabs:AddTab("Tools", editor.tools, "Map editor tools for measuring and changing terrain")
        
		editor.map_path = loveframes.Create("textbox", editor.frame)
		editor.map_path:SetText("maps/fun_roleplay.map")
		editor.map_path:SetPos(5, 30):SetWidth(192)
		--map_path:SetMultiline(true)
		--map_path:SetHeight(90)
		--[[
		local map_path_input_menu = loveframes.Create("menu", editor_frame)
		map_path_input_menu:AddOption("Copy")
		map_path_input_menu:AddOption("Paste")
		map_path_input_menu:SetVisible(false)
		--]]
		editor.pencil_mode = loveframes.Create("multichoice", editor.frame)
		editor.pencil_mode:SetPos(80, 90):SetWidth(80)
		for k, v in pairs(editor.tool_option) do
			editor.pencil_mode:AddChoice(k)
		end	
		editor.pencil_mode:SetChoice("Pencil")
		editor.pencil_mode.OnChoiceSelected = function(object, choice)
			local mode = editor.tool_option[choice] or "pencil"
			--mapdata_toolmode(mode)
		end
		editor.pencil_label = loveframes.Create("label", editor.frame)
		editor.pencil_label:SetPos(5, 90+2):SetText("Tool Mode: ")
		--[[
		local pencil_button = loveframes.Create("button", editor_frame)
		pencil_button:SetPos(5,95):SetText("Pencil"):SetWidth(40)
		pencil_button.OnClick = function(object)
			mapdata_toolmode("pencil")
		end
		
		local rectangle_button = loveframes.Create("button", editor_frame)
		rectangle_button:SetPos(55,95):SetText("Rectangle"):SetWidth(40)
		rectangle_button.OnClick = function(object)
			mapdata_toolmode("rectangle")
		end
		
		
		local colorfill_button = loveframes.Create("button", editor_frame)
		colorfill_button:SetPos(105,95):SetText("Color Fill"):SetWidth(40)
		colorfill_button.OnClick = function(object)
			mapdata_toolmode("fill")
		end--]]
		editor.savebutton = loveframes.Create("button", editor.frame)
		editor.savebutton:SetText("Save")
		editor.savebutton:SetWidth(40)
		editor.savebutton:SetPos(editor.map_path:GetWidth() + 10, 30)
		editor.savebutton:SetPos(50, 60)
		editor.savebutton:SetEnabled(false)
		editor.savebutton.OnClick = function(object)
			--tile_panel.refresh()
		end
		editor.loadbutton = loveframes.Create("button", editor.frame)
		editor.loadbutton:SetText("Load")
		editor.loadbutton:SetWidth(40)
		editor.loadbutton:SetPos(5, 60)
		editor.loadbutton.OnClick = function(object)
			local path = editor.map_path:GetText()
        	if client.map then
				local status = client.map:read(path)
				if status then
					print(status)
				end
			end
			client.mode = "game"
    		editor.tile_panel:Clear()
			editor.tile_panel:Fill()
		end
		editor.settings_panel = loveframes.Create("frame")
		editor.settings_panel:SetVisible(false)
		editor.settings_panel.OnClose = function(object)
			object:SetVisible(false)
			return false
		end
		editor.settingsbutton = loveframes.Create("button", editor.frame)
		editor.settingsbutton:SetWidth(60)
		editor.settingsbutton:SetText("Settings")
		editor.settingsbutton:SetPos(95, 60)
		editor.settingsbutton:SetProperty("target", editor.settings_panel)
		editor.settingsbutton.OnClick = function(object)
			local target = object:GetProperty("target")
			target:SetVisible(true)
			target:Center()
		end
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
			editor.frame:SetPos(0,0)
		end
		editor.resolution_label = loveframes.Create("label", editor.settings_panel)
		editor.resolution_label:SetText("Resolution: ")
		editor.resolution_label:SetPos(10, 35)

return editor
