-- Main entry point for the env module
-- Loads all sub-modules and returns the factory function

return function(server)
------------------------
-- Load base environment
local BASE_ENV = require("env.base_env")

-- CS2D API functions
local cs2dAPI = {}

-- Load API modules
require("env.api.ai")(cs2dAPI, server)
require("env.api.hooks")(cs2dAPI, server)
require("env.api.image")(cs2dAPI, server)
require("env.api.entity")(cs2dAPI, server)
require("env.api.misc")(cs2dAPI, server)
require("env.api.player")(cs2dAPI, server)

-- Setup runtime environments (GAMEMODE_ENV, SERVER_ENV)
require("env.runtime")(cs2dAPI, BASE_ENV, server)

------------------------
end
