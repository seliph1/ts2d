local shaders = {}

-- Shader para inicializar a semente JFA
shaders.seed = [[
    #pragma language glsl3

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(tex, texture_coords);
        if (pixel.a > 0.1) {
            // Se for um obstáculo/luz, guarda a própria coordenada UV
            // O canal Alpha como 1.0 indica semente válida
            return vec4(texture_coords, 0.0, 1.0);
        }
        // Retorna transparente para indicar "sem semente"
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
]]

-- Shader principal do Jump Flood Algorithm (JFA)
shaders.jfa = [[
    #pragma language glsl3

    uniform Image inputTexture;
    uniform vec2 oneOverSize; // 1.0 / resolução
    uniform float uOffset;    // Tamanho do passo em pixels
    uniform bool skip;        // Pula o processamento se for o passo de inicialização vazia

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        if (skip) {
            return vec4(texture_coords, 0.0, 1.0);
        }

        vec4 nearestSeed = vec4(-2.0);
        float nearestDist = 999999.9;

        // Analisa uma vizinhança de 3x3 com o espaçamento uOffset
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            for (float x = -1.0; x <= 1.0; x += 1.0) {
                vec2 sampleUV = texture_coords + vec2(x, y) * uOffset * oneOverSize;

                // Bounds check
                if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0) {
                    continue;
                }

                vec4 sampleValue = Texel(inputTexture, sampleUV);
                vec2 sampleSeed = sampleValue.xy;

                // Verifica pelo Alpha se é uma semente válida
                if (sampleValue.a > 0.5) {
                    vec2 diff = sampleSeed - texture_coords;
                    float dist = dot(diff, diff); // Evita raiz quadrada para ganho de performance
                    if (dist < nearestDist) {
                        nearestDist = dist;
                        nearestSeed = sampleValue;
                    }
                }
            }
        }

        return nearestSeed;
    }
]]

-- Shader para converter o mapa JFA em um Campo de Distâncias Euclidiano (SDF)
shaders.distance_field = [[
    #pragma language glsl3

    uniform Image jfaTexture;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 sampleVal = Texel(jfaTexture, texture_coords);
        if (sampleVal.a > 0.5) {
            vec2 nearestSeed = sampleVal.xy;
            float dist = distance(texture_coords, nearestSeed);
            return vec4(vec3(dist), 1.0);
        }
        // Se não houver semente (improvável no JFA completo), a distância é máxima (1.0)
        return vec4(1.0, 1.0, 1.0, 1.0);
    }
]]

-- Shader de Iluminação Global por Sphere Tracing (Raymarching)
shaders.gi = [[
    #pragma language glsl3

    uniform int rayCount;
    uniform float time;
    uniform float sunAngle;
    uniform float shadowExponent = 10.0;
    uniform float shadowOpacity = 1.0;
    uniform bool showNoise;
    uniform bool showGrain;
    uniform bool useTemporalAccum;
    uniform bool enableSun;
    uniform int maxSteps;
    uniform bool shadowMaskMode;

    uniform Image sceneTexture;
    uniform Image lastFrameTexture;
    uniform Image distanceTexture;

    const float PI = 3.14159265359;
    const float TAU = 2.0 * PI;
    const float EPS = 0.001;

    const vec3 skyColor = vec3(0.02, 0.08, 0.2);
    const vec3 sunColor = vec3(0.95, 0.95, 0.9);

    // Função pseudo-aleatória baseada na posição do pixel
    float rand(vec2 co) {
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }

    // Calcula a radiação direta do céu e do sol
    vec3 sunAndSky(float rayAngle) {
        // Normaliza a diferença de ângulo para [0, TAU]
        float angleToSun = mod(rayAngle - sunAngle, TAU);

        // Intensidade baseada no ângulo relativo
        float sunIntensity = smoothstep(1.0, 0.0, angleToSun);

        return sunColor * sunIntensity + skyColor;
    }

    bool outOfBounds(vec2 uv) {
        return uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        vec4 light = Texel(sceneTexture, uv);

        // Se o pixel atual for um obstáculo ou fonte de luz original
        if (light.a > 0.1) {
            if (shadowMaskMode) {
                // No modo shadow mask, fontes de luz originais ficam transparentes (iluminadas)
                if (length(light.rgb) >= 0.1) {
                    return vec4(0.0, 0.0, 0.0, 0.0);
                }
                // Obstáculos físicos (paredes) ficam totalmente sombreados
                return vec4(0.0, 0.0, 0.0, shadowOpacity);
            }
            // Se for luz (RGB maior que zero), exibe a luz. Caso contrário, exibe o obstáculo (preto).
            if (length(light.rgb) >= 0.1) {
                return vec4(light.rgb, 1.0);
            }
            return vec4(0.0, 0.0, 0.0, 1.0);
        }

        vec4 radiance = vec4(0.0);
        float oneOverRayCount = 1.0 / float(rayCount);
        float angleStepSize = TAU * oneOverRayCount;

        // Adiciona componente dinâmico baseado no tempo se a acumulação estiver ativa
        float coef = useTemporalAccum ? time : 0.0;
        float offset = showNoise ? rand(uv + coef) : 0.0;
        float rayAngleStepSize = showGrain ? angleStepSize + offset * TAU : angleStepSize;

        // Dispara raios igualmente espaçados ao redor do pixel
        for (int i = 0; i < rayCount; i++) {
            float angle = rayAngleStepSize * (float(i) + offset) + sunAngle;
            vec2 rayDirection = vec2(cos(angle), -sin(angle));

            vec2 sampleUv = uv;
            vec4 radDelta = vec4(0.0);
            bool hitSurface = false;

            // Sphere Tracing usando o campo de distância (SDF)
            for (int step = 1; step < maxSteps; step++) {
                float dist = Texel(distanceTexture, sampleUv).r;

                sampleUv += rayDirection * dist;

                if (outOfBounds(sampleUv)) {
                    break;
                }

                // Entrou em contato com um obstáculo
                if (dist < EPS) {
                    vec4 sampleColor = Texel(sceneTexture, sampleUv);
                    // Apenas adiciona contribuição se for uma luz desenhada (RGB >= 0.1)
                    if (length(sampleColor.rgb) >= 0.1) {
                        radDelta = vec4(sampleColor.rgb, 1.0);
                    }
                    hitSurface = true;
                    break;
                }
            }

            // Se o raio se espalhou para o infinito sem bater em nada, pega luz do céu/sol
            if (!hitSurface && enableSun) {
                radDelta += vec4(sunAndSky(angle), 1.0);
            }

            radiance += radDelta;
        }

        // Média da radiação sobre o número de raios
        vec4 finalRadiance = vec4(max(light, radiance * oneOverRayCount).rgb, 1.0);

        // Se usar acumulação temporal, mistura com o frame anterior
        if (useTemporalAccum && time > 0.0) {
            vec4 prevRadiance = Texel(lastFrameTexture, uv);
            finalRadiance = mix(finalRadiance, prevRadiance, 0.9);
        }

        if (shadowMaskMode) {
            // Calcula a intensidade da luz final
            float luz = max(finalRadiance.r, max(finalRadiance.g, finalRadiance.b));
            // Inverte a luz para obter a opacidade da sombra
            float sombra = clamp(1.0 - luz, 0.0, 1.0);
            sombra = pow(sombra, shadowExponent);
            return vec4(0.0, 0.0, 0.0, sombra * shadowOpacity);
        }
        return finalRadiance;
    }
]]

