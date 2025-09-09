---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
	global=true
}

local image1 = LG.newImage("gfx/particle/raindrop.bmp")
image1:setFilter("linear", "linear")

local ps = LG.newParticleSystem(image1, 105)
ps:setColors(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0)
ps:setDirection(0)
ps:setEmissionArea("borderellipse", 600, 600, 0, false)
ps:setEmissionRate(100)
ps:setEmitterLifetime(-1)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(3, 3)
ps:setOffset(16, 16)
ps:setParticleLifetime(0.5, 1)
ps:setRadialAcceleration(-2500, -2500)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(2, 1.5)
ps:setSizeVariation(1)
ps:setSpeed(0, 0)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=0,
	blendMode="add",
	shader=nil,
	texturePath="gfx/particle/raindrop.bmp",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

local ps = LG.newParticleSystem(image1, 105)
ps:setColors(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0)
ps:setDirection(0)
ps:setEmissionArea("borderellipse", 600, 600, 0, false)
ps:setEmissionRate(100)
ps:setEmitterLifetime(-1)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(3, 3)
ps:setOffset(16, 16)
ps:setParticleLifetime(1, 1)
ps:setRadialAcceleration(-1500, -1500)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(1, 0.5)
ps:setSizeVariation(1)
ps:setSpeed(0, 0)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=0,
	blendMode="add",
	shader=nil,
	texturePath="gfx/particle/raindrop.bmp",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
