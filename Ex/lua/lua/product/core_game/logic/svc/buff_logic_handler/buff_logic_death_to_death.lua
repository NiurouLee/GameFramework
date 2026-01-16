--[[
    词缀恐惧之潮专用逻辑，会在怪物Entity销毁之前触发一次技能，并收集被该技能打死的其他怪物，手动执行死亡逻辑，实现连环死亡
]]
_class("BuffLogicDeathToDeath", BuffLogicBase)
BuffLogicDeathToDeath = BuffLogicDeathToDeath

function BuffLogicDeathToDeath:Constructor(buffInstance, logicParam)
    self._skillID = logicParam["skillID"]
end

function BuffLogicDeathToDeath:DoLogic(notify)
    ---@type Entity
    local e = self._buffInstance:Entity()

    --在这里对死亡的怪做标记，防止递归死循环
    e:Attributes():SetSimpleAttribute("BuffDeathToDeath", 1)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")
    skillLogicSvc:CalcSkillEffect(e, self._skillID)
    local result = e:SkillContext():GetResultContainer()

    if self._world:RunAtServer() then
        ---@type table<number,SkillDamageEffectResult>
        local damageResults = e:SkillContext():GetResultContainer():GetEffectResultByArray(SkillEffectType.Damage)
        if damageResults and #damageResults > 0 then
            ---@type MonsterShowLogicService
            local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")

            for _, result in ipairs(damageResults) do
                ---@type Entity
                local target = self._world:GetEntityByID(result:GetTargetID())
                --技能对目标造成了伤害，且目标死亡，则判定为该技能造成的，其实这里判断并不严谨
                if
                    result:GetTotalDamage() > 0 and target:Attributes():GetCurrentHP() <= 0 and
                        target:Attributes():GetAttribute("BuffDeathToDeath") == nil
                 then
                    sMonsterShowLogic:_DoLogicDead(target)
                end
            end
        end
    end

    return BuffResultDeathToDeath:New(e:GetID(), self._skillID,result)
end
