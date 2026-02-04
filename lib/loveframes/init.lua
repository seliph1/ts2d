--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

local path = ...

local loveframes = {}

-- special require for loveframes specific modules
loveframes.require = function(name)
	local ret = require(name)
	if type(ret) == 'function' then return ret(loveframes) end
	return ret
end

-- loveframes specific modules
loveframes.require(path .. ".libraries.utils")
loveframes.require(path .. ".libraries.templates")
loveframes.require(path .. ".libraries.objects")
loveframes.require(path .. ".libraries.skins")
loveframes.require(path .. ".libraries.bind")

-- generic libraries
loveframes.class = require(path .. ".third-party.middleclass")
loveframes.utf8 = require(path .. ".third-party.utf8"):init()
loveframes.input = require(path .. ".third-party.input")
loveframes.sysl = require(path .. ".third-party.sysl")
loveframes.bump = require(path .. ".third-party.bump")

-- library info
loveframes.author = "Kenny Shields"
loveframes.version = "11.3"
loveframes.stage = "Alpha"

-- library configurations
loveframes.config = {}
loveframes.config["DIRECTORY"] = nil
loveframes.config["DEFAULTSKIN"] = "CS2D"
loveframes.config["ACTIVESKIN"] = "CS2D"
loveframes.config["INDEXSKINIMAGES"] = true
loveframes.config["DEBUG"] = false
loveframes.config["ENABLE_SYSTEM_CURSORS"] = false

-- misc library vars
loveframes.state = "none"
loveframes.drawcount = 0
loveframes.collisioncount = 0
loveframes.objectcount = 0
loveframes.collisions = nil
-- Anchors
loveframes.modalobject = false
loveframes.inputobject = false
loveframes.downobject = false
loveframes.hoverobject = false
loveframes.draggingobject = false
loveframes.anchor_x = 0
loveframes.anchor_y = 0
loveframes.drag_width = 0
loveframes.drag_height = 0
loveframes.drag_x = 0
loveframes.drag_y = 0
-- Fonts
loveframes.opacity = 1
loveframes.drawtoggle = true
loveframes.basicfont = love.graphics.newFont(12)
loveframes.basicfontsmall = love.graphics.newFont(10)
-- Cursors
loveframes.cursors = {
	ibeam = love.mouse.getSystemCursor("ibeam"),
	arrow = love.mouse.getSystemCursor("arrow"),
	wait = love.mouse.getSystemCursor("wait"),
	waitarrow = love.mouse.getSystemCursor("waitarrow"),
	crosshair = love.mouse.getSystemCursor("crosshair"),
	hand = love.mouse.getSystemCursor("hand"),
	sizewe = love.mouse.getSystemCursor("sizewe"),
	sizens = love.mouse.getSystemCursor("sizens"),
	sizenesw = love.mouse.getSystemCursor("sizenesw"),
	sizenwse = love.mouse.getSystemCursor("sizenwse"),
	sizeall = love.mouse.getSystemCursor("sizeall"),
	no = love.mouse.getSystemCursor("no"),
}

-- install directory of the library
local dir = loveframes.config["DIRECTORY"] or path

-- replace all "." with "/" in the directory setting
dir = loveframes.utf8.gsub(loveframes.utf8.gsub(dir, "\\", "/"), "(%a)%.(%a)", "%1/%2")
loveframes.config["DIRECTORY"] = dir

-- enable key repeat
love.keyboard.setKeyRepeat(true)

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates all library objects
--]]---------------------------------------------------------
function loveframes.update(dt)
	local base = loveframes.base

	loveframes.collisioncount = 0
	loveframes.objectcount = 0
	loveframes.hoverobject = false

	local downobject = loveframes.downobject
	if loveframes.collisions then
		local top = loveframes.collisions
		if not downobject then
			loveframes.hoverobject = top
		else
			if downobject == top then
				loveframes.hoverobject = top
			end
		end
	end

	if loveframes.config["ENABLE_SYSTEM_CURSORS"] then
		local hoverobject = loveframes.GetHoverObject()
		local draggingobject = loveframes.GetDraggingObject()
		local current = love.mouse.getCursor()
		local cursors = loveframes.cursors

		if draggingobject then
			if current ~= draggingobject.cursor then
				love.mouse.setCursor(draggingobject.cursor)
			end
		elseif hoverobject then
			if current ~= hoverobject.cursor then
				love.mouse.setCursor(hoverobject.cursor)
			end
		else
			if current ~= cursors.arrow then
				love.mouse.setCursor(cursors.arrow)
			end
		end
	end

	local hoverobject = loveframes.GetHoverObject()
	if hoverobject then
		if loveframes.config["DEBUG"] and love.keyboard.isDown("delete") then
			hoverobject:Remove()
		end
	end

	loveframes.collisions = nil
	base:update(dt)
