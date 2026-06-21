--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

local LG = love.graphics
local floor, ceil = math.floor, math.ceil

-- skin table
local skin = {}

-- skin info (you always need this in a skin)
skin.name = "moon"
skin.author = "mozilla"
skin.version = "1.0"

-- get current path
skin.current_path = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\\\])") or "./"

-- Harvest Moon style yellow palette ---------------------------------
-- Tweak these and the whole skin follows.
local pal = {}
pal.cream        = {0.96, 0.90, 0.55, 1.00}    -- main panel / list fill (matches frame.png)
pal.cream_dark   = {0.89, 0.79, 0.40, 1.00}    -- secondary fill (rows, headers, hover)
pal.cream_darker = {0.80, 0.68, 0.28, 1.00}    -- pressed / active / selected fill
pal.gold         = {0.84, 0.62, 0.10, 1.00}    -- gold accent (hover borders, bars)
pal.border       = {0.34, 0.25, 0.08, 1.00}    -- dark-brown outline
pal.text         = {1.00, 1.00, 1.00, 1.00}    	-- dark-brown text
pal.text_soft    = {1.00, 1.00, 1.00, 0.50}    	-- secondary / disabled text
pal.text_strong  = {0.80, 0.80, 0.80, 1.00}     -- emphasized / hover text
pal.slot         = {0.60, 0.80, 0.72, 0.55} -- teal item-slot fill
pal.green        = {0.00, 1.00, 0.00, 1.00} -- teal item-slot fill
pal.highlight    = {0.84, 0.62, 0.10, 0.50}  -- text selection highlight
pal.shadow       = {1.00, 0.96, 0.70, 0.60}   -- light "emboss" highlight on dark text
pal.white        = {1.00, 1.00, 1.00, 1.00}
pal.black        = {0.00, 0.00, 0.00, 1.00}
pal.red			 = {1.00, 0.00, 0.00, 1.00}
pal.grey         = {0.50, 0.50, 0.50, 1.00}
pal.lightgrey    = {0.75, 0.75, 0.75, 1.00}
pal.darkgrey     = {0.25, 0.25, 0.25, 1.00}

-- global border color used throughout the skin
local bordercolor = pal.border

-- add skin directives to this table
skin.directives = {}
-- Text
local pixel_glyphs = 
"ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
"abcdefghijklmnopqrstuvwxyz"..
"0123456789"..
" ,º✿★%'.·*+-×=‾_:;#$^{}[]\\/<>()「」&!?♀฿♪♡█|@©"..
-- Latin-1 Supplement (U+00A0..U+00FF) added to font_page.png
"¡¢£¤¥¦§¨ª«¬®¯°±²³´µ¶¸¹»¼½¾¿"..
"ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß"..
"àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"


local pixel_font_src = skin.current_path.."images/font_page.png"
local pixel_font = love.graphics.newImageFont(pixel_font_src, pixel_glyphs)

skin.directives.text_global = skin.current_path.."images/liberationsans.ttf"
skin.directives.text_fallbacks = {
	--skin.current_path.."images/liberationsans.ttf"
}

local function loadFont(path, option)
	if path:match("%.png$") or path:match("%.png$") then
		local glyphs = option
		return love.graphics.newImageFont(path, glyphs)
	elseif path:match("%.ttf$") or path:match("%.otf$") then
		local size = option
		return love.graphics.newFont(path, size)
	end
end

skin.directives.text_font_height 			= 1
skin.directives.text_default_color		 	= pal.text;
skin.directives.text_default_shadowcolor 	= pal.shadow;
skin.directives.text_default_font_src	 	= pixel_font_src
skin.directives.text_default_font_size	 	= 18
skin.directives.text_default_glyphs			= pixel_glyphs
skin.directives.text_default_font		 	= pixel_font

do
	local fallbacks = {}
	for index, fallback_src in ipairs(skin.directives.text_fallbacks) do
		local fallback = LG.newFont(fallback_src, skin.directives.text_default_font_size)
		fallback:setLineHeight(skin.directives.text_font_height)
		table.insert(fallbacks, fallback)
	end
	skin.directives.text_default_font:setFallbacks(unpack(fallbacks))
end

skin.directives.tooltip_default_font_src	= pixel_font_src
skin.directives.tooltip_default_font		= loadFont(skin.directives.tooltip_default_font_src, pixel_glyphs)
skin.directives.tooltip_default_color 		= {1, 1, 1, 1};

-- controls 
skin.controls = {}
skin.controls.tinyfont = loadFont(skin.current_path.."images/font_page.png", pixel_glyphs)
skin.controls.defaultfont = loadFont(skin.current_path.."images/font_page.png", pixel_glyphs)
skin.controls.smallfont = loadFont(skin.current_path.."images/font_page.png", pixel_glyphs)
skin.controls.titlefont = loadFont(skin.current_path.."images/font_page.png", pixel_glyphs)
skin.controls.imagebuttonfont = loadFont(skin.current_path.."images/font_page2x.png", pixel_glyphs)

--[[
skin.controls.font_sizes = {
	defaultfont 	= 18;
	tinyfont 		= 16;
	smallfont 		= 18;
	titlefont 		= 19;
	imagebuttonfont = 22;
}
if skin.directives.text_default_font_src then
	for size, value in pairs(skin.controls.font_sizes) do
		skin.controls[size] = love.graphics.newFont(skin.directives.text_default_font_src, value)
		skin.controls[size]:setLineHeight(skin.directives.text_font_height)

		if skin.directives.text_fallbacks then
			local fallbacks = {}
			for index, fallback_src in ipairs(skin.directives.text_fallbacks) do
				local fallback = love.graphics.newFont(fallback_src, value)
				fallback:setLineHeight(skin.directives.text_font_height)
				table.insert(fallbacks, fallback)
			end
			skin.controls[size]:setFallbacks(unpack(fallbacks))
		end
	end
end]]

-- skin global colors
skin.controls.text_nohover_color  			= pal.text
skin.controls.text_hover_color  			= pal.text_strong
skin.controls.text_down_color  				= pal.text_strong
skin.controls.text_active_color  			= pal.text_strong
skin.controls.text_toggle_color				= pal.text_soft
skin.controls.text_disabled_color			= pal.text_soft

-- frame
skin.controls.frame_name_color                      = pal.text
skin.controls.frame_name_font                       = skin.controls.titlefont

-- button
skin.controls.button_round_corner					= 0
skin.controls.button_body_color						= pal.cream
skin.controls.button_down_color						= pal.cream_darker
skin.controls.button_nohover_color					= pal.cream
skin.controls.button_hover_color					= pal.cream_dark
skin.controls.button_toggle_color					= pal.cream_dark
skin.controls.button_nonclickable_color				= pal.cream_dark

skin.controls.button_text_color						= pal.text
skin.controls.button_text_down_color                = pal.text_strong
skin.controls.button_text_nohover_color             = pal.text
skin.controls.button_text_hover_color               = pal.text_strong
skin.controls.button_text_toggle_color				= pal.text_soft
skin.controls.button_text_nonclickable_color        = pal.text_soft
skin.controls.button_text_font                      = skin.controls.smallfont

skin.controls.button_border_disabled_color        	= pal.text_soft
skin.controls.button_border_enabled_color			= pal.border

-- imagebutton
skin.controls.imagebutton_text_down_color           = pal.text_strong
skin.controls.imagebutton_text_nohover_color        = pal.text
skin.controls.imagebutton_text_hover_color          = pal.text_strong
skin.controls.imagebutton_text_font                 = skin.controls.imagebuttonfont

-- closebutton
skin.controls.closebutton_body_down_color           = pal.red
skin.controls.closebutton_body_nohover_color        = pal.red
skin.controls.closebutton_body_hover_color          = pal.red

-- progressbar
skin.controls.progressbar_body_color                = pal.cream_dark
skin.controls.progressbar_bar_color                 = pal.gold
skin.controls.progressbar_text_color                = pal.text
skin.controls.progressbar_text_font                 = skin.controls.smallfont

-- scrollarea
skin.controls.scrollarea_body_color                 = pal.cream_dark

-- scrollbody
skin.controls.scrollbody_body_color                 = pal.cream

-- scrollbar
skin.controls.scrollbar_body_down_color				= pal.cream_darker
skin.controls.scrollbar_body_hover_color			= pal.gold
skin.controls.scrollbar_body_nohover_color			= pal.cream_dark

-- slider & button
skin.controls.slider_bar_outline_color              = pal.cream_dark
skin.controls.slider_button_nohover_color           = pal.cream_dark
skin.controls.slider_button_hover_color  	        = pal.gold
skin.controls.slider_button_down_color  	        = pal.cream_darker
skin.controls.slider_button_nonclickable_color		= pal.cream

-- panel
skin.controls.panel_body_color                      = pal.cream

-- list
skin.controls.list_body_color                       = pal.cream

-- tabpanel
skin.controls.tabpanel_body_color                   = pal.cream

-- tabbutton
skin.controls.tab_body_nohover_color                = pal.cream
skin.controls.tab_body_hover_color                  = pal.cream_dark
skin.controls.tab_body_active_color          	    = pal.cream_darker
skin.controls.tab_text_nohover_color                = pal.text
skin.controls.tab_text_hover_color                  = pal.text_strong
skin.controls.tab_text_active_color         		= pal.text_strong
skin.controls.tab_text_font                         = skin.controls.smallfont

-- multichoice
skin.controls.multichoice_body_color                = pal.cream
skin.controls.multichoice_border_hover_color		= pal.gold
skin.controls.multichoice_border_nohover_color		= pal.border
skin.controls.multichoice_border_down_color			= pal.border
skin.controls.multichoice_border_active_color		= pal.gold
skin.controls.multichoice_text_active_color         = pal.text_strong
skin.controls.multichoice_text_color        		= pal.text
skin.controls.multichoice_text_font                 = skin.controls.smallfont

-- multichoicelist
skin.controls.multichoicelist_body_color            = pal.cream_dark

