--[[
    根据瞬移技能的距离叠加层数 
]]
require "buff_logic_base"
_class("BuffLogicAddLayerByTeleportDistance", BuffLogicBase)
---@class BuffLogicAddLayerByTeleportDistance:BuffLogicBase
BuffLogicAddLayerByTeleportDistance = BuffLogicAddLayerByTeleportDistance

function BuffLogicAddLayerByTeleportDistance:Constructor(buffInstance, logicParam)
    -- self._layer = logicParam.layer
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._buffInstance._buffLayerName = self._buffInstance._buffsvc:GetBuffLayerName(self._layerType)
    self._dontDisplay = logicParam.dontDisplay
end

---@param notify NotifyAttackBase
function BuffLogicAddLayerByTeleportDistance:DoLogic(notify)
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local currentRingNum =
        utilCalcSvc:GetGridRingNum(
        notify:GetPosNew(),
        notify:GetPosOld(),
        notify:GetNotifyEntity():BodyArea():GetArea()
    )

    local curMarkLayer = svc:AddBuffLayer(self._entity, self._layerType, currentRingNum)
    local buffResult = BuffResultAddLayer:New(curMarkLayer, self._dontDisplay)
    return buffResult
end
