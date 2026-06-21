-- Detecção de Colisão entre Polígonos (SAT - Separating Axis Theorem)

local mlib = {}

-- Projeção de um polígono em um eixo
local function project_polygon(axis_x, axis_y, polygon)
    local min = math.huge
    local max = -math.huge
    for i = 1, #polygon, 2 do
        local vx, vy = polygon[i], polygon[i + 1]
        -- Produto escalar (dot product)
        local projection = vx * axis_x + vy * axis_y
        min = math.min(min, projection)
        max = math.max(max, projection)
    end
    return min, max
end

-- Verifica se duas projeções se sobrepõem
local function projections_overlap(min1, max1, min2, max2)
    return not (max1 < min2 or max2 < min1)
end

-- Pega os eixos normais (perpendiculares às arestas) de um polígono
local function get_axes(polygon)
    local axes = {}

    for i = 1, #polygon, 2 do
        local x1, y1 = polygon[i], polygon[i + 1]
        local x2, y2 = polygon[i + 2], polygon[i + 3]

        if not x2 then
            x2, y2 = polygon[1], polygon[2]
        end

        -- Vetor da aresta
        local edge_x = x2 - x1
        local edge_y = y2 - y1

        -- Normal perpendicular (rotação 90°)
        local normal_x = -edge_y
        local normal_y = edge_x

        -- Normaliza o vetor
        local length = math.sqrt(normal_x * normal_x + normal_y * normal_y)
        if length > 0 then
            normal_x = normal_x / length
            normal_y = normal_y / length

            table.insert(axes, { normal_x, normal_y })
        end
    end

    return axes
end

-- Função principal: verifica se dois polígonos estão tocando
function mlib.polygonsCollide(poly1, poly2)
    -- Validação
    if #poly1 < 6 or #poly2 < 6 then
        error("(mlib) Polígonos devem ter pelo menos 3 vértices (6 valores)")
    end
    if #poly1 % 2 ~= 0 or #poly2 % 2 ~= 0 then
        error("(mlib) Número ímpar de coordenadas")
    end

    -- Pega todos os eixos de ambos os polígonos
    local axes1 = get_axes(poly1)
    local axes2 = get_axes(poly2)

    -- Testa todos os eixos
    for _, axis in ipairs(axes1) do
        local axis_x, axis_y = axis[1], axis[2]

        local min1, max1 = project_polygon(axis_x, axis_y, poly1)
        local min2, max2 = project_polygon(axis_x, axis_y, poly2)

        -- Se encontrou um eixo separador, NÃO estão colidindo
        if not projections_overlap(min1, max1, min2, max2) then
            return false
        end
    end

    for _, axis in ipairs(axes2) do
        local axis_x, axis_y = axis[1], axis[2]

        local min1, max1 = project_polygon(axis_x, axis_y, poly1)
        local min2, max2 = project_polygon(axis_x, axis_y, poly2)

        if not projections_overlap(min1, max1, min2, max2) then
            return false
        end
    end

    -- Nenhum eixo separador encontrado = estão colidindo!
    return true
end

-- Função auxiliar: verifica se um polígono está completamente dentro de outro
function mlib.polygonContainsPolygon(outer, inner)
    -- Verifica se todos os vértices do polígono interno estão dentro do externo
    for i = 1, #inner, 2 do
        if not mlib.pointIsInsidePolygon(inner[i], inner[i + 1], outer) then
            return false
        end
    end
    return true
end

-- Ray casting para ponto dentro de polígono (corrigido)
function mlib.pointIsInsidePolygon(px, py, polygon)
    local inside = false

    if #polygon < 6 then
        error("(mlib) Polígono deve ter pelo menos 3 vértices")
    end

    for i = 1, #polygon, 2 do
        local x1, y1 = polygon[i], polygon[i + 1]
        local x2, y2 = polygon[i + 2], polygon[i + 3]

        if not x2 then
            x2, y2 = polygon[1], polygon[2]
        end

        if ((y1 > py) ~= (y2 > py)) and
            (px < (x2 - x1) * (py - y1) / (y2 - y1) + x1) then
            inside = not inside
        end
    end

    return inside
end

mlib.polygonContainsPoint = mlib.pointIsInsidePolygon

-- ============================================================================
-- TRANSFORMAÇÕES DE POLÍGONOS
-- ============================================================================

-- Gira um polígono ao redor de um ponto pivot
function mlib.rotatePolygon(polygon, pivot_x, pivot_y, angle)
    -- Converte ângulo para radianos se necessário
    local rad = angle
    local cos_a = math.cos(rad)
    local sin_a = math.sin(rad)

    for i = 1, #polygon, 2 do
        local x = polygon[i]
        local y = polygon[i + 1]

        -- Translada para origem (relativo ao pivot)
        local tx = x - pivot_x
        local ty = y - pivot_y

        -- Rotaciona
        local rx = tx * cos_a - ty * sin_a
        local ry = tx * sin_a + ty * cos_a

        -- Translada de volta
        polygon[i] = rx + pivot_x
        polygon[i + 1] = ry + pivot_y
    end
