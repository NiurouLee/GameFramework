---@class UIWidgetFeatureList : UICustomWidget
_class("UIWidgetFeatureList", UICustomWidget)
UIWidgetFeatureList = UIWidgetFeatureList
function UIWidgetFeatureList:OnShow(uiParams)
    self:InitWidget()
end
function UIWidgetFeatureList:InitWidget()
    self._defaultShowCount = 2
    self._inited = false
    --generated--
    ---@type UnityEngine.GameObject
    self._grd = self:GetGameObject("grd")
    ---@type UnityEngine.GameObject
    self._showHideArea = self:GetGameObject("ShowHideArea")
    ---@type UnityEngine.UI.Image
    self._imgHide = self:GetUIComponent("Image", "ImgHide")
    self._imgHideGo = self:GetGameObject("ImgHide")

    ---@type UnityEngine.UI.Image
    self._imgShow = self:GetUIComponent("Image", "ImgShow")
    self._imgShowGo = self:GetGameObject("ImgShow")


    self:RegisterEvent()

    self._featureGenDic = {}
    self._featureGoDic = {}
    self._featureWidgetNameDic = {}
    self._featureWidgetDic = {}

    self._featureGenDic[FeatureType.Sanity] = self:GetUIComponent("UISelectObjectPath", "FeatureSan")
    self._featureGoDic[FeatureType.Sanity] = self:GetGameObject("FeatureSan")
    self._featureWidgetNameDic[FeatureType.Sanity] = "UIWidgetFeatureSan"

    self._featureGenDic[FeatureType.PersonaSkill] = self:GetUIComponent("UISelectObjectPath", "FeaturePersonaSkill")
    self._featureGoDic[FeatureType.PersonaSkill] = self:GetGameObject("FeaturePersonaSkill")
    self._featureWidgetNameDic[FeatureType.PersonaSkill] = "UIWidgetFeaturePersonaSkill"

    self._featureGenDic[FeatureType.Card] = self:GetUIComponent("UISelectObjectPath", "FeatureCard")
    self._featureGoDic[FeatureType.Card] = self:GetGameObject("FeatureCard")
    self._featureWidgetNameDic[FeatureType.Card] = "UIWidgetFeatureCard"

    self._featureGenDic[FeatureType.MasterSkill] = self:GetUIComponent("UISelectObjectPath", "FeatureMasterSkill")
    self._featureGoDic[FeatureType.MasterSkill] = self:GetGameObject("FeatureMasterSkill")
    self._featureWidgetNameDic[FeatureType.MasterSkill] = "UIWidgetFeatureMasterSkill"

    self._featureGenDic[FeatureType.Scan] = self:GetUIComponent("UISelectObjectPath", "FeatureScan")
    self._featureGoDic[FeatureType.Scan] = self:GetGameObject("FeatureScan")
    self._featureWidgetNameDic[FeatureType.Scan] = "UIWidgetFeatureScan"

    self._featureGenDic[FeatureType.MasterSkillRecover] = self:GetUIComponent("UISelectObjectPath", "FeatureMasterSkillRecover")
    self._featureGoDic[FeatureType.MasterSkillRecover] = self:GetGameObject("FeatureMasterSkillRecover")
    self._featureWidgetNameDic[FeatureType.MasterSkillRecover] = "UIWidgetFeatureMasterSkillRecover"

    self._featureGenDic[FeatureType.MasterSkillTeleport] = self:GetUIComponent("UISelectObjectPath", "FeatureMasterSkillTeleport")
    self._featureGoDic[FeatureType.MasterSkillTeleport] = self:GetGameObject("FeatureMasterSkillTeleport")
    self._featureWidgetNameDic[FeatureType.MasterSkillTeleport] = "UIWidgetFeatureMasterSkillTeleport"

    self._featureGenDic[FeatureType.PopStar] = self:GetUIComponent("UISelectObjectPath", "FeaturePopStar")
    self._featureGoDic[FeatureType.PopStar] = self:GetGameObject("FeaturePopStar")
    self._featureWidgetNameDic[FeatureType.PopStar] = "UIWidgetFeaturePopStar"

    --generated end--