-- multichoicerow
skin.controls.multichoicerow_body_nohover_color     = pal.cream
skin.controls.multichoicerow_body_hover_color       = pal.cream_dark
skin.controls.multichoicerow_text_nohover_color     = pal.text
skin.controls.multichoicerow_text_hover_color       = pal.text_strong
skin.controls.multichoicerow_text_font              = skin.controls.smallfont

-- droplist
skin.controls.droplist_body_nohover_color			= pal.cream
skin.controls.droplist_body_hover_color				= pal.cream_dark
skin.controls.droplist_body_active_color         	= pal.cream_darker
skin.controls.droplist_body_odd_color				= pal.cream
skin.controls.droplist_body_even_color				= pal.cream_dark
skin.controls.droplist_text_nohover_color			= pal.text
skin.controls.droplist_text_hover_color				= pal.text_strong
skin.controls.droplist_text_active_color			= pal.text_strong
skin.controls.droplist_text_font					= skin.controls.smallfont

-- tooltip
skin.controls.tooltip_body_color                    = pal.border
skin.controls.tooltip_font_color                    = pal.cream

-- textbox
skin.controls.textinput_borderhover_color			= pal.gold
skin.controls.textinput_bordernohover_color			= pal.border
skin.controls.textinput_borderactive_color			= pal.gold
skin.controls.textinput_body_color                  = pal.cream
skin.controls.textinput_indicator_color             = pal.black
skin.controls.textinput_text_normal_color           = pal.text
skin.controls.textinput_text_active_color           = pal.text_strong
skin.controls.textinput_text_placeholder_color      = pal.text_soft
skin.controls.textinput_text_selected_color         = pal.text_strong
skin.controls.textinput_highlight_bar_color         = pal.highlight

-- checkbox
skin.controls.checkbox_body_color                   = pal.cream
skin.controls.checkbox_check_color                  = pal.green
skin.controls.checkbox_hover_color                  = pal.gold
skin.controls.checkbox_text_font                    = skin.controls.smallfont

-- radiobutton
skin.controls.radiobutton_check_color               = pal.green
skin.controls.radiobutton_checkinner_color        	= pal.green
skin.controls.radiobutton_hover_color               = pal.gold
skin.controls.radiobutton_inner_border_color        = pal.gold
skin.controls.radiobutton_text_font                 = skin.controls.smallfont

-- collapsiblecategory
skin.controls.collapsiblecategory_text_color        = pal.text

-- columnlist
skin.controls.columnlist_body_color                 = pal.cream

-- columlistarea
skin.controls.columnlistarea_body_color             = pal.cream

-- columnlistheader
skin.controls.columnlistheader_body_down_color		= pal.cream_darker
skin.controls.columnlistheader_body_hover_color		= pal.gold
skin.controls.columnlistheader_body_nohover_color	= pal.cream_dark

skin.controls.columnlistheader_text_down_color      = pal.text_strong
skin.controls.columnlistheader_text_nohover_color   = pal.text
skin.controls.columnlistheader_text_hover_color     = pal.text_strong
skin.controls.columnlistheader_text_font            = skin.controls.tinyfont

-- columnlistrow
skin.controls.columnlistrow_body1_color             = pal.cream
skin.controls.columnlistrow_body2_color             = pal.cream_dark
skin.controls.columnlistrow_body_selected_color     = pal.cream_darker
skin.controls.columnlistrow_body_hover_color        = pal.gold
skin.controls.columnlistrow_text_color              = pal.text
skin.controls.columnlistrow_text_hover_color        = pal.text_strong
skin.controls.columnlistrow_text_selected_color     = pal.text_strong

-- modalbackground
skin.controls.modalbackground_body_color            = {0.20, 0.13, 0.03, 0.45}

-- grid
skin.controls.grid_body_color                       = pal.cream

-- menu & menuoption
skin.controls.menu_body_color                       = pal.cream
skin.controls.menuoption_body_hover_color           = pal.cream_dark
skin.controls.menuoption_text_hover_color           = pal.text_strong
skin.controls.menuoption_text_color                 = pal.text
skin.controls.menuoption_text_font					= skin.controls.tinyfont

-- dial
skin.controls.dial_circle                     		= pal.cream_dark
skin.controls.dial_circle_hover                     = pal.cream
skin.controls.dial_pointer           				= pal.cream_darker
skin.controls.dial_border          					= pal.border

skin.controls.joystick_base                         = pal.cream_dark
skin.controls.joystick_base_hover                   = pal.cream
skin.controls.joystick_border                       = pal.border
skin.controls.joystick_knob                         = pal.cream_darker
skin.controls.joystick_knob_hover                   = pal.gold


