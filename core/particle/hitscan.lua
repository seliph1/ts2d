---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
}

local image1 = LG.newImage("gfx/particle/circle.png")
image1:setFilter("linear", "linear")

local ps = LG.newParticleSystem(image1, 30)
ps:setColors(1, 1, 0, 1, 1, 1, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("uniform", 128, 1, 0, false)
ps:setEmissionRate(0)
ps:setEmitterLifetime(0)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(3, 1.5)
ps:setOffset(50, 50)
ps:setParticleLifetime(0.1, 0.2)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(0.008)
ps:setSizeVariation(0)
ps:setSpeed(250, 50)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0.05)
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
	x=0,
	y=0,
	other={},
})

return particles
