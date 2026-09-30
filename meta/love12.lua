---@meta
-- =============================================================================
-- Stubs de APIs exclusivas do LÖVE 12.0
-- =============================================================================
-- O addon do LuaLS (sumneko/LuaCATS-love2d) ainda descreve a API do LÖVE 11.x,
-- então funções introduzidas/renomeadas no 12.0 aparecem como "undefined field".
-- Este arquivo (carregado como *library*, nunca em runtime — ver ---@meta) declara
-- essas funções só para o editor parar de acusá-las.
--
-- Regras:
--   * Só inclua o que o projeto realmente usa E o LuaLS realmente sublinha.
--   * NÃO inclua APIs que já existem no 11.x (ex.: love.data.* existe desde 11.0).
--   * Ao reaproveitar tipos (ex.: love.Text), use os já definidos pelo addon 11.x
--     para evitar aviso de "classe duplicada".
--
-- Para adicionar mais: rode o jogo no editor, veja o que fica sublinhado e
-- declare aqui. Candidatos comuns do 12.0:
--   love.graphics.newGpuBuffer / readback / setStencilState
--   love.filesystem.openFile / getFullCommonPath
-- =============================================================================

---Cria um objeto de texto desenhável (renomeado de `love.graphics.newText` no 12.0).
---@param font love.Font          # fonte usada para o texto
---@param text? string|table      # texto inicial; tabela = trechos coloridos
---@return love.Text              # reaproveita o tipo Text já definido pelo addon 11.x
function love.graphics.newTextBatch(font, text) end

---Monta um caminho completo do sistema de arquivos do SO no filesystem virtual (12.0).
---@param path string                          # caminho absoluto no SO
---@param mountpoint string                    # ponto de montagem virtual ("" = raiz)
---@param permissions? "read"|"readwrite"      # permissão de acesso (padrão "read")
---@return boolean success
function love.filesystem.mountFullPath(path, mountpoint, permissions) end

---@class love.WindowSettings
---@field vsync? number|integer|boolean

---Altera as dimensões e/ou configurações da janela sem recriar o contexto se possível.
---@param width number                         # largura da janela em pixels
---@param height number                        # altura da janela em pixels
---@param flags? love.WindowSettings|table     # tabela de opções/flags da janela (ex.: vsync, fullscreen)
---@return boolean success
function love.window.updateMode(width, height, flags) end

---Configura um modo de uso comum de stencil, alterando state e color masks internamente.
---@param mode string # "draw" (escreve no buffer) | "test" (testa se == value) | "off" (desativa).
---@param value? number # O valor de stencil (1 a 255) usado quando mode é "draw" ou "test".
function love.graphics.setStencilMode(mode, value) end

---Configura finamente a máquina de estados do stencil para o pipeline gráfico.
---@param action string # O que fazer com o valor ("replace", "keep", "increment", etc).
---@param compare string # O modo de comparação ("always", "equal", "notequal", "greater", "less").
---@param value? number # O valor (1 a 255) a ser escrito ou testado.
function love.graphics.setStencilState(action, compare, value) end

---Abre um dialogo nativo de arquivo do sistema (abrir/salvar/pasta). Assincrono.
---@param type string # Tipo do dialogo: "openfile" | "savefile" | "openfolder" | "openshell".
---@param callback fun(files: string[], filtername: string, err: string) # Chamado quando o dialogo fecha.
---@param settings? table # Opcoes: title, accept, cancel, defaultname, filters, multiselect, attachtowindow.
function love.window.showFileDialog(type, callback, settings) end

---Le de volta os dados de uma textura (Canvas/Image) para a CPU como ImageData.
---Substitui Canvas:newImageData(), que foi descontinuado no 12.0.
---@param texture love.Texture # A textura (ex: Canvas) a ser lida.
---@param slice? number # A camada/face do array/cubemap (1-based). Padrao 1.
---@param mipmap? number # O nivel de mipmap a ler (1-based). Padrao 1.
---@param x? number # Canto x da regiao a ler. Padrao 0.
---@param y? number # Canto y da regiao a ler. Padrao 0.
---@param width? number # Largura da regiao. Padrao = largura da textura.
---@param height? number # Altura da regiao. Padrao = altura da textura.
---@return love.ImageData imagedata # Os pixels lidos da textura.
function love.graphics.readbackTexture(texture, slice, mipmap, x, y, width, height) end