end

-- Gira polígono ao redor do seu centro (centróide)
function mlib.rotatePolygonAroundCenter(polygon, angle)
    -- Calcula centróide
    local cx, cy = 0, 0
    local count = #polygon / 2

    for i = 1, #polygon, 2 do
        cx = cx + polygon[i]
        cy = cy + polygon[i + 1]
    end

    cx = cx / count
    cy = cy / count

    mlib.rotatePolygon(polygon, cx, cy, angle)
end

-- Gira polígono ao redor de um dos seus vértices
function mlib.rotatePolygonAroundVertex(polygon, vertex_index, angle)
    if vertex_index < 1 or vertex_index > #polygon / 2 then
        error("(mlib) Índice de vértice inválido")
    end

    local i = (vertex_index - 1) * 2 + 1
    local pivot_x = polygon[i]
    local pivot_y = polygon[i + 1]

    mlib.rotatePolygon(polygon, pivot_x, pivot_y, angle)
end

-- Translada (move) um polígono
function mlib.translatePolygon(polygon, dx, dy)
    for i = 1, #polygon, 2 do
        polygon[i] = polygon[i] + dx
        polygon[i + 1] = polygon[i + 1] + dy
    end
end

-- Translada polígono usando ângulo e distância
function mlib.translatePolygonPolar(polygon, angle, distance)
    local dx = math.cos(angle) * distance
    local dy = math.sin(angle) * distance
    for i = 1, #polygon, 2 do
        polygon[i] = polygon[i] + dx
        polygon[i + 1] = polygon[i + 1] + dy
    end
end

-- Escala um polígono ao redor de um ponto
function mlib.scalePolygon(polygon, pivot_x, pivot_y, scale_x, scale_y)
    scale_y = scale_y or scale_x -- Escala uniforme se só passar um valor
    for i = 1, #polygon, 2 do
        local x = polygon[i]
        local y = polygon[i + 1]

        -- Translada para origem
        local tx = x - pivot_x
        local ty = y - pivot_y

        -- Escala
        local sx = tx * scale_x
        local sy = ty * scale_y

        -- Translada de volta
        polygon[i] = sx + pivot_x
        polygon[i + 1] = sy + pivot_y
    end
end

-- Calcula o centróide de um polígono
function mlib.getPolygonCentroid(polygon)
    local cx, cy = 0, 0
    local count = #polygon / 2

    for i = 1, #polygon, 2 do
        cx = cx + polygon[i]
        cy = cy + polygon[i + 1]
    end

    return cx / count, cy / count
end

-- Versão mais precisa usando área (para polígonos não-convexos)
function mlib.getPolygonCentroidWeighted(polygon)
    local cx, cy = 0, 0
    local area = 0
    for i = 1, #polygon, 2 do
        local x1, y1 = polygon[i], polygon[i + 1]
        local x2, y2 = polygon[i + 2], polygon[i + 3]
        if not x2 then
            x2, y2 = polygon[1], polygon[2]
        end
        -- Shoelace formula
        local cross = x1 * y2 - x2 * y1
        area = area + cross
        cx = cx + (x1 + x2) * cross
        cy = cy + (y1 + y2) * cross
    end
    area = area / 2
    if area == 0 then
        -- Fallback para centróide simples se área é zero
        return mlib.getPolygonCentroid(polygon)
    end
    cx = cx / (6 * area)
    cy = cy / (6 * area)
    return cx, cy
end

-- Calcula a bounding box de um polígono
function mlib.getPolygonBounds(polygon)
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge

    for i = 1, #polygon, 2 do
        local x, y = polygon[i], polygon[i + 1]
        min_x = math.min(min_x, x)
        min_y = math.min(min_y, y)
        max_x = math.max(max_x, x)
        max_y = math.max(max_y, y)
    end

    return min_x, min_y, max_x - min_x, max_y - min_y
end

-- Translada ponto usando ângulo e distância
function mlib.translatePointPolar(x, y, angle, distance)
    local dx = math.cos(angle) * distance
    local dy = math.sin(angle) * distance
    return x + dx, y + dy
end

mlib.translatePoint = mlib.translatePointPolar

-- ============================================================================
-- INTERSEÇÃO DE POLÍGONOS (Sutherland-Hodgman Algorithm) - Versão Simplificada
-- ============================================================================

