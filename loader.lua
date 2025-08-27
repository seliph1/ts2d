return function(client)
	--[[
	require "lib.lovefs.lovefs"
	local fs = lovefs()
	if love.filesystem.isFused() then
		fs:cd(love.filesystem.getSourceBaseDirectory() )
	else
		fs:cd(love.filesystem.getSource() )
	end]]

	local LF = love.filesystem
	local LG = love.graphics
	for _, item in pairs(client.content.itemlist) do
		local path = item.common_path
		local full_path_d = path .. item.dropped_image
		local full_path_h = path .. item.held_image
		local full_path_k = path .. item.kill_image
		local full_path = path .. item.display_image

		--[[
		if item.dropped_image ~= "" and fs:isFile(full_path) then
			client.gfx.itemlist[full_path] = fs:loadImage(full_path)
		end
		if item.held_image ~= "" and fs:isFile(full_path_d) then
			client.gfx.itemlist[full_path_d] = fs:loadImage(full_path_d)
		end
		if item.display_image ~= "" and fs:isFile(full_path_h) then
			client.gfx.itemlist[full_path_h] = fs:loadImage(full_path_h)
		end
		if item.kill_image ~= "" and fs:isFile(full_path_k) then
			client.gfx.itemlist[full_path_k] = fs:loadImage(full_path_k)
		end
		]]
		if item.dropped_image ~= "" and LF.getInfo(full_path, "file") then
			client.gfx.itemlist[full_path] = LG.newImage(full_path)
		end
		if item.held_image ~= "" and LF.getInfo(full_path_d, "file")  then
			client.gfx.itemlist[full_path_d] = LG.newImage(full_path_d)
		end
		if item.display_image ~= "" and LF.getInfo(full_path_h, "file")  then
			client.gfx.itemlist[full_path_h] = LG.newImage(full_path_h)
		end
		if item.kill_image ~= "" and LF.getInfo(full_path_k, "file")  then
			client.gfx.itemlist[full_path_k] = LG.newImage(full_path_k)
		end
	end

	for name, player in pairs(client.content.player) do
		client.gfx.player[name] = client.gfx.player[name] or {}
		local texture = LG.newImage(player.path)
		client.gfx.player[name].texture = texture
		for entry, value in pairs(player.stance) do
			client.gfx.player[name][entry] = love.graphics.newQuad(value[1], value[2], value[3], value[4], texture) --fs:loadImage(player.path)
		end
	end

	for _, item in pairs(client.content.ui) do
		client.gfx.ui[item] = LG.newImage(item)
	end
end