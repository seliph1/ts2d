--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	local LG           = love.graphics
	local floor, ceil  = math.floor, math.ceil

	-- skin table
	local skin         = {}

	-- skin info (you always need this in a skin)
	skin.name          = "moon"
	skin.author        = "mozilla"
	skin.version       = "1.0"

	-- get current path
	skin.current_path  = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\\\])") or "./"

	-- Harvest Moon style yellow palette ---------------------------------
	-- Tweak these and the whole skin follows.
	local pal          = {}
	pal.cream          = { 0.96, 0.90, 0.55, 1.00 } -- main panel / list fill (matches frame.png)
	pal.cream_dark     = { 0.89, 0.79, 0.40, 1.00 } -- secondary fill (rows, headers, hover)
	pal.cream_darker   = { 0.84, 0.74, 0.36, 1.00 } -- pressed / active / selected fill
	pal.chocolate      = { 0.48, 0.25, 0.00, 1.00 } -- pressed / active / selected fill
	pal.dark_chocolate = { 0.18, 0.09, 0.00, 1.00 } -- pressed / active / selected fill
	pal.gold           = { 0.98, 0.84, 0.26, 1.00 } -- gold accent (hover borders, bars)
	pal.border         = { 0.34, 0.25, 0.08, 1.00 } -- dark-brown outline
	pal.text           = { 0.00, 0.00, 0.00, 1.00 } -- dark-brown text
	pal.text_soft      = { 0.00, 0.00, 0.00, 0.50 } -- secondary / disabled text
	pal.text_strong    = { 0.00, 0.00, 0.00, 1.00 } -- emphasized / hover text
	pal.slot           = { 0.60, 0.80, 0.72, 0.55 } -- teal item-slot fill
	pal.green          = { 0.00, 1.00, 0.00, 1.00 } -- teal item-slot fill
	pal.highlight      = { 0.84, 0.62, 0.10, 0.50 } -- text selection highlight
	pal.shadow         = { 1.00, 0.96, 0.70, 0.60 } -- light "emboss" highlight on dark text
	pal.white          = { 1.00, 1.00, 1.00, 1.00 }
	pal.black          = { 0.00, 0.00, 0.00, 1.00 }
	pal.red            = { 1.00, 0.00, 0.00, 1.00 }
	pal.grey           = { 0.50, 0.50, 0.50, 1.00 }
	pal.lightgrey      = { 0.75, 0.75, 0.75, 1.00 }
	pal.darkgrey       = { 0.25, 0.25, 0.25, 1.00 }
	pal.transparent    = { 0.00, 0.00, 0.00, 0.00 }

	-- global border color used throughout the skin
	local bordercolor  = pal.border

	-- add skin directives to this table
	skin.directives    = {}
	-- Text
	local pixel_glyphs =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
		"abcdefghijklmnopqrstuvwxyz" ..
		"0123456789" ..
		" ,º✿★%'.·*+-×=‾_:;#$^{}[]\\/<>()「」&!?♀฿♪♡█|@©" ..
		-- Latin-1 Supplement (U+00A0..U+00FF) added to font_page.png
		"¡¢£¤¥¦§¨ª«¬®¯°±²³´µ¶¸¹»¼½¾¿" ..
		"ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß" ..
		"àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"


	local pixel_font_src = skin.current_path .. "images/font_page.png"
	local pixel_font = love.graphics.newImageFont(pixel_font_src, pixel_glyphs)

	skin.directives.text_global = skin.current_path .. "images/liberationsans.ttf"
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

	skin.directives.text_font_height         = 1
	skin.directives.text_default_color       = pal.text;
	skin.directives.text_default_shadowcolor = pal.shadow;
	skin.directives.text_default_font_src    = pixel_font_src
	skin.directives.text_default_font_size   = 18
	skin.directives.text_default_glyphs      = pixel_glyphs
	skin.directives.text_default_font        = pixel_font

	do
		local fallbacks = {}
		for index, fallback_src in ipairs(skin.directives.text_fallbacks) do
			local fallback = LG.newFont(fallback_src, skin.directives.text_default_font_size)
			fallback:setLineHeight(skin.directives.text_font_height)
			table.insert(fallbacks, fallback)
		end
		skin.directives.text_default_font:setFallbacks(unpack(fallbacks))
	end

	skin.directives.tooltip_default_font_src          = pixel_font_src
	skin.directives.tooltip_default_font              = loadFont(skin.directives.tooltip_default_font_src, pixel_glyphs)
	skin.directives.tooltip_default_color             = { 1, 1, 1, 1 };

	-- controls
	skin.controls                                     = {}
	skin.controls.tinyfont                            = loadFont(skin.current_path .. "images/font_page.png",
		pixel_glyphs)
	skin.controls.defaultfont                         = loadFont(skin.current_path .. "images/font_page.png",
		pixel_glyphs)
	skin.controls.smallfont                           = loadFont(skin.current_path .. "images/font_page.png",
		pixel_glyphs)
	skin.controls.titlefont                           = loadFont(skin.current_path .. "images/font_page.png",
		pixel_glyphs)
	skin.controls.imagebuttonfont                     = loadFont(skin.current_path .. "images/font_page2x.png",
		pixel_glyphs)

	-- skin global colors
	skin.controls.text_nohover_color                  = pal.text
	skin.controls.text_hover_color                    = pal.text_strong
	skin.controls.text_down_color                     = pal.text_strong
	skin.controls.text_active_color                   = pal.text_strong
	skin.controls.text_toggle_color                   = pal.text_soft
	skin.controls.text_disabled_color                 = pal.text_soft

	-- frame
	skin.controls.frame_name_color                    = pal.text
	skin.controls.frame_name_font                     = skin.controls.titlefont

	-- button
	skin.controls.button_round_corner                 = 10
	skin.controls.button_body_color                   = pal.cream_dark
	skin.controls.button_down_color                   = pal.cream_darker
	skin.controls.button_nohover_color                = pal.cream_dark
	skin.controls.button_hover_color                  = pal.cream_dark
	skin.controls.button_toggle_color                 = pal.cream_dark
	skin.controls.button_disabled_color               = pal.cream

	skin.controls.button_text_color                   = pal.text
	skin.controls.button_text_down_color              = pal.text_strong
	skin.controls.button_text_nohover_color           = pal.text
	skin.controls.button_text_hover_color             = pal.text_strong
	skin.controls.button_text_toggle_color            = pal.text_soft
	skin.controls.button_text_disabled_color          = pal.text_soft
	skin.controls.button_text_font                    = skin.controls.smallfont

	skin.controls.button_border_disabled_color        = pal.border
	skin.controls.button_border_enabled_color         = pal.border

	-- closebutton
	skin.controls.closebutton_body_down_color         = pal.red
	skin.controls.closebutton_body_nohover_color      = pal.red
	skin.controls.closebutton_body_hover_color        = pal.red

	-- progressbar
	skin.controls.progressbar_body_color              = pal.cream_dark
	skin.controls.progressbar_bar_color               = pal.gold
	skin.controls.progressbar_text_color              = pal.text
	skin.controls.progressbar_text_font               = skin.controls.smallfont

	-- scrollarea
	skin.controls.scrollarea_body_color               = pal.cream_dark

	-- scrollbody
	skin.controls.scrollbody_body_color               = pal.cream

	-- scrollbar
	skin.controls.scrollbar_body_down_color           = pal.gold
	skin.controls.scrollbar_body_hover_color          = pal.cream_darker
	skin.controls.scrollbar_body_nohover_color        = pal.cream_dark

	-- slider & button
	skin.controls.slider_bar_outline_color            = pal.cream_dark
	skin.controls.slider_button_nohover_color         = pal.cream_dark
	skin.controls.slider_button_hover_color           = pal.cream_darker
	skin.controls.slider_button_down_color            = pal.gold
	skin.controls.slider_button_disabled_color        = pal.cream

	-- panel
	skin.controls.panel_body_color                    = pal.cream

	-- list
	skin.controls.list_body_color                     = pal.cream

	-- tabpanel
	skin.controls.tabpanel_body_color                 = pal.cream

	-- tabbutton
	skin.controls.tab_body_nohover_color              = pal.cream_darker
	skin.controls.tab_body_hover_color                = pal.cream_dark
	skin.controls.tab_body_active_color               = pal.cream
	skin.controls.tab_text_nohover_color              = pal.text
	skin.controls.tab_text_hover_color                = pal.text_strong
	skin.controls.tab_text_active_color               = pal.text_strong
	skin.controls.tab_text_font                       = skin.controls.smallfont

	-- multichoice
	skin.controls.multichoice_body_color              = pal.cream
	skin.controls.multichoice_border_hover_color      = pal.gold
	skin.controls.multichoice_border_nohover_color    = pal.border
	skin.controls.multichoice_border_down_color       = pal.border
	skin.controls.multichoice_border_active_color     = pal.gold
	skin.controls.multichoice_border_disabled_color   = pal.gold
	skin.controls.multichoice_text_active_color       = pal.text_strong
	skin.controls.multichoice_text_color              = pal.text
	skin.controls.multichoice_text_font               = skin.controls.smallfont

	-- multichoicelist
	skin.controls.multichoicelist_body_color          = pal.cream_dark

	-- multichoicerow
	skin.controls.multichoicerow_body_nohover_color   = pal.cream
	skin.controls.multichoicerow_body_hover_color     = pal.cream_dark
	skin.controls.multichoicerow_text_nohover_color   = pal.text
	skin.controls.multichoicerow_text_hover_color     = pal.text_strong
	skin.controls.multichoicerow_text_font            = skin.controls.smallfont

	-- droplist
	skin.controls.droplist_body_nohover_color         = pal.cream
	skin.controls.droplist_body_hover_color           = pal.cream_darker
	skin.controls.droplist_body_active_color          = pal.green
	skin.controls.droplist_body_odd_color             = pal.cream
	skin.controls.droplist_body_even_color            = pal.cream_dark
	skin.controls.droplist_text_nohover_color         = pal.text
	skin.controls.droplist_text_hover_color           = pal.text_strong
	skin.controls.droplist_text_active_color          = pal.text_strong
	skin.controls.droplist_text_font                  = skin.controls.smallfont

	-- tooltip
	skin.controls.tooltip_body_color                  = pal.black
	skin.controls.tooltip_border_color                = pal.black
	skin.controls.tooltip_font_color                  = pal.white

	-- textbox
	skin.controls.textbox_border_hover_color          = pal.gold
	skin.controls.textbox_border_nohover_color        = pal.border
	skin.controls.textbox_border_active_color         = pal.gold
	skin.controls.textbox_border_disabled_color       = pal.border
	skin.controls.textbox_body_color                  = pal.cream
	skin.controls.textbox_indicator_color             = pal.black
	skin.controls.textbox_normal_color                = pal.text
	skin.controls.textbox_active_color                = pal.text_strong
	skin.controls.textbox_placeholder_color           = pal.text_soft
	skin.controls.textbox_selected_color              = pal.text_strong
	skin.controls.textbox_highlight_bar_color         = pal.highlight

	-- checkbox
	skin.controls.checkbox_body_color                 = pal.cream
	skin.controls.checkbox_check_color                = pal.green
	skin.controls.checkbox_hover_color                = pal.gold
	skin.controls.checkbox_text_font                  = skin.controls.smallfont

	-- toggle
	skin.controls.toggle_body_off_color               = pal.cream_dark
	skin.controls.toggle_body_on_color                = pal.green
	skin.controls.toggle_knob_color                   = pal.cream
	skin.controls.toggle_hover_color                  = pal.gold
	skin.controls.toggle_disabled_color               = pal.text_soft
	skin.controls.toggle_text_font                    = skin.controls.smallfont

	-- radiobutton
	skin.controls.radiobutton_check_color             = pal.green
	skin.controls.radiobutton_checkinner_color        = pal.green
	skin.controls.radiobutton_hover_color             = pal.gold
	skin.controls.radiobutton_inner_border_color      = pal.gold
	skin.controls.radiobutton_text_font               = skin.controls.smallfont

	-- collapsiblecategory
	skin.controls.collapsiblecategory_text_color      = pal.text

	-- columnlist
	skin.controls.columnlist_body_color               = pal.cream

	-- columlistarea
	skin.controls.columnlistarea_body_color           = pal.cream

	-- columnlistheader
	skin.controls.columnlistheader_body_down_color    = pal.gold
	skin.controls.columnlistheader_body_hover_color   = pal.cream_darker
	skin.controls.columnlistheader_body_nohover_color = pal.cream_dark

	skin.controls.columnlistheader_text_down_color    = pal.text_strong
	skin.controls.columnlistheader_text_nohover_color = pal.text
	skin.controls.columnlistheader_text_hover_color   = pal.text_strong
	skin.controls.columnlistheader_text_font          = skin.controls.tinyfont

	-- columnlistrow
	skin.controls.columnlistrow_body1_color           = pal.cream
	skin.controls.columnlistrow_body2_color           = pal.cream_dark
	skin.controls.columnlistrow_body_selected_color   = pal.green
	skin.controls.columnlistrow_body_hover_color      = pal.cream_darker
	skin.controls.columnlistrow_text_color            = pal.text
	skin.controls.columnlistrow_text_hover_color      = pal.text_strong
	skin.controls.columnlistrow_text_selected_color   = pal.text_strong

	-- modalbackground
	skin.controls.modalbackground_body_color          = { 0.20, 0.13, 0.03, 0.45 }

	-- grid
	skin.controls.grid_body_color                     = pal.cream

	-- menu & menuoption
	skin.controls.menu_body_color                     = pal.cream
	skin.controls.menuoption_body_hover_color         = pal.cream_dark
	skin.controls.menuoption_text_hover_color         = pal.text_strong
	skin.controls.menuoption_text_color               = pal.text
	skin.controls.menuoption_text_font                = skin.controls.tinyfont

	-- menubar
	skin.controls.menubar_body_color                  = pal.cream
	skin.controls.menubar_text_font                   = skin.controls.smallfont
	skin.controls.menubar_text_color                  = pal.text
	skin.controls.menubar_text_hover_color            = pal.text_strong
	skin.controls.menubar_item_hover_color            = pal.cream_dark
	skin.controls.menubar_item_active_color           = pal.cream_darker
	skin.controls.menubar_border_color                = pal.border

	-- dial
	skin.controls.dial_circle                         = pal.cream_dark
	skin.controls.dial_circle_hover                   = pal.cream
	skin.controls.dial_pointer                        = pal.cream_darker
	skin.controls.dial_border                         = pal.border

	skin.controls.joystick_base                       = pal.cream_dark
	skin.controls.joystick_base_hover                 = pal.cream
	skin.controls.joystick_border                     = pal.border
	skin.controls.joystick_knob                       = pal.cream_darker
	skin.controls.joystick_knob_hover                 = pal.gold


	local function ParseHeaderText(str, hx, hwidth, tx, twidth)
		local font = love.graphics.getFont()
		twidth = font:getWidth(str) or twidth
		if (tx + twidth) - hwidth / 2 > hx + hwidth then
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

	local frameBG = love.graphics.newImage(skin.current_path .. "images/frame.png")
	local frameBGwidth, frameBGheight = frameBG:getDimensions()

	--[[---------------------------------------------------------
	- func: OutlinedRectangle(x, y, width, height, ovt, ovb, ovl, ovr)
	- desc: creates and outlined rectangle
--]] ---------------------------------------------------------
	function skin.OutlinedRectangle(x, y, width, height, ovt, ovb, ovl, ovr, rx, ry)
		if rx and rx > 0 then
			love.graphics.rectangle("line", x, y, width, height, rx, ry or rx)
			return
		end
		ovt = ovt or false
		ovb = ovb or false
		ovl = ovl or false
		ovr = ovr or false
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
		local r, g, b, a = love.graphics.getColor()
		local br = 0.8
		-- top
		love.graphics.setColor(r, g, b, 1)
		love.graphics.rectangle("fill", x, y, width, 1)
		-- left
		love.graphics.setColor(r, g, b, 1)
		love.graphics.rectangle("fill", x, y, 1, height)
		-- bottom
		love.graphics.setColor(r - br, g - br, b - br, 1)
		love.graphics.rectangle("fill", x, y + height - 1, width, 1)
		-- right
		love.graphics.setColor(r - br, g - br, b - br, 1)
		love.graphics.rectangle("fill", x + width - 1, y, 1, height)
	end

	--[[---------------------------------------------------------
	- func: DrawFrame(object)
	- desc: draws the frame object
--]] ---------------------------------------------------------
	function skin.frame(object)
		local x, y          = object:GetPos()
		local width, height = object:GetDimensions()
		local name          = object:GetName()
		local icon          = object:GetIcon()
		local namecolor     = skin.controls.frame_name_color
		local font          = skin.controls.frame_name_font

		LG.push()
		LG.translate(x, y)

		-- BG body
		local sx, sy, sw, sh = love.graphics.getScissor()
		LG.setScissor(x, y, width, height)
		LG.setColor(1, 1, 1, 1)
		for xcut = 0, ceil(width / frameBGwidth) - 1 do
			for ycut = 0, ceil(height / frameBGheight) - 1 do
				LG.draw(frameBG, xcut * frameBGwidth, ycut * frameBGheight)
			end
		end
		LG.setScissor(sx, sy, sw, sh)

		-- frame name section
		LG.setFont(font)
		if icon then
			local iconwidth = icon:getWidth()
			local iconheight = icon:getHeight()
			LG.setColor(1, 1, 1, 1)
			LG.draw(icon, 10, 5)
			LG.setColor(namecolor)
			skin.PrintText(name, iconwidth + 15, 2)
		else
			LG.setColor(namecolor)
			skin.PrintText(name, 10, 2)
		end
		-- frame top bar
		LG.setColor(bordercolor)
		LG.rectangle("fill", 10, 20, width - 25, 1)
		-- frame border
		LG.setColor(bordercolor)
		skin.OutlinedRectangle(0, 0, width, height)
		LG.pop()
	end

	--[[---------------------------------------------------------
	- func: DrawButton(object)
	- desc: draws the button object
--]] ---------------------------------------------------------
	function skin.button(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local hover = object:GetHover()
		local caption = object:GetCaption()
		local formattedcaption = object:GetFormattedCaption()
		local down = object:GetDown()
		local checked = object:GetChecked()
		local enabled = object:GetEnabled()
		local align = object:GetAlign()
		local captionmesh = object:GetDrawableCaption()
		local textmesh = object:GetDrawableText()
		local text_height = textmesh:getHeight()
		local text_width = textmesh:getWidth()
		local padding = object:GetPadding()
		local left_padding = object.left_padding
		local image_padding = object:GetImagePadding()
		local image_align = object:GetImageAlign()
		local corner = skin.controls.button_round_corner

		-- Default color
		local defaultcolor = skin.controls.button_text_color
		-- Text colors
		local textdowncolor = skin.controls.button_text_down_color
		local texthovercolor = skin.controls.button_text_hover_color
		local textnohovercolor = skin.controls.button_text_nohover_color
		local texttogglecolor = skin.controls.button_text_toggle_color
		local textdisabledcolor = skin.controls.button_text_disabled_color
		-- Body colors
		local downcolor = skin.controls.button_down_color
		local hovercolor = skin.controls.button_hover_color
		local nohovercolor = skin.controls.button_nohover_color
		local togglecolor = skin.controls.button_toggle_color
		local disabledcolor = skin.controls.button_disabled_color
		-- Border colors
		local borderdisabled = skin.controls.button_border_disabled_color
		local borderenabled = skin.controls.button_border_enabled_color
		-- Color pointers
		local textcolor, bodycolor, captioncolor = textnohovercolor, nohovercolor, textdisabledcolor
		local bordercolor = bordercolor
		-- Image pointers
		local image_hover = skin.images["button-hover.png"]
		local image_hover_sh = height / image_hover:getHeight()
		local xoffset, yoffset = 0, 0
		local image_x, image_y, image_width, image_height = 0, 0, 0, 0
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
			bodycolor = disabledcolor
			textcolor = textdisabledcolor
			hover = false
			down = false
		end

		love.graphics.push()
		love.graphics.translate(x, y)

		if object.image then
			image_width = object.image:getWidth()
			image_height = object.image:getHeight()

			if image_align == "center" then
				image_x = math.floor(xoffset + image_padding - image_width / 2)
				image_padding = image_padding - image_width / 2
			else
				image_x = math.floor(xoffset + image_padding)
			end
			image_y = math.floor(yoffset + (height - image_height) / 2)
		end

		if align == "right" then
			text_x = math.floor(xoffset - padding)
		elseif align == "left" then
			text_x = math.floor(xoffset + math.max(padding, image_width + image_padding))
		elseif align == "center" then
			text_x = math.floor(xoffset)
		end
		text_y = math.floor(((height - text_height) / 2) + yoffset)

		caption_x = math.floor(xoffset - left_padding)
		caption_y = math.floor(((height - text_height) / 2) + yoffset)

		if caption ~= formattedcaption then
			captioncolor = defaultcolor
		end
		-- Draw body
		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", 0, 0, width, height, corner, corner)

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
		local brightness = loveframes.Mix(0.1, 0.7, loveframes.Clamp(hovertime * 5, 0, 1))

		-- Button hover shade
		love.graphics.setStencilMode("draw", 1)
		love.graphics.rectangle("fill", 0, 0, width, height, corner, corner)
		love.graphics.setStencilMode("test", 1)

		love.graphics.setColor(1, 1, 1, brightness)
		love.graphics.draw(image_hover, 0, 0, 0, width, image_hover_sh / 2)

		love.graphics.setStencilMode("off")

		-- Draw border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(0, 0, width, height, false, true, false, false, corner, corner)

		love.graphics.pop()
	end

	--[[---------------------------------------------------------
	- func: DrawButton(object)
	- desc: draws the button object
--]] ---------------------------------------------------------
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
		local image_x, image_y, image_width, image_height = 0, 0, 0, 0
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
				image_x = math.floor(x + xoffset + (width - image_width - text_width) / 2)
			elseif align == "left" then
				image_x = math.floor(x + xoffset + padding)
			elseif align == "right" then
				image_x = math.floor(x + xoffset - padding + width - text_width - image_width)
			end
			image_y = math.floor(y + yoffset + (height - image_height) / 2)
		end

		if align == "right" then
			text_x = math.floor(x + xoffset - padding)
		elseif align == "left" then
			text_x = math.floor(x + xoffset + padding + image_width)
		elseif align == "center" then
			text_x = math.floor(x + xoffset + image_width / 2)
		end
		text_y = math.floor((y + (height - text_height) / 2) + yoffset)

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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
			offsetx = offsetx + object.image:getWidth() / 2
			offsety = offsety + object.image:getHeight() / 2

			x = x + object.image:getWidth() / 2
			y = y + object.image:getHeight() / 2
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
--]] ---------------------------------------------------------
	function skin.imagebutton(object)
		local x = object:GetX()
		local y = object:GetY()
		local width = object:GetWidth()
		local height = object:GetHeight()
		local hover = object:GetHover()
		local image = object:GetImage()
		local imagecolor = object.imagecolor or pal.white
		local down = object.down
		local checked = object.checked

		if down then
			if image then
				love.graphics.setColor(imagecolor)
				love.graphics.draw(image, x + 1, y + 1)
			end
		elseif hover then
			if image then
				love.graphics.setColor(imagecolor)
				love.graphics.draw(image, x, y)
			end
		else
			if image then
				love.graphics.setColor(imagecolor)
				love.graphics.draw(image, x, y)
			end
		end
		if checked == true then
			love.graphics.setColor(bordercolor)
			love.graphics.setLineWidth(3)
			love.graphics.setLineStyle("smooth")
			love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2)
		end
	end

	--[[---------------------------------------------------------
	- func: DrawProgressBar(object)
	- desc: draws the progress bar object
--]] ---------------------------------------------------------
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
		local scaley = height / imageheight

		-- progress bar body
		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", x, y, width, height)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(image, x, y, 0, barwidth, scaley)
		love.graphics.setFont(font)
		love.graphics.setColor(textcolor)
		skin.PrintText(text, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)

		-- progress bar border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollArea(object)
	- desc: draws the scroll area object
