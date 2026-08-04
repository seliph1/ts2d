-- =============================================================================
-- core/thread/server_thread.lua — Listen server
-- Roda o servidor vendorizado (core/server) dentro de uma love.thread, fazendo
-- este cliente também ser host. O cliente conecta no loopback (127.0.0.1:36963)
-- como qualquer outro cliente — sem nenhuma mudança de protocolo.
--
-- Canais:
--   listenserver_ctl : cliente -> thread   ("stop")
--   listenserver_evt : thread  -> cliente  ({type="ready"|"error"|"stopped", ...})
-- =============================================================================
local ctl = love.thread.getChannel("listenserver_ctl")
local evt = love.thread.getChannel("listenserver_evt")

-- Redireciona print da thread do servidor para enviar mensagens de log ao cliente principal
local _print = print
function _G.print(...)
	local args = { ... }
	for i = 1, #args do
		args[i] = tostring(args[i])
	end
	local msg = table.concat(args, "\t")
	_print(msg)
	evt:push({ type = "log", msg = msg })
end

-- Numa love.thread só love.thread vem por padrão; declara os submódulos usados.
require "love.timer"
require "love.filesystem"

-- Resolve os requires do servidor a partir de core/server/ (estado Lua fresco,
-- então é seguro/isolado). Prepende para as cópias do servidor vencerem as do cliente.
local base = "core/server/"
love.filesystem.setRequirePath(base .. "?.lua;" .. base .. "?/init.lua;" .. love.filesystem.getRequirePath())

-- local map, settings, port = ...   -- TODO(v1+): escolher mapa/porta; hoje usa defaults

local ok, server = pcall(require, "server")
if not ok then
	evt:push({ type = "error", msg = "require server: " .. tostring(server) })
	return
end

local ok2, err = pcall(server.load)   -- abre o host enet (*:36963) e carrega o mapa
if not ok2 then
	evt:push({ type = "error", msg = "server.load: " .. tostring(err) })
	return
end
evt:push({ type = "ready", port = 36963 })

local timer   = love.timer
local last    = timer.getTime()
local running = true

while running do
	-- comandos de controle (parada graciosa)
	local cmd = ctl:pop()
	while cmd ~= nil do
		if cmd == "stop" or (type(cmd) == "table" and cmd.action == "stop") then
			running = false
		end
		cmd = ctl:pop()
	end

	local now = timer.getTime()
	local dt  = now - last
	last = now

	local ok3, uerr = pcall(server.update, dt)
	if not ok3 then
		evt:push({ type = "error", msg = "server.update: " .. tostring(uerr) })
		running = false
	end
	timer.sleep(1 / 60)
end

if server.shutdown then server.shutdown() end
evt:push({ type = "stopped" })
