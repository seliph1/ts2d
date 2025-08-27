local LF = require "lib.loveframes"
local client = require "client"

-- Binds module
return function(ui)
---------- module start ----------

local action_quit = function(key, isrepeat)
	local hoverobject = LF.GetHoverObject()
	if hoverobject and hoverobject.type == "frame" then
		local closebutton = hoverobject.internals[1]
		-- Trigger the close action object
		closebutton.OnClick(0, 0, closebutton)
        return
    end

    local inputobject = LF.GetInputObject()
    if inputobject and inputobject.type == "textbox" then
        
        return
    end


	local bool = ui.exit_window:IsVisible()
	ui.exit_window:SetVisible(not bool):MoveToTop():Center()

end

local action_debug = function(key, isrepeat)
	local state = LF.config["DEBUG"]
	LF.config["DEBUG"] = not state
end


local action_chat = function(key, isrepeat)
    --if client.connected then
        local bool = ui.chat_input_frame:IsVisible()
		ui.chat_input_frame:SetVisible(not bool):MoveToTop()
    --end
end

LF.bind("all", "", "escape", action_quit)
LF.bind("all", "", "f1", action_debug)
LF.bind("all", "", "return", action_chat)
LF.bind("all", "", "'", ui.console_button.OnClick)

---------- module end ------------
end