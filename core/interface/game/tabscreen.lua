local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--tabscreen ui------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
---@param team_id number
---@return string, string, number, number
function ui.tabscreen_getplayerlist(team_id)
	local share = client.share
	if not (share or share.players) then return "", "", 0, 0 end

	local str_names = ""
	local str_ids = ""
	local count = 0
	local index = 0
	for peer_id, player in pairs(share.players) do
		if player.t == team_id then
			str_names = str_names .. player.n .. "\n"
			str_ids = str_ids .. peer_id .. "\n"
			count = count + 1
		end

		if player.id == client.id then
			index = count
		end
	end
	return str_names, str_ids, count, index
end

function ui.tabscreen_display()
	if ui.tabscreen or not (client.joined) then return end

	local share = client.share
	if not (share or share.players or share.config) then return end

	local players = share.players
	if not players then return end

	local teams = share.config.teams
	if not teams then return end

	ui.tabscreen = LF.Create("panel")
		:SetSize(0.8, 0.8)
		:Center()
		:SetCollidable(false)
		:SetState("game")

	local team_columns = {}

	for i = #teams, 0, -1 do
		local team_id = i
		local team = teams[team_id]

		if team then
			--print("©"..team.color, team.color, team.name)
			table.insert(team_columns, {
				color = team.color,
				title = ui.getcoloredtext("©" .. team.color .. team.name .. " Forces"),
				players = ui.getcoloredtext("©" .. team.color),
				id = team_id,
				color_table = ui.getcolortable(team.color)
			})

			if team_id == 0 then
				team_columns[#team_columns].title = ui.getcoloredtext("©" .. team.color .. team.name)
			end
		end
	end

	function ui.tabscreen:Update()
		if not love.keyboard.isDown("tab") then
			ui.tabscreen:Remove()
			ui.tabscreen = nil
		end
	end

	local font_height = ui.font_chat:getHeight()
	local margin = 20
	function ui.tabscreen:Draw()
		love.graphics.push("all")
		love.graphics.translate(self.x, self.y)

		love.graphics.setColor(0.0, 0.0, 0.0, 0.5)
		love.graphics.rectangle("fill", 0, 0, self.width, self.height, 5, 5)

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.setFont(ui.font_chat)

		local height = 0
		for _, team_row in ipairs(team_columns) do
			local str_names, str_ids, count, index = ui.tabscreen_getplayerlist(team_row.id)
			team_row.players[2] = str_names

			love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
			love.graphics.print(team_row.title, margin, height)
			height = height + font_height

			love.graphics.setColor(team_row.color_table)
			love.graphics.setLineStyle("smooth")
			love.graphics.setLineWidth(1)
			love.graphics.line(margin, height, self.width - margin, height)

			love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
			love.graphics.print(team_row.players, margin, height)
			love.graphics.print(str_ids, 0, height)

			if index > 0 then
				love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
				love.graphics.rectangle("line", margin, height + font_height * (index - 1), self.width - margin,
					font_height)
			end
			height = height + font_height * (count) + 10
		end

		love.graphics.pop()
	end
end

end
