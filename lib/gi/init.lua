local path = ...
local shaders = require(path and (path .. ".shaders") or "lib.gi.shaders")
local canvas_pool = require(path and (path .. ".canvas_pool") or "lib.gi.canvas_pool")

local GI = {}
GI.__index = GI

-- Cria uma nova instância do pipeline de Iluminação Global 2D
function GI.new(width, height)
    local self = setmetatable({}, GI)

    self.width = width
    self.height = height

    -- Escolhe o melhor formato de precisão de ponto flutuante disponível para o JFA
    local formats = love.graphics.getCanvasFormats()
    self.floatFormat = "rgba32f"
    if not formats[self.floatFormat] then
        if formats["rgba16f"] then
            self.floatFormat = "rgba16f"
        else
            self.floatFormat = "normal" -- Fallback de menor precisão
        end
    end

    -- Inicializa os Canvas necessários
    self.sceneCanvas = canvas_pool.newCanvas(width, height, "normal")
    self.seedCanvas = canvas_pool.newCanvas(width, height, self.floatFormat)
    self.jfaPingPong = canvas_pool.createPingPong(width, height, self.floatFormat)
    self.distanceCanvas = canvas_pool.newCanvas(width, height, self.floatFormat)
    self.giPingPong = canvas_pool.createPingPong(width, height, "normal")
    self.blurCanvas = canvas_pool.newCanvas(width, height, "normal")

    -- Índice do canvas ativo para Ping-Pong do GI (Acumulação Temporal)
    self.activeGi = 1
    self.sceneChanged = true

    -- Compila os Shaders do LÖVE
    self.seedShader = love.graphics.newShader(shaders.seed)
    self.jfaShader = love.graphics.newShader(shaders.jfa)
    self.dfShader = love.graphics.newShader(shaders.distance_field)
    self.giShader = love.graphics.newShader(shaders.gi)
    self.blurShader = love.graphics.newShader(shaders.bilateral_blur)

    -- Calcula o número necessário de passes para o Jump Flood
    self.passes = math.ceil(math.log(math.max(width, height)) / math.log(2))

    -- Parâmetros padrão
    self.rayCount = 128
    self.sunAngle = 0
    self.showNoise = true
    self.showGrain = false
    self.useTemporalAccum = false
    self.enableSun = false
    self.maxSteps = 16
    self.enableFboCache = false
    self.enableBilateralBlur = true
    self.blurRadius = 3.0
    self.shadowMaskMode = true

    -- Controle de acumulação temporal
    self.time = 0.0
    self.accumAmt = 60.0 -- Acumula até 60 frames
    self.isDrawing = false

    -- Inicializa filtro bilinear
    self.bilinearFilter = false
    self:updateFilters()

    return self
end

-- Limpa todas as texturas intermediárias e reinicia a acumulação
function GI:clear()
    local oldCanvas = love.graphics.getCanvas()

    love.graphics.setCanvas(self.sceneCanvas)
    love.graphics.clear(0, 0, 0, 0)

    love.graphics.setCanvas(self.seedCanvas)
    love.graphics.clear(0, 0, 0, 0)

    love.graphics.setCanvas(self.distanceCanvas)
    love.graphics.clear(1, 1, 1, 1)

    for i = 1, 2 do
        love.graphics.setCanvas(self.jfaPingPong[i])
        love.graphics.clear(0, 0, 0, 0)

        love.graphics.setCanvas(self.giPingPong[i])
        love.graphics.clear(0, 0, 0, 1)
    end

    love.graphics.setCanvas(oldCanvas)
    self.sceneChanged = true
    self:resetAccumulation()
end

-- Reseta a acumulação temporal (chamado ao desenhar ou mudar parâmetros)
function GI:resetAccumulation()
    self.time = 0.0
end

-- API para desenhar obstáculos e luzes diretamente no canvas da cena
function GI:drawToScene(drawCallback)
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.sceneCanvas)

    drawCallback()

    love.graphics.setCanvas(oldCanvas)
    self.sceneChanged = true
    self:resetAccumulation()
end

-- Altera o ângulo do sol (em radianos)
function GI:setSunAngle(angle)
    if self.sunAngle ~= angle then
        self.sunAngle = angle
        self:resetAccumulation()
    end
end

-- Altera a quantidade de raios
function GI:setRayCount(count)
    if self.rayCount ~= count then
        self.rayCount = count
        self:resetAccumulation()
    end
end

-- Ativa/desativa acumulação temporal
function GI:setTemporalAccumulation(enabled)
    if self.useTemporalAccum ~= enabled then
        self.useTemporalAccum = enabled
        self:resetAccumulation()
    end
end

-- Ativa/desativa ruído nos raios (evita bandeamento)
function GI:setNoise(enabled)
    if self.showNoise ~= enabled then
        self.showNoise = enabled
        self:resetAccumulation()
    end
end

