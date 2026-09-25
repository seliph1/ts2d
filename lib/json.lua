--[[---------------------------------------------------------
	-- JSON Encoder & Decoder for Lua / LÖVE --
	-- Supports RFC 8259 Standard:
	-- - Strings with unicode \uXXXX and surrogate pairs
	-- - Objects, Arrays, Numbers, Booleans, Null
	-- - Fast, zero-dependency, safe error handling
--]]---------------------------------------------------------

local json = {}

-- Sentinel for explicit JSON null representation if needed
json.null = setmetatable({}, {
	__tostring = function() return "null" end
})

-- Unicode helper: converts code point to UTF-8 byte sequence
local function codepoint_to_utf8(cp)
	if cp < 0x80 then
		return string.char(cp)
	elseif cp < 0x800 then
		return string.char(
			0xC0 + math.floor(cp / 0x40),
			0x80 + (cp % 0x40)
		)
	elseif cp < 0x10000 then
		return string.char(
			0xE0 + math.floor(cp / 0x1000),
			0x80 + (math.floor(cp / 0x40) % 0x40),
			0x80 + (cp % 0x40)
		)
	else
		return string.char(
			0xF0 + math.floor(cp / 0x40000),
			0x80 + (math.floor(cp / 0x1000) % 0x40),
			0x80 + (math.floor(cp / 0x40) % 0x40),
			0x80 + (cp % 0x40)
		)
	end
end

local escape_chars = {
	['"']  = '"',
	['\\'] = '\\',
	['/']  = '/',
	['b']  = '\b',
	['f']  = '\f',
	['n']  = '\n',
	['r']  = '\r',
	['t']  = '\t',
}

---Decodes a JSON string into a corresponding Lua table, number, string, boolean or nil.
---@param str string JSON string to parse
---@return any
function json.decode(str)
	if type(str) ~= "string" then
		error("json.decode: string expected, got " .. type(str), 2)
	end

	local len = #str
	local pos = 1

	local function error_at(msg)
		local line = 1
		local col = 1
		for i = 1, math.min(pos, len) do
			if str:byte(i) == 10 then
				line = line + 1
				col = 1
			else
				col = col + 1
			end
		end
		error(string.format("JSON parse error at line %d, col %d (pos %d): %s", line, col, pos, msg), 3)
	end

	local function skip_whitespace()
		while pos <= len do
			local b = str:byte(pos)
			if b == 32 or b == 9 or b == 10 or b == 13 then
				pos = pos + 1
			else
				break
			end
		end
	end

	local parse_value

	local function parse_string()
		pos = pos + 1 -- Skip opening quote
		local start = pos
		local chunks = {}

		while pos <= len do
			local b = str:byte(pos)
			if b == 34 then -- '"'
				local res
				if #chunks == 0 then
					res = str:sub(start, pos - 1)
				else
					table.insert(chunks, str:sub(start, pos - 1))
					res = table.concat(chunks)
				end
				pos = pos + 1
				return res
			elseif b == 92 then -- '\\'
				table.insert(chunks, str:sub(start, pos - 1))
				pos = pos + 1
				local esc = str:sub(pos, pos)
				if escape_chars[esc] then
					table.insert(chunks, escape_chars[esc])
					pos = pos + 1
				elseif esc == 'u' then
					local hex = str:sub(pos + 1, pos + 4)
					if #hex < 4 or not hex:match("^[0-9a-fA-F]+$") then
						error_at("invalid unicode escape \\u" .. hex)
					end
					local cp = tonumber(hex, 16)
					pos = pos + 5

					-- Handle surrogate pairs (e.g. \uD83D\uDE00 for emoji)
					if cp >= 0xD800 and cp <= 0xDBFF and str:sub(pos, pos + 1) == "\\u" then
						local low_hex = str:sub(pos + 2, pos + 5)
						if #low_hex == 4 and low_hex:match("^[0-9a-fA-F]+$") then
							local low_cp = tonumber(low_hex, 16)
							if low_cp >= 0xDC00 and low_cp <= 0xDFFF then
								cp = 0x10000 + ((cp - 0xD800) * 0x400) + (low_cp - 0xDC00)
								pos = pos + 6
							end
						end
					end
					table.insert(chunks, codepoint_to_utf8(cp))
				else
					error_at("invalid escape character \\" .. esc)
				end
				start = pos
			elseif b < 32 then
				error_at("unescaped control character in string (ASCII " .. b .. ")")
			else
				pos = pos + 1
			end
		end
		error_at("unterminated string")
	end

	local function parse_number()
		local s, e = str:find("^%-?%d+%.?%d*[eE]?[+%-]?%d*", pos)
		if not s then
			error_at("malformed number")
			return
		end
		local num_str = str:sub(s, e)
		local num = tonumber(num_str)
		if not num then
			error_at("malformed number '" .. num_str .. "'")
		end
		pos = e + 1
		return num
	end

	local function parse_array()
		pos = pos + 1 -- Skip '['
		local arr = {}
		skip_whitespace()
		if pos <= len and str:byte(pos) == 93 then -- ']'
			pos = pos + 1
			return arr
		end

		local idx = 1
		while true do
			arr[idx] = parse_value()
			idx = idx + 1
			skip_whitespace()

			local b = str:byte(pos)
			if b == 44 then -- ','
				pos = pos + 1
				skip_whitespace()
			elseif b == 93 then -- ']'
				pos = pos + 1
				return arr
			else
				error_at("expected ',' or ']' in array")
			end
		end
	end

	local function parse_object()
		pos = pos + 1 -- Skip '{'
		local obj = {}
		skip_whitespace()
		if pos <= len and str:byte(pos) == 125 then -- '}'
			pos = pos + 1
			return obj
		end

		while true do
			skip_whitespace()
			if str:byte(pos) ~= 34 then -- '"'
				error_at("expected string key in object")
			end
			local key = parse_string()
			skip_whitespace()

			if str:byte(pos) ~= 58 then -- ':'
				error_at("expected ':' after object key")
			end
			pos = pos + 1 -- Skip ':'

			obj[key] = parse_value()
			skip_whitespace()

			local b = str:byte(pos)
			if b == 44 then -- ','
				pos = pos + 1
			elseif b == 125 then -- '}'
				pos = pos + 1
				return obj
			else
				error_at("expected ',' or '}' in object")
			end
		end
	end

	function parse_value()
		skip_whitespace()
		if pos > len then
			error_at("unexpected end of JSON input")
		end

		local b = str:byte(pos)

		if b == 34 then -- '"'
			return parse_string()
		elseif b == 123 then -- '{'
			return parse_object()
		elseif b == 91 then -- '['
			return parse_array()
		elseif (b >= 48 and b <= 57) or b == 45 then -- '0'-'9' or '-'
			return parse_number()
		elseif str:sub(pos, pos + 3) == "true" then
			pos = pos + 4
			return true
		elseif str:sub(pos, pos + 4) == "false" then
			pos = pos + 5
			return false
		elseif str:sub(pos, pos + 3) == "null" then
			pos = pos + 4
			return nil
		else
			error_at("unexpected character '" .. str:sub(pos, pos) .. "'")
		end
	end

	local result = parse_value()
	skip_whitespace()
	if pos <= len then
		error_at("trailing characters after JSON payload")
	end
	return result
