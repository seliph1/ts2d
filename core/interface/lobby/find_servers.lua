local LF = require "lib.loveframes"
local client = require "core.client"
local console = require "core.interface.console"
local json = require "lib.json"
local serpent = require "lib.serpent"

return function(ui)
    --https://ts2d.c4server.website/serverlist/load?debug=true

    ----------------------------------------------------------------------------------------------------
    -- Find Servers Frame
    ----------------------------------------------------------------------------------------------------
    local frame_w = 980
    local frame_h = 580

    ui.find_servers_frame = LF.Create("frame")
        :SetName("Servers")
        :SetSize(frame_w, frame_h)
        :Center()
        :SetCloseAction("hide")
        :SetState("none")
        :SetVisible(false)

    ----------------------------------------------------------------------------------------------------
    -- Top-Right Server / Player / Bot Statistics
    ----------------------------------------------------------------------------------------------------
    local stat_font = ui.font_small or LF.basicfontsmall

    local stat_servers_text = "110 Servers (110)"
    local stat_players_text = "2 Players (2)"
    local stat_bots_text = "24 Bots (24)"

    local right_edge = frame_w - 20
    local stat_servers_w = stat_font:getWidth(stat_servers_text)
    local stat_players_w = stat_font:getWidth(stat_players_text)
    local stat_bots_w = stat_font:getWidth(stat_bots_text)

    ui.fs_stat_servers = LF.Create("label", ui.find_servers_frame)
        :SetFont(stat_font)
        :SetText("©150150150" .. stat_servers_text)
        :SetPos(right_edge - stat_servers_w, 24)

    ui.fs_stat_players = LF.Create("label", ui.find_servers_frame)
        :SetFont(stat_font)
        :SetText("©150150150" .. stat_players_text)
        :SetPos(right_edge - stat_players_w, 38)

    ui.fs_stat_bots = LF.Create("label", ui.find_servers_frame)
        :SetFont(stat_font)
        :SetText("©150150150" .. stat_bots_text)
        :SetPos(right_edge - stat_bots_w, 52)

    ----------------------------------------------------------------------------------------------------
    -- Tabs
    ----------------------------------------------------------------------------------------------------
    local tab_w = frame_w - 20
    local tab_h = frame_h - 88

    ui.find_servers_tabs = LF.Create("tabs", ui.find_servers_frame)
        :SetPos(10, 32)
        :SetSize(tab_w, tab_h)

    local content_h = tab_h - 30

    ui.tab_internet = LF.Create("container"):SetPos(0, 30):SetSize(tab_w, content_h)
    ui.tab_lan = LF.Create("container"):SetPos(0, 30):SetSize(tab_w, content_h)
    ui.tab_favorites = LF.Create("container"):SetPos(0, 30):SetSize(tab_w, content_h)
    ui.tab_recent = LF.Create("container"):SetPos(0, 30):SetSize(tab_w, content_h)

    ui.find_servers_tabs:AddTab("Internet (0)", ui.tab_internet)
    ui.find_servers_tabs:AddTab("LAN (0)", ui.tab_lan)
    ui.find_servers_tabs:AddTab("Favorites (0)", ui.tab_favorites)
    ui.find_servers_tabs:AddTab("Recently Joined (0)", ui.tab_recent)

    ----------------------------------------------------------------------------------------------------
    -- Server List Table (Columnlist)
    ----------------------------------------------------------------------------------------------------
    ui.server_list = LF.Create("columnlist", ui.tab_internet)
        :SetPos(0, 0)
        :SetSize(tab_w, content_h - 4)
        :SetColumnHeight(20)

    -- Header columns matching CS2D Find Servers
    -- 1: Icons / Status, 2: Server Name, 3: Map, 4: Players, 5: Latency
    ui.server_list:AddColumn("")
    ui.server_list:AddColumn("Name")
    ui.server_list:AddColumn("Map")
    ui.server_list:AddColumn("Players")
    ui.server_list:AddColumn("Latency")


    -- Column 5 Custom Renderer: Latency bars / ping indicator
    ui.server_list:SetColumnRenderer(5, function(row, value, x, y, width, height, textx, texty)
        local bars = tonumber(value)
        if bars then
            local start_x = x + (textx or 5)
            local bar_y = y + math.floor(height / 2 - 5)
            for b = 1, 8 do
                if b <= bars then
                    love.graphics.setColor(0.35, 0.9, 0.1, 1)
                else
                    love.graphics.setColor(0.18, 0.18, 0.18, 1)
                end
                love.graphics.rectangle("fill", start_x + (b - 1) * 3, bar_y, 2, 10)
            end
        else
            local text_x = x + (textx or 5)
            local text_y = y + (texty or 0)
            local skin = LF.GetActiveSkin()
            if skin and skin.PrintText then
                skin.PrintText(value, text_x, text_y)
            else
                love.graphics.print(value, text_x, text_y)
            end
        end
    end)

    ----------------------------------------------------------------------------------------------------
    -- Populate Server Entries
    ----------------------------------------------------------------------------------------------------
    local server_records = {}

    local function connect_to_server(ip, port)
        local console = require "core.interface.console"
        ui.find_servers_frame:SetVisible(false)
        if console and console.parse then
            console.parse(string.format("connect %s %s", ip or "127.0.0.1", port or 36963))
        end
    end

    --[[
ui.populate_find_servers = function()
	ui.server_list:Clear()
	server_records = {}

	-- Active server from screenshot
	local record_1 = {
		flags = "©255060060Ds",
		name = "©255060060-[IfWsI]- Deagle One Shot",
		map = "©180060060cs_office",
		players = "©0502550502/32",
		latency = "5",
		ip = "51.81.33.11",
		port = "28500",
	}
	table.insert(server_records, record_1)
	ui.server_list:AddRow(record_1.flags, record_1.name, record_1.map, record_1.players, record_1.latency)

	-- Unresponsive server entries from screenshot
	local unresponsive_ips = {
		"51.81.33.11:28500",
		"157.90.231.122:20003",
		"157.90.170.75:10000",
		"157.90.170.75:10008",
		"159.69.140.91:20004",
		"139.99.135.16:36963",
		"42.194.186.24:36960",
		"188.192.105.33:36965",
		"188.192.105.33:36966",
		"51.81.33.11:27500",
		"45.77.92.159:30001",
		"45.77.92.159:30000",
		"23.230.3.206:36965",
		"185.17.3.123:36699",
		"185.17.3.123:36967",
		"42.194.134.240:36963",
		"194.105.5.43:36963",
		"80.78.132.21:10619",
		"185.17.3.123:36369",
		"161.97.161.121:36963",
		"80.78.132.21:10616",
		"80.78.132.21:10617",
		"188.132.197.200:36963",
	}

	for _, address in ipairs(unresponsive_ips) do
		local ip, port = address:match("^(.-):(%d+)$")
		local record = {
			flags = "©255060060?",
			name = "©255060060" .. address,
			map = "",
			players = "©2550600600/0",
			latency = "©140140140|?|?|?|",
			ip = ip or address,
			port = port or "36963",
		}
		table.insert(server_records, record)
		ui.server_list:AddRow(record.flags, record.name, record.map, record.players, record.latency)
	end
end

ui.populate_find_servers()
]]

    --[[
https://ts2d.c4server.website/serverlist/load?debug=true

Carrega a lista.
Vai carregar 20 servers aleatórios (100 na lista) pq tem debug=true, pra tu testar.
Se der F5, vai carregar os mesmos (1 min cache, comento sobre o cache logo abaixo)

https://ts2d.c4server.website/serverlist/data/188.40.70.19:36963
Retorna em JSON os dados do server. (sem cache)

O /serverlist/load tem cache próprio de 1 minuto.
Se passar a flag &reload=true, ignora o cache a cada requisição.
(só pra listagem dos servers)
]]

    local MASTERSERVER = "ts2d.c4server.website"
    function ui.server_list_get(ip)
        if not ip then return end
        local url = "https://" .. ip
        local endpoint = "/serverlist/load?debug=true"

        ui.server_list:Clear()
        server_records = {}

        console.http_get(url .. endpoint, function(body, code, headers)
            if code ~= 200 then return print("HTTP error: ", code) end
            local ok, data = json.safe_decode(body)
            if not ok then return print("Error decoding json") end
            for k, v in ipairs(data) do
                local address, port = v.ip:match("^(.-):(%d+)$")
                local record = {
                    flags = "©255060060Ds",
                    name = "©255060060" .. (v.name or ""),
                    map = "©180060060fun_roleplay",
                    players = "©050255050" .. math.random(1, 32) .. "/32",
                    latency = tostring(math.random(0, 8)),
                    ip = address or "51.81.33.11",
                    port = port or "28500",
                }

                table.insert(server_records, record)
                ui.server_list:AddRow(record.flags, record.name, record.map, record.players, record.latency)
            end
        end)
    end

    -- Double-click tracking
    local last_clicked_row = nil
    local last_clicked_time = 0

    ui.server_list.OnRowClicked = function(self, row, columndata)
        local cur_time = love.timer.getTime()
        if last_clicked_row == row and (cur_time - last_clicked_time) < 0.4 then
            -- Double click: trigger connect
            local selected = ui.server_list:GetSelectedRows()
            local row_idx = nil
            local list_internal = self.internals[1]
            for i, r in ipairs(list_internal.rows) do
                if r == row then
                    row_idx = i
                    break
                end
            end
            if row_idx and server_records[row_idx] then
                local rec = server_records[row_idx]
                connect_to_server(rec.ip, rec.port)
            end
        end
        last_clicked_row = row
        last_clicked_time = cur_time
    end

    ----------------------------------------------------------------------------------------------------
    -- Bottom Action Buttons
    ----------------------------------------------------------------------------------------------------
    local btn_y = frame_h - 42
    local btn_h = 28

    -- Left Buttons: Filters, Refresh
    ui.find_servers_button_filters = LF.Create("button", ui.find_servers_frame)
        :SetText("Filters (0)")
        :SetPos(10, btn_y)
        :SetSize(115, btn_h)

    ui.find_servers_button_refresh = LF.Create("button", ui.find_servers_frame)
        :SetText("Refresh")
        :SetPos(133, btn_y)
        :SetSize(115, btn_h)

    ui.find_servers_button_refresh.OnClick = function()
        --ui.populate_find_servers()
        ui.server_list_get(MASTERSERVER)
    end

    -- Right Buttons: Connect to IP, Connect
    ui.find_servers_button_connect_ip = LF.Create("button", ui.find_servers_frame)
        :SetText("Connect to IP")
        :SetPos(frame_w - 268, btn_y)
        :SetSize(130, btn_h)

    ui.find_servers_button_connect = LF.Create("button", ui.find_servers_frame)
        :SetText("Connect")
        :SetPos(frame_w - 130, btn_y)
        :SetSize(120, btn_h)

    ui.find_servers_button_connect.OnClick = function()
        local selected = ui.server_list:GetSelectedRows()
        local row_idx = nil
        if #selected > 0 then
            local list_internal = ui.server_list.internals[1]
            for i, r in ipairs(list_internal.rows) do
                if r == selected[1] then
                    row_idx = i
                    break
                end
            end
        end

        if row_idx and server_records[row_idx] then
            local rec = server_records[row_idx]
            connect_to_server(rec.ip, rec.port)
        else
            -- Default to first record if none explicitly selected
            if server_records[1] then
                local rec = server_records[1]
                connect_to_server(rec.ip, rec.port)
            end
        end
    end

    ----------------------------------------------------------------------------------------------------
    -- Connect to IP Modal Dialog
    ----------------------------------------------------------------------------------------------------
    ui.connect_ip_frame = LF.Create("frame")
        :SetName("Connect to IP")
        :SetSize(340, 130)
        :Center()
        :SetCloseAction("hide")
        :SetState("none")
        :SetVisible(false)

    local ip_label = LF.Create("label", ui.connect_ip_frame)
        :SetText("Enter server IP and port:")
        :SetPos(16, 36)

    local ip_input = LF.Create("textbox", ui.connect_ip_frame)
        :SetPos(16, 58)
        :SetSize(308, 24)
        :SetText("127.0.0.1:36963")

    local ip_btn_connect = LF.Create("button", ui.connect_ip_frame)
        :SetText("Connect")
        :SetPos(16, 92)
        :SetSize(148, 26)

    local ip_btn_cancel = LF.Create("button", ui.connect_ip_frame)
        :SetText("Cancel")
        :SetPos(176, 92)
        :SetSize(148, 26)

    ip_btn_cancel.OnClick = function()
        ui.connect_ip_frame:SetVisible(false)
    end

    ip_btn_connect.OnClick = function()
        local text = ip_input:GetText()
        local ip, port = text:match("^(.-):(%d+)$")
        if not ip then
            ip = text
            port = "36963"
        end
        ui.connect_ip_frame:SetVisible(false)
        connect_to_server(ip, port)
    end

    ui.find_servers_button_connect_ip.OnClick = function()
        ui.connect_ip_frame:SetVisible(true):Center():MoveToTop()
    end

    ----------------------------------------------------------------------------------------------------
    -- Filters Modal Dialog
    ----------------------------------------------------------------------------------------------------
    ui.find_servers_filters_frame = LF.Create("frame")
        :SetName("Server Filters")
        :SetSize(320, 200)
        :Center()
        :SetCloseAction("hide")
        :SetState("none")
        :SetVisible(false)

    local chk_not_full = LF.Create("checkbox", ui.find_servers_filters_frame)
        :SetText("Server not full")
        :SetPos(20, 36)

    local chk_has_players = LF.Create("checkbox", ui.find_servers_filters_frame)
        :SetText("Has players")
        :SetPos(20, 62)

    local chk_no_password = LF.Create("checkbox", ui.find_servers_filters_frame)
        :SetText("Is not password protected")
        :SetPos(20, 88)

    local chk_fow = LF.Create("checkbox", ui.find_servers_filters_frame)
        :SetText("Fog of War disabled")
        :SetPos(20, 114)

    local btn_close_filter = LF.Create("button", ui.find_servers_filters_frame)
        :SetText("OK")
        :SetPos(110, 154)
        :SetSize(100, 26)

    btn_close_filter.OnClick = function()
        ui.find_servers_filters_frame:SetVisible(false)
    end

    ui.find_servers_button_filters.OnClick = function()
        ui.find_servers_filters_frame:SetVisible(true):Center():MoveToTop()
    end

    -- End of module
end
