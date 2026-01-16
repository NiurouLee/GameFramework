---@class UIHomelandMinimapDetailCommonBuild:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailCommonBuild", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailCommonBuild = UIHomelandMinimapDetailCommonBuild

function UIHomelandMinimapDetailCommonBuild:OnShow(uiParams)
    ---@type UnityEngine.GameObject
    self._museumIcon = self:GetGameObject("MuseumIcon")
    ---@type UnityEngine.GameObject
    self._wishingPoolIcon = self:GetGameObject("WishingPoolIcon")
    ---@type UnityEngine.GameObject
    self._storageBoxIcon = self:GetGameObject("StorageBoxIcon")
    ---@type UnityEngine.GameObject
    self._albumIcon = self:GetGameObject("AlbumIcon")
    ---@type UnityEngine.GameObject
    self._medalWallIcon = self:GetGameObject("MedalWallIcon")

    ---@type UILocalizationText
    self._nameTxt = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type UILocalizationText
    self._commonContentTxt = self:GetUIComponent("UILocalizationText", "ContentTxt")
    ---@type RawImageLoader
    self._skinRawImageLoader = self:GetUIComponent("RawImageLoader", "Skin")
end

--初始化完成回调
function UIHomelandMinimapDetailCommonBuild:OnInitDone()
    ---@type HomeBuilding
    local building = self:GetIconData():GetParam()
    local skinID = building:SkinID()
    local cfgSkin = Cfg.cfg_item_architecture_skin[skinID]
    
    if cfgSkin then
        self._nameTxt:SetText(StringTable.Get(cfgSkin.SkinName))
        self._commonContentTxt:SetText(StringTable.Get(cfgSkin.Des))
        self._skinRawImageLoader:LoadImage(cfgSkin.SkinIcon)
    else
        local itemID = building:GetBuildId()
        local cfg = Cfg.cfg_item[itemID]
        self._nameTxt:SetText(StringTable.Get(cfg.Name))
        self._commonContentTxt:SetText(StringTable.Get(cfg.Intro))
        self._skinRawImageLoader:LoadImage(cfg.Icon)
    end
    
    if building:GetBuildType() == ArchitectureSubType.Museum then
        self._museumIcon:SetActive(true)
    elseif building:GetBuildType() == ArchitectureSubType.Wishing_Pool then
        self._wishingPoolIcon:SetActive(true)
    elseif building:GetBuildType() == ArchitectureSubType.Storage_Box then
        self._storageBoxIcon:SetActive(true)
    elseif building:GetBuildType() == ArchitectureSubType.Album then
        self._albumIcon:SetActive(true)
    elseif building:GetBuildType() == ArchitectureSubType.Medal_Wall then
        self._medalWallIcon:SetActive(true)
    end

    ---@type UnityEngine.RectTransform
    self._titleRect = self:GetUIComponent("RectTransform", "Title")
    if self._titleRect then
        local titleWidth = self._nameTxt.preferredWidth
        if titleWidth > 350 then
            titleWidth = 350
        end
        self._titleRect.sizeDelta = Vector2(titleWidth,self._titleRect.sizeDelta.y)
    end
end

function UIHomelandMinimapDetailCommonBuild:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailCommonBuild:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailCommonBuild:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailCommonBuild_out"
end
