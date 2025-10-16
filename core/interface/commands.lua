local client = require "client"

-- Client only commands
local commands = {
	prediction = {
		action = function(bool)
			client.scale = (bool == "true")
		end
	};

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
		syntax = "connect <ip:port>",
	};

	players = {
		action = function()
		end;
	};

	setname = {
		action = function(...)
			if client.connected then
				local name = table.concat({...}," ")
				client.send("setname "..name)
			end
		end;
	};

	files = {
		action = function()
			--[[
			print("BRO, PLEASE SHOW ME THE IMAGE")
			local imageData = love.image.newImageData("gfx/c4/map/objects/weapons.png")
			local pixelFormat = imageData:getFormat()
			print(imageData)
			print(pixelFormat)
			]]
		end;
	};

	say = {
		action = function(...)
			local message = table.concat({...}, " ")
			client.send(string.format("say %s", message))
		end;
	};

	scale = {
		action = function(bool)
			client.scale = (bool == "true")
		end;
	};

	tp = {
		action = function()
			local home = client.home
			local share = client.share
			local diff_x = (client.width/2 - home.targetX)
			local diff_y = (client.height/2 - home.targetY)

			local pos_x = client.camera.x - diff_x
			local pos_y = client.camera.y - diff_y

			client.send(string.format("setpos %s %s %s", client.id, pos_x, pos_y))
		end
	};

	setweapon = {
		action =  function(client_id, weapon_id)
			client_id = tonumber(client_id)
			weapon_id = tonumber(weapon_id)
			print(client_id, weapon_id)
			client.send(string.format("setweapon %s %s", client_id, weapon_id))
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

	lua = {
		---Evaluates a lua expression
		---@param ... string
		action = function(...)
			local expression, error_message = loadstring(table.concat({...}," "))
			if expression then
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
}

return commands