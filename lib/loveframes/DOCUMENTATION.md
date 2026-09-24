# Manual de Referência Completo: LoveFrames (TS2D Edition)

Este manual é uma referência técnica e exaustiva da biblioteca **LoveFrames** adaptada para a engine **TS2D / CS2D**. O objetivo deste documento é permitir a consulta rápida de métodos, assinaturas, parâmetros, propriedades e callbacks sem a necessidade de inspecionar os arquivos-fonte em Lua.

---

# Índice Geral

1. [Configuração Global e Ciclo de Vida](#1-configuração-global-e-ciclo-de-vida)
2. [Sistema de Estados (`States`)](#2-sistema-de-estados-states)
3. [Formatador de Cores e Texto (`©RRRGGGBBB`)](#3-formatador-de-cores-e-texto-rrrgggbbb)
4. [Classe `Base` — API Universal](#4-classe-base--api-universal)
   - 4.1 [Posição e Âncoras](#41-posição-e-âncoras)
   - 4.2 [Dimensões](#42-dimensões)
   - 4.3 [Utilitários de Layout Fluido (*Chaining*)](#43-utilitários-de-layout-fluido-chaining)
   - 4.4 [Hierarquia e Ciclo de Vida](#44-hierarquia-e-ciclo-de-vida)
   - 4.5 [Visibilidade e Atualização](#45-visibilidade-e-atualização)
   - 4.6 [Interação, Colisão e Foco](#46-interação-colisão-e-foco)
   - 4.7 [Arrasto, Redimensionamento e Skins](#47-arrasto-redimensionamento-e-skins)
5. [Catálogo Completo de Componentes](#5-catálogo-completo-de-componentes)
   - [Button](#button)
   - [Textbutton](#textbutton)
   - [Imagebutton](#imagebutton)
   - [Imagelink](#imagelink)
   - [Checkbox](#checkbox)
   - [Radiobutton](#radiobutton)
   - [Toggle](#toggle)
   - [Input](#input)
   - [Textbox](#textbox)
   - [Codebox](#codebox)
   - [Numberbox](#numberbox)
   - [Stepper](#stepper)
   - [Slider](#slider)
   - [Dial](#dial)
   - [Frame](#frame)
   - [Panel](#panel)
   - [Container](#container)
   - [Scrollpanel](#scrollpanel)
   - [Dockzone](#dockzone)
   - [Tabs](#tabs)
   - [Collapsiblecategory](#collapsiblecategory)
   - [Grid](#grid)
   - [Columnlist](#columnlist)
   - [Droplist](#droplist)
   - [Multichoice](#multichoice)
   - [Tree](#tree)
   - [Menu](#menu)
   - [Menubar & Menubarmenu](#menubar--menubarmenu)
   - [Label](#label)
   - [Image](#image)
   - [Progressbar](#progressbar)
   - [Loading](#loading)
   - [Toast](#toast)
   - [Messagebox](#messagebox)
   - [Filebrowser](#filebrowser)
   - [Colorpicker](#colorpicker)
   - [Joystick](#joystick)
   - [Carousel & Slideshow](#carousel--slideshow)
   - [Log](#log)
   - [Sysl](#sysl)
   - [Graphfield & Graphnode](#graphfield--graphnode)
6. [Exemplos e Receitas Prontas](#6-exemplos-e-receitas-prontas)

---

# 1. Configuração Global e Ciclo de Vida

O LoveFrames é importado via `require "lib.loveframes"`. O objeto exportado atua como gerenciador global.

### Configurações Globais (`LF.config`)
- `LF.config["ACTIVESKIN"]` *(string)*: Define a skin ativa padrão (ex.: `"CS2D"`).
- `LF.config["DEFAULTSKIN"]` *(string)*: Skin de fallback (padrão `"CS2D"`).
- `LF.config["DEBUG"]` *(boolean)*: Quando `true`, desenha retângulos de colisão, caixas de clique e contadores de desenho. Permite deletar o elemento sob o mouse pressionando a tecla `Delete`.
- `LF.config["ENABLE_SYSTEM_CURSORS"]` *(boolean)*: Habilita a mudança automática de cursores do sistema (`arrow`, `hand`, `ibeam`, etc.).
- `LF.config["ENABLE_KEY_NAVIGATION"]` *(boolean)*: Habilita navegação e foco de elementos via teclas de direção e ativação por tecla configurada.

### Métodos Globais da Biblioteca
- `LF.Create(tipo, [parent])`: Instancia um objeto do tipo informado e define seu `parent` (padrão é `LF.base`).
- `LF.Create(tabela_declarativa)`: Cria hierarquias completas a partir de uma tabela de definições.
- `LF.SetState(name)`: Troca o estado da interface.
- `LF.GetState()`: Retorna o nome do estado ativo atual.
- `LF.SetActiveSkin(name)`: Altera a skin ativa global.
- `LF.GetActiveSkin()`: Retorna a tabela da skin atual.
- `LF.SetCursor(tipo, arquivo_ou_imagedata, ox, oy)`: Registra um cursor customizado.
- `LF.GetHoverObject()`: Retorna o objeto que está atualmente sob o mouse (ou `false`).
- `LF.GetInputObject()`: Retorna o objeto que detém o foco de digitação (ou `false`).
- `LF.GetCollisionCount()`: Retorna o total de elementos da UI que colidiram com as coordenadas do mouse no frame.
- `LF.GetModalObject()`: Retorna o objeto modal ativo que está bloqueando a UI de fundo.
- `LF.CreateSprite(path)`: Carrega uma imagem tornando transparente a cor magenta `(255, 0, 255)`.
- `LF.CreateSpriteSheet(path, tileW, tileH)`: Corta uma imagem em retângulos iguais retornando tabelas com as `Image`s e `ImageData`s.

### Integração nos Callbacks do LÖVE
Em seu loop principal (`main.lua`), repasse os eventos:

```lua
local LF = require "lib.loveframes"

function love.update(dt)
    LF.update(dt)
end

function love.draw()
    LF.draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    LF.mousepressed(x, y, button, istouch, presses)
    -- Trava cliques no jogo se o mouse clicou em um elemento da UI:
    if LF.GetInputObject() == false and LF.GetCollisionCount() < 1 then
        -- Processar cliques do jogo aqui
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    LF.mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    LF.mousemoved(x, y, dx, dy, istouch)
end

function love.wheelmoved(x, y)
    LF.wheelmoved(x, y)
end

function love.keypressed(key, isrepeat)
    LF.keypressed(key, isrepeat)
    if not LF.GetInputObject() then
        -- Teclas do jogo aqui
    end
end

function love.keyreleased(key)
    LF.keyreleased(key)
end

function love.textinput(text)
    LF.textinput(text)
end
```

---

# 2. Sistema de Estados (`States`)

O LoveFrames utiliza estados para alternar entre diferentes interfaces sem alocar ou desalocar objetos a todo momento.

- `LF.SetState("nome")`: Torna ativo o estado indicado. Apenas objetos criados nesse estado ou com o curinga `"*"` serão desenhados e atualizados.
- `object:SetState("nome")`: Atribui o objeto a um estado específico.
- `object:GetState()`: Retorna o estado ao qual o objeto pertence.
- `object:OnState()`: Retorna se o objeto pertence ao estado atual ou se possui o estado curinga `*`.

### O Curinga `"*"`
Se um elemento tiver seu estado definido como `"*"`, ele será renderizado e atualizado em **qualquer estado**. É a escolha padrão para:
- O Console de comandos.
- Menus globais de Opções / Configurações de Áudio e Vídeo.
- Notificações na tela (`toast`).

---

# 3. Formatador de Cores e Texto (`©RRRGGGBBB`)

O LoveFrames integrado ao TS2D analisa sequências iniciadas por `©` seguido de 9 dígitos numéricos:
- Formato: `©RRRGGGBBB`
- Valores de `000` a `255` para cada canal.

### Tabela de Cores Frequentes:
| Sequência | Cor |
| :--- | :--- |
| `©255000000` | Vermelho |
| `©000255000` | Verde |
| `©000000255` | Azul |
| `©255255000` | Amarelo |
| `©000255255` | Ciano |
| `©255000255` | Magenta |
| `©255255255` | Branco puro |
| `©192192192` | Cinza claro padrão do menu |
| `©128128128` | Cinza médio |
| `©000000000` | Preto |

Você pode interpolar várias cores na mesma string de botões, labels, colunas e toasts:
```lua
label:SetText("Jogador: ©000255000Admin ©192192192(Vida: ©255000000100%©192192192)")
```

---

# 4. Classe `Base` — API Universal

Todos os elementos de interface herdam os métodos de `Base`. Quase todos os métodos retornam `self`, permitindo encadeamento fluente (*method chaining*).

## 4.1 Posição e Âncoras
- `SetPos(x, y, [center])`: Define a posição relativa ao pai.
  - **Fração Percentual**: Se `0 <= math.abs(v) < 1`, o valor é multiplicado pela dimensão correspondente do pai (ex.: `0.5` posiciona a 50% da largura/altura do pai).
  - **Coordenadas Negativas**: Um valor negativo posiciona o elemento medido a partir da borda direita/inferior do pai (`pai.largura - obj.largura - math.abs(x)`).
  - `center`: Se `true`, subtrai metade da largura e da altura do próprio elemento, centralizando o ponto pivô.
- `SetAbsolutePos(x, y, [center])`: Define coordenadas absolutas em relação à janela do jogo, ignorando a posição do pai.
- `SetX(x, [center])` / `SetY(y, [center])`: Altera apenas um eixo (com suporte a porcentagens e negativos).
- `GetPos()`: Retorna `x, y` relativos ao pai.
- `GetX()` / `GetY()`: Retorna as coordenadas individuais.
- `GetStaticPos()` / `GetStaticX()` / `GetStaticY()`: Retorna as coordenadas base desconsiderando rolagens de contêineres de scroll.
- `Center()`: Centraliza o elemento no pai horizontal e verticalmente.
- `CenterX()` / `CenterY()`: Centraliza apenas no eixo horizontal ou vertical.
- `CenterWithinArea(x, y, w, h)`: Centraliza o elemento dentro de uma caixa retangular arbitrária.
- `MoveToParent()`: Recalcula e sincroniza a posição com base no pai atual.

## 4.2 Dimensões
- `SetSize(w, h)`: Define largura e altura. Se `w` ou `h` estiver entre `0` e `< 1`, adota o percentual da largura/altura do pai.
- `SetWidth(w)` / `SetHeight(h)`: Altera uma dimensão individual.
- `GetSize([padding])`: Retorna `width, height`. Se `padding` for `true`, deduz o espaçamento interno.
- `GetWidth([padding])` / `GetHeight([padding])`: Retorna largura ou altura individual.
- `SetRetainSize(bool)` / `GetRetainSize()`: Mantém o tamanho intacto mesmo se o layout do pai tentar recalcular.

## 4.3 Utilitários de Layout Fluido (*Chaining*)
Estes métodos evitam a matemática manual de posicionamento de interfaces:
- `AlignLeft(margin)`: Move o objeto para encostar na borda esquerda do pai com margem opcional (padrão `0`).
- `AlignRight(margin)`: Move para encostar na borda direita do pai.
- `AlignTop(margin)`: Move para encostar no topo do pai.
- `AlignBottom(margin)`: Move para encostar no rodapé do pai.
- `AlignTo(target, axis)`: Alinha com as bordas de outro elemento `target`. `axis` pode ser `"top"`, `"bottom"`, `"left"`, `"right"`.
- `AlignChildren(axis, ...)`: Alinha automaticamente os filhos do contêiner no eixo fornecido.
- `Stack(distance, element, align, snap)`: Posiciona o objeto adjacente a outro (`element`) mantendo uma distância (`distance`) e alinhamento opcional.
- `Spread(align, ...)`: Distribui uniformemente os elementos filhos ao longo do espaço disponível.
- `Wrap(margin)`: Redimensiona a largura e altura do elemento para acomodar com precisão todos os seus filhos.
- `Expand(direction, margin)`: Estica a dimensão até o limite da borda do pai na direção informada (`"down"`, `"up"`, `"left"`, `"right"`).
- `ExpandTo(object, axis, margin)`: Estica o tamanho até alcançar o limite de outro objeto.
- `ExpandDown(margin)` / `ExpandUp(margin)` / `ExpandLeft(margin)` / `ExpandRight(margin)`: Atalhos de expansão rápida.

## 4.4 Hierarquia e Ciclo de Vida
- `SetParent(parent)`: Transfere o elemento para um novo contêiner pai.
- `GetParent()`: Retorna o objeto pai imediato.
- `GetBaseParent()`: Retorna o ancestral mais alto da hierarquia (geralmente `LF.base` ou um `frame`).
- `GetParents()`: Retorna uma lista ordenada com todos os ancestrais.
- `GetChildren()`: Retorna a tabela contendo todos os elementos filhos.
- `GetInternals()`: Retorna a lista de componentes internos (ex.: barras de scroll, botões de fechar).
- `MoveToTop()`: Traz o objeto para a frente de todos os seus irmãos no contêiner pai.
- `IsTopChild()`: Retorna `true` se o objeto for o elemento mais no topo dentro do seu pai.
- `SetDrawOrder(order)` / `GetDrawOrder()`: Define ou obtém a ordem manual de renderização.
- `Remove()`: Destrói o elemento, todos os seus filhos e remove suas referências.
- `RemoveChildren(...)`: Remove todos os filhos ou uma lista específica de filhos.

## 4.5 Visibilidade e Atualização
- `SetVisible(bool)` / `GetVisible()`: Define ou consulta se o elemento está visível. Se invisível, seus filhos também não são renderizados.
- `ToggleVisibility()`: Alterna entre visível e invisível.
- `SetAlwaysUpdate(bool)` / `GetAlwaysUpdate()`: Quando `true`, força o objeto a executar sua lógica de `update` mesmo estando invisível.
- `IsActive()`: Retorna se o objeto está visível, no estado correto e com seus pais ativos.

## 4.6 Interação, Colisão e Foco
- `CheckHover()`: Executa o teste de colisão contra as coordenadas atuais do mouse.
- `GetHover()`: Retorna `true` se o mouse está sobre o elemento.
- `GetHoverTime()`: Retorna o tempo contínuo (em segundos) que o mouse repousa sobre ele.
- `SetClickBounds(x, y, w, h)`: Restringe a zona de clique a uma subárea retangular.
- `GetClickBounds()` / `RemoveClickBounds()`: Obtém ou remove a restrição de clique.
- `InBounds()` / `InClickBounds()`: Verifica se o cursor está dentro da caixa total ou restrita.
- `SetTooltip(text)` / `GetTooltip()`: Define uma mensagem de ajuda exibida ao pausar o mouse sobre o objeto.
- `SetContextMenu(menuData)`: Associa uma tabela de menu de contexto que é aberta automaticamente ao clicar com o botão direito.
- `SetCursor(cursor)`: Define o cursor exibido ao passar o mouse sobre o elemento (ex.: `LF.cursors.hand`, `LF.cursors.ibeam`).

## 4.7 Arrasto, Redimensionamento e Skins
- `Drag(mx, my)`: Inicia ou processa o arrasto livre do objeto na tela.
- `GetResizeZone(mx, my)` / `IsResizing(margin)`: Métodos de suporte a detecção de redimensionamento pelas bordas.
- `Resize(mx, my)`: Processa o redimensionamento dinâmico.
- `SetSkin(name)` / `GetSkin()` / `GetSkinName()`: Associa uma skin específica a este elemento e à sua subárvore.
- `Draw`: Callback para substituir completamente o desenho do objeto:
  ```lua
  obj.Draw = function(self)
      -- Código customizado com love.graphics
  end
  ```
- `DrawOver`: Callback desenhado por cima do objeto e de todos os seus filhos.

---

# 5. Catálogo Completo de Componentes

---

### Button
Botão padrão com suporte a texto, ícone, estados hover/down e modo de alternância (*toggle*).
- **Criação**: `LF.Create("button", parent)`
- **Callbacks**:
  - `OnClick = function(self) ... end`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Define/obtém o texto.
  - `SetFont(font)` / `GetFont()`: Define/obtém a fonte utilizada.
  - `SetAlign(mode)` / `GetAlign()`: Alinhamento do texto (`"left"`, `"center"`, `"right"`).
  - `SetCaption(text)` / `GetCaption()`: Define um texto secundário menor.
  - `SetCaptionAlign(mode)` / `GetCaptionAlign()`: Alinhamento da legenda secundária.
  - `SetImage(image)` / `GetImage()`: Associa uma `Image` ou caminho.
  - `SetImageAlign(align)` / `GetImageAlign()`: Posição do ícone (`"left"`, `"right"`, `"center"`).
  - `SetImagePadding(padding)` / `GetImagePadding()`: Espaçamento interno do ícone.
  - `SetPadding(padding)` / `GetPadding()`: Espaçamento de borda do texto.
  - `SetEnabled(bool)` / `GetEnabled()`: Habilita/desabilita interação (fica acinzentado se falso).
  - `SetClickable(bool)` / `GetClickable()`: Define se responde a cliques do mouse.
  - `SetToggleable(bool)` / `GetToggleable()`: Transforma o botão num botão de trava liga/desliga.
  - `SetChecked(bool)` / `GetChecked()`: Marca ou desmarca o estado quando toggleable.
  - `GetDown()`: Retorna se o botão está sendo pressionado no frame atual.

---

### Textbutton
Botão minimalista otimizado para menus no estilo do Counter-Strike 2D. Não desenha bordas de caixa por padrão, apenas o texto com transição de cor quando em hover.
- **Criação**: `LF.Create("textbutton", parent)`
- **Callbacks**:
  - `OnClick = function(self) ... end`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Define o texto no estado normal (suporta `©RRRGGGBBB`).
  - `SetHoverText(text)` / `GetHoverText()`: Define o texto e cor quando o mouse está sobre o botão.
  - `SetFont(font)` / `GetFont()`: Altera a fonte.
  - `SetAlign(mode)` / `GetAlign()`: Alinhamento do texto.
  - `SetImage(image)` / `GetImage()`: Insere ícone opcional.
  - `SetEnabled(bool)` / `GetEnabled()`: Habilita ou desabilita o botão.
  - `SetToggleable(bool)` / `SetChecked(bool)` / `GetChecked()`: Suporte a alternância.

---

### Imagebutton
Botão cujo visual é inteiramente derivado de uma imagem ou sprite.
- **Criação**: `LF.Create("imagebutton", parent)`
- **Callbacks**:
  - `OnClick = function(self) ... end`
- **Métodos**:
  - `SetImage(image)` / `GetImage()`: Define a imagem normal.
  - `SetImageDown(image)`: Define a imagem exibida enquanto pressionado.
  - `SetImageHover(image)`: Define a imagem exibida durante o hover.
  - `SetColor(r, g, b, a)`: Tintura multiplicadora da imagem.

---

### Imagelink
Imagem que atua como hiperlink ou botão navegável.
- **Criação**: `LF.Create("imagelink", parent)`
- **Callbacks**:
  - `OnClick = function(self) ... end`
- **Métodos**:
  - `SetUrl(url)` / `GetUrl()`: URL a ser aberta no navegador padrão do sistema ao clicar.
  - `SetImage(image)` / `GetImage()`: Imagem do link.
  - `SetHoverColor(r, g, b, a)`: Cor aplicada no efeito hover.

---

### Checkbox
Caixa de seleção booleana com texto descritivo.
- **Criação**: `LF.Create("checkbox", parent)`
- **Callbacks**:
  - `OnValueChanged = function(self, checked) ... end`
- **Métodos**:
  - `SetChecked(bool)` / `GetChecked()`: Define ou obtém se a caixa está marcada.
  - `Toggle()`: Inverte o estado de checagem atual.
  - `SetText(text)` / `GetText()`: Altera a legenda ao lado da caixa.
  - `SetFont(font)` / `GetFont()`: Fonte do texto da legenda.
  - `SetEnabled(bool)` / `GetEnabled()`: Habilita ou bloqueia o checkbox.
  - `GetBoxWidth()` / `GetBoxHeight()`: Dimensões da caixinha gráfica.

---

### Radiobutton
Botão de seleção única com exclusão mútua em relação a outros radiobuttons do mesmo grupo.
- **Criação**: `LF.Create("radiobutton", parent)`
- **Callbacks**:
  - `OnChanged = function(self, checked) ... end`
- **Métodos**:
  - `SetGroup(groupName)` / `GetGroup()`: Define o nome do grupo de associação.
  - `SetChecked(bool)` / `GetChecked()`: Marca este botão (desmarcando automaticamente os outros do mesmo grupo).
  - `SetText(text)` / `GetText()`: Texto descritivo.
  - `SetFont(font)` / `GetFont()`: Fonte do texto.
  - `SetEnabled(bool)` / `GetEnabled()`: Habilita ou desabilita interação.

---

### Toggle
Chave seletora deslizante moderna do tipo interruptor (On/Off).
- **Criação**: `LF.Create("toggle", parent)`
- **Callbacks**:
  - `OnChanged = function(self, checked) ... end`
- **Métodos**:
  - `SetChecked(bool)` / `GetChecked()`: Define o estado ligado/desligado.
  - `SetValue(bool)` / `GetValue()`: Sinônimo de `SetChecked`/`GetChecked`.
  - `SetDirection(dir)` / `GetDirection()`: Direção da transição (`"horizontal"` ou `"vertical"`).
  - `SetText(text)` / `GetText()`: Rótulo de texto.
  - `SetEnabled(bool)` / `GetEnabled()`: Habilita/desabilita o interruptor.

---

### Input
Campo de texto de linha única com foco, seleção, teclado e suporte a senhas.
- **Criação**: `LF.Create("input", parent)`
- **Callbacks**:
  - `OnEnter = function(self, text) ... end`: Disparado quando a tecla Enter é pressionada.
  - `OnTextChanged = function(self, text) ... end`: Disparado a cada alteração do texto.
  - `OnFocusGained = function(self) ... end`: Disparado ao receber o foco do mouse/teclado.
  - `OnFocusLost = function(self) ... end`: Disparado ao perder o foco.
  - `OnCopy = function(self, text) ... end` / `OnPaste = function(self, text) ... end`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Altera ou lê o conteúdo do campo.
  - `Clear()`: Apaga todo o texto.
  - `SetFont(font)` / `GetFont()`: Define a fonte da digitação.
  - `SetMasked(bool)`: Ativa modo senha (oculta caracteres).
  - `SetMaskChar(char)`: Define o caractere de máscara (padrão `*`).
  - `SetNumeric(bool)`: Permite digitar estritamente caracteres numéricos.
  - `SetCharacterLimit(limit)`: Define o comprimento máximo do texto.
  - `SetPlaceholderText(text)` / `GetPlaceholderText()`: Texto fantasma quando o campo está vazio.
  - `SetFocus(bool)` / `GetFocus()`: Força ou retira o foco de digitação.
  - `MoveCursorTo(pos)`: Posiciona o cursor de inserção no índice informado.

---

### Textbox
Área de texto de múltiplas linhas para edição livre ou leitura de blocos longos de texto.
- **Criação**: `LF.Create("textbox", parent)`
- **Callbacks**:
  - `OnTextChanged = function(self, text) ... end`
  - `OnEnter = function(self, text) ... end`
  - `OnFocusGained` / `OnFocusLost`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Define ou obtém todo o conteúdo.
  - `SetMultiline(bool)`: Alterna entre linha única e múltiplas linhas.
  - `SetEditable(bool)`: Define se o usuário pode alterar o texto ou apenas lê-lo.
  - `SetFont(font)` / `GetFont()`: Fonte do texto.
  - `SetPadding(v, h)`: Espaçamento interno vertical e horizontal.
  - `SetCharacterLimit(limit)`: Limite total de caracteres.
  - `SetAutoScroll(bool)`: Se ativo, rola para a última linha ao adicionar conteúdo.
  - `Clear()`: Limpa o texto.
  - `Cut()` / `Copy()` / `Paste()`: Operações na área de transferência.

---

### Codebox
Caixa de edição avançada voltada para código-fonte com suporte a numeração de linhas e marcação de sintaxe.
- **Criação**: `LF.Create("codebox", parent)`
- **Callbacks**:
  - `OnTextChanged = function(self, text) ... end`
  - `OnEnter = function(self) ... end`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Lê ou define o código-fonte.
  - `SetLanguage(lang)`: Define a linguagem de destaque (ex.: `"lua"`).
  - `SetLineNumbers(bool)`: Exibe ou oculta a coluna de numeração de linhas.
  - `SetFont(font)`: Define fonte monoespaçada recomendada.
  - `Clear()`: Esvazia o documento.

---

### Numberbox
Campo numérico composto por visor e setas verticais para ajuste fino.
- **Criação**: `LF.Create("numberbox", parent)`
- **Callbacks**:
  - `OnValueChanged = function(self, value) ... end`
- **Métodos**:
  - `SetValue(num)` / `GetValue()`: Define/lê o valor numérico atual.
  - `SetMin(min)` / `GetMin()`: Limite inferior.
  - `SetMax(max)` / `GetMax()`: Limite superior.
  - `SetMinMax(min, max)`: Define limites inferior e superior simultaneamente.
  - `SetStep(step)` / `SetStepAmount(step)`: Valor somado/subtraído por clique de seta.
  - `SetDecimals(places)` / `GetDecimals()`: Casas decimais permitidas.
  - `SetFont(font)`: Fonte dos números.

---

### Stepper
Controle numérico horizontal compacto no formato `[-]  valor  [+]`.
- **Criação**: `LF.Create("stepper", parent)`
- **Callbacks**:
  - `OnValueChanged = function(self, value) ... end`
- **Métodos**:
  - `SetValue(num)` / `GetValue()`: Ajusta ou consulta o valor.
  - `SetMin(min)` / `SetMax(max)` / `SetMinMax(min, max)`: Limites numéricos.
  - `SetStepAmount(amount)`: Valor de incremento por clique nos botões.
  - `SetDecimals(decimals)`: Número de casas decimais.
  - `SetVertical(bool)`: Alterna entre layout horizontal ou vertical.
  - `SetFont(font)`: Fonte da exibição.

---

### Slider
Barra deslizante contínua com arrasto por cursor.
- **Criação**: `LF.Create("slider", parent)`
- **Callbacks**:
  - `OnValueChanged = function(self, value) ... end`: Disparado enquanto o slider desliza.
  - `OnRelease = function(self, value) ... end`: Disparado quando o botão do mouse é solto.
- **Métodos**:
  - `SetValue(value)` / `GetValue()`: Define ou lê o valor atual.
  - `SetMinMax(min, max)` / `GetMinMax()`: Define valores extremos.
  - `SetMin(min)` / `SetMax(max)`: Define limites individuais.
  - `SetSlideType(type)` / `GetSlideType()`: `"horizontal"` ou `"vertical"`.
  - `SetDecimals(decimals)` / `GetDecimals()`: Precisão decimal do valor.
  - `SetScrollable(bool)`: Permite alterar o valor usando a roda do mouse (*scroll*).
  - `SetButtonSize(w, h)`: Dimensão do indicador arrastável.
  - `SetEnabled(bool)`: Habilita ou trava o controle.

---

### Dial
Controle rotativo em forma de botão giratório (Knob/Potenciômetro).
- **Criação**: `LF.Create("dial", parent)`
- **Callbacks**:
  - `OnValueChanged = function(self, value) ... end`
  - `OnRelease = function(self, value) ... end`
- **Métodos**:
  - `SetValue(val)` / `GetValue()`: Valor rotativo atual.
  - `SetMinMax(min, max)`: Intervalo do giro.
  - `SetDecimals(decimals)`: Precisão decimal.

---

### Frame
Janela flutuante completa com barra de título, botão de fechar, arrasto livre e redimensionamento.
- **Criação**: `LF.Create("frame", parent)`
- **Callbacks**:
  - `OnClose = function(self) ... end`: Disparado quando a janela é fechada pelo botão `X`.
- **Métodos**:
  - `SetName(title)` / `GetName()`: Define o texto na barra de título.
  - `SetDraggable(bool)` / `GetDraggable()`: Habilita arrastar segurando a barra de título.
  - `SetScreenLocked(bool)` / `GetScreenLocked()`: Impede que o frame seja arrastado para fora dos limites da janela do jogo.
  - `ShowCloseButton(bool)`: Mostra ou oculta o botão `X` no canto superior direito.
  - `SetCloseAction(func)`: Substitui o comportamento padrão ao clicar no `X` (por padrão esconde o frame via `SetVisible(false)`).
  - `SetModal(bool)` / `IsModal()`: Torna a janela modal (escurece o fundo e bloqueia cliques externos).
  - `SetResizable(bool)` / `GetResizable()`: Habilita redimensionar puxando pelas bordas.
  - `SetMinSize(w, h)` / `GetMinSize()`: Dimensões mínimas permitidas no resize.
  - `SetMaxSize(w, h)` / `GetMaxSize()`: Dimensões máximas no resize.
  - `SetIcon(image)` / `GetIcon()`: Ícone exibido no canto superior esquerdo do título.
  - `SetAlwaysOnTop(bool)` / `GetAlwaysOnTop()`: Garante que o frame fique desenhado acima dos outros.
  - `SetDockable(bool)`: Permite que este frame seja encaixado em um `dockzone`.

---

### Panel
Painel com desenho e cor de fundo padrão da skin. Utilizado para agrupar e delimitar visualmente blocos de componentes.
- **Criação**: `LF.Create("panel", parent)`

---

### Container
Contêiner lógico totalmente invisível (sem nenhuma rotina própria de desenho). Utilizado como agrupador de layout estrutural para posicionar botões com coordenadas relativas.
- **Criação**: `LF.Create("container", parent)`

---

### Scrollpanel
Contêiner com barras de rolagem horizontal e vertical inteligentes que surgem quando o conteúdo excede os limites visíveis.
- **Criação**: `LF.Create("scrollpanel", parent)`
- **Callbacks**:
  - `OnScroll = function(self) ... end`
- **Métodos**:
  - `AddItem(object)`: Insere um elemento gerenciado pelo scroll.
  - `AddItemsFromTable(objects)`: Insere múltiplos objetos de uma vez.
  - `RemoveItem(object)`: Remove um item do painel de rolagem.
  - `Clear()`: Remove e esvazia todos os itens contidos.
  - `RedoLayout()`: Recalcula imediatamente os limites de rolagem.
  - `SetAutoScroll(bool)` / `GetAutoScroll()`: Rola automaticamente para o fim ao inserir itens.
  - `SetMouseWheelScrollAmount(amount)`: Quantidade de pixels rolados pela roda do mouse.
  - `ShowBackground(bool)`: Define se desenha o fundo do painel ou apenas os itens internos.

---

### Dockzone
Área retangular magnética na qual janelas (`frame`) com propriedade `dockable = true` podem se acoplar e fixar.
- **Criação**: `LF.Create("dockzone", parent)`

---

### Tabs
Gerenciador de abas múltiplas com alternância de conteúdo.
- **Criação**: `LF.Create("tabs", parent)`
- **Métodos**:
  - `AddTab(name, contentObject, [image], [onopened], [onclosed])`: Cria uma aba associada ao objeto `contentObject` (geralmente um `panel` ou `container`).
  - `InsertTab(pos, name, contentObject, [image])`: Insere a aba numa posição específica.
  - `RemoveTab(id)`: Remove uma aba existente.
  - `SwitchToTab(tabnumber)`: Alterna programaticamente para a aba informada.
  - `GetTabNumber()`: Retorna o índice da aba aberta no momento.
  - `SetTabHeight(height)`: Altura da barra de botões das abas.
  - `SetPadding(padding)` / `GetPadding()`: Espaçamento interno.
  - `SetAutoButtonAreaWidth(bool)`: Ajusta a largura da barra de abas automaticamente.

---

### Collapsiblecategory
Categoria colapsável do tipo acordeão (*accordion*), que expande e recolhe seu conteúdo com um clique no cabeçalho.
- **Criação**: `LF.Create("collapsiblecategory", parent)`
- **Callbacks**:
  - `OnOpenedClosed = function(self, open) ... end`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Título na barra de colapso.
  - `SetOpen(bool)` / `GetOpen()`: Define se a categoria inicia expandida ou recolhida.
  - `SetObject(childObject)`: Define o conteúdo interno que é exibido ao expandir.

---

### Grid
Contêiner que organiza seus filhos automaticamente em colunas e linhas simétricas.
- **Criação**: `LF.Create("grid", parent)`
- **Callbacks**:
  - `OnSizeChanged = function(self) ... end`
- **Métodos**:
  - `SetRows(rows)` / `SetColumns(cols)`: Define a quantidade de linhas e colunas.
  - `SetCellWidth(w)` / `SetCellHeight(h)`: Define a dimensão de cada célula.
  - `SetCellSize(w, h)`: Ajusta tamanho da célula de uma só vez.
  - `AddItem(object, row, col)`: Aloca um componente na célula informada.

---

### Columnlist
Grade tabular com cabeçalhos de coluna, divisores ajustáveis, ordenação de dados e seleção de linhas. Ideal para navegadores de servidores, placares e exploradores.
- **Criação**: `LF.Create("columnlist", parent)`
- **Callbacks**:
  - `OnRowSelected = function(self, row, rowData) ... end`: Disparado ao selecionar uma linha.
  - `OnRowClicked = function(self, row, rowData) ... end`: Disparado ao clicar numa linha.
  - `OnRowRightClicked = function(self, row, rowData) ... end`: Disparado ao clicar com botão direito.
- **Métodos**:
  - `AddColumn(name, [width])`: Adiciona uma nova coluna com largura inicial.
  - `AddRow(...)`: Insere uma nova linha recebendo os valores de cada coluna em ordem sequencial. Retorna o objeto da linha.
  - `RemoveRow(id)`: Remove a linha do índice informado.
  - `Clear()`: Esvazia todas as linhas da tabela.
  - `SelectRow(row, [ctrl])`: Seleciona uma linha programaticamente.
  - `DeselectRow(row)`: Desmarca a linha informada.
  - `GetSelectedRows()`: Retorna uma tabela contendo todas as linhas selecionadas.
  - `SetColumnWidth(id, width)` / `GetColumnWidth(id)`: Define/lê a largura de uma coluna.
  - `SetColumnResizeEnabled(bool)`: Permite que o usuário redimensione colunas com o mouse.
  - `SetCellText(text, rowId, colId)` / `GetCellText(rowId, colId)`: Altera ou lê o texto de uma célula específica.
  - `SetRowColumnData(rowId, colData)`: Atualiza todos os dados de uma linha de uma só vez.
  - `SetMultiselectEnabled(bool)` / `GetMultiselectEnabled()`: Permite selecionar múltiplas linhas segurando Ctrl ou Shift.
  - `SetAutoScroll(bool)`: Rola automaticamente para o fim ao inserir novas linhas.
  - `SetFont(font)` / `GetFont()`: Define a fonte utilizada nos dados da tabela.

---

### Droplist
Menu suspenso do tipo ComboBox com filtro de pesquisa interno.
- **Criação**: `LF.Create("droplist", parent)`
- **Callbacks**:
  - `OnChoiceSelected = function(self, choice) ... end`: Disparado ao escolher um item.
- **Métodos**:
  - `AddChoice(text, [value])`: Adiciona uma opção selecionável.
  - `SelectChoice(index)`: Define o item ativo pelo índice.
  - `GetSelectedChoice()`: Retorna o texto/valor da opção ativa.
  - `Clear()`: Limpa todas as escolhas.
  - `SetFont(font)`: Altera a fonte.

---

### Multichoice
Seletor com opções múltiplas expansíveis (alternativa estilizada ao droplist).
- **Criação**: `LF.Create("multichoice", parent)`
- **Callbacks**:
  - `OnChoiceSelected = function(self, choice) ... end`
- **Métodos**:
  - `AddChoice(text)` / `RemoveChoice(index)`: Adiciona ou remove itens.
  - `SelectChoice(choice)` / `GetChoice()`: Define ou obtém a opção corrente.

---

### Tree
Visualizador hierárquico em árvore com nós expansíveis e nós folhas.
- **Criação**: `LF.Create("tree", parent)`
- **Callbacks**:
  - `OnSelectNode = function(self, node) ... end`
- **Métodos**:
  - `AddNode(text)`: Adiciona um nó raiz na árvore.
  - `node:AddNode(text)`: Adiciona um sub-nó filho ao nó selecionado.
  - `node:SetIcon(image)`: Define um ícone específico no nó.
  - `node:SetOpen(bool)` / `node:GetOpen()`: Abre ou recolhe o nó.
  - `SetFont(font)`: Define a fonte dos nós.
  - `SetRearrangeEnabled(bool)`: Permite reorganizar nós arrastando com o mouse.

---

### Menu
Menu de contexto flutuante com suporte a submenus e separadores.
- **Criação**: `LF.Create("menu", parent)`
- **Métodos**:
  - `AddOption(text, [icon], [func])`: Adiciona uma opção clicável.
  - `AddDivider()`: Insere uma linha divisória horizontal.
  - `AddSubMenu(text, [icon])`: Retorna um novo objeto `menu` aninhado como submenu.
  - `Open(x, y)`: Abre o menu nas coordenadas informadas na tela.
  - `ConstructFromTable(table)`: Popula o menu a partir de uma tabela estruturada de opções.

---

### Menubar & Menubarmenu
Barra horizontal superior fixa para menus estilo desktop clássico.
- **Criação**: `LF.Create("menubar", parent)`
- **Métodos**:
  - `AddMenu(name)`: Cria um item na barra superior e retorna o objeto `menubarmenu` associado.

---

### Label
Exibição de textos estáticos formatados, multiline e links clicáveis.
- **Criação**: `LF.Create("label", parent)`
- **Métodos**:
  - `SetText(text)` / `GetText()`: Define o texto (suporta `©RRRGGGBBB`).
  - `SetFont(font)` / `GetFont()`: Define a fonte do texto.
  - `SetLinks(bool)`: Habilita detecção e clique em URLs embutidas no texto.
  - `SetMaxWidth(width)`: Define largura máxima ativando quebra de linha automática.

---

### Image
Exibição e controle visual de texturas ou quads.
- **Criação**: `LF.Create("image", parent)`
- **Métodos**:
  - `SetImage(image)` / `GetImage()`: Define a imagem a ser desenhada.
  - `SetScale(sx, sy)`: Define o fator de escala nos eixos X e Y.
  - `SetColor(r, g, b, a)`: Modulador de cor e opacidade do desenho.
  - `SetOrientation(rad)`: Ângulo de rotação em radianos.
  - `SetOffset(ox, oy)`: Ponto de origem do desenho.

---

### Progressbar
Barra percentual de progresso com transição interpolada opcional.
- **Criação**: `LF.Create("progressbar", parent)`
- **Callbacks**:
  - `OnComplete = function(self) ... end`: Disparado quando atinge o valor máximo.
- **Métodos**:
  - `SetValue(val)` / `GetValue()`: Define/lê o valor atual.
  - `SetMinMax(min, max)` / `SetMax(max)`: Define o valor máximo (padrão `100` ou `1.0`).
  - `SetLerp(bool)`: Habilita transição visual suave entre valores.

---

### Loading
Indicador animado de carregamento/espera.
- **Criação**: `LF.Create("loading", parent)`
- **Métodos**:
  - `SetRadius(radius)` / `GetRadius()`: Raio do anel de carregamento.
  - `SetSpeed(speed)`: Velocidade de rotação da animação.

---

### Toast
Sistema de notificações flutuantes temporárias. Pode ser usado instanciando um objeto ou diretamente através do singleton `LF.toast`.
- **Uso Global**:
  ```lua
  LF.toast:PushMessage("Mensagem de aviso", {
      time = 4,              -- Duração em segundos
      color = {1, 1, 1, 1},  -- Cor
      align = "center",      -- "left", "center", "right"
  })
  ```
- **Métodos**:
  - `PushMessage(text, [options])`: Adiciona uma notificação na pilha.
  - `SetBoxAlign(valign, halign)`: Posicionamento da caixa de notificações (`"top"`, `"bottom"`, `"left"`, `"right"`).
  - `SetMargin(margin)` / `SetSpacing(spacing)`: Espaçamento entre as mensagens.
  - `SetOutline(bool)`: Desenha ou remove borda de contorno nas notificações.

---

### Messagebox
Caixa de diálogo modal padronizada para alertas e confirmações rápidas com botões de resposta.
- **Criação**: `LF.Create("messagebox", parent)`
- **Callbacks**:
  - `OnButtonChosen = function(self, buttonText) ... end`
- **Métodos**:
  - `SetTitle(text)`: Título da janela.
  - `SetMessage(text)`: Mensagem central de texto.
  - `SetButtons(buttonTable)`: Lista de nomes de botões (ex.: `{"Sim", "Não"}`).

---

### Filebrowser
Explorador interativo de pastas e arquivos para carregamento ou salvamento de mapas e configurações.
- **Criação**: `LF.Create("filebrowser", parent)`
- **Callbacks**:
  - `on_select = function(self, path) ... end`: Disparado ao confirmar um arquivo.
  - `on_cancel = function(self) ... end`: Disparado ao cancelar.
- **Métodos**:
  - `SetDirectory(path)`: Define a pasta inicial do navegador.

---

### Colorpicker
Seletor de cores completo com roda cromática HSV, ajustes de saturação e transparência (Alpha).
- **Criação**: `LF.Create("colorpicker", parent)`
- **Callbacks**:
  - `OnColorChanged = function(self, colorTable) ... end`
- **Métodos**:
  - `SetColor(r, g, b, [a])` / `GetColor()`: Lê ou define a cor selecionada.

---

### Joystick
Analógico virtual na tela para controles de toque ou mouse.
- **Criação**: `LF.Create("joystick", parent)`
- **Callbacks**:
  - `OnValueChanged = function(self, x, y) ... end`: Disparado enquanto o manche é inclinado (valores normalizados de `-1` a `1`).
  - `OnRelease = function(self) ... end`: Disparado ao soltar o joystick.
- **Métodos**:
  - `GetBaseRadius()` / `GetMaxDistance()`: Dimensões físicas do curso do analógico.

---

### Carousel & Slideshow
Controles de transição de páginas e imagens com paginação visual (pontos indicativos inferiores).
- **Criação**: `LF.Create("slideshow", parent)` ou `LF.Create("carousel", parent)`
- **Callbacks**:
  - `OnTabChange = function(self, currentTab) ... end`
- **Métodos**:
  - `AddTab(object)`: Insere uma página ou tela.
  - `SwitchToTab(index)`: Troca a página ativa.
  - `SetAutoPlay(bool)` / `SetInterval(seconds)`: Ativa transição periódica automática.

---

### Log
Painel de console com rolagem para despejo de logs, eventos ou saída de terminal.
- **Criação**: `LF.Create("log", parent)`
- **Métodos**:
  - `AddText(text)`: Insere uma nova linha de log.
  - `Clear()`: Esvazia o painel.
  - `SetAutoScroll(bool)`: Rola para a linha mais recente automaticamente.

---

### Sysl
Sistema de exibição de texto com efeito máquina de escrever (*typewriter*), ideal para mensagens de missões, diálogos de rádio e cutscenes.
- **Criação**: `LF.Create("sysl", parent)`
- **Métodos**:
  - `SetText(text)`: Define o texto a ser revelado aos poucos.
  - `SetPrintSpeed(speed)`: Velocidade de exibição dos caracteres.
  - `Advance()`: Avança para a próxima mensagem.
  - `Skip()`: Completa instantaneamente a exibição do texto atual.
  - `IsDone()` / `IsFinished()`: Retorna se a fala foi concluída.

---

### Graphfield & Graphnode
Sistema de nós e campos de conexões visuais (estilo Blueprint / Flowgraph).
- **Criação**: `local field = LF.Create("graphfield", parent)`
- **Nós**: `local node = LF.Create("graphnode", field)`
- **Métodos de `Graphnode`**:
  - `AddInput(name, color, datatype)`: Cria um soquete de entrada à esquerda.
  - `AddOutput(name, color, datatype)`: Cria um soquete de saída à direita.

---

# 6. Exemplos e Receitas Prontas

### Receita 1: Diálogo Modal de Confirmação com Botões Alinhados
```lua
local LF = require "lib.loveframes"

local function ShowConfirmDialog(title, message, onConfirm)
    local frame = LF.Create("frame")
    frame:SetName(title)
    frame:SetSize(320, 140)
    frame:Center()
    frame:SetModal(true)
    frame:ShowCloseButton(false)
    frame:SetState("*") -- Visível em qualquer estado

    local lbl = LF.Create("label", frame)
    lbl:SetText(message)
    lbl:SetPos(15, 40)
    lbl:SetMaxWidth(290)

    local btnCancel = LF.Create("button", frame)
    btnCancel:SetText("Cancelar")
    btnCancel:SetSize(80, 24)
    btnCancel:AlignRight(15)
    btnCancel:AlignBottom(15)
    btnCancel.OnClick = function()
        frame:Remove()
    end

    local btnYes = LF.Create("button", frame)
    btnYes:SetText("Confirmar")
    btnYes:SetSize(80, 24)
    btnYes:AlignBottom(15)
    btnYes:AlignTo(btnCancel, "left")
    btnYes:SetX(btnCancel:GetX() - 90)
    btnYes.OnClick = function()
        frame:Remove()
        if onConfirm then onConfirm() end
    end
end
```

### Receita 2: Lista de Servidores com Busca, Colunas e Scroll
```lua
local LF = require "lib.loveframes"

local panel = LF.Create("panel")
panel:SetSize(640, 420):Center()

-- Campo de busca no topo
local searchInput = LF.Create("input", panel)
searchInput:SetPos(10, 10):SetSize(400, 24)
searchInput:SetPlaceholderText("Filtrar servidores...")

-- Tabela de servidores
local list = LF.Create("columnlist", panel)
list:SetPos(10, 42):SetSize(620, 330)
list:AddColumn("Servidor", 300)
list:AddColumn("Mapa", 140)
list:AddColumn("Players", 90)
list:AddColumn("Ping", 70)

-- Inserindo linhas formatadas
list:AddRow("©255255255[BR] Servidor Oficial #1", "de_dust2", "14/32", "18ms")
list:AddRow("©255255000[US] Zombie Plague Mod", "zm_toxic", "26/32", "110ms")

-- Botão de Conectar no rodapé
local btnConnect = LF.Create("button", panel)
btnConnect:SetText("Entrar no Jogo")
btnConnect:SetSize(120, 28)
btnConnect:AlignRight(10)
btnConnect:AlignBottom(10)
btnConnect.OnClick = function()
    local selected = list:GetSelectedRows()
    if #selected > 0 then
        local data = selected[1]:GetColumnData()
        LF.toast:PushMessage("©000255000Conectando a: " .. data[1])
    else
        LF.toast:PushMessage("©255000000Selecione um servidor na lista!")
    end
end
```