local function ParseHeaderText(str, hx, hwidth, tx, twidth)
	local font = love.graphics.getFont()
	twidth = font:getWidth(str) or twidth
	if (tx + twidth) - hwidth/2 > hx + hwidth then
		if #str > 1 then
			return ParseHeaderText(loveframes.utf8.sub(str, 1, #str - 1), hx, hwidth, tx, twidth)
		else
			return str
		end
	else
		return str
	end
end

local function ParseRowText(str, rx, rwidth, tx1, tx2)
	local font = love.graphics.getFont()
	local maxwidth = (rx + rwidth) - (tx1 + tx2)
	if font:getWidth(str) <= maxwidth then
		return str
	end
	-- binary search for the longest prefix that fits. trimming one
	-- character at a time every frame is quadratic per cell, which tanks
	-- the fps when columns get narrow (more characters to trim)
	local utf8 = loveframes.utf8
	local lo, hi = 1, utf8.len(str)
	while lo < hi do
		local mid = math.ceil((lo + hi) / 2)
		if font:getWidth(utf8.sub(str, 1, mid)) <= maxwidth then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return utf8.sub(str, 1, lo)
end

function skin.PrintText(text, x, y)
	love.graphics.print(text, math.floor(x + 0.5), math.floor(y + 0.5))
end


local frameBG = love.graphics.newImage(skin.current_path.."images/frame.png")
local frameBGwidth, frameBGheight = frameBG:getDimensions()

--[[---------------------------------------------------------
	- func: OutlinedRectangle(x, y, width, height, ovt, ovb, ovl, ovr)
	- desc: creates and outlined rectangle
--]]---------------------------------------------------------
function skin.OutlinedRectangle(x, y, width, height, ovt, ovb, ovl, ovr)
	local ovt = ovt or false
	local ovb = ovb or false
	local ovl = ovl or false
	local ovr = ovr or false
	-- top
	if not ovt then
		love.graphics.rectangle("fill", x, y, width, 1)
	end
	-- bottom
	if not ovb then
		love.graphics.rectangle("fill", x, y + height - 1, width, 1)
	end
	-- left
	if not ovl then
		love.graphics.rectangle("fill", x, y, 1, height)
	end
	-- right
	if not ovr then
		love.graphics.rectangle("fill", x + width - 1, y, 1, height)
	end
end

function skin.EmbossedRectangle(x, y, width, height)
	local r,g,b,a = love.graphics.getColor()
	local br = 0.8
	-- top
	love.graphics.setColor(r,g,b, 1)
	love.graphics.rectangle("fill", x, y, width, 1)
	-- left
	love.graphics.setColor(r,g,b, 1)
	love.graphics.rectangle("fill", x, y, 1, height)
	-- bottom
	love.graphics.setColor(r-br,g-br,b-br, 1)
	love.graphics.rectangle("fill", x, y + height - 1, width, 1)
	-- right
	love.graphics.setColor(r-br,g-br,b-br, 1)
	love.graphics.rectangle("fill", x + width - 1, y, 1, height)
end


--[[---------------------------------------------------------
	- func: DrawFrame(object)
	- desc: draws the frame object
--]]---------------------------------------------------------
function skin.frame(object)
	local x = object:GetX()
	local y = object:GetY()
	local width, height = object:GetDimensions()
	local name = object:GetName()
	local icon = object:GetIcon()
	local namecolor = skin.controls.frame_name_color
	local font = skin.controls.frame_name_font

	love.graphics.push()
	love.graphics.translate(x, y)

	-- BG body
	local sx, sy, sw, sh = love.graphics.getScissor()
	love.graphics.setScissor(x, y, width, height)
	love.graphics.setColor(1, 1, 1, 1)
	for xcut = 0, ceil(width/frameBGwidth)-1 do
		for ycut = 0, ceil(height/frameBGheight)-1 do
			love.graphics.draw(frameBG, xcut*frameBGwidth, ycut*frameBGheight)
		end
	end
	love.graphics.setScissor(sx, sy, sw, sh)

	-- frame name section
	love.graphics.setFont(font)
	if icon then
		local iconwidth = icon:getWidth()
		local iconheight = icon:getHeight()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(icon, 10, 5)
		love.graphics.setColor(namecolor)
		skin.PrintText(name, iconwidth + 15, 2)
	else
		love.graphics.setColor(namecolor)
		skin.PrintText(name, 10, 2)
	end
	-- frame top bar
	love.graphics.setColor(bordercolor)
	love.graphics.rectangle("fill", 10, 20, width-25, 1)
	-- frame border
	love.graphics.setColor(bordercolor)
	love.graphics.rectangle("line", 0, 0, width, height)
	love.graphics.pop()
end

--[[---------------------------------------------------------
	- func: DrawButton(object)
	- desc: draws the button object
--]]---------------------------------------------------------
function skin.button(object)
	local x, y = object:GetPos()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local text = object:GetText()
	local caption = object:GetCaption()
	local formattedtext = object:GetFormattedText()
	local formattedcaption = object:GetFormattedCaption()
	local down = object:GetDown()
	local checked = object:GetChecked()
	local enabled = object:GetEnabled()
	local clickable = object:GetClickable()
	local align = object:GetAlign()
	local captionmesh = object:GetDrawableCaption()
	local textmesh = object:GetDrawableText()
	local text_height = textmesh:getHeight()
	local text_width = textmesh:getWidth()
	local padding = object:GetPadding()
	local left_padding = object.left_padding
	local image_padding = object:GetImagePadding()
	local image_align = object:GetImageAlign()

	-- Default color
	local defaultcolor = skin.controls.button_text_color
	-- Text colors
	local textdowncolor = skin.controls.button_text_down_color
	local texthovercolor = skin.controls.button_text_hover_color
	local textnohovercolor = skin.controls.button_text_nohover_color
	local texttogglecolor = skin.controls.button_text_toggle_color
	local textnonclickablecolor = skin.controls.button_text_nonclickable_color
	-- Body colors
	local downcolor = skin.controls.button_down_color
	local hovercolor = skin.controls.button_hover_color
	local nohovercolor = skin.controls.button_nohover_color
	local togglecolor = skin.controls.button_toggle_color
	local nonclickablecolor = skin.controls.button_nonclickable_color
	-- Border colors
	local borderdisabled = skin.controls.button_border_disabled_color
	local borderenabled = skin.controls.button_border_enabled_color
	-- Color pointers
	local textcolor, bodycolor, captioncolor =  textnohovercolor, nohovercolor, textnonclickablecolor
	local bordercolor = bordercolor
	-- Image pointers
	local image_hover = skin.images["button-hover.png"]
	local image_hover_sh = height/image_hover:getHeight()
	local roundcorner = skin.controls.button_round_corner
	local xoffset, yoffset = 0, 0
	local image_x, image_y, image_width, image_height = 0,0,0,0
	local text_x, text_y, caption_x, caption_y = 0, 0, 0, 0

	if hover then
		bodycolor = hovercolor
		textcolor = texthovercolor
		bordercolor = borderenabled
	end
	if down or checked then
		-- Apply -1 -1 offset to make illusion of pressing
		xoffset = xoffset + 1
		yoffset = yoffset + 1
		bodycolor = downcolor
		textcolor = textdowncolor
	end
	if not enabled then
		xoffset = 0 -- Reset the offset if the text isn't clickable
		yoffset = 0
		bordercolor = borderdisabled
		bodycolor = nonclickablecolor
		textcolor = textnonclickablecolor
		hover = false
		down = false
	end

	love.graphics.push()
	love.graphics.translate(x, y)

	if object.image then
		image_width = object.image:getWidth()
		image_height = object.image:getHeight()

		if image_align == "center" then
			image_x = math.floor(xoffset + image_padding - image_width/2)
			image_padding = image_padding - image_width/2
		else
			image_x = math.floor(xoffset + image_padding)
		end
		image_y = math.floor(yoffset + (height - image_height)/2)
	end

	if align == "right" then
		text_x = math.floor(xoffset - padding)
	elseif align == "left" then
		text_x = math.floor(xoffset + math.max(padding, image_width + image_padding) )
	elseif align == "center" then
		text_x = math.floor(xoffset)
	end
	text_y = math.floor(((height - text_height)/2) + yoffset)

	caption_x = math.floor(xoffset - left_padding)
	caption_y = math.floor(((height - text_height)/2) + yoffset)

	if caption ~= formattedcaption then
		captioncolor = defaultcolor
	end
	-- Draw body
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", 0, 0, width, height, roundcorner, roundcorner)

	-- Draw text
	love.graphics.setColor(textcolor)
	love.graphics.draw(textmesh, text_x, text_y)
	-- Draw caption
	love.graphics.setColor(captioncolor)
	love.graphics.draw(captionmesh, caption_x, caption_y)

	-- Image
	if object.image then
		love.graphics.setColor(1, 1, 1, 1)

		if image_align == "center" then
			--love.graphics.draw(object.image, image_x, image_y, 0, 1, 1, image_width/2 - image_x)
			love.graphics.draw(object.image, image_x, image_y)
		else
			love.graphics.draw(object.image, image_x, image_y)
		end
	end

	local hovertime = 0
	if hover and object.hovertime > 0 then
		hovertime = love.timer.getTime() - object.hovertime
	end
	local brightness =  loveframes.Mix(0.1, 0.3, loveframes.Clamp(hovertime*5, 0, 1) )

	-- Button hover shade
	love.graphics.setColor(1, 1, 1, brightness)
	if hover then
		love.graphics.setColor(1, 1, 1, brightness)
	end
	love.graphics.draw(image_hover, 0, 0, 0, width, image_hover_sh/2)

	-- Draw border
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(0, 0, width, height)

	love.graphics.pop()
end

--[[---------------------------------------------------------
	- func: DrawButton(object)
	- desc: draws the button object
--]]---------------------------------------------------------
function skin.textbutton(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local textmesh = object:GetDrawableText()
	local hovertextmesh = object:GetDrawableHoverText()
	local hovertext = object:GetHoverText()
	local text_height = textmesh:getHeight()
	local text_width = textmesh:getWidth()
	local down = object:GetDown()
	local checked = object:GetChecked()
	local enabled = object:GetEnabled()
	local align = object:GetAlign()

	local disabledcolor = skin.controls.text_disabled_color
	local hovercolor = skin.controls.text_hover_color
	local nohovercolor = skin.controls.text_nohover_color

	-- Image, text and color pointers
	local xoffset, yoffset, padding = 0, 0, 3
	local image_x, image_y, image_width, image_height = 0,0,0,0
	local text_x, text_y = 0, 0

	if down or checked then
		-- Apply -1 -1 offset to make illusion of pressing
		xoffset = xoffset + 1
		yoffset = yoffset + 1
	end
	if not enabled then
		xoffset = 0 -- Reset the offset if the text isn't clickable
		yoffset = 0
		down = false
	end
	if object.image then
		image_width = object.image:getWidth()
		image_height = object.image:getHeight()
		if align == "center" then
			image_x = math.floor(x + xoffset + (width - image_width - text_width)/2 )
		elseif align == "left" then
			image_x = math.floor(x + xoffset + padding)
		elseif align == "right" then
			image_x = math.floor(x + xoffset - padding + width - text_width - image_width)
		end
		image_y = math.floor(y + yoffset + (height - image_height)/2)
	end

	if align == "right" then
		text_x = math.floor(x + xoffset - padding)
	elseif align == "left" then
		text_x = math.floor(x + xoffset + padding + image_width)
	elseif align == "center" then
		text_x = math.floor(x + xoffset + image_width/2)
	end
	text_y = math.floor((y + (height - text_height)/2) + yoffset)

	-- Draw Image
	if object.image then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(object.image, image_x, image_y)
	end
	-- Draw Text
	if enabled then
		if hover then
			love.graphics.setColor(hovercolor)
		else
			love.graphics.setColor(nohovercolor)
		end
	else
		love.graphics.setColor(disabledcolor)
	end
	if hover and hovertext ~= "" then
		love.graphics.draw(hovertextmesh, text_x, text_y)
	else
		love.graphics.draw(textmesh, text_x, text_y)
	end
end


--[[---------------------------------------------------------
	- func: DrawCloseButton(object)
	- desc: draws the close button object
--]]---------------------------------------------------------
function skin.closebutton(object)
	local x = object:GetX()
	local y = object:GetY()
	local parent = object.parent
	local parentwidth = parent:GetWidth()
	local hover = object:GetHover()
	local down = object.down
	local image = skin.images["close.png"]
	local bodydowncolor = skin.controls.closebutton_body_down_color
	local bodyhovercolor = skin.controls.closebutton_body_hover_color
	local bodynohovercolor = skin.controls.closebutton_body_nohover_color
	image:setFilter("nearest", "nearest")
	if down then
		-- button body
		love.graphics.setColor(bodydowncolor)
		love.graphics.draw(image, x, y)
	elseif hover then
		-- button body
		love.graphics.setColor(bodyhovercolor)
		love.graphics.draw(image, x, y)
	else
		-- button body
		love.graphics.setColor(bodynohovercolor)
		love.graphics.draw(image, x, y)
	end
	
end

--[[---------------------------------------------------------
	- func: DrawImage(object)
	- desc: draws the image object
--]]---------------------------------------------------------
function skin.image(object)
	local x = object:GetX()
	local y = object:GetY()
	local orientation = object:GetOrientation()
	local scalex = object:GetScaleX()
	local scaley = object:GetScaleY()
	local offsetx = object:GetOffsetX()
	local offsety = object:GetOffsetY()
	local shearx = object:GetShearX()
	local sheary = object:GetShearY()
	local image = object.image
	local color = object.imagecolor
	local stretch = object.stretch
	local centered = object.centered

	if not object.image then
		return
	end

	if stretch then
		scalex, scaley = object:GetWidth() / image:getWidth(), object:GetHeight() / image:getHeight()
	end

	if centered then
		offsetx = offsetx + object.image:getWidth()/2
		offsety = offsety + object.image:getHeight()/2

		x = x + object.image:getWidth()/2
		y = y + object.image:getHeight()/2
	end

	if color then
		love.graphics.setColor(color)
		love.graphics.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
	else
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
	end
end

function skin.imagelink(object)
	local x = object:GetX()
	local y = object:GetY()
	local orientation = object:GetOrientation()
	local scalex = object:GetScaleX()
	local scaley = object:GetScaleY()
	local offsetx = object:GetOffsetX()
	local offsety = object:GetOffsetY()
	local shearx = object:GetShearX()
	local sheary = object:GetShearY()
	local image = object.image
	local color = object.imagecolor
	local stretch = object.stretch
	local hover = object:GetHover()
	if stretch then
		scalex, scaley = object:GetWidth() / image:getWidth(), object:GetHeight() / image:getHeight()
	end
	if color then
		love.graphics.setColor(color)
		love.graphics.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
	else
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
	end
end

--[[---------------------------------------------------------
	- func: DrawImageButton(object)
	- desc: draws the image button object
--]]---------------------------------------------------------
function skin.imagebutton(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local text = object:GetText()
	local hover = object:GetHover()
	local image = object:GetImage()
	local imagecolor = object.imagecolor or {1, 1, 1, 1}
	local down = object.down
	local font = skin.controls.imagebutton_text_font
	local twidth = font:getWidth(object.text)
	local theight = font:getHeight()
	local textdowncolor = skin.controls.imagebutton_text_down_color
	local texthovercolor = skin.controls.imagebutton_text_hover_color
	local textnohovercolor = skin.controls.imagebutton_text_nohover_color
	local checked = object.checked

	if down then
		if image then
			love.graphics.setColor(imagecolor)
			love.graphics.draw(image, x + 1, y + 1)
		end
		love.graphics.setFont(font)
		love.graphics.setColor(0, 0, 0, 1)
		skin.PrintText(text, x + width/2 - twidth/2 + 1, y + height - theight - 5 + 1)
		love.graphics.setColor(textdowncolor)
		skin.PrintText(text, x + width/2 - twidth/2 + 1, y + height - theight - 6 + 1)
	elseif hover then
		if image then
			love.graphics.setColor(imagecolor)
			love.graphics.draw(image, x, y)
		end
		love.graphics.setFont(font)
		love.graphics.setColor(0, 0, 0, 1)
		skin.PrintText(text, x + width/2 - twidth/2, y + height - theight - 5)
		love.graphics.setColor(texthovercolor)
		skin.PrintText(text, x + width/2 - twidth/2, y + height - theight - 6)
	else
		if image then
			love.graphics.setColor(imagecolor)
			love.graphics.draw(image, x, y)
		end
		love.graphics.setFont(font)
		love.graphics.setColor(0, 0, 0, 1)
		skin.PrintText(text, x + width/2 - twidth/2, y + height - theight - 5)
		love.graphics.setColor(textnohovercolor)
		skin.PrintText(text, x + width/2 - twidth/2, y + height - theight - 6)
	end
	if checked == true then
		love.graphics.setColor(bordercolor)
		love.graphics.setLineWidth(3)
		love.graphics.setLineStyle("smooth")
		love.graphics.rectangle("line", x+1, y+1, width-2, height-2)
	end
end

--[[---------------------------------------------------------
	- func: DrawProgressBar(object)
	- desc: draws the progress bar object
--]]---------------------------------------------------------
function skin.progressbar(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local value = object:GetValue()
	local max = object:GetMax()
	local text = object:GetText()
	local barwidth = object:GetBarWidth()
	local font = skin.controls.progressbar_text_font
	local twidth = font:getWidth(text)
	local theight = font:getHeight()
	local bodycolor = skin.controls.progressbar_body_color
	local barcolor = skin.controls.progressbar_bar_color
	local textcolor = skin.controls.progressbar_text_color
	local image = skin.images["progressbar.png"]
	local imageheight = image:getHeight()
	local scaley = height/imageheight

	-- progress bar body
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(image, x, y, 0, barwidth, scaley)
	love.graphics.setFont(font)
	love.graphics.setColor(textcolor)
	skin.PrintText(text, x + width/2 - twidth/2, y + height/2 - theight/2)

	-- progress bar border
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawScrollArea(object)
	- desc: draws the scroll area object
--]]---------------------------------------------------------
function skin.scrollarea(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bartype = object:GetBarType()
	local bodycolor = skin.controls.scrollarea_body_color

	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawScrollBar(object)
	- desc: draws the scroll bar object
--]]---------------------------------------------------------
function skin.scrollbar(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local dragging = object:IsDragging()
	local hover = object:GetHover()
	local bartype = object:GetBarType()
	local bodydowncolor = skin.controls.scrollbar_body_down_color
	local bodyhovercolor = skin.controls.scrollbar_body_hover_color
	local bodynohovercolor = skin.controls.scrollbar_body_nohover_color
	local ox = 2
	local oy = 2
	if dragging then
		love.graphics.setColor(bodydowncolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
	elseif hover then
		love.graphics.setColor(bodyhovercolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
	else
		love.graphics.setColor(bodynohovercolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
	end
	love.graphics.setColor(bordercolor)
	--skin.OutlinedRectangle(x+ox, y+oy, width-ox*2, height-oy*2)
	skin.EmbossedRectangle(x+ox, y+oy, width-ox*2, height-oy*2)
end

--[[---------------------------------------------------------
	- func: DrawScrollBody(object)
	- desc: draws the scroll body object
--]]---------------------------------------------------------
function skin.scrollbody(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.scrollbody_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawScrollButton(object)
	- desc: draws the scroll button object
--]]---------------------------------------------------------
function skin.scrollbutton(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local scrolltype = object:GetScrollType()
	local down = object.down
	local bodydowncolor = skin.controls.scrollbar_body_down_color
	local bodyhovercolor = skin.controls.scrollbar_body_hover_color
	local bodynohovercolor = skin.controls.scrollbar_body_nohover_color
	if down then
		-- button body
		love.graphics.setColor(bodydowncolor)
		love.graphics.rectangle("fill", x, y, width, height)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	elseif hover then
		-- button body
		love.graphics.setColor(bodyhovercolor)
		love.graphics.rectangle("fill", x, y, width, height)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	else
		-- button body
		love.graphics.setColor(bodynohovercolor)
		love.graphics.rectangle("fill", x, y, width, height)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	end
	if scrolltype == "up" then
		local image = skin.images["arrow-up.png"]
		local imagewidth = image:getWidth()
		local imageheight = image:getHeight()
		image:setFilter("nearest", "nearest")
		if hover then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.59)
		end
		love.graphics.draw(image, x + width/2 - imagewidth/2, y + height/2 - imageheight/2)
	elseif scrolltype == "down" then
		local image = skin.images["arrow-down.png"]
		local imagewidth = image:getWidth()
		local imageheight = image:getHeight()
		image:setFilter("nearest", "nearest")
		if hover then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.59)
		end
		love.graphics.draw(image, x + width/2 - imagewidth/2, y + height/2 - imageheight/2)
	elseif scrolltype == "left" then
		local image = skin.images["arrow-left.png"]
		local imagewidth = image:getWidth()
		local imageheight = image:getHeight()
		image:setFilter("nearest", "nearest")
		if hover then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.59)
		end
		love.graphics.draw(image, x + width/2 - imagewidth/2, y + height/2 - imageheight/2)
	elseif scrolltype == "right" then
		local image = skin.images["arrow-right.png"]
		local imagewidth = image:getWidth()
		local imageheight = image:getHeight()
		image:setFilter("nearest", "nearest")
		if hover then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.59)
		end
		love.graphics.draw(image, x + width/2 - imagewidth/2, y + height/2 - imageheight/2)
	end

end


--[[---------------------------------------------------------
	- func: DrawPanel(object)
	- desc: draws the panel object
--]]---------------------------------------------------------
function skin.panel(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.panel_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawScrollPanel(object)
	- desc: draws the panel object
--]]---------------------------------------------------------
function skin.scrollpanel(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.panel_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawContainer(object)
	- desc: draws the panel object
--]]---------------------------------------------------------
function skin.container(object)
	local x = object:GetX()
	local y = object:GetY()
