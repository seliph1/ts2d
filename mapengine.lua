-- Mount a file system here
--[[
require "lib.lovefs.lovefs"
local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory() )
else
	fs:cd(love.filesystem.getSource() )
end
]]

-- Loading some libs
local ffi = require "ffi"
--local List = require "lib.list"
local bump = require "lib.bump"
local shader = require "core.shaders.cs2dshaders"
local effect = require "effect"
local enum = require "enum"
local LF = love.filesystem

-- Localise some important functions to constantly call during execution
local max = math.max
local min = math.min
local sqrt = math.sqrt
local atan2 = math.atan2
local random = math.random
local floor = math.floor
local ceil = math.ceil
local cos = math.cos
local sin = math.sin
local abs = math.abs
local rad = math.rad

-- Default config tables for tiles/tilesets/maps
local DEFAULT_PROPERTY = 0
local DEFAULT_MOD = enum.DEFAULT_MOD
local TILE_PROPERTY = enum.TILE_PROPERTY
local TILE_BLEND_DIR = enum.TILE_BLEND_DIR
local TILE_MODE_HEIGHT = enum.TILE_MODE_HEIGHT
local ENTITY_TYPE = enum.ENTITY_TYPE

effect.register(LF.load "core/particle/sparkle.lua" (), "sparkle")
effect.register(LF.load "core/particle/hitscan.lua" (), "hitscan")
effect.register(LF.load "core/particle/bullettrail.lua" (), "bullettrail")

--effect.register(dofile "core/particle/fire.lua", "fire")
--effect.register(dofile "core/particle/snow.lua", "snow")
--effect.register(dofile "cor'e/particle/rain.lua", "rain")
--[[---------------------------------------------------------
	Lib
--]]---------------------------------------------------------
--- Creates a spritesheet out of a file, in equal rectangles
--- containing all subsections  of the file as a ImageData object
--- @param file string
--- @param xsize number
--- @param ysize number
--- @return table spritesheet_table table containing all ImageData
local function create_spritesheet(file, xsize, ysize)
	--local spritesheet = fs:loadImageData(file)
	local spritesheet = love.image.newImageData(file)
	local spritesheet_table = {}
	local w, h = spritesheet:getDimensions()
	local id = 0
	for y = 0, floor(h/xsize)-1 do
	for x = 0, floor(w/ysize)-1 do
		local sprite = love.image.newImageData(xsize, ysize)
		sprite:paste(spritesheet,0,0,x*xsize,y*ysize,xsize,ysize)
		spritesheet_table[id] = love.graphics.newImage(sprite)
		id = id + 1
	end
	end
	return spritesheet_table
end

local function entityInCamera(e, camx, camy)
	--local path 		= e.string_settings[1]
	local size_x 	= e.number_settings[1]
	local size_y 	= e.number_settings[2]
	local shift_x 	= e.number_settings[3]
	local shift_y 	= e.number_settings[4]
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()
	local x1, y1 = e.x*32 - camx + sw/2 + shift_x, e.y*32 - camy + sh/2 + shift_y
	local x1size, y1size = size_x, size_y
	local x2, y2 = 0, 0
	local x2size, y2size = sw, sh
	if x1 <= x2 + x2size and x1 + x1size >= x2 
	and y1 <= y2 + y2size and y1 + y1size >= y2 
	then
		return true
	else
		return false
	end
end

local function entityPosInScreen(e, camx, camy)
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()
	local x1, y1 = e.x*32 - camx + sw/2, e.y*32 - camy + sh/2
	local x1size, y1size = 32, 32
	local x2, y2 = 0, 0
	local x2size, y2size = sw, sh

	if x1 <= x2 + x2size and x1 + x1size >= x2 
	and y1 <= y2 + y2size and y1 + y1size >= y2 
	then
		return true
	else
		return false
	end
end

local function sort_by_depth(a,b)
	return a.depth < b.depth
end

local function clamp(x, minVal, maxVal)
    if x < minVal then return minVal end
    if x > maxVal then return maxVal end
    return x
end

--[[---------------------------------------------------------
	MapObject 
--]]---------------------------------------------------------
--- The object that creates, manages and draw
--- all map related operations in our game
local MapObject = {
	---@method draw test
	new = function(width, height)
	end,
	spritesheet = create_spritesheet,
}

MapObject.__index = MapObject
MapObject.__tostring = function(self)
	local mapdata = self._mapdata
	return string.format("map: %s (author: %s [#%s])", mapdata.name, mapdata.author, mapdata.usgn)
end

