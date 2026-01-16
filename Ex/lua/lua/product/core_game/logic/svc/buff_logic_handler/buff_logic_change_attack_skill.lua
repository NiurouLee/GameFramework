--[[
    改变攻击技能
]]
_class("BuffLogicChangeAttackSkill", BuffLogicBase)
---@class BuffLogicChangeAttackSkill:BuffLogicBase
BuffLogicChangeAttackSkill = BuffLogicChangeAttackSkill

function BuffLogicChangeAttackSkill:Constructor(buffInstance, logicParam)
    self._attackSkillId = logicParam.attackSkillId
    self._attackSkillCount = logicParam.attackSkillCount
    self._directReplace = logicParam.directReplace or 0 --直接替换普攻，而不是计算普攻扩展，默认0计算扩展
    self._excludeOriPos = logicParam.excludeOriPos or 0 --扩展普攻的范围中去掉原攻击位置 例：sp巴顿 扩展普攻是光灵周围一圈，需要去掉与原普攻位置重叠的部分
    self._useAttackPosAsCenter = logicParam.useAttackPosAsCenter or 0 --扩展普攻的范围中心点使用光灵攻击位置（而不是被击位置）（sp巴顿）
end

function BuffLogicChangeAttackSkill:DoLogic(notify)
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("ChangeNormalSkillID", self._attackSkillId)
    if self._attackSkillCount then
        e:BuffComponent():SetBuffValue("ChangeNormalSkillCount", self._attackSkillCount)
    end
    e:BuffComponent():SetBuffValue("NormalSkillDirectReplace", self._directReplace)
    if self._excludeOriPos then
        e:BuffComponent():SetBuffValue("ChangeNormalSkillExcludeOriPos", self._excludeOriPos)
    end
    if self._useAttackPosAsCenter then
        e:BuffComponent():SetBuffValue("ChangeNormalSkillUseAttackPosAsCenter", self._useAttackPosAsCenter)
    end

    local trapCasterID = 0
    --如果改变普攻技能 是由处罚机关技能通知的
    if notify and notify:GetNotifyType() == NotifyType.TrapSkillStart then
        trapCasterID = notify:GetNotifyEntity():GetID()
    end
    local buffResult = BuffResultChangeAttackSkill:New(trapCasterID)

    return buffResult
end

_class("BuffLogicUndoChangeAttackSkill", BuffLogicBase)
---@class BuffLogicUndoChangeAttackSkill: BuffLogicBase
BuffLogicUndoChangeAttackSkill = BuffLogicUndoChangeAttackSkill

function BuffLogicUndoChangeAttackSkill:Constructor(buffInstance, logicParam)
end

function BuffLogicUndoChangeAttackSkill:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetBuffValue("ChangeNormalSkillID", nil)
    e:BuffComponent():SetBuffValue("ChangeNormalSkillCount", 0)
    e:BuffComponent():SetBuffValue("NormalSkillDirectReplace", 0)
    e:BuffComponent():SetBuffValue("ChangeNormalSkillExcludeOriPos", 0)
    e:BuffComponent():SetBuffValue("ChangeNormalSkillUseAttackPosAsCenter", 0)
end
