---@class UITalePetInfoItem : UICustomWidget
_class("UITalePetInfoItem", UICustomWidget)
UITalePetInfoItem = UITalePetInfoItem
function UITalePetInfoItem:OnShow(uiParams)
    self.ElementSpriteName = {
        [ElementType.ElementType_Blue] = "bing_color",
        [ElementType.ElementType_Red] = "huo_color",
        [ElementType.ElementType_Green] = "sen_color",
        [ElementType.ElementType_Yellow] = "lei_color"
    }
    self.NameBgSpriteName = {
        [1] = "legend_sixiang_btn7",
        [2] = "legend_sixiang_btn4",
        [3] = "legend_sixiang_btn6",
        [4] = "legend_sixiang_btn5",
        [5] = "legend_sixiang_btn7",
    }
    self.atlas = self:GetAsset("UITalePet.spriteatlas", LoadType.SpriteAtlas)
    self.talePetModule = GameGlobal.GetModule(TalePetModule)
    self:InitWidget()
    self:AttachEvent(GameEventType.TalePetInfoDataChange,self.InfoDataChange)
end

function UITalePetInfoItem:OnHide()
    self:DetachEvent(GameEventType.TalePetInfoDataChange)
end

function UITalePetInfoItem:InfoDataChange()
    self:SetTalePetState()
    self:PetInfoRedController()
end

function UITalePetInfoItem:InitWidget()
    ---@type RawImageLoader
    self.prop1 = self:GetUIComponent("Image", "prop1")
    self.prop2 = self:GetUIComponent("Image", "prop2")
    self.propObj1 = self:GetGameObject("prop1Obj")
    self.propObj2 = self:GetGameObject("prop2Obj")
    self.name = self:GetUIComponent("UILocalizationText","Name")
    self.state = self:GetGameObject("state")
    self.txtState = self:GetUIComponent("UILocalizationText","txtState")
    self.imgState1 = self:GetGameObject("imgState1")
    self.imgState2 = self:GetGameObject("imgState2")
    self.bg = self:GetUIComponent("Image","bg")

    self.petInfoRed = self:GetGameObject("petInfoRed")
end
function UITalePetInfoItem:SetData(tmpID,name,callback)
    self.ID = tmpID
    self.name:SetText(StringTable.Get(name))
    self._callback = callback
    self:SetTalePetState()
    self:PetInfoRedController()
    if not self.ID then
        return
    end
    local cfg_pet = Cfg.cfg_pet[self.ID]
    if not cfg_pet then
        return
    end
    self.firstElement = cfg_pet.FirstElement
    self.secondElement = cfg_pet.SecondElement

    self.atlas2 = self:GetAsset("Property.spriteatlas",LoadType.SpriteAtlas)
    local cfg_pet_element = Cfg.cfg_pet_element{}
    self.prop1.sprite = self.atlas2:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[self.firstElement].Icon))
    self.propObj1:SetActive(true)
    self.bg.sprite = self.atlas:GetSprite(self.NameBgSpriteName[self.firstElement])
    if self.secondElement > 0 then
        self.propObj2:SetActive(true)
        self.prop2.sprite = self.atlas2:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[self.secondElement].Icon))
    end
end

function UITalePetInfoItem:btnViewOnClick(go)
    if self._callback then
        self._callback(self.ID)
    end
end

--传说光灵的任务状态
function UITalePetInfoItem:SetTalePetState()
    self.state:SetActive(false)
    self.imgState1:SetActive(false)
    self.imgState2:SetActive(false)
    local info = self.talePetModule:GetPetInfo(self.ID)
    if info == nil then
        return
    end
    
    local selectId = self.talePetModule:SelectPetCfgId()
    if selectId == self.ID then
        self.state:SetActive(true)
        self.imgState2:SetActive(true)
        self.txtState:SetText(StringTable.Get("str_tale_pet_convening_pet"))
        return
    else
        local state = info.pet_status
        -- if state == TalePetCallType.TPCT_Invalid or state == TalePetCallType.TPCT_Pause or state == TalePetCallType.TPCT_Can_Do then
        --     --任务没开始或者任务暂停或者任务已完成可领取
        -- elseif state == TalePetCallType.TPCT_Doing then
        --     --任务进行中
        --     self.state:SetActive(true)
        --     self.imgState2:SetActive(true)
        --     self.txtState:SetText(StringTable.Get("str_tale_pet_convening_pet"))
        -- else
        if state == TalePetCallType.TPCT_Done then
            --已获得
            self.state:SetActive(true)
            self.imgState1:SetActive(true)
            self.imgState2:SetActive(true)
            self.txtState:SetText(StringTable.Get("str_tale_pet_has_get_pet"))
        end
    end
end

---------------------------------------------------红点
function UITalePetInfoItem:PetInfoRedController()
    --光灵可领取但未领取时显示
    if self.ID == self.talePetModule:SelectPetCfgId() then
        return
    end
    local state1 = self.talePetModule:IsCanCallPet(self.ID)
    local state2 = self.talePetModule:IsGetReward(self.ID)
    if state1 or state2 then
        self.petInfoRed:SetActive(true)
    else
        self.petInfoRed:SetActive(false)
    end
end
