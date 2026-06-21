local serpent = require "lib.serpent"
local CONSOLE_ENV = {}
-- Small lua environment only acessible by this file
([[
_VERSION assert error    ipairs   next pairs
pcall    select tonumber tostring type unpack xpcall

coroutine.create coroutine.resume coroutine.running coroutine.status
coroutine.wrap   coroutine.yield

math.abs   math.acos math.asin  math.atan math.atan2 math.ceil
math.cos   math.cosh math.deg   math.exp  math.fmod  math.floor
math.frexp math.huge math.ldexp math.log  math.log10 math.max
math.min   math.modf math.pi    math.pow  math.rad   math.random
math.sin   math.sinh math.sqrt  math.tan  math.tanh

os.clock os.difftime os.time

string.byte string.char  string.find  string.format string.gmatch
string.gsub string.len   string.lower string.match  string.reverse
string.sub  string.upper

table.insert table.maxn table.remove table.sort
]]):gsub('%S+', function(id)
  local module, method = id:match('([^%.]+)%.([^%.]+)')
  if module then
    CONSOLE_ENV[module]         = CONSOLE_ENV[module] or {}
    CONSOLE_ENV[module][method] = _G[module][method]
  else
    CONSOLE_ENV[id] = _G[id]
  end
end)

-- Client only commands
local commands = {
	-------------------------------------------------------
	-- DEBUG
	-------------------------------------------------------
	lerp = {
		---Sets the client interpolation (lerp) speed.
		---@param speed number|string Interpolation speed (default: 30)
		action = function(speed)
			local client = require "client"
			speed = tonumber(speed) or 30
			client.lerp_speed = speed
		end,
	};

    camera = {
		---Controls the client camera according to the given mode.
		---@param mode "update"|"self"|"follow"|"translate"|"snap"|"unbind"|"lerp" Camera operation mode
		---@param ... string Mode arguments (e.g. category/id, x/y or speed)
		---@return string? help Help message when the mode is invalid
        action = function(mode, ...)
			local args = {...}
			local client = require "client"

			if mode == "update" then
				client.map:shiftRender()
			elseif mode == "self" then
                local player = client.share.players[client.id]
                if player then
                    client.camera_follow(player)
                end
            elseif mode == "follow" then
                local category = args[1]
                local id = tonumber( args[2] ) or 0

                local share = client.share
			    if not share[category] then return "There is no category with that name" end
			    if not share[category][id] then return "There is no entity with this ID" end
			    local entity = share[category][id]
			    if entity and entity.x and entity.y then
				    client.camera_follow(entity)
                end
            elseif mode == "translate" then
                local x = tonumber(args[1] ) or 0
                local y = tonumber(args[2] ) or 0
                client.camera_translate(x, y)
            elseif mode == "snap" then
                local x = tonumber(args[1] ) or 0
                local y = tonumber(args[2] ) or 0
                client.camera_snap(x, y)
            elseif mode == "unbind" then
                client.camera_unbind()
			elseif mode == "lerp" then
				local speed = tonumber(args[1]) or 10
				client.camera.tween_speed = speed
            else
                local s = "camera mode not found. Try one of these: "
                for index, camera_mode in
					pairs({"self", "follow", "translate", "snap", "unbind", "lerp"})
				do
                    s = s .. "\n©000255255camera ©255255000"..camera_mode
                end
				return s
            end
        end
    };

	clear = {
		---Clear console
		action = function()
			local console = require "core.interface.console"
			console.window:Clear()
		end;
	};

	lua = {
		---Evaluates a lua expression
		---@param ... string
		action = function(...)
			local block = table.concat({...}, " ")
			local expression, error_message = loadstring( block, "")
			local ui = require "core.interface.ui"
			local client = require "client"
			CONSOLE_ENV.print = print
			CONSOLE_ENV.client = client
			CONSOLE_ENV.ui = ui
			CONSOLE_ENV.msg = ui.chat_frame_server_message
			CONSOLE_ENV.dump = serpent.dump

			if expression then
				setfenv(expression, CONSOLE_ENV)
				local status, error_message = pcall(expression)
				if not status then
					return "©255000000LUA ERROR: "..error_message
				end
			else
				return "©255000000LUA ERROR: "..error_message
			end
		end;
	};

	print = {
		---Evaluates a lua expression and prints the result to the console.
		---@param ... string Lua expression to evaluate
		action = function(...)
			local block = table.concat({...}, " ")
			local expression, error_message = loadstring( "return ".. block)
			local ui = require "core.interface.ui"
			local console = require "core.interface.console"
			local client = require "client"

			CONSOLE_ENV.client = client
			CONSOLE_ENV.ui = ui

			if expression then
				setfenv(expression, CONSOLE_ENV)
				local output = { pcall(expression) }
				if not output[1] then
					console.message("©255000000LUA ERROR: "..output[2])
				else
					for i = 2, #output do
						local value = output[i]
						console.message( tostring(value) )
					end
				end
			else
				console.message("©255000000LUA ERROR: "..error_message)
			end
		end,
		syntax = "",
	};

	dump = {
		---Evaluates a lua expression and dumps the value structure (serpent) to the console.
		---@param ... string Lua expression to evaluate
		action = function(...)
			local block = table.concat({...}, " ")
			local expression, error_message = loadstring( "return ".. block)
			local ui = require "core.interface.ui"
			local console = require "core.interface.console"
			local client = require "client"

			CONSOLE_ENV.client = client
			CONSOLE_ENV.ui = ui

			if expression then
				setfenv(expression, CONSOLE_ENV)
				local output = { pcall(expression) }
				if not output[1] then
					console.window:AddElement("©255000000LUA ERROR: "..output[2])
				else
					for i = 2, #output do
						local value = output[i]
						local dump = serpent.block(value, {
							nocode=true,
							comment=true,
							sortkeys=true,
						})
						console.window:AddElement(dump)
					end
				end
			else
				console.window:AddElement("©255000000LUA ERROR: "..error_message)
			end
		end,
		syntax = "",
	};

	debug = {
		---Sets the debug level reported by the client.
		---@param level number|string Debug level (default: 0)
		action = function(level)
			local client = require "client"
			client.debug_level = tonumber(level) or 0
		end;
	};

	utf8 = {
		---Prints test sentences in several languages to validate UTF-8 rendering.
		---@return string sentences List of formatted sentences per language
		action = function()
			local frases = {
				{ idioma = "Português", frase = "Você já viu o avião de João?" },
				{ idioma = "Inglês", frase = "The quick brown fox jumps over the lazy dog." },
				{ idioma = "Francês", frase = "Où est l'hôtel près du marché ?" },
				{ idioma = "Alemão", frase = "Fußgängerüberweg vor der Straße." },
				{ idioma = "Espanhol", frase = "El niño pidió piñata para su cumpleaños." },
				{ idioma = "Polonês", frase = "Źródło wód żółtych wciąż bije." },
				{ idioma = "Russo", frase = "Москва — столица России." },
				{ idioma = "Grego", frase = "Η Αθήνα είναι όμορφη πόλη." },
				{ idioma = "Árabe", frase = "اللغة العربية جميلة جدًا." },
				{ idioma = "Hebraico", frase = "השפה העברית עתיקה מאוד." },
				{ idioma = "Chinês", frase = "中文字符测试示例。" },
				{ idioma = "Japonês", frase = "日本語の文字をテストします。" },
				{ idioma = "Coreano", frase = "한국어 문자를 시험합니다." },
				{ idioma = "Tailandês", frase = "ภาษาไทยสวยงามมาก." },
			}
			local s = ""
			for k,v in ipairs(frases) do
				s = s + "\n"..v.idioma.." ".. v.frase
			end
			return s
		end;
	};

	-------------------------------------------------------
	-- NETWORK
	-------------------------------------------------------
	sendrate = {
		---Changes the client global packet send rate.
		---@param rate number|string New send rate (default: 35)
		---@return string message Message confirming the rate change
		action = function(rate)
			local client = require "client"
			local old_rate = client.sendRate
			local new_rate = tonumber(rate) or 35

			client.sendRate = new_rate
			return string.format(
				"Global sendRate changed from %.2f to %.2f.",
				old_rate,
				new_rate
			)
		end
	};

	get = {
		---Fires an asynchronous HTTP request on a separate thread.
		---@param url string Target URL of the request
		---@param options? string Additional options passed to the thread
		action = function(url, options)
			local thread = love.thread.newThread("http_thread.lua")
			if thread then
				thread:start(url, options)
			end
		end
	};

	discordrpc = {
		---Sets a Discord Rich Presence property.
		---@param property string Name of the property to change
		---@param ... string Value to assign to the property
		---@return string? status Status returned by the discordRPC library
		action = function(property, ...)
			local value = table.concat({...}," ")
			local discordRPC = require "lib.discordRPC"
			if discordRPC then
				local status = discordRPC.setProperty(property, value)
				if status then
					return status
				end
			end
		end
	};

	ping = {
		---Prints a blank line to the console (response test).
		action = function()
			print()
		end
	};

	connect = {
		---Connects the client to a server if not already connected.
		---@param ip? string Server IP address (default: "127.0.0.1")
		---@param port? string Server port (default: "36963")
		action = function(ip, port)
			local client = require "client"
			if not client.connected then
				ip = ip or "127.0.0.1"
				port = port or "36963"
				client.load()
				client.start(string.format("%s:%s", ip, port))
			end
		end,
		syntax = "connect <ip:port>",
	};

	disconnect = {
		---Disconnects the client from the current server, if connected.
		action = function()
			local client = require "client"
			local LF = require "lib.loveframes"
			if client.connected then
				client.kick()
			end
		end,
	};

	-------------------------------------------------------
	-- UI/MISC
	-------------------------------------------------------
	--[[
	megasena = {
		action = function(seednumber)
			local seed = math.randomseed(os.time())
			if seednumber then
				seed = math.randomseed(tonumber(seednumber) or os.time())
			end
			local pool = {}
			for i = 1, 60 do
				pool[i] = i
			end

			local resultado = {}

			for i = 1, 6 do
				local idx = math.random(#pool)
				resultado[i] = pool[idx]
				table.remove(pool, idx)
			end

			table.sort(resultado)
			print("Números :" .. table.concat(resultado, " - "))
		end
	};
	--]]
	toast = {
		---Displays a temporary message (toast) on the console.
		---@param ... string Text of the message to display
		action = function(...)
			local message = table.concat({...}," ")
			local console = require "core.interface.console"

			local options = {
                spacing=8,
                padding=6,
                time=5,
				font = console.font_mono
            }
			console.toast:PushMessage(message, options)
		end,
	};

    warning = {
		---Opens a modal warning window with the given message.
		---@param ... string Text of the warning message
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

	menu = {
		---Invokes a client-side menu
		---@param ... string
		action = function(...)
			local ui = require "core.interface.ui"
			ui.menu_constructor(table.concat({...}," "))
		end;
	};

	scale = {
		---Enables or disables client render scaling.
		---@param bool "true"|"false" "true" to enable scaling
		action = function(bool)
			local client = require "client"
			client.scale = (bool == "true")
		end;
	};

	volume = {
		---Adjusts the global audio volume (clamped between 0 and 1).
		---@param level number|string Volume level between 0 and 1
		action = function(level)
			level = tonumber(level) or 0
			level = math.min(math.max(0, level), 1)
			love.audio.setVolume(level)
		end,
		alias = nil,
		syntax = "",
	};

	mute = {
		---Fully mutes the audio (volume = 0).
		action = function()
			love.audio.setVolume(0)
		end,
		alias = nil,
		syntax = "",
	};

	vsync = {
		---Enables or disables the window vertical sync (vsync).
		---@param mode "on"|"off"|"true"|"false" Desired vsync state
		---@return string message Message reporting the new vsync state
		action = function(mode)
			local width, height = love.graphics.getDimensions()
			if mode == "true" or mode == "on" then
				love.window.updateMode(width, height, {
					vsync = true;
				})
				return "vsync on"
			elseif mode == "false" or mode == "off" then
				love.window.updateMode(width, height, {
					vsync = false;
				})
				return "vsync off"
			else
				return "unknown value "..mode
			end
		end
	};

	-------------------------------------------------------
	-- REMOTE ACTIONS
	-------------------------------------------------------
	edit = {
		---Loads a map and enters edit mode (editor).
		---@param ... string Map file name (without the .map extension)
		action = function(...)
			local client = require "client"
			local args = {...}
			if client.map then
				local LF = require "lib.loveframes"
				local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
				if status then
					print(status)
				end
				client.mode = "editor"
				LF.SetState("editor")
			end
		end,
		syntax = "/edit <mapfile>",
	};

	map = {
		---Loads a map and enters game mode.
		---@param ... string Map file name (without the .map extension)
		action = function(...)
			local client = require "client"
			local args = {...}
			if client.map then
				local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
				if status then
					print(status)
				end
			end
			client.mode = "game"
		end,
		syntax = "/map <mapfile>",
	};

	clearmap = {
		---Removes all elements from the current map.
		---@param ... string Ignored arguments
		action = function(...)
			local args = {...}
			local client = require "client"
			if client.map then
				print("map clear request")
				client.map:clear()
			end
		end,
		syntax = "/clearmap",
	};

	cleareffect = {
		---Removes all active visual effects from the current map.
		action = function ()
			local client = require "client"
			if client.map then
				client.map:clearEffects()
			end
		end
	};

	effect = {
		---Spawns a visual effect at the given map coordinates.
		---@param effect_id string|number Identifier of the effect to spawn
		---@param x number|string X coordinate (default: 0)
		---@param y number|string Y coordinate (default: 0)
		action = function(effect_id, x, y)
			local client = require "client"
		    x = tonumber(x) or 0
            y = tonumber(y) or 0
            client.map:spawn_effect(effect_id, x, y)
		end,
	};

	scroll = {
		---Scrolls the current map by the given offset.
		---@param x number X scroll offset (default: 0)
		---@param y number Y scroll offset (default: 0)
		action = function(x,y)
			local client = require "client"
			if client.map then
				x = x or 0
				y = y or 0
				client.map:scroll(x, y)
			end
		end
	};

	log = {
		---Pushes a message into the server log panel.
		---@param ... string Text of the log message
		action = function (...)
			local ui = require "core.interface.ui"
			local message = table.concat({...}," ")
			ui.server_log_push(message)
		end
	};

	setname = {
		---Sends a request to change the player name (when connected).
		---@param ... string New player name
		action = function(...)
			local client = require "client"
			if client.connected then
				local name = table.concat({...}," ")
				client.send("setname "..name)
			end
		end;
	};

	say = {
		---Sends a chat message to the server.
		---@param ... string Message text
		action = function(...)
			local client = require "client"
			local message = table.concat({...}, " ")
			client.send(string.format("say %s", message))
		end;
	};

	equip = {
		---Sends a request to equip an item on a target entity.
		---@param target_id string|number Identifier of the target entity
		---@param item_type string|number Type of item to equip
		action = function(target_id, item_type)
			local client = require "client"
			client.send( string.format("equip %s %s", target_id, item_type) )
		end
	};

	tp = {
		---Teleports the player to the current cursor/target position.
		action = function()
			local client = require "client"
			local targetX = client.attribute "targetX"
			local targetY = client.attribute "targetY"

			local diff_x = (client.width/2 - targetX)
			local diff_y = (client.height/2 - targetY)

			local pos_x = client.camera.x - diff_x
			local pos_y = client.camera.y - diff_y

			client.send(string.format("setpos %s %s %s", client.id, pos_x, pos_y))
		end
	};

	follow = {
		---Makes the camera follow an entity, or unbinds it when id is 0.
		---@param category string Share category of the entity (e.g. "players")
		---@param id number|string Entity id, or 0 to unbind the camera
		---@return string? error Error message when the entity cannot be found
		action = function(category, id)
			local client = require "client"
			if not client.joined then return "Client isn't connected. Cannot follow anything." end
			id = tonumber(id) or 0
			if id == 0 then
				client.camera_unbind()
				return
			end

			local share = client.share
			if not share[category] then return "There is no category with that name" end
			if not share[category][id] then return "There is no entity with this ID" end
			local entity = share[category][id]
			if entity and entity.x and entity.y then
				client.camera_follow(entity)
			end

		end;
	};

	team = {
		---Requests a team and look change for the player.
		---@param team string Team to join
		---@param look string Look/appearance selection
		---@return string? error Error message when the client is not connected
		action = function(team, look)
			local client = require "client"
			if not client.joined then
				return "You're not connected!"
			end
			team = team or ""
			look = look or ""
			client.send(string.format("team %s %s", team, look))
		end,
		alias = {"chooseteam", "pickteam"},
	};

	kill = {
		---Sends a request to kill (suicide) the current player.
		action = function()
			local client = require "client"
			client.send("kill")
		end,
		alias = {"suicide"},
		syntax = "",
	};

	rcon = {
		---Sends a remote console (rcon) command to the server.
		---@param ... string Command and arguments to run remotely
		action = function(...)
			local command = table.concat({...}, " ")
			local client = require "client"
			client.send(string.format("rcon %s", command))
		end,
		syntax = "",
	},

	help = {
		---Lists all available commands along with their parameter names.
		---@param property string Unused (reserved for filtering a specific command)
		---@param ... string Unused extra arguments
		---@return string list Newline-separated list of commands and their parameters
		action = function(property, ...)
			local console = require "core.interface.console"
			local commands = console.input.commands
			local list = {}
			table.insert(list, "List of all commands available: ")
			for name, data in pairs(commands) do
				local argNames = {}
				local action = data.action

				for i = 1, debug.getinfo(action).nparams, 1 do
					table.insert(argNames, debug.getlocal(action, i))
				end

				table.insert(list, "©000255255"..name.." ©255255000"..table.concat( argNames, ", " ))
			end
			return table.concat(list, "\n")
		end
	};

}

return commands