end

--[[---------------------------------------------------------
	- func: DrawList(object)
	- desc: draws the list object
--]]---------------------------------------------------------
function skin.list(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.list_body_color
	
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawList(object)
	- desc: used to draw over the object and its children
--]]---------------------------------------------------------
function skin.list_over(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawTabPanel(object)
	- desc: draws the tab panel object
--]]---------------------------------------------------------
function skin.tabs(object)
end

function skin.tabs_over(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local buttonarea = object.buttonareax
	local buttonareawidth = object.buttonareawidth
	local tabheight = object:GetHeightOfButtons()
	local padding = 2

	love.graphics.setColor(bordercolor)
	love.graphics.rectangle("fill", x + buttonarea - padding, y + tabheight - padding, buttonareawidth, 1)
end
--[[---------------------------------------------------------
	- func: DrawTabButton(object)
	- desc: draws the tab button object
--]]---------------------------------------------------------
function skin.tabbutton(object)
	local x = object:GetX()
	local y = object:GetY()
	local hover = object:GetHover()
	local text = object:GetText()
	local image = object:GetImage()
	local tabnumber = object:GetTabNumber()
	local parent = object:GetParent()
	local ptabnumber = parent:GetTabNumber()
	local font = skin.controls.tab_text_font
	local twidth = font:getWidth(object.text)
	local theight = font:getHeight()
	local imagewidth = 0
	local imageheight = 0

	local bodyhovercolor = skin.controls.tab_body_hover_color
	local bodynohovercolor = skin.controls.tab_body_nohover_color
	local bodyactivecolor = skin.controls.tab_body_color
	local texthovercolor = skin.controls.tab_text_hover_color
	local textnohovercolor = skin.controls.tab_text_nohover_color
	local textactivecolor = skin.controls.tab_text_active_color
	if image then
		image:setFilter("nearest", "nearest")
		imagewidth = image:getWidth()
		imageheight = image:getHeight()
		object.width = imagewidth + 15 + twidth
		if imageheight > theight then
			parent:SetTabHeight(imageheight + 5)
			object.height = imageheight + 5
		else
			object.height = parent.tabheight
		end
	else
		object.width = 10 + twidth
		object.height = parent.tabheight
	end
	
	local padding = 2
	local width  = object:GetWidth()
	local height = object:GetHeight()
	local image_hover = skin.images["button-hover.png"]
	local image_hover_sh = (height/(image_hover:getHeight()-padding))/2

	if tabnumber == ptabnumber then
		-- button body
		--love.graphics.setColor(bodynohovercolor)
		--love.graphics.rectangle("fill", x, y, width, height)
		-- Draw image overlay
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.draw(image_hover, x+padding, y+padding, 0, width-padding*2, image_hover_sh)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x+padding, y+padding, width-padding*2, height-padding*2, nil, true, nil, nil)
		if image then
			-- button image
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(image, x + 5, y + height/2 - imageheight/2)
			-- button text
			love.graphics.setFont(font)
			love.graphics.setColor(textactivecolor)
			skin.PrintText(text, x + imagewidth + 10, y + height/2 - theight/2)
		else
			-- button text
			love.graphics.setFont(font)
			love.graphics.setColor(textactivecolor)
			skin.PrintText(text, x + 5, y + height/2 - theight/2)
		end
	else
		-- button body
		--local gradient = skin.images["button-nohover.png"]
		--local gradientheight = gradient:getHeight()
		--local scaley = height/gradientheight
		--love.graphics.setColor(bodynohovercolor)
		--love.graphics.rectangle("fill", x, y, width, height)
		--love.graphics.draw(gradient, x, y, 0, width, scaley)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x+padding, y+padding, width-padding*2, height-padding*2, nil, true, nil, nil)
		if image then
			-- button image
			love.graphics.setColor(1, 1, 1, 0.59)
			love.graphics.draw(image, x + 5, y + height/2 - imageheight/2)
			-- button text
			love.graphics.setFont(font)
			if hover then
				love.graphics.setColor(texthovercolor)
			else
				love.graphics.setColor(textnohovercolor)
			end
			skin.PrintText(text, x + imagewidth + 10, y + height/2 - theight/2)
		else
			-- button text
			love.graphics.setFont(font)
			if hover then
				love.graphics.setColor(texthovercolor)
			else
				love.graphics.setColor(textnohovercolor)
			end
			skin.PrintText(text, x + 5, y + height/2 - theight/2)
		end
	end
