local shader = {}
local path = "core/shaders/"
local shaders = {
    "rainbow",
    "earthquake",
    "crt",
    "crt_ex",
    "gaussianblur",
    "wave",
    "shockwave",
    "pixelate",
    "xbr",
    "scanlines",
    "scanlines_ex",
    "vhs",
    "lcd",
    "highlight",
    "glitch",
}

local function parseValue(val)
    val = val:match("^%s*(.-)%s*$")
    -- Array or Vector: [0.0, 1.0] or {0.0, 1.0} or comma-separated numbers: 0.0, 1.0
    if val:find(",") or val:match("^[%[{]") then
        local tbl = {}
        for num in val:gmatch("[-%d%.eE]+") do
            local n = tonumber(num)
            if n then table.insert(tbl, n) end
        end
        if #tbl > 0 then return tbl end
    end
    if val == "true" then return true end
    if val == "false" then return false end
    local num = tonumber(val)
    if num then return num end
    return val
end

local function extractDefaults(code)
    local defaults = {}
    for line in code:gmatch("[^\r\n]+") do
        -- 1. Explicit comment annotation: // @default <name> = <value>
        local name, val = line:match("^%s*//%s*@default%s+([%w_]+)%s*=%s*(.+)")
        if name and val then
            defaults[name] = parseValue(val)
        else
            -- 2. Fallback: uniform/extern <type> <name> = <val>;
            local uName, uVal = line:match("^%s*[%w_]+%s+[%w_]+%s+([%w_]+)%s*=%s*([^;]+);")
            if uName and uVal and defaults[uName] == nil then
                defaults[uName] = parseValue(uVal)
            end
        end
    end
    return defaults
end

local function sanitizeShaderGLSL(code)
    local lines = {}
    for line in code:gmatch("([^\r\n]*)\r?\n?") do
        local modLine = line
        if modLine:match("^%s*uniform%s+") or modLine:match("^%s*extern%s+") then
            modLine = modLine:gsub("(%s*=%s*[^;]+)(;)", "%2")
        end
        table.insert(lines, modLine)
    end
    return table.concat(lines, "\n")
end

local function readShaderFile(fullPath)
    if love.filesystem and love.filesystem.getInfo(fullPath) then
        return love.filesystem.read(fullPath)
    else
        local f = io.open(fullPath, "r")
        if f then
            local c = f:read("*a")
            f:close()
            return c
        end
    end
    return nil
end

local baseShader = love.graphics.newShader [[
vec4 effect(vec4 COLOR, Image TEXTURE, vec2 UV, vec2 SCREEN_UV) {
    vec4 TEXTURE_COLOR = Texel(TEXTURE, UV);
    return TEXTURE_COLOR * COLOR;
}
]]

shader.baseShader = baseShader
shader.defaults = {}

-- Determines if current runtime environment requires OpenGL ES validation
local isGles = love.system and (love.system.getOS() == "Android" or love.system.getOS() == "iOS")

for _, name in ipairs(shaders) do
    local fullPath = string.format("%s%s.glsl", path, name)
    local code = readShaderFile(fullPath)

    if code then
        local defaults = extractDefaults(code)
        local cleanCode = sanitizeShaderGLSL(code)

        -- Validate for OpenGL ES if on mobile, or fallback to desktop GL
        local validate, status = love.graphics.validateShader(isGles or false, cleanCode)
        if not validate and not isGles then
            -- Also try GLES validation report
            local glesOk, glesErr = love.graphics.validateShader(true, cleanCode)
            if not glesOk then
                print(string.format("[Shader GLES Warning] %s: %s", fullPath, glesErr))
            end
        end

        if validate then
            local ok, instance = pcall(love.graphics.newShader, cleanCode)
            if ok then
                shader[name] = instance
                shader.defaults[name] = defaults

                -- Automatically send default values to shader
                for uName, uVal in pairs(defaults) do
                    if instance:hasUniform(uName) then
                        if type(uVal) == "table" then
                            instance:send(uName, unpack(uVal))
                        else
                            instance:send(uName, uVal)
                        end
                    end
                end
            else
                shader[name] = baseShader
                print(string.format("[Shader Compile Error] [%s]: %s", fullPath, tostring(instance)))
            end
        else
            shader[name] = baseShader
            print(string.format("[Shader Validation Error] [%s]: %s", fullPath, status))
        end
    else
        shader[name] = baseShader
        print(string.format("[Shader Not Found] [%s]", fullPath))
    end
end

return shader