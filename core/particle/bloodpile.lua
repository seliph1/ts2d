---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
    x=0,
    y=0,
}

local image1 = LG.newImage("gfx/sprites/pile1.png")
image1:setFilter("nearest", "nearest")
local image2 = LG.newImage("gfx/sprites/pile2.png")
image2:setFilter("nearest", "nearest")
local image3 = LG.newImage("gfx/sprites/pile3.png")
image3:setFilter("nearest", "nearest")

local ps = LG.newParticleSystem(image1, 1)
ps:setColors(0.34765625, 0, 0, 1, 0.34765625, 0, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(1)
ps:setEmitterLifetime(0)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(200, 200)
ps:setParticleLifetime(1, 1)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(-6.2831854820251, 0)
ps:setSizes(0.10000000149012)
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
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/pile2.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

local ps = LG.newParticleSystem(image2, 1)
ps:setColors(0.34765625, 0, 0, 1, 0.34765625, 0, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(1)
ps:setEmitterLifetime(0)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(200, 137.5)
ps:setParticleLifetime(1, 1)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(6.2831854820251, 0)
ps:setSizes(0.10000000149012)
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
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/pile1.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

local ps = LG.newParticleSystem(image3, 1)
ps:setColors(0.34765625, 0, 0, 1, 0.34765625, 0, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(1)
ps:setEmitterLifetime(0)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(200, 200)
ps:setParticleLifetime(1, 1)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(6.2831854820251, 0)
ps:setSizes(0.10000000149012)
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
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/pile3.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
