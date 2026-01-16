---将加buff的施法者的总防御力，赋给buff持有者的基础防御力
---@class BuffLogicSetGuestDefence:BuffLogicBase
_class("BuffLogicSetGuestDefence", BuffLogicBase)
BuffLogicSetGuestDefence = BuffLogicSetGuestDefence

function BuffLogicSetGuestDefence:Constructor(buffInstance, logicParam)
end

function BuffLogicSetGuestDefence:DoLogic()
    local guestValue = self._entity:BuffComponent():GetBuffValue("GuestDefence")
    if guestValue == nil then
        Log.notice("Haven't guest, SetGuestDefence Error!")
        return
    end
    self._buffLogicService:ChangeBaseDefence(self._entity, self:GetBuffSeq(), ModifyBaseDefenceType.Defense, guestValue)
end

--重置
---@class BuffLogicResetGuestDefence:BuffLogicBase
_class("BuffLogicResetGuestDefence", BuffLogicBase)
BuffLogicResetGuestDefence = BuffLogicResetGuestDefence

function BuffLogicResetGuestDefence:Constructor(buffInstance, logicParam)
end

function BuffLogicResetGuestDefence:DoLogic()
    Log.notice("BuffLogicResetGuestDefence")
    self._buffLogicService:RemoveBaseDefence(self._entity, self:GetBuffSeq(), ModifyBaseDefenceType.Defense)
end
