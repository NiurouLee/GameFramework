--[[
    队伍每损失5%血量，设置1层
]]
--设置技能伤害加成
_class("BuffLogicSetLayerByTeamHpLose", BuffLogicBase)
---@class BuffLogicSetLayerByTeamHpLose:BuffLogicBase
BuffLogicSetLayerByTeamHpLose = BuffLogicSetLayerByTeamHpLose

function BuffLogicSetLayerByTeamHpLose:Constructor(buffInstance, logicParam)
    self._eachTeamHpLose = logicParam.eachTeamHpLose --每x%队伍损失血量
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._entity = buffInstance._entity
end

function BuffLogicSetLayerByTeamHpLose:DoLogic()
    local teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    ---@type CalcDamageService
    local calcDamageService = self._world:GetService("CalcDamage")
    local curHp, maxHp = calcDamageService:GetTeamLogicHP(teamEntity)

    local losePercent = 1 - (curHp / maxHp)
    local layerCount = math.floor(losePercent / self._eachTeamHpLose)

    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    svc:SetBuffLayer(self._entity, self._layerType, layerCount)
    local buffResult = BuffResultAddLayer:New(layerCount)
    return buffResult
end