--]] ---------------------------------------------------------
	function skin.scrollarea(object)
		local x = object:GetX()
		local y = object:GetY()
		local width = object:GetWidth()
		local height = object:GetHeight()
		local bodycolor = skin.controls.scrollarea_body_color

		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", x, y, width, height)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollBar(object)
	- desc: draws the scroll bar object
--]] ---------------------------------------------------------
	function skin.scrollbar(object)
		local x = object:GetX()
		local y = object:GetY()
		local width = object:GetWidth()
		local height = object:GetHeight()
		local dragging = object:IsAnchored()
		local hover = object:GetHover()
		local bodydowncolor = skin.controls.scrollbar_body_down_color
		local bodyhovercolor = skin.controls.scrollbar_body_hover_color
		local bodynohovercolor = skin.controls.scrollbar_body_nohover_color
		local ox = 2
		local oy = 2
		local rwidth = width - ox * 2
		local rheight = height - oy * 2
		local radius = math.min(rwidth, rheight) / 4

		local prevlinewidth = LG.getLineWidth()
		LG.setLineWidth(0.5)
		if dragging then
			love.graphics.setColor(bodydowncolor)
			love.graphics.rectangle("fill", x + ox, y + oy, rwidth, rheight, radius, radius)
		elseif hover then
			love.graphics.setColor(bodyhovercolor)
			love.graphics.rectangle("fill", x + ox, y + oy, rwidth, rheight, radius, radius)
		else
			love.graphics.setColor(bodynohovercolor)
			love.graphics.rectangle("fill", x + ox, y + oy, rwidth, rheight, radius, radius)
		end
		love.graphics.setColor(bordercolor)
		love.graphics.rectangle("line", x + ox, y + oy, rwidth, rheight, radius, radius)
		LG.setLineWidth(prevlinewidth)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollBody(object)
	- desc: draws the scroll body object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
			love.graphics.draw(image, x + width / 2 - imagewidth / 2, y + height / 2 - imageheight / 2)
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
			love.graphics.draw(image, x + width / 2 - imagewidth / 2, y + height / 2 - imageheight / 2)
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
			love.graphics.draw(image, x + width / 2 - imagewidth / 2, y + height / 2 - imageheight / 2)
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
			love.graphics.draw(image, x + width / 2 - imagewidth / 2, y + height / 2 - imageheight / 2)
		end
	end

	--[[---------------------------------------------------------
	- func: DrawPanel(object)
	- desc: draws the panel object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function skin.container(object)
		local x = object:GetX()
		local y = object:GetY()
	end

	--[[---------------------------------------------------------
	- func: DrawList(object)
	- desc: draws the list object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function skin.list_over(object)
		local x = object:GetX()
		local y = object:GetY()
		local width = object:GetWidth()
		local height = object:GetHeight()

		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(x, y, width, height)
	end

	--[[---------------------------------------------------------
	- func: DrawTabButton(object)
	- desc: draws the tab button object
--]] ---------------------------------------------------------
	function skin.tabbutton(object)
		local x, y            = object:GetPos()
		local width, height   = object:GetDimensions()
		local hover           = object:GetHover()
		local text            = object:GetText()
		local image           = object:GetImage()
		local tabnumber       = object:GetTabNumber()
		local parent          = object:GetParent()
		local ptabnumber      = parent:GetTabNumber()
		local font            = skin.controls.tab_text_font
		local twidth, theight = font:getWidth(object.text), font:getHeight()

		LG.push()
		LG.translate(x, y)

		local bodycolor, textcolor
		if tabnumber == ptabnumber then
			bodycolor = skin.controls.tab_body_active_color
			textcolor = skin.controls.tab_text_active_color
		elseif hover then
			bodycolor = skin.controls.tab_body_hover_color
			textcolor = skin.controls.tab_text_hover_color
		else
			bodycolor = skin.controls.tab_body_nohover_color
			textcolor = skin.controls.tab_text_nohover_color
		end

		-- button body
		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", 0, 0, width, height)

		-- button border
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(0, 0, width, height, nil, true, nil, nil)


		local text_offset = parent.tabmargin
		local imagewidth, imageheight = 0, 0
		if image then
			imagewidth, imageheight = image:getDimensions()
			local scale = 1
			if imageheight > (parent.tabheight - parent.tabmargin) then
				scale = (parent.tabheight - parent.tabmargin) / imageheight
			end
			-- button image
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(image, parent.tabmargin, height / 2 - imageheight * scale / 2, 0, scale)
			text_offset = text_offset + math.floor(imagewidth * scale) + parent.tabmargin
		end

		-- button text
		love.graphics.setFont(font)
		love.graphics.setColor(textcolor)
		skin.PrintText(text, text_offset, height / 2 - theight / 2)

		LG.pop()
	end

	--[[---------------------------------------------------------
	- func: DrawMultiChoice(object)
	- desc: draws the multi choice object
--]] ---------------------------------------------------------
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
		local enabled = object:GetEnabled()

		if not enabled then
			bodycolor = skin.controls.text_disabled_color
			textcolor = skin.controls.text_disabled_color
			bordernohovercolor = skin.controls.multichoice_border_nohover_color
			borderhovercolor = bordernohovercolor
		end

		local offset = math.floor((height - image:getHeight()) / 2)
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
			skin.PrintText(text, x + 5, y + height / 2 - theight / 2)
		else
			skin.PrintText(choice, x + 5, y + height / 2 - theight / 2)
		end
		-- Draw downarrow button
		image:setFilter("nearest", "nearest")
		if enabled then
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.setColor(1, 1, 1, 0.5)
		end
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function skin.tooltip(object)
		local x, y = love.mouse.getPosition()
		local text = object.tooltip
		local font = skin.directives.tooltip_default_font
		local width = font:getWidth(text)
		local height = font:getHeight()
		local margin = 4
		local offset_x = math.floor(x - width / 2)
			+ math.max(0, math.floor(width / 2 - x + margin))
			- math.max(0, math.floor(width / 2 + x + margin - love.graphics.getWidth()))
		local offset_y = y + 30
		if y + 30 + height + margin > love.graphics.getHeight() then
			offset_y = y - 30
		end

		local bodycolor = skin.controls.tooltip_body_color
		local bordercolor = skin.controls.tooltip_border_color
		local textcolor = skin.controls.tooltip_font_color
		local time = object:GetHoverTime()

		love.graphics.push()
		love.graphics.translate(offset_x, offset_y)

		if time > 0.5 then
			love.graphics.setColor(bodycolor)
			love.graphics.rectangle("fill", -margin, -margin, width + margin * 2, height + margin * 2, 2, 2)
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", -margin, -margin, width + margin * 2, height + margin * 2, 2, 2)
			love.graphics.setColor(textcolor)
			love.graphics.setFont(font)
			love.graphics.print(text, 0, 0)
		end

		love.graphics.pop()
	end

	--[[---------------------------------------------------------
	- func: Label(object)
	- desc: draws the text object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function skin.messagebox(object)
		local x = math.floor(object.x)
		local y = math.floor(object.y)
		local textmesh = object.textmesh
		local shadow = object.shadow
		if shadow then
			love.graphics.setColor(pal.shadow)
			love.graphics.draw(textmesh, x + 1, y + 1)
		end
		love.graphics.setColor(pal.text)
		love.graphics.draw(textmesh, x, y)
	end

	--[[---------------------------------------------------------
	- func: skin.rtf(object)
	- desc: draws the rich text format object
--]] ---------------------------------------------------------
	function skin.rtf(object)
		local x = object.x
		local y = object.y

		local field = object.field
		love.graphics.setColor(1, 1, 1, 1)
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function skin.textbox(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
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
		local bodycolor = skin.controls.textbox_body_color
		local textnormalcolor = skin.controls.textbox_normal_color
		local textplaceholdercolor = skin.controls.textbox_placeholder_color
		local textactivecolor = skin.controls.textbox_active_color
		local highlightbarcolor = skin.controls.textbox_highlight_bar_color
		local indicatorcolor = skin.controls.textbox_indicator_color

		local enabled = true
		if object.enabled ~= nil then enabled = object.enabled end
		if object.parent and object.parent.type == "numberbox" and object.parent.enabled == false then enabled = false end

		if not enabled then
			bodycolor = skin.controls.text_disabled_color
			textnormalcolor = skin.controls.text_disabled_color
		end

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
				love.graphics.rectangle("fill", selection_x + x + hpadding, selection_y + y + vpadding, selection_w,
					selection_h)
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
		if focus and (blink_phase / 0.90) % 1 < .5 then
			local cursor_x, cursor_y, cursor_height = field:getCursorLayout()
			if cursor_x >= 0 and cursor_x <= width and cursor_y >= -font_height and cursor_y <= height + font_height then
				love.graphics.setColor(indicatorcolor)
				love.graphics.rectangle("fill", cursor_x + x + hpadding, cursor_y + y + vpadding, 1, cursor_height)
			end
		end

		-- Draw the scroll bar
		local canScrollH, canScrollV                 = field:canScroll()
		local hOffset, hCoverage, vOffset, vCoverage = field:getScrollHandles()
		local hHandleLength                          = hCoverage * width
		local vHandleLength                          = vCoverage * height
		local hHandlePos                             = hOffset * width
		local vHandlePos                             = vOffset * height

		if hHandleLength < width then
			love.graphics.setColor(textactivecolor)
			--love.graphics.rectangle("fill", x + width - 2, y + vHandlePos, 2, vHandleLength)
			love.graphics.rectangle("fill", x + hHandlePos, y + height - 2, hHandleLength, 2)
		end
	end

	function skin.textbox_over(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local hover = object:GetHover()
		local focus = object:GetFocus()

		local borderhover = skin.controls.textbox_border_hover_color
		local bordernohover = skin.controls.textbox_border_nohover_color
		local borderactive = skin.controls.textbox_border_active_color

		local enabled = true
		if object.enabled ~= nil then enabled = object.enabled end
		if object.parent and object.parent.type == "numberbox" and object.parent.enabled == false then enabled = false end

		if not enabled then
			bordernohover = skin.controls.textbox_border_disabled_color
			borderhover = bordernohover
			borderactive = bordernohover
		end

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
--]] ---------------------------------------------------------
	function skin.input(object)
	end

	function skin.input_over(object)
	end

	--[[---------------------------------------------------------
	- func: skin.DrawSlider(object)
	- desc: draws the slider object
--]] ---------------------------------------------------------
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
			love.graphics.rectangle("fill", x, y + height / 2 - wideness_h / 2, width, wideness_h, wideness_h / 2,
				wideness_h / 2)
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", x, y + height / 2 - wideness_h / 2, width, wideness_h, wideness_h / 2,
				wideness_h / 2)
		elseif slidtype == "vertical" then
			love.graphics.setColor(baroutlinecolor)
			love.graphics.rectangle("fill", x + width / 2 - wideness_v / 2, y, wideness_v, height, wideness_v / 2,
				wideness_v / 2)
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", x + width / 2 - wideness_v / 2, y, wideness_v, height, wideness_v / 2,
				wideness_v / 2)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.dial(object)
	- desc: draws the dial object
--]] ---------------------------------------------------------
	function skin.dial(object)
		local cx = object.x + object.width / 2
		local cy = object.y + object.height / 2
		local radius = math.min(object.width, object.height) / 2
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
--]] ---------------------------------------------------------
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
		love.graphics.setColor(skin.controls.joystick_border[1], skin.controls.joystick_border[2],
			skin.controls.joystick_border[3], 0.35)
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
--]] ---------------------------------------------------------
	function skin.slideshow(object)
		love.graphics.setColor(0.18, 0.18, 0.2, 1)
		love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
	end

	--[[---------------------------------------------------------
	- func: skin.slideshow_over(object)
	- desc: draws the slideshow border and navigation dots
--]] ---------------------------------------------------------
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
	- func: skin.carousel(object)
	- desc: draws the carousel background
