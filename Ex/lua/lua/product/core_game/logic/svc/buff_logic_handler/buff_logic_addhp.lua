--[[
    按最大生命值百分比、绝对值加血
    2020-12-14 修改为只有加血效果，没有减血效果，减血走DoDamage
]]
_class("BuffLogicAddHP", BuffLogicBase)
---@class BuffLogicAddHP:BuffLogicBase
BuffLogicAddHP = BuffLogicAddHP

function BuffLogicAddHP:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._addValue = logicParam.addValue or 0
    --针对星灵，百分比的类型，1表示是基于队长的百分比，2表示是基于petData的血量的百分比
    self._baseType = logicParam.baseType or 1
    --1表示在秘境中只给单一的星灵加
    self._singlePet = logicParam.singlePet or 0
    self._ignoreForbidCure = logicParam.ignoreForbidCure or 0--无视禁疗 房间词缀用
end

function BuffLogicAddHP:DoLogic(notify)
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()
    local cur_hp = attrCmpt:GetCurrentHP()
    if cur_hp <= 0 then
        return
    end
    if self._entity:PetPstID() then --是星灵
        if self._baseType == 2 then --是基于petdata的血量百分比
            local pstId = self._entity:PetPstID():GetPstID()
            ---@type Pet
            local petData = self._world.BW_WorldInfo:GetPetData(pstId)
            max_hp = petData:GetPetHealth()
        end
    end
    local baseValue = max_hp
    if self._baseType == 3 then --是基于当前已损失的血量
        baseValue = max_hp - cur_hp
    end
    --已经死亡不能加血和减血
    if e:HasDeadMark() or e:HasPetDeadMark() then
        return
    end

    local rate = e:Attributes():GetAttribute("AddBloodRate") or 0
    local add_value = 0
    local damageType = DamageType.Recover
    add_value = baseValue * self._mulValue + self._addValue
    --加血的情况下才使用回血加成系数
    if self._mulValue >= 0 and self._addValue >= 0 then
        add_value = add_value * (1 + rate)
    end
    add_value = math.floor(add_value)

    Log.debug(
        "BuffLogicAddHP add_value=",
        add_value,
        " baseValue=",
        baseValue,
        " mulValue=",
        self._mulValue,
        " AddBloodRate=",
        rate
    )
    if add_value >= 0 then
        self._world:GetMatchLogger():BeginBuff(self._entity:GetID(), self._buffInstance:BuffID())
        local logger = self._world:GetMatchLogger()
        logger:AddBloodLog(
            self._entity:GetID(),
            {
                key = "CalcAddBlood",
                desc = "BUFF加血 攻击者[attacker] 被击者[defender] 加血量[blood] 回血系数[rate] 回血比例[mulValue] 回血加值[addValue]",
                attacker = self._entity:GetID(),
                defender = self._entity:GetID(),
                blood = add_value,
                rate = rate,
                mulValue = self._mulValue,
                addValue = self._addValue
            }
        )
        self._world:GetMatchLogger():EndBuff(self._entity:GetID())
    end
    


    --血量截断
    if add_value + cur_hp > max_hp then
        add_value = max_hp - cur_hp
    end

    if self._ignoreForbidCure == 0 then--没有无视禁疗
        --没有禁疗属性才能回血
        local teamEntity = nil
        if e:HasTeam() then
            teamEntity = e
        elseif e:HasPet() then
            teamEntity = e:Pet():GetOwnerTeamEntity()
        end
        
        if add_value > 0 then
            if teamEntity and teamEntity:Attributes():GetAttribute("BuffForbidCure") then
                return
            elseif e:Attributes():GetAttribute("BuffForbidCure") then
                return
            end
        end
    end
    
    if add_value < 0 then
        damageType = DamageType.Real
        add_value = -add_value
    end

    --self._world:GetMatchLogger():BeginBuff(e:GetID(), self._buffInstance:BuffID())

    ---@type CalcDamageService
    local calcDamage = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(add_value, damageType)
    damageInfo:SetSinglePet(self._singlePet)
    if damageType == DamageType.Recover then
        calcDamage:AddTargetHP(e:GetID(), damageInfo)
    else
        calcDamage:_DoDamageModifyHP(e, e, damageInfo)
    end
    damageInfo:SetHPShield(e:BuffComponent():GetBuffValue("HPShield"))
    --self._world:GetMatchLogger():EndBuff(e:GetID())
    ---@type BuffResultAddHP
    local result = BuffResultAddHP:New(damageInfo)
    if notify then
        if notify:GetNotifyType() == NotifyType.MonsterBeHit then
            local skillID = notify:GetSkillID()
            if skillID then
                ---@type ConfigService
                local configService = self._world:GetService("Config")
                ---@type SkillConfigData
                local skillConfigData = configService:GetSkillConfigData(skillID)
                local cfgEffectArray = skillConfigData:GetSkillEffect()
                for index, cfgEffectParam in ipairs(cfgEffectArray) do
                    if cfgEffectParam:GetEffectType() == SkillEffectType.Teleport then
                        result:SetMatchPass(true)
                        break
                    end
                end
            end

            result:SetNotifyAttackerPos(notify:GetAttackPos())
            result:SetNotifyDefenderPos(notify:GetTargetPos())
            result:SetNotifyAttackerID(notify:GetAttackerEntity():GetID())
            result:SetNotifyDefenderID(notify:GetDefenderEntity():GetID())
        end
        if notify:GetNotifyType() == NotifyType.TeamEachMoveEnd then
            local notifyPos = notify:GetPos()
            result:SetNotifyPos(notifyPos)
            result:SetNotifyEntityID(notify:GetEntityID())
        end
        if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd or notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart then
            local notifyPos = notify:GetPos()
            result:SetNotifyPos(notifyPos)
            result:SetNotifyEntityID(notify:GetEntityID())
        end
        if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
            local notifyPos = notify:GetWalkPos()
            result:SetNotifyPos(notifyPos)
            local monsterEntityID = notify:GetNotifyEntity():GetID()
            result:SetNotifyEntityID(monsterEntityID)
        end
        if notify:GetNotifyType() == NotifyType.MonsterDead then
            local monsterEntity = notify:GetNotifyEntity()
            if monsterEntity then
                local monsterEntityID = monsterEntity:GetID()
                result:SetNotifyEntityID(monsterEntityID)
            end
        end
    end
    return result
end

function BuffLogicAddHP:DoOverlap(logicParam)
    return self:DoLogic()
end
