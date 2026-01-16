---@class UIWidgetFeatureTrapCount : UICustomWidget
_class("UIWidgetFeatureTrapCount", UICustomWidget)
UIWidgetFeatureTrapCount = UIWidgetFeatureTrapCount
function UIWidgetFeatureTrapCount:OnShow(uiParams)
    self:InitWidget()
end
function UIWidgetFeatureTrapCount:InitWidget()
    --generated--
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.GameObject
    self._offSetGo = self:GetGameObject("OffSet")

    ---@type UILocalizationText
    self._titleText = self:GetUIComponent("UILocalizationText", "Title")
    ---@type UILocalizationText
    self._countInfoText = self:GetUIComponent("UILocalizationText", "CountInfo")
    ---@type UnityEngine.UI.Image
    self._iconImage = self:GetUIComponent("Image", "Icon")
    ---@type UnityEngine.UI.Image
    self._bgImage = self:GetUIComponent("Image", "Bg")
    self:RegisterEvent()
    self._offSetGo:SetActive(false)
    --generated end--
end
function UIWidgetFeatureTrapCount:RegisterEvent()
    self:AttachEvent(GameEventType.FeatureListInit, self._OnFeatureListInit)
    self:AttachEvent(GameEventType.TrapRenderShow, self._OnTrapRenderShow)
    self:AttachEvent(GameEventType.TrapRenderDestroy, self._OnTrapRenderDestroy)
end
---@param initData FeatureEffectParamTrapCount
function UIWidgetFeatureTrapCount:SetData(initData)
    self._offSetGo:SetActive(true)
    self._initData = initData
    self._maxCount = self._initData:GetMaxCount()
    local titleStr = self._initData:GetTitleStr()
    self._targetTrapIDList = self._initData:GetTargetTrapIDList()
    local icon = self._initData:GetIcon()
    if icon then
        --self._iconImage.sprite =  self._uiAtlas:GetSprite(icon)
    end
    self._titleText:SetText(StringTable.Get(titleStr))
    self._count = 0
    self:_RefreshCount()
end
function UIWidgetFeatureTrapCount:_RefreshCount()
    local uiCount = self._count
    if uiCount > self._maxCount then
        uiCount = self._maxCount
    end
    if uiCount < 0 then
        uiCount = 0
    end
    local countStr = nil
    if uiCount == self._maxCount then
        self._bgImage.sprite = self._uiAtlas:GetSprite("thread_ztz_di02")
        countStr = "(" ..  tostring(uiCount) .. "/" .. tostring(self._maxCount) .. ")"
    else
        self._bgImage.sprite = self._uiAtlas:GetSprite("thread_ztz_di01")
        local strCurCount = "<color=#561804>" .. tostring(uiCount) .. "</color>"
        countStr = "(" .. strCurCount .. "/" .. tostring(self._maxCount) .. ")"
    end
    self._countInfoText:SetText(countStr)
end
---模块列表初始化
function UIWidgetFeatureTrapCount:_OnFeatureListInit(featureListInfo)
    if self._initData then
        return
    end
    if featureListInfo then
        --昼夜模块ui独立
        for i,v in ipairs(featureListInfo) do
            local featureType = v:GetFeatureType()
            if featureType == FeatureType.TrapCount then--昼夜
                ---@type UIWidgetFeatureTrapCount
                self:SetData(v)
                break
            end
        end
    end
end
function UIWidgetFeatureTrapCount:_OnTrapRenderShow(trapID)
    if table.icontains(self._targetTrapIDList,trapID) then
        self._count = self._count + 1
        self:_RefreshCount()
    end
end
function UIWidgetFeatureTrapCount:_OnTrapRenderDestroy(trapID)
    if table.icontains(self._targetTrapIDList,trapID) then
        self._count = self._count - 1
        if self._count < 0 then
            self._count = 0
        end
        self:_RefreshCount()
    end
end