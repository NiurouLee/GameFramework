--
---@class UIHomelandMinimapDetailBreedLand : UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailBreedLand", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailBreedLand = UIHomelandMinimapDetailBreedLand

function UIHomelandMinimapDetailBreedLand:Constructor()
    ---@type SvrTimeModule
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    self._atlas = self:GetAsset("UIHomelandMap.spriteatlas", LoadType.SpriteAtlas)
end

--初始化
function UIHomelandMinimapDetailBreedLand:OnShow(uiParams)
    self:_GetComponents()
end
--获取ui组件
function UIHomelandMinimapDetailBreedLand:_GetComponents()
    ---@type UILocalizationText
    self._titleText = self:GetUIComponent("UILocalizationText", "TitleText")
    self._titleRectTransform = self._titleText.transform.parent:GetComponent("RectTransform")
    ---@type UILocalizationText
    self._descriptionText = self:GetUIComponent("UILocalizationText", "DescriptionText")
    ---@type RawImageLoader
    self._breedIcon = self:GetUIComponent("RawImageLoader", "BreedIcon")
    ---@type UILocalizationText
    self._name = self:GetUIComponent("UILocalizationText", "Name")
    ---@type UILocalizationText
    self._stateText = self:GetUIComponent("UILocalizationText", "StateText")
    self._stateImg = self:GetUIComponent("Image", "StateImg")
    self._stateImgObj = self:GetGameObject("StateImg")
end

--关闭按钮点击
function UIHomelandMinimapDetailBreedLand:CloseBtnOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

--确定按钮点击
function UIHomelandMinimapDetailBreedLand:ConfirmBtnOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

--初始化完成回调
function UIHomelandMinimapDetailBreedLand:OnInitDone()
    ---@type HomelandBreedLand
    local breedLand = self._iconData:GetParam()
    local itemID = breedLand:GetBuildId()
    local cfg = Cfg.cfg_item[itemID]
    self._titleText:SetText(StringTable.Get(cfg.Name))
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._titleRectTransform)
    self._descriptionText:SetText(StringTable.Get(cfg.Intro))
    local curPhases = breedLand:GetCurPhases()
    local breedIcon = cfg.Icon
    local name = StringTable.Get("str_homeland_minimap_freeland")
    local state = StringTable.Get("str_homeland_minimap_freestate")
    local color = Color(167 / 255, 168 / 255, 168 / 255)
    local spriteName = nil
    local cfgTree = breedLand:GetCurTree()
    if cfgTree then
        local cfgItem = Cfg.cfg_item[cfgTree.ID]
        if cfgItem then
            if curPhases > 0 and curPhases <= 2 then
                name = StringTable.Get("str_homeland_exp_source_2")
            end
            if curPhases >= 3 then
                name = StringTable.Get(cfgItem.Name)
                breedIcon = cfgItem.Icon
            end
        end
    end
    if curPhases > 0 then
        local remainTime = breedLand:GetRemainTime()
        if remainTime > 0 then
            color = Color(128 / 255, 188 / 255, 89 / 255)
            spriteName = "n17_dt_ppdk_time"
            state = HomelandBreedTool.GetRemainTime(remainTime)
            state = StringTable.Get("str_homeland_minimap_remain_time", state)
        else
            spriteName = "n17_dt_ppdk_goux"
            color = Color(250 / 255, 170 / 255, 40 / 255)
            state = StringTable.Get("str_homeland_minimap_reapstate")
        end
    end
    self._breedIcon:LoadImage(breedIcon)
    self._name:SetText(name)
    self._stateText:SetText(state)
    self._stateText.color = color
    if spriteName then
        spriteName = self._atlas:GetSprite(spriteName)
    end
    self._stateImg.sprite = spriteName
    self._stateImgObj:SetActive(spriteName ~= nil)

    ---@type UnityEngine.RectTransform
    self._titleRect = self:GetUIComponent("RectTransform", "Title")
    if self._titleRect then
        local titleWidth = self._titleText.preferredWidth
        if titleWidth > 350 then
            titleWidth = 350
        end
        self._titleRect.sizeDelta = Vector2(titleWidth,self._titleRect.sizeDelta.y)
    end
end

function UIHomelandMinimapDetailBreedLand:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailBreedLand_out"
end
