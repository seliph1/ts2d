-- Image and tween CS2D API functions

return function(cs2dAPI, server)
  cs2dAPI.image = function(path, x, y, mode)
    -- void
  end

  cs2dAPI.imagealpha = function(image_id, alpha)
    -- void
  end

  cs2dAPI.imageblend = function(image_id, blend_mode)
    -- void
  end

  cs2dAPI.imagecolor = function(image_id, r, g, b)
    -- void
  end

  cs2dAPI.imageframe = function(image_id, frame)
    -- void
  end

  cs2dAPI.imagehitzone = function(image_id, mode, x, y, width, height)
    -- void
  end

  cs2dAPI.imageparam = function(image_id, parameter)
    -- void
  end

  cs2dAPI.imagepos = function(image_id, x, y, rotation)
    -- void
  end

  cs2dAPI.imagescale = function(image_id, scale_x, scale_y)
    -- void
  end

  cs2dAPI.freeimage = function(image_id)
    -- void
  end

  -- Tween functions
  cs2dAPI.tween_alpha = function(image_id, duration, alpha)
    -- void
  end

  cs2dAPI.tween_animate = function(image_id, duration, frame_start, frame_end)
    -- void
  end

  cs2dAPI.tween_color = function(image_id, duration, r, g, b)
    -- void
  end

  cs2dAPI.tween_frame = function(image_id, duration, frame)
    -- void
  end

  cs2dAPI.tween_move = function(image_id, duration, x, y)
    -- void
  end

  cs2dAPI.tween_rotate = function(image_id, duration, rotation)
    -- void
  end

  cs2dAPI.tween_rotateconstantly = function(image_id, rotation_speed)
    -- void
  end

  cs2dAPI.tween_scale = function(image_id, duration, scale_x, scale_y)
    -- void
  end
end
