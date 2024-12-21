local ffi = require "ffi"
local List = require "lib/list"
local shader = require "shader/cs2dshaders"
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local rad = math.rad

require "lib/lovefs/lovefs"

local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory() )
else
	fs:cd(love.filesystem.getSource() )
end

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

local TILE_MODE_HEIGHT = {
	[0]=0,		-- 0  normal floor without sound
	[1]=0.5,	-- 1  wall
	[2]=0.3,	-- 2  obstacle
	[3]=0.5,	-- 3  wall without shadow
	[4]=0.3,	-- 4  obstacle without shadow
	[5]=0,		-- 5  wall that is rendered at floor level
	[10]=0,		-- 10 floor dirt
	[11]=0,		-- 11 floor snow (with footprints and fx)
	[12]=0,		-- 12 floor step
	[13]=0,		-- 13 floor tile
	[14]=0,		-- 14 floor wade (water with wave fx)
	[15]=0,		-- 15 floor metal
	[16]=0,		-- 16 floor wood
	[50]=0,		-- 50 deadly normal
	[51]=0,		-- 51 deadly toxic
	[52]=0,		-- 52 deadly explosion
	[53]=0,		-- 53 deadly abyss
}
local EMPTY = {}

local editor = {
	pencil = {
		mode = "paint",
		x = 0,
		y = 0,
		tile_id = 0,
	};
	
	mousemap_x = 0,
	mousemap_y = 0,
	mouse_x = 0,
	mouse_y = 0,
	camera_x = 0,
	camera_y = 0,
	
	
	key_pressed = {};
	key_released = {};
}

local mapfile = {}

--[[---------------------------------------------------------
	Lib
--]]---------------------------------------------------------

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

local function entityInCamera(e, camx, camy)
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

local function render_grid()
	
end


local editor_icons = create_spritesheet("gfx/gui_icons.bmp", 16, 16)
local editor_placeholder = love.image.newImageData(32, 32)
local flare = fs:loadImage("gfx/sprites/flare2.bmp")


--[[---------------------------------------------------------
	Initializer
--]]---------------------------------------------------------

