---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	x=0,
	y=0,
	
}

local image1 = LG.newImage("gfx/particle/circle.png")
image1:setFilter("linear", "linear")
local image2 = LG.newImage("gfx/particle/lineGradient.png")
image2:setFilter("linear", "linear")

local ps = LG.newParticleSystem(image1, 30)
ps:setColors(1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 0)
ps:setDirection(0)
ps:setEmissionArea("uniform", 100, 1, 0, false)
ps:setEmissionRate(0)
ps:setEmitterLifetime(1)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(3, 1.5)
ps:setOffset(50, 50)
ps:setParticleLifetime(0.5, 1)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(0.0086312536150217)
ps:setSizeVariation(0)
ps:setSpeed(250, 50)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0.087266460061073)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=30,
	blendMode="add",
	shader=nil,
	texturePath="gfx/particle/circle.png",
	texturePreset="circle",
	shaderPath="",
	shaderFilename="",
	x=100,
	y=0,
	other={},
})

local ps = LG.newParticleSystem(image2, 2)
ps:setColors(1, 1, 1, 1, 1, 1, 1, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(1)
ps:setEmitterLifetime(0.10000000149012)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(0, 2)
ps:setParticleLifetime(0.10000000149012, 0.10000000149012)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(1)
ps:setSizeVariation(0)
ps:setSpeed(0, 0)
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
	texturePath="gfx/particle/lineGradient.png",
	texturePreset="lineGradient",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
