local LF = require "lib.loveframes"

return function(ui)
--exit window-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.exit_window = LF.Create("frame")
	:SetSize(400, 300)
	:SetName("Quit?")
	:SetCloseAction("hide")
ui.exit_window_panel = LF.Create("panel", ui.exit_window):SetPos(16, 32):SetSize(368, 230)
ui.exit_window_message = LF.Create("messagebox", ui.exit_window_panel)
	:SetFont(ui.font):SetPos(5, 5):SetMaxWidth(368)
	:SetText([[
Thank you for playing!

Help, FAQ and updates are available at
>> https://c4server.website/ <<

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

end
