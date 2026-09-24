local LF = require "lib.loveframes"

return function(ui)
--10-pick menu frame------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.menu_frame = LF.Create("frame")
	:SetSize(272, 440)
	:SetName("Menu")
	:SetCloseAction("hide")
	:SetState("*")
	:SetScreenLocked(true)
	:Center()
ui.menu_buttons = {}
for i = 1, 9 do
	local button = LF.Create("button", ui.menu_frame)
		:SetAlign("left")
		:SetSize(240, 25)
		:SetPos(16, 30 + (i - 1) * 30)
	ui.menu_buttons[i] = button
end

ui.cancel_button = LF.Create("button", ui.menu_frame)
	:SetPos(16, 394):SetSize(240, 25):SetText("©1641641640 ©255255255Cancel"):SetAlign("left")
ui.cancel_button.OnClick = function(object)
	object.parent:SetVisible(false)
end
ui.menu_constructor = function(str)
	local title = ui.menu_frame
	local constructors = {}
	for constructor in (str .. ","):gmatch("(.-),") do
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

			button:SetText(string.format("©164164164%s ©255255255%s", i, text))
			button:SetCaption(caption)
		else -- no constructor
			button:SetEnabled(false)
			button:SetVisible(false)
			button:SetText(string.format("©164164164%s", i))
			button:SetCaption("")
		end
	end
end


function ui.interface_constructor(str)
end


	ui.menu_frame:SetVisible(false)
end
