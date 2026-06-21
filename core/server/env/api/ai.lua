-- AI-related CS2D API functions

return function(cs2dAPI, server)
  cs2dAPI.ai_aim = function(id, x, y)
    -- void
  end

  cs2dAPI.ai_attack = function(id)
    -- void
  end

  cs2dAPI.ai_build = function(id, type, x, y, rot)
    -- void
  end

  cs2dAPI.ai_buy = function(id, item)
    -- void
  end

  cs2dAPI.ai_debug = function(id, mode)
    -- void
  end

  cs2dAPI.ai_drop = function(id)
    -- void
  end

  cs2dAPI.ai_findtarget = function(id, x, y, range, mode)
    -- void target_id
  end

  cs2dAPI.ai_freeline = function(x1, y1, x2, y2)
    -- void boolean
  end

  cs2dAPI.ai_goto = function(id, x, y, mode)
    -- void
  end

  cs2dAPI.ai_iattack = function(id, target_id)
    -- void
  end

  cs2dAPI.ai_move = function(id, direction)
    -- void
  end

  cs2dAPI.ai_radio = function(id, radio_message)
    -- void
  end

  cs2dAPI.ai_reload = function(id)
    -- void
  end

  cs2dAPI.ai_respawn = function(id)
    -- void
  end

  cs2dAPI.ai_rotate = function(id, rotation)
    -- void
  end

  cs2dAPI.ai_say = function(id, text)
    -- void
  end

  cs2dAPI.ai_sayteam = function(id, text)
    -- void
  end

  cs2dAPI.ai_selectweapon = function(id, type)
    -- void
  end

  cs2dAPI.ai_spray = function(id)
    -- void
  end

  cs2dAPI.ai_use = function(id)
    -- void
  end
end
