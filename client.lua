--- Client base framework
local b				= require "lib.battery"
local Map 			= require "mapengine"
local Bump			= require "lib.bump"
local client 		= require "lib.cs"
local serpent 		= require "lib.serpent"

---@class userdata
---Home class that holds player local client data
local home = client.home
---@class Share
--- @field bullets table
--- @field players table
--- @field items table
--- @field scores table
--- Table that gets info from server
local share = client.share

---@class Share
---Table that holds similar data from server, gets updated after server tick
local share_local = client.share_local

---@class Share
---Table that holds interpolated data
local share_lerp = client.share_lerp
share_lerp.players 	= {}
share_lerp.entities = {}
share_lerp.bullets 	= {}
share_lerp.items 	= {}
share_lerp.scores 	= {}

client.version 			= "v1.0.1"
client.enabled 			= true
client.width 			= 800
client.height 			= 600
client.lerp_speed 		= 30
client.debug_level		= 0
client.sendRate 		= 35
client.scale 			= false
client.mode 			= "lobby"
client.canvas 			= love.graphics.newCanvas()
client.map 				= Map.new(50, 50)
client.world			= Bump.new(64)
client.content 			= require "enum"

local modules = {
	"actions";
	"binds";
	"camera";
	"loader";
	"callbacks";
	"callbacks_netcode";
}
for index, module in pairs(modules) do
	require(module)(client)
end

function client.snapshot_lerp(dt)
	local lerp_flags = {
		x = true,
		y = true,
		targetX = true,
		targetY = true,
	}

	local lerp_fields = {
		players = true
	}

	for player_id, player in pairs(share.players) do
		share_lerp.players[player_id] = share_lerp.players[player_id] or {}

		for property, value in pairs(player) do
			if lerp_flags[property] then
				local lerp_value = share_lerp.players[player_id][property] or value
				-- Apply lerp
				share_lerp.players[player_id][property] = b.lerp(lerp_value, value, client.lerp_speed * dt)
			else
				share_lerp.players[player_id][property] = value
			end
		end
	end
end

--- Move player in smooth intervals
---@param peer_id number
function client.predict_player(peer_id, dt) -- `home` is used to apply controls if given
	-- Check if its own player id, and is connected
	if not( client.id == peer_id and client.joined ) then return end

	-- Store player object
	local player_local = share_local.players[peer_id]
	local player = share.players[peer_id]

	-- Check if the player object exists
	if not (player and player_local) then return end

	-- Apply input results to player
	player.x = player_local.x
	player.y = player_local.y
	for index, inputState in client.inputCache:walk() do
		client.apply_input_to_player(inputState.inputStream, client.id)
	end
end

function client.predict_action(peer_id, dt)
	-- Check if its own player id, and is connected
	if not( client.id == peer_id and client.joined ) then return end

	-- Store player object
	local player_local = share_local.players[peer_id]
	local player = share.players[peer_id]

	-- Check if the player object exists
	if not (player and player_local) then return end

	--home._attack1Timer = math.max(0, home._attack1Timer - dt)
	if home._attack1Timer > 0 then
		home._attack1Timer = home._attack1Timer - dt
	end
	if client.attribute("attack") == true then
		-- Increment timer if player is pressing attack
		-- Dont go below 0
		while home._attack1Timer <= 0 do
			local cooldown = client.attack(client.id, true)
			if cooldown > 0 then
				home._attack1Timer = home._attack1Timer + cooldown
			end
		end
	end

end

local bulletsound = love.audio.newSource("sfx/weapons/ak47.wav", "static")
local m3 = love.audio.newSource("sfx/weapons/m3.wav", "static")
local xm = love.audio.newSource("sfx/weapons/xm1014.wav", "static")

