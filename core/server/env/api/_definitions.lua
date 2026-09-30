---@meta
-- CS2D API Global Definitions for Lua Language Server
-- These globals are injected by the sandbox environment into server.lua and map scripts

--------------------------------------------------------------------------------
-- AI Functions
--------------------------------------------------------------------------------

---@class GameModes: table
gamemodes = {}

---@param id integer Player ID
---@param x number X coordinate
---@param y number Y coordinate
function ai_aim(id, x, y) end

---@param id integer Player ID
function ai_attack(id) end

---@param id integer Player ID
---@param type integer Build type
---@param x number X coordinate
---@param y number Y coordinate
---@param rot number Rotation
function ai_build(id, type, x, y, rot) end

---@param id integer Player ID
---@param item integer Item type
function ai_buy(id, item) end

---@param id integer Player ID
---@param mode integer Debug mode
function ai_debug(id, mode) end

---@param id integer Player ID
function ai_drop(id) end

---@param id integer Player ID
---@param x number X coordinate
---@param y number Y coordinate
---@param range number Search range
---@param mode integer Search mode
---@return integer target_id
function ai_findtarget(id, x, y, range, mode) end

---@param x1 number Start X
---@param y1 number Start Y
---@param x2 number End X
---@param y2 number End Y
---@return boolean
function ai_freeline(x1, y1, x2, y2) end

---@param id integer Player ID
---@param x number X coordinate
---@param y number Y coordinate
---@param mode integer Movement mode
function ai_goto(id, x, y, mode) end

---@param id integer Player ID
---@param target_id integer Target player ID
function ai_iattack(id, target_id) end

---@param id integer Player ID
---@param direction integer Movement direction
function ai_move(id, direction) end

---@param id integer Player ID
---@param radio_message string Radio message
function ai_radio(id, radio_message) end

---@param id integer Player ID
function ai_reload(id) end

---@param id integer Player ID
function ai_respawn(id) end

---@param id integer Player ID
---@param rotation number Rotation angle
function ai_rotate(id, rotation) end

---@param id integer Player ID
---@param text string Message text
function ai_say(id, text) end

---@param id integer Player ID
---@param text string Message text
function ai_sayteam(id, text) end

---@param id integer Player ID
---@param type integer Weapon type
function ai_selectweapon(id, type) end

---@param id integer Player ID
function ai_spray(id) end

---@param id integer Player ID
function ai_use(id) end

--------------------------------------------------------------------------------
-- Hook Functions
--------------------------------------------------------------------------------

---@param hookname string Hook name
---@param func string Function name to call
function addhook(hookname, func) end

---@param hook_name string Hook name
---@param function_name string Function name to remove
function freehook(hook_name, function_name) end

---@param hook_name string Hook name
---@param state boolean Hook state
function sethookstate(hook_name, state) end

---@param milliseconds integer Timer interval
---@param function_name string Function to call
---@param params string Optional parameters
---@param count integer Number of times to run (-1 = infinite)
---@return integer timer_id The ID of the created timer
function timer(milliseconds, function_name, params, count) end

---@param timer_id integer Timer ID to free
function freetimerid(timer_id) end

---@param key string Key to bind
---@param command string Command to execute
function addbind(key, command) end

---@param key string Key to remove all binds from
function removeallbinds(key) end

---@param key string Key
---@param command string Command to remove
function removebind(key, command) end

--------------------------------------------------------------------------------
-- Image Functions
--------------------------------------------------------------------------------

---@param path string Image path
---@param x number X position
---@param y number Y position
---@param mode integer Display mode
---@return integer image_id
function image(path, x, y, mode) end

---@param image_id integer Image ID
---@param alpha number Alpha value (0-1)
function imagealpha(image_id, alpha) end

---@param image_id integer Image ID
---@param blend_mode integer Blend mode
function imageblend(image_id, blend_mode) end

---@param image_id integer Image ID
---@param r integer Red (0-255)
---@param g integer Green (0-255)
---@param b integer Blue (0-255)
function imagecolor(image_id, r, g, b) end

---@param image_id integer Image ID
---@param frame integer Frame number
function imageframe(image_id, frame) end

---@param image_id integer Image ID
---@param mode integer Hit zone mode
---@param x number X offset
---@param y number Y offset
---@param width number Width
---@param height number Height
function imagehitzone(image_id, mode, x, y, width, height) end

---@param image_id integer Image ID
---@param parameter string Parameter name
function imageparam(image_id, parameter) end

---@param image_id integer Image ID
---@param x number X position
---@param y number Y position
---@param rotation number Rotation angle
function imagepos(image_id, x, y, rotation) end

---@param image_id integer Image ID
---@param scale_x number X scale
---@param scale_y number Y scale
function imagescale(image_id, scale_x, scale_y) end

---@param image_id integer Image ID
function freeimage(image_id) end

--------------------------------------------------------------------------------
-- Tween Functions
--------------------------------------------------------------------------------

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param alpha number Target alpha
function tween_alpha(image_id, duration, alpha) end

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param frame_start integer Start frame
---@param frame_end integer End frame
function tween_animate(image_id, duration, frame_start, frame_end) end

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param r integer Target red
---@param g integer Target green
---@param b integer Target blue
function tween_color(image_id, duration, r, g, b) end

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param frame integer Target frame
function tween_frame(image_id, duration, frame) end

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param x number Target X
---@param y number Target Y
function tween_move(image_id, duration, x, y) end

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param rotation number Target rotation
function tween_rotate(image_id, duration, rotation) end

---@param image_id integer Image ID
---@param rotation_speed number Rotation speed
function tween_rotateconstantly(image_id, rotation_speed) end

