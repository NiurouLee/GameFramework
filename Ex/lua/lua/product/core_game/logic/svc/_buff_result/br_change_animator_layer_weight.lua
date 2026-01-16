---设置animator的layerWeight，用于切换动作状态（例：双刀换大剑）
_class("BuffResultChangeAnimatorLayerWeight", BuffResultBase)
---@class BuffResultChangeAnimatorLayerWeight:BuffResultBase
BuffResultChangeAnimatorLayerWeight = BuffResultChangeAnimatorLayerWeight
---changeInfo {layerIndex=weight,layerIndex=weight...}
function BuffResultChangeAnimatorLayerWeight:Constructor(changeInfo)
    self._changeInfo = changeInfo
end
function BuffResultChangeAnimatorLayerWeight:GetChangeInfo()
    return self._changeInfo
end
