--[[
    修改星灵CD表现
]]
_class("BuffViewChangePetAndTeamActiveSkill", BuffViewBase)
BuffViewChangePetAndTeamActiveSkill = BuffViewChangePetAndTeamActiveSkill

function BuffViewChangePetAndTeamActiveSkill:PlayView(TT)
    local petPstID = self._buffResult:GetPetPstID()
    local skillID = self._buffResult:GetSkillID()

    GameGlobal:EventDispatcher():Dispatch(GameEventType.ChangePetActiveSkill, petPstID, skillID)
end