---@param image_id integer Image ID
---@param duration integer Duration in ms
---@param scale_x number Target X scale
---@param scale_y number Target Y scale
function tween_scale(image_id, duration, scale_x, scale_y) end

--------------------------------------------------------------------------------
-- Entity Functions
--------------------------------------------------------------------------------

---@param x number X coordinate
---@param y number Y coordinate
---@param name string Entity name
function entity(x, y, name) end

---@param entity_type? number
---@return table
function entitylist(entity_type) end

---@param entity_name string Entity name
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean
function inentityzone(entity_name, x, y) end

---@param entity_name string Entity name
---@return number x, number y
function randomentity(entity_name) end

---@param entity_name string Entity name
---@param key string AI state key
---@param value any AI state value
function setentityaistate(entity_name, key, value) end

--------------------------------------------------------------------------------
-- Hostage Functions
--------------------------------------------------------------------------------

---@param hostage_id integer Hostage ID
---@param parameter string Parameter name
---@return any
function hostage(hostage_id, parameter) end

---@param x number X coordinate
---@param y number Y coordinate
---@param range number Search range
---@return integer hostage_id
function closehostage(x, y, range) end

---@return integer hostage_id
function randomhostage() end

--------------------------------------------------------------------------------
-- Object Functions
--------------------------------------------------------------------------------

---@param object_id integer Object ID
---@param parameter string Parameter name
---@return any
function object(object_id, parameter) end

---@param x number X coordinate
---@param y number Y coordinate
---@param type integer Object type
---@return integer object_id
function objectat(x, y, type) end

---@param type_id integer Type ID
---@param parameter string Parameter name
---@return any
function objecttype(type_id, parameter) end

---@param x number X coordinate
---@param y number Y coordinate
---@param range number Search range
---@return table
function closeobjects(x, y, range) end

--------------------------------------------------------------------------------
-- Item Functions
--------------------------------------------------------------------------------

---@param item_id integer Item ID
---@param x number X coordinate
---@param y number Y coordinate
---@param type integer Item type
function item(item_id, x, y, type) end

---@param type_id integer Type ID
---@param parameter string Parameter name
---@return any
function itemtype(type_id, parameter) end

---@param x number X coordinate
---@param y number Y coordinate
---@param range number Search range
---@return table
function closeitems(x, y, range) end

--------------------------------------------------------------------------------
-- Projectile Functions
--------------------------------------------------------------------------------

---@param projectile_id integer Projectile ID
---@param parameter string Parameter name
---@return any
function projectile(projectile_id, parameter) end

---@param type integer Projectile type
---@param player_id integer Player ID
---@return table
function projectilelist(type, player_id) end

--------------------------------------------------------------------------------
-- Messaging Functions
--------------------------------------------------------------------------------

---@param text string Message text
function msg(text) end

---@param player_id integer Player ID
---@param text string Message text
function msg2(player_id, text) end

---@param player_id integer Player ID
---@param title string Menu title
---@param buttons string Menu buttons
function menu(player_id, title, buttons) end

---@param ... any Values to print
function print(...) end

--------------------------------------------------------------------------------
-- Parsing and Commands
--------------------------------------------------------------------------------

---@param text? string Command to parse
function parse(text) end

---@param category string Function category
---@return table
function funcs(category) end

---@param var_name string Variable name
---@return any
function vars(var_name) end

--------------------------------------------------------------------------------
-- Checksum Functions
--------------------------------------------------------------------------------

---@param filename string File path
---@return string
function checksumfile(filename) end

---@param str string String to checksum
---@return string
function checksumstring(str) end

--------------------------------------------------------------------------------
-- Game and Map Info
--------------------------------------------------------------------------------

---@param parameter string Parameter name
---@return any
function game(parameter) end

---@param parameter string Parameter name
---@return any
function map(parameter) end

---@param x integer Tile X
---@param y integer Tile Y
---@param parameter string Parameter name
---@return any
function tile(x, y, parameter) end

---@param x integer Tile X
---@param y integer Tile Y
---@param property string Property name
---@return any
function tileproperty(x, y, property) end

--------------------------------------------------------------------------------
-- Player Proximity
--------------------------------------------------------------------------------

---@param x number X coordinate
---@param y number Y coordinate
---@param range number Search range
---@param team integer Team filter (optional)
---@return table
function closeplayers(x, y, range, team) end

---@param x number X coordinate
---@param y number Y coordinate
---@param range number Search range
---@param team integer Team filter (optional)
---@return boolean
function hascloseplayers(x, y, range, team) end

--------------------------------------------------------------------------------
-- Fog of War
--------------------------------------------------------------------------------

---@param x number X coordinate
---@param y number Y coordinate
---@param player_id integer Player ID
---@return boolean
function fow_in(x, y, player_id) end

--------------------------------------------------------------------------------
-- HTTP Requests
--------------------------------------------------------------------------------

---@param url string URL
function reqcld(url) end

---@param url string URL
---@param method string HTTP method
---@param params string Parameters
function reqhttp(url, method, params) end

--------------------------------------------------------------------------------
-- Stats
--------------------------------------------------------------------------------

---@param player_id integer Player ID
---@param stat_name string Stat name
---@return any
function stats(player_id, stat_name) end

---@param player_id integer Player ID
---@param stat_name string Stat name
---@return any
function steamstats(player_id, stat_name) end

--------------------------------------------------------------------------------
-- Player Functions
--------------------------------------------------------------------------------

---@param player_id integer Player ID (use 0 for table functions)
---@param parameter string Parameter name
---@param ... any Optional parameters
---@return any
function player(player_id, parameter, ...) end

---@param player_id integer Player ID
---@param type integer Ammo type
---@return integer
function playerammo(player_id, type) end

---@param player_id integer Player ID
---@return table
function playerweapons(player_id) end
