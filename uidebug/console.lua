local ui = {}
local LF = require "lib.loveframes"
--------------------------------------------------------------------------------------------------
--Console Window Frame---------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.console_frame = LF.Create("frame"):SetSize(640, 480):SetResizable(false):SetScreenLocked(true)
:SetName("Console"):SetCloseAction("hide"):SetState("*")

ui.console_window_panel = LF.Create("panel", ui.console_frame)
:SetSize(630, 400):SetPos(5, 30)
ui.console_window = LF.Create("log", ui.console_window_panel)
:SetSize(630, 400):SetPadding(0)

ui.console_input = LF.Create("textbox", ui.console_frame)
ui.console_input:SetPos(5, 435):SetWidth(630):SetMaxHistory(1)
ui.console_input.rollback = 1
ui.console_input.history = {""}
ui.console_input.OnEnter = function(self, text)
	if text == "" then return end
    if not(self.focus) then
        return
    end
	self:SetText("")
	self.parse(text)
	table.insert(self.history, text)
	self.rollback = #self.history + 1
end

ui.console_input.OnControlKeyPressed = function(self, key)
    if not(self.focus) then
        return
    end

	if key=="up" then
		local h = ui.console_input.history
		local r = math.max(self.rollback - 1, 1)

		self:SetText(h[r])
		self:MoveCursorTo("end")
		self.rollback = r
	elseif key=="down" then
		local h = self.history
		local r = math.min(self.rollback + 1, #h)

		self:SetText(h[r])
		self:MoveCursorTo("end")
		self.rollback = r
	end
end

ui.console_input.commands = {
    lua = {
		---Evaluates a lua expression
		---@param ... string
		action = function(...)
			local env = {
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
}


ui.console_input.parse = function(str)
	local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local command_id = args[1]
	local commands = ui.console_input.commands
	if commands[ command_id ] then
		local command_object = commands[ command_id ]
		if command_object.action then
			local status = command_object.action( unpack(args,2) )
		end
	else
		print(string.format("Unknown command: %s", str))
	end
end
ui.parse = ui.console_input.parse
--- print override
_Print = print
function print(...)
	local args = {...}
	local str = {}
	for k,v in pairs(args) do
		table.insert(str, tostring(v))
	end
	if ui.console_window then
		ui.console_window:AddElement(table.concat(str,"	"), true)
	end
	_Print(...)
end

ui.console_frame:SetVisible(false)

LF.bind("all", "", "'", function()
    local bool = ui.console_frame:GetVisible()
	ui.console_frame:SetVisible(not bool):Center():MoveToTop()
end)

LF.bind("all", "", "f1", function()
    local state = LF.config["DEBUG"]
    LF.config["DEBUG"] = not state
end)