require("calc_base")

---@class SkillEffectCalc_MultiplyBuffLayer: SkillEffectCalc_Base
_class("SkillEffectCalc_MultiplyBuffLayer", SkillEffectCalc_Base)
SkillEffectCalc_MultiplyBuffLayer = SkillEffectCalc_MultiplyBuffLayer

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetID number
function SkillEffectCalc_MultiplyBuffLayer:CalculateOnSingleTarget(skillEffectCalcParam, targetID)
    if targetID == -1 then
        return
    end

    ---@type Entity
    local eTarget = self._world:GetEntityByID(targetID)

    ---@type SkillEffectParam_MultiplyBuffLayer
    local param = skillEffectCalcParam:GetSkillEffectParam()

    --身上没有目标buff就不继续了
    --btw其实计算过程和这个buffInstance没什么关系，拿到它是为了把BuffSeq传过去，找到对应的buffViewInstance
    local buffInstance = self:GetBuffInstanceByParam(param, eTarget)
    if not buffInstance then
        return
    end
    local buffEffectType = buffInstance:GetBuffEffectType()
    local buffSeq = buffInstance:BuffSeq()

    ---@type BuffLogicService
    local lsvcBuff = self._world:GetService("BuffLogic")
    local baseVal = lsvcBuff:GetBuffLayer(eTarget, buffEffectType)
    local val = math.floor(baseVal * param:GetMultiplier())

    return SkillEffectResult_MultiplyBuffLayer:New(targetID, buffEffectType, val, buffSeq)
end

---@param param SkillEffectParam_MultiplyBuffLayer
---@param eTarget Entity
function SkillEffectCalc_MultiplyBuffLayer:GetBuffInstanceByParam(param, eTarget)
    local cBuff = eTarget:BuffComponent()
    if not cBuff then
        return nil
    end

    if param:GetLayerBuffID() then
        local buffID = param:GetLayerBuffID()
        return cBuff:GetBuffById(buffID)
    elseif param:GetLayerBuffEffectType() then
        local buffEffectType = param:GetLayerBuffEffectType()
        return cBuff:GetSingleBuffByBuffEffect(buffEffectType)
    end
end
