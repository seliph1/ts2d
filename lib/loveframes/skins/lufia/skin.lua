--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	local LG          = love.graphics
	local lovepatch   = loveframes.lovepatch
	local hex         = loveframes.HexColor
	local floor, ceil = math.floor, math.ceil

	-- skin table
	local skin        = {}

	-- skin info (you always need this in a skin)
	skin.name         = "lufia"
	skin.author       = "mozilla"
	skin.version      = "1.0"

	-- get current path
	skin.current_path = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\\\])") or "./"
	local cwd         = skin.current_path

	-- Palette: theme, contrast, and Gray tones -------------------------------
	-- Tweak these and the whole skin follows.
	local pal         = {}


	-- themes (base backgrounds & panels)
	pal.theme_light                          = hex("#c2a380") -- main panel / list fill
	pal.theme                                = hex("#a88761") -- secondary fill (rows, headers, hover)
	pal.theme_dark                           = hex("#8f6e47") -- pressed / active / selected fill
	pal.theme_darker                         = hex("#75542e") -- very dark theme for accents
	pal.border                               = hex("#332114") -- dark-theme outline

	-- contrasts (accents / highlights / close buttons)
	pal.contrast_light                       = hex("#80c8f0")
	pal.contrast                             = hex("#3860e8")
	pal.contrast_dark                        = hex("#0048d0")
	pal.contrast_darker                      = hex("#002068") -- text selection highlight

	-- Grays (secondary elements / slots / borders)
	pal.grey_light                           = hex("#bfbfbf")
	pal.grey                                 = hex("#808080")
	pal.grey_dark                            = hex("#404040")
	pal.red                                  = hex("#ff0000")
	pal.green                                = hex("#00ff00")
	pal.blue                                 = hex("#0000ff")

	-- Text
	pal.text                                 = hex("#000000e6") -- dark-theme text
	pal.text_soft                            = hex("#00000080") -- secondary / disabled text
	pal.text_strong                          = hex("#000000") -- emphasized / hover text
	pal.text_contrast                        = hex("#ffffffe6") -- light-theme text
	pal.text_contrast_soft                   = hex("#ffffff80") -- secondary / disabled text
	pal.text_contrast_strong                 = hex("#ffffff") -- emphasized / hover text

	-- Neutrals
	pal.white                                = hex("#ffffff")
	pal.white_glass                          = hex("#ffffffcc")
	pal.white_opaque                         = hex("#ffffffe6")
	pal.black                                = hex("#000000")
	pal.black_glass                          = hex("#00000060")
	pal.black_opaque                         = hex("#00000090")
	pal.black_transparent                    = hex("#00000030")
	pal.transparent                          = hex("#00000000")
	pal.shadow                               = hex("#00000080")

	-- add skin directives to this table
	skin.directives                          = {}
	skin.directives.text_global              = skin.current_path .. "images/minecraft.ttf"
	skin.directives.text_fallbacks           = {
		skin.current_path .. "images/pix32.ttf"
	}

	skin.directives.text_font_height         = 1
	skin.directives.text_default_color       = pal.text;
	skin.directives.text_default_shadowcolor = pal.shadow;
	skin.directives.text_default_font_src    = skin.directives.text_global
	skin.directives.text_default_font_size   = 18
	skin.directives.text_default_font        = LG.newFont(
		skin.directives.text_default_font_src, skin.directives_text_default_font_size)

	do
		local fallbacks = {}
		for index, fallback_src in ipairs(skin.directives.text_fallbacks) do
			local fallback = LG.newFont(fallback_src, skin.directives.text_default_font_size)
			fallback:setLineHeight(skin.directives.text_font_height)
			table.insert(fallbacks, fallback)
		end
		skin.directives.text_default_font:setFallbacks(unpack(fallbacks))
	end

	-- controls
	skin.controls            = {}
	skin.controls.font_sizes = {
		defaultfont     = 14,
		tinyfont        = 10,
		smallfont       = 12,
		titlefont       = 16,
		imagebuttonfont = 18,
	}

	if skin.directives.text_default_font_src then
		for size, value in pairs(skin.controls.font_sizes) do
			skin.controls[size] = LG.newFont(skin.directives.text_default_font_src, value)
			skin.controls[size]:setLineHeight(skin.directives.text_font_height)

			if skin.directives.text_fallbacks then
				local fallbacks = {}
				for index, fallback_src in ipairs(skin.directives.text_fallbacks) do
					local fallback = LG.newFont(fallback_src, value)
					fallback:setLineHeight(skin.directives.text_font_height)
					table.insert(fallbacks, fallback)
				end
				skin.controls[size]:setFallbacks(unpack(fallbacks))
			end
		end
	end

	skin.directives.tooltip_default_font  = skin.directives.text_default_font
	skin.directives.tooltip_default_color = pal.white


	-- skin global colors
	skin.controls.text_nohover_color                  = pal.text
	skin.controls.text_hover_color                    = pal.text_strong
	skin.controls.text_down_color                     = pal.text_strong
	skin.controls.text_active_color                   = pal.text_strong
	skin.controls.text_toggle_color                   = pal.text_soft
	skin.controls.text_disabled_color                 = pal.text_soft
	skin.controls.text_link_color                     = pal.theme

	-- frame
	skin.controls.frame_name_color                    = pal.white
	skin.controls.frame_name_font                     = skin.controls.titlefont
	skin.controls.frame_border_color                  = pal.border
	skin.controls.frame_body_color                    = pal.white

	-- button
	skin.controls.button_round_corner                 = 10
	skin.controls.button_down_color                   = pal.contrast
	skin.controls.button_nohover_color                = pal.contrast_darker
	skin.controls.button_hover_color                  = pal.contrast_dark
	skin.controls.button_toggle_color                 = pal.contrast_dark
	skin.controls.button_disabled_color               = pal.text_soft
	skin.controls.button_text_color                   = pal.text_contrast
	skin.controls.button_text_down_color              = pal.text_contrast
	skin.controls.button_text_nohover_color           = pal.text_contrast
	skin.controls.button_text_hover_color             = pal.text_contrast
	skin.controls.button_text_toggle_color            = pal.text_contrast
	skin.controls.button_text_disabled_color          = pal.text_soft
	skin.controls.button_text_font                    = skin.controls.smallfont
	skin.controls.button_border_disabled_color        = pal.grey_dark
	skin.controls.button_border_enabled_color         = pal.border

	-- closebutton
	skin.controls.closebutton_body_down_color         = pal.red
	skin.controls.closebutton_body_nohover_color      = pal.red
	skin.controls.closebutton_body_hover_color        = pal.red

	-- progressbar
	skin.controls.progressbar_body_color              = pal.theme_dark
	skin.controls.progressbar_color                   = pal.contrast_darker
	skin.controls.progressbar_text_color              = pal.text
	skin.controls.progressbar_border_color            = pal.transparent
	skin.controls.progressbar_text_font               = skin.controls.smallfont

	-- scrollarea
	skin.controls.scrollarea_body_color               = pal.transparent

	-- scrollbody
	skin.controls.scrollbody_nohover_color            = pal.black_transparent
	skin.controls.scrollbody_hover_color              = pal.black_glass
	skin.controls.scrollbody_down_color               = pal.black_opaque

	-- scrollbutton
	skin.controls.scrollbutton_nohover_color          = pal.black_transparent
	skin.controls.scrollbutton_hover_color            = pal.black_glass
	skin.controls.scrollbutton_down_color             = pal.black_opaque

	-- scrollbar
	skin.controls.scrollbar_down_color                = pal.white
	skin.controls.scrollbar_hover_color               = pal.white_opaque
	skin.controls.scrollbar_nohover_color             = pal.white_glass

	-- slider & button
	skin.controls.slider_bar_outline_color            = pal.black_transparent
	skin.controls.slider_button_nohover_color         = pal.white_glass
	skin.controls.slider_button_hover_color           = pal.white_opaque
	skin.controls.slider_button_down_color            = pal.white
	skin.controls.slider_button_disabled_color        = pal.grey

	-- panel
	skin.controls.panel_body_color                    = pal.white

	-- list
	skin.controls.list_body_color                     = pal.theme_light

	-- tabpanel
	skin.controls.tabpanel_body_color                 = pal.white

	-- tabbutton
	skin.controls.tab_body_nohover_color              = pal.grey
	skin.controls.tab_body_hover_color                = pal.grey_light
	skin.controls.tab_body_active_color               = pal.white
	skin.controls.tab_text_nohover_color              = pal.text
	skin.controls.tab_text_hover_color                = pal.text_strong
	skin.controls.tab_text_active_color               = pal.text_strong
	skin.controls.tab_text_font                       = skin.controls.smallfont

	-- multichoice
	skin.controls.multichoice_body_color              = pal.white
	skin.controls.multichoice_border_hover_color      = pal.white
	skin.controls.multichoice_border_nohover_color    = pal.white
	skin.controls.multichoice_border_down_color       = pal.white
	skin.controls.multichoice_border_active_color     = pal.white
	skin.controls.multichoice_border_disabled_color   = pal.shadow
	skin.controls.multichoice_text_active_color       = pal.text
	skin.controls.multichoice_text_color              = pal.text
	skin.controls.multichoice_text_font               = skin.controls.smallfont

	-- multichoicelist
	skin.controls.multichoicelist_body_color          = pal.white
	skin.controls.multichoicelist_border_color        = pal.black

	-- multichoicerow
	skin.controls.multichoicerow_body_nohover_color   = pal.transparent
	skin.controls.multichoicerow_body_hover_color     = pal.theme_dark
	skin.controls.multichoicerow_text_nohover_color   = pal.text
	skin.controls.multichoicerow_text_hover_color     = pal.text_contrast_strong
	skin.controls.multichoicerow_text_font            = skin.controls.smallfont

	-- droplist
	skin.controls.droplist_body_nohover_color         = pal.white
	skin.controls.droplist_body_hover_color           = pal.theme_dark
	skin.controls.droplist_body_active_color          = pal.contrast_dark
	skin.controls.droplist_body_odd_color             = pal.white
	skin.controls.droplist_body_even_color            = pal.grey_light
	skin.controls.droplist_text_nohover_color         = pal.text
	skin.controls.droplist_text_hover_color           = pal.text_contrast
	skin.controls.droplist_text_active_color          = pal.text_contrast_strong
	skin.controls.droplist_text_font                  = skin.controls.smallfont

	-- tooltip
	skin.controls.tooltip_body_color                  = pal.black
	skin.controls.tooltip_border_color                = pal.black
	skin.controls.tooltip_font_color                  = pal.white

	-- textbox
	skin.controls.textbox_border_hover_color          = pal.contrast_darker
	skin.controls.textbox_border_nohover_color        = pal.border
	skin.controls.textbox_border_active_color         = pal.contrast
	skin.controls.textbox_border_disabled_color       = pal.border
	skin.controls.textbox_body_color                  = pal.black
	skin.controls.textbox_indicator_color             = pal.black
	skin.controls.textbox_normal_color                = pal.text
	skin.controls.textbox_active_color                = pal.text_strong
	skin.controls.textbox_placeholder_color           = pal.text_soft
	skin.controls.textbox_selected_color              = pal.text_contrast_strong
	skin.controls.textbox_highlight_bar_color         = pal.contrast

	-- checkbox
	skin.controls.checkbox_body_color                 = pal.transparent
	skin.controls.checkbox_border_color               = pal.border
	skin.controls.checkbox_check_color                = pal.contrast
	skin.controls.checkbox_hover_color                = pal.contrast_darker
	skin.controls.checkbox_disabled_color             = pal.shadow
	skin.controls.checkbox_text_font                  = skin.controls.smallfont

	-- toggle
	skin.controls.toggle_body_off_color               = pal.theme
	skin.controls.toggle_body_on_color                = pal.contrast
	skin.controls.toggle_knob_color                   = pal.theme_dark
	skin.controls.toggle_hover_color                  = pal.contrast_darker
	skin.controls.toggle_border_color                 = pal.border
	skin.controls.toggle_disabled_color               = pal.shadow
	skin.controls.toggle_text_font                    = skin.controls.smallfont

	-- radiobutton
	skin.controls.radiobutton_check_color             = pal.contrast
	skin.controls.radiobutton_checkinner_color        = pal.contrast
	skin.controls.radiobutton_hover_color             = pal.contrast_darker
	skin.controls.radiobutton_inner_border_color      = pal.contrast_light
	skin.controls.radiobutton_disabled_color          = pal.shadow
	skin.controls.radiobutton_text_font               = skin.controls.smallfont

	-- collapsiblecategory
	skin.controls.collapsiblecategory_text_color      = pal.text

	-- columnlist
	skin.controls.columnlist_body_color               = pal.theme_light

	-- columlistarea
	skin.controls.columnlistarea_body_color           = pal.theme_light

	-- columnlistheader
	skin.controls.columnlistheader_body_down_color    = pal.contrast
	skin.controls.columnlistheader_body_hover_color   = pal.theme_dark
	skin.controls.columnlistheader_body_nohover_color = pal.theme
	skin.controls.columnlistheader_text_down_color    = pal.text_strong
	skin.controls.columnlistheader_text_nohover_color = pal.text
	skin.controls.columnlistheader_text_hover_color   = pal.text_strong
	skin.controls.columnlistheader_text_font          = skin.controls.tinyfont

	-- columnlistrow
	skin.controls.columnlistrow_body1_color           = pal.theme_light
	skin.controls.columnlistrow_body2_color           = pal.theme
	skin.controls.columnlistrow_body_selected_color   = pal.contrast
	skin.controls.columnlistrow_body_hover_color      = pal.theme_darker
	skin.controls.columnlistrow_text_color            = pal.text
	skin.controls.columnlistrow_text_hover_color      = pal.text_strong
	skin.controls.columnlistrow_text_selected_color   = pal.white

	-- grid
	skin.controls.grid_body_color                     = pal.theme_light

	-- menu & menuoption
	skin.controls.menu_body_color                     = pal.theme_light
	skin.controls.menu_border_color                   = pal.border
	skin.controls.menuoption_body_hover_color         = pal.theme
	skin.controls.menuoption_text_hover_color         = pal.text_strong
	skin.controls.menuoption_text_color               = pal.text
	skin.controls.menuoption_text_font                = skin.controls.smallfont

	-- menubar
	skin.controls.menubar_body_color                  = pal.theme_light
	skin.controls.menubar_text_font                   = skin.controls.smallfont
	skin.controls.menubar_text_color                  = pal.text
	skin.controls.menubar_text_hover_color            = pal.text_strong
	skin.controls.menubar_item_hover_color            = pal.theme
	skin.controls.menubar_item_active_color           = pal.theme_dark
	skin.controls.menubar_border_color                = pal.border

	-- dial
	skin.controls.dial_circle                         = pal.theme
	skin.controls.dial_circle_hover                   = pal.theme_light
	skin.controls.dial_pointer                        = pal.theme_dark
	skin.controls.dial_border                         = pal.border

	skin.controls.joystick_base                       = pal.theme
	skin.controls.joystick_base_hover                 = pal.theme_light
	skin.controls.joystick_border                     = pal.border
	skin.controls.joystick_knob                       = pal.theme_dark
	skin.controls.joystick_knob_hover                 = pal.contrast_light

	-- radialmenu
	skin.controls.radialmenu_hover_color              = pal.contrast_light
	skin.controls.radialmenu_nohover_color            = pal.contrast_dark
	skin.controls.radialmenu_text_hover_color         = pal.text
	skin.controls.radialmenu_text_nohover_color       = pal.text_contrast


	function skin.PrintText(text, x, y)
		LG.print(text, floor(x + 0.5), floor(y + 0.5))
	end

	local frameBG = LG.newImage(cwd .. "images/frame.png")
	frameBG:setWrap("repeat", "repeat")
	local frameQuad = LG.newQuad(0, 0, 0, 0, frameBG)
	local panelPatch = lovepatch.new(cwd .. "images/panel.png", 32, 32)
	local buttonPatch = lovepatch.new(cwd .. "images/button.png", 6)
	local bluePatch = lovepatch.new(cwd .. "images/bluepanel.png", 24, 24)
	local linePatch = lovepatch.new(cwd .. "images/linepanel.png", 32)
	local transparentPatch = lovepatch.new(cwd .. "images/transparentpanel.png", 32)
	local tabPatch = lovepatch.new(cwd .. "images/tab.png", 64, 64)
	local scrollPatch = lovepatch.new(cwd .. "images/scroll.png", 4)

	local cursor = loveframes.CreateSpriteSheet(cwd .. "images/cursor.png", 16, 16)
	local cursorpoint = loveframes.CreateSpriteSheet(cwd .. "images/cursorpoint.png", 16, 16)
	local cursor2x = loveframes.CreateSpriteSheet(cwd .. "images/cursor2x.png", 32, 32)
	local cursorpoint2x = loveframes.CreateSpriteSheet(cwd .. "images/cursorpoint2x.png", 32, 32)

	--[[---------------------------------------------------------
	- func: OutlinedRectangle(x, y, width, height, ovt, ovb, ovl, ovr)
	- desc: creates and outlined rectangle
--]] ---------------------------------------------------------
	function skin.OutlinedRectangle(x, y, width, height, ovt, ovb, ovl, ovr, rx, ry)
		if rx and rx > 0 then
			LG.rectangle("line", x, y, width, height, rx, ry or rx)
			return
		end
		ovt = ovt or false
		ovb = ovb or false
		ovl = ovl or false
		ovr = ovr or false
		-- top
		if not ovt then
			LG.rectangle("fill", x, y, width, 1)
		end
		-- bottom
		if not ovb then
			LG.rectangle("fill", x, y + height - 1, width, 1)
		end
		-- left
		if not ovl then
			LG.rectangle("fill", x, y, 1, height)
		end
		-- right
		if not ovr then
			LG.rectangle("fill", x + width - 1, y, 1, height)
		end
	end

	function skin.ContainedFrame(bg, x, y, width, height)
		frameQuad:setViewport(x, y, width, height, bg:getWidth(), bg:getHeight())
		LG.draw(bg, frameQuad, x, y)
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
		local bordercolor   = skin.controls.frame_border_color
		local bodycolor     = skin.controls.frame_body_color

		if object:IsModal() then
			LG.setColor(pal.shadow)
			LG.rectangle("fill", 0, 0, LG.getDimensions())
		end

		LG.push()
		LG.translate(x, y)

		if not object.docked then
			LG.setColor(pal.shadow)
			LG.rectangle("fill", 8, 8, width, height)
		end

		-- BG body
		LG.setColor(bodycolor)
		skin.ContainedFrame(frameBG, 0, 0, width, height)

		LG.setColor(bordercolor)
		LG.rectangle("line", 0, 0, width, height)

		-- frame name section
		LG.setFont(font)
		if icon then
			local iconwidth = icon:getWidth()
			LG.setColor(1, 1, 1, 1)
			LG.draw(icon, 10, 5)
			LG.setColor(namecolor)
			skin.PrintText(name, iconwidth + 15, 2)
		else
			LG.setColor(namecolor)
			skin.PrintText(name, 10, 2)
		end
		LG.pop()
	end

	--[[---------------------------------------------------------
	- func: DrawButton(object)
	- desc: draws the button object
--]] ---------------------------------------------------------
	function skin.button(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local enabled = object:GetEnabled()
		local down = object:GetDown() or object:GetChecked()
		local toggle = object.GetToggle and object:GetToggle() or object.toggle
		local hover = object:GetHover()
		local controls = skin.controls

		local xoffset, yoffset = 0, 0
		local bodycolor = controls.button_nohover_color
		local textcolor = controls.button_text_nohover_color
		local captioncolor = controls.button_text_disabled_color

		if not enabled then
			bodycolor = controls.button_disabled_color
			textcolor = controls.button_text_disabled_color
		elseif down then
			xoffset, yoffset = 1, 1
			bodycolor = controls.button_down_color
			textcolor = controls.button_text_down_color
		elseif toggle then
			xoffset, yoffset = 1, 1
			bodycolor = controls.button_toggle_color
			textcolor = controls.button_text_toggle_color
		elseif hover then
			bodycolor = controls.button_hover_color
			textcolor = controls.button_text_hover_color
		end

		if object:GetCaption() ~= object:GetFormattedCaption() then
			captioncolor = controls.button_text_color
		end

		local textmesh = object:GetDrawableText()
		local text_height = textmesh:getHeight()
		local text_y = floor((height - text_height) / 2 + yoffset)

		local image_x, image_y, image_width = 0, 0, 0
		local image_padding = object:GetImagePadding()

		if object.image then
			image_width = object.image:getWidth()
			local image_height = object.image:getHeight()

			if object:GetImageAlign() == "center" then
				image_x = floor(xoffset + image_padding - image_width / 2)
				image_padding = image_padding - image_width / 2
			else
				image_x = floor(xoffset + image_padding)
			end
			image_y = floor(yoffset + (height - image_height) / 2)
		end

		local text_x = 0
		local align = object:GetAlign()
		local padding = object:GetPadding()

		if align == "right" then
			text_x = floor(xoffset - padding)
		elseif align == "left" then
			text_x = floor(xoffset + math.max(padding, image_width + image_padding))
		elseif align == "center" then
			text_x = floor(xoffset)
		end

		LG.push()
		LG.translate(x, y)

		-- Draw body
		LG.setColor(bodycolor)
		local corner = controls.button_round_corner
		LG.rectangle("fill", 0, 0, width, height, corner, corner)
		LG.setColor(1, 1, 1, 1)
		buttonPatch:draw(0, 0, width, height)

		-- Draw text
		LG.setColor(textcolor)
		LG.draw(textmesh, text_x, text_y)

		-- Draw caption
		LG.setColor(captioncolor)
		LG.draw(object:GetDrawableCaption(), floor(xoffset - object.left_padding), text_y)

		-- Draw image
		if object.image then
			LG.setColor(1, 1, 1, 1)
			LG.draw(object.image, image_x, image_y)
		end

		LG.pop()
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
				image_x = floor(x + xoffset + (width - image_width - text_width) / 2)
			elseif align == "left" then
				image_x = floor(x + xoffset + padding)
			elseif align == "right" then
				image_x = floor(x + xoffset - padding + width - text_width - image_width)
			end
			image_y = floor(y + yoffset + (height - image_height) / 2)
		end

		if align == "right" then
			text_x = floor(x + xoffset - padding)
		elseif align == "left" then
			text_x = floor(x + xoffset + padding + image_width)
		elseif align == "center" then
			text_x = floor(x + xoffset + image_width / 2)
		end
		text_y = floor((y + (height - text_height) / 2) + yoffset)

		-- Draw Image
		if object.image then
			LG.setColor(pal.white)
			LG.draw(object.image, image_x, image_y)
		end
		-- Draw Text
		if enabled then
			if hover then
				LG.setColor(hovercolor)
			else
				LG.setColor(nohovercolor)
			end
		else
			LG.setColor(disabledcolor)
		end
		if hover and hovertext ~= "" then
			LG.draw(hovertextmesh, text_x, text_y)
		else
			LG.draw(textmesh, text_x, text_y)
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
			LG.setColor(bodydowncolor)
			LG.draw(image, x, y)
		elseif hover then
			-- button body
			LG.setColor(bodyhovercolor)
			LG.draw(image, x, y)
		else
			-- button body
			LG.setColor(bodynohovercolor)
			LG.draw(image, x, y)
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
		local centecontrast = object.centecontrast

		if not object.image then
			return
		end

		if stretch then
			scalex, scaley = object:GetWidth() / image:getWidth(), object:GetHeight() / image:getHeight()
		end

		if centecontrast then
			offsetx = offsetx + object.image:getWidth() / 2
			offsety = offsety + object.image:getHeight() / 2

			x = x + object.image:getWidth() / 2
			y = y + object.image:getHeight() / 2
		end

		if color then
			LG.setColor(color)
			LG.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
		else
			LG.setColor(1, 1, 1, 1)
			LG.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
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
			LG.setColor(color)
			LG.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
		else
			LG.setColor(1, 1, 1, 1)
			LG.draw(image, x, y, orientation, scalex, scaley, offsetx, offsety, shearx, sheary)
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
				LG.setColor(imagecolor)
				LG.draw(image, x + 1, y + 1)
			end
		elseif hover then
			if image then
				LG.setColor(imagecolor)
				LG.draw(image, x, y)
			end
		else
			if image then
				LG.setColor(imagecolor)
				LG.draw(image, x, y)
			end
		end
		if checked == true then
			--[[
			LG.setColor(bordercolor)
			LG.setLineWidth(3)
			LG.setLineStyle("smooth")
			LG.rectangle("line", x + 1, y + 1, width - 2, height - 2)
			]]
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
		local barcolor = skin.controls.progressbar_color
		local textcolor = skin.controls.progressbar_text_color
		local bordercolor = skin.controls.progressbar_border_color
		local image = skin.images["progressbar.png"]
		local imageheight = image:getHeight()
		local scaley = height / imageheight

		-- progress bar body
		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)

		-- Bar color
		if object.color then
			LG.setColor(object.color)
		else
			LG.setColor(barcolor)
		end
		loveframes.Colorize(image, x, y, 0, barwidth, scaley)

		-- Bar Text
		LG.setFont(font)
		LG.setColor(textcolor)
		skin.PrintText(text, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)

		-- progress bar border
		LG.setColor(bordercolor)
		LG.rectangle("line", x, y, width, height)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollBar(object)
	- desc: draws the scroll bar object