-- Ativa/desativa o grão de areia (ruído angular)
function GI:setGrain(enabled)
    if self.showGrain ~= enabled then
        self.showGrain = enabled
        self:resetAccumulation()
    end
end

-- Ativa/desativa a iluminação do sol e céu
function GI:setSunEnabled(enabled)
    if self.enableSun ~= enabled then
        self.enableSun = enabled
        self:resetAccumulation()
    end
end

-- Ativa/desativa otimização de cache de FBO (JFA/SDF)
function GI:setFboCacheEnabled(enabled)
    if self.enableFboCache ~= enabled then
        self.enableFboCache = enabled
        self:resetAccumulation()
    end
end

-- Define os passos máximos de raymarching
function GI:setMaxSteps(steps)
    if self.maxSteps ~= steps then
        self.maxSteps = steps
        self:resetAccumulation()
    end
end

-- Informa ao pipeline se o usuário está desenhando ativamente (pausa acumulação temporariamente)
function GI:setIsDrawing(drawing)
    self.isDrawing = drawing
    if drawing then
        self:resetAccumulation()
    end
end

-- Atualiza as propriedades de filtro (interpolação bilinear) em todos os canvases
function GI:updateFilters()
    local mode = self.bilinearFilter and "linear" or "nearest"
    self.sceneCanvas:setFilter(mode, mode)
    self.seedCanvas:setFilter(mode, mode)
    self.distanceCanvas:setFilter(mode, mode)
    if self.blurCanvas then
        self.blurCanvas:setFilter(mode, mode)
    end
    if self.jfaPingPong then
        for i = 1, 2 do
            self.jfaPingPong[i]:setFilter(mode, mode)
            self.giPingPong[i]:setFilter(mode, mode)
        end
    end
end

-- Ativa ou desativa a interpolação bilinear nos canvases
function GI:setBilinearFilter(enabled)
    if self.bilinearFilter ~= enabled then
        self.bilinearFilter = enabled
        self:updateFilters()
        self:resetAccumulation()
    end
end

-- Ativa/desativa o desfoque bilateral
function GI:setBilateralBlurEnabled(enabled)
    if self.enableBilateralBlur ~= enabled then
        self.enableBilateralBlur = enabled
        self:resetAccumulation()
    end
end

-- Define o raio do desfoque bilateral
function GI:setBilateralBlurRadius(radius)
    if self.blurRadius ~= radius then
        self.blurRadius = radius
        self:resetAccumulation()
    end
end

-- Ativa/desativa o modo de máscara de sombra (apenas sombras projetadas)
function GI:setShadowMaskMode(enabled)
    if self.shadowMaskMode ~= enabled then
        self.shadowMaskMode = enabled
        self:resetAccumulation()
    end
end

-- Retorna a textura final gerada pelo pipeline
function GI:getTexture()
    if self.enableBilateralBlur then
        return self.blurCanvas
    end
    if self.useTemporalAccum then
        -- Retorna a última textura concluída (ping-pong inativo)
        return self.giPingPong[3 - self.activeGi]
    else
        return self.giPingPong[self.activeGi]
    end
end

-- Atualiza o relógio interno para acumulação temporal
function GI:update(dt)
    if self.useTemporalAccum and not self.isDrawing then
        if self.time < self.accumAmt then
            self.time = self.time + 1.0
        end
    else
        self.time = 0.0
    end
end

