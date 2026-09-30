local canvas_pool = {}

-- Cria um novo canvas com formato de precisão customizado
function canvas_pool.newCanvas(width, height, format)
    return love.graphics.newCanvas(width, height, {
        format = format or "normal",
        dpiscale = 1,
        mipmaps = "none"
    })
end

-- Cria um par de canvases para renderização estilo ping-pong (alternada)
function canvas_pool.createPingPong(width, height, format)
    return {
        canvas_pool.newCanvas(width, height, format),
        canvas_pool.newCanvas(width, height, format)
    }
end

return canvas_pool
