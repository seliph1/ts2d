local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--team pick ui------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.teampick_frame = nil
function ui.teampick_display()
	if client.joined and ui.teampick_frame == nil then
		local teams = client.share.config.teams

		ui.teampick_frame = LF.Create("frame")
			:SetSize(0.8, 0.8)
			:SetName("Select a team")
			:Center()
			:SetState("*")

		function ui.teampick_frame:OnClose()
			ui.teampick_frame = nil
		end

		local scrollpanel = LF.Create("scrollpanel", ui.teampick_frame)
			:SetPos(5, 35)
			:Expand("down", 105)
			:Expand("right", 0.5)

		local lookpanel = LF.Create("panel", ui.teampick_frame)
			:SetPos(0.5, 35)
			:Expand("down", 35)
			:Expand("right", 5)

		local autoselect_button = LF.Create("button", ui.teampick_frame)
			:SetY(-35)
			:SetHeight(28)
			:ExpandTo(scrollpanel, "horizontal", 0.8)
			:SetText("Auto-Select")

		function autoselect_button:OnClick()
			local team_id = teams[math.random(1, #teams)]
			local look_id
			if teams[team_id] and teams[team_id].looks then
				local looks = teams[team_id].looks
				look_id = looks[math.random(1, #looks)]
			else
				look_id = ""
			end
			client.send(string.format("team %s %s", team_id, look_id))

			ui.teampick_frame:Remove()
			ui.teampick_frame = nil
		end

		local spectator_button = LF.Create("button", ui.teampick_frame)
			:SetY(-70)
			:SetHeight(28)
			:ExpandTo(scrollpanel, "horizontal", 0.8)
			:SetText("Spectator")

		function spectator_button:OnClick()
			client.send("team 0")

			ui.teampick_frame:Remove()
			ui.teampick_frame = nil
		end

		function ui.teampick_frame.list_teams()
			for i = 1, #teams do
				local team_id = i
				local team = teams[team_id]
				local button = LF.Create("button", scrollpanel)
					:SetSize(0.8, 28)
					:CenterX()
					:SetY((team_id - 1) * 34)
					:SetText(team.name)

				function button:OnClick()
					if team.looks then
						scrollpanel:Clear()
						ui.teampick_frame.list_looks(team_id, team)
					else
						client.send(string.format("team %s", team_id))

						ui.teampick_frame:Remove()
						ui.teampick_frame = nil
					end
				end
			end
		end

		ui.teampick_frame.list_teams()

		-------------------------------------------------------------
		--looks
		-------------------------------------------------------------
		function ui.teampick_frame.list_looks(team_id, team)
			local looks = team.looks
			for i = 1, #looks do
				local look_id = i
				local look = looks[look_id]
				local button = LF.Create("button", scrollpanel)
					:SetSize(0.8, 28)
					:CenterX()
					:SetY((look_id - 1) * 34)
					:SetText(look.name)

				function button:OnClick()
					client.send(string.format("team %s", team_id))

					ui.teampick_frame:Remove()
					ui.teampick_frame = nil
				end
			end

			local backbutton = LF.Create("button", scrollpanel)
				:SetSize(0.8, 28)
				:CenterX()
				:SetY(#looks * 34)
				:SetText("Back")

			function backbutton:OnClick()
				scrollpanel:Clear()
				ui.teampick_frame.list_teams()
			end
		end
	end
end

end
