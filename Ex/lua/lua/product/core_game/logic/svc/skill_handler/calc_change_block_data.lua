--[[
    贴纸技能，在深渊上保存/还原阻挡信息
]]
---@class SkillEffectCalc_ChangeBlockData: Object
_class("SkillEffectCalc_ChangeBlockData", Object)
SkillEffectCalc_ChangeBlockData = SkillEffectCalc_ChangeBlockData

function SkillEffectCalc_ChangeBlockData:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ChangeBlockData:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillChangeBlockDataParam
    local skillParam = skillEffectCalcParam.skillEffectParam
    local change = skillParam:GetChangeType()
    local centerPos = skillEffectCalcParam.centerPos
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    ---@type PieceBlockData
    local blockData = boardCmpt:FindBlockByPos(centerPos)

    local es = boardCmpt:GetPieceEntities(centerPos,function(e)
        return e:Trap() and e:Trap():GetTrapType() == TrapType.TerrainAbyss 
    end)

    if #es == 0 then
        return SkillEffectResultChangeBlockData:New(false, change)
    end
    local e = es[1]
    if change == 'push' then
        blockData:AddBlock(e:GetID(),0) --深渊的阻挡置为0
    elseif change=='pop' then
        blockData:AddBlock(e:GetID(),e:BlockFlag():GetBlockFlag()) --还原深渊的阻挡
    end

    return SkillEffectResultChangeBlockData:New(true, change)
end
