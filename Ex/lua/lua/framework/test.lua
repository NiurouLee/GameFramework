--region类的实例
---@class TestTask:Object
_class("TestTask", Object)
TestTask = TestTask
local testTaskObj
function TestTask:AsyncLoadGO1(TT, name, loadType)
    LoadAsync(TT, name, loadType)
    --等加载完再执行
    --xxx
    YIELD(TT)
end

function TestTask:AsyncLoadGO2(TT, name, loadType)
    local request = ResourceManager:GetInstance():AsyncLoadAsset(TT, name, loadType)
    local go = request.Obj
    go:SetActive(true)
end

---更新caller访问服务器方式
---详细参考: GameLogic:Init和UILoginController:LoginTask
---@public
function TestTask:UpdateCallers()
    ---获得调用中心
    local callCenter = GameGlobal.GameLogic().CallCenter
    ---添加不同类型调用器(名称唯一，可自定义)
    callCenter:AddCallerLua(NetCallerBulletin, "bulletin")
    callCenter:AddCallerLua(NetCallerGateway, "gateway")
    callCenter:AddCallerLua(NetCallerGame, "game")
    ---获得指定调用器并设置访问服务器方式为通过服务器ip地址直连
    local callerBL = callCenter:GetCallerLua("bulletin")
    callerBL:SetLinkConn(NetAddrInfo:New("127.0.0.1", 1111))
    ---获得指定调用器并设置访问服务器方式为通过服务器token+服务器ip地址直连
    local callerGW = callCenter:GetCallerLua("gateway")
    callerGW:SetLink2Conn(NetAddrInfo:New("127.0.0.1", 2222), NetToken:New(NetTokenType.TOKEN_CLIENT))
    ---获得指定调用器并设置访问服务器方式为通过服务器token+gateway代连
    local callerGM = callCenter:GetCallerLua("game")
    callerGW:SetPipe2Conn(NetToken:New(NetTokenType.TOKEN_GAME, "GM", 1), "gateway")
end

---通过点击按钮异步启动调用任务
---@public
function TestTask:BtnDemoOnClick(go)
    self:StartTask(self.CallDemoTask, self)
end

---通过caller和服务器通信
---详细参考: UILoginController:LoginTask
---@public
function TestTask:CallDemoTask(TT)
    ---获得指定调用器
    local caller = GameGlobal.GameLogic().CallCenter:GetCallerLua("bulletin")
    ---请求并获得响应
    local callInfo = AsyncRequestRes:New()
    local reqMsg = NetMessageFactory:GetInstance():CreateMessage(CEventRequestGetLoginInfo)
    local repInfo = caller:Call(TT, reqMsg)
    ---判断调用是否正常
    if repInfo.res ~= CallResultType.Normal then
        callInfo:SetSucc(false)
        return
    end
    callInfo:SetSucc(true)
    ---按需处理具体响应数据
    local repMsg = repInfo.msg
    callInfo:SetResult(repMsg.ret)
end

require "item_message"
---使用道具
---@private
---@param TT 协程函数标识
---@param res AsyncRequestRes 异步请求结果
---@param param ItemUseParameter 道具使用参数
function TestTask:UseItem(TT, res, param)
    ---@type CEventMobileUseItem
    local request = NetMessageFactory:GetInstance():CreateMessage(CEventMobileUseItem, param)
    local caller = GameGlobal.GameLogic().CallCenter:GetCallerLua("game")
    Log.fatal("1111111111111")
    local reply = caller:Call(TT, request)
    Log.fatal(reply.msg._classname)
    log.fatal(reply.res)
    if reply.res ~= CallResultType.Normal then
        res:SetResult(-1)
        return
    end
    res:SetSucc(true)
    local replyEvent = reply.msg
    res:SetResult(replyEvent.nRet)
end

