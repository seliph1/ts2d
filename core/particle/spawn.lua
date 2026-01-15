---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
	
}

local image1 = LG.newImage("gfx/particle/light.png")
image1:setFilter("nearest", "nearest")

local ps = LG.newParticleSystem(image1, 10)
ps:setColors(1, 1, 1, 1, 1, 1, 1, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(0)
ps:setEmitterLifetime(1)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(75, 75)
ps:setParticleLifetime(0.5, 0.69999998807907)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(0.18796952068806)
ps:setSizeVariation(0)
ps:setSpeed(60, 30)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(6.2831854820251)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=10,
	blendMode="add",
	shader=nil,
	texturePath="gfx/particle/light.png",
	texturePreset="light",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