--- Creates a new MapObject handler
---@param width number? map width
---@param height number? map height
---@return table MapObject
function MapObject.new(width, height)
	width = width or 50
	height = height or 50
	local object = {
		_updateRequest = true;
		_breath = 0;
		_oscillation = 0;
		_item_field = {};
		_world = bump.newWorld();

		_camera = {
			x = 0,
			y = 0,
			width = 0,
			height = 0,
			chunk_x = 0,
			chunk_y = 0,
			tile_x = 0,
			tile_y = 0,
		};
		_render = {
			x = 0,
			y = 0,
			width = 16,
			height = 16,
		};

	}

	object._placeholder = love.image.newImageData(32, 32)
	object._placeholder_img = love.graphics.newImage(object._placeholder)
	object._flare = love.graphics.newImage("gfx/sprites/flare2.bmp") --fs:loadImage("gfx/sprites/flare2.bmp")
	object._blendmap = create_spritesheet("gfx/blendmap.bmp", 32, 32)
	object._hudicon = create_spritesheet("gfx/gui_icons.bmp", 16, 16)
	object._smallfont = love.graphics.newFont("gfx/fonts/liberationsans.ttf", 10)
	object._normalfont = love.graphics.newFont("gfx/fonts/liberationsans.ttf", 16)

	local mapdata = {
		name = "untitled";
		header = "Unreal Software's Counter-Strike 2D Map File (max)";
		scroll = 0;
		modifiers = 0;
		uptime = 0;
		usgn = 0;
		author = "mapengine.lua";
		tileset = "cs2dnorm.bmp";
		tile_count = 255;
		width = width-1 or 24;
		height = height-1 or 24;
		write_time = "000000";
		background_file = "";
		background_scroll_speed_x = 0;
		background_scroll_speed_y = 0;
		background_color_red = 0;
		background_color_green = 0;
		background_color_blue = 0;
		save_tile_heights = 0;
		pixel_tiles_hd = 0;
		tile_size = 32;
		daylight = 0;
		version = "CS2D v1.0.1.4";
		tile = {};
		map = {};
		map_mod = {};
		--shadow_mask = love.image.newImageData(width+1, height+1);
		entity_count = 0;
		entity_table = {};
		gfx = {
			tile = {};
			entity = {};
			background = {};
			quad = {};
		};
	}
	for i = -1, mapdata.tile_count do
		mapdata.tile[i] = {
			height = 0,
			modifier = 0,
			property = 0,
		}
	end
	for x = 0, mapdata.width do
	for y = 0, mapdata.height do
		local id = 0
		mapdata.map[x] = mapdata.map[x] or {}
		mapdata.map[x][y] = id
		--mapdata.shadow_mask:setPixel(x, y, 0.0, 0.0, 0.0)
		mapdata.map_mod[x] = mapdata.map_mod[x] or {}
		mapdata.map_mod[x][y] = {
			object_type = "tile",
			brightness = 100,
			rotation = 0,
			color = {
				red = 255,
				blue = 255,
				green = 255,
			},
			modifier = 0,
			blending = 0,
			id = 0,
			height = 0,
			property = 0,
			depth = 0,
		}

		--object._world:add( mapdata.map_mod[x][y], x*32, y*32, 32, 32 )
	end
	end
	--mapdata.shadow_render = love.graphics.newImage(mapdata.shadow_mask)
	--mapdata.shadow_render:setFilter("nearest", "nearest")
	local tileset_atlas = love.image.newImageData("gfx/tiles/"..mapdata.tileset)--fs:loadImageData("gfx/tiles/"..mapdata.tileset)
	local w, h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	tileset_atlas:mapPixel(function(x, y, r, g, b, a)
		-- Verifica se é magenta (255,0,255)
		-- Normalmente os valores de cor vêm como floats 0..1
		if r == 1 and g == 0 and b == 1 then
			return 1, 0, 1, 0 -- deixa transparente (alpha=0)
		else
			return r, g, b, a
		end
	end)
	local tileset_spritesheet = love.graphics.newImage(tileset_atlas)-- Remove magenta pixels

	tileset_spritesheet:setFilter("nearest", "linear")
	mapdata.gfx.ground = love.graphics.newSpriteBatch(tileset_spritesheet, mapdata.width * mapdata.height)
	mapdata.gfx.wall = love.graphics.newSpriteBatch(tileset_spritesheet, mapdata.width * mapdata.height)
	for y = 0, floor(h/s)-1 do
	for x = 0, floor(w/s)-1 do
		local sprite = love.image.newImageData(s, s)
		sprite:paste(tileset_atlas, 0, 0, x*s, y*s, s, s)
		mapdata.gfx.tile[tile_id] = love.graphics.newImage(sprite)
		mapdata.gfx.quad[tile_id] = love.graphics.newQuad(x*s, y*s, s, s, w, h)
		tile_id = tile_id + 1
	end
	end
	-- Entity load (This is actually a new map so no need to walk through a list )
	-- Background load.(This is actually a new map so no need to walk through a list )
	mapdata.gfx.background = love.graphics.newImage(object._placeholder)
	object._mapdata = mapdata
	return setmetatable(object, MapObject)
end

--- @method Clears the map
function MapObject:clear()
	self._updateRequest = true;
	self._breath = 0;
	self._oscillation = 0;
	self._item_field = {};
	self._world = bump.newWorld();

	self._camera = {
			x = 0,
			y = 0,
			width = 0,
			height = 0,
			chunk_x = 0,
			chunk_y = 0,
			tile_x = 0,
			tile_y = 0,
		};
	self._render = {
			x = 0,
			y = 0,
			width = 16,
			height = 16,
	};

	local mapdata = {
		name = "untitled";
		header = "Unreal Software's Counter-Strike 2D Map File (max)";
		scroll = 0;
		modifiers = 0;
		uptime = 0;
		usgn = 0;
		author = "mapengine.lua";
		tileset = "cs2dnorm.bmp";
		tile_count = 255;
		width = 49;
		height = 49;
		write_time = "000000";
		background_file = "";
		background_scroll_speed_x = 0;
		background_scroll_speed_y = 0;
		background_color_red = 0;
		background_color_green = 0;
		background_color_blue = 0;
		save_tile_heights = 0;
		pixel_tiles_hd = 0;
		tile_size = 32;
		daylight = 0;
		version = "CS2D v1.0.1.4";
		tile = {};
		map = {};
		map_mod = {};
		--shadow_mask = love.image.newImageData(width+1, height+1);
		entity_count = 0;
		entity_table = {};
		gfx = {
			tile = {};
			entity = {};
			background = {};
			quad = {};
		};
	}
	for i = -1, mapdata.tile_count do
		mapdata.tile[i] = {
			height = 0,
			modifier = 0,
			property = 0,
		}
	end
	for x = 0, mapdata.width do
	for y = 0, mapdata.height do
		local id = 0
		mapdata.map[x] = mapdata.map[x] or {}
		mapdata.map[x][y] = id
		--mapdata.shadow_mask:setPixel(x, y, 0.0, 0.0, 0.0)
		mapdata.map_mod[x] = mapdata.map_mod[x] or {}
		mapdata.map_mod[x][y] = {
			object_type = "tile",
			brightness = 100,
			rotation = 0,
			color = {
				red = 255,
				blue = 255,
				green = 255,
			},
			modifier = 0,
			blending = 0,
			id = 0,
			height = 0,
			property = 0,
			depth = 0,
		}

		--object._world:add( mapdata.map_mod[x][y], x*32, y*32, 32, 32 )
	end
	end
	--mapdata.shadow_render = love.graphics.newImage(mapdata.shadow_mask)
	--mapdata.shadow_render:setFilter("nearest", "nearest")
	local tileset_atlas = love.image.newImageData("gfx/tiles/"..mapdata.tileset)--fs:loadImageData("gfx/tiles/"..mapdata.tileset)
	local w, h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	tileset_atlas:mapPixel(function(x, y, r, g, b, a)
		-- Verifica se é magenta (255,0,255)
		-- Normalmente os valores de cor vêm como floats 0..1
		if r == 1 and g == 0 and b == 1 then
			return 1, 0, 1, 0 -- deixa transparente (alpha=0)
		else
			return r, g, b, a
		end
	end)
	local tileset_spritesheet = love.graphics.newImage(tileset_atlas)-- Remove magenta pixels
	tileset_spritesheet:setFilter("nearest", "linear")
	mapdata.gfx.ground = love.graphics.newSpriteBatch(tileset_spritesheet, mapdata.width * mapdata.height)
	mapdata.gfx.wall = love.graphics.newSpriteBatch(tileset_spritesheet, mapdata.width * mapdata.height)
	for y = 0, floor(h/s)-1 do
	for x = 0, floor(w/s)-1 do
		local sprite = love.image.newImageData(s, s)
		sprite:paste(tileset_atlas, 0, 0, x*s, y*s, s, s)
		mapdata.gfx.tile[tile_id] = love.graphics.newImage(sprite)
		mapdata.gfx.quad[tile_id] = love.graphics.newQuad(x*s, y*s, s, s, w, h)
		tile_id = tile_id + 1
	end
	end
	-- Entity load (This is actually a new map so no need to walk through a list )
	-- Background load.(This is actually a new map so no need to walk through a list )
	mapdata.gfx.background = love.graphics.newImage(self._placeholder)
	self._mapdata = mapdata
	self:shiftRender()

	collectgarbage("collect")

	print("Map: cleared")
