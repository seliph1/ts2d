local client = require "client"
local LG = love.graphics
local LF = require "lib.loveframes"
local ui = {
    latin_font = LG.newFont("gfx/fonts/liberationsans.ttf", 15),
    latin_font_small = LG.newFont("gfx/fonts/liberationsans.ttf", 11),

    font = LG.newFont("gfx/fonts/NotoSansKR-Regular.ttf", 15),
    font_small = LG.newFont("gfx/fonts/NotoSansKR-Regular.ttf", 11),

    font_mono = LG.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 15),
	font_mono_small = LG.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 12),
}

-- Gera uma string aleatória com o tamanho especificado
local function random_string(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(#charset)
        result[i] = charset:sub(rand, rand)
    end
    return table.concat(result)
end

local function random_color()
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    return string.format("©%03d%03d%03d", r, g, b)
end

ui.editor = require "core.interface.editor"
ui.editor.frame:SetVisible(false)
--------------------------------------------------------------------------------------------------
--Main Menu Container-----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.main_menu = LF.Create("container")
ui.main_menu:SetSize(100, 300):SetPos(20, 200)
ui.main_menu.Update = function(self)
	if client.mode ~= "lobby" then
		self:SetVisible(false)
	end
end

ui.console_button = LF.Create("messagebox", ui.main_menu)
ui.console_button:SetPos(0, 0):SetFont(ui.font_small):SetText("©192192192Console"):SetHoverText("©255255255Console")
ui.console_button.OnClick = function(object)
	local bool = ui.console_frame:GetVisible()
	ui.console_frame:SetVisible(not bool)
end
--Main menu group 1-------------------------------------------------------------------------------
ui.quickplay_button = LF.Create("messagebox", ui.main_menu)
ui.quickplay_button:SetText("©192192192Quick Play"):SetHoverText("©255255255Quick Play"):SetPos(0, 40):SetFont(ui.font)
ui.quickplay_button.OnClick = function(self)
end

ui.newgame_button = LF.Create("messagebox", ui.main_menu)
ui.newgame_button:SetText("©192192192New Game"):SetHoverText("©255255255New Game"):SetPos(0, 60):SetFont(ui.font)
ui.newgame_button.OnClick = function(self)
	local bool = ui.new_game_frame:GetVisible()
	ui.new_game_frame:SetVisible(not bool):Center()
end

ui.findservers_button = LF.Create("messagebox", ui.main_menu)
ui.findservers_button:SetText("©192192192Find Servers"):SetHoverText("©255255255Find Servers"):SetPos(0, 80):SetFont(ui.font)
--Main menu group 2---------------------------------------------------------------------------
ui.options_button = LF.Create("messagebox", ui.main_menu)
ui.options_button:SetText("©192192192Options"):SetHoverText("©255255255Options"):SetPos(0, 120):SetFont(ui.font)

ui.friends_button = LF.Create("messagebox", ui.main_menu)
ui.friends_button:SetText("©192192192Friends"):SetHoverText("©255255255Friends"):SetPos(0, 140):SetFont(ui.font)

ui.mods_button = LF.Create("messagebox", ui.main_menu)
ui.mods_button:SetText("©192192192Mods"):SetHoverText("©255255255Mods"):SetPos(0, 160):SetFont(ui.font)

ui.editor_button = LF.Create("messagebox", ui.main_menu)
ui.editor_button:SetText("©192192192Editor"):SetHoverText("©255255255Editor"):SetPos(0, 180):SetFont(ui.font)
ui.editor_button.OnClick = function(self)
    if client.map then
        local status = client.map:read( "maps/fun_roleplay.map" )
        if status then
            print(status)
        end
    end
    client.mode = "editor"
end

ui.help_button = LF.Create("messagebox", ui.main_menu)
ui.help_button:SetText("©192192192Help"):SetHoverText("©255255255Help"):SetPos(0, 200):SetFont(ui.font)

ui.discord_button = LF.Create("messagebox", ui.main_menu)
ui.discord_button:SetText("©192192192Discord"):SetHoverText("©255255255Discord"):SetPos(0, 220):SetFont(ui.font)
ui.discord_button.OnClick = function(self, key) end
--Main menu group 3-------------------------------------------------------------------------------
ui.quit_button = LF.Create("messagebox", ui.main_menu)
ui.quit_button:SetText("©192192192Quit"):SetHoverText("©255255255Quit"):SetPos(0, 260):SetFont(ui.font)
ui.quit_button.OnClick = function() love.event.quit() end

--------------------------------------------------------------------------------------------------
--Console Window Frame---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.console_frame = LF.Create("frame")
:SetSize(640, 480)
:SetName("Console")
:SetResizable(false)
:SetScreenLocked(true)
:SetCloseAction("hide")

ui.console_window_scroll = LF.Create("scrollpane", ui.console_frame):SetSize(630, 400):SetPos(5, 30)
ui.console_window = LF.Create("droplist", ui.console_window_scroll):SetSize(630, 400):SetFont(ui.font_mono_small)
ui.console_window:SetHighlight(false):SetPadding(0):SetBackground(0,0,0,0)
ui.console_window.history = {}

ui.console_input = LF.Create("textbox", ui.console_frame)
ui.console_input:SetPos(5, 435):SetWidth(630):SetPadding(0):SetFont(ui.font_mono)
ui.console_input:SetMaxHistory(1)
ui.console_input.rollback = 1
ui.console_input.history = {""}
ui.console_input.OnEnter = function(self, text)
    if not(self.focus) then
        return
    end
	self:SetText("")
	self.parse(text)
	table.insert(self.history, text)
	self.rollback = #self.history + 1
end

ui.console_input.OnControlKeyPressed = function(self, key)
    if not(self.focus) then
        return
    end
	if key=="up" then
		local h = ui.console_input.history
		local r = math.max(self.rollback - 1, 1)

		self:SetText(h[r])
		self.rollback = r
	elseif key=="down" then
		local h = self.history
		local r = math.min(self.rollback + 1, #h)

		self:SetText(h[r])
		self.rollback = r
	end
end

ui.console_input.commands = love.filesystem.load("core/interface/commands.lua")()
ui.console_input.parse = function(str)
	local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local command_id = args[1]
	local commands = ui.console_input.commands
	if commands[ command_id ] then
		local command_object = commands[ command_id ]
		if command_object.action then
			local status = command_object.action( unpack(args,2) )
		end
	else
		print(string.format("Unknown command: %s", str))
	end
end

--- print override
_Print = print
function print(...)
	local args = {...}
	local str = {}
	for k,v in pairs(args) do
		table.insert(str, tostring(v))
	end
	if ui.console_window then
		ui.console_window:AddElement(table.concat(str," "), true)
	end
	_Print(...)
end

--------------------------------------------------------------------------------------------------
--New Game Frame----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.new_game_frame = LF.Create("frame"):SetName("Create Server"):SetSize(428, 460):SetCloseAction("hide")

ui.newgame_button_help = LF.Create("button", ui.new_game_frame):SetText("Help"):SetPos(0+10, 430):SetWidth(50)
ui.newgame_button_start = LF.Create("button", ui.new_game_frame):SetText("Start"):SetPos(195+10, 430):SetWidth(100)
ui.newgame_button_cancel = LF.Create("button", ui.new_game_frame):SetText("Cancel"):SetPos(300+10, 430):SetWidth(100)

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
ui.server_name_label = LF.Create("label", ui.new_game_server):SetPos(0, 0+4):SetText("Server Name:")
ui.server_password_label = LF.Create("label", ui.new_game_server):SetPos(0, 25+4):SetText("Server Password:")
ui.server_rcon_password_label = LF.Create("label", ui.new_game_server):SetPos(0, 50+4):SetText("RCon Password:")
ui.server_port_label = LF.Create("label", ui.new_game_server):SetPos(0, 75+4):SetText("Port (UDP):")
ui.server_maxplayers_label = LF.Create("label", ui.new_game_server):SetPos(0, 100+4):SetText("Max. Players:")
ui.server_fow_label = LF.Create("label", ui.new_game_server):SetPos(0, 125+4):SetText("Fog of War:")

ui.server_name_input = LF.Create("textbox", ui.new_game_server)
:SetPos(150, 0+2):SetSize(150, 20):SetPlaceholderText("CS2D Server")

ui.server_password_input = LF.Create("textbox", ui.new_game_server)
:SetPos(150, 25+2):SetSize(150, 20):SetType("password"):SetPasswordCharacter("•")
ui.server_rcon_password_input = LF.Create("textbox", ui.new_game_server)
:SetPos(150, 50+2):SetSize(150, 20):SetType("password"):SetPasswordCharacter("•")

ui.server_port_input = LF.Create("textbox", ui.new_game_server):SetPos(150, 75+2):SetSize(100, 20)
:SetUsable({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}):SetCharacterLimit(5)

ui.server_max_players_numberbox = LF.Create("numberbox", ui.new_game_server):SetPos(150, 100+2):SetMinMax(0, 32)

ui.server_fow_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 125+2):SetSize(200, 20)
:AddChoice("Off")
:AddChoice("Hide characters only")
:AddChoice("Hide characters and effects")
:AddChoice("Hide everything")
:SetChoice("Off")


ui.server_friendlyfire_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 150+2):SetText("Friendly Fire")
ui.server_hide_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 170+2):SetText("Hide Server (unlisted)")
ui.server_usgnonly_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 190+2):SetText("Registered U.S.G.N Users only")
:SetEnabled(false)
ui.server_filetransfer_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 210+2):SetText("Map and File Transfer")
ui.server_offscreendamage_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 230+2):SetText("Off-Screen Damage")
ui.server_forcelightning_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 250+2):SetText("Force Lightning")
ui.server_recoilaccuracy_checkbox = LF.Create("checkbox", ui.new_game_server):SetPos(150, 270+2):SetText("Recoil influences accuracy"):SetText(""):SetEnabled(false)