function client.attack(peer_id, local_data)
	--local player = client.share_lerp.players[peer_id]
	local player = client.share.players[peer_id]
	if not player then return 1 end -- Return 1 second cooldown

	-- Get player held item
	local itemheld = client.get_item_held(peer_id)
	local itemdata = client.get_item_data(itemheld)
	if not itemdata then return 1 end -- Return 1 second cooldown for no item

	-- Get player position and target
	local player_x = player.x
	local player_y = player.y
	local mouse_x = player.targetX
	local mouse_y = player.targetY

	-- Get item attack mode
	local attack_data = itemdata.attack
	if not attack_data then return 1 end
	local args = {}
	for arg in attack_data:gmatch("[^%s:]+") do
		table.insert(args, arg)
	end
	local action = table.remove(args, 1)
	if not action then return 1 end

	-- Get own local data for mouse targeting
	if local_data == true then
		mouse_x = client.attribute("targetX")
		mouse_y = client.attribute("targetY")
	else
		-- Dont run this if server is requesting our peer_id animation in our client.
		if peer_id == client.id then return 0 end
	end

	if action == "bullet" then
		local spawn = tonumber( args[1] ) or 1
		local spread = tonumber( args[2] ) or 1
		local angle = math.atan2(mouse_y - client.height/2, mouse_x - client.width/2)
		-- In CS2D the range value is multiplied by 3
		local distance = itemdata.range * 3
		--local rpm = itemdata.rpm or 200 -- 0.3
		local frame_delay = itemdata.frame_delay or 22
		-- Actions per second
		local seconds = frame_delay / 60

		local offset = 20
		local offset_x = player_x + math.cos(angle) * offset
		local offset_y = player_y + math.sin(angle) * offset

		if itemheld == 10 then
			m3:setVolume(0.1)
			m3:stop()
			m3:play()
		elseif itemheld == 11 then
			xm:setVolume(0.1)
			xm:stop()
			xm:play()
		else
			bulletsound:setVolume(0.1)
			bulletsound:stop()
			bulletsound:play()
		end

		-- Simulate locally that we fired a weapon
		if spawn == 1 then
			-- Skip with single shot
			client.fire(offset_x, offset_y, angle, distance, client.id)
			return seconds
		end

		-- Multishot (from shotguns, etc.)
		local half = math.floor(spawn/2)
		for i = 1, spawn do
			local subangle = angle + math.rad(i * spread - half * spread)
			client.fire(offset_x, offset_y, subangle, distance, client.id)
		end
		return seconds
	end

	return 1
end

---@param start_x number
---@param start_y number
---@param distance number
---@param angle number
---@param peer_id number
function client.fire(start_x, start_y, angle, distance, peer_id)
	peer_id = peer_id or 0
    angle = angle or 0
	distance = distance or (32 * 10)

	local target_x = start_x + math.cos(angle) * distance
	local target_y = start_y + math.sin(angle) * distance

	local hit_x, hit_y, hit = client.raycast(start_x, start_y, target_x, target_y)

	local hit_distance = distance
	if hit then
		local rand = math.random()
		if rand < 0.80 then
			client.map:spawn_effect("whitesmoke", hit_x, hit_y, {
				setDirection = angle + math.pi
			})
		elseif rand >= 0.80 and rand < 0.90 then
			client.map:spawn_effect("blacksmoke", hit_x, hit_y)
		elseif rand >= 0.90 then
			client.map:spawn_effect("sparkle", hit_x, hit_y, {
				setDirection = angle + math.pi
			})
		end

		local dx = hit_x - start_x
		local dy = hit_y - start_y
		hit_distance = math.sqrt( dx*dx + dy*dy )

	end
	local half = hit_distance/2
	local half_x = start_x + math.cos(angle)*half
	local half_y = start_y + math.sin(angle)*half

	-- Create less particle as vector goes shorter
	client.map:spawn_effect("hitscan", half_x, half_y, {
		setDirection = angle,
		setEmissionArea = {"uniform", half, 1, angle, false},
		emitAtStart = math.ceil( hit_distance/distance * 10),
	})

	client.map:spawn_effect("trail", start_x, start_y, {
		angle = angle,
		scaleX = (hit_distance)/32,
		--offsetX = -10,
	})
end


function client.discard(peer_id, item_type)
	if peer_id == client.id then
		local player = share.players[peer_id]
		if not player then return end

		local ui = require "core.interface.ui"
		ui.weaponselect:queryItems(player.i)
	end
end

function client.collect(peer_id, item_type)
	if peer_id == client.id then
		local player = share.players[peer_id]
		if not player then return end

		local ui = require "core.interface.ui"
		ui.weaponselect:queryItems(player.i)
	end
	--print("collected:", peer_id, item_type)
end

function client.select(peer_id, item_type)
	if peer_id == client.id then
		local player = share.players[peer_id]
		if not player then return end

		local ui = require "core.interface.ui"
		ui.weaponselect:queryItemheld(item_type)
	end

	--print("selected:", peer_id, item_type)
end

function client.get_item_held(peer_id)
	local player = share.players[peer_id]
	if not player then return 0 end
	local itemheld = player.ih or 0
	local itemdata = client.content.itemlist[itemheld]
	return itemheld, itemdata
