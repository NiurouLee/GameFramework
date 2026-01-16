--[[------------------------------------------------------------------------------------------
    SyncLogicService 处理同步校验相关的服务对象 
]] --------------------------------------------------------------------------------------------
require "base_service"
---@class SyncLogicService:BaseService
_class("SyncLogicService", BaseService)
SyncLogicService = SyncLogicService

---注册要监听的同步点
function SyncLogicService:Initialize()
    self:OnInitialize()
end

---服务端、客户端重写此初始化方法，建立自己的数据
function SyncLogicService:OnInitialize()
end

function SyncLogicService:DoBattleSync()
    if not _G.ENABLE_SYNC_LOG then
        return
    end
    self:ServerSendSyncCommand()
    self:ClientCheckBattleSync()
end

---下发同步命令，服务端会重写这个方法
function SyncLogicService:ServerSendSyncCommand()
end

---校验本地数据，客户端会重写这个方法
function SyncLogicService:ClientCheckBattleSync()
end
