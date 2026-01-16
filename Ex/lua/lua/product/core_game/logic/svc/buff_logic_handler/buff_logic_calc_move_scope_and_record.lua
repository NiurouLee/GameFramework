--[[
    仲胥 怪、机关移动后 记录移动范围用于转色
]]
_class("BuffLogicCalcMoveScopeAndRecord", BuffLogicBase)
---@class BuffLogicCalcMoveScopeAndRecord:BuffLogicBase
BuffLogicCalcMoveScopeAndRecord = BuffLogicCalcMoveScopeAndRecord

function BuffLogicCalcMoveScopeAndRecord:Constructor(buffInstance, logicParam)
end

function BuffLogicCalcMoveScopeAndRecord:DoLogic(notify)
    ---@type Entity
    local e = self._buffInstance:Entity()
    local moveScopeRecordCmpt = e:MoveScopeRecord()
    if not moveScopeRecordCmpt then
        Log.debug("BuffLogicCalcMoveScopeAndRecord no moveScopeRecord cmpt , entity=", e:GetID())
        return
    end
    if notify:GetNotifyType() ~= NotifyType.EntityMoveEnd then
        return
    end
    ---@type NTEntityMoveEnd
    local moveEndNotify = notify
    local parentNotifyType = moveEndNotify:GetParentNotifyType()
    local moveScope = {}
    local posOld = moveEndNotify:GetPosOld()
    local posNew = moveEndNotify:GetPosNew()
    local offSet = moveScopeRecordCmpt:GetMoveOffSet()
    local posOldWithOffSet = posOld + offSet
    local posNewWithOffSet = posNew + offSet
    if parentNotifyType == NotifyType.HitBackEnd
        or parentNotifyType == NotifyType.TractionEnd
        or parentNotifyType == NotifyType.ForceMovement
    then
        --计算路径 万向直线
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---@type SkillScopeCalculator
        local scopeCalculator = SkillScopeCalculator:New(utilScopeSvc)
        ---@type SkillScopeCalculator_AngleFreeLine
        local scopeAngleFreeLine = SkillScopeCalculator_AngleFreeLine:New(scopeCalculator)
        ---@type Vector2[]
        local attackRange = {}
        ---@type Vector2[]
        local wholeRange = {}
        
        local fakeBodyArea = {Vector2(0,0)}
        ---@type SkillScopeResult
        local scopeResult = scopeAngleFreeLine:CalcRange(
            nil,
            {
                noExtend = 1,
                --widthThreshold = widthThreshold,
            },
            posNewWithOffSet,fakeBodyArea,nil,nil,posOldWithOffSet)
        table.Vector2Append(attackRange,scopeResult:GetAttackRange())
        --table.Vector2Append(wholeRange,scopeResult:GetWholeGridRange())
        moveScope = attackRange
    else
        table.insert(moveScope,posOldWithOffSet)
        table.insert(moveScope,posNewWithOffSet)
    end
    Log.debug("BuffLogicCalcMoveScopeAndRecord moveScope count =", #moveScope )

    moveScopeRecordCmpt:RecordMoveScope(moveScope)
end
