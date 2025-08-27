
-- Module start
return function(client)
---------- module start ----------

local actions = {
-- Server only actions
    mapchange = {
        ---Changes map currently being drawn on screen
        ---@param ... string
        action = function(...)
            local args = {...}
            local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
            if status then
                print(status)
            end
            client.mode = "game"
        end,
    };
    filecheck = {
        ---Checks if a file exists on client side, and send a confirmation to server
        ---@param ... string
        action = function(...)
            local args = {...}
            local path = table.concat(args," ")
            if love.filesystem.getInfo(path, "file") then
                print(string.format("file %s exists.", path))
            else
                print(string.format("file %s does not exist. Requesting", path))
            end
        end
    };
    scroll = {
        --- Scroll camera to a set position
        ---@param x number
        ---@param y number
        action = function(x,y)
            x = tonumber(x) or 0
            y = tonumber(y) or 0

            client.camera.x = x
            client.camera.y = y
            client.map:scroll(x, y)
            print(string.format("scrolled to %s-%s", x, y))
        end
    };
    name = {
        ---Changes name of this client
        ---@param ... string
        action = function(...)
        end;
    };

    menu = {
        ---Invokes a server-side menu
        ---@param ... string
        action = function(...)
            local ui = require "core.interface.ui"
            ui.menu_constructor(table.concat({...}," "))
        end;
    }
}
return actions

---------- module end ------------
end