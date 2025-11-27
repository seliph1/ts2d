local client = require "client"
local serpent = require "lib.serpent"

-- Client only commands
local commands = {
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

	clearmap = {
		action = function(...)
			local args = {...}
			if client.map then
				print("cleared?")
				client.map:clear()
			end
		end,
		syntax = "/clearmap",
	};

	cleareffect = {
		action = function ()
			if client.map then
				client.map:clearEffects()
			end
		end
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


	lua = {
		---Evaluates a lua expression
		---@param ... string
		action = function(...)
			local env = {
				client = client,
				print = print
			}
			local block = table.concat({...}, " ")
			local expression, error_message = loadstring( block )
			if expression then
				setfenv(expression, env)
				local status, error_message = pcall(expression)
				if not status then
					print("©255000000LUA ERROR: "..error_message)
				end
			else
				print("©255000000LUA ERROR: "..error_message)
			end
		end;
	};

	clear = {
		---Clear console
		action = function()
			local ui = require "core.interface.ui"
			ui.console_window:Clear()
		end;
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

	get = {
		action = function(url, options)
			local thread = love.thread.newThread("http_thread.lua")
			if thread then
				thread:start(url, options)
			end
		end
	};

	text = {
		action = function(size)
			size = tonumber(size) or 10
			local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
			local function hugeString(len)
				local t = {}
				for i = 1, len do
					local idx = math.random(#chars)
					t[i] = chars:sub(idx, idx)
				end
				return table.concat(t)
			end
			local LF = require "lib.loveframes"
			local frame = LF.Create("frame"):SetSize(500, 500)
			local w, h = frame:GetSize()
			local panel = LF.Create("panel", frame)
				:SetSize(w, h-30)
				:SetY(30)
			local scroll = LF.Create("scrollpane", frame)
				:SetSize(w, h-30)
				:SetY(30)
			local label = LF.Create("label", scroll)
				:SetMaxWidth(w)
				:SetColor(1,1,1,1)

			local body = hugeString(size)
			if body then
				label:SetText(body)
			end
		end
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
	}
}

return commands