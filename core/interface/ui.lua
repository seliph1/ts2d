local LG 		= love.graphics
local LF 		= require "lib.loveframes"
local client 	= require "client"
local ui 		= {}

ui.font_fallbacks = {
	"gfx/fonts/NotoSansCJK-Regular.ttc",
	"gfx/fonts/NotoSansArabic-Regular.ttf",
	"gfx/fonts/NotoSansThai-Regular.ttf",
	"gfx/fonts/NotoSansHebrew-Regular.ttf",
	"gfx/fonts/NotoSansHindi-Regular.ttf",
	"gfx/fonts/NotoSansCuneiform-Regular.ttf",
}

ui.setFontFallbacks = function(font, size)
	local fallbacks = {}
	for index, fallback_src in ipairs(ui.font_fallbacks) do
		local fallback = LG.newFont(fallback_src, size)
		table.insert(fallbacks, fallback)
	end
	font:setFallbacks(unpack(fallbacks))
end

ui.font_mono = LG.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 15)
ui.setFontFallbacks(ui.font_mono, 15)

ui.font_mono_small = LG.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 12)
ui.setFontFallbacks(ui.font_mono_small, 12)

ui.font = LG.newFont("gfx/fonts/liberationsans.ttf", 15)
ui.setFontFallbacks(ui.font, 15)

ui.font_small = LG.newFont("gfx/fonts/liberationsans.ttf", 11)
ui.setFontFallbacks(ui.font_small, 11)

ui.font_chat = LG.newFont("gfx/fonts/liberationsans.ttf", 18)
ui.setFontFallbacks(ui.font_chat, 18)

ui.setCursor = function(cursorType, cursorImageData, scale)
	local ow, oh = cursorImageData:getWidth(), cursorImageData:getHeight()
	local nw, nh = math.floor(ow * scale), math.floor(oh * scale)
	cursorImageData:mapPixel(function(x, y, r, g, b, a)
		-- Remove magenta (255,0,255) → alpha = 0
		if r == 1 and g == 0 and b == 1 then
			return r, g, b, 0
		else
			return r, g, b, a
		end
	end)
	local cursorImage = love.graphics.newImage(cursorImageData)
	local canvas = LG.newCanvas(nw, nh)
	love.graphics.push("all")
	love.graphics.setCanvas(canvas)
	love.graphics.draw(cursorImage, 0, 0, 0, scale)
	love.graphics.pop()
	love.graphics.setCanvas()
	local imageData = canvas:newImageData()
	--return imageData
	LF.SetCursor(cursorType, imageData, nw/2, nh/2)
end

local _, pointers =  LF.CreateSpriteSheet("gfx/pointer.bmp", 46, 46)
ui.setCursor("arrow", pointers[0], 0.6)


--------------------------------------------------------------------------------------------------
--Local function helpers--------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
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

local function hasRTL(s)
	local utf8 = require "utf8"
    for _, cp in utf8.codes(s) do
        if (cp >= 0x0590 and cp <= 0x05FF)    -- Hebrew
        or (cp >= 0x0600 and cp <= 0x06FF)    -- Arabic
        or (cp >= 0x0700 and cp <= 0x074F)    -- Syriac (às vezes usado em scripts RTL)
        or (cp >= 0x0750 and cp <= 0x077F)    -- Arabic Supplement
        or (cp >= 0x0780 and cp <= 0x07BF)    -- Thaana
        or (cp >= 0x07C0 and cp <= 0x07FF)    -- NKo
        or (cp >= 0x08A0 and cp <= 0x08FF)    -- Arabic Extended-A
        or (cp >= 0xFB1D and cp <= 0xFDFF)    -- Presentation Forms-A (formas de apresentação árabe)
        or (cp >= 0xFE70 and cp <= 0xFEFF)    -- Presentation Forms-B (formas de apresentação árabe)
        then
            return true
        end
    end
    return false
end

local function reverse_utf8(str)
	local chars = {}
	for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(chars, 1, c)
	end
	return table.concat(chars)
end

--------------------------------------------------------------------------------------------------
--Main Menu Container-----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.main_menu = LF.Create("container")
ui.main_menu:SetSize(100, 300):SetPos(20, 200)

