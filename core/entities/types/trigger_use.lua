--[[-----------------------------------------------------------------------------
	-- Trigger_Use Entity Class (Type 93)
	-- Encapsulates Key Use (E) trigger activation area.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerUse = setmetatable({}, { __index = Entity })
TriggerUse.__index = TriggerUse

-- Alignment rotations (0=top, 1=bottom, 2=left, 3=right)
local ALIGNMENT_ROTATION = {
	[0] = 0,               -- Top (attached to top wall)
	[1] = math.pi,         -- Bottom (attached to bottom wall)
	[2] = 3 * math.pi / 2, -- Left (attached to left wall)
	[3] = math.pi / 2,     -- Right (attached to right wall)
}

-- Light colors for lighted and alarm buttons (11..17)
local LIGHT_COLORS = {
	[11] = { 1.0, 0.2, 0.2 },  -- Lighted Red
	[12] = { 0.2, 1.0, 0.2 },  -- Lighted Green
	[13] = { 0.2, 0.6, 1.0 },  -- Lighted Blue
	[14] = { 1.0, 0.95, 0.2 }, -- Lighted Yellow
	[15] = { 1.0, 1.0, 1.0 },  -- Lighted White
	[16] = { 1.0, 0.2, 0.2 },  -- Red Lighted Alarm
	[17] = { 0.2, 1.0, 0.2 },  -- Green Lighted Alarm
}

function TriggerUse.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerUse)
	self.disabled = false
	self.state = 0
	self.initial_state = 0
	self.initial_disabled = false

	-- Lazily initialized in draw if love.graphics exists
	if love.graphics then
		self.storage[1] = love.graphics.newQuad(0, 0, 32, 32, 320, 32)
	end
	return self
end

function TriggerUse:onRoundStart(server)
	self.state = 0
	self.disabled = false
	if server then
		self:syncState(server)
	end
end

function TriggerUse:getPhysicsBody(map)
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = 32,
		h = 32,
		isSolid = false,
		isTrigger = true,
	}
end

function TriggerUse:onToggle(activator, source_id, server, active_set, depth)
	if server and server.is_starting_round then
		return
	end
	self.state = (self.state == 1) and 0 or 1
	self.disabled = (self.state == 1)
	if server then
		self:syncState(server)
	end
end

function TriggerUse:draw(map, client)
	local button_id = self:getInt(1)
	-- 0 = None/Invisible: do not draw anything
	if button_id <= 0 then
		return
	end

	local buttons_img = map:getImage("gfx/sprites/buttons.bmp")
	if not buttons_img then return end

	local quads = self.storage[1]
	if not quads and love.graphics then
		quads = love.graphics.newQuad(0, 0, 32, 32, 320, 32)
		self.storage[1] = quads
	end
	if not quads then return end

	-- alignment: 0=top, 1=bottom, 2=left, 3=right
	local align = self:getInt(2)
	local rot = ALIGNMENT_ROTATION[align] or 0

	local cx = self.x * 32 + 16
	local cy = self.y * 32 + 16

	-- Base button frame:
	-- Buttons 1..10 (up to Lever B) correspond directly to frames 1..10 of buttons.bmp.
	-- Buttons 11+ (Lighted and Alarms) use frame 2 (Gray+Small) as the base button.
	local base_frame = (button_id <= 10) and button_id or 2
	quads:setViewport(32 * (base_frame - 1), 0, 32, 32, 320, 32)

	love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
	love.graphics.draw(buttons_img, quads, cx, cy, rot, 1, 1, 16, 16)

	-- Lighted buttons (11..15) and Alarms (16..17) with additive flare
	if button_id >= 11 then
		local is_active = not self.disabled and self.state ~= 1
		if is_active then
			local flare_img = map:getImage("gfx/sprites/flare.png")
			if flare_img then
				local color = LIGHT_COLORS[button_id] or { 1.0, 1.0, 1.0 }

				-- Gray+Small bulb is near the mounting wall (~12px from tile center)
				local bulb_dist = 12
				local fx = cx + math.sin(rot) * bulb_dist
				local fy = cy - math.cos(rot) * bulb_dist

				local flare_rot = 0
				local flare_scale = 0.6
				local flare_alpha = 0.85

				-- 16: Red Lighted Alarm, 17: Green Lighted Alarm (piscando e girando)
				if button_id == 16 or button_id == 17 then
					local t = love.timer.getTime()
					-- Girando (rotating)
					flare_rot = t * 4
					-- Piscando (blinking / pulsing)
					local pulse = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 8))
					flare_alpha = pulse
					flare_scale = 0.6 * (0.8 + 0.3 * pulse)
				end

				love.graphics.setBlendMode("add")
				love.graphics.setColor(color[1] * flare_alpha, color[2] * flare_alpha, color[3] * flare_alpha, flare_alpha)
				love.graphics.draw(flare_img, fx, fy, flare_rot, flare_scale, flare_scale, 32, 32)
				love.graphics.setBlendMode("alpha")
			end
		end
	end
end

return TriggerUse