---根据pstid使用物品
---@public
---@param TT 协程函数标识
---@param res AsyncRequestRes 异步请求结果
---@param item_pstid int
---@param count int
---@param param1 int
---@param param2 int
---@param param3 int
function TestTask:RequestUseItemByPstID(TT, res, item_pstid, count, param1, param2, param3)
    YIELD(TT)
    local itemUseParameter = {
        item_pstid = item_pstid,
        count = count,
        param1 = param1,
        param2 = param2,
        param3 = param3
    }
    self:UseItem(TT, res, itemUseParameter)
end

function TestTask:foo(TT, a, c)
    YIELD(TT)
    c[1] = 2 * a
    YIELD(TT)
    local id2 = TaskManager:GetInstance():StartTask(testTaskObj.f2, testTaskObj, 10)
    self.id2 = id2
    local id3 = TaskManager:GetInstance():StartTask(testTaskObj.f3, testTaskObj, 10)
    _ylw("curTaskId " .. GetCurTaskId())
    _ylw(GetCurTaskId() .. " start join " .. id3)
    -- YIELD(TT)
    JOIN(TT, id3)
    _ylw("f1 foo return from f3")
    return 20, "111"
end

function TestTask:f1(TT, a, b)
    local c = {}
    local num, s1 = self:foo(TT, a + 1, c)
    _ylw("f1 return from f3")
    YIELD(TT)
    _ylw("f1 end")
end

function TestTask:f2(TT, n)
    for i = 1, n do
        _ylw("f2 i ", i)
        YIELD(TT)
    end
    _ylw("f2 end")
end

function TestTask:f3(TT, n)
    for i = 1, n do
        _ylw("f3 i ", i)
        if i == 1 then
            local task = TaskManager:GetInstance():FindTask(testTaskObj.id2)
            if task then
                JOIN(TT, testTaskObj.id2)
                _ylw("f3 return from f2")
            end
        end
        YIELD(TT)
    end
    _ylw("f3 end")
end

testTaskObj = TestTask:New()
--endregion

--region枚举的定义和使用
---@class EnumABC
local EnumABC = {
    A = 1,
    B = 2,
    C = 3
}

_enum("EnumABC", EnumABC)

---@class EnumArray
---@field A int
---@field B int
---@field C int
local EnumArray = {
    "A",
    "B",
    "C"
}

_autoEnum("EnumArray", EnumArray)
--endregion

--region单例的使用，参考GameGlobal
-- GameGlobal:GetInstance():Init()
-- GameGlobal:Dispose()
--endregion

--region资源加载实例

--同步加载资源
-- local request = ResourceManager:GetInstance():SyncLoadAsset("Sphere.prefab", LoadType.GameObject)
-- local go = request.Obj
-- go:SetActive(false)

--同步加载材质球
-- local request = ResourceManager:GetInstance():SyncLoadAsset("DZ_a_301.mat", LoadType.Mat)
-- local mat = request.Obj

--lua协程加载资源
-- TaskManager:GetInstance():StartTask(testTaskObj.AsyncLoadGO2, testTaskObj, "Sphere.prefab", LoadType.GameObject)

--异步加载资源
-- local loader = GroupLoader.New()
-- local request = loader:LoadAsync("Cube.prefab", LoadType.GameObject)
-- loader:OnFinish(function()
-- 	local go = request.Obj
--     go:SetActive(false)
--     loader:Dispose()
-- end)

--lua协程加载资源
-- TaskManager:GetInstance():StartTask(testTaskObj.AsyncLoadGO1, testTaskObj, "Sphere.prefab", LoadType.GameObject)

--lua协程请求协议
-- local res = AsyncRequestRes:New()
-- TaskManager:GetInstance():StartTask(testTaskObj.RequestUseItemByPstID, testTaskObj, res, 1001, 1, 0, 0, 0)
--同步加载资源
-- local loader2 = GroupLoader:New()
-- local request2 = loader2:LoadSync("Cylinder.prefab", LoadType.GameObject)
-- local go2 = request2.Obj
-- go2:SetActive(false)
-- loader2:Dispose()

--得到文件加载绝对路径，通过lua来加载
-- local text = ResourceManager:GetInstance():GetTextAsset("RoleAssetConfig.xml")
-- Log.debug(text)

--endregion