ui.console_button = LF.Create("messagebox", ui.main_menu)
:SetPos(0, 0):SetCursor(LF.cursors.hand)
:SetText("©192192192Console"):SetHoverText("©255255255Console")
ui.console_button.OnClick = function(object)
	local bool = ui.console_frame:GetVisible()
	ui.console_frame:SetVisible(not bool):Center():MoveToTop()
end
--Main menu group 1-------------------------------------------------------------------------------
ui.quickplay_button = LF.Create("messagebox", ui.main_menu)
:SetPos(0, 40):SetCursor(LF.cursors.hand)
:SetText("©192192192Quick Play"):SetHoverText("©255255255Quick Play")
ui.quickplay_button.OnClick = function(self)
	ui.console_input.parse("map as_snow")
end

ui.newgame_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192New Game"):SetHoverText("©255255255New Game")
:SetPos(0, 60):SetCursor(LF.cursors.hand)
ui.newgame_button.OnClick = function(self)
	local bool = ui.new_game_frame:GetVisible()
	ui.new_game_frame:SetVisible(not bool):Center():MoveToTop()
end

ui.findservers_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Find Servers"):SetHoverText("©255255255Find Servers")
:SetPos(0, 80):SetCursor(LF.cursors.hand)
--Main menu group 2---------------------------------------------------------------------------
ui.options_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Options"):SetHoverText("©255255255Options")
:SetPos(0, 120):SetCursor(LF.cursors.hand)
ui.options_button.OnClick = function(self)
	local bool = ui.options_frame:GetVisible()
	ui.options_frame:SetVisible(not bool):Center():MoveToTop()
end

ui.friends_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Friends"):SetHoverText("©255255255Friends")
:SetPos(0, 140):SetCursor(LF.cursors.hand)
ui.friends_button.OnClick = function(self)
	local testframe = LF.Create("frame"):SetResizable(true)
end

ui.mods_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Mods"):SetHoverText("©255255255Mods")
:SetPos(0, 160):SetCursor(LF.cursors.hand)

ui.editor_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Editor"):SetHoverText("©255255255Editor")
:SetPos(0, 180):SetCursor(LF.cursors.hand)
ui.editor_button.OnClick = function(self)
    if client.map then
        local status = client.map:read( "maps/fun_roleplay.map" )
        if status then
            print(status)
        end
    end
    client.mode = "editor"
	LF.SetState("editor")
end

ui.help_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Help"):SetHoverText("©255255255Help")
:SetPos(0, 200):SetCursor(LF.cursors.hand)

ui.discord_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Discord"):SetHoverText("©255255255Discord")
:SetPos(0, 220):SetCursor(LF.cursors.hand)
--ui.discord_button.OnClick = function(self, key) end
--Main menu group 3-------------------------------------------------------------------------------
ui.quit_button = LF.Create("messagebox", ui.main_menu)
:SetText("©192192192Quit"):SetHoverText("©255255255Quit")
:SetPos(0, 260):SetCursor(LF.cursors.hand)
ui.quit_button.OnClick = function() love.event.quit() end

--------------------------------------------------------------------------------------------------
--Console Window Frame---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.console_frame = LF.Create("frame"):SetSize(640, 480):SetResizable(false):SetScreenLocked(true)
:SetName("Console"):SetCloseAction("hide"):SetState("*")

ui.console_window_panel = LF.Create("panel", ui.console_frame)
:SetSize(630, 400):SetPos(5, 30)
ui.console_window = LF.Create("log", ui.console_window_panel)
:SetSize(630, 400):SetPadding(0):SetFont(ui.font_mono_small)

ui.console_input = LF.Create("textbox", ui.console_frame)
ui.console_input:SetPos(5, 435):SetWidth(630):SetMaxHistory(1):SetFont(ui.font_mono)
ui.console_input.rollback = 1
ui.console_input.history = {""}
ui.console_input.OnEnter = function(self, text)
	if text == "" then return end
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
		ui.console_window:AddElement(table.concat(str,"	"), true)
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
:SetSize(406, 304):SetZebra(true):SetPadding(0)
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
:SetSize(406, 304):SetPadding(0):SetZebra(true)

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


