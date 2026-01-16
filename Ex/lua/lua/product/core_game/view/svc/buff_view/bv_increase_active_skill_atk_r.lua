_class("BuffViewDoIncreaseActiveSkillAtk", BuffViewBase)
BuffViewDoIncreaseActiveSkillAtk = BuffViewDoIncreaseActiveSkillAtk

function BuffViewDoIncreaseActiveSkillAtk:PlayView(TT)
    ---@type BuffResultDoIncreaseActiveSkillAtk
    local result = self._buffResult
    local light = result:GetLight()
    local layer = result:GetLayer()
    if light then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, self._entity:PetPstID():GetPstID(), layer)
    end
end

_class("BuffViewUndoIncreaseActiveSkillAtk", BuffViewBase)
BuffViewUndoIncreaseActiveSkillAtk = BuffViewUndoIncreaseActiveSkillAtk

function BuffViewUndoIncreaseActiveSkillAtk:PlayView(TT)
    ---@type BuffResultUndoIncreaseActiveSkillAtk
    local result = self._buffResult
    if result:GetDark() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, self._entity:PetPstID():GetPstID(), 0)
    end
end
