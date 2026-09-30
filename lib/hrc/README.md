# Volumetric Hierarchical Radiance Cascades (HRC) em LÖVE 12.0

Esta é uma implementação de alto desempenho e alta fidelidade do algoritmo **Volumetric Hierarchical Radiance Cascades (HRC)** adaptada para a engine LÖVE 12.0 utilizando Lua, LuaJIT e shaders GLSL.

Este projeto foi portado da versão original desenvolvida para GameMaker por Yaazarai ([Volumetric-HRC](https://github.com/Yaazarai/Volumetric-HRC)). A implementação foi otimizada para computadores domésticos e laptops, introduzindo técnicas avançadas de renderização como *Early Transmission Breakout* e *LOD Raymarching* que aceleram o processamento em mais de 30x.

---

## 1. Como Funciona (O Algoritmo e a Matemática)

O HRC resolve a equação de transferência radiativa volumétrica em tempo real de forma per-pixel, calculando a iluminação global e sombras realistas (penumbras) para fontes de luz dinâmicas e bloqueadores no plano bidimensional.

### 1.1. Estrutura de Cascatas do HRC
Diferente do Radiance Cascades clássico (que subdivide o espaço em grades bidimensionais regulares isotrópicas), o HRC utiliza **planos de sondas de radiação** orientados paralelamente à direção do frustum de visualização da câmera.
*   O algoritmo realiza o cálculo de radiação em cascatas indexadas por $i$.
*   O intervalo espacial (distância entre planos) na cascata $C_i$ é de $intrv = 2^i$ pixels.
*   Conforme a cascata aumenta, o espaçamento entre planos dobra, mas a resolução angular (número de raios/cones calculados por sonda) também dobra ($2^i$ raios).
*   Como a densidade de planos cai pela metade e o número de raios dobra, o tamanho de memória necessário para cada cascata é **constante** e igual à largura da imagem ($W$). Isso nos permite armazenar o estado completo de radiação de uma cascata em uma única textura de mesma resolução da cena ($W \times H$).

### 1.2. Integração Física de Luz (Raymarching)
Dentro de cada cone angular de abertura $\theta$, traçamos os raios que definem os limites esquerdo ($coneL$) e direito ($coneR$). O comprimento do traçado local é determinado pelo espaçamento da cascata corrente. A luz acumulada ao longo do raio é integrada em espaço linear simulando a absorção e emissividade do meio físico:
*   $tt = \exp2(-\text{Absorption} \times \text{optlen})$ (Fator de transmissão/transparência)
*   $rr = \text{Emissivity} \times (1.0 - tt)$ (Fator de luz emitida atenuada)
*   $\text{Radiance}_{\text{acumulada}} = \text{Radiance}_{\text{acumulada}} + rr \times \text{Transmit}$

Ao fim do traçado local, amostramos a radiação vinda da cascata superior ($C_{i+1}$) e a adicionamos multiplicada pela transmissão acumulada do meio:
$$\text{Radiance}_{\text{final}} = (\text{Radiance}_{\text{tracada}} \times wedge) + (\text{Transmit}_{\text{acumulada}} \times \text{Radiance}_{\text{superior}})$$
onde $wedge$ é a abertura angular daquele cone:
$$wedge = 0.5 \times (\arctan(\text{coneR}) - \arctan(\text{coneL}))$$

### 1.3. Alinhamento de Planos e Interpolação
Para mesclar as cascatas, existem dois casos baseados na paridade do plano da sonda:
*   **Planos Ímpares ($align = 1.0$):** Alinham-se perfeitamente com os planos da cascata superior $C_{i+1}$. O comprimento do traçado local é exatamente $intrv$. A radiação é a mesclagem padrão do ponto de impacto do raio.
*   **Planos Pares ($align = 2.0$):** Não possuem plano correspondente no nível superior. Para resolver o aliasing espacial, traçamos o dobro da distância ($2 \times intrv$) até o plano superior distante e fundimos. A radiação final do ponto é calculada fazendo uma interpolação linear (peso $0.5$) entre a radiação fundida distante e a própria radiância local superior no plano próximo:
    $$\text{Radiance} = 0.5 \times \text{Radiance}_{\text{distante\_fundida}} + 0.5 \times \text{Radiance}_{\text{proxima\_superior}}$$

---

## 2. Como Foi Feito (Arquitetura e Implementação)

A implementação no LÖVE 12.0 foi organizada na forma de uma biblioteca modular sob a pasta `hrc/`, separando cada responsabilidade lógica:

### 2.1. Organização de Arquivos
*   `hrc/init.lua` - Ponto de entrada que expõe a API orientada a objetos do HRC e inicializa os canvases e shaders de forma segura.
*   `hrc/util.lua` - Funções matemáticas auxiliares (cálculo de potência de 2, progressões geométricas e logs).
*   `hrc/textures.lua` - Alocação e gerenciamento de Canvases com precisão HDR (`rgba16f`) para evitar estouros na fusão de luz e filtros `nearest` para evitar sangramento bilinear de pixels.
*   `hrc/probes.lua` - Resolvedor de rotações de sonda (`probes.rotate`). Como calculamos apenas frustums de 90°, o shader de fusão é rodado 4 vezes sequencialmente aplicando rotações ortogonais ($0^\circ$, $90^\circ$, $180^\circ$, $270^\circ$).
*   `hrc/cascades.lua` - Determina recursivamente os alvos de textura de leitura e escrita de radiação.
*   `hrc/renderer.lua` - A pipeline principal. Dispara os shaders de linearização de cor, o laço de fusão das cascatas de radiação e a composição final sRGB.
*   `hrc/shaders/srgb_to_linear.glsl` - Pré-converte texturas de entrada para espaço físico linear ($color^{2.2}$).
*   `hrc/shaders/merging_hrc.glsl` - Fragment shader que calcula os raios locais e mescla as cascatas recursivamente.
*   `hrc/shaders/fluence_hrc.glsl` - Sumariza a iluminação dos 4 frustums em sRGB ($color^{1/2.2}$).

### 2.2. Adaptações de LÖVE 12.0 e GLSL
*   **Resolvedor Dinâmico de Pacote:** Ajustamos o carregamento de arquivos no topo do `init.lua` e do `renderer.lua` para resolver o caminho relativo dinamicamente. Isso permite que a pasta `hrc/` seja importada de qualquer diretório (como `libs/hrc`) de forma transparente.
*   **Portabilidade GLSL Multiplataforma:** Algumas GPUs e drivers OpenGL desktop lançam erros ao compilar comparações diretas de vetores (ex: `vec2 == vec2`). Reescrevemos as operações lógicas do shader usando operadores escalares padrão (`&&` e `||`) garantindo portabilidade para Windows, macOS e Linux.

### 2.3. Otimizações Críticas de Desempenho
A varredura crua em resolução $2048 \times 2048$ exige até **68 bilhões de passos de DDA na GPU por frame**. Para tornar a execução viável e suave em tempo real, introduzimos as seguintes otimizações:
1.  **Zero Alocações por Frame:** Canvases HDR temporários são criados apenas no início e reutilizados entre passes.
2.  **Adaptive Step Size (LOD Raymarching):** Em cascatas de nível alto (raios longos), a iluminação é de frequência muito baixa (sombras borradas). Aumentamos o passo de varredura do raio proporcionalmente ao tamanho da cascata (`step_size = max(1.0, floor(intrv / 8.0))`). Isso reduz as iterações da cascata superior de **1024 para apenas 8 passos**, garantindo velocidade mais de **30x superior** com perda visual imperceptível.
3.  **Early Transmission Breakout:** Se a transmissão acumulada do raio cair abaixo de `0.005` (luz totalmente bloqueada por uma parede), o laço de raytracing é interrompido imediatamente na GPU. Em cenários com paredes, isso remove quase todo o custo de pixels atrás de obstáculos sólidos.

---

## 3. Como Usar (Guia de Integração)

### 3.1. Instalação
Basta copiar a pasta `hrc` para dentro do seu projeto LÖVE.

### 3.2. Exemplo de Código Mínimo
```lua
local HRC = require("hrc")
local hrc

function love.load()
    -- Inicializa o HRC na resolução 1024x1024 (deve ser potência de 2)
    hrc = HRC.new(1024)
end

function love.update(dt)
    -- Atualize sua física ou posições de luzes aqui
end

function love.draw()
    -- 1. Desenhe as fontes de luz (emissividade)
    hrc:drawToEmissivity(function()
        love.graphics.setColor(1, 0.5, 0, 1) -- Luz laranja
        love.graphics.circle("fill", 512, 512, 10)
    end)
    
    -- 2. Desenhe os obstáculos/sólidos (absorção)
    -- NOTA: Emissores de luz também devem ser desenhados aqui se você quer que eles bloqueiem luz externa
    hrc:drawToAbsorption(function()
        -- Blocker opaco (absorção 1, 1, 1 absorve todas as cores)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 400, 300, 200, 50)
    end)
    
    -- 3. Execute a simulação física na GPU
    hrc:process()
    
    -- 4. Renda o resultado final na tela
    -- Roda a soma de fluência, faz a correção gama automática e exibe o resultado
    hrc:draw(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end
```

### 3.3. Recursos Avançados do Exemplo Interativo
No exemplo fornecido na pasta do projeto, você dispõe de controles avançados via teclado para verificar a simulação:
*   **Mouse:** Move um emissor de luz principal pela tela.
*   **Botão Esquerdo do Mouse:** Pinta elementos dinamicamente.
*   **Tecla `B`:** Alterna o pincel de pintura entre desenhar fontes de `Luz (Emissividade)` ou `Paredes (Absorção)`.
*   **Teclas `5`, `6`, `7`, `8`, `9`, `0`:** Alteram a cor do pincel (Vermelho, Verde, Azul, Amarelo, Ciano, Branco). 
    *   *Curiosidade:* Desenhar paredes coloridas faz com que elas atuem como filtros espectrais físicos de luz (ex: uma parede pintada de azul absorverá a luz azul, deixando passar o canal vermelho e verde!).
*   **Tecla `F`:** Liga ou desliga a lanterna do mouse para que você possa inspecionar apenas as luzes que desenhou estaticamente.
*   **Tecla `C`:** Limpa todas as suas pinturas da tela.
*   **Teclas `1`, `2`, `3`, `4`:** Modificam a resolução interna da simulação dinamicamente (`256`, `512`, `1024`, `2048`).
*   **Tecla `V`:** Alterna a exibição da tela para inspecionar os buffers crus de emissividade linear, absorção linear ou o resultado final do HRC.
