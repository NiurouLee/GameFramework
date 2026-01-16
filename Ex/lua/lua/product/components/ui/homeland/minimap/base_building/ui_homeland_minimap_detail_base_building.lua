---@class UIHomelandMinimapDetailBaseBuilding:UIHomelandMinimapDetailBase
_class("UIHomelandMinimapDetailBaseBuilding", UIHomelandMinimapDetailBase)
UIHomelandMinimapDetailBaseBuilding = UIHomelandMinimapDetailBaseBuilding
function UIHomelandMinimapDetailBaseBuilding:OnShow()
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "NameTxt")
    ---@type RawImageLoader
    self.imgIcon = self:GetUIComponent("RawImageLoader", "Skin")
    ---@type UILocalizationText
    self.txtSkin = self:GetUIComponent("UILocalizationText", "ContentTxt")
    ---@type UICustomWidgetPool
    self.Content = self:GetUIComponent("UISelectObjectPath", "Content")
end
function UIHomelandMinimapDetailBaseBuilding:OnClose()
    UIHomelandMinimapDetailBaseBuilding.super.OnClose(self)
    self.imgIcon:DestoryLastImage()
end

--初始化完成回调
function UIHomelandMinimapDetailBaseBuilding:OnInitDone()
    self:Init()
    self:Flush()
end

function UIHomelandMinimapDetailBaseBuilding:Init()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetForgeData()
    self.data:Init(self.mHomeland:GetHomelandInfo())
end

function UIHomelandMinimapDetailBaseBuilding:Flush()
    self:FlushBuilding()
    self:FlushSequence()
end
function UIHomelandMinimapDetailBaseBuilding:FlushBuilding()
    local iconData = self:GetIconData()
    if not iconData then
        return
    end
    ---@type HomeBuilding
    local building = iconData:GetParam()
    local skinId = building:SkinID()
    local cfg_item_architecture_skin = Cfg.cfg_item_architecture_skin[skinId]
    self.txtName:SetText(StringTable.Get(cfg_item_architecture_skin.SkinName))
    self.imgIcon:LoadImage(cfg_item_architecture_skin.SkinIcon)
    self.txtSkin:SetText(StringTable.Get(cfg_item_architecture_skin.Des))
    -- self.imgIcon:LoadImage(cfg_item_architecture_skin.SkinIcon)

    ---@type UnityEngine.RectTransform
    self._titleRect = self:GetUIComponent("RectTransform", "Title")
    if self._titleRect then
        local titleWidth = self.txtName.preferredWidth
        if titleWidth > 350 then
            titleWidth = 350
        end
        self._titleRect.sizeDelta = Vector2(titleWidth,self._titleRect.sizeDelta.y)
    end
end
function UIHomelandMinimapDetailBaseBuilding:FlushSequence()
    if not self.data then
        return
    end
    local len = table.count(self.data.sequnces)
    self.Content:SpawnObjects("UIHomelandMinimapDetailBaseBuildingItem", len)
    ---@type UIHomelandMinimapDetailBaseBuildingItem[]
    local uis = self.Content:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        ui:Flush(self.data.sequnces[i].index)
    end
end

function UIHomelandMinimapDetailBaseBuilding:ExitOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailBaseBuilding:BtnBGOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapCloseDetailUI)
    self:OnClose()
end

function UIHomelandMinimapDetailBaseBuilding:GetCloseAnimtionName()
    return "UIHomelandMinimapDetailBaseBuilding_out"
end
