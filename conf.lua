
function love.conf(t)
    t.title = "TiledMapDemo"		-- The title of the window the game is in (string)
    t.author = "mozilla"		-- The author of the game (string)
    t.window.width = 800			-- The window width (number)
    t.window.height = 600			-- The window height (number)
	t.window.resizable = false
    t.window.fullscreen = false		-- Enable fullscreen (boolean)
    t.window.vsync = false			-- Enable vertical sync (boolean)
	t.window.msaa = 1
	t.window.depth = 1
end
