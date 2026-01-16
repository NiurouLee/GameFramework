--[[
    根据技能的击杀的怪物增加传说能量 
]]
require "buff_logic_base"
_class("BuffLogicAddLegendPowerByMonsterDead", BuffLogicBase)
---@class BuffLogicAddLegendPowerByMonsterDead:BuffLogicBase
BuffLogicAddLegendPowerByMonsterDead = BuffLogicAddLegendPowerByMonsterDead

function BuffLogicAddLegendPowerByMonsterDead:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
end

---@param notify NotifyAttackBase
function BuffLogicAddLegendPowerByMonsterDead:DoLogic(notify)
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

    --增加
    local petPstIDComponent = casterEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    ---@type AttributesComponent
    local curAttributeCmpt = casterEntity:Attributes()
    local curLegendPower = curAttributeCmpt:GetAttribute("LegendPower")

    local newPower = curLegendPower + (self._addValue * addLayer)
    if newPower < 0 then
        newPower = 0
    end

    local ready = false

    local activeSkillID = casterEntity:SkillInfo():GetActiveSkillID()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")

    local requireNTPowerReady = false
    if newPower >= skillConfigData:GetSkillTriggerParam() then
        blsvc:ChangePetActiveSkillReady(casterEntity, 1)
        ready = true

        local notify = NTPowerReady:New(casterEntity)
        self._world:GetService("Trigger"):Notify(notify)
        requireNTPowerReady = true
    else
        blsvc:ChangePetActiveSkillReady(casterEntity, 0)
        ready = false
    end
    if newPower > BattleConst.LegendPowerMax then
        newPower = BattleConst.LegendPowerMax
    end
    curAttributeCmpt:Modify("LegendPower", newPower)

    local buffResult = BuffResultAddLegendPowerByMonsterDead:New(petPstID, newPower, ready)
    if requireNTPowerReady then
        buffResult:RequireNTPowerReady(casterEntity:GetID())
    end

    return buffResult
end
