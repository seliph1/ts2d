-- Module start
return function(client)
---------- module start ----------
-- These functions are restricted to be used by server only
-- Only works when server sends them to this client

--- Client command parser
--- @param str string
function client.parse(str)
    local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local action_id = args[1]
	local actions = client.actions
	if actions[ action_id ] then
		local action_object = actions[ action_id ]
		if action_object.action then
			local status = action_object.action( unpack(args,2) )
		end
	else
		print(string.format("Unknown command: %s", str))
	end
end

local actions = {
    warning = {
        action = function(...)
			local message = table.concat({...}," ")
            local LF = require "lib.loveframes"
			local width, height = 300, 150
            local frame = LF.Create("frame"):SetSize(width, height):SetState("*"):Center()
			local panel = LF.Create("panel", frame):SetSize(width-20, height-50):SetPos(10, 30)
            local messagebox = LF.Create("messagebox", panel)
            messagebox:SetMaxWidth(width-20):SetText("©255000000"..message):Center()
        end
    };

	print = {
		action = function(...)
			print(...)
		end,
	};

	message = {
        action = function(...)
            local message = table.concat({...}," ")

            local ui = require "core.interface.ui"
            ui.chat_frame_server_message(message)
		end,
	};

    log = {
        action = function(...)
            local message = table.concat({...}," ")

            local ui = require "core.interface.ui"
            ui.server_log_push("©255220000"..message)
		end,
    };

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

    menu = {
        ---Invokes a server-side menu
        ---@param ... string
        action = function(...)
            local ui = require "core.interface.ui"
            ui.menu_constructor(table.concat({...}," "))
        end;
    };

    say = {
        action = function(peer_id, ...)
            peer_id = tonumber(peer_id)
            local message = table.concat({...}," ")
            local player = client.share.players[peer_id]

            if player then
                local ui = require "core.interface.ui"
                ui.chat_frame_message(player, message)
            end
        end
    };

    effect = {
        action = function(effect_id, x, y)
            x = tonumber(x) or 0
            y = tonumber(y) or 0
            client.map:spawn_effect(effect_id, x, y)
        end
    };

    hitscan = {
        action = function(tx, ty, hit)
            local player = client.share.players[client.id]
            local x, y = player.x, player.y
            tx = tonumber(tx) or 0
            ty = tonumber(ty) or 0

            local angle = math.atan2(ty-y, tx-x)
            local length = math.sqrt( (tx-x)^2 + (ty-y)^2 )

            local half = length/2
            local hx = x + math.cos(angle)*half
	        local hy = y + math.sin(angle)*half

            client.map:spawn_effect("hitscan", hx, hy,
                {
                    setDirection = angle,
                    setEmissionArea = {"uniform", half, 1, angle, false}
                }
		    )

            client.map:spawn_effect("bullettrail", tx, ty)

            if hit == "true" then
                client.map:spawn_effect("sparkle", tx, ty, {
                    setDirection = angle + math.pi
                })
            end
        end
    };

    attack = {
        ---@param peer_id number
        action = function(peer_id)
            peer_id = tonumber(peer_id) or 0
            -- NO home argument, this will be running for remote peers
            client.attack(peer_id)
        end
    };

    attack2 = {
    };

    reload = {
    };

    fire = {
        action = function(x, y, distance, angle, peer_id)
            -- Source of fire
            peer_id = tonumber(peer_id) or 0
            x = tonumber(x) or 0
            y = tonumber(y) or 0
            distance = tonumber(distance) or (32 * 4)
            angle = tonumber(angle) or 0

            client.fire(x, y, distance, angle, peer_id)
        end
    };

    hit = {
        action = function(...)
            print("hit: ", ...)
        end
    };

    kill = {
        action = function(...)
            print("kill: ", ...)
        end
    };

    --
    new = {
        action = function()
        end
    };
}
actions.msg = actions.message


client.actions = actions
---------- module end ------------
end