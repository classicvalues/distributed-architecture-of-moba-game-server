local config = require("GameConfig");
local CmdType = require("gateway/const/CmdType");
local ServiceType = require("ServiceType");
local Responce = require("Respones");

-- stype -> session 映射表
local sessionDic={}
-- 当前正在链接的服务器
local connectingSession={};
local g_ukey=1;
local tag_sessionDic={};
local uid_sessionDic={};

--连接到指定服务器
local function ConnectToServer(stype,ip,port)
	Netbus.TcpConnect(ip,port,
		--链接成功的回调
		function(session)
			connectingSession[stype]=false;
			if not session then
				Debug.LogError("connect to server ["..config.servers[stype].descrip.."]"..ip..port.." failed, reconnecting...");
				return;
			end
			--链接成功
			print("connect to server ["..config.servers[stype].descrip.."]"..ip..port.." success");
			sessionDic[stype]=session;
		end)
end

--检查服务器的链接
local function CheckServerConnect()
	-- 检查服务的链接，每秒进行一次
	for k,v in pairs(config.servers) do
		if sessionDic[v.serviceType]==nil
			and connectingSession[v.serviceType]==false
			then
			--如果没有链接，就链接服务器
			connectingSession[v.serviceType]=true;
			ConnectToServer(v.serviceType,v.ip,v.port);
		end
	end
end

--初始化网关服务器
local function GatewayServiceInit()
	for k,v in pairs(config.servers) do
		sessionDic[v.serviceType]=nil;
		connectingSession[v.serviceType]=false;
	end
	--启动一个定时器
	Timer.Repeat(CheckServerConnect,1000,-1,5000);
end

--是否为登陆返回消息
local function _IsLoginAuthRes(stype, ctype )
	if stype ~= ServiceType.Auth then
		return false;
	end

    if CmdType.UserLoginRes == ctype or CmdType.UserRegisteRes == ctype then
        return true;
    end
    return false;
end

--是否为登陆请求
local function _IsLoginAuthReq(stype, ctype )
	if stype ~= ServiceType.Auth then
		return false;
	end
    if CmdType.UserLoginReq == ctype or CmdType.UserRegisteReq == ctype then
        return true;
    end
    return false;
end

--是否为登陆逻辑服务器的请求
local function _IsLoginLogicReq(stype, ctype)
	return stype ==ServiceType.Logic and ctype == CmdType.LoginLogicReq;
end

-- 发给客户端
local function _server_send_to_client(s,raw)

	local stype,ctype,utag = RawCmd.ReadHeader(raw);

	--print("from server tag: ",utag);
	local clientSession = nil;
	--如果是登陆命令的回复
	if _IsLoginAuthRes(stype, ctype) then


		--取消tag_sessionDIc中的引用
		clientSession=tag_sessionDic[utag];
		tag_sessionDic[utag]=nil;

		if clientSession==nil then
			Debug.LogWarning("clientSession is null, uTag:", utag);
			return;
		end

		local body = RawCmd.ReadBody(raw);

		if config.enable_gateway_log then
			Debug.Log("s-c:LoginAuthRes "..body.status);
		end

		--如果返回结果不正常，直接返回
		if body.status~=Responce.Ok then
			Debug.LogWarning("Responce is not ok",body.status);
			RawCmd.SetUTag(raw,0);
			Session.SendRawPackage(clientSession,raw);
			return;
		end

		local uid = body.uinfo.uid;

		--判断是否有session已经用这个id登陆
		if uid_sessionDic[uid] and uid_sessionDic[uid]~=clientSession then
			--说明重复登陆
			Debug.LogWarning("somebody relogin");
			local reloginMsg = {ServiceType.Auth,CmdType.ReLogin,0,nil};
			Session.SendPackage(uid_sessionDic[uid],reloginMsg);
			Session.Close(uid_sessionDic[uid]);
			-- uid_sessionDic[uid]=nil;
		end



		--记录uid
		--print("remember uid: ",uid);
		uid_sessionDic[uid]=clientSession;
		Session.SetUId(clientSession,uid);

		--发送回客户端
		--print("send back to client");
		body.uinfo.uid=0;
		local loginRes={stype,ctype,0,body};
		Session.SendPackage(clientSession,loginRes);
		return;
	else
		if config.enable_gateway_log then
			Debug.Log("S->C["..utag.."] ["..stype..":"..ctype.."]");
		end
	end

	--print("BBB");
	clientSession=uid_sessionDic[utag];


	--发给用户
	if clientSession then
		--print("flag");
		--永远不要让用户知道utag
		RawCmd.SetUTag(raw,0);
		Session.SendRawPackage(clientSession,raw);

		--如果是注销消息
		if stype==ServiceType.Auth and ctype==CmdType.UserUnregisterRes then
			Session.SetUId(clientSession,0);
			uid_sessionDic[utag]=nil;
		end
	else
		print("clientSession is null? utag: ",utag);
	end
