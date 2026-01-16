--- @class EUIActiveTaskMainContentState
local UIActivityPetEnhanceAreaUIStyle = {
    N32_NORMAL = 1,
    N32_HARD = 2,
    N32_MULTI_LINE = 3,
}
_enum("UIActivityPetEnhanceAreaUIStyle", UIActivityPetEnhanceAreaUIStyle)

---@class UIActivityPetEnhanceAreaWidget : UICustomWidget
_class("UIActivityPetEnhanceAreaWidget", UICustomWidget)
UIActivityPetEnhanceAreaWidget = UIActivityPetEnhanceAreaWidget
function UIActivityPetEnhanceAreaWidget:OnShow(uiParams)
    self:InitWidget()
end
function UIActivityPetEnhanceAreaWidget:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.petListGen = self:GetUIComponent("UISelectObjectPath", "PetListArea")
    ---@type UILocalizationText
    self.detailInfoText = self:GetUIComponent("UILocalizationText", "DetailInfo")
    self.detailValueText = self:GetUIComponent("UILocalizationText", "DetailValue")
    self.detailBtnTitleText = self:GetUIComponent("UILocalizationText", "DetailBtnTitle")
    self.detailInfoAreaGo = self:GetGameObject("DetailInfoArea")
    self.areaBgLoader = self:GetUIComponent("RawImageLoader", "AreaBg")
    self:_AttachEvents()
end
function UIActivityPetEnhanceAreaWidget:_AttachEvents()
    self:AttachEvent(GameEventType.ClosePetEnhanceTips, self._ClosePetEnhanceTips)

end
function UIActivityPetEnhanceAreaWidget:SetData(componentId,uiStyle)
    uiStyle = uiStyle or UIActivityPetEnhanceAreaUIStyle.N32_NORMAL
    if uiStyle == UIActivityPetEnhanceAreaUIStyle.N32_NORMAL
        or uiStyle == UIActivityPetEnhanceAreaUIStyle.N32_MULTI_LINE
     then
        self.areaBgLoader:LoadImage("n32hd_glycxz_di03")
        self.detailBtnTitleText.color = Color(97 / 255, 62 / 255, 6 / 255, 1)
    elseif uiStyle == UIActivityPetEnhanceAreaUIStyle.N32_HARD then
        self.areaBgLoader:LoadImage("n32hd_glycxz_di04")
        self.detailBtnTitleText.color = Color(70 / 255, 70 / 255, 72 / 255, 1)
    end
    local cfgGroup = Cfg.cfg_campaign_mission_pet_correct{ComponentID=componentId}
    if cfgGroup and #cfgGroup > 0 then
        local maxShowCount = 3
        local cfgCount = #cfgGroup
        local showCount = 3--固定3个，没有数据则显示空图
        self.petListGen:SpawnObjects("UIActivityPetEnhancePetItem",showCount)
        local petItems = self.petListGen:GetAllSpawnList()
        for i = 1, showCount do
            local cfg = cfgGroup[i]
            petItems[i]:InitByCfg(cfg)
        end
        local baseCfg = cfgGroup[1]
        local descStr = StringTable.Get("str_activity_pet_enhance_tips")
        self.detailInfoText:SetText(descStr)
        -- local lvStr = StringTable.Get("str_pet_config_common_advance") .. baseCfg.GradeLv .. " LV." .. baseCfg.Level

        -- local valueStr = ""
        -- valueStr = valueStr .. "-" .. StringTable.Get("str_pet_config_btn_level") .. " ≥ <color=#faba3c>" .. lvStr .. "</color>"
        -- valueStr = valueStr .. "\n"
        -- valueStr = valueStr .. "-" .. StringTable.Get("str_pet_config_common_equip") .. " ≥ <color=#faba3c>" .. " LV." .. baseCfg.EquipLv .. "</color>"
        -- valueStr = valueStr .. "\n"
        -- valueStr = valueStr .. "-" .. StringTable.Get("str_pet_config_break_title") .. " ≥ <color=#faba3c>" .. baseCfg.AwakeningLv .. "</color>"
        -- valueStr = valueStr .. "\n"
        -- valueStr = valueStr .. "-" .. StringTable.Get("str_pet_equip_refine") .. " ≥ <color=#faba3c>" .. baseCfg.EquipRefineLv .. "</color>"
        -- valueStr = valueStr .. "\n"
        local valueStr = StringTable.Get("str_activity_pet_enhance_detail_tips",baseCfg.GradeLv,baseCfg.Level,baseCfg.EquipLv,baseCfg.AwakeningLv,baseCfg.EquipRefineLv)
        self.detailValueText:SetText(valueStr)
    else
        local showCount = 3--固定3个，没有数据则显示空图
        self.petListGen:SpawnObjects("UIActivityPetEnhancePetItem",showCount)
        local petItems = self.petListGen:GetAllSpawnList()
        for i = 1, showCount do
            petItems[i]:InitByCfg(nil)
        end
    end
    
end
function UIActivityPetEnhanceAreaWidget:DetailBtnOnClick(go)
    self.detailInfoAreaGo:SetActive(true)
end
function UIActivityPetEnhanceAreaWidget:ClostTipsBtnOnClick(go)
    self.detailInfoAreaGo:SetActive(false)
end
function UIActivityPetEnhanceAreaWidget:_ClosePetEnhanceTips()
    self.detailInfoAreaGo:SetActive(false)
end