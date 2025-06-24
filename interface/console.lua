local loveframes = require "lib/loveframes"
local client = require "client"

_Print = print
function print(...)
	local args = {...}
	local str = {}
	for k,v in pairs(args) do
		table.insert(str, tostring(v))
	end
	if Console then
		--Console.frame:InsertText( table.concat(str," ") )
		table.insert( Console.window.history, table.concat(str, " ") )
	end
	_Print(unpack(args))
end

local console_frame = loveframes.Create("frame")
console_frame:SetSize(640, 480)
console_frame:SetName("Console")
console_frame:SetResizable(false)
console_frame:ShowCloseButton(false)
console_frame:SetScreenLocked(true)

--[[
local console_window = loveframes.Create("textinput", console_frame)
console_window:SetPos(5, 30):SetSize(630, 400)
console_window:SetMultiline(true)
console_window:SetEditable(false)
console_window:SetAutoScroll(true)
console_window:ShowLineNumbers(false)
]]

local console_window = loveframes.Create("panel", console_frame)
console_window:SetPos(5, 30):SetSize(630, 400)
console_window.Draw = function(self)
	--love.graphics.print("test", self.x, self.y)
	--if self.history then
	--	love.graphics.print(self.history[#self.history], self.x, self.y)
	--end
	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setFont(loveframes.skins.CS2D.controls.tinyfont)
	love.graphics.setColor(1,1,1,1)
	local counter = 0
	for entry = #self.history, #self.history-30, -1 do
		counter = counter + 1
		if self.history[entry] then
			love.graphics.print(self.history[entry], self.x, self.y + 400 - counter*13)
		end
	end
end
console_window.history = {}

local console_input = loveframes.Create("textinput", console_frame)
console_input:SetPos(5, 435):SetWidth(630)
console_input.rollback = 1
console_input.history = {""}
console_input.OnEnter = function(self, text)
	self:SetText("")
	self.parse(text)
	table.insert(self.history, text)
	self.rollback = #self.history + 1
end
--console_window.history = console_input.history

console_input.OnControlKeyPressed = function(self, key)
	if key=="up" then
		local h = console_input.history
		local r = math.max(self.rollback - 1, 1)

		self:SetText(h[r])
		self.rollback = r
	elseif key=="down" then
		local h = self.history
		local r = math.min(self.rollback + 1, #h)

		self:SetText(h[r])
		self.rollback = r
	end
end

console_input.parse = function(str)
	local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local command_id = args[1]
	local commands = console_input.commands
	if commands[ command_id ] then
		local command_object = commands[ command_id ]
		if command_object.action then
			local status = command_object.action( unpack(args,2) )
		end
	else
		print(string.format("Unknown command: %s", str))
	end
end

-- Client only commands
console_input.commands = {
	["map"] = {
		action = function(...)
			local args = {...}
			if client.map then
				local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
				if status then
					print(status)
				end
			end
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
			print(client.map)
		end;
	};
}

return {
	frame = console_frame,
	window = console_window,
	input = console_input,
}