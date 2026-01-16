_class("BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters", BuffResultBase)
---@class BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters:BuffResultBase
BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters = BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters

function BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters:Constructor(ownerEntityID, defenderEntityID)
    self._ownerEntityID = ownerEntityID
    self._defenderEntityID = defenderEntityID

    ---@type BuffResultSpreadSelfBuffLayerToOtherMonsters_SpreadInfo[]
    self._spreadResults = {}
end

function BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters:GetOwnerEntityID()
    return self._ownerEntityID
end

function BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters:GetDefenderEntityID()
    return self._defenderEntityID
end

---@class BuffResultSpreadSelfBuffLayerToOtherMonsters_SpreadInfo
---@field targetID number
---@field layerBuffEffectType number
---@field layer number
---@field buffSeq number

function BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters:AddSpreadResult(targetID, layerBuffEffectType, addLayer, finalLayer, buffSeq, casterEntity)
    table.insert(self._spreadResults, {
        targetID = targetID,
        layerBuffEffectType = layerBuffEffectType,
        addLayer = addLayer,
        finalLayer = finalLayer,
        buffSeq = buffSeq,
        casterEntity = casterEntity,
    })
end

function BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters:GetSpreadResults()
    return self._spreadResults
end
