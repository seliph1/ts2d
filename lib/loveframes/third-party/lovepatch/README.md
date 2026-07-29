# Documentação do `lovepatch`

O arquivo [init.lua](./init.lua) da biblioteca **lovepatch** implementa uma funcionalidade de **9-slice scaling** (fatiamento em 9 partes) para a engine LÖVE (Love2D). Essa técnica é muito útil para desenhar elementos de interface (UI), como painéis e botões, permitindo que eles sejam redimensionados para qualquer largura e altura sem distorcer as bordas e cantos da imagem original.

## Como funciona?
A imagem fornecida é dividida em 9 partes (quads). Os 4 cantos são desenhados em seu tamanho original, as 4 bordas são esticadas apenas em uma direção (horizontal ou vertical), e o centro é esticado em ambas as direções para preencher o tamanho desejado.

---

## Funções da Biblioteca

### `lovepatch.load(image, arg1, arg2, arg3, arg4)`
Função principal para carregar e fatiar uma imagem. Ela identifica automaticamente se você quer bordas simétricas ou bordas com tamanhos diferentes com base no número de argumentos passados.

**Parâmetros:**
- `image` *(string | userdata)*: O caminho da imagem (string) ou o objeto da imagem já carregado (`love.graphics.Image`).
- **Uso com bordas uniformes (3 argumentos no total):**
  - `arg1` *(number)*: `edgeW` - A largura da borda (esquerda e direita).
  - `arg2` *(number)*: `edgeH` - A altura da borda (topo e base).
- **Uso com bordas diferentes (5 argumentos no total):**
  - `arg1` *(number)*: `left` - A largura da borda esquerda.
  - `arg2` *(number)*: `right` - A largura da borda direita.
  - `arg3` *(number)*: `top` - A altura da borda do topo.
  - `arg4` *(number)*: `bottom` - A altura da borda da base.

**Retorno:**
- Retorna uma tabela representando o `patch` fatiado contendo a imagem, dimensões, configurações de borda e os 9 `quads` gerados.

---

### `lovepatch.loadDiffrntEdge(image, left, right, top, bottom)`
Função interna usada por `load` para fatiar imagens onde as bordas possuem tamanhos diferentes.

**Parâmetros:**
- `image` *(userdata)*: Objeto da imagem `love.graphics.Image`.
- `left`, `right`, `top`, `bottom` *(number)*: Tamanhos das margens correspondentes (esquerda, direita, topo, base).

**Retorno:**
- Retorna o objeto do `patch` configurado.

---

### `lovepatch.loadSameEdge(image, edgeW, edgeH)`
Função interna usada por `load` para fatiar imagens onde as bordas opostas são uniformes (mesma largura para esquerda/direita e mesma altura para topo/base).

**Parâmetros:**
- `image` *(userdata)*: Objeto da imagem `love.graphics.Image`.
- `edgeW` *(number)*: Largura das bordas laterais (esquerda e direita).
- `edgeH` *(number)*: Altura das bordas verticaais (topo e base).

**Retorno:**
- Retorna o objeto do `patch` configurado.

---

### `lovepatch.draw(patch, x, y, width, height, sx, sy)`
Desenha o patch na tela com as dimensões especificadas, aplicando o algoritmo de 9-slice.

**Parâmetros:**
- `patch` *(table)*: O objeto de patch retornado por `lovepatch.load`.
- `x` *(number)*: A posição no eixo X onde o patch será desenhado.
- `y` *(number)*: A posição no eixo Y onde o patch será desenhado.
- `width` *(number)*: A largura total que o patch desenhado deve ocupar.
- `height` *(number)*: A altura total que o patch desenhado deve ocupar.
- `sx` *(number, opcional)*: Escala no eixo X dos cantos e bordas originais (padrão é `1`).
- `sy` *(number, opcional)*: Escala no eixo Y dos cantos e bordas originais (padrão é `1`).

---

## Estrutura do Objeto `patch`
Quando você usa `lovepatch.load`, ele retorna uma tabela com a seguinte estrutura interna, que é depois utilizada na função `draw`:
```lua
{
    image  = image,       -- O objeto love.graphics.Image base
    width  = imageW,      -- Largura original da imagem
    height = imageH,      -- Altura original da imagem
    left   = edgeW,       -- Tamanho da borda esquerda
    right  = edgeW,       -- Tamanho da borda direita
    top    = edgeH,       -- Tamanho da borda superior
    bottom = edgeH,       -- Tamanho da borda inferior
    quads  = { ... }      -- Array contendo os 9 quads (love.graphics.newQuad) para desenhar as fatias
}
```

> [!NOTE]
> Há também um código comentado (`drawRepeat`) no final do arquivo, sugerindo que existe a intenção futura de adicionar a capacidade de **repetir** (tile) a textura central e das bordas em vez de esticá-la (stretch), mas no momento essa funcionalidade não está habilitada/implementada por completo.
