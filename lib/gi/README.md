# Pipeline de Iluminação Global 2D com SDF e JFA no LÖVE 12.0

Este repositório contém uma implementação robusta e modular de **Iluminação Global Realista em 2D** desenvolvida para a engine **LÖVE 12.0** utilizando Lua/LuaJIT e shaders em GLSL3. A técnica baseia-se na geração acelerada por GPU de um Campo de Distâncias Euclidiano (SDF) via *Jump Flood Algorithm* (JFA) para realizar *Sphere Tracing* dinâmico em tempo real.

---

## 🌟 Recursos Principais

- **Raymarching por Sphere Tracing**: Caminhamento de raio eficiente que salta distâncias seguras fornecidas pelo SDF em vez de passos fixos (Raymarching convencional).
- **Jump Flood Algorithm (JFA) acelerado por GPU**: Gera o SDF completo da cena a partir de emissores e obstáculos desenhados em apenas $\log_2(N)$ passes de shader, mantendo 60+ FPS mesmo em resoluções altas.
- **Acumulação Temporal**: Filtro inteligente que acumula a iluminação sobre vários frames consecutivos para eliminar completamente o ruído gerado por direções estocásticas de raios sem perda de desempenho.
- **Otimização de FBO Caching**: O pipeline JFA e a geração do SDF só são computados quando ocorrem alterações na geometria da cena. Se a cena estiver estática, os passos 1 a 3 são pulados, economizando ciclos valiosos de GPU.
- **Simulação Dinâmica de Céu e Sol**: Luz solar direcional difusa integrada com luz celeste atmosférica configurável em tempo real.

---

## 📐 Arquitetura do Pipeline

A simulação é processada em **4 passos sequenciais** na GPU a cada frame:

```mermaid
graph TD
    A[Cena: Scene Canvas] -->|Passo 1: Seed Shader| B(Seed Canvas: Coordenadas UV)
    B -->|Passo 2: JFA Shader (Ping-Pong)| C(JFA Output: Semente mais próxima)
    C -->|Passo 3: SDF Shader| D(Distance Canvas: SDF em pixels)
    D -->|Passo 4: GI Shader| E[Textura Final com Iluminação Global]
```

### 1. Inicialização de Sementes (Seed Pass)
Identifica todos os pixels desenhados na tela (sejam obstáculos opacos ou luzes emissivas) e escreve suas respectivas coordenadas UV normalizadas nos canais vermelho e verde. Pixels sem sementes recebem transparência total (`Alpha = 0`).

### 2. Jump Flood Algorithm (JFA Pass)
Propaga as posições das sementes de forma exponencial na GPU. Para uma textura de $512 \times 512$, o JFA executa apenas 9 iterações. A cada iteração, o passo (offset) de amostragem reduz-se pela metade ($256 \to 128 \to 64 \to \dots \to 1$), garantindo que todo pixel da imagem aponte com extrema precisão para a semente física mais próxima dele.

### 3. Geração do Campo de Distâncias (SDF Pass)
Calcula a distância euclidiana real entre a coordenada do pixel atual (`texture_coords`) e a semente mais próxima identificada pelo JFA (`nearestSeed`), gerando um mapa contínuo de distâncias que é mapeado para um FBO de ponto flutuante (`distanceCanvas`).

### 4. Raymarching & Iluminação Global (GI Pass)
Para cada pixel receptor da tela:
1. Dispara `rayCount` raios em direções igualmente espaçadas com ruído pseudo-aleatório dinâmico para evitar bandeamento cromático.
2. Faz *Sphere Tracing* marchando o raio em passos iguais ao valor lido no SDF (`distanceCanvas`).
3. Se colidir com um obstáculo (distância menor que `EPS`), verifica se ele é uma luz brilhante (RGB > 0.1) e coleta sua emissividade.
4. Se o raio escapar para fora da tela sem colisões, coleta a luz do Sol e do Céu.
5. Aplica a média de radiância de todos os raios e mistura com o frame anterior caso a **Acumulação Temporal** esteja habilitada.

---

## 📂 Estrutura de Arquivos do Módulo

O pipeline é encapsulado em uma pasta independente `gi/`, facilitando a integração em qualquer outro projeto LÖVE:

*   **`gi/canvas_pool.lua`**: Gerencia de forma limpa a alocação de canvases de textura no LÖVE 12.0, garantindo o melhor formato de precisão de ponto flutuante disponível no hardware (`rgba32f` $\to$ `rgba16f` $\to$ `normal`).
*   **`gi/shaders.lua`**: Concentra todo o código-fonte em GLSL3 de todos os shaders utilizados (`seed`, `jfa`, `distance_field` e `gi`).
*   **`gi/init.lua`**: Controla a lógica da CPU, inicializa os canvases, atualiza o tempo acumulado e orquestra os passes de renderização da GPU.

---

## 🚀 Como Integrar e Usar em seu Projeto

A biblioteca é extremamente fácil de integrar. Siga o exemplo básico abaixo:

