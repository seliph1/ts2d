---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
	
}

local image1 = LG.newImage("gfx/particle/blackSmoke24.png")
image1:setFilter("nearest", "nearest")

local ps = LG.newParticleSystem(image1, 1)
ps:setColors(0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(0)
ps:setEmitterLifetime(0)
ps:setInsertMode("bottom")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(196.5, 185.5)
ps:setParticleLifetime(1, 2)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(true)
ps:setRotation(360, 0)
ps:setSizes(0.04, 0.06)
ps:setSizeVariation(1)
ps:setSpeed(10, 20)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=1,
	blendMode="add",
	shader=nil,
	texturePath="gfx/particle/blackSmoke24.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
