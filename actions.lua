local serpent = require "lib.serpent"

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
        alias = {"msg", "sv_msg"}
	};

    log = {
        action = function(...)
            local message = "©255220000"..table.concat({...}," ")

            local ui = require "core.interface.ui"
            local console = require "core.interface.console"
            ui.server_log_push(message)
            console.message(message)
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

            if client.joined and player then
                local ui = require "core.interface.ui"
                local console = require "core.interface.console"
                local full_message = ui.chat_frame_message(player, message)
                console.message(full_message)
            end
        end
    };

    effect = {
        action = function(effect_id, x, y, p1, p2, r, g, b)
            x = tonumber(x) or 0
            y = tonumber(y) or 0
            local amount, radius, velocity
            if (r and g and b) then
                r = (tonumber(r) or 255)/255
                g = (tonumber(g) or 255)/255
                b = (tonumber(b) or 255)/255
            end

            if effect_id == "fire" then
            elseif effect_id == "smoke" then
            elseif effect_id == "blood" then
            elseif effect_id == "flare" then
                if (r and g and b) then
                    client.map:spawn_effect(effect_id, x, y, {
                        setColors = {r, g, b, 1};
                    })
                else
                    client.map:spawn_effect(effect_id, x, y)
                end
            elseif effect_id == "colorsmoke" then
            elseif effect_id == "particles" then
            end

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
        action = function(peer_id, reload_step, seconds)
            local ui = require "core.interface.ui"
            -- reload_step 0 = cancelled reloading
	        -- reload_step 1 = starting reload
	        -- reload_step 2 = done reloading
            peer_id = tonumber(peer_id)
            reload_step = tonumber(reload_step)
            seconds = tonumber(seconds)

            local player = client.share.players[peer_id]

            if peer_id == client.id then
                if reload_step == 1 then -- We are reloading
                    ui.reload_display(seconds)
                    client.map:playSoundAt("sfx/weapons/w_clipout.wav", player.x, player.y)
                elseif reload_step == 2 then -- We finished reloading
                    ui.reload_dispose()
                    client.map:playSoundAt("sfx/weapons/w_clipin.wav", player.x, player.y)
                elseif reload_step == 0 then -- We cancelled reloading
                    ui.reload_dispose()
                end
            end
        end,
        syntax = "",
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
        end
    };

    kill = {
        action = function(...)
        end
    };

    camera = {
        action = function(mode, ...)
            if mode == "self" then
                local player = client.share.players[client.id]
                if player then
                    client.camera_follow(player)
                end
            elseif mode == "follow" then
                local category = arg[1]
                local id = tonumber( arg[2] ) or 0

                local share = client.share
			    if not share[category] then return "There is no category with that name" end
			    if not share[category][id] then return "There is no entity with this ID" end
			    local entity = share[category][id]
			    if entity and entity.x and entity.y then
				    client.camera_follow(entity)
                end

            elseif mode == "translate" then
                local x = tonumber(arg[1] ) or 0
                local y = tonumber(arg[2] ) or 0
                client.camera_translate(x, y)
            elseif mode == "snap" then
                local x = tonumber(arg[1] ) or 0
                local y = tonumber(arg[2] ) or 0
                client.camera_snap(x, y)
            elseif mode == "unbind" then
                client.camera_unbind()
            end
        end
    };

    menu_team = {
        action = function()
            local ui = require "core.interface.ui"
            ui.teampick_display()
        end
    };

    menu_buy = {
        action = function(...)
            local ui = require "core.interface.ui"
            ui.buymenu_display()
        end,
    };

    spawn = {
        action = function(peer_id, x, y)
            -- Release the spawning effect on this peer_id player
            peer_id = tonumber(peer_id)
            x = tonumber(x) or 0
            y = tonumber(y) or 0
            if not client.joined then return end
            if not (client.share or client.share.players or client.share.config) then return end
            local player = client.share.players[peer_id]
            local teams = client.share.config.teams

            if player then
                local team_id = player.t
                local team = teams[team_id]
                local color = {0.75, 0.75, 0.75}
                if team then
                   	local r, g, b = team.color:match("(%d%d%d)(%d%d%d)(%d%d%d)")
                    if (r and g and b) then
                        color[1] = tonumber(r) / 255
                        color[2] = tonumber(g) / 255
                        color[3] = tonumber(b) / 255
                    end
                end

                client.map:spawn_effect("spawn", x, y, {
                    -- Transition from opaque to transparent (1->0)
                    setColors = {
                        color[1], color[2], color[3], 1.0,
                        color[1], color[2], color[3], 0.0,
                    },
                })
            end

        end,
    };

    die = {
        action = function(victim_id, attacker_id, item_type, x, y)
            -- Release the spawning effect on this peer_id player
            victim_id = tonumber(victim_id)
            x = tonumber(x) or 0
            y = tonumber(y) or 0
            if not client.joined then return end
            if not (client.share or client.share.players or client.share.config) then return end
            local player = client.share.players[victim_id]

            if player then
                client.map:spawn_effect("bloodpile", x, y)
            end
        end,
    };

    restart = {
        action = function(...)
            print("Round restarted by server.")
        end,
        syntax = "",
    };

}
actions.msg = actions.message

client.actions = actions
---------- module end ------------
end