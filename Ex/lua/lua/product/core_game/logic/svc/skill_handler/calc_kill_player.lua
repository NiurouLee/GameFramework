--[[
    KillPlayer 祭剑座特殊技能（怪）
]]

_class("SkillEffectCalc_KillPlayer", Object)
---@class SkillEffectCalc_KillPlayer: Object
SkillEffectCalc_KillPlayer = SkillEffectCalc_KillPlayer

function SkillEffectCalc_KillPlayer:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_KillPlayer:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Vector2[]
    local range =  skillEffectCalcParam.skillRange
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type Vector2
    local gridPos = teamEntity:GetGridPosition()
    if table.Vector2Include(range,gridPos) then
        ---@type AttributesComponent
        local attributeCmpt = teamEntity:Attributes()
        attributeCmpt:Modify("HP",0)
        teamEntity:AddTeamDeadMark()
    end
end