-- Executa o pipeline de shaders completo
function GI:renderPipeline()
    local oldCanvas = love.graphics.getCanvas()
    local oldShader = love.graphics.getShader()
    local oldColor = { love.graphics.getColor() }

    love.graphics.setColor(1, 1, 1, 1)

    if not self.enableFboCache or self.sceneChanged then
        -- ----------------------------------------------------
        -- PASSO 1: Inicialização da Semente JFA (Seed Pass)
        -- ----------------------------------------------------
        love.graphics.setCanvas(self.seedCanvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setShader(self.seedShader)
        love.graphics.draw(self.sceneCanvas, 0, 0)

        -- ----------------------------------------------------
        -- PASSO 2: Passes do Jump Flood Algorithm (JFA)
        -- ----------------------------------------------------
        local jfaInput = self.seedCanvas
        local jfaOutput = self.jfaPingPong[1]
        local activeJfaIdx = 1

        love.graphics.setShader(self.jfaShader)
        self.jfaShader:send("oneOverSize", { 1.0 / self.width, 1.0 / self.height })

        for i = 0, self.passes - 1 do
            local offset = 2 ^ (self.passes - i - 1)
            self.jfaShader:send("uOffset", offset)
            self.jfaShader:send("skip", false)
            self.jfaShader:send("inputTexture", jfaInput)

            love.graphics.setCanvas(jfaOutput)
            love.graphics.clear(0, 0, 0, 0)
            love.graphics.draw(jfaInput, 0, 0)

            -- Ping-pong swap
            jfaInput = jfaOutput
            activeJfaIdx = 3 - activeJfaIdx
            jfaOutput = self.jfaPingPong[activeJfaIdx]
        end

        -- ----------------------------------------------------
        -- PASSO 3: Geração do Campo de Distâncias (SDF)
        -- ----------------------------------------------------
        love.graphics.setCanvas(self.distanceCanvas)
        love.graphics.clear(1, 1, 1, 1)
        love.graphics.setShader(self.dfShader)
        self.dfShader:send("jfaTexture", jfaInput)
        love.graphics.draw(jfaInput, 0, 0)

        self.sceneChanged = false
    end

    -- ----------------------------------------------------
    -- PASSO 4: Raymarching & Iluminação Global (GI Pass)
    -- ----------------------------------------------------
    local currentGiOutput = self.giPingPong[self.activeGi]
    local prevGiOutput = self.giPingPong[3 - self.activeGi]

    love.graphics.setCanvas(currentGiOutput)
    love.graphics.clear(0, 0, 0, 0)

    love.graphics.setShader(self.giShader)
    self.giShader:send("rayCount", self.rayCount)
    self.giShader:send("time", self.time)
    self.giShader:send("sunAngle", self.sunAngle)
    self.giShader:send("showNoise", self.showNoise)
    self.giShader:send("showGrain", self.showGrain)
    self.giShader:send("useTemporalAccum", self.useTemporalAccum)
    self.giShader:send("enableSun", self.enableSun)
    self.giShader:send("maxSteps", self.maxSteps)
    self.giShader:send("shadowMaskMode", self.shadowMaskMode)

    self.giShader:send("sceneTexture", self.sceneCanvas)
    self.giShader:send("distanceTexture", self.distanceCanvas)

    if self.useTemporalAccum then
        self.giShader:send("lastFrameTexture", prevGiOutput)
    else
        self.giShader:send("lastFrameTexture", self.sceneCanvas)
    end

    -- Aciona o pixel shader preenchendo toda a tela de forma garantida
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- ----------------------------------------------------
    -- PASSO 5: Filtro de Suavização Bilateral (Opcional)
    -- ----------------------------------------------------
    if self.enableBilateralBlur then
        love.graphics.setCanvas(self.blurCanvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setShader(self.blurShader)
        self.blurShader:send("giTexture", currentGiOutput)
        self.blurShader:send("sceneTexture", self.sceneCanvas)
        self.blurShader:send("distanceTexture", self.distanceCanvas)
        self.blurShader:send("oneOverSize", { 1.0 / self.width, 1.0 / self.height })
        self.blurShader:send("blurRadius", self.blurRadius)

        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end

    -- Restaura os estados originais do LÖVE
    love.graphics.setShader(oldShader)
    love.graphics.setCanvas(oldCanvas)
    love.graphics.setColor(oldColor)

    -- Rotaciona ping-pong do GI
    if self.useTemporalAccum then
        self.activeGi = 3 - self.activeGi
    end
end

-- Redimensiona dinamicamente a resolução interna da simulação, preservando o desenho existente
function GI:resize(newWidth, newHeight)
    if self.width == newWidth and self.height == newHeight then
        return
    end

    local oldScene = self.sceneCanvas

    self.width = newWidth
    self.height = newHeight
    self.passes = math.ceil(math.log(math.max(newWidth, newHeight)) / math.log(2))

    -- Recria todos os Canvas com o novo tamanho
    self.sceneCanvas = canvas_pool.newCanvas(newWidth, newHeight, "normal")
    self.seedCanvas = canvas_pool.newCanvas(newWidth, newHeight, self.floatFormat)
    self.jfaPingPong = canvas_pool.createPingPong(newWidth, newHeight, self.floatFormat)
    self.distanceCanvas = canvas_pool.newCanvas(newWidth, newHeight, self.floatFormat)
    self.giPingPong = canvas_pool.createPingPong(newWidth, newHeight, "normal")
    self.blurCanvas = canvas_pool.newCanvas(newWidth, newHeight, "normal")

    -- Restaura o estado de desenho antigo para o novo canvas de cena (redimensionando proporcionalmente)
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.sceneCanvas)
    love.graphics.clear(0, 0, 0, 0)

    local oldColor = { love.graphics.getColor() }
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(oldScene, 0, 0, 0, newWidth / oldScene:getWidth(), newHeight / oldScene:getHeight())
    love.graphics.setColor(oldColor)

    love.graphics.setCanvas(oldCanvas)

    -- Aplica o filtro bilinear nos novos canvases
    self:updateFilters()

    -- Força a recomputação do pipeline JFA/SDF
    self.sceneChanged = true
    self:resetAccumulation()
end

-- Função de atalho para desenhar a iluminação final na tela
function GI:draw(x, y, r, sx, sy)
    love.graphics.draw(self:getTexture(), x or 0, y or 0, r or 0, sx or 1, sy or 1)
end

return GI
