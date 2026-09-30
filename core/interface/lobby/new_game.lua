local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--New Game Frame----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.new_game_frame = LF.Create("frame"):SetName("Create Server"):SetSize(428, 460):SetCloseAction("hide")

ui.newgame_button_help = LF.Create("button", ui.new_game_frame):SetText("Help"):SetPos(0 + 10, 430):SetWidth(50)
ui.newgame_button_start = LF.Create("button", ui.new_game_frame):SetText("Start"):SetPos(195 + 10, 430):SetWidth(100)
ui.newgame_button_cancel = LF.Create("button", ui.new_game_frame):SetText("Cancel"):SetPos(300 + 10, 430):SetWidth(100)

-- Sobe um listen server (host local numa thread) e conecta no loopback.
ui.newgame_button_start.OnClick = function()
	local console = require "core.interface.console"
	local elements = ui.map_display_list:GetFilteredElements()
	local selected_id = ui.map_display_list.selected
	local selected = elements[selected_id]
	local map_name
	if selected then
		map_name = type(selected) == "table" and selected.text or selected
	end

	client.startListenServer(map_name)

	ui.new_game_frame:SetVisible(false)
	console.parse("connect 127.0.0.1 36963")
end
ui.newgame_button_cancel.OnClick = function()
	ui.new_game_frame:SetVisible(false)
end

ui.new_game_tabs = LF.Create("tabs", ui.new_game_frame):SetSize(418, 400):SetPos(10, 30)
--Tabs--------------------------------------------------------------------------------------------
ui.new_game_server = LF.Create("container"):SetPos(0, 30):SetSize(400, 400)
ui.new_game_map = LF.Create("container"):SetPos(0, 30):SetSize(400, 400)
ui.new_game_settings = LF.Create("container"):SetPos(0, 30):SetSize(400, 400)
ui.new_game_bots = LF.Create("container"):SetPos(0, 30):SetSize(400, 400)
ui.new_game_mods = LF.Create("container"):SetPos(0, 30):SetSize(400, 400)
ui.new_game_moresettings = LF.Create("container"):SetPos(0, 30):SetSize(400, 400)

ui.new_game_tabs:AddTab("Server", ui.new_game_server)
ui.new_game_tabs:AddTab("Map", ui.new_game_map)
ui.new_game_tabs:AddTab("Settings", ui.new_game_settings)
ui.new_game_tabs:AddTab("Bots", ui.new_game_bots)
ui.new_game_tabs:AddTab("Mods", ui.new_game_mods)
ui.new_game_tabs:AddTab("More Settings", ui.new_game_moresettings)
--Tab 1: Server-----------------------------------------------------------------------------------
ui.server_name_label = LF.Create("label", ui.new_game_server):SetPos(0, 0 + 4):SetText("Server Name:")
ui.server_password_label = LF.Create("label", ui.new_game_server):SetPos(0, 25 + 4):SetText("Server Password:")
ui.server_rcon_password_label = LF.Create("label", ui.new_game_server):SetPos(0, 50 + 4):SetText("RCon Password:")
ui.server_port_label = LF.Create("label", ui.new_game_server):SetPos(0, 75 + 4):SetText("Port (UDP):")
ui.server_maxplayers_label = LF.Create("label", ui.new_game_server):SetPos(0, 100 + 4):SetText("Max. Players:")
ui.server_fow_label = LF.Create("label", ui.new_game_server):SetPos(0, 125 + 4):SetText("Fog of War:")

ui.server_name_input = LF.Create("textbox", ui.new_game_server)
	:SetPos(150, 0 + 2):SetSize(150, 20):SetPlaceholderText("CS2D Server")

ui.server_password_input = LF.Create("textbox", ui.new_game_server)
	:SetPos(150, 25 + 2):SetSize(150, 20):SetType("password"):SetPasswordCharacter("•")
ui.server_rcon_password_input = LF.Create("textbox", ui.new_game_server)
	:SetPos(150, 50 + 2):SetSize(150, 20):SetType("password"):SetPasswordCharacter("•")

ui.server_port_input = LF.Create("textbox", ui.new_game_server):SetPos(150, 75 + 2):SetSize(100, 20)
	:SetUsable({ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }):SetCharacterLimit(5)

