--[[
module = {
	x=emitterPositionX, y=emitterPositionY,
	[1] = {
		system=particleSystem1,
		kickStartSteps=steps1, kickStartDt=dt1, emitAtStart=count1,
		blendMode=blendMode1, shader=shader1,
		texturePreset=preset1, texturePath=path1,
		shaderPath=path1, shaderFilename=filename1,
		x=emitterOffsetX, y=emitterOffsetY
	},
	[2] = {
		system=particleSystem2,
		...
	},
	...
}
]]
local LG        = love.graphics
local particles = {x=4.2426406871193, y=17.942834572609}

local image1 = LG.newImage("gfx/particle/ellipse.png")
image1:setFilter("linear", "linear")

local ps = LG.newParticleSystem(image1, 11)
ps:setColors(0.9453125, 1, 0, 1, 0.9453125, 1, 0, 0)
ps:setDirection(0)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(0)
ps:setEmitterLifetime(0)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(5, 4)
ps:setOffset(50, 10.5)
ps:setParticleLifetime(1, 1)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(true)
ps:setRotation(0, 0)
ps:setSizes(0.095902815461159, 0, 0)
ps:setSizeVariation(0)
ps:setSpeed(150, 300)
ps:setSpin(-0.0005130753852427, 0)
ps:setSpinVariation(0)
ps:setSpread(6.2831854820251)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {system=ps, kickStartSteps=0, kickStartDt=0, emitAtStart=11, blendMode="add", shader=nil, texturePath="gfx/particle/ellipse.png", texturePreset="ellipse", shaderPath="", shaderFilename="", x=0, y=0})

return particles
