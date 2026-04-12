---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
	type="particle",
	x=0,
	y=0,
}

local image1 = LG.newImage("gfx/particle/ellipse.png")
image1:setFilter("linear", "linear")

local ps = LG.newParticleSystem(image1, 58)
ps:setColors(1, 1, 1, 1, 1, 0.8671875, 0, 0.77734375, 1, 0.31289672851563, 0.07421875, 0.77734375)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(4.0972962379456)
ps:setEmitterLifetime(0.033637803047895)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(-8.4957485198975, 7.2153434753418)
ps:setOffset(50, 10.5)
ps:setParticleLifetime(0.11249999701977, 0.13750000298023)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(0.07121554762125)
ps:setSizeVariation(0.041533544659615)
ps:setSpeed(699.43872070313, 2.4202032089233)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0)
ps:setTangentialAcceleration(-1054.1329345703, 1054.1329345703)
table.insert(particles, {
	system=ps,
	kickStartSteps=0,
	kickStartDt=0,
	emitAtStart=57,
	blendMode="alpha",
	shader=nil,
	texturePath="gfx/particle/ellipse.png",
	texturePreset="ellipse",
	shaderPath="",
	shaderFilename="",
	x=0,
	y=0,
	other={},
})

return particles