ui.server_max_players_numberbox = LF.Create("numberbox", ui.new_game_server):SetPos(150, 100 + 2):SetMinMax(0, 32)

ui.server_fow_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 125 + 2):SetSize(200, 20)
	:AddChoice("Off")
	:AddChoice("Hide characters only")
	:AddChoice("Hide characters and effects")
	:AddChoice("Hide everything")
	:SetChoice("Off")


ui.server_friendlyfire_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 150 + 2):SetText("Friendly Fire")
ui.server_hide_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 170 + 2):SetText(
	"Hide Server (unlisted)")
ui.server_usgnonly_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 190 + 2):SetText(
		"Registered U.S.G.N Users only")
	:SetEnabled(false)
ui.server_filetransfer_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 210 + 2):SetText(
	"Map and File Transfer")
ui.server_offscreendamage_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 230 + 2):SetText(
	"Off-Screen Damage")
ui.server_forcelightning_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 250 + 2):SetText(
	"Force Lightning")
ui.server_recoilaccuracy_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 270 + 2):SetText(
	"Recoil influences accuracy"):SetText(""):SetEnabled(false)

ui.server_voicechat_label = LF.Create("label", ui.new_game_server):SetPos(0, 290 + 4):SetText("Voice Chat:")
ui.server_gamemode_label = LF.Create("label", ui.new_game_server):SetPos(0, 315 + 4):SetText("Gamemode:")
ui.server_spectate_label = LF.Create("label", ui.new_game_server):SetPos(0, 340 + 4):SetText("Allow to Spectate: ")

ui.server_voicechat_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 290 + 2):SetSize(200, 20)
	:AddChoice("Disabled")
	:AddChoice("For All")
	:AddChoice("Team Only")
	:AddChoice("Team Only + Spectators")
	:SetChoice("Team Only")

ui.server_gamemode_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 315 + 2):SetSize(200, 20)
	:AddChoice("Standard")
	:AddChoice("Deathmatch")
	:AddChoice("Team Deathmatch")
	:AddChoice("Construction")
	:AddChoice("Zombies")
	:SetChoice("Standard")

ui.server_spectate_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 340 + 2):SetSize(200, 20)
	:AddChoice("Nothing (War Mode)")
	:AddChoice("Everything")
	:AddChoice("Own Team Only")
	:SetChoice("Own Team Only")

--Tab 2: Map--------------------------------------------------------------------------------------
ui.map_display_label = LF.Create("label", ui.new_game_map):SetText("Display: "):SetPos(0, 0 + 4)
ui.map_display_search_label = LF.Create("label", ui.new_game_map):SetText("Search: "):SetPos(0, 25 + 4)
ui.map_display_choice = LF.Create("multichoice", ui.new_game_map):SetPos(80, 0 + 2):SetWidth(300)
	:AddChoice("All Maps")
	:AddChoice("AS - Assassination")
	:AddChoice("CS - Hostage Rescue")
	:AddChoice("DE - Bomb Defuse")
	:AddChoice("DM - Deathmatch")
	:AddChoice("CTF - Capture The Flag")
	:AddChoice("DOM - Domination")
	:AddChoice("CON - Construction")
	:AddChoice("ZM - Zombie")
	:AddChoice("FY - Fight Yard")
	:AddChoice("HE - High Explosives")
	:AddChoice("KA - Knife Arena")
	:AddChoice("AWP - AWP Arena")
	:AddChoice("AIM - Aiming Training")
	:AddChoice("Other Maps")
	:SetChoice("All Maps")

ui.map_display_sort_button = LF.Create("button", ui.new_game_map):SetText("Sort Z-A"):SetPos(300, 25 + 2)
ui.map_display_sort_button.OnClick = function(object)
	if object.text == "Sort Z-A" then
		object:SetText("Sort A-Z")
		ui.map_display_list:Sort(function(a, b) return a > b end)
	elseif object.text == "Sort A-Z" then
		object:SetText("Sort Z-A")
		ui.map_display_list:Sort(function(a, b) return a < b end)
	end
end