end

--- @method Reads from a CS2D Map file
--- @param path string file relative to maps/ path in CS2D
function MapObject:read(path, noindexing)
	--local filedata = love.filesystem.newFileData(path)
	if not love.filesystem.getInfo(path) then --if not fs:isFile(path) then
		return string.format("File %q does not exist. Check your files/folders and try again!", path)
	end
	--local filedata = fs:loadFile(path)
	local filedata = love.filesystem.newFileData(path)
	-- Get a C pointer to read files as binary mode.
	local size = filedata:getSize()
	local pointer = filedata:getFFIPointer()
	-- Set byte and integer tables to read.
	local bytearray = ffi.cast('uint8_t*',pointer)
	local integerarray = ffi.cast('int32_t*',pointer)
	local shortarray = ffi.cast('uint16_t*',pointer)
	-- Set the cursor at the start of file
	local cursor = 0
	-- Read single byte
	local function read_byte()
		local value = bytearray[cursor]
		cursor = cursor+1
		return value
	end
	-- Reading functions
	local function read_integer()
		local b1, b2, b3, b4 = bytearray[cursor],bytearray[cursor+1],bytearray[cursor+2],bytearray[cursor+3]
		-- Read integer as signed non endian
		local value =  b4 * 0x1000000 + b3 * 0x10000 + b2 * 0x100 + b1
		cursor = cursor + 4
		return value > 0x7fffffff and value - 0x100000000 or value
	end
	-- Read string until \n
	local function read_string()
		local str = ""
		local i = 0
		for index = 0,size-cursor do
			local chr = string.char(bytearray[cursor+index])
			if bytearray[cursor+index]==10 then
				cursor = cursor + index+1
				return str
			end
			if bytearray[cursor+index]~=13 then
				str = str .. chr
			end
		end
	end
	-- Read short integer as unsigned endian.
	local function read_short()
		local value = shortarray[math.floor(cursor/2)]
		cursor = cursor+2
		return value
	end
	-- Jumps the cursor
	local function seek_forward(bytes)
		cursor = cursor + bytes
	end
	-----------------------------------------------------------------------------------------------------------
	-- HEADER (1)
	-----------------------------------------------------------------------------------------------------------
	-- header first check
	-----------------------------------------------------------------------------------------------------------
	local header_check_a = read_string() -- Header check 
	print("Map: Header check 1: \""..header_check_a.."\"")
	if not (
		string.find(header_check_a, "Unreal Software's Counter-Strike 2D Map File",1,true) or
		string.find(header_check_a, "Unreal Software's CS2D Map File",1,true) 
	) then
		error("\n\nMap header first check failed. \nCheck if your file is corrupted.\nResult string: \""..header_check_a.."\"")
	end
	-- skeleton
	-----------------------------------------------------------------------------------------------------------
	local mapdata = {
		gfx = {
			tile = {};
			entity = {};
			background = {};
			quad = {};
			--ground = love.graphics.newSpriteBatch(self._placeholder);
			--wall = love.graphics.newSpriteBatch(self._placeholder);
		};
	}

	self._world = bump.newWorld()
	-- byte header data
	-----------------------------------------------------------------------------------------------------------
	mapdata.name = string.match(path, "(.+).map")
	mapdata.scroll = read_byte() 				-- Map scroll property
	mapdata.modifiers = read_byte()				-- Modifiers
	mapdata.save_tile_heights = read_byte()		-- Tile height property
	mapdata.pixel_tiles_hd = read_byte()		-- Tile pixel size
	mapdata.tile_size = mapdata.pixel_tiles_hd == 1 and 64 or 32
	seek_forward(6)
	-- integer header data
	-----------------------------------------------------------------------------------------------------------	-- Six empty slots
	mapdata.uptime = read_integer()				-- Time map were made
	mapdata.usgn = read_integer()-51			-- Author USGN
	mapdata.daylight = read_integer()			-- Daylight value
	seek_forward(7*4)
	-- string header data
	-----------------------------------------------------------------------------------------------------------	-- 7*4 empty spaces
	mapdata.author = read_string()				-- Author name
	mapdata.version = read_string()				-- Map version
	seek_forward(8*2)
	-- more map settings
	-----------------------------------------------------------------------------------------------------------
	mapdata.write_time = read_string()			-- Map date
	mapdata.tileset = read_string()				-- Tileset name string
	mapdata.tile_count = read_byte()			-- How many tiles is in the map
	mapdata.tile={}
	for i = -1, mapdata.tile_count do
		mapdata.tile[i] = {
			height = 0,
			modifier = 0,
			property = 0,
		}
	end	
	mapdata.width = read_integer()						-- Map x size
	mapdata.height = read_integer()						-- Map y size
	mapdata.background_file = read_string()
	mapdata.background_scroll_speed_x = read_integer()
	mapdata.background_scroll_speed_y = read_integer()
	mapdata.background_color_red = read_byte()
	mapdata.background_color_green = read_byte()
	mapdata.background_color_blue = read_byte()
	-- header second check
	-----------------------------------------------------------------------------------------------------------
	local header_check_b = read_string()
	if header_check_b ~= "ed.erawtfoslaernu" then
		--file:close()
		error("Map header second check failed. Check if your file is corrupted.")
	end
	-----------------------------------------------------------------------------------------------------------
	-- TILE MODES (2)
	-----------------------------------------------------------------------------------------------------------
	for i = 0, mapdata.tile_count do
		mapdata.tile[i].property = read_byte()
	end
	-----------------------------------------------------------------------------------------------------------
	-- TILE HEIGHTS (3)
	-----------------------------------------------------------------------------------------------------------
	if mapdata.save_tile_heights > 0 then
		for i = 0, mapdata.tile_count do
			if mapdata.save_tile_heights == 1 then -- CS2D 1.0.0.3 prerelease
				mapdata.tile[i].height = read_integer()
			elseif mapdata.save_tile_heights == 2 then-- CS2D 1.0.0.3 and above
				mapdata.tile[i].height = read_short()
				mapdata.tile[i].modifier = read_byte()
			end
		end
	else
		for i = 0, mapdata.tile_count do
			if mapdata.tile[i].property == 0 then
				mapdata.tile[i].height = 0
			elseif mapdata.tile[i].property == 1 or mapdata.tile[i].property == 3 then
				mapdata.tile[i].height = 32
			elseif mapdata.tile[i].property == 2 or mapdata.tile[i].property == 4 then
				mapdata.tile[i].height = 16
			elseif mapdata.tile[i].property >= 10 then
				mapdata.tile[i].height = 0
			end
			mapdata.tile[i].modifier = 0
		end
	end
	-----------------------------------------------------------------------------------------------------------
	-- MAP (4)
	-----------------------------------------------------------------------------------------------------------
	mapdata.map = {}
	--mapdata.shadow_mask = love.image.newImageData(mapdata.width+1, mapdata.height+1)
	for x = 0, mapdata.width do
	for y = 0, mapdata.height do
		local id = read_byte()
		mapdata.map[x] = mapdata.map[x] or {}
		mapdata.map[x][y] = id
		local property = mapdata.tile[id].property
		local height = TILE_MODE_HEIGHT[property]
		--mapdata.shadow_mask:setPixel(x, y, height, height, height)
	end
	end
	--mapdata.shadow_render = love.graphics.newImage(mapdata.shadow_mask)
	--mapdata.shadow_render:setFilter("nearest", "nearest")
	----------------------------------------------------------------------------------------------
	-- Tile id mod table.
	mapdata.map_mod = {}
	if mapdata.modifiers == 1 then
		for x = 0, mapdata.width  do
		for y = 0, mapdata.height  do
			local modifier = read_byte()
			local rotation = modifier % 4
			local brightness = 100
			local blending = 0
			local color = {
				red = 255,
				green = 255,
				blue = 255,
				overlay = 0,
			}
			if modifier > 0 then -- At least something is modified.
				-- menor que 64 -- bits 00
				-- maior que 64 e menor que 128 -- bits 01
				-- maior que 128 e menor que 192 -- bits 10
				-- maior que 192 -- 11
				if modifier >= 192 then -- Some stuff that DC planned.
					read_string()
				elseif modifier >= 64 and modifier < 128 then -- Blending
					brightness = math.floor( ( modifier - 64 - rotation) * 2.5 )
					blending = read_byte() + 2
				elseif modifier >= 128 then -- Color + Blending
					brightness = math.floor( ( modifier - 128 - rotation) * 2.5 )
					color.red = read_byte()
					color.green = read_byte()
					color.blue = read_byte()
					color.overlay = read_byte()
				else
					brightness = (modifier - rotation) * 2.5
				end
			end
			if brightness == 0 then brightness = 100 end
			mapdata.map_mod[x] = mapdata.map_mod[x] or {}
			mapdata.map_mod[x][y] = {
				object_type = "tile",
				blending = blending,
				color = color,
				rotation = rotation,
				modifier = modifier,
				brightness = brightness,
				depth = 0,
			}

			--self._world:add( mapdata.map_mod[x][y], x*32, y*32, 32, 32 )
		end
		end
	else
		for x = 0, mapdata.width  do
		for y = 0, mapdata.height  do
			mapdata.map_mod[x] = mapdata.map_mod[x] or {}
			mapdata.map_mod[x][y] = {
				object_type="tile",
				brightness = 100,
				rotation = 0,
				color = {
					red = 255,
					blue = 255,
					green = 255,
				},
				modifier = 0,
				blending = 0,
				depth = 0,
			}
			--self._world:add( mapdata.map_mod[x][y], x*32, y*32, 32, 32 )
		end
		end
	end
	-----------------------------------------------------------------------------------------------------------
	-- ENTITIES (5)
	-----------------------------------------------------------------------------------------------------------
	mapdata.entity_count = read_integer()
	mapdata.entity_table = {}
	print("Map: Entity count: " .. mapdata.entity_count)
	for i = 1, mapdata.entity_count do
		local e = {}
		e.object_type = "entity"
		e.name = read_string()
		e.type = read_byte()
		e.x = read_integer()
		e.y = read_integer()
		e.trigger = read_string()
		e.string_settings = {}
		e.number_settings = {}
		e.index = i
		e.depth = e.index
		for j = 1, 10 do
			e.number_settings[j] = read_integer()
			e.string_settings[j] = read_string()
		end
		table.insert(mapdata.entity_table, e)

		-- Add it to bump world
		self._world:add(e, e.x*32, e.y*32, 32, 32)
	end

	if noindexing then
		self._mapdata = mapdata
		self:shiftRender()
		return
	end
	-----------------------------------------------------------------------------------------------------------
	-- GFX/SFX INDEXING (6)
	-----------------------------------------------------------------------------------------------------------
	-- Tileset load.
	local tileset_path = string.format("gfx/tiles/%s", mapdata.tileset)
	--local tileset_raw = fs:loadImage(path)
	--local tileset_atlas = fs:loadImageData(tileset_path)
	local tileset_atlas = love.image.newImageData(tileset_path)
	local w, h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	tileset_atlas:mapPixel(function(x, y, r, g, b, a)
		-- Verifica se é magenta (255,0,255)
		-- Normalmente os valores de cor vêm como floats 0..1
		if r == 1 and g == 0 and b == 1 then
			return 1, 0, 1, 0 -- deixa transparente (alpha=0)
		else
			return r, g, b, a
		end
	end)
	local tileset_spritesheet = love.graphics.newImage(tileset_atlas)-- Remove magenta pixels
	tileset_spritesheet:setFilter("nearest", "linear")
	mapdata.gfx.ground = love.graphics.newSpriteBatch(tileset_spritesheet, mapdata.width * mapdata.height)
	mapdata.gfx.wall = love.graphics.newSpriteBatch(tileset_spritesheet, mapdata.width * mapdata.height)
	for y = 0, floor(h/s)-1 do
	for x = 0, floor(w/s)-1 do
		local sprite = love.image.newImageData(s, s)
		sprite:paste(tileset_atlas,0,0,x*s, y*s, s, s)
		mapdata.gfx.tile[tile_id] = love.graphics.newImage(sprite)
		mapdata.gfx.quad[tile_id] = love.graphics.newQuad(x*s, y*s, s, s, w, h)
		tile_id = tile_id + 1
	end
	end

	-- Entity load
	for index, e in pairs(mapdata.entity_table) do
		if e.type == 22 then
			local sprite_path = (e.string_settings[1] or "gfx/cs2d.bmp")
			if not mapdata.gfx.entity[sprite_path] then -- Try to load a new image
				--if fs:isFile(sprite_path) then -- Check if file exists
				if love.filesystem.getInfo(sprite_path) then -- Check if file exists
					local sprite = love.graphics.newImage(sprite_path)
					mapdata.gfx.entity[sprite_path] = sprite
					print(string.format("Map: Sprite loaded: %s", sprite_path))
				else
					mapdata.gfx.entity[sprite_path] = love.graphics.newImage(self._placeholder)
					print(string.format("Map: Failed to load %s", sprite_path))
				end
			end
		end
	end
	-- Background load.
	local background_path = string.format("gfx/backgrounds/%s", mapdata.background_file)
	if (mapdata.background_file ~= "") and love.filesystem.getInfo(path) then --fs:isFile(background_path) then
		print(string.format("Map: Sprite loaded: %s", background_path))
		--mapdata.gfx.background = fs:loadImage(background_path)
		mapdata.gfx.background = love.graphics.newImage(background_path)
		mapdata.gfx.background:setWrap("repeat", "repeat")
	else
		mapdata.gfx.background = love.graphics.newImage(self._placeholder)
	end
	self._mapdata = mapdata
	self:shiftRender()