end

--[[---------------------------------------------------------
	- func: DrawMultiChoice(object)
	- desc: draws the multi choice object
--]]---------------------------------------------------------
function skin.multichoice(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local text = object:GetText()
	local choice = object:GetChoice()
	local image = skin.images["multichoice-arrow.png"]
	local font = skin.controls.multichoice_text_font
	local theight = font:getHeight()
	local hover = object:GetHover()
	local haslist = object.haslist

	local bodycolor = skin.controls.multichoice_body_color
	local textcolor = skin.controls.multichoice_text_color
	local textactivecolor = skin.controls.multichoice_text_active_color
	local borderhovercolor = skin.controls.multichoice_border_hover_color
	local bordernohovercolor = skin.controls.multichoice_border_nohover_color
	local borderactivecolor = skin.controls.multichoice_border_active_color
	local offset = math.floor((height - image:getHeight())/2)
	-- Draw frame body
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x + 1, y + 1, width - 2, height - 2)
	-- Draw selected option
	if haslist then
		love.graphics.setColor(textactivecolor)
		love.graphics.setFont(font)
	else
		love.graphics.setColor(textcolor)
		love.graphics.setFont(font)
	end
	if choice == "" then
		skin.PrintText(text, x + 5, y + height/2 - theight/2)
	else
		skin.PrintText(choice, x + 5, y + height/2 - theight/2)
	end
	-- Draw downarrow button
	image:setFilter("nearest", "nearest")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(image, x + width - 20, y + offset)
	-- Draw border
	if haslist then
		love.graphics.setColor(borderactivecolor)
	else
		if hover then
			love.graphics.setColor(borderhovercolor)
		else
			love.graphics.setColor(bordernohovercolor)
		end
	end
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawMultiChoiceList(object)
	- desc: draws the multi choice list object
--]]---------------------------------------------------------
function skin.multichoicelist(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.multichoicelist_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
end

function skin.multichoicelist_over(object)
	local skin = object:GetSkin()
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y - 1, width, height + 1)
end

--[[---------------------------------------------------------
	- func: DrawMultiChoiceRow(object)
	- desc: draws the multi choice row object
--]]---------------------------------------------------------
function skin.multichoicerow(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local text = object:GetText()
	local font = skin.controls.multichoicerow_text_font
	local bodyhovecolor = skin.controls.multichoicerow_body_hover_color
	local texthovercolor = skin.controls.multichoicerow_text_hover_color
	local bodynohovercolor = skin.controls.multichoicerow_body_nohover_color
	local textnohovercolor = skin.controls.multichoicerow_text_nohover_color
	local hpadding = 5
	local vpadding = 2
	love.graphics.setFont(font)
	if object.hover then
		love.graphics.setColor(bodyhovecolor)
		love.graphics.rectangle("fill", x, y, width, height)
		love.graphics.setColor(texthovercolor)
		skin.PrintText(text, x + hpadding, y + vpadding)
	else
		love.graphics.setColor(bodynohovercolor)
		love.graphics.rectangle("fill", x, y, width, height)
		love.graphics.setColor(textnohovercolor)
		skin.PrintText(text, x + hpadding, y + vpadding)
	end
end

--[[---------------------------------------------------------
	- func: DrawToolTip(object)
	- desc: draws the tool tip object
--]]---------------------------------------------------------
function skin.tooltip(object)
	local x, y = love.mouse.getPosition()
	local text = object.tooltip
	local font = skin.directives.tooltip_default_font
	local width = font:getWidth(text)
	local height = font:getHeight()
	local margin = 4
	local offset_x = math.floor(x - width/2)
	+ math.max(0, math.floor( width/2 - x + margin))
	- math.max(0, math.floor( width/2 + x + margin - love.graphics.getWidth()))
	local offset_y = y + 30
	if y + 30 + height + margin > love.graphics.getHeight() then
		offset_y = y - 30
	end

	local bodycolor = skin.controls.tooltip_body_color
	local textcolor = skin.controls.tooltip_font_color
	local time = object:GetHoverTime()

	if time > 0.5 then
		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", offset_x - margin, offset_y - margin, width + margin*2, height + margin*2, 5, 5)
		love.graphics.setColor(textcolor)
		love.graphics.setFont(font)
		love.graphics.print(text, offset_x, offset_y)
	end
end


--[[---------------------------------------------------------
	- func: Label(object)
	- desc: draws the text object
--]]---------------------------------------------------------
function skin.label(object)
	local textmesh = object.textmesh
	local x = object.x
	local y = object.y

	local parent = object.parent
	local nohovercolor = skin.controls.text_hover_color
	local disabledcolor = skin.controls.text_disabled_color

	love.graphics.setColor(nohovercolor)
	if parent and parent.grayable and not parent.enabled then
		love.graphics.setColor(disabledcolor)
	end
	if object.color then
		love.graphics.setColor(object.color)
	end
	love.graphics.draw(textmesh, x, y)
end

--[[---------------------------------------------------------
	- func: skin.MessageBox(object)
	- desc: draws the text object
--]]---------------------------------------------------------
function skin.messagebox(object)
	local x = math.floor(object.x)
	local y = math.floor(object.y)
	local textmesh = object.textmesh
	local shadow = object.shadow
	if shadow then
		love.graphics.setColor(pal.shadow)
		love.graphics.draw(textmesh, x+1, y+1)
	end
	love.graphics.setColor(pal.text)
	love.graphics.draw(textmesh, x, y)
end
--[[---------------------------------------------------------
	- func: skin.rtf(object)
	- desc: draws the rich text format object
--]]---------------------------------------------------------
function skin.rtf(object)
	local x = object.x
	local y = object.y

	local field = object.field
	love.graphics.setColor(1,1,1,1)
	field:draw(x, y)
end

function skin.rtf_over(object)
	local x = object.x
	local y = object.y
end

--[[---------------------------------------------------------
	- func: skin.sysl(object)
	- desc: draws the sysl dialogue box (panel + typewriter
			text + a blinking "continue" arrow)
--]]---------------------------------------------------------
function skin.sysl(object)
	local x = floor(object.x)
	local y = floor(object.y)
	local width = object.width
	local height = object.height
	local padding = object.padding or 12

	-- dialogue panel
	love.graphics.setColor(pal.cream)
	love.graphics.rectangle("fill", x, y, width, height, 6, 6)
	love.graphics.setColor(pal.gold)
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", x + 0.5, y + 0.5, width - 1, height - 1, 6, 6)

	-- text, clipped to the inner region
	local sx, sy, sw, sh = love.graphics.getScissor()
	love.graphics.setScissor(x + padding, y + padding, width - padding * 2, height - padding * 2)
	love.graphics.setColor(1, 1, 1, 1)
	object.field:draw(x + padding, y + padding)
	love.graphics.setScissor(sx, sy, sw, sh)

	-- blinking continue arrow once the current page has printed
	if object:IsFinished() and floor(object.blink * 2) % 2 == 0 then
		local ax = x + width - padding - 10
		local ay = y + height - padding - 8
		love.graphics.setColor(pal.gold)
		love.graphics.polygon("fill", ax, ay, ax + 10, ay, ax + 5, ay + 6)
	end

	love.graphics.setColor(1, 1, 1, 1)
end

--[[---------------------------------------------------------
	- func: DrawTextBox(object)
	- desc: draws the text object
--]]---------------------------------------------------------
function skin.textbox(object)
	local x = object.x
	local y = object.y
	local width = object:GetWidth()
	local height = object:GetHeight()
	local vpadding = object:GetVerticalPadding()
	local hpadding = object:GetHorizontalPadding()
	local focus = object:GetFocus()
	local field = object.field
	local font = object:GetFont()
	local font_height = font:getHeight()
	local blink_phase = field:getBlinkPhase()
	local placeholder_text = field:getPlaceholderText()
	local text_length = field:getTextLength()

	-- Colors
	local bodycolor = skin.controls.textinput_body_color
	local textnormalcolor = skin.controls.textinput_text_normal_color
	local textplaceholdercolor = skin.controls.textinput_text_placeholder_color
	local textactivecolor = skin.controls.textinput_text_active_color
	local highlightbarcolor = skin.controls.textinput_highlight_bar_color
	local indicatorcolor = skin.controls.textinput_indicator_color

	love.graphics.setFont(font)

	-- Draw body
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)

	-- Draw placeholder text
	love.graphics.setColor(textplaceholdercolor)
	if text_length == 0 and placeholder_text ~= "" then
		skin.PrintText(placeholder_text, x + hpadding, y + vpadding)
	end

	-- Draw the selected text
	love.graphics.setColor(highlightbarcolor)
	for _, selection_x, selection_y, selection_w, selection_h in field:eachSelection() do
		if selection_y >= -font_height and selection_y + selection_h <= height + font_height then
			love.graphics.rectangle("fill", selection_x + x + hpadding, selection_y + y + vpadding, selection_w, selection_h)
		end
	end

	-- Draw text
	if focus then
		love.graphics.setColor(textactivecolor)
	else
		love.graphics.setColor(textnormalcolor)
	end
	if object.color then
		love.graphics.setColor(object.color)
	end
	for _, text, line_x, line_y in field:eachVisibleLine() do
		if line_y >= -font_height and line_y <= height + font_height then
			skin.PrintText(text, x + hpadding + line_x, y + vpadding + line_y)
		end
	end

	-- Draw cursor blinking
	if focus and (blink_phase/ 0.90) % 1 < .5 then
		local cursor_x, cursor_y, cursor_height = field:getCursorLayout()
		if cursor_x >= 0 and cursor_x <= width and cursor_y >= -font_height and cursor_y <= height + font_height then
			love.graphics.setColor(indicatorcolor)
			love.graphics.rectangle("fill", cursor_x + x + hpadding, cursor_y + y + vpadding, 1, cursor_height)
		end
	else
		-- void
	end

	-- Draw the scroll bar
	local canScrollH, canScrollV                 = field:canScroll()
	local hOffset, hCoverage, vOffset, vCoverage = field:getScrollHandles()
	local hHandleLength = hCoverage * width
	local vHandleLength = vCoverage * height
	local hHandlePos    = hOffset   * width
	local vHandlePos    = vOffset   * height
	
	if hHandleLength < width then
		love.graphics.setColor(textactivecolor)
		--love.graphics.rectangle("fill", x+width - 2, y+vHandlePos, 2, vHandleLength)
		love.graphics.rectangle("fill", x+hHandlePos, y+height-2, hHandleLength, 2)
	end
