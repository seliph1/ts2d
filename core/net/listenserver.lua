--- Listen server (controle no lado do cliente)
--- Sobe/derruba o servidor vendorizado (core/server) numa love.thread, deixando
--- este cliente também ser host. O cliente conecta no loopback como sempre.
--- O thread runner é core/thread/server_thread.lua.
return function(client)
	local CTL = "listenserver_ctl"
	local EVT = "listenserver_evt"

	--- Sobe o listen server, se ainda não estiver rodando.
	---@param map string?  mapa (reservado; v1 usa o default do servidor)
	---@return boolean started
	function client.startListenServer(map)
		if client.listenThread and client.listenThread:isRunning() then
			return false
		end
		-- limpa canais de uma sessão anterior
		love.thread.getChannel(CTL):clear()
		love.thread.getChannel(EVT):clear()

		local thread = love.thread.newThread("core/thread/server_thread.lua")
		client.listenThread = thread
		thread:start(map, nil, 36963)
		print("listenserver: iniciando host em 127.0.0.1:36963 (map=" .. tostring(map or "default") .. ")")
		return true
	end

	--- Para o listen server e espera a thread encerrar (libera a porta UDP).
	function client.stopListenServer()
		local t = client.listenThread
		if not t then return end
		love.thread.getChannel(CTL):push("stop")
		t:wait()
		client.listenThread = nil
		print("listenserver: parado")
	end

	--- Drena os eventos da thread (ready/error/stopped). Chamar a cada frame.
	function client.pollListenServer()
		local t = client.listenThread
		if not t then return end
		local ch = love.thread.getChannel(EVT)
		local e = ch:pop()
		while e ~= nil do
			if type(e) == "table" then
				if e.type == "ready" then
					print("listenserver: pronto na porta " .. tostring(e.port))
				elseif e.type == "log" then
					print("listenserver: " .. tostring(e.msg))
				elseif e.type == "error" then
					print("listenserver: ERRO -> " .. tostring(e.msg))
				elseif e.type == "stopped" then
					print("listenserver: thread encerrada")
				end
			end
			e = ch:pop()
		end
		-- captura crash duro da thread (erro fora do pcall do runner)
		local err = t:getError()
		if err then
			print("listenserver: CRASH NA THREAD -> " .. tostring(err))
			client.listenThread = nil
		end
	end
end
