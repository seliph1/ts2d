-- Mount a file system here
require "lib.lovefs.lovefs"

local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory())
else
	fs:cd(love.filesystem.getSource())
end

-- Loading some libs
local ffi = require "ffi"
local List = require "lib.list"
local bump = require "lib.bump"
local enum = require "core.enum"

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

local SOLID_THRESHOLD = 0.3
local WALL_THRESHOLD = 1.0

---@class Entity
---@field name string
---@field type number
---@field x number
---@field y number
---@field trigger string
---@field string_settings string[]
---@field number_settings number[]

---@class MapObject
---@field _mapdata MapData
---@field _world Bump.World
---@field _camera Camera
---@field _render Render
---@field _updateRequest boolean
---@field _breath number
---@field _oscillation number

---@class MapData
---@field name string
---@field header string
---@field scroll number
---@field modifiers number
---@field uptime number
---@field usgn number
---@field author string
---@field tileset string
---@field tile_count number
---@field width number
---@field height number
---@field write_time string
---@field background_file string
---@field background_scroll_speed_x number
---@field background_scroll_speed_y number
---@field background_color_red number
---@field background_color_green number
---@field background_color_blue number
---@field background_path string
---@field save_tile_heights number
---@field pixel_tiles_hd number
---@field tile_size number
---@field daylight number
---@field version string
---@field tile table<number, TileData>
---@field map table<number, table<number, number>>
---@field map_mod table<number, table<number, MapModData>>
---@field entity_count number
---@field entity_table table<number, Entity>
---@field entity_cache table<number, Entity>
---@field entity_list List<Entity>
---@field gfx table<string, table<number, userdata>>

---@class TileData
---@field height number
---@field modifier number
---@field property number

---@class MapModData
---@field ct number
---@field brightness number
---@field rotation number
---@field color table<number, number>
---@field modifier number
---@field blending number

---@class Camera
---@field x number
---@field y number
---@field width number
---@field height number
---@field chunk_x number
---@field chunk_y number
---@field tile_x number
---@field tile_y number

---@class Render
---@field x number
---@field y number
---@field width number
---@field height number

--[[---------------------------------------------------------
	Lib
--]] ---------------------------------------------------------
--- Creates a spritesheet out of a file, in equal rectangles
--- containing all subsections  of the file as a ImageData object
--- @param file string
--- @param xsize number
--- @param ysize number
--- @return table spritesheet_table table containing all ImageData
local function create_spritesheet(file, xsize, ysize)
	local spritesheet = fs:loadImageData(file)
	local spritesheet_table = {}
	local w, h = spritesheet:getDimensions()
	local id = 0
	for y = 0, floor(h / xsize) - 1 do
		for x = 0, floor(w / ysize) - 1 do
			local sprite = love.image.newImageData(xsize, ysize)
			sprite:paste(spritesheet, 0, 0, x * xsize, y * ysize, xsize, ysize)
			spritesheet_table[id] = love.graphics.newImage(sprite)
			id = id + 1
		end
	end
	return spritesheet_table
end

local function entityInCamera(e, camx, camy, sprite)
	local path           = e.string_settings[1]
	local size_x         = e.number_settings[1]
	local size_y         = e.number_settings[2]
	local shift_x        = e.number_settings[3]
	local shift_y        = e.number_settings[4]

	local sw             = love.graphics.getWidth()
	local sh             = love.graphics.getHeight()

	local x1, y1         = e.x * 32 - camx + sw / 2 + shift_x, e.y * 32 - camy + sh / 2 + shift_y
	local x1size, y1size = size_x, size_y

	local x2, y2         = 0, 0
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
	local x1, y1 = e.x * 32 - camx + sw / 2, e.y * 32 - camy + sh / 2
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


--[[---------------------------------------------------------
	MapObject
--]] ---------------------------------------------------------
--- The object that creates, manages and draw
--- all map related operations in our game
--- @class MapObject: table
local MapObject = {}

MapObject.__index = MapObject
MapObject.__tostring = function(self)
	local mapdata = self._mapdata
	return string.format("map: %s (author: %s [#%s])", mapdata.name, mapdata.author, mapdata.usgn)
end

