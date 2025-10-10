return function(client)
	--[[
	require "lib.lovefs.lovefs"
	local fs = lovefs()
	if love.filesystem.isFused() then
		fs:cd(love.filesystem.getSourceBaseDirectory() )
	else
		fs:cd(love.filesystem.getSource() )
	end]]


	local function imageload(path)
		local imageData = love.image.newImageData(path)
		imageData:mapPixel(function(x, y, r, g, b, a)
			-- Verifica se é magenta (255,0,255)
			-- Normalmente os valores de cor vêm como floats 0..1
			if r == 1 and g == 0 and b == 1 then
				return 1, 0, 1, 0 -- deixa transparente (alpha=0)
			else
				return r, g, b, a
			end
		end)
		local image = love.graphics.newImage(imageData)-- Remove magenta pixels
		return image
	end

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
			client.gfx.itemlist[full_path] = imageload(full_path)
		end
		if item.held_image ~= "" and LF.getInfo(full_path_d, "file")  then
			client.gfx.itemlist[full_path_d] = imageload(full_path_d)
		end
		if item.display_image ~= "" and LF.getInfo(full_path_h, "file")  then
			client.gfx.itemlist[full_path_h] = imageload(full_path_h)
		end
		if item.kill_image ~= "" and LF.getInfo(full_path_k, "file")  then
			client.gfx.itemlist[full_path_k] = imageload(full_path_k)
		end
	end

	for name, player in pairs(client.content.player) do
		client.gfx.player[name] = client.gfx.player[name] or {}
		local texture = imageload(player.path)
		client.gfx.player[name].texture = texture
		for entry, value in pairs(player.stance) do
			client.gfx.player[name][entry] = love.graphics.newQuad(value[1], value[2], value[3], value[4], texture) --fs:loadImage(player.path)
		end
	end

	for _, item in pairs(client.content.ui) do
		client.gfx.ui[item] = imageload(item)
	end
end