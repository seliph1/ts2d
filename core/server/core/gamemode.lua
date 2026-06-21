-- Read gamemodes available on disk
local standard = dofile("standard.lua")

-- List of gamemodes
gamemodes[0] = standard()
for gamemode_id, gamemode in pairs(gamemodes) do
    gamemode.init()
end