end

--[[---------------------------------------------------------
	- func: draw()
	- desc: draws all library objects
--]]---------------------------------------------------------
function loveframes.draw()
	-- Store previous graphic settings
	local base = loveframes.base
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()

	-- Start the draw counter fot debug window
	loveframes.drawcount = 0
	--// ---------------------------------//--
	base:draw() -- D R A W 
	--//----------------------------------//--

	-- Tooltip ( should be drawn above other objects)
	local hoverobject = loveframes.GetHoverObject()
	if hoverobject and hoverobject.tooltip then
		local skin = hoverobject:GetSkin()
		skin.tooltip(hoverobject)
	end

	-- Debug draw
	if loveframes.config["DEBUG"] then
		loveframes.DebugDraw()
	end

	-- Reset the graphic pipeline
	love.graphics.setColor(r, g, b, a)
	love.graphics.setScissor()
	love.graphics.reset()

	-- Reset font
	if font then
		love.graphics.setFont(font)
	end
end


--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]]---------------------------------------------------------
function loveframes.mousemoved(x, y, dx, dy, istouch)
	local base = loveframes.base
	base:mousemoved(x, y, dx, dy, istouch)

	local ctrl
	if loveframes.config["DEBUG"] then
		if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
			ctrl = true
		end
	end
	local draggingobject = loveframes.draggingobject
	if draggingobject and ctrl then
		draggingobject:Drag()
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function loveframes.mousepressed(x, y, button, istouch, presses)
	local hoverobject = loveframes.GetHoverObject()
	if hoverobject and button == 1 then
		loveframes.draggingobject = hoverobject
		loveframes.anchor_x = x - hoverobject.x
		loveframes.anchor_y = y - hoverobject.y
		loveframes.drag_x = hoverobject.x
		loveframes.drag_y = hoverobject.y
		loveframes.drag_width = hoverobject.width
		loveframes.drag_height = hoverobject.height
	end

	local base = loveframes.base
	base:mousepressed(x, y, button, istouch, presses)

	if loveframes.inputobject then
		if loveframes.inputobject ~= loveframes.hoverobject then
			loveframes.inputobject = false
		end
	end

	if button ~= 1 then
		loveframes.AnchorReset()
	end
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function loveframes.mousereleased(x, y, button, istouch, presses)
	-- reset the hover object
	if button == 1 then
		loveframes.AnchorReset()
	end

	local base = loveframes.base
	base:mousereleased(x, y, button, istouch, presses)
end

--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function loveframes.wheelmoved(x, y)
	local base = loveframes.base
	base:wheelmoved(x, y)
end

--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat)
	- desc: called when the player presses a key
--]]---------------------------------------------------------
function loveframes.keypressed(key, isrepeat)
	local base = loveframes.base
	base:keypressed(key, isrepeat)

	-- Run keys if we aren't stuck in an input
	if not loveframes.inputobject then
		local keyhandler = loveframes.keyhandlers[loveframes.getModKeys()][key]
		if keyhandler then
			return keyhandler(key, isrepeat)
		else
			return false, false
		end
	end
end

--[[---------------------------------------------------------
	- func: keyreleased(key)
	- desc: called when the player releases a key
--]]---------------------------------------------------------
function loveframes.keyreleased(key)
	local base = loveframes.base
	base:keyreleased(key)
end

--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the user inputs text
--]]---------------------------------------------------------
function loveframes.textinput(text)
	local base = loveframes.base
	base:textinput(text)
end

loveframes.LoadObjects(dir .. "/objects")
loveframes.LoadTemplates(dir .. "/templates")
loveframes.LoadSkins(dir .. "/skins")

-- create the base gui object
local base = loveframes.objects["base"]
loveframes.base = base:new()

return loveframes
