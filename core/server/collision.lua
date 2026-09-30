-- Module start
return function(server)
---------- module start ----------
local collision = {}

do
	local width, height = server.map:getDimensions()
	for x = 0, width do
	for y = 0, height do
		local tile_id, mod, property  = server.map:tile(x, y)
		if property == 1 then
			server.world:add( mod, x*32, y*32, 32, 32)
		end	
	end
	end
end

---------- module end ------------
end