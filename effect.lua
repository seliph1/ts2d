local effect = {}

effect.queue = {}
effect.list = {}

function effect.register(particle, name)
	effect.list[name] = particle
end

function effect.new(name, x, y)
	local effect_instance = effect.list[name]
	local new_effect = {}
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
		-- Start emitting the particles
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
			if particle.system:isStopped() and particle.system:getCount() == 0 then
				effect.queue[effect_id] = nil
			else
				particle.system:update(dt)
			end
		end
	end
end


function effect.draw()
	-- Draw effects
	for _, effect in pairs(effect.queue) do
		for _, particle in ipairs(effect) do
			love.graphics.setBlendMode(particle.blendMode)
			love.graphics.draw(particle.system)
		end
	end
end

return effect