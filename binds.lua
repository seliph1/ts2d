return function(client)
------------------------
-- Module start
------------------------
local binds = {}

-- Input types: stream, pulse

binds[1]            = {input="attack", type="toggle"}
binds[2]            = {input="attack2", type="toggle"}
binds[3]            = {input="attack3", type="toggle"}
--binds["mwheelup"]   = {input="invnext", type="pulse"}
--binds["mwheeldown"] = {input="invprev", type="pulse"}
binds["w"]          = {input="forward", type="stream"}
binds["s"]          = {input="back", type="stream"}
binds["a"]          = {input="left", type="stream"}
binds["d"]          = {input="right", type="stream"}
binds["r"]          = {input="reload", type="pulse"}
binds["g"]          = {input="drop", type="pulse"}
binds["lshift"]     = {input="walk", type="stream"}
binds["f"]          = {input="flashlight", type="pulse"}
binds["1"]          = {input="slot1", type="pulse"}
binds["2"]          = {input="slot2", type="pulse"}
binds["3"]          = {input="slot3", type="pulse"}
binds["4"]          = {input="slot4", type="pulse"}
binds["5"]          = {input="slot5", type="pulse"}
binds["6"]          = {input="slot6", type="pulse"}
binds["7"]          = {input="slot7", type="pulse"}
binds["8"]          = {input="slot8", type="pulse"}
binds["9"]          = {input="slot9", type="pulse"}
binds["f2"]         = {input="serveraction1", type="pulse"}
binds["f3"]         = {input="serveraction2", type="pulse"}
binds["f4"]         = {input="serveraction3", type="pulse"}
binds["e"]          = {input="use", type="pulse"}

return binds
------------------------
-- Module end
------------------------
end