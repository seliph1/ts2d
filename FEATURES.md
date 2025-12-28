# Actions:

```
connect 50.21.187.191

```



# Features:

    Increases hudtxt unique id
    cache hudtxt message
    force update
    health info style: (health bar, percentage)
    sv_forcecamera
    entity move callback
    callback on projectiles:  spawning/colliding with wall/player/etc/stopping motion/despawning
    udp crypto/security
    add image snap on objects that has x.y property
    add search bar in new game window
    add vehicles
    NPC AI: [leaving the box will use the default AI]
     Hide number option for menu api (for example menu(uid,"title@b@n,abcdefg,hijk"))
     stop cs2d2 working when grabbing window
     remove threshold for removing black pixels from sprites
     apply shaders to objects, items, images, buildings (from map editor and script)


    entity: Func_Slick
    entity: pressure plate
    entity: valves

    client routine:
    check files
    request files from server
    load map 
    receive server data
    receive physics data
    receive player data
    receive hostage data
    receive item data
    receive entity state
    receive dynamic object data
    receive projectile data
    receive dynamic object image data
    receive tween data
    receive custom tile data
    receive map cycle
    receive enabled server mod
    switch to ingame mode



-- CONCEPTS TO STUDY
SCREEN SPACE SHADOWS
CONTACT SHADOWS

---
---Mounts a full platform-dependent path to a zip file or folder for reading or writing in love.filesystem. 
---
---@overload fun(filedata: love.FileData, mountpoint: string, appendToPath?: boolean):boolean
---@overload fun(data: love.Data, archivename: string, mountpoint: string, appendToPath?: boolean):boolean
---@param archive string # The folder or zip file in the game's save directory to mount.
---@param mountpoint string # The new path the archive will be mounted to.
---@param permission love.PermissionType
---@param appendToPath? boolean # Whether the archive will be searched when reading a filepath before or after already-mounted archives. This includes the game's source and save directories.
---@return boolean success # True if the archive was successfully mounted, false otherwise.
function love.filesystem.mountFullPath( archive, mountpoint, permission, appendToPath) end