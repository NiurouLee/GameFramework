---@class UIChooseAssistantPetSkinCard : UICustomWidget
_class("UIChooseAssistantPetSkinCard", UICustomWidget)
UIChooseAssistantPetSkinCard = UIChooseAssistantPetSkinCard
function UIChooseAssistantPetSkinCard:Constructor()
    self._checkIsCurSkinCallBack = nil
end
function UIChooseAssistantPetSkinCard:OnShow(uiParams)
    self:InitWidget()
end
function UIChooseAssistantPetSkinCard:InitWidget()
    --generated--
    self._cardAreaGo = self:GetGameObject("CardArea")

    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "BottomBg")
    self._bgGo = self:GetGameObject("BottomBg")
    ---@type RawImageLoader
    self._headImg = self:GetUIComponent("RawImageLoader", "HeadImg")
    ---@type UnityEngine.GameObject
    self._curUseArea = self:GetGameObject("CurUseArea")
    ---@type UILocalizationText
    self._skinNameText = self:GetUIComponent("UILocalizationText", "SkinNameText")
    ---@type UnityEngine.UI.Image
    self.selectFrame = self:GetUIComponent("Image", "SelectFrame")
    self._frameImgGo = self:GetGameObject("SelectFrame")
    ---@type UnityEngine.GameObject
    self._funcLayerGo = self:GetGameObject("FuncLayer")
    self._grayCoverGo = self:GetGameObject("GrayCoverImg")
    --generated end--

    self._red = self:GetGameObject("red")

    self:AttachEvent(GameEventType.OnRemoveAsCardNew,self.RemoveAsNew)
end
function UIChooseAssistantPetSkinCard:RemoveAsNew(asid)
    if asid == self._asid then
        self._red:SetActive(false)
    end
end
function UIChooseAssistantPetSkinCard:SetCheckIsCurSkinCallBack(callBack)
    self._checkIsCurSkinCallBack = callBack
end
---@param skinData choose_assistant_ui_data_skin
function UIChooseAssistantPetSkinCard:SetData(skinData,idx,callbcak, begindrag, drag, enddrag)
    local skinCfg = MatchPet.GetPetSkinCfg(skinData.petid,skinData.grade,skinData.skinid,PetSkinEffectPath.HEAD_ICON_CHANGE_ASSIST)
    self._idx = idx
    
    self._callback = callbcak
    self._beginDrag = begindrag
    self._drag = drag
    self._endDrag = enddrag

    self._asid = 0

    local resData = {}
    if skinData.asid and skinData.asid ~= 0 then
        local cfg = Cfg.cfg_only_assistant[skinData.asid]
        resData.icon = cfg.Icon
        self._asid = skinData.asid
    else
        resData.icon = skinCfg.AircraftBody
    end

    if self._curUseArea and self._checkIsCurSkinCallBack then
        local isCur = self._checkIsCurSkinCallBack(skinData.petid,skinData.grade,skinData.skinid,skinData.asid)
        self._curUseArea:SetActive(isCur)
    end
    if self._headImg and skinCfg then
        --self._headImg:LoadImage(skinCfg.TeamBody)--tmp
        --self._headImg:LoadImage(skinCfg.VideoIcon)--tmp
        self._headImg:LoadImage(resData.icon)--tmp
    end

    self:SetIsOnTop(true)

    self:SetRed()

    self:AddUICustomEventListener(UICustomUIEventListener.Get(self._bgGo), UIEvent.BeginDrag, self._beginDrag)
    self:AddUICustomEventListener(UICustomUIEventListener.Get(self._bgGo), UIEvent.Drag, self._drag)
    self:AddUICustomEventListener(UICustomUIEventListener.Get(self._bgGo), UIEvent.EndDrag, self._endDrag)
end
function UIChooseAssistantPetSkinCard:SetRed()
    self._redState = false
    if self._asid ~= 0 then
        local itemModule = GameGlobal.GetModule(ItemModule)
        local itemDatas = itemModule:GetItemByTempId(self._asid)
        if itemDatas and table.count(itemDatas) > 0 then
            ---@type Item
            local item_data
            for key, value in pairs(itemDatas) do
                item_data = value
                break
            end
            local isNew = item_data:IsNewOverlay()
            self._redState = isNew
            self._pstid = item_data:GetID()
        end
    end
    self._red:SetActive(self._redState)
end
function UIChooseAssistantPetSkinCard:BottomBgOnClick(go)
    if self._callback then
        self._callback(self._idx)
    end
end
function UIChooseAssistantPetSkinCard:SetIsOnTop(isOnTop)
    if self._lastOnTop ~= isOnTop then
        self._lastOnTop = isOnTop
    else
        return
    end
    if isOnTop then
        --self:GetGameObject().transform:DOScale(Vector3(1, 1, 1),0.2)
        self._cardAreaGo.transform:DOLocalMoveX(-5.5,0.2)
    else
        --self:GetGameObject().transform:DOScale(Vector3(0.95, 0.95, 1),0.2)
        self._cardAreaGo.transform:DOLocalMoveX(0,0.2)
    end
    self._funcLayerGo:SetActive(isOnTop)
    self._frameImgGo:SetActive(isOnTop)
    self._grayCoverGo:SetActive(not isOnTop)

end
