local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
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
ui.options_player_name = LF.Create("label", ui.options_tabs_player):SetText("Player Name: "):SetPos(0, 0 + 4)
ui.options_player_spraylogo = LF.Create("label", ui.options_tabs_player):SetText("Spray Logo: "):SetPos(0, 60 + 4)
ui.options_player_crosshair = LF.Create("label", ui.options_tabs_player):SetText("Crosshair: "):SetPos(0, 200 + 4)

ui.options_player_name_input = LF.Create("textbox", ui.options_tabs_player):SetPos(150, 0 + 2):SetSize(200, 20)
ui.options_player_name_input.OnTextChanged = function(object, textadded)
	local text = object:GetText()
	if text ~= "" then
		client.name = text
	end
end

ui.options_mark_own_player = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 120 + 2)
	:SetText("Mark own Player")
ui.options_lefthanded_players = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 140 + 2)
	:SetText("Lefthand Players")
ui.options_recoil_animations = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 160 + 2)
	:SetText("Recoil Animations")
ui.options_wiggle_animations = LF.Create("checkbox", ui.options_tabs_player):SetPos(150, 180 + 2)
	:SetText("Wiggle Animations")

ui.options_spray_panel = LF.Create("panel", ui.options_tabs_player):SetPos(150, 40):SetSize(60, 60)
ui.options_spray_images = {}
for _, filename in ipairs(love.filesystem.getDirectoryItems("logos")) do
	if filename:find(".bmp") then
		table.insert(ui.options_spray_images, "logos/" .. filename)
	end
end

ui.options_spray_pointer = 1
ui.options_spray_image = LF.Create("image", ui.options_spray_panel)
ui.options_spray_image:SetImage(ui.options_spray_images[ui.options_spray_pointer]):Center()

ui.options_spray_left = LF.Create("button", ui.options_tabs_player):SetPos(150, 100):SetText("L"):SetSize(20, 20)
ui.options_spray_left.OnClick = function(object)
	ui.options_spray_pointer = ui.options_spray_pointer - 1
	if ui.options_spray_pointer <= 0 then
		ui.options_spray_pointer = #ui.options_spray_images
	end
	ui.options_spray_image:SetImage(ui.options_spray_images[ui.options_spray_pointer]):Center()
end
ui.options_spray_right = LF.Create("button", ui.options_tabs_player):SetPos(190, 100):SetText("R"):SetSize(20, 20)
ui.options_spray_right.OnClick = function(object)
	ui.options_spray_pointer = ui.options_spray_pointer + 1
	if ui.options_spray_pointer > #ui.options_spray_images then
		ui.options_spray_pointer = 1
	end
	ui.options_spray_image:SetImage(ui.options_spray_images[ui.options_spray_pointer]):Center()
end

ui.options_spray_r = LF.Create("slider", ui.options_tabs_player):SetPos(220, 40):SetMinMax(0, 255):SetDecimals(0)
	:SetValue(255)
ui.options_spray_g = LF.Create("slider", ui.options_tabs_player):SetPos(220, 60):SetMinMax(0, 255):SetDecimals(0)
	:SetValue(255)
ui.options_spray_b = LF.Create("slider", ui.options_tabs_player):SetPos(220, 80):SetMinMax(0, 255):SetDecimals(0)
	:SetValue(255)

ui.options_spray_r.OnValueChanged = function(object, value)
	ui.options_spray_image:SetColor(value / 255, nil, nil)
end
ui.options_spray_g.OnValueChanged = function(object, value)
	ui.options_spray_image:SetColor(nil, value / 255, nil)
end
ui.options_spray_b.OnValueChanged = function(object, value)
	ui.options_spray_image:SetColor(nil, nil, value / 255)
end



ui.options_crosshair_panel = LF.Create("panel", ui.options_tabs_player):SetPos(150, 210):SetSize(96, 96)
ui.options_crosshair_label = LF.Create("label", ui.options_tabs_player):SetPos(250, 310):SetText("")
ui.options_crosshair_image = LF.Create("image", ui.options_crosshair_panel)
	:SetImage(ui.pointers[0]):SetCentered(true):Center()

ui.options_crosshair_slider = LF.Create("slider", ui.options_tabs_player)
	:SetPos(150, 310):SetWidth(97):SetMinMax(0.2, 1.5)
ui.options_crosshair_slider.OnValueChanged = function(object, value)
	ui.options_crosshair_image:SetScale(value, value)
	ui.options_crosshair_label:SetText(tostring(value))
end
ui.options_crosshair_slider:SetValue(1)

ui.options_button_help = LF.Create("button", ui.options_frame):SetText("Help"):SetPos(0 + 10, 430):SetWidth(50)
ui.options_button_okay = LF.Create("button", ui.options_frame):SetText("Okay"):SetPos(195 + 10, 430):SetWidth(100)
ui.options_button_okay.OnClick = function(object)
	--local slider = ui.options_crosshair_slider:GetValue()
	--ui.setCursor("arrow", pointers[0], slider)
end
ui.options_button_cancel = LF.Create("button", ui.options_frame):SetText("Cancel"):SetPos(300 + 10, 430):SetWidth(100)


	ui.options_frame:SetVisible(false)
end
