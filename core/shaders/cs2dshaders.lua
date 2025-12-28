local shader = {}
local path = "core/shaders/"
local shaders = {
    "rainbow",
    "earthquake",
    "crt",
    "gaussianblur",
    "wave",
    "shockwave",
}

local baseShader = love.graphics.newShader [[
vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    TEXTURE_COLOR = TEXTURE_COLOR;

    return TEXTURE_COLOR * COLOR;
}
]]

shader.baseShader = baseShader
for index, name in pairs(shaders) do
    local fullPath = string.format("%s%s.glsl", path, name)
    local validate, status = love.graphics.validateShader(false, fullPath)
    if validate then
        shader[name] = love.graphics.newShader ( fullPath )
    else
        shader[name] = baseShader
        print(status)
    end
end

return shader