--------------------------------------------------------------------------------------------------
--10-pick menu frame------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.menu_frame = LF.Create("frame"):SetSize(272, 440):SetName("Menu"):SetCloseAction("hide"):Center()
ui.menu_buttons = {}
for i = 1,9 do
	local button = LF.Create("button", ui.menu_frame)
	:SetAlign("left"):SetSize(240, 25):SetPos(16, 30+(i-1)*30):SetImage("gfx/gametitle.png")

	ui.menu_buttons[i] = button
end
--[[
ui.debug_button = LF.Create("slider", ui.menu_frame):SetText("Orientation"):SetPos(16, 30+9*30):SetWidth(240)

ui.debug_button = LF.Create("button", ui.menu_frame):SetText("Orientation"):SetPos(16, 30+9*30):SetWidth(240)
ui.debug_button.OnClick = function(object)
	for i = 1,9 do
		local button = ui.menu_buttons[i]
		local align = button:GetAlign()
		if align == "center" then
			button:SetAlign("left")
		elseif align == "left" then
			button:SetAlign("right")
		elseif align == "right" then
			button:SetAlign("center")
		end
	end
end
]]

ui.cancel_button = LF.Create("button", ui.menu_frame)
:SetPos(16, 394):SetSize(240, 25):SetText("©1641641640 ©255255255Cancel"):SetAlign("left")
ui.cancel_button.OnClick = function(object)
	object.parent:SetVisible(false)
end
ui.menu_constructor = function(str)
	local title = ui.menu_frame
	local constructors = {}
	for constructor in (str..","):gmatch("(.-),") do
		table.insert(constructors, constructor)
	end
	title:SetName(string.format("%s", constructors[1])):SetVisible(true):MoveToTop()
	for i = 1, 9 do
		local constructor = constructors[i + 1]
		--print(constructor)
		local button = ui.menu_buttons[i]
		local disabled = false
		local invisible = false
		if constructor then
			if constructor == "" then
				button:SetVisible(false)
			end
			local brackets = constructor:match("^%((.*)%)$")
			local text, caption
			if brackets then
				constructor = brackets
				button:SetEnabled(false)
			else
				button:SetEnabled(true)
			end
			text, caption = constructor:match("^(.-)|(.-)$")
			if not text then
				text, caption = constructor, ""
			end

			button:SetText( string.format("©164164164%s ©255255255%s", i, text ))
			button:SetCaption( caption )
		else -- no constructor
			button:SetEnabled(false)
			button:SetVisible(false)
			button:SetText(string.format("©164164164%s", i))
			button:SetCaption("")
		end
	end
end
--------------------------------------------------------------------------------------------------
--options-----------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.options_frame = LF.Create("frame")
:SetCloseAction("hide"):SetSize(430, 460):SetName("Options")
ui.options_tabs = LF.Create("tabs", ui.options_frame):SetSize(410, 420):SetPos(10, 30)
ui.options_tabs_player = LF.Create("container"):SetPos(410, 420)
ui.options_tabs_controls = LF.Create("container"):SetPos(410, 420)
ui.options_tabs_game = LF.Create("container"):SetPos(410, 420)
ui.options_tabs_graphics = LF.Create("container"):SetPos(410, 420)
ui.options_tabs_sound = LF.Create("container"):SetPos(410, 420)
ui.options_tabs_net = LF.Create("container"):SetPos(410, 420)
ui.options_tabs_more = LF.Create("container"):SetPos(410, 420)

--tabs--------------------------------------------------------------------------------------------
ui.options_tabs:AddTab("Player", ui.options_tabs_player)
ui.options_tabs:AddTab("Controls", ui.options_tabs_controls)
ui.options_tabs:AddTab("Game", ui.options_tabs_game)
ui.options_tabs:AddTab("Graphics", ui.options_tabs_graphics)
ui.options_tabs:AddTab("Sound", ui.options_tabs_sound)
ui.options_tabs:AddTab("Net", ui.options_tabs_net)
ui.options_tabs:AddTab("More", ui.options_tabs_more)

