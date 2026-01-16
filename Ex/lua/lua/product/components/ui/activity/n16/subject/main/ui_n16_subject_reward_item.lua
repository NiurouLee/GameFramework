---@class UIN16SubjectRewardItem : UICustomWidget
_class("UIN16SubjectRewardItem", UICustomWidget)
UIN16SubjectRewardItem = UIN16SubjectRewardItem

function UIN16SubjectRewardItem:OnShow()
    self._iconImgLoader = self:GetUIComponent("RawImageLoader", "Icon")
    self._iconImgRaw =  self:GetUIComponent("RawImage", "Icon")
    self._iconImg = self:GetUIComponent("RawImage", "Icon")
    self._iconGo = self:GetGameObject("Icon")
    self._countLabel = self:GetUIComponent("UILocalizationText", "Count")
    self._countBg = self:GetGameObject("CountBg")
    self._hasGetCountBg = self:GetGameObject("HasGetCount")
    self._hasGetCountImg =  self:GetUIComponent("Image", "HasGetCount")
    self._go = self:GetGameObject()
end

function UIN16SubjectRewardItem:OnHide()
    self._EMIMat = nil
end

function UIN16SubjectRewardItem:Refresh(reward, hasComplete)
    self._rewardId = reward[1]
    self._countLabel.text = reward[2]
    local ItemTempleate = Cfg.cfg_item[self._rewardId]
    self._iconImgLoader:LoadImage(ItemTempleate.Icon)
    if hasComplete then
        self._countBg:SetActive(false)
        self._hasGetCountBg:SetActive(true)
        self:SetRawImageGray(true)
    else
        self._countBg:SetActive(true)
        self._hasGetCountBg:SetActive(false)
        self:SetRawImageGray(false)
    end
end

function UIN16SubjectRewardItem:SetRawImageGray(gray)
    -- if not self._EMIMat then
    --     self._EMIMat = UnityEngine.Material:New(self._iconImg.material)
    -- end

    -- if gray then
    --     -- LoadImage(name) 会将同样图片的 material 设置为同一个
    --     -- 需要替换独立的 material 然后设置灰度
    --     local texture = self._iconImg.material.mainTexture
    --     self._iconImg.material = self._EMIMat
    --     self._iconImg.material.mainTexture = texture
    --     self._iconImg.material:SetFloat("_LuminosityAmount", 0.6)
    -- else
    --     -- LoadImage(name) 如果读取与之前名字相同的图片会直接 return
    --     -- 需要保证独立的 material 灰度正常
    --     self._iconImg.material:SetFloat("_LuminosityAmount", 0)
    -- end

    -- self._iconGo:SetActive(false)
    -- self._iconGo:SetActive(true)
    if gray then 
        self._iconImgRaw.color = Color.New(255 / 255,255 / 255, 255 / 255, 150/255)
        self._countLabel.color  = Color.New(255 / 255,255 / 255, 255 / 255, 150/255)
        self._hasGetCountImg .color  = Color.New(255 / 255,255 / 255, 255 / 255, 150/255)
    else 
        self._iconImgRaw.color = Color.New(255 / 255,255 / 255, 255 / 255, 255/255)
        self._countLabel.color  = Color.New(255 / 255,255 / 255, 255 / 255, 255/255)
        self._hasGetCountImg .color  = Color.New(255 / 255,255 / 255, 255 / 255, 255/255)
    end
end

function UIN16SubjectRewardItem:BtnOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN16SubjectRewardItemClicked, self._rewardId, self._go.transform.position)
end
