require("base_ins_r")
---@class PlayForceMovementInstruction: BaseInstruction
_class("PlayForceMovementInstruction", BaseInstruction)
PlayForceMovementInstruction = PlayForceMovementInstruction

function PlayForceMovementInstruction:Constructor(paramList)
    self.speed = paramList.speed
    self.fxID = tonumber(paramList.effectID)
    self.setEffectDirByPath = tonumber(paramList.setEffectDirByPath)
    self.effectOutAnim = paramList.effectOutAnim
end

function PlayForceMovementInstruction:GetCacheResource()
    local t = {}
    if self.fxID and self.fxID > 0 then
        table.insert(t, {Cfg.cfg_effect[self.fxID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayForceMovementInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_ForceMovement
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.ForceMovement)
    if not result then
        return
    end

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")

    local speed = self.speed
    local moveResults = result:GetMoveResult()
    local tMoveTaskID = {}
    local effEntity = nil
    for _, moveResult in ipairs(moveResults) do
        local e = self._world:GetEntityByID(moveResult.targetID)
        if moveResult.isMoved and e then
            -- e:SetDirection()
            e:AddGridMove(speed, moveResult.v2NewPos, moveResult.v2OldPos)
            if self.fxID then
                effEntity = effectService:CreateEffect(self.fxID, e)
                if self.setEffectDirByPath and (self.setEffectDirByPath == 1) then
                    YIELD(TT)
                    local effDir = moveResult.v2NewPos - moveResult.v2OldPos
                    effEntity:SetDirection(effDir)
                end
            end

            local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._CheckMoveFinish, self, e)
            table.insert(tMoveTaskID, taskID)

            playBuffService:PlayBuffView(TT, NTForceMovement:New(e, moveResult.v2OldPos, moveResult.v2NewPos))
        end
    end

    while (not TaskHelper:GetInstance():IsAllTaskFinished(tMoveTaskID)) do
        YIELD(TT)
    end
    if effEntity and self.effectOutAnim then
        if effEntity:View() then
            local anim = effEntity:View():GetGameObject():GetComponent("Animation")
            if anim then
                anim:Play(self.effectOutAnim)
            end
        end
    end
    -- 触发型机关的触发
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    for _, info in ipairs(moveResults) do
        local entity = self._world:GetEntityByID(info.targetID)
        if entity and (info.v2NewPos ~= info.v2OldPos) then -- 没能移动的目标不会重复触发机关
            local listTrapTrigger = info.triggeredTrapIDs
            local array = {}
            for _, id in ipairs(listTrapTrigger) do
                local e = self._world:GetEntityByID(id)
                if e then
                    table.insert(array, e)
                end
            end
            trapServiceRender:PlayTrapTriggerSkillTasks(TT, array, false, entity)
        end
    end
end

function PlayForceMovementInstruction:_CheckMoveFinish(TT, entity)
    while (entity:HasGridMove()) do
        YIELD(TT)
    end
end