--player tab--------------------------------------------------------------------------------------
ui.options_player_name = LF.Create("label", ui.options_tabs_player):SetText("Player Name: "):SetPos(0, 0+4)
ui.options_player_spraylogo = LF.Create("label", ui.options_tabs_player):SetText("Spray Logo: "):SetPos(0, 60+4)
ui.options_player_crosshair = LF.Create("label", ui.options_tabs_player):SetText("Crosshair: "):SetPos(0, 200+4)

ui.options_player_name_input = LF.Create("textbox", ui.options_tabs_player):SetPos(150, 0+2):SetSize(200, 20)
ui.options_player_name_input.OnTextChanged = function(object, textadded)
	local text = object:GetText()
	if text ~= "" then
		client.name = text
	end
end

ui.options_mark_own_player = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 120+2)
:SetText("Mark own Player")
ui.options_lefthanded_players = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 140+2)
:SetText("Lefthand Players")
ui.options_recoil_animations = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 160+2)
:SetText("Recoil Animations")
ui.options_wiggle_animations = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 180+2)
:SetText("Wiggle Animations")

ui.options_spray_panel = LF.Create("panel", ui.options_tabs_player):SetPos(150, 40):SetSize(60, 60)
ui.options_spray_images = {}
for _, filename in ipairs(love.filesystem.getDirectoryItems("logos")) do
	if filename:find(".bmp") then
		table.insert(ui.options_spray_images, "logos/"..filename)
	end
end

ui.options_spray_pointer = 1
ui.options_spray_image = LF.Create("image", ui.options_spray_panel)
ui.options_spray_image:SetImage(ui.options_spray_images[ui.options_spray_pointer]):Center()

ui.options_spray_left = LF.Create("button", ui.options_tabs_player):SetPos(150, 100):SetText("L"):SetSize(20,20)
ui.options_spray_left.OnClick = function (object)
	ui.options_spray_pointer = ui.options_spray_pointer - 1
	if ui.options_spray_pointer <= 0 then
		ui.options_spray_pointer = #ui.options_spray_images
	end
	ui.options_spray_image:SetImage(ui.options_spray_images[ui.options_spray_pointer]):Center()
end
ui.options_spray_right = LF.Create("button", ui.options_tabs_player):SetPos(190, 100):SetText("R"):SetSize(20,20)
ui.options_spray_right.OnClick = function (object)
	ui.options_spray_pointer = ui.options_spray_pointer + 1
	if ui.options_spray_pointer > #ui.options_spray_images then
		ui.options_spray_pointer = 1
	end
	ui.options_spray_image:SetImage(ui.options_spray_images[ui.options_spray_pointer]):Center()
end

ui.options_spray_r = LF.Create("slider", ui.options_tabs_player):SetPos(220, 40):SetMinMax(0,255):SetDecimals(0):SetValue(255)
ui.options_spray_g = LF.Create("slider", ui.options_tabs_player):SetPos(220, 60):SetMinMax(0,255):SetDecimals(0):SetValue(255)
ui.options_spray_b = LF.Create("slider", ui.options_tabs_player):SetPos(220, 80):SetMinMax(0,255):SetDecimals(0):SetValue(255)

ui.options_spray_r.OnValueChanged = function(object, value)
	ui.options_spray_image:SetColor(value/255, nil, nil)
end
ui.options_spray_g.OnValueChanged = function(object, value)
	ui.options_spray_image:SetColor(nil, value/255, nil)
end
ui.options_spray_b.OnValueChanged = function(object, value)
	ui.options_spray_image:SetColor(nil, nil, value/255)
end



ui.options_crosshair_panel = LF.Create("panel", ui.options_tabs_player):SetPos(150, 210):SetSize(96, 96)
ui.options_crosshair_label = LF.Create("label", ui.options_tabs_player):SetPos(250, 310):SetText("")
ui.options_crosshair_image = LF.Create("image", ui.options_crosshair_panel)
:SetImage(pointers[0]):SetCentered(true):Center()

ui.options_crosshair_slider = LF.Create("slider", ui.options_tabs_player)
:SetPos(150, 310):SetWidth(97):SetMinMax(0.2, 1.5)
ui.options_crosshair_slider.OnValueChanged = function(object, value)
	ui.options_crosshair_image:SetScale(value, value)
	ui.options_crosshair_label:SetText(tostring(value))
