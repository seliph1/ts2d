
function love.conf(t)
    t.title = "Tactical Strike 2D"		-- The title of the window the game is in (string)
    t.author = "mozilla"		-- The author of the game (string)
    --t.window.width = 800			-- The window width (number)
    --t.window.height = 600			-- The window height (number)
    t.window.width = 1080			-- The window width (number)
    t.window.height = 720			-- The window height (number)	
	--t.window.minwidth = 1280
	--t.window.minheight = 720
	--t.window.resizable = true
    t.window.fullscreen = false		-- Enable fullscreen (boolean)
    t.window.vsync = false			-- Enable vertical sync (boolean)
	t.physics = false
    t.console = true
	--t.window.msaa = 1
	--t.window.depth = 1
	--t.window.highdpi = true            -- Enable high-dpi mode for the window on a Retina display (boolean)
    --t.window.usedpiscale = true         -- Enable automatic DPI scaling when highdpi is set to true as well (boolean)
end
