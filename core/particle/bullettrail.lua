---@diagnostic disable: redundant-parameter

local LG        = love.graphics
local particles = {
    type = "image",
    x=0,
    y=0,
}

local image = {
    texturePath="gfx/block.bmp",
    x = 0,
    y = 0,
    initialX = 0,
    initialY = 0,
    endX = 0,
    endY = 0,
    velocity = 0,
    vectorTime = 0.1,
    displayTime = 0.1, -- seconds
    angle = 0,
    scaleX = 1,
    scaleY = 0.05,
    offsetX = 0,
    offsetY = 16,
    gradient = {0,0,0,0},
    color = {1.0, 1.0, 0.0, 0.2},
    colorTarget = {1.0, 1.0, 0.0, 0.0},
    blendMode = "add",
}
image.texture = LG.newImage(image.texturePath)
image.texture:setFilter("nearest","nearest")
table.insert(particles, image)


return particles