--[[
    设置animator的layerWeight，用于切换动作状态（例：双刀换大剑）
]]
_class("BuffLogicChangeAnimatorLayerWeight", BuffLogicBase)
---@class BuffLogicChangeAnimatorLayerWeight : BuffLogicBase
BuffLogicChangeAnimatorLayerWeight = BuffLogicChangeAnimatorLayerWeight

function BuffLogicChangeAnimatorLayerWeight:Constructor(buffInstance, logicParam)
    self._layerWeightTable = {}
    if logicParam.layerWeightTable then
        for key,value in pairs(logicParam.layerWeightTable) do
            self._layerWeightTable[key] = tonumber(value)
        end
    end
end

function BuffLogicChangeAnimatorLayerWeight:DoLogic(notify)
    return BuffResultChangeAnimatorLayerWeight:New(self._layerWeightTable)
end
