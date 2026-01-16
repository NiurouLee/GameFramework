--
---@class UIHomePetInvitePoint : UICustomWidget
_class("UIHomePetInvitePoint", UICustomWidget)
UIHomePetInvitePoint = UIHomePetInvitePoint

function UIHomePetInvitePoint:Constructor()
    self._atlas = self:GetAsset("UIHomelandInvite.spriteatlas", LoadType.SpriteAtlas)
end

--初始化
function UIHomePetInvitePoint:OnShow(uiParams)
    self:_GetComponents()
    self:AttachEvent(GameEventType.OnPetInvitePreview,self.Refresh)
end

function UIHomePetInvitePoint:OnHide()
    self:DetachEvent(GameEventType.OnPetInvitePreview,self.Refresh)
end
--获取ui组件
function UIHomePetInvitePoint:_GetComponents()
    ---@type UnityEngine.UI.Image
    self._selectImg = self:GetUIComponent("Image", "SelectImg")
    ---@type UILocalizationText
    self._invitePointIndex = self:GetUIComponent("UILocalizationText", "InvitePointIndex")
    self._petIcon = self:GetUIComponent("RawImageLoader", "PetIcon")
    self._petIconGo = self:GetGameObject("PetIcon")
    self._removeBtnGo = self:GetGameObject("RemoveBtn")
end

--设置数据
---@param inviteManager HomelandPetInviteManager
---@param index number 交互点索引
---@param pet HomelandPet
function UIHomePetInvitePoint:SetData(inviteManager, index, pet, callback)
    self._inviteManager = inviteManager
    self._index = index
    self._callback = callback
    self._invitePointIndex:SetText(self._index)
    self:SetPetInfo(pet)
end

--按钮点击
function UIHomePetInvitePoint:AddBtnOnClick(go)
    if not self._pet then
        self:OnSelect()
    end
end

function UIHomePetInvitePoint:RemoveBtnOnClick(go)
    if self._pet then
        self._inviteManager:InviteEnterListPreview(self._pet, false)
        self:SetPetInfo(nil)
        self.uiOwner:DefaultSelect()
        self._inviteManager:UpdateInvitedPets(self._index, nil)
    end
end

function UIHomePetInvitePoint:Refresh(pet,enter)
    if not self._pet then 
        return 
    end 
    if pet and pet:TemplateID() == self._pet:TemplateID() then
        if  enter then 
            
        else 
            self:SetPetInfo(nil)
            self.uiOwner:DefaultSelect()
            self._inviteManager:UpdateInvitedPets(self._index, nil)
        end 
    end
end


function UIHomePetInvitePoint:RefreshSelectImg(selected)
    if selected then
        self._selectImg.sprite = self._atlas:GetSprite("N17_hudong_icon06_02")
    else
        self._selectImg.sprite = self._atlas:GetSprite("N17_hudong_icon06_01")
    end
end

--设置当前交互点上的光灵信息
function UIHomePetInvitePoint:SetPetInfo(pet)
    self._pet = pet
    if self._pet then
        local icon = nil
        if self._pet._clothSkinID ~= nil then 
            local headicon = Cfg.cfg_pet_skin[self._pet._clothSkinID]
            icon  = headicon.Head
        else 
            icon  = "head1_".. self._pet._tmpID
        end  
        self._petIcon:LoadImage(icon)
    end
    local selected = self._pet ~= nil
    self._petIconGo:SetActive(selected)
    self._removeBtnGo:SetActive(selected)
end

function UIHomePetInvitePoint:GetPet()
    return self._pet
end

---交互点索引
function UIHomePetInvitePoint:GetIndex()
    return self._index
end

function UIHomePetInvitePoint:OnSelect()
    self:RefreshSelectImg(true)
    self._callback(self)
end