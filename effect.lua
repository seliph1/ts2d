local effect = {}
local LG = love.graphics
local serpent = require "lib.serpent"

effect.queue = {}
effect.list = {}
effect.imagequeue = {}

local function lerp(a, b, t)
	return a + (b - a) * t
end

function effect.register(particle, name, options)
	if type(particle) == "function" then
		effect.list[name] = particle()
	elseif type(particle) == "table" then
		effect.list[name] = particle
	end
end

function effect.new(name, x, y, args)
	if not effect.list[name] then
		print(string.format("effect %s not found.", name))
		return
	end

	if effect.list[name].type == "particle" then
		local effect_id, new_effect =  effect.new_particle(name, x, y, args)
		return effect_id, new_effect
	end

	if effect.list[name].type == "image" then
		effect.new_image(name, x, y, args)
	end
end

function effect.new_particle(name, x, y, args)
	local effect_instance = effect.list[name]
	local new_effect = {}

	args = args or {}

	for index, attribute in pairs(effect_instance) do
		if type(index)~="number" then
			new_effect[index] = attribute
		end
	end

	for _, particle in ipairs(effect_instance) do
		local new_particle = {}
		for k,v in pairs(particle) do
			-- Copy the particle data from original effect
			if k ~= "system" then
				new_particle[k] = v
			end
		end
		-- Clone the particle system with a new fresh seed
		new_particle.system = particle.system:clone()
		table.insert(new_effect, new_particle)

		-- Add new args if possible
		for k,v in pairs(args) do
			if new_particle.system[k] then
				local object = new_particle.system
				if type(v) == "table" then
 					new_particle.system[k](object, unpack(v))
				else
					new_particle.system[k](object, v)
				end
			elseif new_particle[k] then
				if type(v) == "table" then
 					new_particle[k] = {unpack(v)}
				else
					new_particle[k] = v
				end
			end
		end

		-- Start emitting the particles
		if effect_instance.global then
			x, y = 0, 0
		else
			x = x + new_particle.x
			y = y + new_particle.y
		end
		new_particle.system:setPosition(x, y)
		new_particle.system:start()
		for step = 1, new_particle.kickStartSteps do
			new_particle.system:update(new_particle.kickStartDt)
		end
		new_particle.system:emit(new_particle.emitAtStart)
	end
	--local effect_id = table.insert(effect.queue, new_effect)
	local effect_id = #effect.queue+1
	effect.queue[effect_id] = new_effect
	return effect_id, new_effect
end

function effect.new_image(name, x, y, args)
	local new_instance = {}
	local instance = effect.list[name]

	for index, attribute in pairs(instance) do
		if type(index) ~= "number" then
			new_instance[index] = attribute
		end
	end

	--print(#new_instance)
	for _, image in ipairs(instance) do
		local new_image = {}
		for k, v in pairs(image) do
			new_image[k] = v
		end
		table.insert(new_instance, new_image)


		-- Add new args if possible
		for k,v in pairs(args) do
			if new_image[k] then
				if type(v) == "table" then
 					new_image[k] = { unpack(v) }
				else
					new_image[k] = v
				end
			end
		end

		-- Emits the image x, y 
		if instance.global then
			x, y = 0, 0
		else
			x = x + new_image.x
			y = y + new_image.y
		end
		new_image.x = x
		new_image.y = y
	end
	local image_id = #effect.imagequeue + 1

	effect.imagequeue[image_id] = new_instance
	return image_id, new_instance
end

function effect.dispose(effect_id)
	local effect_instance = effect.queue[effect_id]
	for _, particle in ipairs(effect_instance) do
		particle:stop()
	end
	effect.queue[effect_id] = nil
end

function effect.update(dt)
	for effect_id, effect_instance in pairs(effect.queue) do
		for _, particle in ipairs(effect_instance) do
			local stopped_instances = 0
			if particle.system:isStopped() and particle.system:getCount() == 0 then
				stopped_instances = stopped_instances + 1
			else
				particle.system:update(dt)
			end

			if stopped_instances == #effect_instance then
				effect.queue[effect_id] = nil
			end
		end
	end

	for image_id, image_instance in pairs(effect.imagequeue) do
		for _,image in ipairs(image_instance) do
			local stopped_instances = 0
			image.displayTime = image.displayTime - dt
			if image.displayTime <= 0 then
				stopped_instances = stopped_instances + 1
			end
			if stopped_instances >= #image_instance then
				effect.imagequeue[image_id] = nil
			end
		end
	end
end

function effect.clear()
	for _, effect_instance in pairs(effect.queue) do
		for _, particle in ipairs(effect_instance) do
			particle:stop()
		end
	end
	effect.queue = {}
	effect.imagequeue = {}
	collectgarbage("collect")
end

function effect.draw()
	-- Draw effects
	for _, effect_instance in pairs(effect.queue) do
		for _, particle in ipairs(effect_instance) do
			love.graphics.setBlendMode(particle.blendMode)
			if effect_instance.global then
				love.graphics.push()
				love.graphics.origin()
				love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
				love.graphics.draw(particle.system)
				love.graphics.pop()
			else
				love.graphics.draw(particle.system)
			end
		end
	end

	-- Draw image instances
	for image_id, image_instance in pairs(effect.imagequeue) do
		for _, image in ipairs(image_instance) do
			local i = image
			local blendMode = i.blendMode or "alpha"
			local deltaTime = i.displayTime / i.vectorTime
			love.graphics.setColor(
				lerp(i.colorTarget[1], i.color[1], deltaTime),
				lerp(i.colorTarget[2], i.color[2], deltaTime),
				lerp(i.colorTarget[3], i.color[3], deltaTime),
				lerp(i.colorTarget[4], i.color[4], deltaTime)
			)
			love.graphics.setBlendMode(i.blendMode)
			love.graphics.draw(i.texture, i.x, i.y, i.angle, i.scaleX, i.scaleY, i.offsetX, i.offsetY)
		end
	end
end

return effect