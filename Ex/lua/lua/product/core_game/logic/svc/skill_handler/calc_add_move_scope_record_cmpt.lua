--[[
    AddMoveScopeRecordCmpt = 192, --仲胥 给点选位置的机关/怪增加记录移动范围的组件，并记录点选位置对机关/怪中心位置的偏移
]]
_class("SkillEffectCalc_AddMoveScopeRecordCmpt", Object)
---@class SkillEffectCalc_AddMoveScopeRecordCmpt: Object
SkillEffectCalc_AddMoveScopeRecordCmpt = SkillEffectCalc_AddMoveScopeRecordCmpt

function SkillEffectCalc_AddMoveScopeRecordCmpt:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddMoveScopeRecordCmpt:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_AddMoveScopeRecordCmpt
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---@type BattleStatComponent
    local battleCmpt = self._world:BattleStat()

    

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    local results = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local centerPos = skillEffectCalcParam:GetCenterPos()
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for _, targetID in ipairs(targets) do
        ---@type Entity
        local e = self._world:GetEntityByID(targetID)
        if e then
            local entityCenterPos = e:GetGridPosition()
            local offSet = Vector2(centerPos.x - entityCenterPos.x,centerPos.y - entityCenterPos.y)
            
            ---@type SkillEffectResultAddMoveScopeRecordCmpt
            local result = SkillEffectResultAddMoveScopeRecordCmpt:New(targetID,offSet)
            table.insert(results,result)
        end
    end
    return results
end
