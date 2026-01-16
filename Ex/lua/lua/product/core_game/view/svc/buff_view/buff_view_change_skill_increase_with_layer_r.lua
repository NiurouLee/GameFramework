--[[
    修改星灵技能伤害某些星灵有表现
]]
_class("BuffViewChangeSkillIncreaseWithLayer", BuffViewBase)
BuffViewChangeSkillIncreaseWithLayer = BuffViewChangeSkillIncreaseWithLayer

function BuffViewChangeSkillIncreaseWithLayer:PlayView(TT)
end

_class("BuffViewRemoveSkillIncreaseWithLayer", BuffViewBase)
BuffViewRemoveSkillIncreaseWithLayer = BuffViewRemoveSkillIncreaseWithLayer

function BuffViewRemoveSkillIncreaseWithLayer:PlayView(TT)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end
