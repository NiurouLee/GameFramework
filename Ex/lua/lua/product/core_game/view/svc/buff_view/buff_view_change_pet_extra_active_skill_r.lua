--[[
    改变星灵附加主动技
]]
_class("BuffViewChangePetExtraActiveSkill", BuffViewBase)
---@class BuffViewChangePetExtraActiveSkill : BuffViewBase
BuffViewChangePetExtraActiveSkill = BuffViewChangePetExtraActiveSkill

function BuffViewChangePetExtraActiveSkill:PlayView(TT)
    local pstId = self._entity:PetPstID():GetPstID()
    local skillID = self._buffResult:GetNewSkillID()
    local oriSkillID = self._buffResult:GetOriSkillID()
    --通知更换主动技
    GameGlobal:EventDispatcher():Dispatch(GameEventType.ChangePetExtraActiveSkill, pstId, oriSkillID,skillID)
end