--- Creates a new MapObject handler
---@param width? number map width
---@param height? number map height
---@return MapObject
function MapObject.new(width, height)
	width = width or 50
	height = height or 50
	---@class MapObject: table
	local object = {
		_updateRequest = true,
		_breath = 0,
		_oscillation = 0,
		_camera = {
			x = 0,
			y = 0,
			width = 0,
			height = 0,
			chunk_x = 0,
			chunk_y = 0,
			tile_x = 0,
			tile_y = 0,
		},
		_render = {
			x = 0,
			y = 0,
			width = 16,
			height = 16,
		},
		_world = bump.newWorld()
	}
	local mapdata = {
		name = "untitled",
		header = "Unreal Software's Counter-Strike 2D Map File (max)",
		scroll = 0,
		modifiers = 0,
		uptime = 0,
		usgn = 0,
		author = "mapengine.lua",
		tileset = "cs2dnorm.bmp",
		tile_count = 255,
		width = width - 1,
		height = height - 1,
		write_time = "000000",
		background_file = "",
		background_scroll_speed_x = 0,
		background_scroll_speed_y = 0,
		background_color_red = 0,
		background_color_green = 0,
		background_color_blue = 0,
		save_tile_heights = 0,
		pixel_tiles_hd = 0,
		tile_size = 32,
		daylight = 0,
		version = "CS2D v1.0.1.4",
		tile = {},
		map = {},
		map_mod = {},
		--shadow_mask = love.image.newImageData(width+1, height+1);
		entity_count = 0,
		entity_table = {},
		entity_cache = {},
		entity_list = List:new(),
		gfx = {
			tile = {},
			entity = {},
			background = {},
			quad = {},
		},
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
				ct = 4, -- Collision type 4 (tile)
				brightness = 100,
				rotation = 0,
				color = {
					red = 255,
					blue = 255,
					green = 255,
				},
				modifier = 0,
				blending = 0,
			}
		end
	end

	object._mapdata = mapdata
	return setmetatable(object, MapObject)
end

--- @method Clears the map
function MapObject:clear()
	collectgarbage("collect")
end

--- @method Reads from a CS2D Map file
--- @return string path file relative to maps/ path in CS2D
function MapObject:name()
	return self._mapdata.name
end

function MapObject:walk()
	--[[
	local mapdata = self._mapdata
	local width = mapdata.width
	local height = mapdata.height
	return function()
		
	end--]]
end