ui.map_display_pane = LF.Create("scrollpanel", ui.new_game_map):SetPos(0, 50 + 4):SetSize(406, 304)
ui.map_display_list = LF.Create("droplist", ui.map_display_pane)
	:SetSize(406, 304):SetZebra(true):SetPadding(0)
local elements = {}
for _, name in pairs(love.filesystem.getDirectoryItems("maps")) do
	if name:find("%.map$") then
		table.insert(elements, name)
	end
end
ui.map_display_list:AddElementsFromTable(elements)

ui.map_display_search_bar = LF.Create("textbox", ui.new_game_map):SetPos(80, 25 + 2):SetSize(200, 20)
ui.map_display_search_bar.OnTextChanged = function(self, text)
	ui.map_display_list:SetFilter(text)
end

--Tab 3: Settings--------------------------------------------------------------------------------------
ui.settings_timepermap = LF.Create("label", ui.new_game_settings):SetPos(0, 0 + 4):SetText("Time per Map (Min.):")
ui.settings_winlimit = LF.Create("label", ui.new_game_settings):SetPos(0, 25 + 4):SetText("Win Limit (Rounds):")
ui.settings_roundlimit = LF.Create("label", ui.new_game_settings):SetPos(0, 50 + 4):SetText("Round Limit (Rounds):")
ui.settings_timeperround = LF.Create("label", ui.new_game_settings):SetPos(0, 75 + 4):SetText("Time per Round (Min.):")
ui.settings_freezetime = LF.Create("label", ui.new_game_settings):SetPos(0, 100 + 4):SetText("Freeze Time (Sec.):")
ui.settings_buytime = LF.Create("label", ui.new_game_settings):SetPos(0, 125 + 4):SetText("Buy Time (Min.):")
ui.settings_startmoney = LF.Create("label", ui.new_game_settings):SetPos(0, 150 + 4):SetText("Start Money:")
ui.settings_kickafterxteamkills = LF.Create("label", ui.new_game_settings):SetPos(0, 200 + 4):SetText(
	"Kick after X Team Kills:")
ui.settings_kickafterxhostagekills = LF.Create("label", ui.new_game_settings):SetPos(0, 225 + 4):SetText(
	"Kick after X Hostage Kills:")

ui.settings_timepermap_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 0 + 4):SetHeight(20):SetMin(0):SetStepAmount(1)
ui.settings_winlimit_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 25 + 4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_roundlimit_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 50 + 4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_timeperround_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 75 + 4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_freezetime_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 100 + 4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_buytime_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 125 + 4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_startmoney_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 150 + 4):SetHeight(20):SetMinMax(0, 16000):SetStepAmount(1000)
ui.settings_kickafterxteamkills_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 200 + 4):SetMin(0):SetHeight(20)
ui.settings_kickafterxhostagekills_textbox = LF.Create("numberbox", ui.new_game_settings)
	:SetPos(200, 225 + 4):SetMin(0):SetHeight(20)
ui.settings_killteamkiller_checkbox = LF.Create("checkbox", ui.new_game_settings)
	:SetPos(200, 260 + 4):SetText("Kill TKer on next Round")
ui.settings_kickidlers_checkbox = LF.Create("checkbox", ui.new_game_settings)
	:SetPos(200, 280 + 4):SetText("Kick Idlers (or other action)")
ui.settings_vulnerablehostages_checkbox = LF.Create("checkbox", ui.new_game_settings)
	:SetPos(200, 300 + 4):SetText("Hostages are vulnerable")
ui.settings_autoteambalance_checkbox = LF.Create("checkbox", ui.new_game_settings)
	:SetPos(200, 320 + 4):SetText("Auto Teambalance")
ui.settings_spectatemouse_checkbox = LF.Create("checkbox", ui.new_game_settings)
	:SetPos(200, 340 + 4):SetText("Spectate mouse")

--Tab 4: Bots--------------------------------------------------------------------------------------
ui.bots_prefix_label = LF.Create("label", ui.new_game_bots):SetPos(0, 0 + 4):SetText("Bot Name Prefix: ")
ui.bots_amount_label = LF.Create("label", ui.new_game_bots):SetPos(0, 25 + 4):SetText("Bots:")
ui.bots_jointeam_label = LF.Create("label", ui.new_game_bots):SetPos(0, 100 + 4):SetText("Join Team:")
ui.bots_skills_label = LF.Create("label", ui.new_game_bots):SetPos(0, 175 + 4):SetText("Skills:")
ui.bots_weapons_label = LF.Create("label", ui.new_game_bots):SetPos(0, 200 + 4):SetText("Weapons:")

