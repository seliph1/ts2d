-- Module start
return function(server)
	---------- module start ----------
	local actions = {
		say = {
			action = function(action_id, peer_id, ...)
				local args = { ... }
				local message = table.concat(args, " ")

				local player = server.share.players[peer_id]
				if player then
					server.send("all", string.format("%s %s %s", action_id, peer_id, message))
				end
				local name = player.n or "UNKNOWN PLAYER: "
				print(string.format("%s: %s", name, message))

				server.callhook("say", peer_id, message)
				server.callhook("sayutf8", peer_id, message)
			end,
			syntax = "send <id> [message]",
			source = "remote",
		},

		message = {
			action = function(action_id, peer_id, ...)
				-- We purposely ignore peer_id to send
				-- Just the message among the peers
				-- Since ID of this command will always be 0 (server)
				local message = table.concat({ ... }, " ")
				server.send("all", string.format("%s %s", action_id, message))
			end,
			alias = { "sv_msg", "msg", "sv_message" },
			source = "local",
		},

		message2 = {
			action = function(action_id, peer_id, target_id, ...)
				-- We purposely ignore peer_id to send
				-- Just the message among the peers
				-- Since ID of this command will always be 0 (server)
				local message = table.concat({ ... }, " ")
				server.send(target_id, string.format("%s %s", action_id, message))
			end,
			alias = { "sv_msg2", "msg2", "sv_message2" },
			source = "local",
		},

		setname = {
			action = function(action_id, peer_id, ...)
				local player = server.share.players[peer_id]
				local args = { ... }
				local name = table.concat(args)
				if player then
					player.n = name
				end
			end,
			source = "remote",
		},

		version = {
			action = function(action_id, peer_id, ...)
				server.send("")
			end,
			source = "remote",
		},

		setphase = {
			action = function(action_id, peer_id, phase)
				phase = tonumber(phase) or 0
				server.share.game.phase = phase
			end,
			syntax = "setphase <phase>",
			source = "local",
		},

		setpos = {
			action = function(action_id, peer_id, target_id, x, y)
				target_id = tonumber(target_id)
				x, y = tonumber(x), tonumber(y)
				local status = server.setpos(target_id, x, y)
				if not status then
					return "Player with this ID doesn't exist"
				end
			end,
			alias = { "tp" },
			source = "remote",
		},

		speedmod = {
			action = function(action_id, peer_id, target_id, speed)
				target_id = tonumber(target_id)
				speed = tonumber(speed) or 0
				
				local player = server.share.players[target_id]
				if player then
					player.s = speed
				end
			end,
			source = "remote",
		},

		setweapon = {
			action = function(action_id, peer_id, target_id, item_id)
				target_id = tonumber(target_id)
				local weapon_id = tonumber(item_id)
				local status, err = server.setitem(target_id, item_id)
				if not status then
					return err
				end
			end,
			alias = { "setitem" },
			source = "remote",
		},

		equip = {
			action = function(action_id, peer_id, target_id, item)
				target_id = tonumber(target_id)

				local status, err = server.equip(target_id, item)
				if not status then
					return err
				end
			end,
			source = "remote",
		},

		team = {
			action = function(action_id, peer_id, team_id, look_id)
				team_id = tonumber(team_id) or 0
				look_id = tonumber(look_id) or 0
				server.changeteam(peer_id, team_id)
			end,
			alias = { "pickteam", "chooseteam", "changeteam" },
			source = "remote",
		},

		weapon = {
			action = function(action_id, peer_id, item_id)
				item_id = tonumber(item_id)
				local status, err = server.setitem(peer_id, item_id)
				if not status then
					return err
				end
			end,
			source = "remote",
		},

		kill = {
			action = function(action_id, peer_id)
				server.sethealth(peer_id, 0)
			end,
			syntax = "",
			source = "remote",
		},

		slap = {
			action = function(action_id, peer_id)
				server.decreasehealth(peer_id, 10)
			end,
			syntax = "",
			source = "local",
		},

		buy = {
			action = function(action_id, peer_id, ...)
				server.buy(peer_id, ...)
			end,
			syntax = "buy <item1> <item2> <...>",
			source = "remote",
		},

		restart = {
			action = function(action_id, peer_id, seconds)
				seconds = tonumber(seconds) or 5
				server.restart(seconds)
			end,
			syntax = "restart <seconds>",
			alias = { "sv_restart", "restartround", "sv_restartround" },
			source = "local",
		},

		spawnplayer = {
			action = function(action_id, peer_id, target_id, x, y)
				target_id = tonumber(target_id)
				x, y = tonumber(x), tonumber(y)
				server.spawnplayer(target_id, x, y)
			end,
			syntax = "spawnplayer <id> <x?> <y?>",
			source = "local",
		},

		spawnplayer_silent = {
			action = function(action_id, peer_id, target_id, x, y)
				target_id = tonumber(target_id)
				x, y = tonumber(x), tonumber(y)
				server.spawnplayer(target_id, x, y, true)
			end,
			syntax = "spawnplayer_silent <id> <x?> <y?>",
			source = "local",
		},

		respawnrequest = {
			action = function(action_id, peer_id)
				server.respawnrequest(peer_id)
			end,
			syntax = "respawnrequest",
			source = "remote",
		},

		startround = {
			action = function(action_id, peer_id)
				server.startround()
			end,
			syntax = "startround",
			source = "local",
		},

		endround = {
			action = function(action_id, peer_id, team_win)
				team_win = tonumber(team_win) or 0
				server.endround(team_win)
			end,
			syntax = "endround <team_win>",
			source = "local",
		},

		settime = {
			action = function(action_id, peer_id, time)
				time = tonumber(time) or 20
				-- Change from minutes to seconds
				server.settime(time * 60)
			end,
			syntax = "settime <time>",
			source = "local",
		},

		pause = {
			action = function(action_id, peer_id)
				server.pausetime()
			end,
			syntax = "pause",
			source = "local",
		},

		resume = {
			action = function(action_id, peer_id)
				server.resumetime()
			end,
			syntax = "resume",
			source = "local",
		},

		mp_roundtime = {
			action = function(action_id, peer_id, time)
				time = tonumber(time) or 20
				-- Change from minutes to seconds
				server.setroundtime(time * 60)
			end,
			syntax = "mp_roundtime <time>",
			source = "local",
		},

		rcon = {
			action = function(action_id, peer_id, ...)
				local args = { ... }
				local serpent = require "lib.serpent"
				local command = table.concat(args, " ")

				if args[1] == "rcon" then
					return
				end
				if server.actions[args[1]] then
					local peer_ip = server.getENetPeer(peer_id)
					server.log(7, "rcon", string.format("RCon[%s]: %s", peer_ip, command))
					server.parse(0, command)
				end
			end,
			syntax = "rcon <command>",
			source = "remote",
		},

		gamemode = {
			action = function(action_id, peer_id, mode_id)
				mode_id = tonumber(mode_id)
				if mode_id then
					server.gamemode_change(mode_id)
					server.log(1, "gamemode", string.format("Gamemode changed to ID: %d", mode_id))
					server.startround()
				else
					server.log(1, "gamemode", "Usage: gamemode <mode_id> (0 = Standard, 1 = Freeplay)")
				end
			end,
			alias = { "sv_gamemode" },
			syntax = "gamemode <mode_id>",
			source = "local",
		},
	}
	return actions
	---------- module end ----------
end
