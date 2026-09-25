local LF = require "lib.loveframes"
local LG = love.graphics
local client = require "core.client"

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
		if (cp >= 0x0590 and cp <= 0x05FF) -- Hebrew
			or (cp >= 0x0600 and cp <= 0x06FF) -- Arabic
			or (cp >= 0x0700 and cp <= 0x074F) -- Syriac (às vezes usado em scripts RTL)
			or (cp >= 0x0750 and cp <= 0x077F) -- Arabic Supplement
			or (cp >= 0x0780 and cp <= 0x07BF) -- Thaana
			or (cp >= 0x07C0 and cp <= 0x07FF) -- NKo
			or (cp >= 0x08A0 and cp <= 0x08FF) -- Arabic Extended-A
			or (cp >= 0xFB1D and cp <= 0xFDFF) -- Presentation Forms-A (formas de apresentação árabe)
			or (cp >= 0xFE70 and cp <= 0xFEFF) -- Presentation Forms-B (formas de apresentação árabe)
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



return function(ui)
--chat--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

ui.chat_frame = LF.Create("frame")
	:SetSize(0.25, 0.4)
	:SetState("game")
	:SetScreenLocked(true)
	:ShowCloseButton(false)
	:SetPos(0, -0.2)

ui.chat_frame_message = function(player, message)
	if not (client.joined and player) then return end
	local teams = client.share.config.teams
	local team = teams[player.t or 0]
	local color = team.color and ("©" .. team.color) or "©000255000"
	local messagecolor = "©255220000"
	local deadtag = ""
	if player.h <= 0 then
		deadtag = "©255220000 *DEAD*"
	end
	if hasRTL(message) then
		message = reverse_utf8(message)
	end
	local full_message = string.format("%s%s%s: %s%s", color, player.n, deadtag, messagecolor, message)

	ui.chat_log:AddElement(full_message)

	return full_message
end

ui.chat_frame_server_message = function(message)
	if message:find("@C$") then
		message = message:match("(.+)@C$")
		LF.PushMessage(message, {
			spacing = 1,
			padding = 1,
			outline = false,
			time = 6,
			font = ui.font_big,
		})
	else
		ui.chat_log:AddElement(message)
	end
	return message
end

ui.chat_frame.Draw = function(object)
	local hover = object:GetHover()
	local hovertime = 0
	if hover and object.hovertime > 0 then
		hovertime = love.timer.getTime() - object.hovertime
	end
	local brightness = LF.Mix(0.1, 0.3, LF.Clamp(hovertime * 5, 0, 1))

	LG.setColor(0, 0, 0, brightness)
	LG.rectangle("fill", object.x, object.y, object.width, object.height, 10, 10)

	LG.setColor(0, 0, 0, brightness)

	local skin = LF.GetActiveSkin()
	LG.setColor(0.8, 0.8, 0.8, brightness)
	local drag = skin.images["vdrag.png"]
	local scale = 0.3
	LG.draw(drag, object.x + object.width / 2 - drag:getWidth() / 2 * scale, object.y + 8, 0, scale)
end

ui.chat_log = LF.Create("log", ui.chat_frame)
	:SetWidth(1):SetPos(0, 30):Expand("Down"):SetPadding(0)
	:SetFont(ui.font_chat)


ui.chat_log.internals = {}
--------------------------------------------------------------------------------------------------
--chat input--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

ui.chat_input = LF.Create("input", ui.chat_frame)
	:SetSize(1, 30):SetCharacterLimit(80):SetFont(ui.font_chat)
	:SetColor(1.00, 0.86, 0.00, 1.00)
	:SetCursorColor(1.00, 0.86, 0.00, 1.00)
	:SetHighlightColor(1.00, 0.86, 0.00, 0.20)
	:SetState("game")
	:SetY(0.99)
	:SetVisible(false)

ui.chat_input.Draw = function(object)
	local x = object.x
	local y = object.y
	local textwidth, textheight = object.field:getTextDimensions()
	local vpadding = object:GetVerticalPadding()
	local hpadding = object:GetHorizontalPadding()

	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", x, y, textwidth + hpadding * 2, textheight + vpadding * 2, 5)
end

local chat_key = "return"
ui.chat_input.OnControlKeyPressed = function(object, key)
	if LF.inputobject and LF.inputobject ~= object then return end
	if key == chat_key then
		local visible = ui.chat_input:GetVisible()
		if visible then
			-- Submit
			local text = object:GetText()
			if text ~= "" then
				if text:sub(1, 1) == "/" then
					local console = require "core.interface.console"
					local status = console.parse(text:sub(2))
					if status then
						ui.chat_log:AddElement(status)
					end
				else
					if client.joined then
						client.send(string.format("say %s", text))
					end
				end
			end
			ui.chat_input:SetVisible(false)
			ui.chat_input:Clear(true)
		else
			-- Show
			ui.chat_input:SetVisible(true)
			ui.chat_input:EnableInput(true)
		end
	end
end

end
