-- Mount a file system here
require "lib/lovefs/lovefs"
local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory() )
else
	fs:cd(love.filesystem.getSource() )
end

-- Loading some libs
local ffi = require "ffi"
local List = require "lib/list"
local shader = require "shader/cs2dshaders"

-- Localise some important functions to constantly call during execution
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local rad = math.rad
local random = math.random

-- Default config tables for tiles/tilesets/maps
local DEFAULT_PROPERTY = 0

local DEFAULT_MOD = {
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

local TILE_PROPERTY = {
	[0]="normal floor without sound";
	[1]="wall";
	[2]="obstacle";
	[3]="wall without shadow";
	[4]="obstacle without shadow";
	[5]="wall that is rendered at floor level";
	[10]="floor dirt";
	[11]="floor snow (with footprints and fx)";
	[12]="floor step";
	[13]="floor tile";
	[14]="floor wade (water with wave fx)";
	[15]="floor metal";
	[16]="floor wood";
	[50]="deadly normal";
	[51]="deadly toxic";
	[52]="deadly explosion";
	[53]="deadly abyss";
}

local TILE_MODE_HEIGHT = {
	[0]=0.0,		-- 0  normal floor without sound
	[1]=1.0,	-- 1  wall
	[2]=0.5,	-- 2  obstacle
	[3]=1.0,	-- 3  wall without shadow
	[4]=0.5,	-- 4  obstacle without shadow
	[5]=0.0,		-- 5  wall that is rendered at floor level
	[10]=0.0,		-- 10 floor dirt
	[11]=0.0,		-- 11 floor snow (with footprints and fx)
	[12]=0.0,		-- 12 floor step
	[13]=0.0,		-- 13 floor tile
	[14]=0.0,		-- 14 floor wade (water with wave fx)
	[15]=0.0,		-- 15 floor metal
	[16]=0.0,		-- 16 floor wood
	[50]=0.0,		-- 50 deadly normal
	[51]=0.0,		-- 51 deadly toxic
	[52]=0.0,		-- 52 deadly explosion
	[53]=0.0,		-- 53 deadly abyss
}

local TILE_BLEND_DIR = {
	[-1] = {0, 0};
	[0] = { 0,-1};
	[1] = { 1,-1};
	[2] = { 1, 0};
	[3] = { 1, 1};
	[4] = { 0, 1};
	[5] = {-1, 1};
	[6] = {-1, 0};
	[7] = {-1,-1};
}

local ENTITY_TYPE = {
	["null"] = {
		name = "Null";
		color = {1,1,1};
	};
	[0] = {
		name = "Info_T";
		color = {1,0,0};
		label = "T";
	};
		
	[1] = { 
		name = "Info_CT";
		color = {0,0,1};
		label = "CT";
	};


	[22] = {
		name ="Env_Sprite";
		color = {0,1,0};
		label = "Spr";
	};
}


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
	local spritesheet = fs:loadImageData(file)
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

local function entityInCamera(e, camx, camy, sprite)
	local path 		= e.string_settings[1]
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


--[[---------------------------------------------------------
	MapObject 
--]]---------------------------------------------------------
--- The object that creates, manages and draw
--- all map related operations in our game
---@class MapObject

local MapObject = {
	---@method draw test
	new = function()
	end
}

MapObject.__index = MapObject
MapObject.__tostring = function(self)
	local mapdata = self._mapdata
	return string.format("map: %s (author: %s [#%s])", mapdata.name, mapdata.author, mapdata.usgn)
end

--- Creates a new MapObject handler
---@param width number map width
---@param height number map height
---@return table MapObject
function MapObject.new(width, height)
	width = width or 50
	height = height or 50
	local object = {
		_updateRequest = true;
		_breath = 0;
		_oscillation = 0;
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
	object._flare = fs:loadImage("gfx/sprites/flare2.bmp");
	object._blendmap = create_spritesheet("gfx/blendmap.bmp", 32, 32)
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
		entity_cache = {};
		entity_list = List:new();
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
	--mapdata.shadow_render = love.graphics.newImage(mapdata.shadow_mask)
	--mapdata.shadow_render:setFilter("nearest", "nearest")
	local tileset_atlas = fs:loadImageData("gfx/tiles/"..mapdata.tileset)
	local w, h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	-- New spritebatch technique
	local tileset_spritesheet = fs:loadImage("gfx/tiles/"..mapdata.tileset)
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
	collectgarbage("collect")
end

--- @method Reads from a CS2D Map file
--- @param path string file relative to maps/ path in CS2D
function MapObject:read(path, noindexing)
	--local filedata = love.filesystem.newFileData(path)
	if not fs:isFile(path) then
		return string.format("File %q does not exist. Check your files/folders and try again!", path)
	end
	local filedata = fs:loadFile(path)
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
	print("Header check 1: \""..header_check_a.."\"")
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
	--mapdata.world:add(player, player.x, player.y, player.w, player.h)
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
				blending = blending,
				color = color,
				rotation = rotation,
				modifier = modifier,
				brightness = brightness,
			}
		end
		end
	else
		for x = 0, mapdata.width  do
		for y = 0, mapdata.height  do
			mapdata.map_mod[x] = mapdata.map_mod[x] or {}
			mapdata.map_mod[x][y] = {
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
		mapdata.entity_list:push( e )
		table.insert(mapdata.entity_table, e)
		mapdata.entity_cache[e.x] = mapdata.entity_cache[e.x] or {}
		mapdata.entity_cache[e.x][e.y] = e
	end

	if noindexing then
		self._mapdata = mapdata
		self._updateRequest = true
		return
	end
	-----------------------------------------------------------------------------------------------------------
	-- GFX/SFX INDEXING (6)
	-----------------------------------------------------------------------------------------------------------
	-- Tileset load.
	local tileset_path = string.format("gfx/tiles/%s", mapdata.tileset)
	--local tileset_raw = fs:loadImage(path)
	local tileset_atlas = fs:loadImageData(tileset_path)
	local w, h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	local tileset_spritesheet = fs:loadImage("gfx/tiles/"..mapdata.tileset)
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
	for _, e in mapdata.entity_list:walk() do
		if e.type == 22 then
			local sprite_path = (e.string_settings[1] or "gfx/cs2d.bmp")
			if not mapdata.gfx.entity[sprite_path] then -- Try to load a new image
				if fs:isFile(sprite_path) then -- Check if file exists
					local sprite = fs:loadImage(sprite_path)
					mapdata.gfx.entity[sprite_path] = sprite
					print(string.format("Sprite loaded: %s", sprite_path))
				else
					mapdata.gfx.entity[sprite_path] = love.graphics.newImage(self._placeholder)
					print(string.format("Failed to load %s", sprite_path))
				end
			end
		end
	end
	-- Background load.
	local background_path = string.format("gfx/backgrounds/%s", mapdata.background_file)
	if (mapdata.background_file ~= "") and fs:isFile(background_path) then
		print(string.format("Sprite loaded: %s", background_path))
		mapdata.gfx.background = fs:loadImage(background_path)
		mapdata.gfx.background:setWrap("repeat", "repeat")
	else
		mapdata.gfx.background = love.graphics.newImage(self._placeholder)
	end
	self._mapdata = mapdata
	self._updateRequest = true
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

function MapObject:isColliding(object, tx, ty)
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

function MapObject:update(dt)
	if not self._updateRequest then return end
	self._updateRequest = false
	local mapdata = self._mapdata
	local gfx = mapdata.gfx
	local camera = self._camera
	local screen_w = love.graphics.getWidth()
	local screen_h = love.graphics.getHeight()
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

function MapObject:draw_floor()
	local camera = self._camera
	local mapdata = self._mapdata
	local render = self._render
	
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local tile_size = mapdata.tile_size
	
	-- Draw background
	self:draw_background()

	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)

	-- Draw floor level
	love.graphics.setShader(shader.magenta)
	love.graphics.draw(mapdata.gfx.ground)
	love.graphics.setShader()
  
	-- Draw tile blends
  	local off_x, off_y = floor(tile_size/2), floor(tile_size/2)
	for x = render.x, render.width do
	for y = render.y, render.height do
		local tile_id, mod, property = self:tile(x, y)
		local quad = mapdata.gfx.quad[tile_id]
		
		if mod.blending > 1 then
			love.graphics.setColor(1,1,1,1)
			local sx = x * tile_size + off_x
			local sy = y * tile_size + off_y
			local dir = TILE_BLEND_DIR[ (mod.blending-2)%8 ]
			local tile_id_blend = self:tile(x + dir[1], y + dir[2])
			
			shader.mask:send("tile", mapdata.gfx.tile[tile_id_blend])
			love.graphics.setShader(shader.mask)
			love.graphics.draw(self._blendmap[mod.blending-2], sx, sy, rad(mod.rotation*90), 1, 1, off_x, off_y)	
			love.graphics.setShader()
		end
	end
	end
	
	-- Reset the transformation stack
	love.graphics.pop()
	
	-- Reset render
	love.graphics.setShader()
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
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)	
end

