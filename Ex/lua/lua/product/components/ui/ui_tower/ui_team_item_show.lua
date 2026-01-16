--[[
    与UITeamItem共用一个Prefab，但仅供展示，不可交互，不可查看队员详情
]]
---@class UITeamItemShow:UICustomWidget
_class("UITeamItemShow", UICustomWidget)
UITeamItemShow = UITeamItemShow

function UITeamItemShow:OnShow()
    ---@type UISelectObjectPath
    self._card = self:GetUIComponent("UISelectObjectPath", "card")
    self._cardGo = self:GetGameObject("card")
    self:GetGameObject("imgMask"):SetActive(false)
    self:GetGameObject("imgAdd"):SetActive(false)
    self:GetGameObject("imgLock"):SetActive(false)
    self:GetGameObject("UIWeakKuang"):SetActive(false)

    --不可交互
    self:GetUIComponent("Image", "imgBG").raycastTarget = false
    --
    self._slot = 0
end

function UITeamItemShow:Flush(slot, pet)
    self._slot = slot
    ---@type SimplePet
    self._pet = pet

    if pet == nil then
    else
        self._cardGo:SetActive(true)
        ---@type UIPetMemberItemShow
        local uiItem = self._card:SpawnObject("UIPetMemberItemShow")
        uiItem:SetData(self._slot, self._pet)
    end
end