end

-- Methods
--[[
function MapObject:colorfill(x, y, replace)
	--local color = mapdata_gettile(x,y)
	if color == replace then return end
	local q = {}
	local t = self._mapfile.map
	
	
	table.insert(q, {x=x,y=y})
	for index, n in ipairs(q) do
		
		local w, e  = {},{}
		
		w.x, w.y = n.x, n.y
		e.x, e.y = n.x, n.y
		
		while t[w.x][w.y] == color and w.x > 0 do
			w.x = w.x - 1
		end
		
		while t[e.x][e.y] == color and e.x < mapfile.height do
			e.x = e.x + 1
		end

		for i = w.x+1, e.x-1 do
			mapdata_settile(i, n.y, replace)
			
			local north = math.min(n.y + 1, mapfile.height)
			local south = math.max(n.y - 1, 0)
			
			if t[i][south]==color then
				table.insert(q,{x = i, y = south})
			end
			
			if t[i][north]==color then
				table.insert(q,{x = i, y = north})
			end
		end		
	end
end
--]]
function MapObject:random()
	for x = 0, self._mapdata.width do
	for y = 0, self._mapdata.height do
		local r = math.random(0,255)
		self._mapdata.map[x] = self._mapdata.map[x] or {}
		self._mapdata.map[x][y] = r
		local property = self._mapdata.tile[r].property
		local height = TILE_MODE_HEIGHT[property]
		--mapfile.shadow_mask:setPixel(x, y, height, height, height)
	end
	end
	--mapdata_shadow_refresh()
