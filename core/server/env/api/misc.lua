-- Miscellaneous CS2D API functions

return function(cs2dAPI, server)
    local share = server.share
    local game = server.share.game

    -- Messaging
    cs2dAPI.msg = function(text)
        server.send("all", "msg " .. text)
    end

    cs2dAPI.msg2 = function(player_id, text)
        server.send(player_id, "msg " .. text)
    end

    cs2dAPI.menu = function(player_id, title, buttons)
        -- void
    end

    cs2dAPI.print = function(...)
        server.log(1, "lua", ...)
    end

    -- Parsing and commands
    cs2dAPI.parse = function(text)
        -- ID 0 = server
        server.parse(0, text)
    end

    cs2dAPI.funcs = function(category)
        -- void
    end

    cs2dAPI.vars = function(var_name)
        -- void
    end

    -- Checksum
    cs2dAPI.checksumfile = function(filename)
        -- void
    end

    cs2dAPI.checksumstring = function(str)
        -- void
    end

    -- from this page: https://www.cs2d.com/help.php?luacat=game&luacmd=game#cmd
    local GAME_FUNCTIONS = {
        version = function()
            return server.version
        end,

        dedicated = function()
            -- TODO: make the game run a live server.
            return true
        end,

        phase = function()
            -- Return 0 for freeze time, 1 for actual game
            return share.game.phase
        end,

        round = function()
            return share.game.round
        end,

        roundtime = function()
            return share.game.timer
        end,

        --  remaining time on map in seconds (float precision), 1000000 if unlimited
        timeleft = function()
            --local time_left = share.game.timer_start - os.time()
            --return time_left
            local timer_now = os.time() - game.timer_start
            local timer = game.timer - timer_now
            if timer < 0 then
                timer = 0
            end
            return timer
        end,

        timepassed = function()
            return os.time() - game.timer_start
        end,

        maptimeleft = function()
            return 1000000
        end,

        score_t = function()
            return share.scores[1]
        end,

        score_ct = function()
            return share.scores[2]
        end,

        score = function(team)
            return share.scores[team]
        end,

        winrow_t = function()
            return share.winrows[1]
        end,

        winrow_ct = function()
            return share.winrows[2]
        end,

        winrow = function(team)
            return share.winrows[team]
        end,
		
		buyzones = function()
			return server.map:getBuyZones()
		end
    }

    -- Game and map info
    cs2dAPI.game = function(parameter)
        if GAME_FUNCTIONS[parameter] then
            local f = GAME_FUNCTIONS[parameter]
            return f()
        end
    end

    local MAP_FUNCTIONS = {
        xsize = function()
            return server.map:getWidth()
        end,

        ysize = function()
            return server.map:getHeight()
        end,

        name = function()
            return server.map:getName()
        end,

        author = function()
            return server.map:getAuthor()
        end,

        usgn = function()
            return server.map:getUSGN()
        end,

        tileset = function()
            return server.map:getTileset()
        end,

        tilesize = function()
            return server.map:getTileSize()
        end,

        tilecount = function()
            return server.map:getTileCount()
        end,
    }

    cs2dAPI.map = function(parameter)
        if MAP_FUNCTIONS[parameter] then
            local f = MAP_FUNCTIONS[parameter]
            return f()
        end
    end

    local TILE_FUNCTIONS = {
        walkable = function(x, y)
            if server.map:isCollidingWithTile(x, y, 0) then
                return false
            end
            return true
        end,

        frame = function(x, y)
            return server.map:getTile(x, y)
        end,
    }

    cs2dAPI.tile = function(x, y, parameter)
        if x < 0 or y < 0 then
            return nil
        end
        if x > server.map:getWidth() or y > server.map:getHeight() then
            return nil
        end
        if TILE_FUNCTIONS[parameter] then
            local f = TILE_FUNCTIONS[parameter]
            return f(x, y)
        end
    end

    cs2dAPI.tileproperty = function(x, y, property)
        -- void
    end

    -- Player proximity
    cs2dAPI.closeplayers = function(x, y, range, team)
        -- void
    end

    cs2dAPI.hascloseplayers = function(x, y, range, team)
        -- void
    end

    -- Fog of war
    cs2dAPI.fow_in = function(x, y, player_id)
        -- void
    end

    -- HTTP requests
    cs2dAPI.reqcld = function(url)
        -- void
    end

    cs2dAPI.reqhttp = function(url, method, params)
        -- void
    end

    -- Stats
    cs2dAPI.stats = function(player_id, stat_name)
        -- void
    end

    cs2dAPI.steamstats = function(player_id, stat_name)
        -- void
    end
end