function MapObject:read(path, noindexing)
	--local filedata = love.filesystem.newFileData(path)
	if not fs:isFile(path) then
		error(string.format("File %q does not exist. Check your files/folders and try again!", path))
		--return string.format("File %q does not exist. Check your files/folders and try again!", path)
	end
	local filedata = fs:loadFile(path)
	-- Get a C pointer to read files as binary mode.
	local size = filedata:getSize()
	local pointer = filedata:getFFIPointer()
	-- Set byte and integer tables to read.
	local bytearray = ffi.cast('uint8_t*', pointer)
	local integerarray = ffi.cast('int32_t*', pointer)
	local shortarray = ffi.cast('uint16_t*', pointer)
	-- Set the cursor at the start of file
	local cursor = 0
	-- Read single byte
	local function read_byte()
		local value = bytearray[cursor]
		cursor = cursor + 1
		return value
	end
	-- Reading functions
	local function read_integer()
		local b1, b2, b3, b4 = bytearray[cursor], bytearray[cursor + 1], bytearray[cursor + 2], bytearray[cursor + 3]
		-- Read integer as signed non endian
		local value = b4 * 0x1000000 + b3 * 0x10000 + b2 * 0x100 + b1
		cursor = cursor + 4
		return value > 0x7fffffff and value - 0x100000000 or value
	end
	-- Read string until \n
	local function read_string()
		local str = ""
		local i = 0
		for index = 0, size - cursor do
			local chr = string.char(bytearray[cursor + index])
			if bytearray[cursor + index] == 10 then
				cursor = cursor + index + 1
				return str
			end

			if bytearray[cursor + index] ~= 13 then
				str = str .. chr
			end
		end
	end
	-- Read short integer as unsigned endian.
	local function read_short()
		local value = shortarray[floor(cursor / 2)]
		cursor = cursor + 2
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
	--print("Header check 1: \""..header_check_a.."\"")
	if not (
			string.find(header_check_a, "Unreal Software's Counter-Strike 2D Map File", 1, true) or
			string.find(header_check_a, "Unreal Software's CS2D Map File", 1, true)
		) then
		error("\n\nMap header first check failed. \nCheck if your file is corrupted.\nResult string: \"" ..
			header_check_a .. "\"")
	end
	-- skeleton
	-----------------------------------------------------------------------------------------------------------
	local mapdata = {
		gfx = {
			tile = {},
			entity = {},
			background = {},
			quad = {},
			--ground = love.graphics.newSpriteBatch(self._placeholder);
			--wall = love.graphics.newSpriteBatch(self._placeholder);
		},
	}
	-- byte header data
	-----------------------------------------------------------------------------------------------------------
	mapdata.name = string.match(path, "([^/\\]+)%.%w+$")
	mapdata.scroll = read_byte()         -- Map scroll property
	mapdata.modifiers = read_byte()      -- Modifiers
	mapdata.save_tile_heights = read_byte() -- Tile height property
	mapdata.pixel_tiles_hd = read_byte() -- Tile pixel size
	mapdata.tile_size = mapdata.pixel_tiles_hd == 1 and 64 or 32
	seek_forward(6)
	-- integer header data
	-----------------------------------------------------------------------------------------------------------	-- Six empty slots
	mapdata.uptime = read_integer() -- Time map were made
	mapdata.usgn = read_integer() - 51 -- Author USGN
	mapdata.daylight = read_integer() -- Daylight value
	seek_forward(7 * 4)
	-- string header data
	-----------------------------------------------------------------------------------------------------------	-- 7*4 empty spaces
	mapdata.author = read_string() -- Author name
	mapdata.version = read_string() -- Map version
	seek_forward(8 * 2)
	-- more map settings
	-----------------------------------------------------------------------------------------------------------
	mapdata.write_time = read_string() -- Map date
	mapdata.tileset = read_string() -- Tileset name string
	mapdata.tile_count = read_byte() -- How many tiles is in the map
	mapdata.tile = {}
	for i = -1, mapdata.tile_count do
		mapdata.tile[i] = {
			height = 0,
			modifier = 0,
			property = 0,
		}
	end
	mapdata.width = read_integer() -- Map x size
	mapdata.height = read_integer() -- Map y size
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
	--[[
			Tile modes are:
		0  normal floor without sound
		1  wall
		2  obstacle
		3  wall without shadow
		4  obstacle without shadow
		5  wall that is rendered at floor level
		10 floor dirt
		11 floor snow (with footprints and fx)
		12 floor step
		13 floor tile
		14 floor wade (water with wave fx)
		15 floor metal
		16 floor wood
		50 deadly normal
		51 deadly toxic
		52 deadly explosion
		53 deadly abyss
	--]]
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
			elseif mapdata.save_tile_heights == 2 then -- CS2D 1.0.0.3 and above
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
	--mapdata.world:add(player, player.x, player.y, player.w, player.h)
	----------------------------------------------------------------------------------------------
	-- Tile id mod table.
	mapdata.map_mod = {}
	if mapdata.modifiers == 1 then
		for x = 0, mapdata.width do
			for y = 0, mapdata.height do
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
					if modifier >= 192 then        -- Some stuff that DC planned.
						read_string()
					elseif modifier >= 64 and modifier < 128 then -- Blending
						brightness = floor((modifier - 64 - rotation) * 2.5)
						blending = read_byte() + 2
					elseif modifier >= 128 then -- Color + Blending
						brightness = floor((modifier - 128 - rotation) * 2.5)
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
					ct = 4, -- Collision type 4 (tile)
					blending = blending,
					color = color,
					rotation = rotation,
					modifier = modifier,
					brightness = brightness,
				}
			end
		end
	else
		for x = 0, mapdata.width do
			for y = 0, mapdata.height do
				mapdata.map_mod[x] = mapdata.map_mod[x] or {}
				mapdata.map_mod[x][y] = {
					ct = 4, -- Collision type 4 (tile)
					brightness = 100,
					rotation = 0,
					color = {
						red = 255,
						blue = 255,
						green = 255,
					},
					modifier = 0,
					blending = 0,
				}
			end
		end
	end
	-----------------------------------------------------------------------------------------------------------
	-- ENTITIES (5)
	-----------------------------------------------------------------------------------------------------------
	mapdata.entity_count = read_integer()
	mapdata.entity_list = List.new()
	mapdata.entity_table = {}
	mapdata.entity_cache = {}
	--print("Entity count: " .. mapdata.entity_count)
	for i = 1, mapdata.entity_count do
		local e = {}
		e.name = read_string()
		e.type = read_byte()
		e.x = read_integer()
		e.y = read_integer()
		e.trigger = read_string()
		e.string_settings = {}
		e.number_settings = {}
		for j = 1, 10 do
			e.number_settings[j] = read_integer()
			e.string_settings[j] = read_string()
		end
		mapdata.entity_list:push(e)
		table.insert(mapdata.entity_table, e)
		mapdata.entity_cache[e.x] = mapdata.entity_cache[e.x] or {}
		mapdata.entity_cache[e.x][e.y] = e
	end

	self._mapdata = mapdata
	self._updateRequest = true