end

function MapObject:settile(x, y, tile_id)
	if self._mapdata.map[x] and self._mapdata.map[x][y] then
		self._mapdata.map[x][y] = tile_id
	end
	local property = self._mapdata.tile[tile_id].property
	local height = TILE_MODE_HEIGHT[property]
	--self._mapdata.shadow_mask:setPixel(x, y, height, height, height)
	--mapdata_shadow_refresh()
end

function MapObject:gettile(x, y) -- coords in tiles
	if self._mapdata.map[x] and self._mapdata.map[x][y] then 
		return self._mapdata.map[x][y]
	else
		return 0
	end
end

function MapObject:tile(x, y) -- coords in tiles
	if self._mapdata.map[x] and self._mapdata.map[x][y] then
		local id = self._mapdata.map[x][y]
		local mod = self._mapdata.map_mod[x][y]
		local property =  self._mapdata.tile[id].property
		return id, mod, property
	else
		return -1, DEFAULT_MOD
	end
end

function MapObject:gfx(group, id)
	if self._mapdata.gfx[group] then
		if self._mapdata.gfx[group][id] then
			return self._mapdata.gfx[group][id]
		end
	end
	return nil
end

function MapObject:get(property)
	if self._mapdata[property] then
		return self._mapdata[property]
	end
end