ui.server_voicechat_label = LF.Create("label", ui.new_game_server):SetPos(0, 290+4):SetText("Voice Chat:")
ui.server_gamemode_label = LF.Create("label", ui.new_game_server):SetPos(0, 315+4):SetText("Gamemode:")
ui.server_spectate_label = LF.Create("label", ui.new_game_server):SetPos(0, 340+4):SetText("Allow to Spectate: ")

ui.server_voicechat_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 290+2):SetSize(200, 20)
:AddChoice("Disabled")
:AddChoice("For All")
:AddChoice("Team Only")
:AddChoice("Team Only + Spectators")
:SetChoice("Team Only")

ui.server_gamemode_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 315+2):SetSize(200, 20)
:AddChoice("Standard")
:AddChoice("Deathmatch")
:AddChoice("Team Deathmatch")
:AddChoice("Construction")
:AddChoice("Zombies")
:SetChoice("Standard")

ui.server_spectate_choice = LF.Create("multichoice", ui.new_game_server):SetPos(150, 340+2):SetSize(200, 20)
:AddChoice("Nothing (War Mode)")
:AddChoice("Everything")
:AddChoice("Own Team Only")
:SetChoice("Own Team Only")

--Tab 2: Map--------------------------------------------------------------------------------------
ui.map_display_label = LF.Create("label", ui.new_game_map):SetText("Display: "):SetPos(0, 0+4)
ui.map_display_search_label = LF.Create("label", ui.new_game_map):SetText("Search: "):SetPos(0, 25+4)
ui.map_display_choice = LF.Create("multichoice", ui.new_game_map):SetPos(80, 0+2):SetWidth(300)
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
ui.map_display_search_bar = LF.Create("textbox", ui.new_game_map):SetPos(80, 25+2):SetSize(200, 20)
ui.map_display_sort_button = LF.Create("button", ui.new_game_map):SetText("Sort Z-A"):SetPos(300, 25+2)
ui.map_display_sort_button.OnClick = function(object)
	if object.text == "Sort Z-A" then
		object:SetText("Sort A-Z")
		ui.map_display_list:Sort(function(a,b) return a > b end)
	elseif object.text == "Sort A-Z" then
		object:SetText("Sort Z-A")
		ui.map_display_list:Sort(function(a,b) return a < b end)
	end