-- Clip de um polígono contra uma aresta
local function clipPolygonEdge(polygon, x1, y1, x2, y2)
    local result = {}
    -- Vetor normal da aresta (aponta para "dentro")
    local nx = -(y2 - y1)
    local ny = x2 - x1
    for i = 1, #polygon, 2 do
        local sx, sy = polygon[i], polygon[i + 1]
        local ex, ey = polygon[i + 2], polygon[i + 3]
        if not ex then
            ex, ey = polygon[1], polygon[2]
        end
        -- Testa se pontos estão "dentro" (lado correto da aresta)
        local s_inside = (sx - x1) * nx + (sy - y1) * ny >= 0
        local e_inside = (ex - x1) * nx + (ey - y1) * ny >= 0
        if s_inside and e_inside then
            -- Ambos dentro: adiciona ponto final
            table.insert(result, ex)
            table.insert(result, ey)
        elseif s_inside and not e_inside then
            -- Saindo: adiciona interseção
            local intersects, ix, iy = mlib.lineSegmentsIntersect(
                sx, sy, ex, ey,
                x1, y1, x2, y2
            )
            if intersects then
                table.insert(result, ix)
                table.insert(result, iy)
            end
        elseif not s_inside and e_inside then
            -- Entrando: adiciona interseção e ponto final
            local intersects, ix, iy = mlib.lineSegmentsIntersect(
                sx, sy, ex, ey,
                x1, y1, x2, y2
            )
            if intersects then
                table.insert(result, ix)
                table.insert(result, iy)
            end
            table.insert(result, ex)
            table.insert(result, ey)
        end
    end

    return result
end

-- Calcula a interseção de dois polígonos convexos
function mlib.getPolygonIntersection(subject, clip)
    local result = {}
    -- Copia subject para resultado inicial
    for i = 1, #subject do
        result[i] = subject[i]
    end
    -- Clip contra cada aresta do polígono de clipping
    for i = 1, #clip, 2 do
        local x1, y1 = clip[i], clip[i + 1]
        local x2, y2 = clip[i + 2], clip[i + 3]
        if not x2 then
            x2, y2 = clip[1], clip[2]
        end
        -- Clip o polígono atual contra esta aresta
        result = clipPolygonEdge(result, x1, y1, x2, y2)
        -- Se não sobrou nada, não há interseção
        if #result == 0 then
            return {}
        end
    end
    return result
end

-- Verifica se dois polígonos têm interseção
function mlib.hasPolygonIntersection(poly1, poly2)
    local intersection = mlib.getPolygonIntersection(poly1, poly2)
    return #intersection > 0
end

-- Calcula área de um polígono (Shoelace formula)
function mlib.getPolygonArea(polygon)
    if #polygon < 6 then return 0 end
    local area = 0
    for i = 1, #polygon, 2 do
        local x1, y1 = polygon[i], polygon[i + 1]
        local x2, y2 = polygon[i + 2], polygon[i + 3]
        if not x2 then
            x2, y2 = polygon[1], polygon[2]
        end
        area = area + (x1 * y2 - x2 * y1)
    end
    return math.abs(area) / 2
end

-- Calcula área da interseção entre dois polígonos
function mlib.getIntersectionArea(poly1, poly2)
    local intersection = mlib.getPolygonIntersection(poly1, poly2)
    return mlib.getPolygonArea(intersection)
end

-- ============================================================================
-- DETECÇÃO DE INTERSEÇÃO DE ARESTAS (Simplificada)
-- ============================================================================

-- Verifica se dois segmentos de linha se intersectam
function mlib.lineSegmentsIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
    local denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    -- Linhas paralelas
    if denom == 0 then
        return false
    end
    local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    local ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom
    -- Verifica se interseção está dentro dos segmentos
    if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
        local ix = x1 + ua * (x2 - x1)
        local iy = y1 + ua * (y2 - y1)
        return true, ix, iy
    end
    return false
end

-- Encontra todos os pontos de interseção entre arestas de dois polígonos
function mlib.getPolygonIntersectionPoints(poly1, poly2)
    local intersections = {}
    for i = 1, #poly1, 2 do
        local x1, y1 = poly1[i], poly1[i + 1]
        local x2, y2 = poly1[i + 2], poly1[i + 3]
        if not x2 then
            x2, y2 = poly1[1], poly1[2]
        end
        for j = 1, #poly2, 2 do
            local x3, y3 = poly2[j], poly2[j + 1]
            local x4, y4 = poly2[j + 2], poly2[j + 3]
            if not x4 then
                x4, y4 = poly2[1], poly2[2]
            end
            local intersects, ix, iy = mlib.lineSegmentsIntersect(
                x1, y1, x2, y2,
                x3, y3, x4, y4
            )
            if intersects then
                table.insert(intersections, { x = ix, y = iy })
            end
        end
    end
    return intersections
end

-- Encontra auto-interseções de um polígono
function mlib.getPolygonSelfIntersections(polygon)
    local intersections = {}
    for i = 1, #polygon, 2 do
        local x1, y1 = polygon[i], polygon[i + 1]
        local x2, y2 = polygon[i + 2], polygon[i + 3]
        if not x2 then
            x2, y2 = polygon[1], polygon[2]
        end
        for j = i + 4, #polygon, 2 do
            local x3, y3 = polygon[j], polygon[j + 1]
            local x4, y4 = polygon[j + 2], polygon[j + 3]
            if not x4 then
                if i ~= 1 then
                    x4, y4 = polygon[1], polygon[2]
                else
                    break
                end
            end
            local intersects, ix, iy = mlib.lineSegmentsIntersect(
                x1, y1, x2, y2,
                x3, y3, x4, y4
            )
            if intersects then
                table.insert(intersections, { x = ix, y = iy })
            end
        end
    end
    return intersections
end

return mlib