function mapfile_new(width, height)
	local mapdata = {
		header = "Unreal Software's Counter-Strike 2D Map File (max)";
		scroll = 0;
		modifiers = 0;
		uptime = 0;
		usgn = 0;
		author = "mapfile.lua";
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
		background_scroll_speed_x = 0;
		background_scroll_speed_y = 0;
		save_tile_heights = 0;
		pixel_tiles_hd = 0; 
		tile_size = 32;
		daylight = 0;
		version = "CS2D v1.0.1.4";

		tile = {};
		map = {};
		map_mod = {};
		
		entity_count = 0;
		entity_table = {};
		entity_list = List:new();
		
		gfx = {
			tile = {};
			entity = {};
			background = {};
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
	
	local tileset_atlas = fs:loadImageData("gfx/tiles/"..mapdata.tileset)
	local w,h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	
	for y = 0, floor(h/s)-1 do
	for x = 0, floor(w/s)-1 do
		local sprite = love.image.newImageData(s, s)
		sprite:paste(tileset_atlas, 0, 0, x*s, y*s, s, s)
		mapdata.gfx.tile[tile_id] = love.graphics.newImage(sprite)
		tile_id = tile_id + 1
	end
	end
	
	-- Entity load
	for index, e in mapdata.entity_list:walk() do
		if e.type == 22 then
			local path = (e.string_settings[1] or "gfx/cs2d.bmp")
	
			if not mapdata.gfx.entity[path] then -- Try to load a new image
				if fs:isFile(path) then
					local sprite = fs:loadImage(path)
					
					mapdata.gfx.entity[path] = sprite
					print(string.format("Sprite loaded: %s", path))
				else
					mapdata.gfx.entity[path] = love.graphics.newImage(editor_placeholder)
					print(string.format("Failed to load: %s", path))
				end				
			end
		end	
	end
	
	-- Background load.
	local path = string.format("gfx/backgrounds/%s", mapdata.background_file)
	if (mapdata.background_file ~= "") and fs:isFile(path) then
		mapdata.gfx.background = fs:loadImage(path)
		print(string.format("Sprite loaded: %s", path))
	else
		mapdata.gfx.background = love.graphics.newImage(editor_placeholder)
	end

	return mapdata
end

--[[---------------------------------------------------------
	Load a new empty map
--]]---------------------------------------------------------
local mapfile = mapfile_new(50, 50)



--[[---------------------------------------------------------
	Callbacks
--]]---------------------------------------------------------
function mapdata_keypressed(key, unicode)
	editor.key_pressed[key] = true 
	
	if (key=="f2") then
		mapdata_random()
	end
end

function mapdata_keyreleased(key, unicode)
	editor.key_pressed[key] = false
end

--[[---------------------------------------------------------
	Functions
--]]---------------------------------------------------------

function mapdata_setpencil(tile_id)
	if tile_id and type(tile_id) == "number" and tile_id > 0 and tile_id < 255 then
		editor.pencil.tile_id = tile_id
	else
		editor.pencil.tile_id = 0
	end	
end

function mapdata_random()
	for x = 0, mapfile.width do
	for y = 0, mapfile.height do
		--local id = 0
		mapfile.map[x] = mapfile.map[x] or {}
		mapfile.map[x][y] = math.random(0,255)
	end
	end	
end


function mapdata_settile(x, y, tile_id)
	if mapfile.map[x] and mapfile.map[x][y] then
		mapfile.map[x][y] = tile_id
	end	
end

function mapdata_gettile(x, y) -- coords in tiles
	if mapfile.map[x] and mapfile.map[x][y] then 
		return mapfile.map[x][y]
	else
		return 0
	end	
end


function mapfile_read(path)
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
	
	local mapdata = {
		gfx = {
			tile = {};
			entity = {};
			background = {};
		}
	}
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
	-- byte header data
	-----------------------------------------------------------------------------------------------------------
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
		file:close()
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
		mapdata.tile[i].property = read_byte(file)
	end

	-----------------------------------------------------------------------------------------------------------
	-- TILE HEIGHTS (3)
	-----------------------------------------------------------------------------------------------------------
	if mapdata.save_tile_heights > 0 then
		for i = 0, mapdata.tile_count do
			if mapdata.save_tile_heights == 1 then -- CS2D 1.0.0.3 prerelease
				mapdata.tile[i].height = read_int()
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
	for x = 0, mapdata.width do
	for y = 0, mapdata.height do
		local id = read_byte()
		mapdata.map[x] = mapdata.map[x] or {}
		mapdata.map[x][y] = id
	end
	end	
	
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
		
		for i = 1, 10 do
			e.number_settings[i] = read_integer()
			e.string_settings[i] = read_string()
		end
		mapdata.entity_list:push( e )
		table.insert(mapdata.entity_table, e)
	end

	-----------------------------------------------------------------------------------------------------------
	-- GFX/SFX INDEXING (6)
	-----------------------------------------------------------------------------------------------------------
	-- Tileset load.
	local path = string.format("gfx/tiles/%s", mapdata.tileset)
	--local tileset_raw = fs:loadImage(path)
	local tileset_atlas = fs:loadImageData(path)
	local w, h = tileset_atlas:getDimensions()
	local s = mapdata.tile_size
	local tile_id = 0
	
	for y = 0, floor(h/s)-1 do
	for x = 0, floor(w/s)-1 do
		local sprite = love.image.newImageData(s, s)
		sprite:paste(tileset_atlas,0,0,x*s, y*s, s, s)
		
		mapdata.gfx.tile[tile_id] = love.graphics.newImage(sprite)
		tile_id = tile_id + 1
	end
	end
	
	-- Entity load
	for index, e in mapdata.entity_list:walk() do
		if e.type == 22 then
			local path = (e.string_settings[1] or "gfx/cs2d.bmp")
	
			if not mapdata.gfx.entity[path] then -- Try to load a new image
				if fs:isFile(path) then -- Check if file exists
					local sprite = fs:loadImage(path)
					mapdata.gfx.entity[path] = sprite
					print(string.format("Sprite loaded: %s", path))
				else
					mapdata.gfx.entity[path] = love.graphics.newImage(editor_placeholder)
					print(string.format("Failed to load %s", path))
				end				
			end
		end	
	end
	
	-- Background load.
	local path = string.format("gfx/backgrounds/%s", mapdata.background_file)
	if (mapdata.background_file ~= "") and fs:isFile(path) then
		print(string.format("Sprite loaded: %s", path))
		mapdata.gfx.background = fs:loadImage(path)
	else
		mapdata.gfx.background = love.graphics.newImage(editor_placeholder)
	end

	mapfile = mapdata
	
	editor.camera_x = 0
	editor.camera_y = 0
end

function mapfile_tile(x, y) -- coords in tiles
	if mapfile.map[x] and mapfile.map[x][y] then
		return mapfile.map[x][y], mapfile.map_mod[x][y]
	else
		return -1, DEFAULT_MOD
	end	
end

function mapfile_gfx(group, id)
	if mapfile.gfx[group] then
		if mapfile.gfx[group][id] then
			return mapfile.gfx[group][id]
		end	
	end
	
	return nil
end

function mapdata_update(dt)
	if loveframes.collisioncount == 0 then
		local s = 500*dt
		if (editor.key_pressed.up or editor.key_pressed.w) then 
			editor.camera_y = editor.camera_y - s
		end
		if (editor.key_pressed.left or editor.key_pressed.a) then 
			editor.camera_x = editor.camera_x - s 
		end
		if (editor.key_pressed.down or editor.key_pressed.s) then 
			editor.camera_y = editor.camera_y + s
		end

		if (editor.key_pressed.right or editor.key_pressed.d) then 
			editor.camera_x = editor.camera_x + s 
		end
		
		if love.mouse.isDown(1) then
			mapdata_settile(editor.mousemap_x, editor.mousemap_y, editor.pencil.tile_id)
		elseif love.mouse.isDown(2) then
			mapdata_setpencil( mapdata_gettile(editor.mousemap_x, editor.mousemap_y) )
		end
	end
	
	editor.mousemap_x = math.floor( (love.mouse.getX() - love.graphics.getWidth()/2 + editor.camera_x) / 32  )
	editor.mousemap_y = math.floor( (love.mouse.getY() - love.graphics.getHeight()/2 + editor.camera_y) / 32  )
end


function mapdata_draw()
	local camera_x, camera_y = floor(editor.camera_x), floor(editor.camera_y)
	local screen_w = love.graphics.getWidth()
	local screen_h = love.graphics.getHeight()
	local center_x = screen_w/2 - camera_x
	local center_y = screen_h/2 - camera_y
	
	local ts = mapfile.tile_size

	local entity_screen = 0
	local entity_total = mapfile.entity_list:count()
	
	
	if mapfile.background_file ~= "" then
		local background_w, background_h = mapfile.gfx.background:getDimensions()
		for i = 0, screen_w / background_w do
		for j = 0, screen_w / background_h do
		
			love.graphics.draw(mapfile.gfx.background, i * background_w, j * background_h)
		end
		end
	end	
	
	
	local minx, maxx = floor( (camera_x - screen_w/2 ) / ts ), ceil( ( camera_x + screen_w/2 ) / ts )
	local miny, maxy = floor( (camera_y - screen_h/2 ) / ts ), ceil( ( camera_y + screen_h/2 ) / ts )
	
	
	love.graphics.reset()
	love.graphics.setShader(shader.magenta)
	-- FLOORS
	for x = minx, maxx do
	for y = miny, maxy do
		local tile_id, mod = mapfile_tile(x,y)
		local gfx = mapfile.gfx.tile[tile_id]
		local property = mapfile.tile[tile_id].property
		
		if gfx and property ~= 1 then 
			local off_x, off_y = floor(ts/2), floor(ts/2)
			local sx = x*ts - camera_x + screen_w/2 + off_x
			local sy = y*ts - camera_y + screen_h/2 + off_y
			local brightness = (mod.brightness/100)
			
			love.graphics.setColor(
				love.math.colorFromBytes(
					mod.color.red * brightness , 
					mod.color.green * brightness, 
					mod.color.blue * brightness
				)
			)

			love.graphics.draw(gfx, sx, sy, rad(mod.rotation*90), 1, 1, off_x, off_y)

		end
	end
	end
	
	
	-- Entities
	love.graphics.setShader(shader.entity)
	for index, e in mapfile.entity_list:walk() do
	--for index, e in ipairs(EMPTY) do
		if e.type == 22 and entityInCamera(e, camera_x, camera_y) then
			local path 		= e.string_settings[1]
			local sprite 	= mapfile.gfx.entity[path]
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
			local angle = math.rad(rotation + rotationspeed * os.clock() * 90)
			local scale_x = size_x/width
			local scale_y = size_y/height
			local sx = (e.x * 32) + center_x + shift_x + size_x/2
			local sy = (e.y * 32) + center_y + shift_y + size_y/2
			
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
			entity_screen = entity_screen + 1
		end
	end
	
	love.graphics.reset()
	love.graphics.setShader(shader.magenta)
	-- WALLS
	for x = minx, maxx do
	for y = miny, maxy do
		local tile_id, mod = mapfile_tile(x,y)
		local gfx = mapfile.gfx.tile[tile_id]
		local property = mapfile.tile[tile_id].property
		if gfx and property == 1 then
			local off_x, off_y = floor(ts/2), floor(ts/2)
			local sx = x*ts - camera_x + screen_w/2 + off_x
			local sy = y*ts - camera_y + screen_h/2 + off_y
			local brightness = (mod.brightness/100)
			love.graphics.setColor(
				love.math.colorFromBytes(
					mod.color.red * brightness , 
					mod.color.green * brightness, 
					mod.color.blue * brightness
				)
			)
			love.graphics.draw(gfx, sx, sy, rad(mod.rotation*90), 1, 1, off_x, off_y)
		end
		
	end
	end
	
	--[[
	-- ENTITY ICONS
	love.graphics.setBlendMode("screen", "premultiplied")
	love.graphics.setShader()
	local breath = math.cos(os.clock()*8)/2 + 0.5
	for index, e in mapfile.entity_list:walk() do
		if e.type == 22 and aabb(e.x, e.y, minx, miny, maxx, maxy) then
			
			love.graphics.setColor(0,0.3*breath , 0,1)
			love.graphics.draw(flare, e.x*32+16 + camera_x, e.y*32+16 + camera_y, 0, 0.4, 0.4, 48, 48)
		
			love.graphics.setColor(0,1,0,1)
			love.graphics.draw(editor_icons[9], e.x*32+16 + camera_x, e.y*32+16 + camera_y, 0, 1, 1, 8, 8)
		end	
	end
	--]]
	
	love.graphics.reset()
	love.graphics.print(string.format ("entities on screen: %d/%d", entity_screen, entity_total), love.graphics.getWidth()-200, 20)
	
	
	if loveframes.collisioncount == 0 then
		local tile_id = mapfile_tile(editor.mousemap_x, editor.mousemap_y)
		local label = string.format(
			"Camera: %dpx|%dpx   Tile Position: %d|%d    Tile #%d", 
			editor.camera_x, 
			editor.camera_y, 
			editor.mousemap_x, 
			editor.mousemap_y, 
			tile_id
		)
		
		love.graphics.print(label , love.graphics.getWidth()/2, love.graphics.getHeight()-20)
		
		
		local offset_x = screen_w % 32 - screen_w/2 
		local offset_y = screen_h % 32 - screen_h/2 
		
		local cursor_x = love.mouse.getX() - ( camera_x + love.mouse.getX() - offset_x  )%32
		local cursor_y = love.mouse.getY() - ( camera_y + love.mouse.getY() - offset_y  )%32
		local time = love.timer.getTime()
		local oscillation = (math.sin( time * math.pi * 2) + 1)/2
		
		love.graphics.setColor(1, 1, 0, 0.5 + oscillation/2  )
		--love.graphics.setColor(1, 1, 0, 1)
		love.graphics.rectangle("line",cursor_x, cursor_y, 32, 32)
		
		
		
		-- Draw visible area
		love.graphics.reset()
		love.graphics.rectangle("line", screen_w/2 - 10*32,  screen_h/2 - 8*32, 20*32, 16*32)
		local label = "CS2D visible area"
		local labelsize = love.graphics.getFont():getWidth(label)
		love.graphics.print(label, screen_w/2 - labelsize/2, screen_h/2 - 8*32)
		
		
		-- Draw map limits
		love.graphics.setColor(0,1,0,1)
		local label = "CS2D map limit"
		love.graphics.print(label, center_x + 4, center_y - 18)
		love.graphics.rectangle("line", center_x, center_y, (mapfile.width+1)*32, (mapfile.height+1)*32)
		
		-- Draw grid
		love.graphics.setColor(0,1,0,1)
	end	

end
--[[---------------------------------------------------------
	Load editor module UI
--]]---------------------------------------------------------
love.filesystem.load("interface/editor.lua")()

--[[---------------------------------------------------------
	
--]]---------------------------------------------------------

print("Maploader module loaded.")

