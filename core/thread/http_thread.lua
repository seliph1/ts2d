local console_in = love.thread.getChannel("console_in")
local console_out = love.thread.getChannel("console_out")

if love.getVersion() ~= 12 then
	return console_out:push("©255000000no https module available")
end
local https     = require "https"
local url       = require "socket.url"
local lf      	= require "love.image"
local fs 		= require "love.filesystem"

-- If module not found, just skip
if not https then return console_out:push("©255000000http: not available!") end

local args      = {...}
local hyperlink = table.concat(args, " ")

if not hyperlink then return console_out:push("©255000000http: empty url") end

--[[---------------------------------------------------------
	Helpers
--]]---------------------------------------------------------
local function console_log(message)
	console_out:push(tostring( message ))
end

local function urlencode(list)
	-- Since order of pairs is undefined, the key-value order is also undefined.
	local result = {}
	for k, v in pairs(list) do
		result[#result + 1] = url.escape(k).."="..url.escape(v)
	end
	return table.concat(result, "&")
end

local function encode_image(body)
	local filedata = fs.newFileData(body, "image")
	
	local data = { pcall(lf.newImageData, filedata) }
	local status = data[1]
	if not status then
		local error_message = data[2]
		console_log("©255000000LUA ERROR: "..error_message)
		return
	end
	return data[2]
end
--[[---------------------------------------------------------
	Main
--]]---------------------------------------------------------


console_log("http: request on ".. hyperlink)

local code, body, headers = https.request(hyperlink, {
	headers = {
		["User-Agent"] = "LOVE/12.0 (lua-https)"
	};
	method = "GET";
	--[[
	data = urlencode({
		key = "value";
	})--]]
})


if code == 0 then
	console_log("http: request failure: code "..code)
	return
else
	console_log("http: "..(code or "nil"))
end

if not headers or type(headers) ~= "table" then
	headers = {}
end	

--[[
for k,v in pairs(headers) do
	http_response:push(k.." "..v)
end--]]

if headers["content-type"] then
	local content_type = headers["content-type"]
	console_log("http: content-type "..content_type)

	local is_image = content_type:find("image")
	if is_image then
		local image_data = encode_image( body )

		if image_data then
			console_in:push({
				action = "display_image";
				args = {
					image_data = image_data;
				}
			})
		end
	end	-- if content_type:find("image")...

	if not is_image then
		console_in:push({
			action = "display_http_response";
			args = {
				body = body;
			}
		})
	end
end

if not headers["content-type"] then
	-- TODO: Try to detect which type of file

	console_in:push({
		action = "display_http_response";
		args = {
			body = body;
		}
	})
end