end

function skin.textbox_over(object)
	local x = object.x
	local y = object.y
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local focus = object:GetFocus()

	local borderhover = skin.controls.textinput_borderhover_color
	local bordernohover = skin.controls.textinput_bordernohover_color
	local borderactive = skin.controls.textinput_borderactive_color

	if focus then
		love.graphics.setColor(borderactive)
	else
		if hover then
			love.graphics.setColor(borderhover)
		else
			love.graphics.setColor(bordernohover)
		end
	end
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: DrawInput(object)
	- desc: draws a simple input 
--]]---------------------------------------------------------
function skin.input(object)
end

function skin.input_over(object)
end
--[[---------------------------------------------------------
	- func: skin.DrawSlider(object)
	- desc: draws the slider object
--]]---------------------------------------------------------
function skin.slider(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local slidtype = object:GetSlideType()
	local baroutlinecolor = skin.controls.slider_bar_outline_color
	local wideness_v, wideness_h = object:GetButtonSize()
	if slidtype == "horizontal" then
		love.graphics.setColor(baroutlinecolor)
		love.graphics.rectangle("fill", x, y + height/2 - wideness_h/2, width, wideness_h)
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y + height/2 - wideness_h/2, width, wideness_h)
		
	elseif slidtype == "vertical" then
		
		love.graphics.setColor(baroutlinecolor)
		love.graphics.rectangle("fill", x + width/2 - wideness_v/2, y, wideness_v, height)
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x + width/2 - wideness_v/2, y, wideness_v, height)
	end

end

--[[---------------------------------------------------------
	- func: skin.dial(object)
	- desc: draws the dial object
--]]---------------------------------------------------------
function skin.dial(object)
	local cx = object.x + object.width/2
	local cy = object.y + object.height/2
	local radius = math.min(object.width, object.height)/2
	local angle = math.rad(object.angle)
	local enabled = object.enabled
	local hover = object.hover

	-- body
	if not enabled then
		love.graphics.setColor(skin.controls.dial_circle)
	elseif hover or object.dragging then
		love.graphics.setColor(skin.controls.dial_circle_hover)
	else
		love.graphics.setColor(skin.controls.dial_circle)
	end
	love.graphics.circle("fill", cx, cy, radius)
	love.graphics.setColor(skin.controls.dial_border)
	love.graphics.circle("line", cx, cy, radius)

	-- indicator (0 = up, clockwise)
	local ix = cx + math.sin(angle) * (radius - 10)
	local iy = cy - math.cos(angle) * (radius - 10)
	love.graphics.setColor(skin.controls.dial_pointer)
	love.graphics.setLineWidth(2)
	love.graphics.line(cx, cy, ix, iy)
	love.graphics.setLineWidth(1)
	love.graphics.circle("fill", ix, iy, 3)
end

--[[---------------------------------------------------------
	- func: skin.joystick(object)
	- desc: draws the virtual joystick (base well + knob)
--]]---------------------------------------------------------
function skin.joystick(object)
	local cx = object.x + object.width / 2
	local cy = object.y + object.height / 2
	local radius = object:GetBaseRadius()
	local knobr = object.knobsize / 2
	local enabled = object.enabled
	local hover = object.hover
	local active = object.dragging

	-- base well
	if not enabled then
		love.graphics.setColor(skin.controls.joystick_base)
	elseif hover or active then
		love.graphics.setColor(skin.controls.joystick_base_hover)
	else
		love.graphics.setColor(skin.controls.joystick_base)
	end
	love.graphics.circle("fill", cx, cy, radius)
	love.graphics.setColor(skin.controls.joystick_border)
	love.graphics.circle("line", cx, cy, radius)

	-- range guide
	love.graphics.setColor(skin.controls.joystick_border[1], skin.controls.joystick_border[2], skin.controls.joystick_border[3], 0.35)
	love.graphics.circle("line", cx, cy, object:GetMaxDistance())

	-- knob
	local kx = cx + object.knobx
	local ky = cy + object.knoby
	if active then
		love.graphics.setColor(skin.controls.joystick_knob_hover)
	else
		love.graphics.setColor(skin.controls.joystick_knob)
	end
	love.graphics.circle("fill", kx, ky, knobr)
	love.graphics.setColor(skin.controls.joystick_border)
	love.graphics.circle("line", kx, ky, knobr)
end

--[[---------------------------------------------------------
	- func: skin.slideshow(object)
	- desc: draws the slideshow background (behind the slide)
--]]---------------------------------------------------------
function skin.slideshow(object)
	love.graphics.setColor(0.18, 0.18, 0.2, 1)
	love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
end

--[[---------------------------------------------------------
	- func: skin.slideshow_over(object)
	- desc: draws the slideshow border and navigation dots
--]]---------------------------------------------------------
function skin.slideshow_over(object)
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
	local r = object.dotradius
	for i, dot in ipairs(object.dots) do
		if i == object.tab then
			love.graphics.setColor(0.4, 0.55, 1, 1)
			love.graphics.circle("fill", dot.x, dot.y, r)
		else
			love.graphics.setColor(0.78, 0.78, 0.78, 0.85)
			love.graphics.circle("fill", dot.x, dot.y, r - 1)
		end
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.circle("line", dot.x, dot.y, r)
	end
end

