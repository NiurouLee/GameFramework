require('buff_logic_base')

_class("BuffLogicButterflyPollen", BuffLogicBase)
---@class BuffLogicButterflyPollen:BuffLogicBase
BuffLogicButterflyPollen = BuffLogicButterflyPollen

function BuffLogicButterflyPollen:Constructor(buffInstance, logicParam)
    self._layerType = tonumber(logicParam.layerType)
    self._damagePercent = logicParam.damagePercent

    self._monsterDamageIncreaseMinValue = logicParam.monsterDamageIncreaseMinValue or 0
    self._monsterDamageIncreaseOneLayerValue = logicParam.monsterDamageIncreaseOneLayerValue or 0

    self._petDamageIncreaseMinValue = logicParam.petDamageIncreaseMinValue or 0
    self._petDamageIncreaseOneLayerValue = logicParam.petDamageIncreaseOneLayerValue or 0

    self._monsterAddHPMulValue = logicParam.monsterAddHPMulValue or 0
    self._monsterAddHPValue = logicParam.monsterAddHPValue or 0
end

---@param notify NotifyAttackBase
function BuffLogicButterflyPollen:DoLogic(notify)
    local e = self._entity

    local layer = self._buffLogicService:GetBuffLayer(e, self._layerType)
    if layer <= 0 then
        return
    end

    local result = BuffResultButterflyPollen:New()

    ---@type Entity
    if e:HasMonsterID() then
        -- 0层怎么办？
        if self._monsterDamageIncreaseMinValue > 0 or self._monsterDamageIncreaseOneLayerValue > 0 then
            ---@type BuffLogicService
            local svc = self._world:GetService("BuffLogic")

            local changeVal = self._monsterDamageIncreaseMinValue + self._monsterDamageIncreaseOneLayerValue * layer
            local seq = self:GetBuffSeq()

            self._buffLogicService:RemoveSkillIncrease(e, seq, ModifySkillIncreaseParamType.MonsterDamage)
            self._buffLogicService:ChangeSkillIncrease(e, seq, ModifySkillIncreaseParamType.MonsterDamage, changeVal)
        end

        if self._monsterAddHPMulValue > 0 or self._monsterAddHPValue > 0 then
            ---@type AttributesComponent
            local cAttr = e:Attributes()
            local maxHP = cAttr:CalcMaxHp()
            local rate = cAttr:GetAttribute("AddBloodRate") or 0

            local val = math.floor((maxHP * self._monsterAddHPMulValue + self._monsterAddHPValue) * (1 + rate))
            if val >= 0 then
                self._world:GetMatchLogger():BeginBuff(self._entity:GetID(), self._buffInstance:BuffID())
                local logger = self._world:GetMatchLogger()
                logger:AddBloodLog(
                        self._entity:GetID(),
                        {
                            key = "ButterflyPollen",
                            desc = "BUFF加血 攻击者[attacker] 被击者[defender] 加血量[blood] 回血系数[rate] 回血比例[mulValue] 回血加值[addValue]",
                            attacker = self._entity:GetID(),
                            defender = self._entity:GetID(),
                            blood = val,
                            rate = rate,
                            mulValue = self._mulValue,
                            addValue = self._addValue
                        }
                )
                self._world:GetMatchLogger():EndBuff(self._entity:GetID())

                ---@type CalcDamageService
                local calcDamage = self._world:GetService("CalcDamage")
                ---@type DamageInfo
                local damageInfo = DamageInfo:New(val, DamageType.Recover)
                damageInfo:SetHPShield(e:BuffComponent():GetBuffValue("HPShield"))

                calcDamage:AddTargetHP(e:GetID(), damageInfo)

                result:SetRecoveryDamageInfo(damageInfo)
            end
        end
    elseif e:HasTeam() then
        ---@type AttributesComponent
        local attrCmpt = e:Attributes()

        local maxHp = attrCmpt:CalcMaxHp()
        if maxHp <= 0 then
            return
        end

        ---@type BuffLogicService
        local blsvc = self._world:GetService("BuffLogic")
        Log.debug("Buff AddPoison, beforeCalcDmg,entityID: ",e:GetID())
        local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), e, e, {
            percent = self._damagePercent,
            layer = layer,
            formulaID = 15
        })

        --历史原因，在这之前的中毒相关逻辑都做了这样的处理，作者找不到了，推测是计算过程中真伤有些特殊处理
        if damageInfo:GetDamageType() == DamageType.Real then
            damageInfo:SetDamageType(DamageType.Poison)
        end

        result:SetPoisonDamageInfo(damageInfo)

        if self._petDamageIncreaseMinValue > 0 or self._petDamageIncreaseOneLayerValue > 0 then
            local changeVal = self._petDamageIncreaseMinValue + self._petDamageIncreaseOneLayerValue * layer
            local seq = self:GetBuffSeq()

            ---@type TeamComponent
            local cTeam = e:Team()
            for _, pet in ipairs(cTeam:GetTeamPetEntities()) do
                self._buffLogicService:RemoveSkillIncrease(pet, seq, ModifySkillIncreaseParamType.NormalSkill)
                self._buffLogicService:RemoveSkillIncrease(pet, seq, ModifySkillIncreaseParamType.ChainSkill)
                self._buffLogicService:RemoveSkillIncrease(pet, seq, ModifySkillIncreaseParamType.ActiveSkill)

                self._buffLogicService:ChangeSkillIncrease(pet, seq, ModifySkillIncreaseParamType.NormalSkill, changeVal)
                self._buffLogicService:ChangeSkillIncrease(pet, seq, ModifySkillIncreaseParamType.ChainSkill, changeVal)
                self._buffLogicService:ChangeSkillIncrease(pet, seq, ModifySkillIncreaseParamType.ActiveSkill, changeVal)
            end
        end
    end

    return result
end

_class("BuffLogicRevertButterflyPollen", BuffLogicBase)
---@class BuffLogicRevertButterflyPollen:BuffLogicBase
BuffLogicRevertButterflyPollen = BuffLogicRevertButterflyPollen

---@param notify NotifyAttackBase
function BuffLogicRevertButterflyPollen:DoLogic(notify)
    local e = self._entity

    local seq = self:GetBuffSeq()

    ---@type Entity
    if e:HasMonsterID() then
        self._buffLogicService:RemoveSkillIncrease(e, seq, ModifySkillIncreaseParamType.MonsterDamage)
    elseif e:HasTeam() then
        ---@type TeamComponent
        local cTeam = e:Team()
        for _, pet in ipairs(cTeam:GetTeamPetEntities()) do
            self._buffLogicService:RemoveSkillIncrease(pet, seq, ModifySkillIncreaseParamType.NormalSkill)
            self._buffLogicService:RemoveSkillIncrease(pet, seq, ModifySkillIncreaseParamType.ChainSkill)
            self._buffLogicService:RemoveSkillIncrease(pet, seq, ModifySkillIncreaseParamType.ActiveSkill)
        end
    end

    return true
end