---Check if a collision is happening between `object` that has x|y property and a map tile
---
---If `x` and `y` is not specified, it will calculate collision at its own camera position
---@param x number
---@param y number
---@return boolean
function MapObject:isColliding(x, y)
	local tx, ty = floor(x/32), floor(y/32)
	local id, mod, property = self:tile(tx, ty)

	if TILE_MODE_HEIGHT[property] and TILE_MODE_HEIGHT[property] >= 0.5 then
		return true
	end
	return false
end

function MapObject:scroll(x, y)
	x, y = floor(x), floor(y)
	local cx = floor(x / (32 * 8))
	local cy = floor(y / (32 * 8))
	if self._camera.chunk_x ~= cx or self._camera.chunk_y ~= cy then
		self:shiftRender()
	end
	self._camera.chunk_x = cx
	self._camera.chunk_y = cy
	self._camera.x = x
	self._camera.y = y
end

function MapObject:shiftRender()
	local mapdata = self._mapdata
	local gfx = mapdata.gfx
	local camera = self._camera
	local screen_w = 800
	local screen_h = 600
	local sw, sh = screen_w, screen_h
	local tile_size = mapdata.tile_size
	local off_x, off_y = floor(tile_size/2), floor(tile_size/2)
	local render_x = floor( (camera.x - sw ) / tile_size )
	local render_y = floor( (camera.y - sh ) / tile_size )
	local render_width = ceil( ( camera.x + sw ) / tile_size )
	local render_height = ceil( ( camera.y + sh ) / tile_size )
	self._render.x = render_x
	self._render.y = render_y
	self._render.width = render_width
	self._render.height = render_height

	gfx.ground:clear()
	gfx.wall:clear()
	for x = render_x, render_width do
	for y = render_y, render_height do
		local tile_id, mod, property = self:tile(x, y)
		local quad = gfx.quad[tile_id]
		local level = property == 1 and "wall" or "ground"
		if tile_id >= 0 then
			local brightness = (mod.brightness/100)

			mapdata.gfx[level]:setColor(
				love.math.colorFromBytes(
					mod.color.red * brightness,
					mod.color.green * brightness,
					mod.color.blue * brightness
				)
			)
			mapdata.gfx[level]:add(
				quad,
				x * tile_size + off_x,
				y * tile_size + off_y,
				rad(mod.rotation*90),
				1,
				1,
				off_x,
				off_y
			)
		end
	end
	end
end

function MapObject:update(dt)
	local time = love.timer.getTime()
	self._oscillation = (sin( time * math.pi * 2) + 1)/2


	effect.update(dt)
end

function MapObject:isOnScreen(x, y)
	local camera = self._camera
	local render = self._render

	if x > render.x
	and y > render.y
	and x < render.width
	and y < render.height
	then
		return true
	end
	return false
end

function MapObject:draw_background()
	local mapdata = self._mapdata
	if mapdata.background_file ~= "" then
		local background_w, background_h = mapdata.gfx.background:getDimensions()
		for i = 0, love.graphics.getWidth() / background_w do
		for j = 0, love.graphics.getHeight() / background_h do
			love.graphics.draw(mapdata.gfx.background, i * background_w, j * background_h)
		end
		end
	else
		love.graphics.setColor(
			mapdata.background_color_red/255,
			mapdata.background_color_green/255,
			mapdata.background_color_blue/255
		)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.setColor(1,1,1,1)
		--[[
		love.graphics.setBackgroundColor(
			mapdata.background_color_red/255,
			mapdata.background_color_green/255,
			mapdata.background_color_blue/255
		)
		]]
		--love.graphics.clear(
			--mapdata.background_color_red/255,
			--mapdata.background_color_green/255,
			--mapdata.background_color_blue/255
		--)
	end
end

function MapObject:draw_floor()
	local camera = self._camera
	local mapdata = self._mapdata
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Draw background
	self:draw_background()
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)
	-- Draw floor level
	love.graphics.draw(mapdata.gfx.ground)
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
end

function MapObject:draw_ceiling()
	local camera = self._camera
	local mapdata = self._mapdata
	local render = self._render
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local tile_size = mapdata.tile_size
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)
	-- Draw the wall layer
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(mapdata.gfx.wall)
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)

end

function MapObject:draw_effects()
	local camera = self._camera
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)
	-- Draw effect particles above everything!
	effect.draw()
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
end

function MapObject:draw_bullets(share, home, client)
	local camera = self._camera
	local render = self._render
	local bullets = share.bullets
	local cache = client.cache
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)
	-- Bullets
	for id, bullet in pairs(bullets) do
		local bullet_cache = cache.bullets[id]
		love.graphics.push()
		love.graphics.translate(bullet.x, bullet.y)
		--love.graphics.translate(bullet_cache.x, bullet_cache.y)
		love.graphics.rotate(math.atan2(bullet.dy, bullet.dx))
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.ellipse('fill', 0, 0, 24, 1)
		love.graphics.setColor(1, 1, 1, 0.38)
		love.graphics.setLineWidth(0.3) -- Outline
		love.graphics.ellipse('line', 0, 0, 24, 1)
		love.graphics.pop()
	end
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
end

