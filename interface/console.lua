_print = print

function print(...)
	local args = {...}
	local str = {}
	for k,v in pairs(args) do
		table.insert(str, tostring(v))
	end
	if console_window then
		--console_window:InsertText( table.concat(str," ") )
	end	
	_print(unpack(args))
end


console_frame = loveframes.Create("frame")
console_frame:SetSize(640, 480)
console_frame:SetName("Console")
console_frame:SetResizable(false)
console_frame:ShowCloseButton(false)
console_frame:SetScreenLocked(true)
--console_frame.Update = function(self)
	--console_frame:SetName(string.format("Console [FPS: %i]", love.timer.getFPS()))
--end


console_window = loveframes.Create("textinput", console_frame)
console_window:SetPos(5, 30):SetSize(630, 400)
console_window:SetMultiline(true)
console_window:SetEditable(false)
console_window:SetAutoScroll(true)
console_window:ShowLineNumbers(false)


console_input = loveframes.Create("textinput", console_frame)
console_input:SetPos(5, 435):SetWidth(630)
console_input.OnEnter = function(self, text)
	self:SetText("")
	self.parse(text)
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
			client.start("127.0.0.1:36963")

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
	
	["say"] = {
		action = function(message)
		end;
	};
}