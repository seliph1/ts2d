--				NO GLITCHES?
--		⠀⣞⢽⢪⢣⢣⢣⢫⡺⡵⣝⡮⣗⢷⢽⢽⢽⣮⡷⡽⣜⣜⢮⢺⣜⢷⢽⢝⡽⣝
--		⠸⡸⠜⠕⠕⠁⢁⢇⢏⢽⢺⣪⡳⡝⣎⣏⢯⢞⡿⣟⣷⣳⢯⡷⣽⢽⢯⣳⣫⠇
--		⠀⠀⢀⢀⢄⢬⢪⡪⡎⣆⡈⠚⠜⠕⠇⠗⠝⢕⢯⢫⣞⣯⣿⣻⡽⣏⢗⣗⠏
--		⠀ ⠀⠪⡪⡪⣪⢪⢺⢸⢢⢓⢆⢤⢀⠀⠀⠀⠀⠈⢊⢞⡾⣿⡯⣏⢮⠷⠁⠀⠀ 
--		⠀⠀⠀⠈⠊⠆⡃⠕⢕⢇⢇⢇⢇⢇⢏⢎⢎⢆⢄⠀⢑⣽⣿⢝⠲⠉⠀⠀⠀⠀ ⠀
--		⠀⠀⠀⠀⡿⠂⠠⠀⡇⢇⠕⢈⣀⠀⠁⠡⠣⡣⡫⣂⣿⠯⢪⠰⠂⠀⠀⠀⠀ ⠀
--		⠀⠀⠀⡦⡙⡂⢀⢤⢣⠣⡈⣾⡃⠠⠄⠀⡄⢱⣌⣶⢏⢊⠂⠀⠀⠀⠀⠀⠀ ⠀
--		⠀⠀⠀⢝⡲⣜⡮⡏⢎⢌⢂⠙⠢⠐⢀⢘⢵⣽⣿⡿⠁⠁⠀⠀⠀⠀⠀⠀⠀ ⠀⠀
--		⠀⠀⠨⣺⡺⡕⡕⡱⡑⡆⡕⡅⡕⡜⡼⢽⡻⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀
--		⠀⣼⣳⣫⣾⣵⣗⡵⡱⡡⢣⢑⢕⢜⢕⡝⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀
--		⣴⣿⣾⣿⣿⣿⡿⡽⡑⢌⠪⡢⡣⣣⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀
--		⡟⡾⣿⢿⢿⢵⣽⣾⣼⣘⢸⢸⣞⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀
--		⠁⠇⠡⠩⡫⢿⣝⡻⡮⣒⢽⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
---@diagnostic disable: duplicate-set-field, undefined-field, redundant-parameter

---------------------------------------------------------------------------------------
if love.getVersion() < 12 then
	love.graphics.newTextBatch = love.graphics.newText
end

local fps_cap = 1/120
--fps_cap = 0.001

function love.run()
	if love.load then love.load(love.parsedGameArguments, love.rawGameArguments) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f,g,h in love.event.poll() do
				if name == "quit" then
					if c or not love.quit or not love.quit() then
						return a or 0, b
					end
				end
				love.handlers[name](a,b,c,d,e,f,g,h)
			end
		end

		-- Update dt, as we'll be passing it to update
		local dt = love.timer and love.timer.step() or 0

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(fps_cap) end
	end
end

local loveframes 	= require "lib.loveframes"
local console 		= require "core.interface.console"

do
	--require "uidebug.uidebug"
	--return
end

local ui 			= require "core.interface.ui"
local client 		= require "client"
--local discordRPC	= require "lib.discordRPC"

local initializer = {
	["debug"] = function()
		-- VS Code debugger
		local lldebugger = require "lldebugger"
		if lldebugger then
			lldebugger.start()
		end
	end,

	["fused"] = function()
		local base_dir = love.filesystem.getSourceBaseDirectory()
		if love.getVersion() == 12 then
			assert(love.filesystem.mountFullPath(base_dir, "", "readwrite"), "failed to mount")
		else
			--assert(love.filesystem.mount(base_dir, ""), "failed to mount")
		end
	end,

	["discord"] = function()
        if discordRPC then
		    discordRPC.initialize(require "core.applicationId", true)
		    function discordRPC.ready(userId, username, discriminator, avatar)
			    print(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
		    end

		    function discordRPC.disconnected(errorCode, message)
			    print(string.format("Discord: disconnected (%d: %s)", errorCode, message))
		    end

		    function discordRPC.errored(errorCode, message)
			    print(string.format("Discord: error (%d: %s)", errorCode, message))
		    end

		    function discordRPC.joinGame(joinSecret)
			    print(string.format("Discord: join (%s)", joinSecret))
		    end

		    function discordRPC.spectateGame(spectateSecret)
			    print(string.format("Discord: spectate (%s)", spectateSecret))
		    end

		    function discordRPC.joinRequest(userId, username, discriminator, avatar)
			    print(string.format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator, avatar))
			    discordRPC.respond(userId, "yes")
		    end
        end
	end,
}

function love.load(arguments)
	if love.getVersion() ~= 12 then
		love.graphics.newTextBatch = love.graphics.newText
	end

	if arguments and type(arguments) == "table" then
		for index, argument in pairs(arguments) do
			if initializer[argument] then
				initializer[argument]()
			end
		end
	end
	love.keyboard.setTextInput(true)
	client.load()
end

function love.update( dt )
    if discordRPC then
    	discordRPC.update( dt )
    end

	loveframes.update(dt)
	client.update(dt)
end

function love.draw()
	client.draw()
	loveframes.draw()
end

function love.mousepressed(x, y, button, istouch, presses)
	loveframes.mousepressed(x, y, button, istouch, presses)
	if loveframes.GetInputObject() == false and loveframes.GetCollisionCount() < 1 then
		client.mousepressed(x, y, button, istouch, presses)
	end
end

function love.mousereleased(x, y, button, istouch, presses)
	loveframes.mousereleased(x, y, button, istouch, presses)
	client.mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
	loveframes.mousemoved(x, y, dx, dy, istouch)
	client.mousemoved(x, y)
end

function love.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
	client.wheelmoved(x, y)
end

function love.keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
	if not loveframes.GetInputObject() then
		client.keypressed(key)
	end
end

function love.keyreleased(key, unicode)
	loveframes.keyreleased(key)
	client.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end

function love.quit()
    if discordRPC then
    	discordRPC.shutdown()
    end
end

function love.resize(w, h)
	client.resize(w, h)
end