--]] ---------------------------------------------------------
	function skin.carousel(object)
		love.graphics.setColor(0.18, 0.18, 0.2, 1)
		love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
	end

	--[[---------------------------------------------------------
	- func: skin.carousel_over(object)
	- desc: draws the carousel border
--]] ---------------------------------------------------------
	function skin.carousel_over(object)
		love.graphics.setColor(bordercolor)
		skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
	end

	--[[---------------------------------------------------------
	- func: skin.dockzone(object)
	- desc: draws the dockzone object
--]] ---------------------------------------------------------
	function skin.dockzone(object)
		if object.highlight then
			love.graphics.setColor(0.3, 0.6, 1, 0.2)
			love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
			love.graphics.setColor(0.3, 0.6, 1, 0.8)
			skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
		else
			love.graphics.setColor(1, 1, 1, 0.05)
			love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
			love.graphics.setColor(1, 1, 1, 0.1)
			skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawSliderButton(object)
	- desc: draws the slider button object
--]] ---------------------------------------------------------
	function skin.sliderbutton(object)
		local x = object:GetX()
		local y = object:GetY()
		local width = object:GetWidth()
		local height = object:GetHeight()
		local hover = object:GetHover()
		local down = object.down
		local parent = object:GetParent()
		local enabled = parent:GetEnabled()

		local disabledcolor = skin.controls.slider_button_disabled_color
		local bodydowncolor = skin.controls.slider_button_down_color
		local bodyhovercolor = skin.controls.slider_button_hover_color
		local bodynohovercolor = skin.controls.slider_button_nohover_color

		local ox = 2
		local oy = 2
		local r = 8
		if not enabled then
			-- button body
			love.graphics.setColor(disabledcolor)
			love.graphics.rectangle("fill", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
			-- button border
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
			return
		end
		if down then
			-- button body
			love.graphics.setColor(bodydowncolor)
			love.graphics.rectangle("fill", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
			-- button border
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
		elseif hover then
			-- button body
			love.graphics.setColor(bodyhovercolor)
			love.graphics.rectangle("fill", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
			-- button border
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
		else
			-- button body
			love.graphics.setColor(bodynohovercolor)
			love.graphics.rectangle("fill", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
			-- button border
			love.graphics.setColor(bordercolor)
			love.graphics.rectangle("line", x + ox, y + oy, width - ox * 2, height - oy * 2, r, r)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawCheckBox(object)
	- desc: draws the check box object
--]] ---------------------------------------------------------
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

		local offset = math.floor((height - box_height) / 2)
		local close_image = skin.images["ok.png"]
		local half_width = (box_width - close_image:getWidth()) / 2
		local half_height = (box_height - close_image:getHeight()) / 2

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
		LG.rectangle("line", x, y + offset, box_width, box_height)
		--skin.OutlinedRectangle(x, y + offset, box_width, box_height)

		-- Checker
		if checked then
			love.graphics.setColor(checkcolor)
			love.graphics.draw(close_image, x + half_width, y + half_height)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawToggle(object)
	- desc: draws the toggle object
--]] ---------------------------------------------------------
	function skin.toggle(object)
		local x = object:GetX()
		local y = object:GetY()
		local box_width = object:GetBoxWidth()
		local box_height = object:GetBoxHeight()
		local height = object:GetHeight()
		local width = object:GetWidth()
		local checked = object:GetChecked()
		local enabled = object:GetEnabled()
		local hover = object:GetHover()
		local offcolor = skin.controls.toggle_body_off_color
		local oncolor = skin.controls.toggle_body_on_color
		local knobcolor = skin.controls.toggle_knob_color
		local hovercolor = skin.controls.toggle_hover_color
		local disabledcolor = skin.controls.toggle_disabled_color
		local direction = object.GetDirection and object:GetDirection() or "horizontal"

		if direction == "vertical" then
			local offset_x = math.floor((width - box_width) / 2)
			local track_x = x + offset_x
			local track_y = y
			local radius = math.floor(box_width / 2)
			local padding = math.max(2, math.floor(box_width / 8))
			local knob_size = math.max(2, box_width - padding * 2)
			local knob_y = y + padding

			if checked then
				knob_y = y + box_height - knob_size - padding
			end

			if enabled then
				love.graphics.setColor(checked and oncolor or offcolor)
			else
				love.graphics.setColor(disabledcolor)
			end
			love.graphics.rectangle("fill", track_x, track_y, box_width, box_height, radius, radius, 16)

			if enabled and hover then
				love.graphics.setColor(hovercolor)
			else
				love.graphics.setColor(bordercolor)
			end
			love.graphics.rectangle("line", track_x, track_y, box_width, box_height, radius, radius, 16)

			love.graphics.setColor(knobcolor)
			love.graphics.circle("fill", track_x + box_width / 2, knob_y + knob_size / 2, knob_size / 2, 16)
			love.graphics.setColor(bordercolor)
			love.graphics.circle("line", track_x + box_width / 2, knob_y + knob_size / 2, knob_size / 2, 16)
		else
			local offset = math.floor((height - box_height) / 2)
			local track_y = y + offset
			local radius = math.floor(box_height / 2)
			local padding = math.max(2, math.floor(box_height / 8))
			local knob_size = math.max(2, box_height - padding * 2)
			local knob_x = x + padding

			if checked then
				knob_x = x + box_width - knob_size - padding
			end

			if enabled then
				love.graphics.setColor(checked and oncolor or offcolor)
			else
				love.graphics.setColor(disabledcolor)
			end
			love.graphics.rectangle("fill", x, track_y, box_width, box_height, radius, radius, 16)

			if enabled and hover then
				love.graphics.setColor(hovercolor)
			else
				love.graphics.setColor(bordercolor)
			end
			love.graphics.rectangle("line", x, track_y, box_width, box_height, radius, radius, 16)

			love.graphics.setColor(knobcolor)
			love.graphics.circle("fill", knob_x + knob_size / 2, track_y + box_height / 2, knob_size / 2, 16)
			love.graphics.setColor(bordercolor)
			love.graphics.circle("line", knob_x + knob_size / 2, track_y + box_height / 2, knob_size / 2, 16)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawRadioButton(object)
	- desc: draws the radio button object
