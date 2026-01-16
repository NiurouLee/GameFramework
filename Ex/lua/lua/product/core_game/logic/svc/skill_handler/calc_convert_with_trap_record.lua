--[[
    ConvertWithTrapRecord = 112, --使用机关记录的颜色转色，不通知buff转色
]]
---@class SkillEffectCalc_ConvertWithTrapRecord: Object
_class("SkillEffectCalc_ConvertWithTrapRecord", Object)
SkillEffectCalc_ConvertWithTrapRecord = SkillEffectCalc_ConvertWithTrapRecord

function SkillEffectCalc_ConvertWithTrapRecord:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ConvertWithTrapRecord:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    if not casterEntity then
        return
    end
    ---@type TrapComponent
    local trapCmpt = casterEntity:Trap()
    if not trapCmpt then
        return
    end

    local pos = casterEntity:GridLocation().Position

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    if boardServiceLogic:IsPosBlock(pos, BlockFlag.ChangeElement) then
        return
    end

    local color = trapCmpt:GetRecordPieceType()

    local skillConvertEffectResult = SkillConvertGridElementEffectResult:New({pos}, color)
    skillConvertEffectResult:SetNotifyBuff(false)
    return skillConvertEffectResult
end
