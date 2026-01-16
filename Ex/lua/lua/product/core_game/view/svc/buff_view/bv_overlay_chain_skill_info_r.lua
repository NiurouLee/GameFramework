_class("BuffViewOverlayChainSkillInfo", BuffViewBase)
---@class BuffViewOverlayChainSkillInfo:BuffViewBase
BuffViewOverlayChainSkillInfo = BuffViewOverlayChainSkillInfo

function BuffViewOverlayChainSkillInfo:PlayView(TT)
    -- push game event to UI
    if not self._entity:HasPetPstID() then
        return
    end
    -- local petPstID = self._entity:PetPstID():GetPstID()

    -- -- get its view index and light up
    -- ---@type BuffConfigData
    -- local buffConfig = self._viewInstance:BuffConfigData()
    -- local viewParam = buffConfig:GetViewParams() or {}
    -- local index = viewParam.ActiveSkillChainEnergyViewIndex
    -- if not index then
    --     -- no index, no light
    --     return
    -- end

    -- -- "Let there be light. "
    -- GameGlobal:EventDispatcher():Dispatch(GameEventType.UpdateBuffLayerActiveSkillEnergyChange, {
    --     petPstID = petPstID,
    --     index = index,
    --     on = true
    -- })
end



_class("BuffViewClearOverlayChainSkillInfo", BuffViewBase)
---@class BuffViewClearOverlayChainSkillInfo:BuffViewBase
BuffViewClearOverlayChainSkillInfo = BuffViewClearOverlayChainSkillInfo

function BuffViewClearOverlayChainSkillInfo:PlayView(TT)
    if not self._entity:HasPetPstID() then
        return
    end
    -- local petPstID = self._entity:PetPstID():GetPstID()

    -- GameGlobal:EventDispatcher():Dispatch(GameEventType.UpdateBuffLayerActiveSkillEnergyChange, {
    --     petPstID = petPstID,
    --     index = self._buffResult.index,
    --     on = false,
    --     all = self._buffResult.isAll,
    -- })
end
