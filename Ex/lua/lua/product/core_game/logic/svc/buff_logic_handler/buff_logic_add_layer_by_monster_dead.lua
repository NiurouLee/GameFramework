--[[
    根据技能的击杀的怪物叠加层数 
]]
require "buff_logic_base"
_class("BuffLogicAddLayerByMonsterDead", BuffLogicBase)
---@class BuffLogicAddLayerByMonsterDead:BuffLogicBase
BuffLogicAddLayerByMonsterDead = BuffLogicAddLayerByMonsterDead

function BuffLogicAddLayerByMonsterDead:Constructor(buffInstance, logicParam)
    -- self._layer = logicParam.layer
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._buffInstance._buffLayerName = self._buffInstance._buffsvc:GetBuffLayerName(self._layerType)
    self._dontDisplay = logicParam.dontDisplay
end

---@param notify NotifyAttackBase
function BuffLogicAddLayerByMonsterDead:DoLogic(notify)
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")

    local addLayer = 0

    -- local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    -- for i, e in ipairs(monsterGroup:GetEntities()) do
    --     --这里还没有加上死亡标记
    --     -- if e:HasDeadMark() then
    --     if e:Attributes():GetAttribute("HP") == 0 then
    --         addLayer = addLayer + 1
    --     end
    -- end

    local casterEntity = notify:GetAttackerEntity()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    ---伤害索引无效，可以返回/ 拾取点释放带有多段伤害的技能
    if not damageResultArray or #damageResultArray == 0 then
        return
    end
    local targetEntityList = {}
    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetEntityID)
        --技能没有造成伤害 也会返回一个 targetID -1 的技能结果
        if targetEntity and targetEntity:HasMonsterID() and not table.intable(targetEntityList, targetEntity) then
            table.insert(targetEntityList, targetEntity)
        end
    end
    for _, entity in ipairs(targetEntityList) do
        --这里还没有加上死亡标记
        -- if e:HasDeadMark() then
        if entity:Attributes():GetCurrentHP() == 0 then
            addLayer = addLayer + 1
        end
    end

    if addLayer == 0 then
        return
    end

    local curMarkLayer = svc:AddBuffLayer(self._entity, self._layerType, addLayer)
    local buffResult = BuffResultAddLayer:New(curMarkLayer, self._dontDisplay)

    return buffResult
end