end

function MapObject:getFiles()
	local files   = {}
	local mapdata = self._mapdata

	table.insert(files, mapdata.background_path)

	for _, e in mapdata.entity_list:walk() do
		---@cast e Entity
		if e.type == 22 then
			local sprite_path = e.string_settings[1]
			if sprite_path then
				table.insert(files, sprite_path)
			end
		end
	end
	return files
end

function MapObject:getSpawnPoints()
	local spawnpoints = {}
	local mapdata     = self._mapdata
	for _, e in mapdata.entity_list:walk() do
		---@cast e Entity
		if e.type == 0 or e.type == 1 then
			table.insert(spawnpoints, { x = e.x, y = e.y })
		end
	end
	return spawnpoints
end

---@param entity_type? number
---@return Entity[]
function MapObject:getEntities(entity_type)
	local mapdata = self._mapdata
	local entities = {}
	for _, e in mapdata.entity_list:walk() do
		---@cast e Entity
		if entity_type then
			if e.type == entity_type then
				-- Dont expose inner table
				-- And just add x and y as tile coordinates
				table.insert(entities, {
					name = e.name,
					type = e.type,
					x = e.x,
					y = e.y,
					trigger = e.trigger,
					string_settings = e.string_settings,
					number_settings = e.number_settings,
				})
			end
		else
			table.insert(entities, {
				name = e.name,
				type = e.type,
				x = e.x,
				y = e.y,
				trigger = e.trigger,
				string_settings = e.string_settings,
				number_settings = e.number_settings,
			})
		end
	end
	return entities
end

function MapObject:getDimensions()
	local mapdata = self._mapdata
	return mapdata.width, mapdata.height
end

function MapObject:getWidth()
	local mapdata = self._mapdata
	return mapdata.width
end

function MapObject:getHeight()
	local mapdata = self._mapdata
	return mapdata.height
end

function MapObject:getPixelDimensions()
	local mapdata = self._mapdata
	return mapdata.width * 32, mapdata.height * 32
end

function MapObject:getPixelWidth()
	local mapdata = self._mapdata
	return mapdata.width * 32
end

function MapObject:getPixelHeight()
	local mapdata = self._mapdata
	return mapdata.height * 32
end

function MapObject:getName()
	return self._mapdata.name
end

function MapObject:getAuthor()
	return self._mapdata.author
end

function MapObject:getUSGN()
	return self._mapdata.usgn
end

function MapObject:getTileset()
	return self._mapdata.tileset
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
			local r = random(0, 255)
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
		local property = self._mapdata.tile[id].property
		return id, mod, property
	else
		return -1, DEFAULT_MOD
	end
end

function MapObject:tileProp(x, y)
	if self._mapdata.map[x] and self._mapdata.map[x][y] then
		return self._mapdata.map_mod[x][y]
	end
	return
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
function MapObject:isColliding(x, y, height)
	local height = height or 0.5
	local tx, ty = floor(x / 32), floor(y / 32)
	local id, mod, property = self:tile(tx, ty)

	if TILE_MODE_HEIGHT[property] and TILE_MODE_HEIGHT[property] >= height then
		return true
	end
	return false
end

