local function imageload(path)
	local imageData = love.image.newImageData(path)
	imageData:mapPixel(function(x, y, r, g, b, a)
		-- Verifica se é magenta (255,0,255)
		-- Normalmente os valores de cor vêm como floats 0..1
		if r == 1 and g == 0 and b == 1 then
			return 1, 0, 1, 0 -- deixa transparente (alpha=0)
		--elseif r == 0 and g == 0 and b == 0 then
			--return 0, 0, 0, 0 -- deixa transparente (alpha=0)
		else
			return r, g, b, a
		end
	end)
	local image = love.graphics.newImage(imageData)-- Remove magenta pixels
	return image
end

return function(client)
	client.gfx = {
		hud = {};
		ui = {};
	}

	client.sfx = {
		ui = {}
	}

	local LF = love.filesystem
	local LG = love.graphics

	for _, item in pairs(client.content.ui) do
		client.gfx.ui[item] = imageload(item)
	end
end