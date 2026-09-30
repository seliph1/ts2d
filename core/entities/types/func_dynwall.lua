--[[-----------------------------------------------------------------------------
	-- Func_DynWall Entity Class (Type 71)
	-- Encapsulates dynamic wall / door behavior, state toggling, and rendering.
	-- Encapsulates dynamic wall / door behavior, modes (wall, obstacle, floor, shadows),
	-- crushing players on close, and rendering.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local FuncDynWall = setmetatable({}, { __index = Entity })
FuncDynWall.__index = FuncDynWall

function FuncDynWall.new(data)
	local self = Entity.new(data)
	setmetatable(self, FuncDynWall)
	self.state = 0 -- 0 = activated (closed/solid/visible), 1 = deactivated (open/passable/hidden)
	return self
end

--- Checks if this DynWall is solid for player physics movement
--- Mode 0 (Wall), Mode 1 (Obstacle), Mode 2 (Wall w/o Shdw), Mode 3 (Obstacle w/o Shdw) are solid.
--- Mode 4 (Floor+Tile Behavior) behaves like a floor and is not solid to players.
function FuncDynWall:isSolid(context)
	local state = (context and self:getState(context)) or self.state
	if state ~= 0 then return false end
	local mode = self:getInt(2)
	-- Mode 4 is floor level, not solid to players
	if mode == 4 then return false end
	return true
end

--- Checks if this DynWall blocks bullet hitscan / projectiles.
--- Mode 0 (Wall) and Mode 2 (Wall w/o Shdw.) block bullets.
--- Mode 1 (Obstacle), Mode 3 (Obstacle w/o Shdw.), and Mode 4 (Floor) allow bullets to pass over.
function FuncDynWall:blocksBullets(context)
	local state = (context and self:getState(context)) or self.state
	if state ~= 0 then return false end
	local mode = self:getInt(2)
	return mode == 0 or mode == 2
end

--- Returns shadow height for the heightmap shader.
--- Mode 0 (Wall): 1.0 (casts wall shadow)
--- Mode 1 (Obstacle): 0.5 (casts lower obstacle shadow)
--- Mode 2 (Wall w/o Shdw.): 0.0 (no shadow)
--- Mode 3 (Obstacle w/o Shdw.): 0.0 (no shadow)
--- Mode 4 (Floor+Tile Behavior): 0.0 (no shadow)
function FuncDynWall:getHeightMapHeight(context)
	local state = (context and self:getState(context)) or self.state
	if state ~= 0 then return 0.0 end
	local mode = self:getInt(2)
	if mode == 0 then
		return 1.0
	elseif mode == 1 then
		return 0.5
	else
		return 0.0
	end
end

--- Called at round start: all DynWalls start activated and visible
---@param server table|nil
function FuncDynWall:onRoundStart(server)
	self.state = 0
	if server then
		self:syncState(server)
	end
end

--- Toggles open/closed state of the DynWall.
--- When closing (transitioning to state 0), handles "Close only if not blocked" and crushing players.
---@param activator table|nil Player who triggered the activation
---@param source_id number|nil Peer ID of the activator
---@param server table|nil Server instance
function FuncDynWall:onToggle(activator, source_id, server)
	local target_state = (self.state == 1) and 0 or 1

	-- If the wall is attempting to close / activate (target_state == 0)
	if target_state == 0 then
		local w = math.max(1, self:getInt(4)) * 32
		local h = math.max(1, self:getInt(5)) * 32
		local wx = self.x * 32
		local wy = self.y * 32
		local close_if_not_blocked = (self:getInt(3) == 1)
		local mode = self:getInt(2)

		-- Find living players inside the wall tile area
		local players = (server and server.share and server.share.players) or {}
		local overlapping_players = {}

		for peer_id, p in pairs(players) do
			if p and p.h and p.h > 0 and p.x and p.y then
				-- Check if player position is within the DynWall bounds
				if p.x >= wx and p.x < wx + w and p.y >= wy and p.y < wy + h then
					table.insert(overlapping_players, { id = peer_id, player = p })
				end
			end
		end

		-- If "Close only if not blocked" is set and any player is inside, abort closing!
		if close_if_not_blocked and #overlapping_players > 0 then
			return
		end

		-- Activate and close the wall
		self.state = 0
		self:syncState(server)

		-- Crushing: activating a solid wall/obstacle (modes 0, 1, 2, 3) on top of a player kills them!
		if mode ~= 4 and #overlapping_players > 0 and server then
			for _, entry in ipairs(overlapping_players) do
				local peer_id = entry.id
				local p = entry.player
				if p and p.h and p.h > 0 then
					if server.hit then
						server.hit(peer_id, source_id or 0, 0, 1000)
					end
					-- Ensure victim is dead even if hit was intercepted
					if p.h > 0 and server.die then
						p.h = 0
						server.die(peer_id, source_id or 0, 0)
					end
				end
			end
		end
	else
		-- Deactivating / opening the wall
		self.state = 1
		self:syncState(server)
	end
end

function FuncDynWall:getPhysicsBody(map, client)
	local w = math.max(1, self:getInt(4)) * 32
	local h = math.max(1, self:getInt(5)) * 32
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = w,
		h = h,
		isSolid = self:isSolid(client),
		isTrigger = false,
	}
end

function FuncDynWall:draw(mapengine, client)
	local state = (client and self:getState(client)) or self.state
	if state ~= 0 then return end

	local w = math.max(1, self:getInt(4))
	local h = math.max(1, self:getInt(5))

	if client.debug_level == 2 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("line", self.x * 32, self.y * 32, w * 32, h * 32)
	end

	local tile_index = self:getInt(1)
	local mapdata = mapengine._mapdata
	local tile_img = mapdata and mapdata.gfx and mapdata.gfx.tile and mapdata.gfx.tile[tile_index]

	if tile_img then
		local alpha_str = self:getStr(1)
		local alpha = 1.0
		if alpha_str and alpha_str ~= "" then
			local num = tonumber(alpha_str)
			if num then
				if num <= 0 then
					alpha = math.max(0.0, math.min(1.0, 1.0 + num))
				else
					alpha = math.max(0.0, math.min(1.0, 1.0 - num))
				end
			end
		end

		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.setBlendMode("alpha")
		for tx = 0, w - 1 do
			for ty = 0, h - 1 do
				love.graphics.draw(tile_img, (self.x + tx) * 32, (self.y + ty) * 32)
			end
		end
	end
end

return FuncDynWall
