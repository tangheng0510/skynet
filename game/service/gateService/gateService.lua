local skynet = require "skynet"
local socket = require "skynet.socket"
local pb = require "pb"
local protoc = require "protoc"

require("stringEx")
require("log")

local clients = {}
local CMD = {}

assert(protoc:load [[
   message Phone {
      optional string name        = 1;
      optional int64  phonenumber = 2;
   }
   message Person {
      optional string name     = 1;
      optional int32  age      = 2;
      optional string address  = 3;
      repeated Phone  contacts = 4;
   } ]])


print(_VERSION)

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,   
    unpack = skynet.tostring,   --- 将C point 转换为lua 二进制字符串
}

local function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    print("s:", s)
    if size < s+2 then
        return nil, text
    end
 
    return text:sub(3,2+s), text:sub(3+s)
end

local function decodeMsg(msg)
    --- 前两个字节在netpack.filter 已经解析
    print("msg size:", #msg)
    local proto_name,stringbuffer = string.unpack(">s2s",msg)
    local body = pb.decode(proto_name, stringbuffer)
    return proto_name, body
end

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
            local data, last = unpack_package(readdata)
            local proto_name, body = decodeMsg(data)
            print(fd .. " proto_name " .. proto_name)
            print(fd .. " body " .. GetDumpStr(body))
            --socket.write(fd,readdata)
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

