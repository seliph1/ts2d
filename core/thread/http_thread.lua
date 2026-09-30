local console_in = love.thread.getChannel("console_in")
local console_out = love.thread.getChannel("console_out")

--[[---------------------------------------------------------
	Helpers
--]]---------------------------------------------------------
local function notify_callback(callback_id, message, code)
	if callback_id then
		console_in:push({
			action = "function",
			callback_id = callback_id,
			args = { nil, code or 0, {}, tostring(message) },
		})
	else
		console_out:push(tostring(message))
	end
end

--[[---------------------------------------------------------
	Argument Parsing
	Supports table config: { url, method, headers, data, callback_id }
	or varargs: url, [options_or_callback_id], [callback_id]
--]]---------------------------------------------------------
local raw_arg1, raw_arg2, raw_arg3 = ...
local request = {}
local callback_id = nil

if type(raw_arg1) == "table" then
	request = raw_arg1
	callback_id = raw_arg1.callback_id
elseif type(raw_arg1) == "string" then
	request.url = raw_arg1
	if type(raw_arg2) == "table" then
		for k, v in pairs(raw_arg2) do request[k] = v end
		callback_id = raw_arg2.callback_id
	elseif type(raw_arg2) == "number" or type(raw_arg2) == "string" then
		callback_id = raw_arg2
	end
	if raw_arg3 and (type(raw_arg3) == "number" or type(raw_arg3) == "string") then
		callback_id = raw_arg3
	end
end

local hyperlink = request.url

if love.getVersion() ~= 12 then
	notify_callback(nil, "©255000000no https module available (requires LOVE 12)")
	return
end

local https = require "https"
local url   = require "socket.url"
local lf    = require "love.image"
local fs    = require "love.filesystem"

-- If module not found, report and exit
if not https then
	notify_callback(nil, "©255000000http: https module not available!")
	return
end

if not hyperlink or hyperlink == "" then
	notify_callback(nil, "©255000000http: empty url")
	return
end

local function urlencode(list)
	local result = {}
	for k, v in pairs(list) do
		result[#result + 1] = url.escape(k) .. "=" .. url.escape(v)
	end
	return table.concat(result, "&")
end

local function encode_image(body)
	if not body or #body == 0 then return nil end
	local filedata = fs.newFileData(body, "image")
	local data = { pcall(lf.newImageData, filedata) }
	local status = data[1]
	if not status then
		local error_message = data[2]
		notify_callback(callback_id, "©255000000LUA ERROR: " .. tostring(error_message), 0)
		return nil
	end
	return data[2]
end

--[[---------------------------------------------------------
	Main HTTP Request
--]]---------------------------------------------------------
console_out:push("http: request on " .. hyperlink)

local req_method = (request.method or "GET"):upper()
local req_headers = request.headers or {}
if not req_headers["User-Agent"] and not req_headers["user-agent"] then
	req_headers["User-Agent"] = "LOVE/12.0 (lua-https)"
end

local req_data = request.data or request.body
if type(req_data) == "table" then
	req_data = urlencode(req_data)
	if not req_headers["Content-Type"] and not req_headers["content-type"] then
		req_headers["Content-Type"] = "application/x-www-form-urlencoded"
	end
end

local code, body, headers = https.request(hyperlink, {
	headers = req_headers,
	method = req_method,
	data = req_data,
})

if code == 0 then
	console_out:push("http: request failure: code " .. tostring(code))
	notify_callback(callback_id, "Request failed (connection error or timeout)", code)
	return
else
	console_out:push("http: " .. tostring(code or "nil"))
end

if not headers or type(headers) ~= "table" then headers = {} end

-- Normalize headers to lowercase for content-type detection
local content_type = ""
for k, v in pairs(headers) do
	if k:lower() == "content-type" then
		content_type = tostring(v):lower()
		break
	end
end

local is_image = content_type:find("image")
local image_data = nil
if is_image then
	console_out:push("http: content-type " .. content_type)
	image_data = encode_image(body)
end

if callback_id then
	-- Call the registered callback through the console channel
	console_in:push({
		action = "function",
		callback_id = callback_id,
		args = {
			body,
			code,
			headers,
			image_data,
		}
	})
else
	-- No callback provided: default console display behavior
	if is_image and image_data then
		console_in:push({
			action = "display_image",
			args = {
				image_data = image_data,
			}
		})
	else
		console_in:push({
			action = "display_http_response",
			args = {
				body = body,
			}
		})
	end
end
