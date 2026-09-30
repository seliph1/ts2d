-- Read gamemodes available on disk
local standard = dofile("standard.lua")
local freeplay = dofile("freeplay.lua")

-- List of gamemodes
gamemodes[0] = standard()
gamemodes[1] = freeplay()

for gamemode_id, gamemode in pairs(gamemodes) do
    gamemode.init()
end