function MapObject:draw_external(z)
end

function MapObject:draw_bullets(share, home, client)
	local camera = self._camera
	local render = self._render
	local bullets = share.bullets
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)
	-- Bullets
	for _, bul in pairs(bullets) do
		love.graphics.push()
		love.graphics.translate(bul.x, bul.y)
		love.graphics.rotate(math.atan2(bul.dirY, bul.dirX))

		love.graphics.setColor(bul.r, bul.g, bul.b) -- Fill
		love.graphics.ellipse('fill', 0, 0, 24, 1)
		love.graphics.setColor(1, 1, 1, 0.38)

		love.graphics.setLineWidth(0.3) -- Outline
		love.graphics.ellipse('line', 0, 0, 24, 1)

		love.graphics.pop()
	end
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)	
end

function MapObject:draw_players(share, home, client) -- get info from server!
	local camera = self._camera
	local render = self._render
	local players = share.players -- get info from server
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)

	for clientId, player in pairs(players) do
		love.graphics.push()
		love.graphics.translate(player.x, player.y)

		local targetX, targetY
		if clientId == client.id then -- If it's us, use `home` data directly
			targetX, targetY = home.targetX, home.targetY
		else
			targetX, targetY = player.targetX, player.targetY
		end
		--local x,y = normalize(targetX, targetY)
		--love.graphics.rotate(math.atan2(targetY - player.y, targetX -  player.x))
		love.graphics.rotate(math.atan2(targetY - sh/2, targetX -  sw/2))

		love.graphics.setColor(player.r, player.g, player.b) -- Fill
		love.graphics.polygon('fill', -20, 20, 30, 0, -20, -20)

		love.graphics.setColor(1, 1, 1, 0.8) -- Outline (thicker if it's us)
		love.graphics.setLineWidth(clientId == client.id and 3 or 1)
		love.graphics.polygon('line', -20, 20, 30, 0, -20, -20)
		love.graphics.pop() -- Pop rotation (don't rotate health bar)
		--[[
		love.graphics.setColor(0, 0, 0, 0.5) -- Health bar
		love.graphics.rectangle('fill', -20, -35, 40, 4)
		love.graphics.setColor(0.933, 0.961, 0.859, 0.5)
		love.graphics.rectangle('fill', -20, -35, player.health / 100 * 40, 4)
		love.graphics.pop()
		--]]
	end
	-- Reset the transformation stack
	love.graphics.pop()
	-- Reset render
	love.graphics.setShader()
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

function MapObject:draw_background()
	local mapdata = self._mapdata
	if mapdata.background_file ~= "" then
		local background_w, background_h = mapdata.gfx.background:getDimensions()

		for i = 0, love.graphics.getWidth() / background_w do
		for j = 0, love.graphics.getHeight() / background_h do
			love.graphics.draw(mapdata.gfx.background, i * background_w, j * background_h)
		end
		end
	end
end

function MapObject:draw_entities()
	local camera = self._camera
	local mapdata = self._mapdata
	local render = self._render
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	-- Change camera perspective
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)
	-- Draw entity sprites
	for index, e in mapdata.entity_list:walk() do
		--do break end
		if e.type == 22 and entityInCamera(e, camera.x, camera.y) then
			self:draw_entity(e)
		end
	end
	-- Reset the transformation stack
	love.graphics.pop()
end

function MapObject:draw_items(share, client)
	local camera = self._camera
	local mapdata = self._mapdata
	local itemlist = share.itemlist
	local gfx = client.gfx
	local itemdata = client.content.itemdata
	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	love.graphics.push()
	love.graphics.translate(-camera.x + sw/2, -camera.y + sh/2)

	for _, item in pairs(itemlist) do
		love.graphics.push()
		love.graphics.translate(mapdata.tile_size/2, mapdata.tile_size/2) --  Offset by half a tile
		
		love.graphics.setColor(1, 1, 1, 1)
		local path = itemdata[item.id].common_path .. itemdata[item.id].dropped_image
		if not client.gfx.itemlist[path] then
			client.gfx.itemlist[path] = fs:loadImage(path)
		end

		love.graphics.setColor(0, 0, 0, 0.8)
		love.graphics.circle("fill",item.x*32, item.y*32, 7)
		love.graphics.setColor(0, 0, 0, 0.8)
		love.graphics.circle("fill",item.x*32, item.y*32, 8)
		love.graphics.draw(client.gfx.itemlist[path])

		
		love.graphics.pop()
	end
	love.graphics.pop()
end


return MapObject