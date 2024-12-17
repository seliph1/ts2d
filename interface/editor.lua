

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

-- Widgets
-------------------------------------------------------------------

	local editor_frame = loveframes.Create("frame")
	editor_frame:SetName("Editor")
	editor_frame:SetSize(320, love.graphics.getHeight())
	editor_frame:SetResizable(false)
	editor_frame:ShowCloseButton(false)
	editor_frame:SetScreenLocked(true)
	
	
		local resolution_picker = loveframes.Create("multichoice", editor_frame)
		resolution_picker:SetPos(5, 60)
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
		
	
		local tabs = loveframes.Create("tabs",editor_frame)
		tabs:SetPos(5, 120)
		tabs:SetSize(32*8, 480)

			local settings_panel = loveframes.Create("panel")
			local tools_panel = loveframes.Create("panel")
			local tile_panel = loveframes.Create("list")

			tile_panel:EnableHorizontalStacking(true)
			tile_panel.Fill = function(object)
				for i=0, 255 do 
					local gfx = mapfile.gfx.tile[i]
					if gfx then
						local tile = loveframes.Create("image")
						tile:SetImage(gfx)
						tile_panel:AddItem(tile)
					end	
				end
			end
			tile_panel:Fill()
			

			local entity_panel = loveframes.Create("columnlist")
			--local entity_panel = loveframes.Create("list")
			entity_panel:AddColumn("Entity ID")
			entity_panel:AddColumn("Entity typename")
			
			for k,v in pairs(ENTITY_TYPE) do
				entity_panel:AddRow(k,v)
				--local entry = loveframes.Create("text")
				--entry:SetText(v)
				--entity_panel:AddItem(entry)
			end
			
		tabs:AddTab("Tileset", tile_panel)
		tabs:AddTab("Entity", entity_panel)
		tabs:AddTab("Settings", settings_panel)
		tabs:AddTab("Tools", tools_panel)
		
		
	
		local map_path = loveframes.Create("textinput", editor_frame)
		map_path:SetText("maps/fun_roleplay.map")
		map_path:SetPos(5, 30)
		--map_path:SetMultiline(true)
		--map_path:SetHeight(90)

		local savebutton = loveframes.Create("button", editor_frame)
		savebutton:SetText("Save")
		savebutton:SetWidth(30)
		savebutton:SetPos(map_path:GetWidth() + 10, 30)
		savebutton.OnClick = function(object)
			--tile_panel.refresh()
		end
	
		local loadbutton = loveframes.Create("button", editor_frame)
		loadbutton:SetText("Load")
		loadbutton:SetWidth(30)
		loadbutton:SetPos(map_path:GetWidth() + 45, 30)
		loadbutton.OnClick = function(object)
			local path = map_path:GetText()
		
			mapfile_read(path)
			
			tile_panel:Clear()
			tile_panel:Fill()
			cam_x, cam_y = 0, 0
		end
