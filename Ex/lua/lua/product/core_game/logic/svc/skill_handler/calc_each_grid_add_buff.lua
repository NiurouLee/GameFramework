--[[
    EachGridAddBuff = 18, ---每个格子产生buff
]]
---@class SkillEffectCalc_EachGridAddBuff: Object
_class("SkillEffectCalc_EachGridAddBuff", Object)
SkillEffectCalc_EachGridAddBuff = SkillEffectCalc_EachGridAddBuff

function SkillEffectCalc_EachGridAddBuff:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EachGridAddBuff:DoSkillEffectCalculator(skillEffectCalcParam)
    --local t1=os.clock()
    local layerCount =0
    local targetPieces = skillEffectCalcParam.skillEffectParam:GetPieceTypes()
    for _, pos in ipairs(skillEffectCalcParam.skillRange) do
        if targetPieces then
            local isMatch = self._skillEffectService:_IsGridElementMatch(pos, targetPieces)
            if isMatch then
                layerCount = layerCount + 1
            end
        else
            layerCount = layerCount + 1
        end
    end
    local result = self:_CalculateAddBuffSinglePosResult(layerCount,skillEffectCalcParam)
    --local t2=os.clock()-t1
    --Log.fatal('SkillEffectCalc_EachGridAddBuff:DoSkillEffectCalculator() use time=',t2)
    return result
end
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EachGridAddBuff:_CalculateAddBuffSinglePosResult(layerCount, skillEffectCalcParam)
    ---@type SkillEffectCalc_AddBuff
    local skillEffectCalc = SkillEffectCalc_AddBuff:New(self._world)
    ---@type SkillAddBuffEffectParam
    local effectParam=  skillEffectCalcParam.skillEffectParam
    effectParam:SetBuffInitLayer(layerCount)
    ---@type SkillBuffEffectResult[]
    local tResults = skillEffectCalc:DoSkillEffectCalculator(skillEffectCalcParam)
    for _, r in ipairs(tResults) do
        local eid = r:GetEntityID()
        local e = self._world:GetEntityByID(eid)
        local newBuffArray = r:GetAddBuffResult()
        local cBuff = e:BuffComponent()
        for _, seq in ipairs(newBuffArray) do
            local inst = cBuff:GetBuffBySeq(seq)
            local layer = inst:GetLayerCount()
            r:SetBuffInitLayer(layer)
        end
    end
    --if #tResults > 0 then
    --    Log.fatal("AddMoreBuff SkillID:",skillEffectCalcParam.skillID)
    --end
    return tResults
end