end

ui.map_display_pane = LF.Create("scrollpane", ui.new_game_map):SetPos(0, 50+4):SetSize(406, 304)
ui.map_display_list = LF.Create("droplist", ui.map_display_pane)
:SetSize(406, 304):SetZebra(true):SetFont(ui.font):SetPadding(0)
local elements = {}
for _, name in pairs(love.filesystem.getDirectoryItems("maps")) do
	table.insert(elements, name)
end
ui.map_display_list:AddElementsFromTable(elements)
--Tab 3: Settings--------------------------------------------------------------------------------------
ui.settings_timepermap = LF.Create("label", ui.new_game_settings):SetPos(0, 0+4):SetText("Time per Map (Min.):")
ui.settings_winlimit = LF.Create("label", ui.new_game_settings):SetPos(0, 25+4):SetText("Win Limit (Rounds):")
ui.settings_roundlimit = LF.Create("label", ui.new_game_settings):SetPos(0, 50+4):SetText("Round Limit (Rounds):")
ui.settings_timeperround = LF.Create("label", ui.new_game_settings):SetPos(0, 75+4):SetText("Time per Round (Min.):")
ui.settings_freezetime = LF.Create("label", ui.new_game_settings):SetPos(0, 100+4):SetText("Freeze Time (Sec.):")
ui.settings_buytime = LF.Create("label", ui.new_game_settings):SetPos(0, 125+4):SetText("Buy Time (Min.):")
ui.settings_startmoney = LF.Create("label", ui.new_game_settings):SetPos(0, 150+4):SetText("Start Money:")
ui.settings_kickafterxteamkills = LF.Create("label", ui.new_game_settings):SetPos(0, 200+4):SetText("Kick after X Team Kills:")
ui.settings_kickafterxhostagekills = LF.Create("label", ui.new_game_settings):SetPos(0, 225+4):SetText("Kick after X Hostage Kills:")

