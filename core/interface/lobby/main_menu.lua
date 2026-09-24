local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--Main Menu Container-----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.main_menu = LF.Create("container")
ui.main_menu:SetSize(100, 300):SetPos(20, 200)

ui.console_button = LF.Create("textbutton", ui.main_menu)
	:SetPos(0, 0):SetCursor(LF.cursors.hand)
	:SetText("©192192192Console")
	:SetHoverText("©255000000Console")
ui.console_button.OnClick = function(object)
	local console = require "core.interface.console"
	local toggle = not console.frame:GetVisible()

	console.frame
		:SetVisible(toggle)
		:Center()
		:MoveToTop()
end
--Main menu group 1-------------------------------------------------------------------------------
ui.quickplay_button = LF.Create("textbutton", ui.main_menu)
	:SetPos(0, 40):SetCursor(LF.cursors.hand)
	:SetText("©192192192Quick Play")
	:SetHoverText("©255255255Quick Play")
ui.quickplay_button.OnClick = function(self)
	--local console = require "core.interface.console"
	--console.parse("map as_snow")
end

ui.newgame_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192New Game")
	:SetHoverText("©255255255New Game")
	:SetPos(0, 60):SetCursor(LF.cursors.hand)
ui.newgame_button.OnClick = function(self)
	ui.new_game_frame:SetVisible(true):Center():MoveToTop()
end

ui.findservers_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Find Servers")
	:SetHoverText("©255255255Find Servers")
	:SetPos(0, 80):SetCursor(LF.cursors.hand)
ui.findservers_button.OnClick = function(self)
	--[[
	local console = require "core.interface.console"
	console.frame
		:SetVisible(true)
		:Center()
		:MoveToTop()

	local console = require "core.interface.console"
	console.parse("connect 127.0.0.1 36963")
	]]
	ui.find_servers_frame
		:SetVisible(true)
		:Center()
		:MoveToTop()
end
--Main menu group 2---------------------------------------------------------------------------
ui.options_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Options")
	:SetHoverText("©255255255Options")
	:SetPos(0, 120):SetCursor(LF.cursors.hand)
ui.options_button.OnClick = function(self)
	--local bool = ui.options_frame:GetVisible()
	--ui.options_frame:SetVisible(not bool):Center():MoveToTop()
end

ui.friends_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Friends")
	:SetHoverText("©255255255Friends")
	:SetPos(0, 140):SetCursor(LF.cursors.hand)
ui.friends_button.OnClick = function(self)
	--local testframe = LF.Create("frame"):SetResizable(true)
end

ui.mods_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Mods")
	:SetHoverText("©255255255Mods")
	:SetPos(0, 160):SetCursor(LF.cursors.hand)

ui.editor_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Editor")
	:SetHoverText("©255255255Editor")
	:SetPos(0, 180):SetCursor(LF.cursors.hand)
ui.editor_button.OnClick = function(self)
	if client.map then
		local status = client.map:read("maps/de_dust.map")
		if status then
			print(status)
		end
		client.world:clear()
		if client.map.syncEntitiesToWorld then
			client.map:syncEntitiesToWorld(client.world)
		end
	end
	client.scene.switch("editor")
end

ui.help_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Help"):SetHoverText("©255255255Help")
	:SetPos(0, 200):SetCursor(LF.cursors.hand)

ui.discord_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Discord"):SetHoverText("©255255255Discord")
	:SetPos(0, 220):SetCursor(LF.cursors.hand)
--ui.discord_button.OnClick = function(self, key) end
--Main menu group 3-------------------------------------------------------------------------------
ui.quit_button = LF.Create("textbutton", ui.main_menu)
	:SetText("©192192192Quit"):SetHoverText("©255255255Quit")
	:SetPos(0, 260):SetCursor(LF.cursors.hand)
ui.quit_button.OnClick = function() love.event.quit() end



end