```lua
local GI = require("gi")

local gi

function love.load()
    -- Inicializa o pipeline de GI para uma simulação interna de 400x400
    gi = GI.new(400, 400)
    
    -- Configura os parâmetros iniciais
    gi:setRayCount(32)             -- 32 raios por pixel
    gi:setMaxSteps(32)             -- Máximo de 32 passos de raymarch por raio
    gi:setSunAngle(4.2)            -- Ângulo do Sol
    gi:setTemporalAccumulation(true) -- Liga a acumulação temporal para eliminar ruído
    gi:setFboCacheEnabled(true)    -- Liga a otimização de FBO Caching
end

function love.update(dt)
    -- Atualiza o acumulador temporal
    gi:update(dt)
    
    -- Desenha os obstáculos e luzes na cena (isto só roda e invalida o cache se chamado)
    gi:drawToScene(function()
        -- Limpa a tela de cena
        love.graphics.clear(0, 0, 0, 0)
        
        -- Desenhar uma luz amarela estática
        love.graphics.setColor(1.0, 0.95, 0.70, 1.0)
        love.graphics.circle("fill", 100, 100, 30)
        
        -- Desenhar um obstáculo estático (preto com alpha > 0.1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 200, 150, 50, 50)
    end)
    
    -- Roda os shaders na GPU e gera a textura final
    gi:renderPipeline()
end

function love.load()
    -- ...
end

function love.draw()
    -- Desenha a textura iluminada na tela, escalada para o tamanho da janela
    gi:draw(0, 0, 0, love.graphics.getWidth() / gi.width, love.graphics.getHeight() / gi.height)
end
```

---

## 🎛️ Métodos de Controle da API Pública

Os seguintes métodos estão disponíveis para ajustar a iluminação em tempo real via script ou menus de depuração:

| Método | Descrição |
| :--- | :--- |
| `gi:clear()` | Limpa a cena, apaga todos os desenhos e reinicia a acumulação. |
| `gi:resize(W, H)` | Altera dinamicamente a resolução interna da simulação, redimensionando proporcionalmente os desenhos existentes. |
| `gi:drawToScene(callback)` | Escopo para desenhar emissores e obstáculos opacos no canvas da cena. Invalida o cache FBO de forma inteligente. |
| `gi:setRayCount(n)` | Ajusta a quantidade de raios por pixel (suporta qualquer valor inteiro, tipicamente entre `4` e `64`). |
| `gi:setMaxSteps(n)` | Define o limite de iterações do Sphere Tracing por raio (`8` a `48`). |
| `gi:setSunAngle(rad)` | Altera o ângulo direcional da iluminação solar (`0` a `2 * PI`). |
| `gi:setSunEnabled(bool)` | Ativa ou desativa a iluminação do sol e céu (luz de fundo). |
| `gi:setTemporalAccumulation(bool)` | Liga/desliga o acumulador temporal de quadros. |
| `gi:setFboCacheEnabled(bool)` | Liga/desliga o caching de JFA/SDF para economia de processamento da GPU. |
| `gi:setBilinearFilter(bool)` | Liga/desliga a interpolação bilinear (filtragem linear) em todas as texturas e canvases de simulação. |
| `gi:setBilateralBlurEnabled(bool)` | Liga/desliga o filtro de desfoque bilateral inteligente (suavização de sombras e penumbras sem ruído). |
| `gi:setBilateralBlurRadius(n)` | Ajusta o raio de ação do desfoque bilateral (tipicamente entre `1.0` e `3.0` pixels). |
| `gi:setShadowMaskMode(bool)` | Liga/desliga o modo de máscara de sombra (a iluminação é convertida em um canal Alpha invertido para desenhar apenas sombras). |
| `gi:setNoise(bool)` | Ativa ou desativa o ruído estocástico de dithering espacial. |
| `gi:setGrain(bool)` | Ativa ou desativa o efeito de grão angular. |
| `gi:setIsDrawing(bool)` | Informa ao pipeline se o usuário está desenhando (pausa a acumulação para evitar lag visual). |
| `gi:getTexture()` | Retorna o canvas final iluminado e pronto para renderização customizada. |
| `gi:draw(x, y, r, sx, sy)` | Função helper para desenhar rapidamente a textura final na tela. |

---

## 🎨 Controles Gráficos do Aplicativo de Teste

O executável principal (`main.lua`) inclui um painel lateral completo feito em `loveframes` contendo:
- **Modos de Exibição**: Alterna visualmente para renderizar o SDF físico gerado, as sementes do JFA ou a iluminação global resolvida.
- **Painel de Toggles**: Ligar/desligar de forma dinâmica o Sol, a Acumulação Temporal, a Textura de Grão, a Suavização, a otimização de Cache e a **Interpolação Bilinear** (filtragem linear).
- **Sliders Interativos**: Ângulo do Sol, Passos do Raymarch, Raio do Pincel e Quantidade de Raios.
- **Tamanho da Simulação**: Alterna a simulação instantaneamente em resoluções de $100 \times 100$, $200 \times 200$, $400 \times 400$ ou $800 \times 800$ mantendo a integridade da cena desenhada.
- **Pincéis Emissores**: Seleção de diferentes cores brilhantes ou borracha para apagar.