function MapObject:draw_players(share, client) -- get info from server!
	local camera = self._camera
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Players in lerp
	local players = share.players
	-- Inputs
	local home = client.home

	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)

	for peer_id, player in pairs(players) do
		love.graphics.push()
		-- Direction
		local targetX, targetY = 0,0
		if peer_id == client.id then
			targetX, targetY = home.targetX, home.targetY
		else
			targetX, targetY = player.targetX, player.targetY
		end
		-- Calculate drawing angle
		local angle = math.atan2(targetY - client.height/2, targetX - client.width/2) + math.pi/2
		-- Get the player's held weapon
		local holding = player.ih
		-- Check if that weapon ID exists in available list
		local itemdata = client.content.itemlist[holding]
		-- Check what stance should player hold that weapon
		local stance = itemdata.player_stance
		-- Get the player texture for that stance
		local texture = client.gfx.player[player.p].texture
		local quad = client.gfx.player[player.p][stance]
		-- Get the weapon texture from weapon ID
		local weapon_gfx_path
		local weapon_texture
		if itemdata.held_image ~= "" then
			weapon_gfx_path = itemdata.common_path .. itemdata.held_image
			weapon_texture = client.gfx.itemlist[weapon_gfx_path]
			if not weapon_texture then
				weapon_texture = love.graphics.newImage(weapon_gfx_path)
				client.gfx.itemlist[weapon_gfx_path] = weapon_texture
			end
			if not weapon_texture then
				-- Defaults to a placeholder
				weapon_texture = self._placeholder
			end
		end

		if client.debug_level >= 2 and peer_id == client.id then
			local __player = client.share_local.players[client.id]
			love.graphics.push()
			love.graphics.translate(__player.x, __player.y)
			love.graphics.setColor(1, 0, 0, 0.2)
			love.graphics.draw(texture, quad, 0, 0, angle, 1, 1, 16, 16)
			love.graphics.pop()
		end
		-- Translate to player
		love.graphics.translate(player.x, player.y)

		if client.debug_level >= 2 then
			-- Set to blue color
			love.graphics.setColor(0, 0, 1, 1)
			-- Draw the hitbox
			love.graphics.rectangle("line", -player.size/2, -player.size/2, player.size, player.size)
		end
		-- Set to (1,1,1,1) color
		love.graphics.setColor(1, 1, 1, 1)
		-- Draw the player
		love.graphics.draw(texture, quad, 0, 0, angle, 1, 1, 16, 16)
		-- Draw weapon held
		if weapon_texture then
			local width = weapon_texture:getWidth()
			local height = weapon_texture:getHeight()
			love.graphics.draw(weapon_texture, 0, 0, angle, 1, 1, width/2, height)
		end
		-- Pop for the next player
		love.graphics.pop()
	end
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
end

function MapObject:draw_entity(e)
	local mapdata 	= self._mapdata
	local path 		= e.string_settings[1]
	local sprite 	= mapdata.gfx.entity[path]
	local width		= sprite:getWidth()
	local height 	= sprite:getHeight()
	local size_x 	= e.number_settings[1]
	local size_y 	= e.number_settings[2]
	local shift_x 	= e.number_settings[3]
	local shift_y 	= e.number_settings[4]
	local rotation 	= -e.number_settings[5]
	local red 		= e.number_settings[6]
	local green 	= e.number_settings[7]
	local blue 		= e.number_settings[8]
	local fx		= e.number_settings[9]
	local blend 	= e.number_settings[10]
	local alpha 	= ( tonumber( e.string_settings[2] ) or 1 ) * 255
	local mask 		= ( tonumber( e.string_settings[3] ) or 0 )
	local rotationspeed = ( tonumber( e.string_settings[4] ) or 0 )
	local angle = math.rad(rotation + rotationspeed * love.timer.getTime() * 90)
	local scale_x = size_x/width
	local scale_y = size_y/height
	local sx = (e.x * 32) + shift_x + size_x/2
	local sy = (e.y * 32) + shift_y + size_y/2
	love.graphics.setShader(shader.entity)
	if blend == 0 then -- No filter/solid
		love.graphics.setBlendMode("alpha")
	elseif blend == 3 then -- Light
		love.graphics.setBlendMode("screen", "premultiplied")
	elseif blend == 4 then -- Shade
		love.graphics.setBlendMode("multiply", "premultiplied")
	else
		love.graphics.setBlendMode("alpha")
	end
	shader.entity:send("mask", mask)
	shader.entity:send("blend", blend)

	love.graphics.setColor(love.math.colorFromBytes(red, green, blue, alpha))
	love.graphics.draw(sprite, sx, sy, angle, scale_x, scale_y, width/2, height/2)
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
end

function MapObject:draw_entities()
	local camera = self._camera
	local mapdata = self._mapdata
	local render = self._render
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Create new transformation stack
	love.graphics.push()
	-- Change camera perspective
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)

	local x, y, w, h = camera.x - 800, camera.y - 600, 800*2, 600*2
  	local entity, len = self._world:queryRect(x, y, w, h)
	table.sort(entity, sort_by_depth)
	for i = 1, len do
		local e = entity[i]
		if e.object_type =="entity" and e.type == 22 then
			self:draw_entity(e)
		end
	end
 	-- Change font of small entity sprites
	love.graphics.setFont(self._smallfont)
	-- Set blend mode
	love.graphics.setBlendMode("add")
	for i = 1, len do
		local e = entity[i]
		local t = ENTITY_TYPE[e.type] or ENTITY_TYPE["null"]
		local c = t.color
		love.graphics.setColor(c[1], c[2], c[3], 0.5 + self._oscillation/2)
		love.graphics.draw(self._hudicon[9], e.x*32+16, e.y*32+16, 0, 1, 1, 8, 8)
		love.graphics.printf(t.label or "", e.x*32+20, e.y*32+20, 48 ,"left")
	end
	love.graphics.setBlendMode("alpha")
	love.graphics.setFont(self._normalfont)
	-- Reset the transformation stack
	love.graphics.pop()
end

function MapObject:update_items(share, client)
	local camera = self._camera
	local mapdata = self._mapdata
	local items = share.items
	local gfx = client.gfx
	local itemlist = client.content.itemlist

	self._item_field = {}
	for _, item in pairs(items) do
		local cx = floor( item.x / 32)
		local cy = floor( item.y / 32)

		self._item_field[cx] = self._item_field[cx] or {}
		self._item_field[cx][cy] = self._item_field[cx][cy] or {}

		table.insert(self._item_field[cx][cy], item)
	end
	print("Map: item field updated")
end

function MapObject:getItemsFromCamera()
	local render = self._render

	local x1 = floor(render.x/32)
	local x2 = floor(render.width/32)
	local y1 = floor(render.y/32)
	local y2 = floor(render.height/32)

	local len = 0
	local dict = {}
	for x = x1, x2 do
	for y = y1, y2 do
		if self._item_field[x] and self._item_field[x][y] then
			dict[ self._item_field[x][y] ] = true
			len = len + 1
		end
	end
	end

	return dict, len
end