end
ui.options_crosshair_slider:SetValue(1)

ui.options_button_help = LF.Create("button", ui.options_frame):SetText("Help"):SetPos(0+10, 430):SetWidth(50)
ui.options_button_okay = LF.Create("button", ui.options_frame):SetText("Okay"):SetPos(195+10, 430):SetWidth(100)
ui.options_button_okay.OnClick = function(object)
	local slider = ui.options_crosshair_slider:GetValue()
	ui.setCursor("arrow", pointers[0], slider)
end
ui.options_button_cancel = LF.Create("button", ui.options_frame):SetText("Cancel"):SetPos(300+10, 430):SetWidth(100)






--controls tab------------------------------------------------------------------------------------
--game tab----------------------------------------------------------------------------------------
--graphics tab------------------------------------------------------------------------------------
--net tab-----------------------------------------------------------------------------------------
--more options tab--------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
--chat--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.chat_width = 400
ui.chat_height = 200

ui.chat_frame = LF.Create("frame"):SetSize(ui.chat_width, ui.chat_height):SetState("game")
ui.chat_frame:SetScreenLocked(true):ShowCloseButton(false):SetPos(0, love.graphics.getHeight()-ui.chat_height-40)
ui.chat_frame_message = function(player, message)
	local game = {mode = 1}
	if not player then return end
	local teamcolor = ""
	if player.t == 0 then
		teamcolor = "©128128128"
	elseif player.t == 1 then
		teamcolor = "©050150254"
	elseif player.t == 2 then
		teamcolor = "©254025000"
	end
	local messagecolor = "©255220000"
	local deadindicator = ""
	if player.h <= 0 then
		deadindicator = "©255220000 *DEAD*"
	end
	if game.mode == 1 and player.t ~= 0 then
		teamcolor = "©000255000"
	end

	if hasRTL(message) then
		print("reverse!!")
		message = reverse_utf8(message)
	end

	local full_message = string.format("%s%s%s: %s%s", teamcolor, player.n, deadindicator, messagecolor, message)
	ui.chat_log:AddElement(full_message)

	return full_message
end

ui.chat_frame.Draw = function(object)
	local hover = object:GetHover()
	local hovertime = 0
	if hover and object.hovertime > 0 then
		hovertime = love.timer.getTime() - object.hovertime
	end
	local brightness =  LF.Mix(0.1, 0.3, LF.Clamp(hovertime*5, 0, 1) )

	LG.setColor(0, 0, 0, brightness)
	LG.rectangle("fill", object.x, object.y, object.width, object.height, 10, 10)

	LG.setColor(0, 0, 0, brightness)

	local skin = LF.GetActiveSkin()
	LG.setColor(0.8,0.8,0.8, brightness)
	local drag = skin.images["vdrag.png"]
	local scale = 0.3
	LG.draw(drag, object.x + object.width/2 - drag:getWidth()/2*scale, object.y + 8, 0, scale)
end

ui.chat_log = LF.Create("log", ui.chat_frame)
:SetSize(ui.chat_width, ui.chat_height-30):SetPos(0, 30):SetPadding(0)
:SetFont(ui.font_chat)

--------------------------------------------------------------------------------------------------
--server log--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.server_log_width = 200
ui.server_log_height = 100

ui.server_log_frame = LF.Create("frame")
:SetSize(ui.server_log_width, ui.server_log_height)
:SetState("game")
:SetScreenLocked(true)
:ShowCloseButton(false)
:SetPos(love.graphics.getWidth()/2, 0)

ui.server_log_frame.Draw = function(object)
	local hover = object:GetHover()
	local hovertime = 0
	if hover and object.hovertime > 0 then
		hovertime = love.timer.getTime() - object.hovertime
	end
	local brightness =  LF.Mix(0.1, 0.3, LF.Clamp(hovertime*5, 0, 1) )

	LG.setColor(0, 0, 0, brightness)
	LG.rectangle("fill", object.x, object.y, object.width, object.height, 10, 10)

	LG.setColor(0, 0, 0, brightness)

	local skin = LF.GetActiveSkin()
	LG.setColor(0.8,0.8,0.8, brightness)
	local drag = skin.images["vdrag.png"]
	local scale = 0.3
	LG.draw(drag, object.x + object.width/2 - drag:getWidth()/2*scale, object.y + 8, 0, scale)
