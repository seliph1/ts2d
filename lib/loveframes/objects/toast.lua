return function(loveframes)

local Toast = loveframes.NewObject("toast", "loveframes_object_toast", true)

function Toast:initialize()
    local skin = loveframes.GetActiveSkin()
    local font = skin.directives.text_default_font or loveframes.basicfont

    self.type = "toast"
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    self.font = font
    self.messages = {}
    self.spacing = 8
    self.padding = 6
    self.default_align = "center"
    self.box_valign = "right"
    self.box_halign = "down"
    self.box_margin = 2
    self.fade_time = 0.4
    self.default_time = 5
    self.collide = false
    self.margin = 2
    self.backgroundcolor = {0, 0, 0, 0.8}
    self.textcolor = {1, 1, 1, 1}
    self.outline = true
    self.message_order = "ascending"
    self.shadow = true
    self.relative_box_width = 0.6
    self:SetDrawFunc()
end

-----------------------------------------------------------
-- Push Message
-----------------------------------------------------------
function Toast:PushMessage(text, opt)
    if not text or text == "" then return end
    local options = {
        time        = self.default_time,
        font        = self.font,
        outline     = self.outline,
        spacing     = self.spacing,
        padding     = self.padding,
        margin      = self.margin,
        align       = self.default_align,
    }
    if type( opt ) == "table" then
        for k, v in pairs( opt ) do
            options[k] = v
        end
    end

    local text_fixed = self:fixUTF8(text)
    local msg = {}
    msg.text = text_fixed
    msg.time = options.time
    msg.font = options.font
    msg.outline = options.outline
    msg.padding = options.padding
    msg.spacing = options.spacing
    msg.margin = options.margin
    msg.life = 0
    msg.alpha = 1
    msg.batch = love.graphics.newTextBatch(msg.font)

    local formatted = self:ParseText(msg.text)
    local index = msg.batch:setf(
        formatted,
        math.floor(self.width * self.relative_box_width) - options.margin*2,
        options.align
    )
    msg.height = msg.batch:getHeight(index) + msg.padding * 2
    msg.width = msg.batch:getWidth()
    table.insert(self.messages, msg)

    if self.parent then
        self:MoveToTop()
    end
end

-----------------------------------------------------------
-- Update
-----------------------------------------------------------
function Toast:update(dt)
    if self.parent and not self:OnState() then return end
    if not self:isUpdating() then return end
	local parent = self.parent
	local base = loveframes.base
    if parent and parent ~= base then
        self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
    end

    for i = #self.messages, 1, -1 do
        local msg = self.messages[i]
        msg.life = msg.life + dt

        -- Fade
        if msg.life > (msg.time - self.fade_time) then
            local remaining = msg.time - msg.life
            msg.alpha = math.max(remaining / self.fade_time, 0)
        end

        -- Remove when finished
        if msg.life >= msg.time then
            msg.batch:release()
            table.remove(self.messages, i)
        end
    end
end

-----------------------------------------------------------
-- Draw
-----------------------------------------------------------
function Toast:draw()
    if self.parent and not self:OnState() then return end
    if not self:isUpdating() then return end

	local drawfunc = self.Draw or self.drawfunc
	local drawoverfunc = self.DrawOver or self.drawoverfunc

	if drawfunc then
		drawfunc(self)
	end
	if drawoverfunc then
		drawoverfunc(self)
	end
end

-----------------------------------------------------------
-- ParseText (mesmo padrão do log)
-----------------------------------------------------------
function Toast:fixUTF8(s, replacement)
  local p, len, invalid = 1, #s, {}
  while p <= len do
    if     p == s:find("[%z\1-\127]", p) then p = p + 1
    elseif p == s:find("[\194-\223][\128-\191]", p) then p = p + 2
    elseif p == s:find(       "\224[\160-\191][\128-\191]", p)
        or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
        or p == s:find(       "\237[\128-\159][\128-\191]", p)
        or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then p = p + 3
    elseif p == s:find(       "\240[\144-\191][\128-\191][\128-\191]", p)
        or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
        or p == s:find(       "\244[\128-\143][\128-\191][\128-\191]", p) then p = p + 4
    else
      s = s:sub(1, p-1)..replacement..s:sub(p+1)
      table.insert(invalid, p)
    end
  end
  return s, invalid
end

function Toast:ParseText(str)
    local formattedchunks = {}
    local defaultColor = self.textcolor
    local last = 1
    while true do
        local i, j = str:find("©", last)
        if not i then
            table.insert(formattedchunks, defaultColor)
            table.insert(formattedchunks, str:sub(last))
            break
        end

        if i > last then
            table.insert(formattedchunks, defaultColor)
            table.insert(formattedchunks, str:sub(last, i-1))
        end

        local k = str:find("©", j+1) or (#str+1)
        local capture = str:sub(j+1, k-1)

        local r,g,b = capture:match("(%d%d%d)(%d%d%d)(%d%d%d)")
        local text = capture:sub(10)

        if r and g and b then
            table.insert(formattedchunks, {
                tonumber(r)/255,
                tonumber(g)/255,
                tonumber(b)/255,
                1
            })
            table.insert(formattedchunks, text)
        end

        last = k
    end

    return formattedchunks
end

-----------------------------------------------------------
-- SetParent
-----------------------------------------------------------
function Toast:SetParent(parent)
    Toast.super.SetParent(self, parent)
    self:SetSize(parent:GetSize())
end
-----------------------------------------------------------

function Toast:SetBoxAlign(valign, halign)
    self.box_valign = valign
    self.box_halign = halign
    return self
end

function Toast:SetBoxVAlign(valign)
    self.box_valign = valign
    return self
end

function Toast:SetBoxHAlign(halign)
    self.box_halign = halign
    return self
end

function Toast:SetAlign(align)
    self.default_align = align
    return self
end

function Toast:SetMessageOrder(order)
    self.message_order = order
    return self
end

function Toast:SetShadow(bool)
    self.shadow = bool
    return self
end

function Toast:ToggleShadow()
    self.shadow = not self.shadow
    return self
end

function Toast:SetMargin(margin)
    self.margin = margin
    return self
end

function Toast:SetSpacing(spacing)
    self.spacing = spacing
    return self
end

function Toast:SetPadding(padding)
    self.padding = padding
    return self
end

function Toast:SetOutline(bool)
    self.outline = bool
    return self
end

function Toast:ToggleOutline()
    self.outline = not self.outline
    return self
end

function Toast:SetRelativeBoxWidth(width)
    self.relative_box_width = width
    return self
end

end
