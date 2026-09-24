local LG            = love.graphics
local LF            = require "lib.loveframes"
local serpent       = require "lib.serpent"
local client        = require "core.client"

local ui            = {}
ui.font_fallbacks   = {
	--"gfx/fonts/NotoSansCJK-Regular.ttc",
}

--ui.sounds = {}

ui.setFontFallbacks = function(font, size)
	local fallbacks = {}
	for index, fallback_src in ipairs(ui.font_fallbacks) do
		local fallback = LG.newFont(fallback_src, size)
		table.insert(fallbacks, fallback)
	end
	font:setFallbacks(unpack(fallbacks))
end

ui.font_mono        = LG.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 15)
ui.setFontFallbacks(ui.font_mono, 15)

ui.font_mono_small = LG.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 12)
ui.setFontFallbacks(ui.font_mono_small, 12)

ui.font = LG.newFont("gfx/fonts/liberationsans.ttf", 15)
ui.setFontFallbacks(ui.font, 15)

ui.font_small = LG.newFont("gfx/fonts/liberationsans.ttf", 11)
ui.setFontFallbacks(ui.font_small, 11)

ui.font_medium = LG.newFont("gfx/fonts/liberationsans.ttf", 13)
ui.setFontFallbacks(ui.font_small, 13)

ui.font_chat = LG.newFont("gfx/fonts/liberationsans.ttf", 18)
ui.setFontFallbacks(ui.font_chat, 18)

ui.font_big = LG.newFont("gfx/fonts/liberationsans.ttf", 24)
ui.setFontFallbacks(ui.font_chat, 24)

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
	LF.SetCursor(cursorType, imageData, nw / 2, nh / 2)
end

local _, pointers = LF.CreateSpriteSheet("gfx/pointer.bmp", 46, 46)
--ui.setCursor("arrow", pointers[0], 0.6)

function ui.getcoloredtext(text)
	local function fixUTF8(s, replacement)
		local p, len, invalid = 1, #s, {}
		while p <= len do
			if p == s:find("[%z\1-\127]", p) then
				p = p + 1
			elseif p == s:find("[\194-\223][\128-\191]", p) then
				p = p + 2
			elseif p == s:find("\224[\160-\191][\128-\191]", p)
				or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
				or p == s:find("\237[\128-\159][\128-\191]", p)
				or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then
				p = p + 3
			elseif p == s:find("\240[\144-\191][\128-\191][\128-\191]", p)
				or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
				or p == s:find("\244[\128-\143][\128-\191][\128-\191]", p) then
				p = p + 4
			else
				s = s:sub(1, p - 1) .. replacement .. s:sub(p + 1)
				table.insert(invalid, p)
			end
		end
		return s, invalid
	end

	local function parsetext(str)
		local formattedchunks = {}
		local formattedstring = {}
		local defaultColor = { 0, 0, 0, 1 }

		local last = 1
		while true do
			local i, j = str:find("©", last)
			if not i then
				-- restante
				table.insert(formattedchunks, defaultColor)
				table.insert(formattedchunks, str:sub(last))
				table.insert(formattedstring, str:sub(last))
				break
			end

			-- trecho antes do ©
			if i > last then
				local segment = str:sub(last, i - 1)
				table.insert(formattedchunks, defaultColor)
				table.insert(formattedchunks, segment)
				table.insert(formattedstring, segment)
			end

			-- agora pega o próximo trecho até o próximo © ou fim
			local k = str:find("©", j + 1) or (#str + 1)
			local capture = str:sub(j + 1, k - 1)

			local r, g, b = capture:match("(%d%d%d)(%d%d%d)(%d%d%d)")
			local captured_text = capture:sub(10)
			if r and g and b then
				table.insert(formattedchunks, { tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255 })
				table.insert(formattedchunks, captured_text)
				table.insert(formattedstring, captured_text)
			else
				-- não é cor válida, volta o texto inteiro
				local bad = "©" .. capture
				local previousColor
				if #formattedchunks > 0 then
					previousColor = formattedchunks[#formattedchunks - 2]
				else
					previousColor = defaultColor
				end
				table.insert(formattedchunks, previousColor)
				table.insert(formattedchunks, bad)
				table.insert(formattedstring, bad)
			end
			last = k
		end

		return formattedchunks, table.concat(formattedstring)
	end

	local fixed_text = fixUTF8(text, "")
	local formatted_chunk, formatted_text = parsetext(fixed_text)
	return formatted_chunk, formatted_text
end

function ui.getcolortable(color_tag)
	local r, g, b = color_tag:match("(%d%d%d)(%d%d%d)(%d%d%d)")
	if r and g and b then
		return {
			tonumber(r) / 255,
			tonumber(g) / 255,
			tonumber(b) / 255,
			1.0,
		}
	end
	return { 1, 1, 1, 1 }
end

--------------------------------------------------------------------------------------------------
--Toast config------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
LF.toast
	:SetBoxAlign("center", "center")
	:SetOutline(false)
	:SetRelativeBoxWidth(1.0)
	:SetMessageOrder("descending")
	:SetFont(ui.font_big)


ui.pointers = pointers

return ui
