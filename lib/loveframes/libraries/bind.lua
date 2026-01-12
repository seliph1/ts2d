return function(loveframes)
---------- module start ----------
local LK   = require "love.keyboard"
local LS   = require "love.system"
local isMac = (LS.getOS() == "OS X")

loveframes.keyhandlers = {
	[ "cas"]={}, [ "ca"]={}, [ "cs"]={}, [ "as"]={}, [ "c"]={}, [ "a"]={}, [ "s"]={}, [ ""]={},
	["^cas"]={}, ["^ca"]={}, ["^cs"]={}, ["^as"]={}, ["^c"]={}, ["^a"]={}, ["^s"]={}, ["^"]={}, -- macOS only.
}

---@param system string
---@param mod_keys "cas" | "ca" | "cs" | "as" | "c" | "a" | "s" | "" | "^cas" | "^ca" | "^cs" | "^as" | "^c" | "^a" | "^s" | "^"
---@param key string
---@param action function
function loveframes.bind(system, mod_keys, key, action)
	if system == "all" or (system == "macos") == isMac then
		loveframes.keyhandlers[mod_keys][key] = action
	end
end

function loveframes.unbind(mod_keys, key)
    loveframes.keyhandlers[mod_keys][key] = nil
end

local LCTRL = isMac and "lgui" or "lctrl"
local RCTRL = isMac and "rgui" or "rctrl"
-- modKeys = getModKeys( )
-- modKeys = "cas" | "ca" | "cs" | "as" | "c" | "a" | "s" | "" | "^cas" | "^ca" | "^cs" | "^as" | "^c" | "^a" | "^s" | "^"
function loveframes.getModKeys()
	local c = LK.isDown(LCTRL,    RCTRL   )
	local a = LK.isDown("lalt",   "ralt"  )
	local s = LK.isDown("lshift", "rshift")

	if isMac and LK.isDown("lctrl", "rctrl") then
		if     c and a and s then  return "^cas"
		elseif c and a       then  return "^ca"
		elseif c and s       then  return "^cs"
		elseif a and s       then  return "^as"
		elseif c             then  return "^c"
		elseif a             then  return "^a"
		elseif s             then  return "^s"
		else                       return "^"  end
	end

	if     c and a and s then  return "cas"
	elseif c and a       then  return "ca"
	elseif c and s       then  return "cs"
	elseif a and s       then  return "as"
	elseif c             then  return "c"
	elseif a             then  return "a"
	elseif s             then  return "s"
	else                       return ""  end
end

---------- module end ----------
end