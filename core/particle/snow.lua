---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
	global=true
}

local image1 = LG.newImage("gfx/particle/lightBlur.png")
image1:setFilter("linear", "linear")

local ps = LG.newParticleSystem(image1, 105)
ps:setColors(1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 0)
ps:setDirection(-1.5707963705063)
ps:setEmissionArea("borderellipse", 800, 600, 0, true)
ps:setEmissionRate(20)
ps:setEmitterLifetime(-1)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(7, 6)
ps:setOffset(60, 60)
ps:setParticleLifetime(5, 5)
ps:setRadialAcceleration(-800, -700)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(0.59939259290695, 0.10240289568901)
ps:setSizeVariation(0)
ps:setSpeed(0, 0)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0)
ps:setTangentialAcceleration(-1000, 1000)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=0,
	blendMode="add",
	shader=nil,
	texturePath="gfx/particle/lightBlur.png",
	texturePreset="lightBlur",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