end

function client.get_item_data(item_type)
	local itemdata = client.content.itemlist[item_type]
	if itemdata then
		return itemdata
	else
		return client.content.itemdata_default
	end
end

function client.apply_input_to_player(input, peer_id)
	local player = share.players[peer_id]
	local map = client.map
	if not (player and map) then return end

	-- Initialize forces
	local h, v, w = 0, 0, 1
	if input["forward"] then v = -1 	end
	if input["back"] 	then v =  1 	end
	if input["left"] 	then h = -1 	end
	if input["right"] 	then h =  1 	end
	if input["walk"] 	then w =  0.5 	end

	if v ~= 0 or h ~= 0 then
		-- Calculate magnitude
		local mag = math.sqrt(v*v + h*h)
		local scale
		if mag == 0 then
			v, h = 0, 0
		else
			scale = 1/mag
			v, h = v * scale, h * scale
		end
		client.apply_forces_to_player(peer_id, v, h, w)
	end
end

function client.apply_forces_to_player(peer_id, v, h, w)
	local player = share.players[peer_id]
	local map = client.map
	if not (player and map) then return end

	-- Multiply vector by velocity and walk factor
	-- and store the forces
	local dx = player.s * h * w
	local dy = player.s * v * w

	-- Slide square object into the map
	local future_x, future_y = map:moveWithSliding(player.size, player.x, player.y, dx, dy)

	-- Get the player half size
	local half = math.floor(player.size/2)

	-- Calculate player colliding with other objects
	client.world:update(player, player.x - half, player.y - half, player.size, player.size)

	-- Apply the collision result
	local filter = client.player_collision_filter
	local current_x, current_y, collisions, length = client.world:move(player, future_x - half, future_y - half, filter)
	player.x = current_x + half
	player.y = current_y + half

	-- Collision handler
	for i = 1, length do
		local collision = collisions[i]
		local _type 	= collision.type
		local object 	= collision.other
		local itemRect 	= collision.itemRect
		local otherRect = collision.otherRect
		local move 		= collision.move
		local normal 	= collision.normal
		local ti 		= collision.ti
		local overlaps 	= collision.overlaps
	end
end

function client.player_collision_filter(item, other)
	if item.ct == 1 then
		if other.ct == 2 then
			return "cross" -- Ignore physics and register the collision
		elseif other.ct == 1 then
			return "slide" -- Apply physics to other players
		end
	end
end

--- Cast a ray that collides with map, players, items and entities. ---
--- Returns the first object that collided with this segment
function client.raycast(x1, y1, x2, y2)
	if not client.map then return false end

	local start_x, start_y = x1, y1
	local impact_x, impact_y, hit = client.map:hitscan(x1, y1, x2, y2)

	local item_info, len = client.world:querySegmentWithCoords(start_x, start_y, impact_x, impact_y)
	for i=1, len do
		local info = item_info[i]

		-- Update the values for the first object impacted
		impact_x = info.x1
		impact_y = info.y1
		hit = true
		-- Breaks on the first impact
		break
	end

	return impact_x, impact_y, hit
end

--- Cast a ray that dont collide with anything, but register intersection
--- with map, players, items and entities.
--- Returns a list of tiles and objects that intersected with this segment
function client.raycast_t(x1, y1, x2, y2)
end

function client.draw_splash(ox, oy)
	local splash_art = client.gfx.ui["gfx/splash.bmp"]
	local splash_width = love.graphics.getWidth() / splash_art:getWidth()
	local splash_height = love.graphics.getHeight() / splash_art:getHeight()
	love.graphics.draw(splash_art, ox, oy, 0, splash_width, splash_height)
end

function client.render()
	love.graphics.push('all')
	love.graphics.setCanvas(client.canvas)

    -- Center display
    local ox = 0.5 * (love.graphics.getWidth() - client.width)
	local oy = 0.5 * (love.graphics.getHeight() - client.height)

	-- Set the boundaries to render engine
	love.graphics.setScissor(ox, oy, client.width, client.height)

	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.map:draw_floor()
		--client.map:draw_entities()
	end

    if client.joined then
		-- Draw items on the ground
		client.map:draw_items(share, client)
		-- Player render
		client.map:draw_players(share_lerp, client)
    end

	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.map:draw_ceiling()
		client.map:draw_effects()
	end

	-- Resets scissoring and canvas
	love.graphics.pop()
	love.graphics.setCanvas()
end

--- Returns the client object to the main code block
return client