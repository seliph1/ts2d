---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
	
}

local image1 = LG.newImage("gfx/particle/circle.png")
image1:setFilter("nearest", "nearest")

local ps = LG.newParticleSystem(image1, 4)
ps:setColors(0.30000001192093, 0, 0, 1, 0.30000001192093, 0, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(1)
ps:setEmitterLifetime(0)
ps:setInsertMode("bottom")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(6, 10)
ps:setOffset(50, 50)
ps:setParticleLifetime(2, 2)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(0.079999998211861, 0.059999998658895)
ps:setSizeVariation(0.80000001192093)
ps:setSpeed(0, 400)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0.17453292012215)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=4,
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/circle.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

local ps = LG.newParticleSystem(image1, 20)
ps:setColors(0.30000001192093, 0, 0, 1, 0.30000001192093, 0, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(1)
ps:setEmitterLifetime(0)
ps:setInsertMode("bottom")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(6, 10)
ps:setOffset(50, 50)
ps:setParticleLifetime(1, 1)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(0.029999999329448, 0.050000000745058)
ps:setSizeVariation(0.80000001192093)
ps:setSpeed(0, 600)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0.34906584024429)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=20,
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/circle.png",
	texturePreset="",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