--]] ---------------------------------------------------------
	function skin.scrollbar(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local dragging = object:IsAnchored()
		local hover = object:GetHover()

		if dragging then
			LG.setColor(skin.controls.scrollbar_down_color)
		elseif hover then
			LG.setColor(skin.controls.scrollbar_hover_color)
		else
			LG.setColor(skin.controls.scrollbar_nohover_color)
		end
		scrollPatch:draw(x, y, width, height)

		local image = skin.images["scrollstub.png"]
		local halfW = (width - image:getWidth()) / 2
		local halfH = (height - image:getHeight()) / 2

		LG.draw(image, x + halfW, y + halfH)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollBody(object)
	- desc: draws the scroll body object
--]] ---------------------------------------------------------
	function skin.scrollbody(object)
	end

	function skin.scrollarea(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local radius = 6
		local padding = -6
		LG.setColor(skin.controls.scrollbody_nohover_color)
		LG.rectangle("fill", x - padding, y - padding, width + padding * 2, height + padding * 2, radius)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollButton(object)
	- desc: draws the scroll button object
--]] ---------------------------------------------------------
	function skin.scrollbutton(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()

		local scrolltype = object:GetScrollType()
		local hover = object:GetHover()
		local down = object.down

		local image
		if scrolltype == "up" then
			image = skin.images["arrow-up.png"]
		elseif scrolltype == "down" then
			image = skin.images["arrow-down.png"]
		elseif scrolltype == "left" then
			image = skin.images["arrow-left.png"]
		elseif scrolltype == "right" then
			image = skin.images["arrow-right.png"]
		end
		if down then
			LG.setColor(skin.controls.scrollbutton_down_color)
		elseif hover then
			LG.setColor(skin.controls.scrollbutton_hover_color)
		else
			LG.setColor(skin.controls.scrollbutton_nohover_color)
		end

		local halfW = (width - image:getWidth()) / 2
		local halfH = (height - image:getHeight()) / 2
		LG.draw(image, x + halfW, y + halfH)
	end

	--[[---------------------------------------------------------
	- func: DrawPanel(object)
	- desc: draws the panel object
--]] ---------------------------------------------------------
	function skin.panel(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local bodycolor = skin.controls.panel_body_color

		LG.setColor(bodycolor)
		panelPatch:drawTiled(x, y, width, height)
	end

	--[[---------------------------------------------------------
	- func: DrawScrollPanel(object)
	- desc: draws the panel object
--]] ---------------------------------------------------------
	function skin.scrollpanel_over(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local bodycolor = skin.controls.panel_body_color

		if object.background then
			LG.setColor(bodycolor)
			linePatch:drawTiled(x, y, width, height)
		end
	end

	--[[---------------------------------------------------------
	- func: DrawContainer(object)
	- desc: draws the panel object
--]] ---------------------------------------------------------
	function skin.container(object)
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
		LG.setColor(bodycolor)
		tabPatch:drawTiled(0, 0, width, height)

		local text_offset = parent.tabmargin
		local imagewidth, imageheight = 0, 0
		if image then
			imagewidth, imageheight = image:getDimensions()
			local scale = 1
			if imageheight > (parent.tabheight - parent.tabmargin) then
				scale = (parent.tabheight - parent.tabmargin) / imageheight
			end
			-- button image
			LG.setColor(1, 1, 1, 1)
			LG.draw(image, parent.tabmargin, height / 2 - imageheight * scale / 2, 0, scale)
			text_offset = text_offset + floor(imagewidth * scale) + parent.tabmargin
		end

		-- button text
		LG.setFont(font)
		LG.setColor(textcolor)
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
		local radius = 4

		local bodycolor = skin.controls.multichoice_body_color
		local textcolor = skin.controls.multichoice_text_color
		local textactivecolor = skin.controls.multichoice_text_active_color
		local borderactivecolor = skin.controls.multichoice_border_active_color
		local borderhovercolor = skin.controls.multichoice_border_hover_color
		local bordernohovercolor = skin.controls.multichoice_border_nohover_color
		local enabled = object:GetEnabled()

		if not enabled then
			bodycolor = skin.controls.text_disabled_color
			textcolor = skin.controls.text_disabled_color
			bordernohovercolor = skin.controls.multichoice_border_disabled_color
			borderhovercolor = bordernohovercolor
		end

		local offset = floor((height - image:getHeight()) / 2)
		-- Draw frame body
		LG.setColor(bodycolor)
		LG.rectangle("fill", x + 1, y + 1, width - 2, height - 2, radius)

		if haslist then
			LG.setColor(borderactivecolor)
		else
			if hover then
				LG.setColor(borderhovercolor)
			else
				LG.setColor(bordernohovercolor)
			end
		end
		linePatch:draw(x, y, width, height)
		-- Draw selected option
		if haslist then
			LG.setColor(textactivecolor)
			LG.setFont(font)
		else
			LG.setColor(textcolor)
			LG.setFont(font)
		end
		if choice == "" then
			skin.PrintText(text, x + 5, y + height / 2 - theight / 2)
		else
			skin.PrintText(choice, x + 5, y + height / 2 - theight / 2)
		end
		-- Draw downarrow button
		image:setFilter("nearest", "nearest")
		if enabled then
			LG.setColor(pal.white)
		else
			LG.setColor(bodycolor)
		end
		LG.draw(image, x + width - 20, y + offset)
	end

	--[[---------------------------------------------------------
	- func: DrawMultiChoiceList(object)
	- desc: draws the multi choice list object
--]] ---------------------------------------------------------
	function skin.multichoicelist(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local bordercolor = skin.controls.multichoicelist_border_color
		local bodycolor = skin.controls.multichoicelist_body_color

		LG.setColor(pal.shadow)
		LG.rectangle("fill", x + 8, y + 8, width, height)

		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)

		LG.setColor(bordercolor)
		LG.rectangle("line", x, y, width, height)
	end

	--[[---------------------------------------------------------
	- func: DrawMultiChoiceRow(object)
	- desc: draws the multi choice row object
--]] ---------------------------------------------------------
	function skin.multichoicerow(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local text = object:GetText()
		local font = skin.controls.multichoicerow_text_font
		local texthovercolor = skin.controls.multichoicerow_text_hover_color
		local textnohovercolor = skin.controls.multichoicerow_text_nohover_color
		local hpadding = 5
		local vpadding = 2
		LG.setFont(font)
		if object.hover then
			LG.setColor(skin.controls.multichoicerow_body_hover_color)
			LG.rectangle("fill", x, y, width, height)
			LG.setColor(texthovercolor)
			skin.PrintText(text, x + hpadding, y + vpadding)
		else
			LG.setColor(skin.controls.multichoicerow_body_nohover_color)
			LG.rectangle("fill", x, y, width, height)
			LG.setColor(textnohovercolor)
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
		local offset_x = floor(x - width / 2)
			+ math.max(0, floor(width / 2 - x + margin))
			- math.max(0, floor(width / 2 + x + margin - LG.getWidth()))
		local offset_y = y + 30
		if y + 30 + height + margin > LG.getHeight() then
			offset_y = y - 30
		end

		local bodycolor = skin.controls.tooltip_body_color
		local bordercolor = skin.controls.tooltip_border_color
		local textcolor = skin.controls.tooltip_font_color
		local time = object:GetHoverTime()

		LG.push()
		LG.translate(offset_x, offset_y)

		if time > 0.5 then
			LG.setColor(bodycolor)
			LG.rectangle("fill", -margin, -margin, width + margin * 2, height + margin * 2, 2, 2)
			LG.setColor(bordercolor)
			LG.rectangle("line", -margin, -margin, width + margin * 2, height + margin * 2, 2, 2)
			LG.setColor(textcolor)
			LG.setFont(font)
			LG.print(text, 0, 0)
		end

		LG.pop()
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

		LG.setColor(nohovercolor)
		if parent and parent.grayable and not parent.enabled then
			LG.setColor(disabledcolor)
		end
		if object.color then
			LG.setColor(object.color)
		end
		--LG.setFont()
		LG.draw(textmesh, x, y)
	end

	--[[---------------------------------------------------------
	- func: skin.MessageBox(object)
	- desc: draws the text object
--]] ---------------------------------------------------------
	function skin.messagebox(object)
		local x = floor(object.x)
		local y = floor(object.y)
		local textmesh = object.textmesh
		local shadow = object.shadow
		if shadow then
			LG.setColor(pal.shadow)
			LG.draw(textmesh, x + 1, y + 1)
		end
		LG.setColor(pal.text)
		LG.draw(textmesh, x, y)
	end

	--[[---------------------------------------------------------
	- func: skin.rtf(object)
	- desc: draws the rich text format object
--]] ---------------------------------------------------------
	function skin.rtf(object)
		local x = object.x
		local y = object.y

		local field = object.field
		LG.setColor(1, 1, 1, 1)
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
		LG.setColor(pal.theme_light)
		LG.rectangle("fill", x, y, width, height, 6, 6)
		LG.setColor(pal.contrast_light)
		LG.setLineWidth(1)
		LG.rectangle("line", x + 0.5, y + 0.5, width - 1, height - 1, 6, 6)

		-- text, clipped to the inner region
		local sx, sy, sw, sh = LG.getScissor()
		LG.setScissor(x + padding, y + padding, width - padding * 2, height - padding * 2)
		LG.setColor(1, 1, 1, 1)
		object.field:draw(x + padding, y + padding)
		LG.setScissor(sx, sy, sw, sh)

		-- blinking continue arrow once the current page has printed
		if object:IsFinished() and floor(object.blink * 2) % 2 == 0 then
			local ax = x + width - padding - 10
			local ay = y + height - padding - 8
			LG.setColor(pal.contrast_light)
			LG.polygon("fill", ax, ay, ax + 10, ay, ax + 5, ay + 6)
		end

		LG.setColor(1, 1, 1, 1)
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
		local textnormalcolor = skin.controls.textbox_normal_color
		local textplaceholdercolor = skin.controls.textbox_placeholder_color
		local textactivecolor = skin.controls.textbox_active_color
		local highlightbarcolor = skin.controls.textbox_highlight_bar_color
		local indicatorcolor = skin.controls.textbox_indicator_color

		local enabled = true
		if object.enabled ~= nil then enabled = object.enabled end
		if object.parent and object.parent.type == "numberbox" and object.parent.enabled == false then enabled = false end

		if not enabled then
			textnormalcolor = skin.controls.text_disabled_color
		end

		-- Draw body
		LG.setColor(pal.white)
		LG.rectangle("fill", x, y, width, height, 6, 6)

		-- Draw placeholder text
		LG.setFont(font)
		LG.setColor(textplaceholdercolor)
		if text_length == 0 and placeholder_text ~= "" then
			skin.PrintText(placeholder_text, x + hpadding, y + vpadding)
		end
		-- Draw the selected text
		LG.setColor(highlightbarcolor)
		for _, selection_x, selection_y, selection_w, selection_h in field:eachSelection() do
			if selection_y >= -font_height and selection_y + selection_h <= height + font_height then
				LG.rectangle("fill", selection_x + x + hpadding, selection_y + y + vpadding, selection_w,
					selection_h)
			end
		end

		-- Draw text
		if focus then
			LG.setColor(textactivecolor)
		else
			LG.setColor(textnormalcolor)
		end
		if object.color then
			LG.setColor(object.color)
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
				LG.setColor(indicatorcolor)
				LG.rectangle("fill", cursor_x + x + hpadding, cursor_y + y + vpadding, 1, cursor_height)
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
			LG.setColor(textactivecolor)
			LG.rectangle("fill", x + hHandlePos, y + height - 2, hHandleLength, 2)
		end
	end

	function skin.textbox_over(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		-- Draw body
		LG.setColor(pal.white)
		linePatch:draw(x, y, width, height)
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
			LG.setColor(skin.controls.dial_circle)
		elseif hover or object.dragging then
			LG.setColor(skin.controls.dial_circle_hover)
		else
			LG.setColor(skin.controls.dial_circle)
		end
		LG.circle("fill", cx, cy, radius)
		LG.setColor(skin.controls.dial_border)
		LG.circle("line", cx, cy, radius)

		-- indicator (0 = up, clockwise)
		local ix = cx + math.sin(angle) * (radius - 10)
		local iy = cy - math.cos(angle) * (radius - 10)
		LG.setColor(skin.controls.dial_pointer)
		LG.setLineWidth(2)
		LG.line(cx, cy, ix, iy)
		LG.setLineWidth(1)
		LG.circle("fill", ix, iy, 3)
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
			LG.setColor(skin.controls.joystick_base)
		elseif hover or active then
			LG.setColor(skin.controls.joystick_base_hover)
		else
			LG.setColor(skin.controls.joystick_base)
		end
		LG.circle("fill", cx, cy, radius)
		LG.setColor(skin.controls.joystick_border)
		LG.circle("line", cx, cy, radius)

		-- range guide
		LG.setColor(skin.controls.joystick_border[1], skin.controls.joystick_border[2],
			skin.controls.joystick_border[3], 0.35)
		LG.circle("line", cx, cy, object:GetMaxDistance())

		-- knob
		local kx = cx + object.knobx
		local ky = cy + object.knoby
		if active then
			LG.setColor(skin.controls.joystick_knob_hover)
		else
			LG.setColor(skin.controls.joystick_knob)
		end
		LG.circle("fill", kx, ky, knobr)
		LG.setColor(skin.controls.joystick_border)
		LG.circle("line", kx, ky, knobr)
	end

	--[[---------------------------------------------------------
	- func: skin.slideshow(object)
	- desc: draws the slideshow background (behind the slide)
--]] ---------------------------------------------------------
	function skin.slideshow(object)
		LG.setColor(0.18, 0.18, 0.2, 1)
		LG.rectangle("fill", object.x, object.y, object.width, object.height)
	end

	--[[---------------------------------------------------------
	- func: skin.slideshow_over(object)
	- desc: draws the slideshow border and navigation dots
--]] ---------------------------------------------------------
	function skin.slideshow_over(object)
		LG.setColor(pal.border)
		LG.rectangle("fill", object.x, object.y, object.width, object.height)
		local r = object.dotradius
		for i, dot in ipairs(object.dots) do
			if i == object.tab then
				LG.setColor(0.4, 0.55, 1, 1)
				LG.circle("fill", dot.x, dot.y, r)
			else
				LG.setColor(0.78, 0.78, 0.78, 0.85)
				LG.circle("fill", dot.x, dot.y, r - 1)
			end
			LG.setColor(0, 0, 0, 0.6)
			LG.circle("line", dot.x, dot.y, r)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.carousel(object)
	- desc: draws the carousel background
--]] ---------------------------------------------------------
	function skin.carousel(object)
		LG.setColor(pal.border)
		LG.rectangle("fill", object.x, object.y, object.width, object.height)
	end

	--[[---------------------------------------------------------
	- func: skin.carousel_over(object)
	- desc: draws the carousel border
--]] ---------------------------------------------------------
	function skin.carousel_over(object)
		LG.setColor(pal.border)
		skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
	end

	--[[---------------------------------------------------------
	- func: skin.dockzone(object)
	- desc: draws the dockzone object
--]] ---------------------------------------------------------
	function skin.dockzone(object)
		if object.highlight then
			LG.setColor(0.3, 0.6, 1, 0.2)
			LG.rectangle("fill", object.x, object.y, object.width, object.height)
			LG.setColor(0.3, 0.6, 1, 0.8)
			skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
		else
			LG.setColor(1, 1, 1, 0.05)
			LG.rectangle("fill", object.x, object.y, object.width, object.height)
			LG.setColor(1, 1, 1, 0.1)
			skin.OutlinedRectangle(object.x, object.y, object.width, object.height)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawSlider(object)
	- desc: draws the slider object
--]] ---------------------------------------------------------
	function skin.slider(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local slidtype = object:GetSlideType()
		local baroutlinecolor = skin.controls.slider_bar_outline_color
		local wideness_v, wideness_h = 4, 4
		local radius = 4
		local halfW, halfH = (width - wideness_v) / 2, (height - wideness_h) / 2

		LG.setColor(baroutlinecolor)
		if slidtype == "horizontal" then
			LG.rectangle("fill", x, y + halfH, width, wideness_h, radius)
		elseif slidtype == "vertical" then
			LG.rectangle("fill", x + halfW, y, wideness_v, height, radius)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawSliderButton(object)
	- desc: draws the slider button object
--]] ---------------------------------------------------------
	function skin.sliderbutton(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local hover = object:GetHover()
		local down = object.down
		local parent = object:GetParent()
		local enabled = parent:GetEnabled()

		local cwidth, cheight = cursor2x[1]:getDimensions()
		local halfW, halfH = (cwidth - width) / 2, (cheight - height) / 2
		local mod = 0
		local alpha = 1.0

		local drawcolor = skin.controls.slider_button_nohover_color
		if not enabled then
			return
		end
		if down then
			alpha = 1.0
			drawcolor = skin.controls.slider_button_down_color
			mod = floor(object:GetHoverTime() * 10) % 5
		elseif hover then
			alpha = 0.9
			drawcolor = skin.controls.slider_button_hover_color
			mod = floor(object:GetHoverTime() * 5) % 5
		else
			alpha = 0.8
		end
		LG.setColor(drawcolor[1], drawcolor[2], drawcolor[3], alpha)
		LG.draw(cursor2x[mod], x, y, 0, 1, 1, halfW, halfH)
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
		local bordercolor = skin.controls.checkbox_border_color
		local checkcolor = skin.controls.checkbox_check_color
		local hovercolor = skin.controls.checkbox_hover_color
		local disabledcolor = skin.controls.checkbox_disabled_color

		local offset = floor((height - box_height) / 2)
		local close_image = skin.images["ok.png"]
		local half_width = (box_width - close_image:getWidth()) / 2
		local half_height = (box_height - close_image:getHeight()) / 2

		-- Rectangle box
		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y + offset, box_width, box_height)

		-- Ghost check
		if enabled then
			if hover then
				LG.setColor(hovercolor)
			else -- not hover
				LG.setColor(bordercolor)
			end
		else
			LG.setColor(disabledcolor)
		end

		-- Border
		LG.rectangle("line", x, y + offset, box_width, box_height)

		-- Checker
		if checked then
			LG.setColor(checkcolor)
			LG.draw(close_image, x + half_width, y + half_height)
		end
	end

	--[[---------------------------------------------------------
	- func: skin.DrawToggle(object)
	- desc: draws the toggle object
--]] ---------------------------------------------------------
	function skin.toggle(object)
		local x, y = object:GetPos()
		local width, height = object:GetDimensions()
		local box_width, box_height = object:GetBoxWidth(), object:GetBoxHeight()
		local checked, enabled, hover = object:GetChecked(), object:GetEnabled(), object:GetHover()

		local controls = skin.controls
		local is_vert = (object.GetDirection and object:GetDirection() or "horizontal") == "vertical"

		local short = is_vert and box_width or box_height
		local track_x = x + (is_vert and floor((width - box_width) / 2) or 0)
		local track_y = y + (is_vert and 0 or floor((height - box_height) / 2))

		local radius = floor(short / 2)
		local padding = math.max(2, floor(short / 8))
		local knob_size = math.max(2, short - padding * 2)
		local knob_r = knob_size / 2

		local knob_cx, knob_cy
		if is_vert then
			knob_cx = track_x + box_width / 2
			knob_cy = y + (checked and (box_height - knob_size - padding) or padding) + knob_r
		else
			knob_cx = x + (checked and (box_width - knob_size - padding) or padding) + knob_r
			knob_cy = track_y + box_height / 2
		end

		local line_thickness = 8
		local line_x = is_vert and (track_x + box_width / 2 - line_thickness / 2) or track_x
		local line_y = is_vert and track_y or (track_y + box_height / 2 - line_thickness / 2)
		local line_w = is_vert and line_thickness or box_width
		local line_h = is_vert and box_height or line_thickness

		LG.setColor(enabled and (checked and controls.toggle_body_on_color or controls.toggle_body_off_color) or
			controls.toggle_disabled_color)
		LG.rectangle("fill", line_x, line_y, line_w, line_h, line_thickness / 2, line_thickness / 2, 16)


		local img_x = knob_cx - cursor2x[1]:getWidth() / 2
		local img_y = knob_cy - cursor2x[1]:getHeight() / 2
		local mod = 0
		if enabled and hover then
			mod = floor(object:GetHoverTime() * 10) % 5
		end

		if enabled then
			LG.setColor(pal.white)
			LG.draw(cursor2x[mod], img_x, img_y)
		else
			LG.setColor(pal.grey)
			loveframes.Colorize(cursor2x[mod], img_x, img_y)
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
		local disabledcolor = skin.controls.radiobutton_disabled_color
		local bordercolor = pal.border
		local radius = (box_width + box_height) / 4
		local offsetX = radius
		local offsetY = radius + (height - box_height) / 2
		LG.push()
		LG.translate(x, y)

		-- Circle
		if enabled then
			if hover then
				LG.setColor(hovercolor)
			else
				LG.setColor(bordercolor)
			end
		else
			LG.setColor(disabledcolor)
		end
		LG.setLineStyle("smooth")
		LG.setLineWidth(1)
		LG.circle("line", offsetX, offsetY, radius, 15)

		if checked then
			LG.setColor(checkinnercolor)
			LG.circle("fill", offsetX, offsetY, radius / 2, 360)
			LG.setColor(checkcolor)
			LG.circle("line", offsetX, offsetY, radius / 2, 360)
		end

		LG.pop()
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
		local bordercolor = pal.border
		local font = skin.controls.smallfont
		local radius = 6


		LG.setColor(pal.white)
		LG.rectangle("fill", x, y, width, height, radius)

		LG.setColor(pal.white)
		linePatch:draw(x, y, width, height)

		if open then
			local icon = skin.images["collapse.png"]
			icon:setFilter("nearest", "nearest")
			LG.draw(icon, x + width - 21, y + 5)
		else
			local icon = skin.images["expand.png"]
			icon:setFilter("nearest", "nearest")
			LG.draw(icon, x + width - 21, y + 5)
		end

		LG.setFont(font)
		LG.setColor(textcolor)
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

		--LG.setColor(bodycolor)
		if background then
			LG.setColor(background)
			LG.rectangle("fill", x, y, width, height)
		elseif zebra_list then
			LG.setColor(bodyoddcolor)
			LG.draw(odd_list, x, y)

			LG.setColor(bodyevencolor)
			LG.draw(even_list, x, y)
		else
			LG.setColor(bodynohovercolor)
			LG.rectangle("fill", x, y, width, height)
		end
		LG.setColor(textnohovercolor)
		LG.draw(text, x, y)

		-- Draw icons
		for i, element in ipairs(elements) do
			if type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions then
				local icon = element.icon
				local cell_y = y + (i - 1) * cell_height
				local icon_w, icon_h = icon:getDimensions()
				LG.setColor(1, 1, 1, 1)
				LG.draw(icon, x + 5, cell_y + cell_height / 2 - icon_h / 2)
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

			LG.setColor(bodyhovercolor)
			LG.rectangle("fill", cell_x, cell_y, cell_width, cell_height)

			LG.setColor(texthovercolor)
			LG.setFont(font)

			if type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions then
				local icon = element.icon
				local icon_w, icon_h = icon:getDimensions()
				LG.setColor(1, 1, 1, 1)
				LG.draw(icon, cell_x + 5, cell_y + cell_height / 2 - icon_h / 2)
				LG.setColor(texthovercolor)
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

			LG.setColor(bodyactivecolor)
			LG.rectangle("fill", cell_x, cell_y, cell_width, cell_height)

			LG.setColor(textactivecolor)
			LG.setFont(font)

			if type(element) == "table" and element.icon and type(element.icon) ~= "boolean" and element.icon.getDimensions then
				local icon = element.icon
				local icon_w, icon_h = icon:getDimensions()
				LG.setColor(1, 1, 1, 1)
				LG.draw(icon, cell_x + 5, cell_y + cell_height / 2 - icon_h / 2)
				LG.setColor(textactivecolor)
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
		local fx = floor(x - offsetx)
		local fy = floor(y - offsety)

		if object.shadow then
			LG.setColor(skin.directives.text_default_shadowcolor)
			LG.draw(text, fx + 1, fy + 1)
		end
		LG.setColor(1, 1, 1, 1)
		LG.draw(text, fx, fy)
	end

	--[[---------------------------------------------------------
	- func: skin.DrawToast(object)
	- desc: draws the toast object
--]] ---------------------------------------------------------
	function skin:toast()
		local x, y = self:GetPos()
		local width, height = self:GetDimensions()
		local shadow = self.shadow

		LG.push()
		-- Draw some toast on the screen (or container subset)
		LG.translate(x, y)

		-- Calculate total height
		local total_height = 0
		for _, msg in ipairs(self.messages) do
			total_height = total_height + msg.height + msg.spacing
		end

		local start_y = 0
		if self.box_halign == "center" then
			start_y = floor((height - total_height) / 2)
		elseif self.box_halign == "up" then
			start_y = self.box_margin
		elseif self.box_halign == "down" then
			start_y = (height - total_height) - self.box_margin
		else
			start_y = floor((height - total_height) / 2)
		end
		local current_y = start_y

		local box_width = floor(width * self.relative_box_width)
		local box_x = 0
		if self.box_valign == "center" then
			box_x = floor((width - box_width) / 2)
		elseif self.box_valign == "right" then
			box_x = floor(width * (1 - self.relative_box_width)) - self.box_margin
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
					LG.setColor(
						self.backgroundcolor[1],
						self.backgroundcolor[2],
						self.backgroundcolor[3],
						self.backgroundcolor[4] * msg.alpha
					)
				else
					LG.setColor(
						pal.theme_light[1], pal.theme_light[2], pal.theme_light[3],
						pal.theme_light[4] * msg.alpha
					)
				end
				LG.rectangle(
					"fill",
					box_x,
					current_y,
					box_width,
					msg.height,
					6,
					6
				)

				LG.setColor(
					pal.border[1], pal.border[2], pal.border[3],
					pal.border[4] * msg.alpha
				)

				LG.rectangle(
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
				LG.setColor(0, 0, 0, msg.alpha)
				LG.draw(msg.batch, msg_x + 1, current_y + msg.padding + 1)
			end

			-- Text
			LG.setColor(pal.text[1], pal.text[2], pal.text[3], pal.text[4] * msg.alpha)
			if msg.color then
				LG.setColor(
					msg.color[1], msg.color[2], msg.color[3], msg.color[4] * msg.alpha)
			end
			LG.draw(msg.batch, msg_x, current_y + msg.padding)

			current_y = current_y + msg.height + msg.spacing
		end

		LG.pop()
		LG.setColor(1, 1, 1, 1)
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
		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)
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
		local bordercolor = pal.border

		local name = object:GetName()

		if down then
			-- header body
			LG.setColor(bodydowncolor)
			LG.rectangle("fill", x, y, width, height)
			-- header name
			LG.setFont(font)
			LG.setColor(textdowncolor)
			skin.PrintText(name, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)
			-- header border
			LG.setColor(bordercolor)
			skin.OutlinedRectangle(x, y, width, height)
		elseif hover then
			-- header body
			LG.setColor(bodyhovercolor)
			LG.rectangle("fill", x, y, width, height)
			-- header name
			LG.setFont(font)
			LG.setColor(textdowncolor)
			skin.PrintText(name, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)
			-- header border
			LG.setColor(bordercolor)
			skin.OutlinedRectangle(x, y, width, height)
		else
			-- header body
			LG.setColor(nohovercolor)
			LG.rectangle("fill", x, y, width, height)
			-- header name
			LG.setFont(font)
			LG.setColor(textnohovercolor)
			skin.PrintText(name, x + width / 2 - twidth / 2, y + height / 2 - theight / 2)
			-- header border
			LG.setColor(bordercolor)
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
		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)

		-- header strip outline
		local cheight = 0
		if #columns > 0 then
			cheight = columns[1]:GetHeight()
		end
		LG.setColor(pal.border)
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
			-- rows are ordecontrast top to bottom: stop once past the bottom
			if ry >= bottom then
				break
			end
			if (ry + rheight) > top then
				local rx = row.x
				local rwidth = row.width
				local font = row.font
				local theight = font:getHeight("")
				local textx = 5
				local texty = rheight / 2 - theight / 2
				row.textx = textx
				row.texty = texty

				if row.selected then
					LG.setColor(bodyselectedcolor)
				elseif row.hover then
					LG.setColor(bodyhovercolor)
				elseif row.colorindex == 1 then
					LG.setColor(body1color)
				else
					LG.setColor(body2color)
				end
				LG.rectangle("fill", rx, ry, rwidth, rheight)

				LG.setFont(font)
				if row.selected then
					LG.setColor(textselectedcolor)
				elseif row.hover then
					LG.setColor(texthovercolor)
				else
					LG.setColor(textcolor)
				end

				local cx = rx
				for ci, value in ipairs(row.columndata) do
					local colwidth = columnlist:GetColumnWidth(ci)
					if colwidth then
						local text = value --ParseRowText(value, cx, colwidth, cx, textx)
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
		LG.setColor(pal.border)
		skin.OutlinedRectangle(x, y, width, height)
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

		LG.setColor(pal.border)
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
				LG.setColor(bodycolor)
				LG.rectangle("fill", cx, cy, cw, ch)
				LG.setColor(pal.border)
				skin.OutlinedRectangle(cx, cy, cw, ch, ovt, false, ovl, false)
				cx = cx + cw
			end
			cx = x
			cy = cy + ch
		end
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
		local bordercolor = skin.controls.menu_body_color

		LG.setColor(pal.shadow)
		LG.rectangle("fill", x + 8, y + 8, width, height)

		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)
		LG.setColor(bordercolor)
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

		LG.push()
		LG.translate(x, y)

		if option_type == "divider" then
			LG.setColor(pal.border)
			LG.rectangle("fill", 4, 2, width - 8, 1)
		else
			LG.setFont(text_font)

			local enabled = object.enabled
			if enabled == nil then enabled = true end

			if enabled and object.activated then
				LG.setColor(body_hover_color)
				LG.rectangle("fill", 2, 2, width - 4, height - 4)
			end

			if not enabled then
				local disabled_color = skin.controls.text_disabled_color
				LG.setColor(disabled_color)
				skin.PrintText(text, 26, margin)
			elseif hover then
				LG.setColor(body_hover_color)
				LG.rectangle("fill", 2, 2, width - 4, height - 4)
				LG.setColor(text_hover_color)
				skin.PrintText(text, 26, margin)
			else
				LG.setColor(text_color)
				skin.PrintText(text, 26, margin)
			end

			if not enabled then
				LG.setColor(1, 1, 1, 0.35)
			else
				LG.setColor(1, 1, 1, 1)
			end

			if option_type == "submenu_activator" then
				local arrow = skin.images["arrow-right.png"]
				LG.draw(arrow, width - arrow:getWidth(), height / 2 - arrow:getHeight() / 2)
			end

			if icon then
				local image_width, image_height = icon:getDimensions()
				local image_width_h, image_height_h = image_width / 2, image_height / 2
				local scale_x = 1 / image_width * 16
				local scale_y = 1 / image_height * 16
				LG.draw(icon, 5, height / 2, 0, scale_x, scale_y, 0, image_height_h)
			end
		end

		LG.pop()
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
		local bordercolor = skin.controls.menubar_border_color or pal.border

		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)

		-- Bottom border
		LG.setColor(bordercolor)
		LG.rectangle("fill", x, y + height - 1, width, 1)

		local font = skin.controls.menubar_text_font
		LG.setFont(font)

		for i, item in ipairs(object.items) do
			local ix = x + item.x
			local iy = y
			local iw = item.width
			local ih = height

			local is_active = (object.menu_active and object.active_menu == item.menu)
			local is_hover = (i == object.hovered_index)

			if is_active then
				LG.setColor(skin.controls.menubar_item_active_color)
				LG.rectangle("fill", ix, iy, iw, ih - 1)
			elseif is_hover then
				LG.setColor(skin.controls.menubar_item_hover_color)
				LG.rectangle("fill", ix, iy, iw, ih - 1)
			end

			if is_active or is_hover then
				LG.setColor(skin.controls.menubar_text_hover_color)
			else
				LG.setColor(skin.controls.menubar_text_color)
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
		local bcolor = skin.controls.panel_border_color or pal.border

		LG.setColor(bodycolor)
		LG.rectangle("fill", x, y, width, height)

		LG.setColor(bcolor)
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

		local sx, sy, sw, sh = love.graphics.getScissor()
		sy = sy or 0
		sh = sh or love.graphics.getHeight()

		for index, node in ipairs(nodes) do
			if node.y + node.height >= sy and node.y <= sy + sh then
				-- selection highlight
				if object.selectednode == node then
					local twidth = font:getWidth(node.text)
					local theight = font:getHeight()
					LG.setColor(highlightbarcolor)
					LG.rectangle("fill", node.textx, node.texty, twidth, theight)
				end
				-- icon
				if node.icon then
					LG.setColor(pal.white)
					LG.draw(node.icon, node.iconx, node.icony)
				end
				-- text
				LG.setFont(font)
				LG.setColor(nohovercolor)
				skin.PrintText(node.text, node.textx, node.texty)
				-- open/close button
				if node.haschildren then
					local image
					if node.open then
						image = skin.images["tree-node-button-close.png"]
					else
						image = skin.images["tree-node-button-open.png"]
					end
					LG.setColor(pal.white)
					LG.draw(image, node.buttonx, node.buttony)
				end
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

		LG.setColor(color)
		LG.setLineWidth(2)
		LG.line(points)
		LG.setLineWidth(1)
	end

	function skin.graphfield(object)
		local x, y = object:GetPos()
		local w, h = object:GetSize()

		-- Draw workspace background using dark theme border palette
		LG.setColor(pal.theme_dark)
		LG.rectangle("fill", x, y, w, h)

		-- Minor grid lines (spacing = 20)
		local grid = 20
		local ox = object.scrollx % grid
		local oy = object.scrolly % grid
		LG.setColor(pal.theme[1], pal.theme[2], pal.theme[3], 0.3)
		for gx = x + ox, x + w, grid do
			LG.line(gx, y, gx, y + h)
		end
		for gy = y + oy, y + h, grid do
			LG.line(x, gy, x + w, gy)
		end

		-- Major grid lines (spacing = 100)
		local major = 100
		local mx_offset = object.scrollx % major
		local my_offset = object.scrolly % major
		LG.setColor(pal.theme[1], pal.theme[2], pal.theme[3], 0.6)
		for gx = x + mx_offset, x + w, major do
			LG.line(gx, y, gx, y + h)
		end
		for gy = y + my_offset, y + h, major do
			LG.line(x, gy, x + w, gy)
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
		LG.setColor(pal.theme_light)
		LG.rectangle("fill", x, y, w, h, 4, 4)

		-- Header title bar
		LG.setColor(pal.theme)
		LG.rectangle("fill", x, y, w, object.header_height, 4, 4)
		-- Sharp rect overlay to cover bottom rounded corners of the header
		LG.rectangle("fill", x, y + object.header_height - 4, w, 4)

		-- Draw title text
		LG.setFont(skin.controls.titlefont)
		LG.setColor(pal.text)
		skin.PrintText(object.name, x + 8, y + (object.header_height - 12) / 2)

		-- Highlight border when hovered/dragged
		if object.hover or object.dragging then
			LG.setColor(pal.contrast_light)
		else
			LG.setColor(pal.border)
		end
		LG.rectangle("line", x, y, w, h, 4, 4)
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
			LG.setColor(object.color[1], object.color[2], object.color[3], 0.3)
			LG.circle("fill", cx, cy, r + 4)
		end

		-- Check if connected
		local connected = false
		local gf = object:GetGraphField()
		if gf then
			connected = gf:IsSocketConnected(object)
		end

		LG.setColor(object.color)
		if connected then
			LG.circle("fill", cx, cy, r)
		else
			LG.circle("line", cx, cy, r)
			-- smaller dot inside
			LG.circle("fill", cx, cy, r - 3)
		end

		-- Draw socket name text next to it
		LG.setFont(font)
		LG.setColor(pal.text)
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


		local hovercolor       = skin.controls.radialmenu_hover_color
		local nohovercolor     = skin.controls.radialmenu_nohover_color
		local textnohovercolor = skin.controls.radialmenu_text_nohover_color
		local texthovercolor   = skin.controls.radialmenu_text_hover_color


		local slice = (math.pi * 2) / num_options
		local font = skin.controls.smallfont
		local gap = 0.05 -- gap angle

		-- 1. Draw slices (masked by stencil to form a donut)
		LG.setStencilState("replace", "always", 1)
		LG.setColorMask(false, false, false, false)
		LG.circle("fill", cx, cy, object.radius_inner)

		LG.setStencilState("keep", "notequal", 1)
		LG.setColorMask(true, true, true, true)

		for i = 1, num_options do
			local start_angle = (i - 1.5) * slice + gap / 2
			local end_angle = start_angle + slice - gap

			local current_radius = object.radius_outer
			if object.hovered_option == i then
				-- hovered slices pop out slightly and are solid
				LG.setColor(hovercolor[1], hovercolor[2], hovercolor[3], hovercolor[4] * 0.8)
				current_radius = current_radius + 6
			else
				-- Normal slices are slightly translucent
				LG.setColor(nohovercolor[1], nohovercolor[2], nohovercolor[3], nohovercolor[4] * 0.8)
			end

			-- Draw slice
			LG.arc("fill", "pie", cx, cy, current_radius, start_angle, end_angle)
		end

		LG.setStencilMode("off") -- Reset stencil so text can safely overflow if needed

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
			LG.setFont(font)
			if object.hovered_option == i then
				LG.setColor(texthovercolor)
			else
				LG.setColor(textnohovercolor)
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
			LG.setColor(pal.theme[1], pal.theme[2], pal.theme[3], alpha)

			LG.circle("fill", dx, dy, radius * 0.15 + (alpha * radius * 0.1))
		end

		LG.pop()
	end

	function skin.navigable(object)
		local x, y = object:GetPos()
		local width, height = object:GetSize()
		local halfH = (height - cursorpoint2x[1]:getHeight()) / 2
		local img_width = cursorpoint2x[1]:getWidth()
		local mod = 2 + floor(love.timer.getTime() * 10) % 6
		LG.draw(cursorpoint2x[mod], x - img_width, y + halfH, 0, 1, 1)
	end

	-- register the skin
	loveframes.RegisterSkin(skin)

	---------- module end ----------
end