ui.settings_timepermap_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 0+4):SetHeight(20):SetMin(0):SetStepAmount(1)
ui.settings_winlimit_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 25+4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_roundlimit_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 50+4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_timeperround_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 75+4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_freezetime_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 100+4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_buytime_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 125+4):SetHeight(20):SetMin(0):SetStepAmount(0.5)
ui.settings_startmoney_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 150+4):SetHeight(20):SetMinMax(0, 16000):SetStepAmount(1000)
ui.settings_kickafterxteamkills_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 200+4):SetMin(0):SetHeight(20)
ui.settings_kickafterxhostagekills_textbox = LF.Create("numberbox", ui.new_game_settings)
:SetPos(200, 225+4):SetMin(0):SetHeight(20)
ui.settings_killteamkiller_checkbox = LF.Create("checkbox", ui.new_game_settings)
:SetPos(200, 260+4):SetText("Kill TKer on next Round")
ui.settings_kickidlers_checkbox = LF.Create("checkbox", ui.new_game_settings)
:SetPos(200, 280+4):SetText("Kick Idlers (or other action)")
ui.settings_vulnerablehostages_checkbox = LF.Create("checkbox", ui.new_game_settings)
:SetPos(200, 300+4):SetText("Hostages are vulnerable")
ui.settings_autoteambalance_checkbox = LF.Create("checkbox", ui.new_game_settings)
:SetPos(200, 320+4):SetText("Auto Teambalance")
ui.settings_spectatemouse_checkbox = LF.Create("checkbox", ui.new_game_settings)
:SetPos(200, 340+4):SetText("Spectate mouse")

--Tab 4: Bots--------------------------------------------------------------------------------------
ui.bots_prefix_label = LF.Create("label", ui.new_game_bots):SetPos(0, 0+4):SetText("Bot Name Prefix: ")
ui.bots_amount_label = LF.Create("label", ui.new_game_bots):SetPos(0, 25+4):SetText("Bots:")
ui.bots_jointeam_label = LF.Create("label", ui.new_game_bots):SetPos(0, 100+4):SetText("Join Team:")
ui.bots_skills_label = LF.Create("label", ui.new_game_bots):SetPos(0, 175+4):SetText("Skills:")
ui.bots_weapons_label = LF.Create("label", ui.new_game_bots):SetPos(0, 200+4):SetText("Weapons:")

