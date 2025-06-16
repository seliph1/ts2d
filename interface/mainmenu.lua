require "lib/lovefs/lovefs"

local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory() )
else
	fs:cd(love.filesystem.getSource() )
end

local splash = fs:loadImage("gfx/splash.bmp")

function mainmenu_update(dt)

end

function mainmenu_draw()
	love.graphics.draw(splash)
end
