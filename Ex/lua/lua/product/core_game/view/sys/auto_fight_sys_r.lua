---@class AutoFightSystem_Render:Object
_class("AutoFightSystem_Render", Object)
AutoFightSystem_Render = AutoFightSystem_Render

---@param world MainWorld
function AutoFightSystem_Render:Constructor(world)
    self._world = world
    ---@type AutoFightService
    self.svc = self._world:GetService("AutoFight")
end
---每帧检测尝试执行一次自动战斗逻辑
function AutoFightSystem_Render:Execute()
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    if not utilStatSvc:GetStatAutoFight() then--UI点击Auto后，切换至自动战斗状态
        return
    end

    local isWaitInputState = self:_IsWaitInputState()
    if not isWaitInputState then--在waitInput状态下执行
        return
    end

    if self.svc:IsRunning() then--正在执行自动战斗逻辑则返回
        return
    end

    local teamEntity = self._world:Player():GetCurrentTeamEntity()--当前队伍，黑拳赛时可以是敌方队伍
    GameGlobal.TaskManager():CoreGameStartTask(self.svc.AutoFight, self.svc, teamEntity)
end

function AutoFightSystem_Render:_IsWaitInputState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()
    if gameFsmStateID == GameStateID.PickUpChainSkillTarget then
        return true --处理主动技跳到传送旋涡图中开自动的情况
    end
    return utilDataSvc:GetMainStateInputEnable()
end
