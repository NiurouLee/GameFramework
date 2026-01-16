--[[
    改变星灵连锁技能 表现
]]
_class("BuffViewChangePetChainSkill", BuffViewBase)
BuffViewChangePetChainSkill = BuffViewChangePetChainSkill

function BuffViewChangePetChainSkill:PlayView(TT)
    if self._buffResult:GetLight() == 1 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), true)
    end
end

_class("BuffViewChangePetChainSkillUndo", BuffViewBase)
BuffViewChangePetChainSkillUndo = BuffViewChangePetChainSkillUndo

function BuffViewChangePetChainSkillUndo:PlayView(TT)
    if self._buffResult:GetBlack() == 1 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), false)
    end
end
