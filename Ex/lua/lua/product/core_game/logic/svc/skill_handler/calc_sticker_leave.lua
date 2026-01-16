--[[
    109 贴纸离开格子转色处理，深渊上的格子转灰色，普通格子支持配转色
]]
---@class SkillEffectCalc_StickerLeave: Object
_class("SkillEffectCalc_StickerLeave", Object)
SkillEffectCalc_StickerLeave = SkillEffectCalc_StickerLeave

function SkillEffectCalc_StickerLeave:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_StickerLeave:DoSkillEffectCalculator(skillEffectCalcParam)
    local pos = skillEffectCalcParam.attackPos
    local sep = skillEffectCalcParam.skillEffectParam
    local convertColor = sep:GetConvertColor()
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es =
        boardCmpt:GetPieceEntities(
        pos,
        function(e)
            return e:Trap() and e:Trap():GetTrapType() == TrapType.TerrainAbyss
        end
    )
    local range = {}
    local color = boardCmpt:GetPieceType(pos)
    local onAbyss = #es > 0
    if onAbyss then
        range[#range + 1] = pos
        color = PieceType.None
    elseif convertColor and convertColor > PieceType.None and convertColor <= PieceType.Any then
        local boardServiceLogic=self._world:GetService("BoardLogic")
        local canConverPos = boardServiceLogic:GetCanConvertGridElement(pos)
        if canConverPos then
            range[#range + 1] = pos
            color = convertColor
        end
    end
    local skillConvertEffectResult = SkillConvertGridElementEffectResult:New(range, color)
    return skillConvertEffectResult
end