end
function UIWidgetFeatureList:RegisterEvent()
    self:AttachEvent(GameEventType.FeatureListInit, self._OnFeatureListInit)
    --self:AttachEvent(GameEventType.UIPersonaSkillInfoShow, self._OnUIPersonaSkillInfoShow)
    self:AttachEvent(GameEventType.UIFeatureSkillInfoShow, self._OnUIFeatureSkillInfoShow)
    self:AttachEvent(GameEventType.UISwitchActiveSkillUI, self.OnSwitchActiveSkillUI)
    self:AttachEvent(GameEventType.UIPetClickToSwitch, self.OnSwitchActiveSkillUI)
end
---模块列表初始化
function UIWidgetFeatureList:_OnFeatureListInit(featureListInfo)
    if featureListInfo then
        --昼夜模块ui独立
        self:SetData(featureListInfo)
    end
end
--
-- function UIWidgetFeatureList:_OnUIPersonaSkillInfoShow(show)
--     if show then
--         self._imgShowGo:SetActive(false)
--         self._imgHideGo:SetActive(false)
--         for key,featureGo in pairs(self._featureGoDic) do
--             if key ~= FeatureType.PersonaSkill then
--                 featureGo:SetActive(false)
--             end
--         end
--     else
--         self:_RefreshArrowState()
--         self:_RefreshFeatureGoState()
--     end
-- end
function UIWidgetFeatureList:_OnUIFeatureSkillInfoShow(show,featureType)
    local needShowToFirst = true
    if featureType == FeatureType.Card then
        needShowToFirst = false
    end
    if show then
        if needShowToFirst then
            self._imgShowGo:SetActive(false)
            self._imgHideGo:SetActive(false)
            for key,featureGo in pairs(self._featureGoDic) do
                if key ~= featureType then
                    featureGo:SetActive(false)
                end
            end
        end
    else
        self:_RefreshArrowState()
        self:_RefreshFeatureGoState()
    end
end
function UIWidgetFeatureList:SetUIBattle(uiBattle)
    self._uiBattle = uiBattle
end
function UIWidgetFeatureList:GetUIBattle()
    return self._uiBattle
end
function UIWidgetFeatureList:GetFeatureEnterCustomPrefab(featureType,featureData)
    if featureType == FeatureType.Card then
        if featureData then
            local uiType = featureData:GetUiType()
            if uiType then--杰诺时装修改ui
                if uiType == FeatureCardUiType.Skin1 then
                    return "UIWidgetFeatureCard_l.prefab"
                end
            end
        end
    elseif featureType == FeatureType.MasterSkill then
        if featureData then
            local uiType = featureData:GetUiType()
            if uiType then
                if uiType == FeatureMasterSkillUiType.TypeSeason then
                    return "UIWidgetFeatureMasterSkillSeason.prefab"
                end
            end
        end
    end
    return
end
function UIWidgetFeatureList:GetFeatureEnterCustomWidgetName(featureType,featureData)
    if featureType == FeatureType.Card then
        if featureData then
            local uiType = featureData:GetUiType()
            if uiType then--杰诺时装修改ui
                if uiType == FeatureCardUiType.Skin1 then
                    return "UIWidgetFeatureCard_L"
                end
            end
        end
    end
    return