--]] ---------------------------------------------------------
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
		local radius = (box_width + box_height) / 4
		local offsetX = radius
		local offsetY = radius + (height - box_height) / 2
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
			love.graphics.circle("fill", offsetX, offsetY, radius / 2, 360)
			love.graphics.setColor(checkcolor)
			love.graphics.circle("line", offsetX, offsetY, radius / 2, 360)
		end

		love.graphics.pop()
	end

	--[[---------------------------------------------------------
	- func: skin.DrawCollapsibleCategory(object)
	- desc: draws the collapsible category object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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

		-- Draw icons
		for i, element in ipairs(elements) do
			if type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions then
				local icon = element.icon
				local cell_y = y + (i - 1) * cell_height
				local icon_w, icon_h = icon:getDimensions()
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(icon, x + 5, cell_y + cell_height / 2 - icon_h / 2)
			end
		end

		if highlight and hovered ~= 0 then
			local cell_x = x
			local cell_y = y + (hovered - 1) * cell_height
			local text_y = y + (hovered - 1) * cell_height + padding / 2
			local element = elements[hovered]
			local h_text = type(element) == "table" and element.text or element or ""
			local x_offset = (type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions) and
				24 or 5

			love.graphics.setColor(bodyhovercolor)
			love.graphics.rectangle("fill", cell_x, cell_y, cell_width, cell_height)

			love.graphics.setColor(texthovercolor)
			love.graphics.setFont(font)

			if type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions then
				local icon = element.icon
				local icon_w, icon_h = icon:getDimensions()
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(icon, cell_x + 5, cell_y + cell_height / 2 - icon_h / 2)
				love.graphics.setColor(texthovercolor)
			end

			skin.PrintText(h_text, cell_x + x_offset, text_y)
		end

		if highlight and selected ~= 0 then
			local cell_x = x
			local cell_y = y + (selected - 1) * cell_height
			local text_y = y + (selected - 1) * cell_height + padding / 2
			local element = elements[selected]
			local h_text = type(element) == "table" and element.text or element or ""
			local x_offset = (type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions) and
				24 or 5

			love.graphics.setColor(bodyactivecolor)
			love.graphics.rectangle("fill", cell_x, cell_y, cell_width, cell_height)

			love.graphics.setColor(textactivecolor)
			love.graphics.setFont(font)

			if type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions then
				local icon = element.icon
				local icon_w, icon_h = icon:getDimensions()
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(icon, cell_x + 5, cell_y + cell_height / 2 - icon_h / 2)
				love.graphics.setColor(textactivecolor)
			end

			skin.PrintText(h_text, cell_x + x_offset, text_y)
		end
	end

	function skin.droplist_over(object)
	end

	--[[---------------------------------------------------------
	- func: skin.DrawDropList(object)
	- desc: draws the drop list object
--]] ---------------------------------------------------------
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
			love.graphics.draw(text, fx + 1, fy + 1)
		end
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(text, fx, fy)
	end

	--[[---------------------------------------------------------
	- func: skin.DrawToast(object)
	- desc: draws the toast object
--]] ---------------------------------------------------------
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
			box_x = math.floor(width * (1 - self.relative_box_width)) - self.box_margin
		elseif self.box_valign == "left" then
			box_x = self.box_margin
		end

		for i = 1, #self.messages do
			local msg
			if self.message_order == "ascending" then
				msg = self.messages[(#self.messages - i) + 1]
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
				love.graphics.draw(msg.batch, msg_x + 1, current_y + msg.padding + 1)
			end

			-- Text
			love.graphics.setColor(pal.text[1], pal.text[2], pal.text[3], pal.text[4] * msg.alpha)
			if msg.color then
				love.graphics.setColor(
					msg.color[1], msg.color[2], msg.color[3], msg.color[4] * msg.alpha)
			end
			love.graphics.draw(msg.batch, msg_x, current_y + msg.padding)

			current_y = current_y + msg.height + msg.spacing
		end

		love.graphics.pop()
		love.graphics.setColor(1, 1, 1, 1)
	end

	--[[---------------------------------------------------------
	- func: skin.DrawColumnList(object)
	- desc: draws the column list object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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

		local name = ParseHeaderText(object:GetName(), x, width, x + width / 2, twidth)

		if down then
			-- header body
			love.graphics.setColor(bodydowncolor)
			love.graphics.rectangle("fill", x, y, width, height)
			-- header name
			love.graphics.setFont(font)
			love.graphics.setColor(textdowncolor)
			skin.PrintText(name, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)
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
			skin.PrintText(name, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)
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
			skin.PrintText(name, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)
			-- header border
			love.graphics.setColor(bordercolor)
			skin.OutlinedRectangle(x, y, width, height)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawColumnListArea(object)
	- desc: draws the column list area object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
				local texty = rheight / 2 - theight / 2
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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

		for i = 1, object.rows do
			for n = 1, object.columns do
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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

			local enabled = object.enabled
			if enabled == nil then enabled = true end

			if enabled and object.activated then
				love.graphics.setColor(body_hover_color)
				love.graphics.rectangle("fill", 2, 2, width - 4, height - 4)
			end

			if not enabled then
				local disabled_color = skin.controls.text_disabled_color
				love.graphics.setColor(disabled_color)
				skin.PrintText(text, 26, margin)
			elseif hover then
				love.graphics.setColor(body_hover_color)
				love.graphics.rectangle("fill", 2, 2, width - 4, height - 4)
				love.graphics.setColor(text_hover_color)
				skin.PrintText(text, 26, margin)
			else
				love.graphics.setColor(text_color)
				skin.PrintText(text, 26, margin)
			end

			if not enabled then
				love.graphics.setColor(1, 1, 1, 0.35)
			else
				love.graphics.setColor(1, 1, 1, 1)
			end

			if option_type == "submenu_activator" then
				local arrow = skin.images["arrow-right.png"]
				love.graphics.draw(arrow, width - arrow:getWidth(), height / 2 - arrow:getHeight() / 2)
			end

			if icon then
				local image_width, image_height = icon:getDimensions()
				local image_width_h, image_height_h = image_width / 2, image_height / 2
				local scale_x = 1 / image_width * 16
				local scale_y = 1 / image_height * 16
				love.graphics.draw(icon, 5, height / 2, 0, scale_x, scale_y, 0, image_height_h)
			end
		end

		love.graphics.pop()
	end

	--[[---------------------------------------------------------
	- func: skin.menubar(object)
	- desc: draws the menubar object
--]] ---------------------------------------------------------
	function skin.menubar(object)
		local x = object.x
		local y = object.y
		local width = object.width
		local height = object.height
		local bodycolor = skin.controls.menubar_body_color
		local bordercolor = skin.controls.menubar_border_color or bordercolor

		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", x, y, width, height)

		-- Bottom border
		love.graphics.setColor(bordercolor)
		love.graphics.rectangle("fill", x, y + height - 1, width, 1)

		local font = skin.controls.menubar_text_font
		love.graphics.setFont(font)

		for i, item in ipairs(object.items) do
			local ix = x + item.x
			local iy = y
			local iw = item.width
			local ih = height

			local is_active = (object.menu_active and object.active_menu == item.menu)
			local is_hover = (i == object.hovered_index)

			if is_active then
				love.graphics.setColor(skin.controls.menubar_item_active_color)
				love.graphics.rectangle("fill", ix, iy, iw, ih - 1)
			elseif is_hover then
				love.graphics.setColor(skin.controls.menubar_item_hover_color)
				love.graphics.rectangle("fill", ix, iy, iw, ih - 1)
			end

			if is_active or is_hover then
				love.graphics.setColor(skin.controls.menubar_text_hover_color)
			else
				love.graphics.setColor(skin.controls.menubar_text_color)
			end

			local th = font:getHeight()
			skin.PrintText(item.text, ix + 15, iy + ih / 2 - th / 2)
		end
	end

	skin.menubarmenu = skin.menu

	function skin.filebrowser(object)
		local x = object:GetX()
		local y = object:GetY()
		local width = object:GetWidth()
		local height = object:GetHeight()
		local bodycolor = skin.controls.panel_body_color
		local bcolor = skin.controls.panel_border_color or bordercolor

		love.graphics.setColor(bodycolor)
		love.graphics.rectangle("fill", x, y, width, height)

		love.graphics.setColor(bcolor)
		skin.OutlinedRectangle(x, y, width, height)
	end

	function skin.tree(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()

		local nohovercolor = skin.directives.text_default_color
		local textselectedcolor = skin.controls.textbox_selected_color
		local textactivecolor = skin.controls.textbox_active_color
		local highlightbarcolor = skin.controls.textbox_highlight_bar_color

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

	--[[---------------------------------------------------------
		Cubic Bezier curve evaluator (for graphfield)
	--]] ---------------------------------------------------------
	local function evaluateBezier(p0, p1, p2, p3, t)
		local mt = 1 - t
		local w0 = mt * mt * mt
		local w1 = 3 * mt * mt * t
		local w2 = 3 * mt * t * t
		local w3 = t * t * t

		local rx = w0 * p0[1] + w1 * p1[1] + w2 * p2[1] + w3 * p3[1]
		local ry = w0 * p0[2] + w1 * p1[2] + w2 * p2[2] + w3 * p3[2]
		return rx, ry
	end

	local function drawBezier(x1, y1, x2, y2, color, sockettype)
		local steps = 30
		local points = {}

		-- Calculate control points for horizontal bezier curve
		local dx = math.abs(x2 - x1)
		local offset = math.max(60, dx * 0.5)

		local p0, p1, p2, p3
		if sockettype == "output" then
			p0 = { x1, y1 }
			p1 = { x1 + offset, y1 }
			p2 = { x2 - offset, y2 }
			p3 = { x2, y2 }
		else
			p0 = { x1, y1 }
			p1 = { x1 - offset, y1 }
			p2 = { x2 + offset, y2 }
			p3 = { x2, y2 }
		end

		for i = 0, steps do
			local t = i / steps
			local rx, ry = evaluateBezier(p0, p1, p2, p3, t)
			table.insert(points, rx)
			table.insert(points, ry)
		end

		love.graphics.setColor(color)
		love.graphics.setLineWidth(2)
		love.graphics.line(points)
		love.graphics.setLineWidth(1)
	end

	function skin.graphfield(object)
		local x, y = object:GetPos()
		local w, h = object:GetSize()

		-- Draw workspace background using dark brown border palette
		love.graphics.setColor(pal.dark_chocolate)
		love.graphics.rectangle("fill", x, y, w, h)

		-- Minor grid lines (spacing = 20)
		local grid = 20
		local ox = object.scrollx % grid
		local oy = object.scrolly % grid
		love.graphics.setColor(pal.chocolate[1], pal.chocolate[2], pal.chocolate[3], 0.3)
		for gx = x + ox, x + w, grid do
			love.graphics.line(gx, y, gx, y + h)
		end
		for gy = y + oy, y + h, grid do
			love.graphics.line(x, gy, x + w, gy)
		end

		-- Major grid lines (spacing = 100)
		local major = 100
		local mx_offset = object.scrollx % major
		local my_offset = object.scrolly % major
		love.graphics.setColor(pal.chocolate[1], pal.chocolate[2], pal.chocolate[3], 0.6)
		for gx = x + mx_offset, x + w, major do
			love.graphics.line(gx, y, gx, y + h)
		end
		for gy = y + my_offset, y + h, major do
			love.graphics.line(x, gy, x + w, gy)
		end

		-- Draw active connections
		for _, conn in ipairs(object.connections) do
			local fx, fy = conn.from:GetPos()
			local tx, ty = conn.to:GetPos()
			local fw, fh = conn.from:GetSize()
			local tw, th = conn.to:GetSize()

			-- Center coordinates of the circular sockets
			local fcx, fcy = fx + fw / 2, fy + fh / 2
			local tcx, tcy = tx + tw / 2, ty + th / 2

			drawBezier(fcx, fcy, tcx, tcy, conn.from.color, "output")
		end

		-- Draw connection line preview when dragging
		if object.drag_src_socket then
			local sx, sy = object.drag_src_socket:GetPos()
			local sw, sh = object.drag_src_socket:GetSize()
			local scx, scy = sx + sw / 2, sy + sh / 2
			local mx, my = love.mouse.getPosition()

			drawBezier(scx, scy, mx, my, object.drag_src_socket.color, object.drag_src_socket.sockettype)
		end
	end

	function skin.graphnode(object)
		local x, y = object:GetPos()
		local w, h = object:GetSize()

		-- Node background panel
		love.graphics.setColor(pal.cream)
		love.graphics.rectangle("fill", x, y, w, h, 4, 4)

		-- Header title bar
		love.graphics.setColor(pal.cream_dark)
		love.graphics.rectangle("fill", x, y, w, object.header_height, 4, 4)
		-- Sharp rect overlay to cover bottom rounded corners of the header
		love.graphics.rectangle("fill", x, y + object.header_height - 4, w, 4)

		-- Draw title text
		love.graphics.setFont(skin.controls.titlefont)
		love.graphics.setColor(pal.text)
		skin.PrintText(object.name, x + 8, y + (object.header_height - 12) / 2)

		-- Highlight border when hovered/dragged
		if object.hover or object.dragging then
			love.graphics.setColor(pal.gold)
		else
			love.graphics.setColor(pal.border)
		end
		love.graphics.rectangle("line", x, y, w, h, 4, 4)
	end

	function skin.graphsocket(object)
		local x, y = object:GetPos()
		local w, h = object:GetSize()
		local cx, cy = x + w / 2, y + h / 2
		local r = w / 2

		local font = skin.controls.smallfont
		local tw = font:getWidth(object.name)
		local th = font:getHeight()

		-- Draw socket circle
		if object.hover then
			-- Glowing effect when hovered
			love.graphics.setColor(object.color[1], object.color[2], object.color[3], 0.3)
			love.graphics.circle("fill", cx, cy, r + 4)
		end

		-- Check if connected
		local connected = false
		local gf = object:GetGraphField()
		if gf then
			connected = gf:IsSocketConnected(object)
		end

		love.graphics.setColor(object.color)
		if connected then
			love.graphics.circle("fill", cx, cy, r)
		else
			love.graphics.circle("line", cx, cy, r)
			-- smaller dot inside
			love.graphics.circle("fill", cx, cy, r - 3)
		end

		-- Draw socket name text next to it
		love.graphics.setFont(font)
		love.graphics.setColor(pal.text)
		if object.sockettype == "input" then
			skin.PrintText(object.name, x + w + 6, cy - th / 2)
		else
			skin.PrintText(object.name, x - tw - 6, cy - th / 2)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.radialmenu(object)
	- desc: draws the radial menu object
--]] ---------------------------------------------------------
	function skin.radialmenu(object)
		if not object.visible then return end
		local cx = object.x + object.radius_outer
		local cy = object.y + object.radius_outer
		local num_options = #object.options

		if num_options == 0 then return end

		local slice = (math.pi * 2) / num_options
		local font = skin.controls.smallfont
		local gap = 0.05 -- gap angle

		-- 1. Draw slices (masked by stencil to form a donut)
		love.graphics.setStencilState("replace", "always", 1)
		love.graphics.setColorMask(false, false, false, false)
		love.graphics.circle("fill", cx, cy, object.radius_inner)

		love.graphics.setStencilState("keep", "notequal", 1)
		love.graphics.setColorMask(true, true, true, true)

		for i = 1, num_options do
			local start_angle = (i - 1.5) * slice + gap / 2
			local end_angle = start_angle + slice - gap

			local current_radius = object.radius_outer
			if object.hovered_option == i then
				-- Hovered slices pop out slightly and are solid
				love.graphics.setColor(pal.gold)
				current_radius = current_radius + 6
			else
				-- Normal slices are slightly translucent
				love.graphics.setColor(pal.cream_dark[1], pal.cream_dark[2], pal.cream_dark[3], 0.85)
			end

			-- Draw slice
			love.graphics.arc("fill", "pie", cx, cy, current_radius, start_angle, end_angle)
		end

		love.graphics.setStencilMode("off") -- Reset stencil so text can safely overflow if needed

		-- 2. Draw texts
		for i = 1, num_options do
			local start_angle = (i - 1.5) * slice + gap / 2

			local current_radius = object.radius_outer
			if object.hovered_option == i then
				current_radius = current_radius + 6
			end

			local mid_angle = start_angle + (slice - gap) / 2
			local text_radius = (object.radius_inner + current_radius) / 2
			local tx = cx + math.cos(mid_angle) * text_radius
			local ty = cy + math.sin(mid_angle) * text_radius

			local opt = object.options[i]
			love.graphics.setFont(font)
			if object.hovered_option == i then
				love.graphics.setColor(pal.dark_chocolate)
			else
				love.graphics.setColor(pal.text)
			end

			local text_w = font:getWidth(opt.text)
			local text_h = font:getHeight()
			skin.PrintText(opt.text, tx - text_w / 2, ty - text_h / 2)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.loading(object)
	- desc: draws the loading object
--]] ---------------------------------------------------------
	function skin.loading(object)
		local x = object.x
		local y = object.y
		local radius = object.radius
		local angle = object.angle
		local cx = x + radius
		local cy = y + radius

		LG.push()
		LG.translate(cx, cy)
		LG.rotate(angle)

		local num_dots = 8
		for i = 1, num_dots do
			local a = (i / num_dots) * math.pi * 2
			local dx = math.cos(a) * (radius * 0.7)
			local dy = math.sin(a) * (radius * 0.7)

			local alpha = (i / num_dots)
			LG.setColor(pal.chocolate[1], pal.chocolate[2], pal.chocolate[3], alpha)

			LG.circle("fill", dx, dy, radius * 0.15 + (alpha * radius * 0.1))
		end

		LG.pop()
	end

	-- register the skin
	loveframes.RegisterSkin(skin)

	---------- module end ----------
end
