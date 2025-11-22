return function(ui)
--//------------------------ MODULE START ------------------------//--
local LF = require "lib.loveframes"

local console_in = love.thread.getChannel("console_in")
local console_out = love.thread.getChannel("console_out")

ui.console_frame = LF.Create("frame"):SetSize(640, 480):SetResizable(false):SetScreenLocked(true)
:SetName("Console"):SetCloseAction("hide"):SetState("*")

ui.console_frame.Update = function(object, dt)
    object.name = string.format("Console [%s]",love.timer.getFPS())
    local block = console_in:pop()
    if block then

        if type(block) == "string" then
			local expression, error_message = loadstring( block )
			if expression then
				local status, error_message = pcall(expression)
				if not status then
					print("©255000000LUA ERROR: "..error_message)
				end
			else
				print("©255000000LUA ERROR: "..error_message)
			end
		end


        if type(block) == "table" then
			if block.action then
				if block.action == "display_image" then
					local frame = LF.Create("frame"):SetSize(500, 500)
					local w, h = frame:GetSize()
					local scroll = LF.Create("scrollpane", frame):SetSize(w, h-30):SetY(30)
					local image_holder = LF.Create("image", scroll)
					local image_data = block.args.image_data

					if image_data then
                        local image = love.graphics.newImage(image_data)
                        if image then
						    image_holder:SetImage(image)
                        end
					end
				end

				if block.action == "display_http_response" then
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
						:SetFont(ui.font_mono_small)
						:SetColor(1,1,1,1)

					local body = block.args.body
					if body then
						label:SetText(body)
					end
				end
			end
        end -- if type(block) == "table" then

    end

    local out = console_out:pop()
    if out then
        print(out)
    end
end

ui.console_window_panel = LF.Create("panel", ui.console_frame)
:SetSize(630, 400):SetPos(5, 30)
ui.console_window = LF.Create("log", ui.console_window_panel)
:SetSize(630, 400):SetPadding(0):SetFont(ui.font_mono_small)

ui.console_input = LF.Create("textbox", ui.console_frame)
ui.console_input:SetPos(5, 435):SetWidth(630):SetMaxHistory(1):SetFont(ui.font_mono)
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

ui.console_input.commands = love.filesystem.load("core/interface/commands.lua")()
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
			if status then
				print(status)
				return
			end
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


--//------------------------ MODULE END ------------------------//--
end