function MapObject:scroll(x, y)
	x, y = floor(x), floor(y)
	local cx = floor(x / (32 * 8))
	local cy = floor(y / (32 * 8))
	if self._camera.chunk_x ~= cx or self._camera.chunk_y ~= cy then
		self._updateRequest = true
	end
	self._camera.chunk_x = cx
	self._camera.chunk_y = cy
	self._camera.x = x
	self._camera.y = y
end

function MapObject:getTileSize()
	return self._mapdata.tile_size
end

function MapObject:getTileCount()
	return self._mapdata.tile_count
end

---Check if a collision is happening between `object` that has x|y property and a map tile
---
---If `x` and `y` is not specified, it will calculate collision at its own camera position
---@param tx number
---@param ty number
---@return boolean
function MapObject:isCollidingTile(tx, ty, height)
	local height = height or 0.5
	tx = max(min(tx, self:getWidth()), 0)
	ty = max(min(ty, self:getHeight()), 0)

	local id, mod, property = self:tile(tx, ty)

	if TILE_MODE_HEIGHT[property] and TILE_MODE_HEIGHT[property] >= height then
		return true
	end
	return false
end

MapObject.isCollidingWithTile = MapObject.isCollidingTile

local EPSILON = 0.0001 -- deslocamento mínimo para evitar ficar preso

-- Função auxiliar: colisão contínua com um tile
function MapObject:sweptAABB(size, x1, y1, vx, vy, tileX, tileY)
	local half      = floor(size / 2)
	local tile_size = self:getTileSize()

	local ox1       = x1 - half
	local oy1       = y1 - half
	local ox2       = x1 + half
	local oy2       = y1 + half

	local tx1       = tileX * tile_size
	local ty1       = tileY * tile_size
	local tx2       = tx1 + tile_size
	local ty2       = ty1 + tile_size

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
function MapObject:move_and_slide(size, x1, y1, dx, dy)
	-- 1ª fase: tentar mover normalmente
	local earliest, nx, ny = 1, 0, 0
	local hit              = false

	local half             = floor(size / 2)
	local tile_size        = self:getTileSize()

	local minx             = math.min(x1 - half, x1 + dx - half)
	local maxx             = math.max(x1 + half, x1 + dx + half)
	local miny             = math.min(y1 - half, y1 + dy - half)
	local maxy             = math.max(y1 + half, y1 + dy + half)

	local tx1              = math.floor(minx / tile_size)
	local ty1              = math.floor(miny / tile_size)
	local tx2              = math.floor(maxx / tile_size)
	local ty2              = math.floor(maxy / tile_size)

	for ty = ty1, ty2 do
		for tx = tx1, tx2 do
			if self:isCollidingTile(tx, ty, SOLID_THRESHOLD) then
				local t, nxx, nyy = self:sweptAABB(size, x1, y1, dx, dy, tx, ty)
				if t and t < earliest then
					earliest = t
					nx = nxx or 0
					ny = nyy or 0
					hit = true
				end
			end
		end
	end

	if not hit then
		-- sem colisão: move direto
		return x1 + dx, y1 + dy
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
	local finalX, finalY = self:move_and_slide(size, moveX, moveY, rx, ry)
	return finalX, finalY
end

function MapObject:hitscan(x1, y1, x2, y2, height)
	local dx = x2 - x1
	local dy = y2 - y1
	height = height or 0

	local steps = math.abs(dx)
	if math.abs(dy) > steps then
		steps = math.abs(dy)
	end

	if steps == 0 then
		-- linha degenerada (ponto único)
		if self:isColliding(x1, y1, height) then
			return x1, y1, true
		else
			return x1, y1, false
		end
	end

	local sx = dx / steps
	local sy = dy / steps
	local x, y = x1, y1

	for i = 1, steps do
		if self:isColliding(x, y, height) then
			return x, y, true -- impacto
		end
		x = x + sx
		y = y + sy
	end

	return x2, y2, false -- sem colisão
end

function MapObject:getBuyZones()
	local buyzone = {}
	local mapdata = self._mapdata
	for _, e in mapdata.entity_list:walk() do
		---@cast e Entity
		if e.type == 0 or e.type == 1 then
			for x = -1, 1 do
			for y = -1, 1 do
				buyzone[e.x + x] = buyzone[e.x + x] or {}
				buyzone[e.x + x][e.y + y] = e.type
			end
			end
		end
	end
	return buyzone
end

return MapObject
