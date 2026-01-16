---@class UIAircraftDecorateItem : UICustomWidget
_class("UIAircraftDecorateItem", UICustomWidget)
UIAircraftDecorateItem = UIAircraftDecorateItem
function UIAircraftDecorateItem:OnShow(uiParams)
    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GameLogic():GetModule(AircraftModule)
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIAircraftDecorate.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvent(GameEventType.UIAircraftDecorateSelectItem, self._OnUIAircraftDecorateSelectItem)
    self:AttachEvent(GameEventType.UIAircraftDecoratePutFurniture, self._OnUIAircraftDecoratePutFurniture)
end

---@param item Item
function UIAircraftDecorateItem:SetData(index, item, getCallback)
    self:_GetComponents()

    ---@type Item
    self._item = item
    self._itemID = self._item:GetTemplateID()
    --道具表
    self._cfg_item = Cfg.cfg_item[self._itemID]
    --道具家居表
    self._cfg_item_furniture = Cfg.cfg_item_furniture[self._itemID]
    self._index = index
    self._getCallback = getCallback

    self:_OnRefresh()
end

function UIAircraftDecorateItem:_GetComponents()
    self._rectTransform = self:GetUIComponent("RectTransform", "Root")
    self._selectObj = self:GetGameObject("Select")
    self._alreadyObj = self:GetGameObject("Already")
    self._newObj = self:GetGameObject("New")
    self._rawImageLoader = self:GetUIComponent("RawImageLoader", "RawImage")
    self._rawImage = self:GetUIComponent("RawImage", "RawImage")
    self._rawImageObj = self:GetGameObject("RawImage")
    self._txtCount = self:GetUIComponent("UILocalizationText", "TextCount")
    self._textAtmosphere = self:GetUIComponent("UILocalizationText", "TextAtmosphere")
    self._txtName = self:GetUIComponent("RollingText", "TextName")
    self._bg = self:GetUIComponent("Image", "BG")
    self._bgAtmosphere = self:GetUIComponent("Image", "BGAtmosphere")
    self._bgAlready = self:GetUIComponent("Image", "BGAlready")
end

function UIAircraftDecorateItem:_OnRefresh()
    self._rawImageLoader:LoadImage(self._cfg_item.Icon)
    self._txtName:RefreshText(StringTable.Get(self._cfg_item.Name))

    --初始数值
    local atmosphere = self._cfg_item_furniture.Atmosphere
    local lfAv, lfMv = self._aircraftModule:CalCentralPetWorkSkill()
    local newAtmosphere = atmosphere + math.floor(atmosphere * lfMv) + math.floor(lfAv)
    -- self._textAtmosphere:SetText(atmosphere .. "+" .. (newAtmosphere - atmosphere))
    self._textAtmosphere:SetText(newAtmosphere)

    --摆放数量
    local useNum = self._aircraftModule:GetUseFurnitureItemNumByItemID(self._itemID)
    --剩余数量
    local remainsNum = self._aircraftModule:GetRemainsFurnitureItemNumByItemID(self._itemID)

    self._txtCount:SetText(remainsNum)

    --new
    self._newObj:SetActive(self._item:IsNewFurniture())

    --QA18516
    --已配置
    -- self._alreadyObj:SetActive(useNum > 0)
    self._alreadyObj:SetActive(false)

    local useGray = false
    if useNum == 0 then
        --没有摆放的家居
        self._bg.sprite = self._atlas:GetSprite("home_jiaju_kuang11")
    else
        if remainsNum == 0 then
            --全部摆放完
            self._bg.sprite = self._atlas:GetSprite("home_jiaju_kuang13")

            if not self._EMIMatResRequest then
                self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset("ui_image_gray.mat", LoadType.Mat)
                self._EMIMat = self._EMIMatResRequest.Obj
            end
            useGray = true
        else
            --摆了  没摆完
            self._bg.sprite = self._atlas:GetSprite("home_jiaju_kuang12")
        end
    end

    if useGray then
        self._bgAlready.material = self._EMIMat
        self._bgAtmosphere.material = self._EMIMat
        self._rawImage.material:SetFloat("_LuminosityAmount", 1)
    else
        self._bgAlready.material = nil
        self._bgAtmosphere.material = nil
        self._rawImage.material:SetFloat("_LuminosityAmount", 0)
    end

    self._rawImageObj:SetActive(false)
    self._rawImageObj:SetActive(true)

    --选中
    self._selectObj:SetActive(false)

    -- UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._rectTransform)
end

---刷新选中状态
function UIAircraftDecorateItem:_OnUIAircraftDecorateSelectItem(item)
    self._selectObj:SetActive(self._itemID == item:GetTemplateID())
end

---摆放家居
function UIAircraftDecorateItem:_OnUIAircraftDecoratePutFurniture(itemID)
    --数量
    --摆放
end

function UIAircraftDecorateItem:BGOnClick()
    --UI先去掉New，异步发送消息给服务器，取消玩家身上New的数据
    self._newObj:SetActive(false)

    if self._getCallback then
        self._getCallback(self._item)
    end
end

--引导用
function UIAircraftDecorateItem:GetBG()
    return self:GetGameObject("BG")
end