ui.bots_prefix_textbox = LF.Create("textbox", ui.new_game_bots):SetPos(150, 0+4):SetSize(150, 20)
ui.bots_amount_textbox = LF.Create("numberbox", ui.new_game_bots):SetPos(150, 25+4)

ui.bots_team_radiogroup = {}
ui.bots_both_radiobutton = LF.Create("radiobutton", ui.new_game_bots)
:SetPos(150, 100+4):SetText("Both"):SetGroup(ui.bots_team_radiogroup)
ui.bots_tr_radiobutton = LF.Create("radiobutton", ui.new_game_bots)
:SetPos(150, 120+4):SetText("Terrorists"):SetGroup(ui.bots_team_radiogroup)
ui.bots_ct_radiobutton = LF.Create("radiobutton", ui.new_game_bots)
:SetPos(150, 140+4):SetText("Counter-Terrorists"):SetGroup(ui.bots_team_radiogroup)
ui.bots_both_radiobutton:SetChecked(true)

ui.bots_autofill = LF.Create("checkbox", ui.new_game_bots):SetPos(150, 50+4):SetText("Auto Fill")
ui.bots_keepfreeslots = LF.Create("checkbox", ui.new_game_bots):SetPos(150, 70+4):SetText("Keep free slots for joining")

ui.bots_skills_option = LF.Create("multichoice", ui.new_game_bots):SetPos(150, 175+2)
:AddChoice("Very Low")
:AddChoice("Low")
:AddChoice("Normal")
:AddChoice("Advanced")
:AddChoice("Professional")
:SetChoice("Professional")
ui.bots_weapons_option = LF.Create("multichoice", ui.new_game_bots):SetPos(150, 200+2)
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
ui.command_scroll = LF.Create("scrollpane", ui.new_game_moresettings):SetPos(0, 10):SetSize(406, 304)
ui.command_list = LF.Create("droplist", ui.command_scroll)
:SetSize(406, 304):SetFont(ui.font):SetPadding(0):SetZebra(true)
--:SetBackground(0.15,0.15,0.15,1.0):

local commands = {
	"mp_postspawn";
	"mp_c4timer";
	"mp_mapgoalscore";
	"mp_autogamemode";
	"mp_flashlight";
	"mp_smokeblock";
	"mp_tempbantime";
	"sv_daylighttime";
	"mp_damagefactor";
	"mp_curtailedexplosions";
	"mp_infammo";
	"mp_kevlar";
	"mp_shotweakening";
	"mp_buymenu";
	"mp_unbuyable";
	"mp_grenaderebuy";
	"mp_deathdrop";
	"mp_dropgrenades";
	"mp_hud";
	"mp_hudscale";
	"mp_hovertext";
	"mp_killinfo";
	"mp_mvp";
	"mp_assist";
	"mp_radar";
	"mp_luaserver";
	"mp_luamap";
	"transfer_speed";
	"mp_lagcompensation";
	"mp_lagcompensationdivisor";
	"mp_natholepunching";
	"mp_pinglimit";
	"mp_connectionlimit";
	"mp_floodprot";
	"mp_floodprotignoretime";
	"mp_maxclientsip";
	"mp_maxrconfails";
	"mp_reservations";
	"mp_localrconoutput";
	"sv_checkusgnlogin";
	"sv_rconusers";
}

ui.command_list:AddElementsFromTable(commands)



ui.menu_frame = LF.Create("frame"):SetSize(272, 440):SetName("Menu"):SetCloseAction("hide"):Center()
ui.menu_buttons = {}
for i = 1,9 do
	ui.menu_buttons[i] = LF.Create("button", ui.menu_frame)
	:SetText(string.format("©128128128%s", i)):SetAlign("left")
	:SetSize(240, 25):SetPos(16, 30+(i-1)*30)
end
ui.cancel_button = LF.Create("button", ui.menu_frame)
:SetPos(16, 394):SetSize(240, 25):SetText("©1281281280 ©255255255Cancel"):SetAlign("left")

ui.cancel_button.OnClick = function(object)
	object.parent:SetVisible(false)
end

------------------------------------------------
ui.new_game_frame:SetVisible(false)
ui.console_frame:SetVisible(false)
ui.menu_frame:SetVisible(false)

return ui