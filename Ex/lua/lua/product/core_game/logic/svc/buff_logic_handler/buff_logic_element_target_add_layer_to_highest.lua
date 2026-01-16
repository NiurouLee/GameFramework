--[[
    在技能目标中找到指定属性的目标，并让指定buff层数提升到目标中层数最高的 
]]
require "buff_logic_base"
_class("BuffLogicElementTargetAddLayerToHighest", BuffLogicBase)
---@class BuffLogicElementTargetAddLayerToHighest:BuffLogicBase
BuffLogicElementTargetAddLayerToHighest = BuffLogicElementTargetAddLayerToHighest

function BuffLogicElementTargetAddLayerToHighest:Constructor(buffInstance, logicParam)
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._element = logicParam.element
end

---@param notify NotifyAttackBase
function BuffLogicElementTargetAddLayerToHighest:DoLogic(notify)
    if not notify.GetDefenderEntityIDList then
        return
    end

    local highestLayer = 0
    local elementTargetList = {}

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    local eids = notify:GetDefenderEntityIDList()

    for _, eid in ipairs(eids) do
        local entity = self._world:GetEntityByID(eid)
        local element = utilSvc:GetEntityElementType(entity)
        if not entity:HasDeadMark() and element == self._element then
            table.insert(elementTargetList, entity)
        end
        ---@type BuffComponent
        local buffComponent = entity:BuffComponent()
        if buffComponent then
            local curMarkLayer = self._buffLogicService:GetBuffLayer(entity, self._layerType)
            if curMarkLayer > highestLayer then
                highestLayer = curMarkLayer
            end
        end
    end

    local buffResultAddLayerList = {}
    for _, entity in ipairs(elementTargetList) do
        local curMarkLayer = self._buffLogicService:GetBuffLayer(entity, self._layerType)
        if curMarkLayer < highestLayer then
            local addLayer = highestLayer - curMarkLayer
            local curMarkLayer, buffinst = self._buffLogicService:AddBuffLayer(entity, self._layerType, addLayer)
            if buffinst then
                local buffResultLayer = BuffResultLayer:New(curMarkLayer, buffinst:BuffSeq())
                buffResultLayer:SetEntityID(entity:GetID())
                table.insert(buffResultAddLayerList, buffResultLayer)
            end
        end
    end

    local buffResult = BuffResultElementTargetAddLayerToHighest:New(buffResultAddLayerList)

    return buffResult
end
