loveframes.SetActiveSkin("CS2D")

_print = print

function print(...)
	local args = {...}
	local str = {}
	for k,v in pairs(args) do
		table.insert(str, tostring(v))
	end	
	console_window:InsertText( table.concat(str," ") )
	_print(unpack(args))
end


console_frame = loveframes.Create("frame")
console_frame:SetSize(640, 480)
console_frame:SetName("Console")
console_frame:SetResizable(false)
console_frame:ShowCloseButton(false)


console_window = loveframes.Create("textinput", console_frame)
console_window:SetPos(5, 30):SetSize(630, 400)
console_window:SetMultiline(true)
console_window:SetEditable(false)
console_window:SetAutoScroll(true)
console_window:ShowLineNumbers(false)


console_input = loveframes.Create("textinput", console_frame)
console_input:SetPos(5, 435):SetWidth(630)
console_input.rollback = 1
console_input.history = {""}
console_input.OnEnter = function(self, text)
	self:SetText("")
	parse(text)
	
	table.insert(console_input.history, text)
	console_input.rollback = #console_input.history + 1
end

console_input.OnControlKeyPressed = function(self, key)
	if key=="up" then
		local h = console_input.history
		local r = math.max(console_input.rollback - 1, 1)
		
		
		self:SetText(h[r])
		console_input.rollback = r
		
	elseif key=="down" then
		local h = console_input.history
		local r = math.min(console_input.rollback + 1, #h)

		self:SetText(h[r])
		console_input.rollback = r
	end
end

function parse(str)
	local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local command_id = args[1]
	if commands[ command_id ] then
		local command_object = commands[ command_id ]
		if command_object.action then
			local parameters = debug.getinfo(command_object.action).nparams
			if #args - 1 < parameters then
				
				if command_object.syntax then
					print(string.format("PARSE ERROR: unexpected parameters (%s). Expected: %s", str, command_object.syntax))
				else
					print(string.format("PARSE ERROR: not enough parameters to perform action (%s).", str))
				end
				return
			end
			
			local status, err = pcall(command_object.action, unpack(args, 2) )
			if not status then
				print("LUA ERROR: "..err)
			end
		end
		
	else
		print(string.format("Unknown command: %s", str))
	end
end

commands = {
	["map"] = {
		action = function(...)
			local args = {...}
			local status = mapfile_read( "maps/"..table.concat(args," ")..".map" )
			
			if status then
				print(status)
			end
		end,
		syntax = "/map <mapfile>",
	};
	
	["send"] = {
		action = function(peer_id, ...)
			local args = {...}
			local peer_id = tonumber( peer_id )
			local message = table.concat(args," ") 
			
			server.send(peer_id,message)
		end,
		syntax = "send <id> [message]",
	};
	
	["setpos"] = {
		action = function(id, x, y)
			server.setpos(tonumber(id), x, y)
		end,
		syntax = "setpos <id> <x> <y>",
	};
	
	["users"] = {
		action = function(...)
			local args = {...}
			
		end,
	}
}