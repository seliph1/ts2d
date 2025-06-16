-- Enum
-------------------------------------------------------------------
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


	local resolution_option = {
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
	
	local editor_default_size = 600
	local editor_default_width = 32*6
	
	local tool_option = {
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

	local editor_frame = loveframes.Create("frame")
	editor_frame:SetName("Editor")
	editor_frame:SetSize(editor_default_width+10, editor_default_size)
	editor_frame:SetResizable(false)
	editor_frame:ShowCloseButton(false)
	editor_frame:SetScreenLocked(true)
	
		local tabs = loveframes.Create("tabs",editor_frame)
		tabs:SetPos(5, 150)
		tabs:SetSize(editor_default_width, editor_default_size-150)
		
		
			local tile_panel = loveframes.Create("list")
			tile_panel:EnableHorizontalStacking(true)
			tile_panel.Select = function(object)
				local tile_id = object:GetProperty("tile_id")
				if tile_id then
					mapdata_setpencil(tile_id)
					print(string.format("Tile ID selected: %s ", tile_id))
				end
			end
			tile_panel.Hovering = function(object)
				if object.hover then
					love.graphics.setColor(1, 1, 1, 0.2)
					love.graphics.rectangle("fill", object.x, object.y, 32, 32)
				end	
			end
			
			tile_panel.Fill = function(object)
				for i = 0, 255 do 
					local gfx = mapfile_gfx("tile", i)
					if gfx then
						local tile = loveframes.Create("imagelink")
						--local tile = loveframes.Create("button")
						tile:SetProperty("tile_id", i)
						--tile:SetText(i):SetSize(32,32)
						tile:SetImage(gfx)
						--tile.groupIndex = 1
						
						tile.OnClick = tile_panel.Select
						tile.DrawOver = tile_panel.Hovering
						
						
						tile_panel:AddItem(tile)
					end	
				end
			end
			tile_panel:Fill()
			
			local entity_panel = loveframes.Create("columnlist")
			entity_panel:AddColumn("ID")
			entity_panel:AddColumn("Typename")
			entity_panel:SetColumnWidth(1, 20)
			entity_panel:SetColumnWidth(2, editor_default_width-40)
			entity_panel:SetColumnResizeEnabled(bool)
			for k,v in pairs(ENTITY_TYPE) do
				entity_panel:AddRow(k,v)
			end
			
			
			local tools = loveframes.Create("panel")
		
		tabs:AddTab("Tileset", tile_panel, "Tileset containing all individual tiles\nto paint into the map")
		tabs:AddTab("Entity", entity_panel, "Entity list containing all objects, buildings and NPCs\nthat can be added in the map")
		tabs:AddTab("Tools", tools, "Map editor tools for measuring and changing terrain")
		
	
		local map_path = loveframes.Create("textinput", editor_frame)
		map_path:SetText("maps/fun_roleplay.map")
		--map_path:SetText("maps/de_dust.map")
		map_path:SetPos(5, 30):SetWidth(192)
		--map_path:SetMultiline(true)
		--map_path:SetHeight(90)
		--[[
		local map_path_input_menu = loveframes.Create("menu", editor_frame)
		map_path_input_menu:AddOption("Copy")
		map_path_input_menu:AddOption("Paste")
		map_path_input_menu:SetVisible(false)
		--]]
		
		
		local pencil_mode = loveframes.Create("multichoice", editor_frame)
		pencil_mode:SetPos(75, 90):SetWidth(80)
		for k, v in pairs(tool_option) do
			pencil_mode:AddChoice(k)
		end	
		pencil_mode:SetChoice("Pencil")
		pencil_mode.OnChoiceSelected = function(object, choice)
			local mode = tool_option[choice] or "pencil"
			mapdata_toolmode(mode)
		end
		
		local pencil_label = loveframes.Create("label", editor_frame)
		pencil_label:SetPos(5, 95):SetText("Tool Mode: ")
		
		
		local savebutton = loveframes.Create("button", editor_frame)
		savebutton:SetText("Save")
		savebutton:SetWidth(40)
		savebutton:SetPos(map_path:GetWidth() + 10, 30)
		savebutton:SetPos(50, 60)
		savebutton:SetEnabled(false)
		savebutton.OnClick = function(object)
			--tile_panel.refresh()
		end
	
		local loadbutton = loveframes.Create("button", editor_frame)
		loadbutton:SetText("Load")
		loadbutton:SetWidth(40)
		loadbutton:SetPos(5, 60)
		loadbutton.OnClick = function(object)
			local path = map_path:GetText()
		
			mapfile_read(path)
			
			tile_panel:Clear()
			tile_panel:Fill()
		end
		
		local settings_panel = loveframes.Create("frame")
		settings_panel:SetVisible(false)
		settings_panel.OnClose = function(object)
			object:SetVisible(false)
			return false
		end
		
		
		local settingsbutton = loveframes.Create("button", editor_frame)
		settingsbutton:SetWidth(60)
		settingsbutton:SetText("Settings")
		settingsbutton:SetPos(95, 60)
		settingsbutton:SetProperty("target", settings_panel)
		settingsbutton.OnClick = function(object)
			local target = object:GetProperty("target")
			target:SetVisible(true)
			target:Center()
		end



		local resolution_picker = loveframes.Create("multichoice", settings_panel)
		resolution_picker:SetPos(80, 30)
		resolution_picker:SetWidth(80)
		for k, v in pairs(resolution_option) do
			resolution_picker:AddChoice(k)
		end	
		resolution_picker:SetChoice("800x600")
		resolution_picker.OnChoiceSelected = function(object, choice)
			local width, height = unpack(resolution_option[choice])
				
			love.window.setMode(width, height)
			editor_frame:SetMaxHeight(height)
			editor_frame:SetHeight(height)
			editor_frame:SetPos(0,0)
		end
		
		local resolution_label = loveframes.Create("label",settings_panel)
		resolution_label:SetText("Resolution: ")
		resolution_label:SetPos(10, 35)
		
		--[[
		local shadow_update = loveframes.Create("button", settings_panel)
		shadow_update:SetPos(10, 65)
		shadow_update.OnClick = function(object)
			mapdata_shadow_refresh()
		end--]]
		

		local entity_icon_render = checkbox