end
function UIWidgetFeatureList:SetData(featureListInfo)
    if featureListInfo then
        local featureCount = 0
        local featureGoList = {}
        local layoutList = {}
        for i,v in ipairs(featureListInfo) do
            local featureType = v:GetFeatureType()
            if self._featureGoDic[featureType] and self._featureGenDic[featureType] then
                if not self._featureWidgetDic[featureType] then--伙伴 可能中途加入 重发通知
                    ---@type UICustomWidgetPool
                    local sop = self._featureGenDic[featureType]
                    local customPrefabPath = self:GetFeatureEnterCustomPrefab(featureType,v)
                    if customPrefabPath then
                        sop:Engine():SetObjectName(customPrefabPath)
                    end
                    local widgetName = self._featureWidgetNameDic[featureType]
                    local customWidgetName = self:GetFeatureEnterCustomWidgetName(featureType,v)
                    if customWidgetName then
                        widgetName = customWidgetName
                    end
                    local widget = sop:SpawnObject(widgetName)
                    self._featureWidgetDic[featureType] = widget
                    if widget.SetUIBattle then
                        widget:SetUIBattle(self:GetUIBattle())
                    end
                    widget:SetData(v)
                end
                if featureType ~= FeatureType.DayNight 
                    and featureType ~= FeatureType.TrapCount
                then--昼夜的ui不在这里
                    featureCount = featureCount + 1
                end

                local featureConfigGroup = Cfg.cfg_feature{FeatureType=featureType}
                if featureConfigGroup and #featureConfigGroup > 0 then
                    local featureCfg = featureConfigGroup[1]
                    local layoutOrder = featureCfg.LayoutOrder
                    if layoutOrder then
                        table.insert(layoutList,{type=featureType,order=layoutOrder})
                    end
                end
            end
        end
        local cmptFunc = function(a,b)
            return a.order < b.order
        end
        table.sort(layoutList,cmptFunc)
        local siblingIndex = 1
        for i,v in ipairs(layoutList) do
            self._featureGoDic[v.type].transform:SetSiblingIndex(siblingIndex)
            siblingIndex = siblingIndex + 1
            table.insert(featureGoList,self._featureGoDic[v.type])
        end
        for index,featureGo in ipairs(featureGoList) do
            if self._bOpenList or (index <= self._defaultShowCount) then
                featureGo:SetActive(true)
            end
        end
        -- if #featureGoList > 0 then
        --     featureGoList[1]:SetActive(true)
        -- end
        self._featureGoList = featureGoList
        if (not self._inited) or (not self._bOpenList) then
            local bShowArrow = (featureCount > self._defaultShowCount)--1个以上显示箭头
            self._showHideArea:SetActive(bShowArrow)
            self._bOpenList = false
            if bShowArrow then
                self:_RefreshArrowState()
            end
        end
        
        self._inited = true
    end
end
function UIWidgetFeatureList:_RefreshArrowState()
    self._imgShowGo:SetActive(not self._bOpenList)
    self._imgHideGo:SetActive(self._bOpenList)
end
function UIWidgetFeatureList:ImgHideOnClick(go)
    self._bOpenList = false
    self:_RefreshArrowState()
    self:_RefreshFeatureGoState()
end
function UIWidgetFeatureList:ImgShowOnClick(go)
    self._bOpenList = true
    self:_RefreshArrowState()
    self:_RefreshFeatureGoState()
end

function UIWidgetFeatureList:_RefreshFeatureGoState()
    if self._featureGoList then
        for i,go in ipairs(self._featureGoList) do
            if self._bOpenList then
                go:SetActive(true)
            else
                if i <= self._defaultShowCount then
                    go:SetActive(true)
                else
                    go:SetActive(false)
                end
            end
        end
    end
end
function UIWidgetFeatureList:OnSwitchActiveSkillUI()
    if self._featureWidgetDic then
        for k,widget in pairs(self._featureWidgetDic) do
            if widget.OnSwitchActiveSkillUI then
                widget:OnSwitchActiveSkillUI()
            end
        end
        -- local widget = self._featureWidgetDic[FeatureType.PersonaSkill]
        -- if widget then
        --     widget:OnSwitchActiveSkillUI()
        -- end
    end
end
function UIWidgetFeatureList:OnChooseTargetConfirm()
    if self._featureWidgetDic then
        for k,widget in pairs(self._featureWidgetDic) do
            if widget.OnChooseTargetConfirm then
                widget:OnChooseTargetConfirm()
            end
        end
        -- local widget = self._featureWidgetDic[FeatureType.PersonaSkill]
        -- if widget then
        --     widget:OnChooseTargetConfirm()
        -- end
    end
end