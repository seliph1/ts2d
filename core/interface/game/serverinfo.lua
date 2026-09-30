local LF = require "lib.loveframes"

return function(ui)
--server information ui---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.serverinfo = LF.Create("frame")
	--:SetSize( love.graphics.getWidth() - 60, love.graphics.getHeight() - 60 )
	:SetSize(0.9, 0.9)
	:SetScreenLocked(true)
	:SetName("CS2D Server - Info")
	:Center()

ui.serverinfo_panel = LF.Create("scrollpanel", ui.serverinfo)
	:SetSize(0.96, 0.89)
	:SetY(25)
	:CenterX()
	:ShowBackground(true)

ui.serverinfo_text = LF.Create("messagebox", ui.serverinfo_panel)
	:SetMaxWidth(0.97)
	:SetPos(5, 5)
	:SetFont(ui.font_chat)
	:SetText([[
©255255255Welcome on my CS2D Server!
©192192192This is the default server info message. Edit sys/serverinfo.txt to change it.
Remove the file if you don't want to use a server message.
©255000000
- Don't cheat/hack
- Don't spam/flame/flood
- Don't teamkick/hostagekill
- Don't votekick innocent players
©192192192
Have fun!
©255255000
www.cs2d.com
www.usgn.de
www.unrealsoftware.de
]])

ui.serverinfo_button = LF.Create("button", ui.serverinfo)
	:SetText("Close")
	:SetWidth(0.96)
	:SetY(-10)
	:CenterX()


ui.serverinfo:SetVisible(false)

end
