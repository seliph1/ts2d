---@diagnostic disable: duplicate-set-field
local loveframes = require "lib.loveframes"
local LF = loveframes

function love.load()
    love.filesystem.load("uidebug/console.lua") ()
    love.filesystem.load("uidebug/objects.lua") ()
end

function love.update(dt)
    loveframes.update(dt)
end

function love.draw()
    loveframes.draw()
end

function love.keypressed(key, unicode)
    loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
    loveframes.keyreleased(key)
end

function love.wheelmoved(x, y)
    loveframes.wheelmoved(x, y)
end

function love.mousemoved(x, y, dx, dt, touch)
    loveframes.mousemoved(x, y, dx, dt, touch)
end

function love.mousepressed(x, y, button, istouch, pressed)
    loveframes.mousepressed(x, y, button, istouch, pressed)
end

function love.mousereleased(x, y, button, istouch, presses)
    loveframes.mousereleased(x, y, button, istouch, presses)
end

function love.textinput(text)
    loveframes.textinput(text)
end

