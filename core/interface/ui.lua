--- Core Interface Aggregator
--- Reune e expoes os modulos de interface divididos por cena e compartilhados,
--- mantendo 100% de compatibilidade com todo o restante da engine.

-- 1. Base comum (fontes, cursores, utilitarios de texto, toast)
local ui = require "core.interface.common"
package.loaded["core.interface.ui"] = ui

-- 2. Dialogos e janelas compartilhadas / globais (SetState("*"))
require("core.interface.shared.options")(ui)
require("core.interface.shared.menu_frame")(ui)
require("core.interface.shared.exit_window")(ui)
require("core.interface.shared.shader_controls")(ui)

-- 3. Interface da cena Lobby (SetState("none"))
require("core.interface.lobby.main_menu")(ui)
require("core.interface.lobby.new_game")(ui)

-- 4. Interface da cena Game (SetState("game"))
require("core.interface.game.hud")(ui)
require("core.interface.game.chat")(ui)
require("core.interface.game.weaponselect")(ui)
require("core.interface.game.spectator")(ui)
require("core.interface.game.server_log")(ui)
require("core.interface.game.serverinfo")(ui)
require("core.interface.game.team_pick")(ui)
require("core.interface.game.tabscreen")(ui)
require("core.interface.game.buymenu")(ui)
require("core.interface.game.reload")(ui)

-- 5. Interface da cena Editor (SetState("editor"))
ui.editor = require "core.interface.editor"

return ui
