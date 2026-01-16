--[[
    改变星灵主动技能
]]
_class("BuffViewChangePetActiveSkill", BuffViewBase)
BuffViewChangePetActiveSkill = BuffViewChangePetActiveSkill

function BuffViewChangePetActiveSkill:PlayView(TT)
    local pstId = self._entity:PetPstID():GetPstID()
    local skillID = self._buffResult:GetSkillID()
    local layer = self._buffResult:GetLayer()
    --通知更换主动技
    GameGlobal:EventDispatcher():Dispatch(GameEventType.ChangePetActiveSkill, pstId, skillID)
end
