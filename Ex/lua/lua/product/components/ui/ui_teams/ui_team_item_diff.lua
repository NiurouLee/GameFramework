---@class UITeamItemDiff : UICustomWidget
_class("UITeamItemDiff", UICustomWidget)
UITeamItemDiff = UITeamItemDiff
function UITeamItemDiff:Constructor()
end
function UITeamItemDiff:OnShow()
    self._diffGo = self:GetGameObject("diffGo")
end
function UITeamItemDiff:OnHide()
end
function UITeamItemDiff:SetData(pstID, teamType)
    local show = false
    if teamType == TeamOpenerType.Diff and pstID > 0 then
        ---@type UIDiffMissionModule
        local module = GameGlobal.GetUIModule(DifficultyMissionModule)
        local filterPets = module:GetFilterPets()
        if filterPets[pstID] then
            show = true
        end
    elseif teamType == TeamOpenerType.Sailing then
        ---@type SailingMissionModule
        local sailingMissionModule = GameGlobal.GetModule(SailingMissionModule)
        local filterPets = sailingMissionModule:GetFilterPets()
        if filterPets[pstID] then
            show = true
        end
    elseif teamType == TeamOpenerType.Vampire then
        show = false
    elseif teamType == TeamOpenerType.Camp_Diff then
        ---@type UIDiffMissionModule
        local module = GameGlobal.GetUIModule(DifficultyMissionModule)
        local filterPets = module:GetFilterPets()
        if filterPets[pstID] then
            show = true
        end
    end
    self._diffGo:SetActive(show)
end
