local client = require "client"
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

	edit = {
		action = function(...)
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

	menu = {
		---Invokes a client-side menu
		---@param ... string
		action = function(...)
			local ui = require "core.interface.ui"
			ui.menu_constructor(table.concat({...}," "))
		end;
	};

	scale = {
		action = function(bool)
			client.scale = (bool == "true")
		end;
	};

	-------------------------------------------------------
	-- DEBUG
	-------------------------------------------------------

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
			CONSOLE_ENV.print = print
			CONSOLE_ENV.client = client
			CONSOLE_ENV.ui = ui
			CONSOLE_ENV.msg = ui.chat_frame_server_message
			CONSOLE_ENV.dump = serpent.dump

			if expression then
				setfenv(expression, CONSOLE_ENV)
				local status, error_message = pcall(expression)
				if not status then
					print("©255000000LUA ERROR: "..error_message)
				end
			else
				print("©255000000LUA ERROR: "..error_message)
			end
		end;
	};

	print = {
		action = function(...)
			local block = table.concat({...}, " ")
			local expression, error_message = loadstring( "return ".. block)
			local ui = require "core.interface.ui"
			local console = require "core.interface.console"

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
						console.window:AddElement( tostring(value) )
					end
				end
			else
				console.window:AddElement("©255000000LUA ERROR: "..error_message)
			end
		end,
		syntax = "",
	};

	dump = {
		action = function(...)
			local block = table.concat({...}, " ")
			local expression, error_message = loadstring( "return ".. block)
			local ui = require "core.interface.ui"
			local console = require "core.interface.console"

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

	map = {
		action = function(...)
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

	cleareffect = {
		action = function ()
			if client.map then
				client.map:clearEffects()
			end
		end
	};

	clearmap = {
		action = function(...)
			local args = {...}
			if client.map then
				print("map clear request")
				client.map:clear()
			end
		end,
		syntax = "/clearmap",
	};

	debug = {
		---Clear console
		action = function(level)
			client.debug_level = tonumber(level) or 0
		end;
	};

	utf8 = {
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

			for k,v in ipairs(frases) do
				print(v.idioma, v.frase)
			end
		end;
	};

	vsync = {
		---@param mode "on"|"off"|"true"|"false"
		action = function(mode)
			local width, height = love.graphics.getDimensions()
			if mode == "true" or mode == "on" then
				love.window.updateMode(width, height, {
					vsync = true;
				})
				print("vsync on")
			elseif mode == "false" or mode == "off" then
				love.window.updateMode(width, height, {
					vsync = false;
				})
				print("vsync off")
			else
				return "unknown value "..mode
			end
		end
	};

	sendrate = {
		---@param rate number
		action = function(rate)
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
		action = function(url, options)
			local thread = love.thread.newThread("http_thread.lua")
			if thread then
				thread:start(url, options)
			end
		end
	};

	discordrpc = {
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

	help = {
		action = function(property, ...)
			local ui = require "core.interface.ui"
			local commands = ui.console_input.commands

			for name, data in pairs(commands) do
				local argNames = {}
				local action = data.action
				for i = 1, debug.getinfo(action).nparams, 1 do
					table.insert(argNames, debug.getlocal(action, i))
				end

				print(name, table.concat( argNames, ", " ))

			end
		end
	};

	-------------------------------------------------------
	-- REMOTE ACTIONS
	-------------------------------------------------------
	effect = {
		action = function(effect_id, x, y)
		    x = tonumber(x) or 0
            y = tonumber(y) or 0
            client.map:spawn_effect(effect_id, x, y)
		end,
	};

	scroll = {
		action = function(x,y)
			if client.map then
				x = x or 0
				y = y or 0
				client.map:scroll(x, y)
			end
		end
	};

	log = {
		action = function (...)
			local ui = require "core.interface.ui"
			local message = table.concat({...}," ")
			ui.server_log_push(message)
		end
	};

	ping = {
		action = function()
			print()
		end
	};

	connect = {
		action = function(ip, port)
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
		action = function()
			local LF = require "lib.loveframes"
			if client.connected then
				client.kick()
			end
		end,
	};

	setname = {
		action = function(...)
			if client.connected then
				local name = table.concat({...}," ")
				client.send("setname "..name)
			end
		end;
	};

	say = {
		action = function(...)
			local message = table.concat({...}, " ")
			client.send(string.format("say %s", message))
		end;
	};

	equip = {
		action = function(target_id, item_type)
			client.send( string.format("equip %s %s", target_id, item_type) )
		end
	};

	tp = {
		action = function()
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
		action = function(category, id)
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
		action = function(team, look)
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
		action = function()
			client.send("kill")
		end,
		alias = {"suicide"},
		syntax = "",
	};

	slap = {
		action = function(target_id)
			client.send(string.format("slap %s", target_id))
		end,
		syntax = "",
	};

}

return commands