--[[---------------------------------------------------------
	- func: skin.DrawSliderButton(object)
	- desc: draws the slider button object
--]]---------------------------------------------------------
function skin.sliderbutton(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local down = object.down
	local parent = object:GetParent()
	local enabled = parent:GetEnabled()

	local nonclickablecolor = skin.controls.slider_button_nonclickable_color
	local bodydowncolor = skin.controls.slider_button_down_color
	local bodyhovercolor = skin.controls.slider_button_hover_color
	local bodynohovercolor = skin.controls.slider_button_nohover_color

	local ox = 2
	local oy = 2
	if not enabled then
		-- button body
		love.graphics.setColor(nonclickablecolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.EmbossedRectangle(x+ox, y+oy, width-ox*2, height-oy*2)
		return
	end
	if down then
		-- button body
		love.graphics.setColor(bodydowncolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.EmbossedRectangle(x+ox, y+oy, width-ox*2, height-oy*2)
	elseif hover then
		-- button body
		love.graphics.setColor(bodyhovercolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.EmbossedRectangle(x+ox, y+oy, width-ox*2, height-oy*2)
	else
		-- button body
		love.graphics.setColor(bodynohovercolor)
		love.graphics.rectangle("fill", x+ox, y+oy, width-ox*2, height-oy*2)
		-- button border
		love.graphics.setColor(bordercolor)
		skin.EmbossedRectangle(x+ox, y+oy, width-ox*2, height-oy*2)
	end
end

--[[---------------------------------------------------------
	- func: skin.DrawCheckBox(object)
	- desc: draws the check box object
--]]---------------------------------------------------------
function skin.checkbox(object)
	local x = object:GetX()
	local y = object:GetY()
	local box_width = object:GetBoxWidth()
	local box_height = object:GetBoxHeight()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local checked = object:GetChecked()
	local enabled = object:GetEnabled()
	local hover = object:GetHover()
	local bodycolor = skin.controls.checkbox_body_color
	local checkcolor = skin.controls.checkbox_check_color
	local hovercolor = skin.controls.checkbox_hover_color
	local disabledcolor = skin.controls.text_disabled_color

	local offset = math.floor((height - box_height)/2)
	local close_image = skin.images["ok.png"]
	local half_width = ( box_width - close_image:getWidth() )/2
	local half_height = ( box_height - close_image:getHeight() )/2

	-- Rectangle box
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y + offset, box_width, box_height)

	-- Ghost check
	if enabled then
		if hover then
			love.graphics.setColor(hovercolor)
		else -- not hover
			love.graphics.setColor(bordercolor)
		end
	else
		love.graphics.setColor(disabledcolor)
	end
	-- Border
	skin.OutlinedRectangle(x, y + offset, box_width, box_height)

	-- Checker
	if checked then
		love.graphics.setColor(checkcolor)
		love.graphics.draw(close_image, x + half_width, y + half_height)
	end
end

--[[---------------------------------------------------------
	- func: skin.DrawRadioButton(object)
	- desc: draws the radio button object
--]]---------------------------------------------------------
function skin.radiobutton(object)
	local x, y = object:GetPos()
	local width, height = object:GetDimensions()
	local box_width = object:GetBoxWidth()
	local box_height = object:GetBoxHeight()
	local checked = object:GetChecked()
	local enabled = object:GetEnabled()
	local hover = object:GetHover()
	local checkcolor = skin.controls.radiobutton_check_color
	local checkinnercolor = skin.controls.radiobutton_checkinner_color
	local hovercolor = skin.controls.radiobutton_hover_color
	local disabledcolor = skin.controls.text_disabled_color
	local radius = (box_width + box_height)/4
	local offsetX = radius
	local offsetY = radius + (height - box_height)/2
	love.graphics.push()
	love.graphics.translate(x, y)

	-- Circle
	if enabled then
		if hover then
			love.graphics.setColor(hovercolor)
		else
			love.graphics.setColor(bordercolor)
		end
	else
		love.graphics.setColor(disabledcolor)
	end
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(1)
	love.graphics.circle("line", offsetX, offsetY, radius, 15)

	if checked then
		love.graphics.setColor(checkinnercolor)
		love.graphics.circle("fill", offsetX, offsetY, radius/2, 360)
		love.graphics.setColor(checkcolor)
		love.graphics.circle("line", offsetX, offsetY, radius/2, 360)
	end

	love.graphics.pop()
end

--[[---------------------------------------------------------
	- func: skin.DrawCollapsibleCategory(object)
	- desc: draws the collapsible category object
--]]---------------------------------------------------------
function skin.collapsiblecategory(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local text = object:GetText()
	local open = object:GetOpen()
	local textcolor = skin.controls.collapsiblecategory_text_color
	local font = skin.controls.smallfont
	
	love.graphics.setColor(1, 1, 1, 1)
	--love.graphics.draw(image, x, y, 0, width, scaley)
	
	love.graphics.setColor(1, 1, 1, 1)
	--love.graphics.draw(topbarimage, x, y, 0, topbarimage_scalex, topbarimage_scaley)
	
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
	
	love.graphics.setColor(1, 1, 1, 1)
	if open then
		local icon = skin.images["collapse.png"]
		icon:setFilter("nearest", "nearest")
		love.graphics.draw(icon, x + width - 21, y + 5)
		love.graphics.setColor(1, 1, 1, 0.27)
		skin.OutlinedRectangle(x + 1, y + 1, width - 2, 24)
	else
		local icon = skin.images["expand.png"]
		icon:setFilter("nearest", "nearest")
		love.graphics.draw(icon, x + width - 21, y + 5)
		love.graphics.setColor(1, 1, 1, 0.27)
		skin.OutlinedRectangle(x + 1, y + 1, width - 2, 23)
	end
	
	love.graphics.setFont(font)
	love.graphics.setColor(textcolor)
	skin.PrintText(text, x + 5, y + 5)
end
--[[---------------------------------------------------------
	- func: skin.DrawDropList(object)
	- desc: draws the drop list object
--]]---------------------------------------------------------
function skin.droplist(object)
	local highlight = object.highlight
	local zebra_list = object.zebra_list
	local even_list = object.even_list
	local odd_list = object.odd_list
	local height = object:GetHeight()
	local width = object:GetWidth()
	local font = object:GetFont()
	local font_height = font:getHeight()
	local padding = object:GetPadding()
	local x = object:GetX()
	local y = object:GetY()
	local text = object.texthash
	local selected = object.selected
	local hovered = object.hovered
	local elements = object.elements
	local background = object.background
	local body1color = skin.controls.columnlistrow_body1_color
	local body2color = skin.controls.columnlistrow_body2_color

	-- droplist
	local bodynohovercolor = skin.controls.droplist_body_nohover_color
	local bodyhovercolor = skin.controls.droplist_body_hover_color
	local bodyactivecolor = skin.controls.droplist_body_active_color
	local bodyoddcolor = skin.controls.droplist_body_odd_color
	local bodyevencolor = skin.controls.droplist_body_even_color
	local texthovercolor = skin.controls.droplist_text_hover_color
	local textnohovercolor = skin.controls.droplist_text_nohover_color
	local textactivecolor = skin.controls.droplist_text_active_color

	-- Retrieve the cell size
	local cell_width = width
	local cell_height = font_height + padding
	
	--love.graphics.setColor(bodycolor)
	if background then
		love.graphics.setColor(background)
		love.graphics.rectangle("fill", x, y, width, height)
	elseif zebra_list then
		love.graphics.setColor(bodyoddcolor)
		love.graphics.draw(odd_list, x, y)

		love.graphics.setColor(bodyevencolor)
		love.graphics.draw(even_list, x, y)
	else
		love.graphics.setColor(bodynohovercolor)
		love.graphics.rectangle("fill", x, y, width, height)
	end
	love.graphics.setColor(textnohovercolor)
	love.graphics.draw(text, x, y)

	if highlight and hovered ~= 0 then
		local cell_x = x
		local cell_y = y + (hovered-1) * cell_height
		local text_y = y + (hovered-1) * cell_height + padding/2
		local h_text = elements[hovered] or ""

		love.graphics.setColor(bodyhovercolor)
		love.graphics.rectangle("fill", cell_x, cell_y, cell_width, cell_height)

		love.graphics.setColor(texthovercolor)
		love.graphics.setFont(font)
		love.graphics.print(h_text, cell_x, text_y)
	end

	if highlight and selected ~= 0 then
		local cell_x = x
		local cell_y = y + (selected-1) * cell_height
		local text_y = y + (selected-1) * cell_height + padding/2
		local h_text = elements[selected] or ""

		love.graphics.setColor(bodyactivecolor)
		love.graphics.rectangle("fill", cell_x, cell_y, cell_width, cell_height)

		love.graphics.setColor(textactivecolor)
		love.graphics.setFont(font)
		love.graphics.print(h_text, cell_x, text_y)
	end
end

function skin.droplist_over(object)
end
--[[---------------------------------------------------------
	- func: skin.DrawDropList(object)
	- desc: draws the drop list object
--]]---------------------------------------------------------
function skin.log(object)
	local x = object:GetX()
	local y = object:GetY()
	local offsetx = object.offsetx
	local offsety = object.offsety
	local text = object.texthash
	-- Retrieve the cell size
	local fx = math.floor(x - offsetx)
	local fy = math.floor(y - offsety)

	if object.shadow then
		love.graphics.setColor(skin.directives.text_default_shadowcolor)
		love.graphics.draw(text, fx+1, fy+1)
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(text, fx, fy)
end

--[[---------------------------------------------------------
	- func: skin.DrawToast(object)
	- desc: draws the toast object
--]]---------------------------------------------------------
function skin:toast()
	local x, y = self:GetPos()
    local width, height = self:GetDimensions()
	local shadow = self.shadow

	love.graphics.push()
	-- Draw some toast on the screen (or container subset)
	love.graphics.translate(x, y)

    -- Calculate total height
    local total_height = 0
    for _, msg in ipairs(self.messages) do
        total_height = total_height + msg.height + msg.spacing
    end

    local start_y = 0
	if self.box_halign == "center" then
		start_y = math.floor((height - total_height) / 2)
	elseif self.box_halign == "up" then
		start_y = self.box_margin
	elseif self.box_halign == "down" then
		start_y = (height - total_height) - self.box_margin
	else
		start_y = math.floor((height - total_height) / 2)
	end
    local current_y = start_y

    local box_width = math.floor(width * self.relative_box_width)
    local box_x = 0
	if self.box_valign == "center" then
		box_x = math.floor((width - box_width) / 2)
	elseif self.box_valign == "right" then
		box_x = math.floor(width * ( 1 - self.relative_box_width) ) - self.box_margin
	elseif self.box_valign == "left" then
		box_x = self.box_margin
	end

	for i = 1, #self.messages do
		local msg
		if self.message_order == "ascending" then
			msg = self.messages[ (#self.messages - i) + 1 ]
		elseif self.message_order == "descending" then
			msg = self.messages[i]
		end
		if msg.outline then
			-- Background
			if self.backgroundcolor then
				love.graphics.setColor(
					self.backgroundcolor[1],
					self.backgroundcolor[2],
					self.backgroundcolor[3],
					self.backgroundcolor[4] * msg.alpha
				)
			else
				love.graphics.setColor(
					pal.cream[1], pal.cream[2], pal.cream[3],
					pal.cream[4] * msg.alpha
				)
			end
			love.graphics.rectangle(
				"fill",
				box_x,
				current_y,
				box_width,
				msg.height,
				6,
				6
			)

			love.graphics.setColor(
				pal.border[1], pal.border[2], pal.border[3],
				pal.border[4] * msg.alpha
			)

			love.graphics.rectangle(
				"line",
				box_x,
				current_y,
				box_width,
				msg.height,
				6,
				6
			)
		end
		local msg_x = box_x + msg.margin

		-- shadow
		if shadow then
			love.graphics.setColor(0, 0, 0, msg.alpha)
			love.graphics.draw(msg.batch, msg_x + 1, current_y + msg.padding+1)
		end

        -- Text
        love.graphics.setColor(1, 1, 1, msg.alpha)
		love.graphics.draw(msg.batch, msg_x, current_y + msg.padding)

        current_y = current_y + msg.height + msg.spacing
    end

	love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

--[[---------------------------------------------------------
	- func: skin.DrawColumnList(object)
	- desc: draws the column list object
--]]---------------------------------------------------------
function skin.columnlist(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.columnlist_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
end

--[[---------------------------------------------------------
	- func: skin.DrawColumnListHeader(object)
	- desc: draws the column list header object
--]]---------------------------------------------------------
function skin.columnlistheader(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local down = object.down
	local font = skin.controls.columnlistheader_text_font
	local theight = font:getHeight()
	local twidth = font:getWidth("")

	local bodydowncolor = skin.controls.columnlistheader_body_down_color
	local textdowncolor = skin.controls.columnlistheader_text_down_color
	local bodyhovercolor = skin.controls.columnlistheader_body_hover_color
	local textdownhovercolor = skin.controls.columnlistheader_text_hover_color
	local nohovercolor = skin.controls.columnlistheader_body_nohover_color
	local textnohovercolor = skin.controls.columnlistheader_text_nohover_color

	local name = ParseHeaderText(object:GetName(), x, width, x + width/2, twidth)

	if down then
		-- header body
		love.graphics.setColor(bodydowncolor)
		love.graphics.rectangle("fill", x, y, width, height)
		-- header name
		love.graphics.setFont(font)
		love.graphics.setColor(textdowncolor)
		skin.PrintText(name, x + width/2 - twidth/2, y + height/2 - theight/2)
		-- header border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	elseif hover then
		-- header body
		love.graphics.setColor(bodyhovercolor)
		love.graphics.rectangle("fill", x, y, width, height)
		-- header name
		love.graphics.setFont(font)
		love.graphics.setColor(textdowncolor)
		skin.PrintText(name, x + width/2 - twidth/2, y + height/2 - theight/2)
		-- header border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	else
		-- header body
		love.graphics.setColor(nohovercolor)
		love.graphics.rectangle("fill", x, y, width, height)
		-- header name
		love.graphics.setFont(font)
		love.graphics.setColor(textnohovercolor)
		skin.PrintText(name, x + width/2 - twidth/2, y + height/2 - theight/2)
		-- header border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	end
	
end

--[[---------------------------------------------------------
	- func: skin.DrawColumnListArea(object)
	- desc: draws the column list area object
--]]---------------------------------------------------------
function skin.columnlistarea(object)
	local skin = object:GetSkin()
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local columns = object:GetParent():GetChildren()
	local bodycolor = skin.controls.columnlistarea_body_color

	-- area body
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)

	-- header strip outline
	local cheight = 0
	if #columns > 0 then
		cheight = columns[1]:GetHeight()
	end
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, cheight, true, false, true, true)
end

--[[---------------------------------------------------------
	- func: skin.columnlistrows(object)
	- desc: draws the rows of the column list area (clipped to
	        the scrollable region by the area itself)
--]]---------------------------------------------------------
function skin.columnlistrows(object)
	local columnlist = object:GetParent()
	local columns = columnlist:GetChildren()
	local body1color = skin.controls.columnlistrow_body1_color
	local body2color = skin.controls.columnlistrow_body2_color
	local bodyhovercolor = skin.controls.columnlistrow_body_hover_color
	local bodyselectedcolor = skin.controls.columnlistrow_body_selected_color
	local textcolor = skin.controls.columnlistrow_text_color
	local texthovercolor = skin.controls.columnlistrow_text_hover_color
	local textselectedcolor = skin.controls.columnlistrow_text_selected_color

	-- only draw rows inside the visible region (culling)
	local top = object.y + columnlist.columnheight
	local bottom = object.y + object.height

	for _, row in ipairs(object.rows) do
		local ry = row.y
		local rheight = row.height
		-- rows are ordered top to bottom: stop once past the bottom
		if ry >= bottom then
			break
		end
		if (ry + rheight) > top then
			local rx = row.x
			local rwidth = row.width
			local font = row.font
			local theight = font:getHeight("a")
			local textx = 5
			local texty = rheight/2 - theight/2
			row.textx = textx
			row.texty = texty

			if row.selected then
				love.graphics.setColor(bodyselectedcolor)
			elseif row.hover then
				love.graphics.setColor(bodyhovercolor)
			elseif row.colorindex == 1 then
				love.graphics.setColor(body1color)
			else
				love.graphics.setColor(body2color)
			end
			love.graphics.rectangle("fill", rx, ry, rwidth, rheight)

			love.graphics.setFont(font)
			if row.selected then
				love.graphics.setColor(textselectedcolor)
			elseif row.hover then
				love.graphics.setColor(texthovercolor)
			else
				love.graphics.setColor(textcolor)
			end

			local cx = rx
			for ci, value in ipairs(row.columndata) do
				local colwidth = columnlist:GetColumnWidth(ci)
				if colwidth then
					local text = ParseRowText(value, cx, colwidth, cx, textx)
					skin.PrintText(text, cx + textx, ry + texty)
					cx = cx + columns[ci]:GetWidth()
				else
					break
				end
			end
		end
	end
end

--[[---------------------------------------------------------
	- func: skin.DrawOverColumnListArea(object)
	- desc: draws over the column list area object
--]]---------------------------------------------------------
function skin.columnlistarea_over(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: skin.DrawModalBackground(object)
	- desc: draws the modal background object
--]]---------------------------------------------------------
function skin.modalbackground(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.modalbackground_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
end


--[[---------------------------------------------------------
	- func: skin.DrawGrid(object)
	- desc: draws the grid object
--]]---------------------------------------------------------
function skin.grid(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.grid_body_color
	
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
	
	local cx = x
	local cy = y
	local cw = object.cellwidth + (object.cellpadding * 2)
	local ch = object.cellheight + (object.cellpadding * 2)
	
	for i=1, object.rows do
		for n=1, object.columns do
			local ovt = false
			local ovl = false
			if i > 1 then
				ovt = true
			end
			if n > 1 then	
				ovl = true
			end
			love.graphics.setColor(bodycolor)
			love.graphics.rectangle("fill", cx, cy, cw, ch)
			love.graphics.setColor(bordercolor)
			skin.OutlinedRectangle(cx, cy, cw, ch, ovt, false, ovl, false)
			cx = cx + cw
		end
		cx = x
		cy = cy + ch
	end

end

--[[---------------------------------------------------------
	- func: skin.DrawForm(object)
	- desc: draws the form object
--]]---------------------------------------------------------
function skin.form(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local topmargin = object.topmargin
	local name = object.name
	local font = skin.controls.form_text_font
	local textcolor = skin.controls.form_text_color
	local twidth = font:getWidth(name)
	
	love.graphics.setFont(font)
	love.graphics.setColor(textcolor)
	skin.PrintText(name, x + 7, y)
	
	love.graphics.setColor(bordercolor)
	love.graphics.rectangle("fill", x, y + 7, 5, 1)
	love.graphics.rectangle("fill", x + twidth + 9, y + 7, width - (twidth + 9), 1)
	love.graphics.rectangle("fill", x, y + height, width, 1)
	love.graphics.rectangle("fill", x, y + 7, 1, height - 7)
	love.graphics.rectangle("fill", x + width - 1, y + 7, 1, height - 7)
	
end

--[[---------------------------------------------------------
	- func: skin.DrawMenu(object)
	- desc: draws the menu object
--]]---------------------------------------------------------
function skin.menu(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local bodycolor = skin.controls.menu_body_color
	love.graphics.setColor(bodycolor)
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(bordercolor)
	skin.OutlinedRectangle(x, y, width, height)
end

--[[---------------------------------------------------------
	- func: skin.DrawMenuOption(object)
	- desc: draws the menuoption object
--]]---------------------------------------------------------
function skin.menuoption(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()
	local hover = object:GetHover()
	local text = object:GetText()
	local icon = object:GetIcon()
	local margin = object.margin
	local option_type = object.option_type
	local body_hover_color = skin.controls.menuoption_body_hover_color
	local text_hover_color = skin.controls.menuoption_text_hover_color
	local text_color = skin.controls.menuoption_text_color
	local text_font = skin.controls.menuoption_text_font

	love.graphics.push()
	love.graphics.translate(x, y)

	if option_type == "divider" then
		love.graphics.setColor(pal.border)
		love.graphics.rectangle("fill", 4, 2, width - 8, 1)
	else
		love.graphics.setFont(text_font)
		if hover then
			love.graphics.setColor(body_hover_color)
			love.graphics.rectangle("fill", 2, 2, width - 4, height - 4)
			love.graphics.setColor(text_hover_color)
			skin.PrintText(text, 26, margin)
		else
			love.graphics.setColor(text_color)
			skin.PrintText(text, 26, margin)
		end

		if object.activated then
			love.graphics.setColor(body_hover_color)
			love.graphics.rectangle("fill", 2, 2, width - 4, height - 4)
		end

		love.graphics.setColor(1,1,1,1)
		if option_type == "submenu_activator" then
			local arrow = skin.images["arrow-right.png"]
			love.graphics.draw(arrow, width - arrow:getWidth(), height/2 - arrow:getHeight()/2)
		end

		if icon then
			local image_width, image_height = icon:getDimensions()
			local image_width_h, image_height_h = image_width/2, image_height/2
			local scale_x = 1/image_width * 16
			local scale_y = 1/image_height * 16
			love.graphics.draw(icon, 5, height/2, 0, scale_x, scale_y, 0, image_height_h)
		end
	end

	love.graphics.pop()

end

function skin.tree(object)
	local x = object:GetX()
	local y = object:GetY()
	local width = object:GetWidth()
	local height = object:GetHeight()

	local nohovercolor = skin.directives.text_default_color
	local textselectedcolor = skin.controls.textinput_text_selected_color
	local textactivecolor = skin.controls.textinput_text_active_color
	local highlightbarcolor = skin.controls.textinput_highlight_bar_color

	local font = object.font or skin.controls.imagebuttonfont
	local nodes = object.visiblenodes
	if not nodes then return end

	for index, node in ipairs(nodes) do
		-- selection highlight
		if object.selectednode == node then
			local twidth = font:getWidth(node.text)
			local theight = font:getHeight()
			love.graphics.setColor(highlightbarcolor)
			love.graphics.rectangle("fill", node.textx, node.texty, twidth, theight)
		end
		-- icon
		if node.icon then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(node.icon, node.iconx, node.icony)
		end
		-- text
		love.graphics.setFont(font)
		love.graphics.setColor(nohovercolor)
		skin.PrintText(node.text, node.textx, node.texty)
		-- open/close button
		if node.haschildren then
			local image
			if node.open then
				image = skin.images["tree-node-button-close.png"]
			else
				image = skin.images["tree-node-button-open.png"]
			end
			image:setFilter("nearest", "nearest")
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(image, node.buttonx, node.buttony)
		end
	end
end

-- register the skin
loveframes.RegisterSkin(skin)

---------- module end ----------
end