function MapObject:draw_items(share, client)
	local camera = self._camera
	local mapdata = self._mapdata
	local gfx = client.gfx
	local itemlist = client.content.itemlist
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local tile_size = mapdata.tile_size

	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)

	--[[
	for chunk in pairs(self:getItemsFromCamera()) do
		for index, item in pairs(chunk) do
			local itemdata = itemlist[item.it]
			local path = itemdata.common_path .. itemdata.dropped_image
			local imagedata = gfx.itemlist[path]

			if itemdata and imagedata then
				-- Transpose and rotate the image relative to the center
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(imagedata, item.x*tile_size + tile_size/2, item.y*tile_size + tile_size/2, item.r + love.timer.getTime()%360, 1, 1, imagedata:getWidth()/2, imagedata:getHeight()/2)
			end
		end
	end
	]]
	love.graphics.pop()
end

function MapObject:getDimensions()
	local mapdata  = self._mapdata
	return mapdata.width, mapdata.height
end

function MapObject:getWidth()
	local mapdata  = self._mapdata
	return mapdata.width
end

function MapObject:getHeight()
	local mapdata  = self._mapdata
	return mapdata.height
end

function MapObject:getPixelDimensions()
	local mapdata  = self._mapdata
	return mapdata.width*32, mapdata.height*32
end

function MapObject:getPixelWidth()
	local mapdata  = self._mapdata
	return mapdata.width*32
end

function MapObject:getPixelHeight()
	local mapdata  = self._mapdata
	return mapdata.height*32
end

function MapObject:mouseToMap(x, y)
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local camera = self._camera
	local mx = x + camera.x - sw/2
	local my = y + camera.y - sh/2
	return mx, my
end

function MapObject:mapToMouse(x, y)
end

function MapObject:spawn_effect(effect_id, x, y, args)
	effect.new(effect_id, x, y, args)
end

function MapObject:clearEffects()
	effect.clear()
end

function MapObject:getTileSize()
	return self._mapdata.tile_size
end

---Check if a collision is happening between `object` that has x|y property and a map tile
---If `x` and `y` is not specified, it will calculate collision at its own camera position
---@param tx number
---@param ty number
---@return boolean
function MapObject:isCollidingTile(tx, ty)
	tx = clamp(tx, 0, self:getWidth())
	ty = clamp(ty, 0, self:getHeight())
	local id, mod, property = self:tile(tx, ty)
	if TILE_MODE_HEIGHT[property] and TILE_MODE_HEIGHT[property] >= 0.5 then
		return true
	end
	return false
end

local EPSILON = 0.0001 -- deslocamento mínimo para evitar ficar preso
--- Função auxiliar: colisão contínua com um tile
--- @param size number
--- @param x1 number
--- @param y1 number
--- @param vx number
--- @param vy number
--- @param tileX number
--- @param tileY number
function MapObject:sweptAABB(size, x1, y1, vx, vy, tileX, tileY)
	local half 		= floor(size/2)
	local tile_size = self:getTileSize()
	
    local ox1 = x1 - half
    local oy1 = y1 - half
    local ox2 = x1 + half
    local oy2 = y1 + half

    local tx1 = tileX * tile_size
    local ty1 = tileY * tile_size
    local tx2 = tx1 + tile_size
    local ty2 = ty1 + tile_size

    local xEntry, xExit, yEntry, yExit

    if vx > 0 then
        xEntry = (tx1 - ox2) / vx
        xExit  = (tx2 - ox1) / vx
    elseif vx < 0 then
        xEntry = (tx2 - ox1) / vx
        xExit  = (tx1 - ox2) / vx
    else
        xEntry = -math.huge
        xExit  = math.huge
    end

    if vy > 0 then
        yEntry = (ty1 - oy2) / vy
        yExit  = (ty2 - oy1) / vy
    elseif vy < 0 then
        yEntry = (ty2 - oy1) / vy
        yExit  = (ty1 - oy2) / vy
    else
        yEntry = -math.huge
        yExit  = math.huge
    end

    local entryTime = math.max(xEntry, yEntry)
    local exitTime  = math.min(xExit, yExit)

    if entryTime > exitTime or (xEntry < 0 and yEntry < 0) or entryTime > 1 or entryTime < 0 then
        return nil
    end

    local nx, ny = 0, 0
    if xEntry > yEntry then
        nx = (vx < 0) and 1 or -1
    else
        ny = (vy < 0) and 1 or -1
    end

    return entryTime, nx, ny
end

-- Função principal: move com colisão + sliding
function MapObject:moveWithSliding(size, x1, y1, dx, dy)
    -- 1ª fase: tentar mover normalmente
    local earliest, nx, ny = 1, 0, 0
    local hit = false
	local half 		= floor(size/2)
	local tile_size = self:getTileSize()

    local minx = math.min(x1-half, x1 + dx - half)
    local maxx = math.max(x1+half, x1 + dx + half)
    local miny = math.min(y1-half, y1 + dy - half)
    local maxy = math.max(y1+half, y1 + dy + half)

    local tx1 = math.floor(minx / tile_size)
    local ty1 = math.floor(miny / tile_size)
    local tx2 = math.floor(maxx / tile_size)
    local ty2 = math.floor(maxy / tile_size)

    for ty = ty1, ty2 do
        for tx = tx1, tx2 do
            if self:isCollidingTile(tx, ty) then
                local t, nxx, nyy = self:sweptAABB(size, x1, y1, dx, dy, tx, ty)
                if t and t < earliest then
                    earliest = t
					---@diagnostic disable-next-line: cast-local-type
                    nx, ny = nxx, nyy
                    hit = true
                end
            end
        end
    end

    if not hit then
        -- sem colisão: move direto
        return x1 + dx, y1 + dy, hit
    end

    -- Mover até ponto de impacto (menos um epsilon)
    local moveX = x1 + dx * (earliest - EPSILON)
    local moveY = y1 + dy * (earliest - EPSILON)

    -- Calcula o movimento restante
    local remaining = 1 - earliest
    local rx = dx * remaining
    local ry = dy * remaining

    -- Remove componente na direção da colisão (faz sliding)
    if nx ~= 0 then rx = 0 end
    if ny ~= 0 then ry = 0 end

    -- 2ª fase: tenta mover no vetor restante (slide)
    local finalX, finalY = self:moveWithSliding(size, moveX, moveY, rx, ry)
    return finalX, finalY, hit
end


return MapObject