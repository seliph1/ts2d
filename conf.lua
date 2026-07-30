function love.conf(t)
    -- Modo servidor dedicado headless: `love . --server` (ver branch em main.lua).
    local is_server = false
    for _, a in ipairs(arg or {}) do
        if a == "--server" or a == "server" then
            is_server = true
            break
        end
    end

    t.identity = "TS2D" -- The name of the save directory (string)
    if is_server then
        -- Espelha o conf headless do ts2d_ag (sem janela/gráficos/áudio).
        t.console          = true
        t.modules.graphics = false
        t.modules.window   = false
        t.modules.audio    = false
        t.modules.sound    = false
        t.modules.video    = false
        t.physics          = false
        return
    end
    --t.version = "11.5"                  -- The LÖVE version this game was made for (string)
    t.appendidentity    = false                -- Search files in source directory before save directory (boolean)
    t.console           = false                -- Attach a console (boolean, Windows only)
    t.window.title      = "Tactical Strike 2D" -- The window title (string)
    t.window.icon       = "cs2d.png"           -- Filepath to an image to use as the window's icon (string)
    t.window.width      = 1280                 -- The window width (number)
    t.window.height     = 728                  -- The window height (number)
    t.window.borderless = false                -- Remove all border visuals from the window (boolean)
    t.window.resizable  = false                -- Let the window be user-resizable (boolean)
    t.window.vsync      = 1                    -- Vertical sync mode (number)
    t.window.msaa       = 0                    -- The number of samples to use with multi-sampled antialiasing (number)
    --t.window.minwidth = 1               -- Minimum window width if the window is resizable (number)
    --t.window.minheight = 1              -- Minimum window height if the window is resizable (number)
end
