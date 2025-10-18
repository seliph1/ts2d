---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=-111,
	y=77.5,
	
}

local image1 = LG.newImage("gfx/particle/blackSmoke00.png")
image1:setFilter("nearest", "nearest")

local ps = LG.newParticleSystem(image1, 5)
ps:setColors(0.40000000596046, 0.40000000596046, 0.40000000596046, 0, 0.40000000596046, 0.40000000596046, 0.40000000596046, 0.5, 0.40000000596046, 0.40000000596046, 0.40000000596046, 0, 0.40000000596046, 0.40000000596046, 0.40000000596046, 0)
ps:setDirection(-1.5707963705063)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(0)
ps:setEmitterLifetime(0)
ps:setInsertMode("bottom")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(181, 168)
ps:setParticleLifetime(1.7999999523163, 2.2000000476837)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(0.02)
ps:setSizeVariation(0)
ps:setSpeed(2, 3)
ps:setSpin(0, 0)
ps:setSpinVariation(0.5)
ps:setSpread(8)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=5,
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/blackSmoke00.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