end

ui.server_log = LF.Create("log", ui.server_log_frame)
:SetSize(ui.server_log_width, ui.server_log_height-30)
:SetPos(0, 30)
:SetPadding(0)
:SetFont(ui.font_small)
:SetScrollBody(false)

ui.server_log_push = function(message)
	ui.server_log:AddElement(message)
end

--------------------------------------------------------------------------------------------------
--chat input--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

ui.chat_input_frame = LF.Create("container")
:SetSize(800, 60)
:SetY(LG.getHeight()-60)
:CenterX()
:SetState("game")
:SetVisible(false)

ui.chat_input_header = LF.Create("messagebox", ui.chat_input_frame)
:SetFont(ui.font_chat)
:SetText("©255220000Say:")
:CenterY()

local chat_offset = ui.chat_input_header:GetWidth()
ui.chat_input = LF.Create("input", ui.chat_input_frame)
:SetSize(800, 30):SetCharacterLimit(80):SetFont(ui.font_chat)
:SetX(chat_offset)
:SetColor(1.00, 0.86, 0.00, 1.00)
:SetCursorColor(1.00, 0.86, 0.00, 1.00)
:SetHighlightColor(1.00, 0.86, 0.00, 0.20)
:CenterY()

ui.chat_input.Draw = function(object)
	local x = object.x
	local y = object.y
	local textwidth, textheight = object.field:getTextDimensions()
	local vpadding = object:GetVerticalPadding()
	local hpadding = object:GetHorizontalPadding()

	love.graphics.setColor(0,0,0,0.5)
	love.graphics.rectangle("fill", x, y, textwidth + hpadding*2, textheight + vpadding*2, 5)
end

ui.chat_input.OnEnter = function (object, text)
	ui.chat_input:Clear()
	if ui.chat_input_frame:GetVisible() and text ~= "" then
		if text:sub(1, 1) == "/" then
			ui.console_input.parse( text:sub(2) )
		else
			client.send(string.format("say %s", text))
		end
	end
end
--------------------------------------------------------------------------------------------------
--exit window-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.exit_window = LF.Create("frame"):SetSize(400, 300):SetName("Quit?"):SetCloseAction("hide")
ui.exit_window_panel = LF.Create("panel", ui.exit_window):SetPos(16, 32):SetSize(368, 230)
ui.exit_window_message = LF.Create("messagebox",ui.exit_window_panel)
:SetFont(ui.font):SetPos(5, 5):SetMaxWidth(368)
:SetText([[
Thank you for playing CS2D!

Help, FAQ and updates are available at
>>www.CS2D.com<<
More free games at
>>www.UnrealSoftware.de<<

©255255000Are you really sure you want to quit?
]]):Center()
ui.exit_window_yesbutton = LF.Create("button", ui.exit_window)
:SetSize(100, 20):SetPos(180, 270):SetText("Yes, Quit!")
ui.exit_window_yesbutton.OnClick = function()
	love.event.quit()
end
ui.exit_window_nobutton = LF.Create("button", ui.exit_window)
:SetSize(100, 20):SetPos(284, 270):SetText("No")
ui.exit_window_nobutton.OnClick = function()
	ui.exit_window:SetVisible(false)
end

ui.exit_window:SetVisible(false)
--------------------------------------------------------------------------------------------------
--editor------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.editor = require "core.interface.editor"

--------------------------------------------------------------------------------------------------
--bindings----------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.binds = require "core.interface.binds" (ui)

--------------------------------------------------------------------------------------------------
--final wrapping of windows-----------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.new_game_frame:SetVisible(false)
ui.console_frame:SetVisible(false):SetAlwaysOnTop(true)
ui.menu_frame:SetVisible(false)
ui.options_frame:SetVisible(false)
--------------------------------------------------------------------------------------------------
--end of module-----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
return ui