ui.bots_prefix_textbox = LF.Create("textbox", ui.new_game_bots):SetPos(150, 0 + 4):SetSize(150, 20)
ui.bots_amount_textbox = LF.Create("numberbox", ui.new_game_bots):SetPos(150, 25 + 4)

ui.bots_team_radiogroup = {}
ui.bots_both_radiobutton = LF.Create("radiobutton", ui.new_game_bots)
	:SetPos(150, 100 + 4):SetText("Both"):SetGroup(ui.bots_team_radiogroup)
ui.bots_tr_radiobutton = LF.Create("radiobutton", ui.new_game_bots)
	:SetPos(150, 120 + 4):SetText("Terrorists"):SetGroup(ui.bots_team_radiogroup)
ui.bots_ct_radiobutton = LF.Create("radiobutton", ui.new_game_bots)
	:SetPos(150, 140 + 4):SetText("Counter-Terrorists"):SetGroup(ui.bots_team_radiogroup)
ui.bots_both_radiobutton:SetChecked(true)

ui.bots_autofill = LF.Create("checkbox", ui.new_game_bots):SetPos(150, 50 + 4):SetText("Auto Fill")
ui.bots_keepfreeslots = LF.Create("checkbox", ui.new_game_bots):SetPos(150, 70 + 4):SetText(
	"Keep free slots for joining")

ui.bots_skills_option = LF.Create("multichoice", ui.new_game_bots):SetPos(150, 175 + 2)
	:AddChoice("Very Low")
	:AddChoice("Low")
	:AddChoice("Normal")
	:AddChoice("Advanced")
	:AddChoice("Professional")
	:SetChoice("Professional")
ui.bots_weapons_option = LF.Create("multichoice", ui.new_game_bots):SetPos(150, 200 + 2)
	:AddChoice("All Weapons")
	:AddChoice("Melee only")
	:AddChoice("Pistols only")
	:AddChoice("Shotguns only")
	:AddChoice("SMGs only")
	:AddChoice("Rifles only")
	:AddChoice("Sniper Rifles only")
	:AddChoice("MGs only")
	:SetChoice("All Weapons")


--Tab 6: More settings-----------------------------------------------------------------------------
ui.command_scroll = LF.Create("scrollpanel", ui.new_game_moresettings):SetPos(0, 10):SetSize(406, 304)
ui.command_list = LF.Create("droplist", ui.command_scroll)
	:SetSize(406, 304):SetPadding(0):SetZebra(true)

local commands = {
	"mp_postspawn",
	"mp_c4timer",
	"mp_mapgoalscore",
	"mp_autogamemode",
	"mp_flashlight",
	"mp_smokeblock",
	"mp_tempbantime",
	"sv_daylighttime",
	"mp_damagefactor",
	"mp_curtailedexplosions",
	"mp_infammo",
	"mp_kevlar",
	"mp_shotweakening",
	"mp_buymenu",
	"mp_unbuyable",
	"mp_grenaderebuy",
	"mp_deathdrop",
	"mp_dropgrenades",
	"mp_hud",
	"mp_hudscale",
	"mp_hovertext",
	"mp_killinfo",
	"mp_mvp",
	"mp_assist",
	"mp_radar",
	"mp_luaserver",
	"mp_luamap",
	"transfer_speed",
	"mp_lagcompensation",
	"mp_lagcompensationdivisor",
	"mp_natholepunching",
	"mp_pinglimit",
	"mp_connectionlimit",
	"mp_floodprot",
	"mp_floodprotignoretime",
	"mp_maxclientsip",
	"mp_maxrconfails",
	"mp_reservations",
	"mp_localrconoutput",
	"sv_checkusgnlogin",
	"sv_rconusers",
}

ui.command_list:AddElementsFromTable(commands)


	ui.new_game_frame:SetVisible(false)
end
