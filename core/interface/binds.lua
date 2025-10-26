local LF = require "lib.loveframes"
local client = require "client"

-- Binds module
return function(ui)
---------- module start ----------

local action_quit = function(key, isrepeat)
	local bool = ui.exit_window:IsVisible()
	ui.exit_window:SetVisible(not bool):MoveToTop():Center()
end

local action_debug = function(key, isrepeat)
	local state = LF.config["DEBUG"]
	LF.config["DEBUG"] = not state
end


local action_chat = function(key, isrepeat)
    --if client.connected then
        --local bool = ui.chat_input_frame:IsVisible()
		--ui.chat_input_frame:SetVisible(not bool):MoveToTop()
    --end
end

local action_selectweapon = function(key, isrepeat)
end

LF.bind("all", "", "escape", action_quit)
LF.bind("all", "", "f1", action_debug)
LF.bind("all", "", "return", action_chat)
LF.bind("all", "", "'", ui.console_button.OnClick)
LF.bind("all", "", "")

---------- module end ------------
end