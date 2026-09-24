local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)

ui.find_servers_frame = LF.Create("frame")
    :SetCloseAction("close")
    :SetState("none")

end