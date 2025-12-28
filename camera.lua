return function(client)
---------- module start ----------
local function tween(a, b, t)
	return a + (b - a) * t
end

client.camera = {
	x = 0,
	y = 0,
	tx = 0,
	ty = 0,
	snap_pointer = {category = nil, id = nil},
	snap_enabled = false,
	speed = 500, -- pixel/frame
	tween_speed = 15, -- pixel/frame
	pointer = nil
}

--- Camera movement vector function
---@param dt number Delta time
function client.camera_move(dt)
	local camera = client.camera
	local home = client.home
	-- Speed
	local s = camera.speed * dt
	if client.key.space then
		s = s * 5
	end
	-- Vector
	local vx, vy = 0, 0
	if (client.key.up) then vy = -s end
	if (client.key.left) then vx = -s end
	if (client.key.down) then vy = s end
	if (client.key.right) then vx = s end
	-- Vector apply
	camera.tx = camera.tx + vx
	camera.ty = camera.ty + vy

	local p = camera.pointer and camera.pointer.target
	if p and p.x and p.y then
		local x = p.x
		local y = p.y
		--local delta_x = (client.width/2 - home.targetX)/2
		--local delta_y = (client.height/2 - home.targetY)/2
		local delta_x = 0
		local delta_y = 0
		camera.tx = x - delta_x
		camera.ty = y - delta_y
	end
end

function client.camera_follow(target)
	client.camera.pointer = setmetatable( { target = target }, { __mode = "v"} )
end

function client.camera_translate(x, y)
	client.camera_unbind()

	local camera = client.camera
	camera.x = x
	camera.y = y
	camera.tx = x
	camera.ty = y
end

function client.camera_unbind()
	client.camera.pointer = nil
end

function client.camera_shake()
end

---Camera interpolated movement function
---@param dt number Delta time
function client.camera_tween(dt)
	client.camera.x = tween(client.camera.x, client.camera.tx, client.camera.tween_speed * dt)
	client.camera.y = tween(client.camera.y, client.camera.ty, client.camera.tween_speed * dt)
end
---------- module end ------------
end