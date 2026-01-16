---@class UIWorldBossRedPoint:Object
_class("UIWorldBossRedPoint", Object)
UIWorldBossRedPoint = UIWorldBossRedPoint

function UIWorldBossRedPoint:Constructor()
    self._worldBossModule = GameGlobal.GetModule(WorldBossModule)
    self._loginModule = GameGlobal.GetModule(LoginModule)
    self._roleModule = GameGlobal.GetModule(RoleModule)
end

function UIWorldBossRedPoint:MainLobbyHaveRedPoint()
    return self:_ModuleUnLock() and self:_OpenRecord() <= 0
end
--解锁
function UIWorldBossRedPoint:_ModuleUnLock()
    return self._roleModule:CheckModuleUnlock(GameModuleID.MD_WorldBoss)
end
--打开记录
function UIWorldBossRedPoint:_OpenRecord()
    return LocalDB.GetInt("UIWorldBossControllerOpenRecord"..self._loginModule:GetRoleShowID(), 0)
end