end

-- 发给服务器
local function _client_send_to_server(s,raw)

	local stype,ctype,utag = RawCmd.ReadHeader(raw);
	local targetServerSession = sessionDic[stype];
	if nil==targetServerSession then
		print("server is null, stype:"..stype);
		return;
	end

	if _IsLoginAuthReq(stype,ctype) then
		--如果是登陆用户服务器请求
		utag = Session.GetUTag(s);
		if utag==0 then
			--用户第一次登陆
			utag=g_ukey;
			g_ukey=g_ukey+1;
			Session.SetUTag(s,utag);
		end
		tag_sessionDic[utag]=s;


		if config.enable_gateway_log then
			Debug.Log("c-s:LoginAuthReq "..utag);
		end

		--print("get utag: ",utag);
	elseif _IsLoginLogicReq(stype,ctype) then
		--如果是登陆逻辑服务器请求
		utag = Session.GetUId(s);
		if uid==0 then
			--该操作需要先登陆
			Debug.LogError("you need to login first");
			return;
		end

		if config.enable_gateway_log then
			Debug.Log("c-s:LoginLoginReq");
		end
	else
		utag = Session.GetUId(s);
		if utag==0 then
			--该操作需要先登陆
			Debug.LogWarning("you need to login first");
			return;
		end
		--uid_sessionDic[uid]=s;
		if config.enable_gateway_log then
			Debug.Log("c-s:Normal ["..stype.."-"..ctype.."]");
		end
	end

	--打上utag然后发给我们的服务器
	--print("client tag: "..utag.." send to server")
	RawCmd.SetUTag(raw,utag);
	Session.SendRawPackage(targetServerSession,raw);
end

GatewayServiceInit();

return   {
    OnSessionRecvRaw=function(s,raw)
    	if Session.IsClient(s) then
    		_server_send_to_client(s,raw);
    	else
		    _client_send_to_server(s,raw);
    	end
    end,
    OnSessionDisconnected=function(s,stype)
		if Session.IsClient(s) then
			--和其他服务器的连接断开
    		for k,v in pairs(sessionDic) do
    			if v==s then
    				Debug.LogError("disconnected from: ["..config.servers[k].descrip.."]");
    				sessionDic[k]=nil;
    			end
    		end
    		return;
    	else
    		--和玩家断开

            local ip,port = Session.GetAddress(s);
            print("client ["..ip..":"..port.."] leave");

    		--1.把客户端从utag临时映射表删除，只有发起登录请求但是没有收到回复的会走这个逻辑
    		local utag = Session.GetUTag(s);
    		if tag_sessionDic[utag] and tag_sessionDic[utag]==s then
    			tag_sessionDic[utag]=nil;
    			Session.SetUTag(s,0);
    		end
            --2.把客户端从uid映射表删除，已经登陆了的短线请求会走这里
    		local uid = Session.GetUId(s);
    		if uid_sessionDic[uid] and uid_sessionDic[uid]==s then
    			uid_sessionDic[uid]=nil;
                --这里不能把用户uid值为零，用户注册的每个服务都会走这段代码
                --如果第一次我们就把uid置为零，后面走这段代码的服务器就不知道
                --是哪个用户掉线了
    			--Session.SetUId(s,0);
    			--table.remove(uid_sessionDic,uid);
    		end

            local targetServer = sessionDic[stype];
			if nil==targetServer then
				Debug.LogError("Unexpeced stype:"..stype);
                return;
            end

            --客户端uid用户掉线，我要把这个事件告诉中转服务器
            if uid~=0 then
                local userLostMsg = {stype,CmdType.UserLostConn,uid,nil};
                Session.SendPackage(targetServer,userLostMsg);
            end
    	end
    end,
};