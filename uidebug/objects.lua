local ui = {}
local LF = require "lib.loveframes"
--------------------------------------------------------------------------------------------------
--Local function helpers--------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- Gera uma string aleatória com o tamanho especificado
local function random_string(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(#charset)
        result[i] = charset:sub(rand, rand)
    end
    return table.concat(result)
end

local function random_color()
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    return string.format("©%s%s%s", r, g, b)
end
--------------------------------------------------------------------------------------------------
--Objects-----------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.container = LF.Create ("container"):Center()

ui.input = LF.Create ("textbox", ui.container)

function ui.container.OnControlKeyPressed(key)
end

function ui.container.Draw(object)
    --love.graphics.setColor(1,1,1,1)
    --love.graphics.rectangle("fill", object.x, object.y, object.width, object.height)
end


do return end
ui.frame = LF.Create("frame"):SetName("Debug"):SetSize(400, 300):CenterX()
ui.hoverlabel = LF.Create("label", ui.frame):SetPos(5, 30):SetText("Hover: ")
ui.hoverdisplay = LF.Create("label", ui.frame):SetPos(ui.hoverlabel:GetWidth(-5), 30)

ui.downlabel = LF.Create("label", ui.frame):SetPos(5, 50):SetText("Down: ")
ui.downdisplay = LF.Create("label", ui.frame):SetPos(ui.hoverlabel:GetWidth(-5), 50)

ui.inputlabel = LF.Create("label", ui.frame):SetPos(5, 70):SetText("Input: ")
ui.inputdisplay = LF.Create("label", ui.frame):SetPos(ui.inputlabel:GetWidth(-5), 70)

ui.dragginglabel = LF.Create("label", ui.frame):SetPos(5, 90):SetText("Dragging: ")
ui.draggingdisplay = LF.Create("label", ui.frame):SetPos(ui.dragginglabel:GetWidth(-5), 90)

ui.memorylabel = LF.Create("label", ui.frame):SetPos(5, 110):SetText("Memory: ")
ui.memorydisplay = LF.Create("label", ui.frame):SetPos(ui.memorylabel:GetWidth(-5), 110)

ui.fpslabel = LF.Create("label", ui.frame):SetPos(5, 130):SetText("FPS: ")
ui.fpsdisplay = LF.Create("label", ui.frame):SetPos(ui.fpslabel:GetWidth(-5), 130)

ui.resizelabel = LF.Create("label", ui.frame):SetPos(5, 150):SetText("Resize: ")
ui.resizedisplay = LF.Create("label", ui.frame):SetPos(ui.resizelabel:GetWidth(-5), 150)

function ui.frame.Update(object)
    local hover = tostring(LF.hoverobject) or "nil"
    ui.hoverdisplay:SetText(hover)
    local down = tostring(LF.downobject) or "nil"
    ui.downdisplay:SetText(down)
    local input = tostring(LF.inputobject) or "nil"
    ui.inputdisplay:SetText(input)
    local dragging = tostring(LF.draggingobject) or "nil"
    ui.draggingdisplay:SetText(dragging)

    local memory = collectgarbage("count") / 1024
    ui.memorydisplay:SetText( string.format("%.2f MB", memory) )

    local fps = love.timer.getFPS()
    ui.fpsdisplay:SetText( tostring(fps) )

    local ax, ay, x, y, w, h = LF.anchor_x, LF.anchor_y, LF.drag_x, LF.drag_y, LF.drag_width, LF.drag_height
    ui.resizedisplay:SetText( string.format(" anchor[%s, %s, %s, %s, %s, %s]", ax, ay, x, y, w, h ) )
end


local filltable = {}
for i=1,5000 do table.insert(filltable, random_string(30)) end

ui.droplistframe = LF.Create("frame"):SetName("Droplist"):SetSize(400, 400)
ui.droplistscroll = LF.Create("scrollpane", ui.droplistframe)
:SetY(30):SetSize( ui.droplistframe:GetWidth(10), ui.droplistframe:GetHeight(40) - 100 ):CenterX()
ui.droplist = LF.Create("droplist", ui.droplistscroll):SetSize(ui.droplistscroll:GetSize())
ui.droplist:AddItemsFromTable(filltable)
ui.droplist_amount = LF.Create("label", ui.droplistframe)
ui.droplist_amount:SetText(string.format("Amount: %s", ui.droplist:Count())):SetPos( 5, ui.droplistframe:GetWidth(110) )

ui.droplist_add = LF.Create("button", ui.droplistframe)
ui.droplist_add:SetText("add"):SetPos( 5, ui.droplistframe:GetWidth(40) ):CenterX()

ui.droplist_remove = LF.Create("button", ui.droplistframe)
ui.droplist_remove:SetText("remove"):SetPos( 5, ui.droplistframe:GetWidth(70) ):CenterX()
function ui.droplist_remove.OnClick(object)
    ui.droplist:RemoveItem()

    ui.droplist_amount:SetText( string.format("Amount: %s", ui.droplist:Count() ) )
end

function ui.droplist_add.OnClick(object)
    ui.droplist:AddItem(random_string(10))

    ui.droplist_amount:SetText( string.format("Amount: %s", ui.droplist:Count() ) )
end

function ui.droplist.OnClick(object, element, element_id)
    print(object, element, element_id)
end
----------------------

ui.resizableframe = LF.Create("frame")
:SetResizable(true):Center():SetName("Resizable Frame")


----------------------
ui.inputs = LF.Create("frame"):SetName("Input"):SetSize(300, 730)
ui.input_scroll = LF.Create("scrollpane", ui.inputs):SetY(30):SetSize(300, 700)
for i=1, 1000 do
    local input = LF.Create("textbox", ui.input_scroll)
    input:SetPos(5, (i-1)*30)
    --local label = LF.Create("label", ui.input_scroll)
    --label:SetPos(5, (i-1)*30):SetText (random_string(20))
    local button = LF.Create("button", ui.input_scroll)
    button:SetPos(input:GetWidth() + 10, (i-1)*30):SetHeight(input:GetHeight())
end


ui.textboxframe = LF.Create ("frame"):SetName("TextBox"):SetSize(300, 330)
ui.textbox = LF.Create("textbox", ui.textboxframe):SetSize(280, 280):CenterX():SetY(30):SetMultiline(true)

--ui.textbox:SetText(table.concat(filltable, "\n"))

ui.seaoftextframe = LF.Create ( "frame" ):SetName("Sea of Text"):SetSize(300, 330)
ui.seaoftextscroll = LF.Create("scrollpane",ui.seaoftextframe):SetSize(280, 280):CenterX():SetY(30)
ui.seaoftext = LF.Create("messagebox", ui.seaoftextscroll):SetMaxWidth(260)

--print(table.concat(filltable, "\n"))
ui.seaoftext:SetText(table.concat(filltable, "\n"))