end

---Safely decodes JSON without throwing errors; returns (ok, result_or_error_message).
---@param str string
---@return boolean ok
---@return any result_or_err
function json.safe_decode(str)
	local ok, res = pcall(json.decode, str)
	return ok, res
end

--[[---------------------------------------------------------
	JSON Encoder
--]]---------------------------------------------------------
local escape_map = {
	['"']  = '\\"',
	['\\'] = '\\\\',
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\n'] = '\\n',
	['\r'] = '\\r',
	['\t'] = '\\t',
}

local function escape_string(s)
	return '"' .. s:gsub('[%z\1-\31\\"]', function(c)
		return escape_map[c] or string.format("\\u%04x", c:byte())
	end) .. '"'
end

local function is_array(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	for i = 1, count do
		if t[i] == nil then
			return false
		end
	end
	return true
end

---Encodes a Lua value (table, string, number, boolean) into a JSON string.
---@param val any
---@return string
function json.encode(val)
	local t = type(val)
	if t == "nil" then
		return "null"
	elseif t == "boolean" then
		return val and "true" or "false"
	elseif t == "number" then
		if val ~= val or val == math.huge or val == -math.huge then
			return "null"
		end
		return tostring(val)
	elseif t == "string" then
		return escape_string(val)
	elseif t == "table" then
		if val == json.null then
			return "null"
		end
		if is_array(val) then
			local items = {}
			for i = 1, #val do
				items[i] = json.encode(val[i])
			end
			return "[" .. table.concat(items, ",") .. "]"
		else
			local items = {}
			for k, v in pairs(val) do
				table.insert(items, escape_string(tostring(k)) .. ":" .. json.encode(v))
			end
			return "{" .. table.concat(items, ",") .. "}"
		end
	else
		error("json.encode: unsupported type '" .. t .. "'", 2)
	end
end

-- Aliases
json.parse       = json.decode
json.safe_parse  = json.safe_decode
json.stringify   = json.encode

return json
