  shader = love.graphics.newShader [[
    extern Image palette;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) { 
      vec4 tex_color = texture2D(texture, texture_coords);
      vec2 index = vec2(tex_color.r, 0); //get color based on red
      return texture2D(palette, index);
    }]]