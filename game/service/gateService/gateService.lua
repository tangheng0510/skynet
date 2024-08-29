local skynet = require "skynet"
local socket = require "skynet.socket"

local clients = {}
local CMD = {}

local function connect(fd, addr)
	--启用连接，开始等待接收客户端消息
	print(fd .. " connected addr:" .. addr)
	socket.start(fd)
	clients[fd] = {}
	--消息处理
	while true do
		local readdata = socket.read(fd) --利用协程实现阻塞模式
		--正常接收
		if readdata ~= nil then
			print(fd .. " recv " .. readdata)
		else 
			print(fd .. " close ")
			socket.close(fd)
			clients[fd] = nil
		end	
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd , ...) --skynet.dispatch指定参数一类型消息的处理方式（这里是“lua”类型，Lua服务间的消息类型是“lua”），即处理lua服务之间的消息
		local f = CMD[cmd]
        if f then
            f(source, ...)
        end
	end)

    local listenfd = socket.listen("0.0.0.0", 8888) --监听所有ip，端口8888
	socket.start(listenfd, connect) --新客户端发起连接时，conncet方法将被调用。
end)

