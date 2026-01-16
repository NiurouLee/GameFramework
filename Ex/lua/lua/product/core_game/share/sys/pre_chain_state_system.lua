--[[------------------------------------------------------------------------------------------
    主状态机：连锁前阶段处理system
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class PreChainStateSystem:MainStateSystem
_class("PreChainStateSystem", MainStateSystem)
PreChainStateSystem = PreChainStateSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PreChainStateSystem:_GetMainStateID()
    return GameStateID.PreChain
end

---@param TT token 协程识别码，服务端是nil
function PreChainStateSystem:_OnMainStateEnter(TT)
   local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---保存施法者位置
    local posCasterOld = teamEntity:GetGridPosition()

    local trapIds = self:_DoLogicPreChainTrapSkill()
    self:_PlayPreChainTrapSkill(TT, trapIds)

    local listTrapTrigger = self:_DoLogicWaitTeleportFinish(posCasterOld,teamEntity)

    self:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity) ---表现  等待主动技瞬移完成  检查触发机关

    self:_DoLogicResetPickUp(teamEntity)

    self:_DoRenderResetPickUp()

    self:_DoLogicPreChainFinish()
end

---------------------------------逻辑接口---------------------------
function PreChainStateSystem:_DoLogicPreChainTrapSkill()
    ---@type TrapServiceLogic
    local sTrapLogic = self._world:GetService("TrapLogic")
    local trapIds = sTrapLogic:CalcTrapPreChainSkill()
    return trapIds
end

function PreChainStateSystem:_DoLogicPreChainFinish()
    local flag = self._world:BattleStat():GetTriggerDimensionFlag()
    local nextId = 1
    if flag == TriggerDimensionFlag.WaitInput then
        nextId = 2
    elseif flag == TriggerDimensionFlag.RoundResult then
        nextId = 3
    end
    self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.None) --重置任意门触发阶段标记
    self._world:EventDispatcher():Dispatch(GameEventType.PreChainFinish, nextId)
end

function PreChainStateSystem:_DoLogicResetPickUp(teamEntity)
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    logicPickUpCmpt:ResetLogicPickUp()
end


---@return Entity[]
function PreChainStateSystem:_DoLogicWaitTeleportFinish(posCasterOld, teamEntity)
    local posCasterNew = teamEntity:GetGridPosition()
    local bHaveTeleport = posCasterNew ~= posCasterOld
    local listTrapTrigger = nil
    if bHaveTeleport then
        ---@type TrapServiceLogic
        local sTrapLogic = self._world:GetService("TrapLogic")
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")

        listTrapTrigger = sTrapLogic:TriggerTrapByTeleport(teamEntity, true) --宝宝瞬移触发机关时只传队伍实体
    end
    return listTrapTrigger
end

---------------------------------表现接口---------------------------
function PreChainStateSystem:_PlayPreChainTrapSkill(TT, trapIds)
end

function PreChainStateSystem:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity)
end

function PreChainStateSystem:_DoRenderResetPickUp()
end