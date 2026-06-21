-- Entity, object, and hostage CS2D API functions

return function(cs2dAPI, server)
    cs2dAPI.entity = function(x, y, name)
        -- void
    end

    ---@param entity_type? number
    ---@return Entity[]
    cs2dAPI.entitylist = function(entity_type)
        local entities = server.map:getEntities(entity_type)
        return entities
    end

    cs2dAPI.inentityzone = function(entity_name, x, y)
        -- void
    end

    cs2dAPI.randomentity = function(entity_name)
        -- void
    end

    cs2dAPI.setentityaistate = function(entity_name, key, value)
        return
    end

    -- Hostage functions
    cs2dAPI.hostage = function(hostage_id, parameter)
        -- void
    end

    cs2dAPI.closehostage = function(x, y, range)
        -- void
    end

    cs2dAPI.randomhostage = function()
        -- void
    end

    -- Object functions
    cs2dAPI.object = function(object_id, parameter)
        -- void
    end

    cs2dAPI.objectat = function(x, y, type)
        -- void
    end

    cs2dAPI.objecttype = function(type_id, parameter)
        -- void
    end

    cs2dAPI.closeobjects = function(x, y, range)
        -- void
    end

    -- Item functions
    cs2dAPI.item = function(item_id, x, y, type)
        -- void
    end

    cs2dAPI.itemtype = function(type_id, parameter)
        -- void
    end

    cs2dAPI.closeitems = function(x, y, range)
        -- void
    end

    -- Projectile functions
    cs2dAPI.projectile = function(projectile_id, parameter)
        -- void
    end

    cs2dAPI.projectilelist = function(type, player_id)
        -- void
    end
end
