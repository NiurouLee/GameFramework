--[[
    在技能目标中找到指定属性的目标，并让指定buff层数提升到目标中层数最高的 
]]
_class("BuffViewElementTargetAddLayerToHighest", BuffViewBase)
---@class BuffViewElementTargetAddLayerToHighest:BuffViewBase
BuffViewElementTargetAddLayerToHighest = BuffViewElementTargetAddLayerToHighest
---
function BuffViewElementTargetAddLayerToHighest:PlayView(TT)
    ---@type BuffResultElementTargetAddLayerToHighest
    local result = self:GetBuffResult()

    local BuffResultAddLayerList = result:GetBuffResultAddLayerList()
    for _, result in ipairs(BuffResultAddLayerList) do
        ---@type BuffResultLayer
        local result = result
        local curMarkLayer = result:GetLayer()
        local buffSeq = result:GetBuffSeq()
        local entityID = result:GetEntityID()
        local entity = self._world:GetEntityByID(entityID)
        if entity then
            ---@type BuffViewComponent
            local buffView = entity:BuffView()
            ---@type BuffViewInstance
            local viewInstance = buffView:GetBuffViewInstance(buffSeq)
            if viewInstance then
                viewInstance:SetLayerCount(TT, curMarkLayer)
            end
        end
    end

    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end
