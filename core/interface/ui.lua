local loveframes = require "lib/loveframes"
local client = require "client"
local LF = loveframes
local LG = love.graphics
local ui = {
    latin_font = LG.newFont("lib/loveframes/skins/CS2D/images/liberationsans.ttf", 15),
    latin_font_small = LG.newFont("lib/loveframes/skins/CS2D/images/liberationsans.ttf", 11),

    font = LG.newFont("lib/loveframes/skins/CS2D/images/NotoSansKR-Regular.ttf", 15),
    font_small = LG.newFont("lib/loveframes/skins/CS2D/images/NotoSansKR-Regular.ttf", 11)
}


ui.main_menu = LF.Create("container")
ui.main_menu:SetSize(400, 400):SetPos(20, 200)
ui.main_menu.Draw = function()
end

ui.console_button = LF.Create("messagebox", ui.main_menu)
ui.console_button:SetPos(0, 0):SetFont(ui.font_small):SetText("©192192192Console"):SetHoverText("©255255255Console")
ui.console_button.OnClick = function(object)
    loveframes.Create("frame")
end
--------------------------------------------------------------------------------------------------
ui.quickplay_button = LF.Create("messagebox", ui.main_menu)
ui.quickplay_button:SetText("©192192192Quick Play"):SetHoverText("©255255255Quick Play"):SetPos(0, 40):SetFont(ui.font)

ui.newgame_button = LF.Create("messagebox", ui.main_menu)
ui.newgame_button:SetText("©192192192New Game"):SetHoverText("©255255255New Game"):SetPos(0, 60):SetFont(ui.font)

ui.findservers_button = LF.Create("messagebox", ui.main_menu)
ui.findservers_button:SetText("©192192192Find Servers"):SetHoverText("©255255255Find Servers"):SetPos(0, 80):SetFont(ui.font)
--------------------------------------------------------------------------------------------------
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
    client.mode = "game"
end

ui.help_button = LF.Create("messagebox", ui.main_menu)
ui.help_button:SetText("©192192192Help"):SetHoverText("©255255255Help"):SetPos(0, 200):SetFont(ui.font)

ui.discord_button = LF.Create("messagebox", ui.main_menu)
ui.discord_button:SetText("©192192192Discord"):SetHoverText("©255255255Discord"):SetPos(0, 220):SetFont(ui.font)
--------------------------------------------------------------------------------------------------
ui.quit_button = LF.Create("messagebox", ui.main_menu)
ui.quit_button:SetText("©192192192Quit"):SetHoverText("©255255255Quit"):SetPos(0, 260):SetFont(ui.font)



ui.new_game_frame = LF.Create("frame")
ui.new_game_frame:SetName("Create Server"):SetSize(428, 460)

ui.new_game_tabs = LF.Create("tabs", ui.new_game_frame):SetSize(418, 430):SetPos(10, 30)

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

ui.server_name_label = LF.Create("label", ui.new_game_server):SetPos(0, 0+4):SetText("Server Name")
ui.server_password_label = LF.Create("label", ui.new_game_server):SetPos(0, 25+4):SetText("Server Password")
ui.server_rcon_password_label = LF.Create("label", ui.new_game_server):SetPos(0, 50+4):SetText("RCon Password")
ui.server_port_label = LF.Create("label", ui.new_game_server):SetPos(0, 75+4):SetText("Port (UDP)")
ui.server_maxplayers_label = LF.Create("label", ui.new_game_server):SetPos(0, 100+4):SetText("Max. Players")
ui.server_fow_label = LF.Create("label", ui.new_game_server):SetPos(0, 125+4):SetText("Fog of War")

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


ui.server_voicechat_label = LF.Create("label", ui.new_game_server):SetPos(0, 290+4):SetText("Voice Chat")
ui.server_gamemode_label = LF.Create("label", ui.new_game_server):SetPos(0, 315+4):SetText("Gamemode")
ui.server_spectate_label = LF.Create("label", ui.new_game_server):SetPos(0, 340+4):SetText("Allow to Spectate")

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

ui.server_button_help = LF.Create("button", ui.new_game_server):SetText("Help"):SetPos(0, 370):SetWidth(50)
ui.server_button_start = LF.Create("button", ui.new_game_server):SetText("Start"):SetPos(195, 370):SetWidth(100)
ui.server_button_cancel = LF.Create("button", ui.new_game_server):SetText("Cancel"):SetPos(300, 370):SetWidth(100)

--sandbox = LF.Create("textbox", ui.new_game_server)
--:SetPos(150, 100+3):SetSize(200, 200):SetType("multinowrap")

return ui