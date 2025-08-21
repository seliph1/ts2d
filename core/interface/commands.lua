local client = require "client"

-- Client only commands
local commands = {
	["profile"] = {
		---@param act "start"|"stop"|"report"
		action = function(act)
			local profiler = require "lib.profi"
			if act == "start" then
				profiler:start()
			elseif act == "stop" then
				profiler:stop()
			elseif act == "report" then
				profiler:writeReport("report.txt")
			end
		end,
		syntax = "/map <mapfile>",
	};

	["map"] = {
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
	["scroll"] = {
		action = function(x,y)
			if client.map then
				x = x or 0
				y = y or 0
				client.map:scroll(x, y)
			end
		end
	};
	["edit"] = {
		action = function(...)
			local args = {...}
			if client.map then
				local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
				if status then
					print(status)
				end
				client.mode = "editor"
			end
		end,
		syntax = "/edit <mapfile>",
	};
	["ping"] = {
		action = function()
		end
	};
	["connect"] = {
		action = function(ip, port)
			ip = ip or "127.0.0.1"
			port = port or "36963"
			--client.start(string.format("%s:%s", ip, port))
			client.start(string.format("127.0.0.1:36963"))
		end,
		syntax = "connect <ip:port>",
	};
	["send"] = {
		action = function(message)
		end,
	};
	["version"] = {
		action = function()
		end,
	};
	["players"] = {
		action = function()
		end;
	};
	["name"] = {
		action = function(name)
		end;
	};
	["files"] = {
		action = function()
			if client then
				for k,v in pairs(client.gfx.items) do
					print(k,v)
				end
			end
		end;
	};
	["say"] = {
		action = function(message)
		end;
	};

	["info"] = {
		action = function()
			print(1, 2, 3, 4, 5, 6)
		end;
	};
	["scale"] = {
		action = function(bool)
			client.scale = (bool == "true")
		end;
	};
	["tp"] = {
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
	menu = {
		---Invokes a server-side menu
		---@param ... string
		action = function(...)
			local menu_constructor = table.concat({...}," ")
			local ui = require "core.interface.ui"
			local title = ui.menu_frame
			local constructors = {}
			for constructor in (menu_constructor..","):gmatch("(.-),") do
				table.insert(constructors, constructor)
			end
			title:SetName(string.format("%s", constructors[1])):SetVisible(true):MoveToTop()
			for i = 1, 9 do
				local constructor = constructors[i + 1]
				print(constructor)
				local button = ui.menu_buttons[i]
				local disabled = false
				local invisible = false
				if constructor then
					if constructor == "" then
						button:SetVisible(false)
					end
					local brackets = constructor:match("^%((.*)%)$")
					if brackets then
						button:SetEnabled(false)
						button:SetText(string.format("©128128128%s ©255255255%s", i, brackets))
					else
						button:SetEnabled(true)
						button:SetText(string.format("©128128128%s ©255255255%s", i, constructor))
					end
				else -- no constructor
					button:SetEnabled(true)
					button:SetVisible(false)
					button:SetText(string.format("©128128128%s", i))
				end
			end
		end;
	}
}

return commands