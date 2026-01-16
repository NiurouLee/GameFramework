--[[
    纯表现 播放特效动画
]]
_class("BuffLogicPlayEffectAnim", BuffLogicBase)
---@class BuffLogicPlayEffectAnim:BuffLogicBase
BuffLogicPlayEffectAnim = BuffLogicPlayEffectAnim

function BuffLogicPlayEffectAnim:Constructor(buffInstance, logicParam)
    self._objName = logicParam.objName
    self._animName = logicParam.animName
    self._waitTime = logicParam.waitTime
end

function BuffLogicPlayEffectAnim:DoLogic()
    local buffResult = BuffResultPlayEffectAnim:New(self._objName, self._animName, self._waitTime)
    return buffResult
end
