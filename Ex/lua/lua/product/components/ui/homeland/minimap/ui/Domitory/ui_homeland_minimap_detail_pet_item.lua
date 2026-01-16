--
---@class UIHomelandMinimapDetailPetItem : UICustomWidget
_class("UIHomelandMinimapDetailPetItem", UICustomWidget)
UIHomelandMinimapDetailPetItem = UIHomelandMinimapDetailPetItem
--初始化
function UIHomelandMinimapDetailPetItem:OnShow(uiParams)
    self:InitWidget()
    ---@type UIHomePetAffinityItem
    self._affinity = self.affinity:SpawnObject("UIHomePetAffinityItem")
end
--获取ui组件
function UIHomelandMinimapDetailPetItem:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UICustomWidgetPool
    self.affinity = self:GetUIComponent("UISelectObjectPath", "affinity")
    --generated end--
end
--设置数据
---@param pet MatchPet
function UIHomelandMinimapDetailPetItem:SetData(pet)
    if pet then
        self.icon:LoadImage(pet:GetPetTeamBody(PetSkinEffectPath.CARD_TEAM))
        self._affinity:SetData(pet)
        self.icon.gameObject:SetActive(true)
        self._affinity:GetGameObject():SetActive(true)
    else
        self.icon.gameObject:SetActive(false)
        self._affinity:GetGameObject():SetActive(false)
    end
end