-- Shader de Desfoque Bilateral (Bilateral Filter)
shaders.bilateral_blur = [[
    #pragma language glsl3

    uniform Image giTexture;         // Textura do GI acumulado
    uniform Image sceneTexture;      // Textura da cena (para identificar paredes)
    uniform Image distanceTexture;   // SDF (para manter cantos nítidos)
    uniform vec2 oneOverSize;        // 1.0 / resolução
    uniform float blurRadius;        // Raio do desfoque em pixels

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        vec4 centerScene = Texel(sceneTexture, uv);

        // Se for parede ou luz direta, não desfoca (mantém original)
        if (centerScene.a > 0.1) {
            return Texel(giTexture, uv);
        }

        vec4 sum = vec4(0.0);
        float totalWeight = 0.0;

        float centerSdf = Texel(distanceTexture, uv).r;
        vec4 centerColor = Texel(giTexture, uv);

        // Limita o loop com constantes para máxima compatibilidade com drivers antigos
        int steps = int(blurRadius);
        for (int y = -3; y <= 3; y++) {
            for (int x = -3; x <= 3; x++) {
                if (abs(x) > steps || abs(y) > steps) {
                    continue;
                }

                vec2 offset = vec2(float(x), float(y)) * oneOverSize;
                vec2 sampleUv = uv + offset;

                // Bounds check
                if (sampleUv.x < 0.0 || sampleUv.x > 1.0 || sampleUv.y < 0.0 || sampleUv.y > 1.0) {
                    continue;
                }

                // Não desfoca se o vizinho estiver dentro de uma parede
                float neighborAlpha = Texel(sceneTexture, sampleUv).a;
                if (neighborAlpha > 0.1) {
                    continue;
                }

                float neighborSdf = Texel(distanceTexture, sampleUv).r;
                vec4 neighborColor = Texel(giTexture, sampleUv);

                // Peso espacial (Gaussiano sutil)
                float r2 = float(x*x + y*y);
                float spatialWeight = exp(-r2 / (2.0 * blurRadius * blurRadius));

                // Peso geométrico (SDF) para manter bordas de sombras nítidas
                float sdfDiff = abs(centerSdf - neighborSdf);
                float geoWeight = exp(-sdfDiff * sdfDiff * 150.0);

                // Peso de intensidade/cor
                float colorDiff = length(centerColor.rgb - neighborColor.rgb);
                float colorWeight = exp(-colorDiff * colorDiff * 3.0);

                float weight = spatialWeight * geoWeight * colorWeight;

                sum += neighborColor * weight;
                totalWeight += weight;
            }
        }

        if (totalWeight > 0.0) {
            return sum / totalWeight;
        }
        return centerColor;
    }
]]

return shaders
