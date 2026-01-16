--[[
    舒默尔狂暴后的特殊击退效果：计算目标向4方向击退到版边位置，选择与自己核心位置最远的点造成击退
]]

require("calc_base")

_class("SkillEffectCalc_SchummerHitback", SkillEffectCalc_Base)
---@class SkillEffectCalc_SchummerHitback : SkillEffectCalc_Base
SkillEffectCalc_SchummerHitback = SkillEffectCalc_SchummerHitback

SkillEffectCalc_SchummerHitback.Directions = {
    Vector2.up, Vector2.down, Vector2.left, Vector2.right
}

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SchummerHitback:CalculateOnSingleTarget(skillEffectCalcParam, targetID)
    local entity = self._world:GetEntityByID(targetID)
    local pos = entity:GetGridPosition()
    local distance = 9 -- 退到版边
    local exceptPosList = nil -- 不考虑例外位置
    local ignorePlayerBlock = false

    local idCaster = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local eCaster = self._world:GetEntityByID(idCaster)
    ---@type Vector2
    local v2CasterPos = eCaster:GetGridPosition()

    local v2FinalDir = Vector2.zero
    local v2FinalPos = Vector2.zero
    local distanceHitback = 0
    for _, v2Dir in ipairs(SkillEffectCalc_SchummerHitback.Directions) do
        local v2Pos = self._skillEffectService:CalHitbackPosByEntityDir(
            pos,
            entity:BodyArea(),
            v2Dir,
            distance,
            exceptPosList,
            ignorePlayerBlock,
            entity
        )

        local dis = Vector2.Distance(v2CasterPos, v2Pos)
        if dis > distanceHitback then
            v2FinalDir = v2Dir
            v2FinalPos = v2Pos
            distanceHitback = dis
        end
    end

    if v2FinalPos == Vector2.zero then
        return
    end

    local hitbackDirType = nil
    if v2FinalDir == Vector2.up then
        hitbackDirType = HitBackDirectionType.Up
    elseif v2FinalDir == Vector2.right then
        hitbackDirType = HitBackDirectionType.Right
    elseif v2FinalDir == Vector2.down then
        hitbackDirType = HitBackDirectionType.Down
    elseif v2FinalDir == Vector2.left then
        hitbackDirType = HitBackDirectionType.Left
    end
    ---@type Vector2[]
    local skillRange = skillEffectCalcParam.skillRange
    return self._skillEffectService:CalcHitbackEffectResult(
        eCaster:GetGridPosition(),
        eCaster:GetGridDirection(),
        eCaster:BodyArea():GetArea(),
        targetID,
        hitbackDirType,
        HitBackType.PushAway,
        distance,
        HitBackCalcType.Instant,
        ignorePlayerBlock,
        false,
        eCaster,
        skillRange,nil,nil,nil,nil,skillEffectCalcParam:GetSkillEffectParam():GetSkillType()
    )
end
