--//------------------------ MODULE START ------------------------//--
local LF = require "lib.loveframes"

local console = {}

local console_in = love.thread.getChannel("console_in")
local console_out = love.thread.getChannel("console_out")

local font_fallbacks = {
	--"gfx/fonts/NotoSansCJK-Regular.ttc",
	"gfx/fonts/NotoSansArabic-Regular.ttf",
	"gfx/fonts/NotoSansThai-Regular.ttf",
	"gfx/fonts/NotoSansHebrew-Regular.ttf",
	"gfx/fonts/NotoSansHindi-Regular.ttf",
}

local setFontFallbacks = function(font, size)
	local fallbacks = {}
	for index, fallback_src in ipairs(font_fallbacks) do
		local fallback = love.graphics.newFont(fallback_src, size)
		table.insert(fallbacks, fallback)
	end
	font:setFallbacks(unpack(fallbacks))
end

local font_mono = love.graphics.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 15)
setFontFallbacks(font_mono, 15)

local font_mono_small = love.graphics.newFont("gfx/fonts/NotoSansMono-Regular.ttf", 12)
setFontFallbacks(font_mono_small, 12)

console.frame = LF.Create("frame")
:SetSize(0.8, 0.8)
:SetResizable(false)
:SetScreenLocked(true)
:SetName("Console")
:SetCloseAction("hide")
:SetState("*")

console.frame.Update = function(object, dt)
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
					local scroll = LF.Create("scrollpanel", frame):SetSize(w, h-30):SetY(30)
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
					local scroll = LF.Create("scrollpanel", frame)
						:SetSize(w, h-30)
						:SetY(30)
					local label = LF.Create("label", scroll)
						:SetMaxWidth(w)
						:SetFont(font_mono_small)
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

console.input = LF.Create("textbox", console.frame)
:SetY(-8)
:SetSize(0.98, 25)
:CenterX()
:SetMaxHistory(1)
:SetFont(font_mono)

console.window_panel = LF.Create("panel", console.frame)
:SetY(30)
:SetWidth(0.98)
:Expand("bottom", 40)
:CenterX()
console.window = LF.Create("log", console.window_panel)
:Expand()
:SetPadding(0)
:SetFont(font_mono_small)

console.window.menu = LF.Create("menu", console.window)
:AddOption("Clear Console", nil, function ()
	console.window:Clear()
end)
:AddDivider()
:AddOption("Copy Line")
:AddOption("Copy All")

console.input.menu = LF.Create("menu", console.input)
:AddOption("Clear Input", nil, function() console.input:Clear() end)
:AddOption("Cut Input", nil, function() console.input:Cut() end)
:AddOption("Copy Input", nil, function() console.input:Copy() end)
:AddOption("Paste Input", nil, function() console.input:Paste() end)


console.input.rollback = 1
console.input.history = {""}
console.input.OnEnter = function(self, text)
	if text == "" then return end
    if not(self.focus) then
        return
    end
	self:SetText("")
	self.parse(text)
	table.insert(self.history, text)
	self.rollback = #self.history + 1
end

console.input.OnControlKeyPressed = function(self, key)
    if not(self.focus) then
        return
    end

	if key=="up" then
		local h = console.input.history
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

console.input.commands = love.filesystem.load("core/interface/commands.lua")()
for command, data in pairs(console.input.commands) do
	if data.alias then
		for index, alias in pairs(data.alias) do
			console.input.commands[alias] = data
		end
	end
end

console.input.parse = function(str)
	local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local command_id = args[1]
	local commands = console.input.commands
	if commands[ command_id ] then
		local command_object = commands[ command_id ]
		if command_object.action then
			local status = command_object.action( unpack(args,2) )
			if status then
				print(status)
				return status
			end
		end
	else
		local status = string.format("Unknown command: %s", str)
		print(status)
		return status
	end
end
console.parse = console.input.parse

function console.message(...)
	local str = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		table.insert(str, tostring(v))
	end
	if console.window then
		console.window:AddElement(table.concat(str, "	"), true)
	end
end

--- print override
_Print = print
function print(...)
	local str = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		v = tostring(v)
		if v == "true" then
			v = "©255255000"..v.."©255255255"
		elseif v == "false" then
			v = "©255000000"..v.."©255255255"
		elseif v == "nil" then
			v = "©255000000"..v.."©255255255"
		end
		table.insert(str, v)
	end

	if console.window then
		console.window:AddElement(table.concat(str, "	"), true)
	end
	_Print(...)
end

LF.bind("all", "", "'", function()
	local toggle = not console.frame:GetVisible()
	console.frame
	:SetVisible(toggle)
	:Center()
	:MoveToTop()
end)

LF.bind("all", "", "f1", function()
	local state = LF.config["DEBUG"]
	LF.config["DEBUG"] = not state
end)

LF.bind("all", "", "f12", function()
	love.event.quit("restart")
end)


console.frame
:SetVisible(false)
:Center()
:MoveToTop()

return console

--//------------------------ MODULE END ------------------------//--
