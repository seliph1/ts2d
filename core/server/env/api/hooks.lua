-- Hook and timer management CS2D API functions

return function(cs2dAPI, server)
	--- Adds a Lua function to a hook. The function will be called when the hook event triggers.
	---@param hookname string The name of the hook to attach to (e.g., "always", "spawn", "kill")
	---@param func string The name of the Lua function to call when the hook triggers
	cs2dAPI.addhook = function(hookname, func)
		if not server.hooks[hookname] then
			server.log(7, "error",
				string.format('Lua: Cannot add function "%s" to hook "%s" (Hook does not exist).', func, hookname)
			)
			return
		end

		if server.hooks[hookname][func] then
			server.log(7, "error", "Lua: Hook already added. Use freehook if you want to remove this hook.")
			return
		end
		server.hooks[hookname][func] = true
		server.log(1, "lua", string.format('Lua: Adding function "%s" to hook "%s".', func, hookname))
	end

	--- Removes a Lua function from a hook.
	---@param hook_name string The name of the hook to remove from
	---@param function_name string The name of the Lua function to remove
	cs2dAPI.freehook = function(hook_name, function_name)
		return
	end

	--- Enables or disables a hook entirely.
	---@param hook_name string The name of the hook to modify
	---@param state integer 0 = disabled, 1 = enabled
	cs2dAPI.sethookstate = function(hook_name, state)
		return
	end

	--- Creates a timer that calls a function after a specified delay.
	---@param milliseconds number Delay in milliseconds before the function is called
	---@param function_name string The name of the Lua function to call
	---@param parameter? string Optional parameters to pass to the function
	---@param count? number Number of times to call the function (0 = infinite)
	---@return number timer_id The ID of the created timer
	cs2dAPI.timer = function(milliseconds, function_name, parameter, count)
		local timer_id, error_message = server.new_timer(milliseconds, function_name, parameter, count)
		if not timer_id then
			cs2dAPI.print("Error creating timer: " .. error_message)
		end
		return timer_id
	end

	---Removes timers which call the specified "function" with the specified "parameter".
	---If "parameter" is not set (or ""), all timers with the matching "function" will be removed.
	---If neither "function" nor "parameter" is set (or if both are ""), this will remove ALL existing timers.
	---Once a timer has been removed it won't be executed anymore.
	---Of course you can create the same time again if you want to.
	---@param function_name string The ID of the timer to remove
	---@param parameter string
	cs2dAPI.freetimer = function(function_name, parameter)
		server.free_timer_by_name(function_name, parameter)
	end

	-- Remove timer with specified ID
	---@param timer_id integer
	cs2dAPI.freetimerid = function(timer_id)
		server.free_timer(timer_id)
	end

	--- Binds a key to execute a console command.
	---@param key string The key to bind (e.g., "f1", "space")
	---@param command string The console command to execute when the key is pressed
	cs2dAPI.addbind = function(key, command)
		return
	end

	--- Removes all bindings from a specific key.
	---@param key string The key to unbind
	cs2dAPI.removeallbinds = function(key)
		return
	end

	--- Removes a specific command binding from a key.
	---@param key string The key to modify
	---@param command string The specific command to unbind from the key
	cs2dAPI.removebind = function(key, command)
		return
	end
end
