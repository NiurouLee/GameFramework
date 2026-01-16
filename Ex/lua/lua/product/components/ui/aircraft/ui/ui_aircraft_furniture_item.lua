---@class UIAircraftFurnitureItem : UICustomWidget
_class("UIAircraftFurnitureItem", UICustomWidget)
UIAircraftFurnitureItem = UIAircraftFurnitureItem
function UIAircraftFurnitureItem:OnShow(uiParams)
    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GameLogic():GetModule(AircraftModule)
    -- ---@type UnityEngine.U2D.SpriteAtlas
    -- self._atlas = self:GetAsset("UIAircraftDecorate.spriteatlas", LoadType.SpriteAtlas)
    self:_GetComponents()
end

---@param item Item
function UIAircraftFurnitureItem:SetData(furnitureInfo)
    local item_cfg = Cfg.cfg_item {}
    local furnitureNameID = item_cfg[furnitureInfo.nAssetId].Name
    local furnitureName = StringTable.Get(furnitureNameID)
    self._name:SetText(furnitureName)
    self._num:SetText("x" .. furnitureInfo.count)
    self._addNum:SetText(furnitureInfo.baseAmbient)
    --QA:18513 不显示额外氛围
    -- self._extaAdd:SetText("(" .. "+" .. furnitureInfo.exAmbient .. ")")
end

function UIAircraftFurnitureItem:_GetComponents()
    self._name = self:GetUIComponent("Text", "Name")
    self._num = self:GetUIComponent("Text", "Num")
    self._addNum = self:GetUIComponent("Text", "AddNum")
    self._extaAdd = self:GetUIComponent("Text", "ExtaAdd")
end

function UIAircraftFurnitureItem:_OnRefresh()
    -- self._rawImageLoader:LoadImage(self._cfg_item.Icon)
    -- self._txtName:SetText(StringTable.Get(self._cfg_item.Name))
    -- --初始数值
    -- local atmosphere = self._cfg_item_furniture.Atmosphere
    -- local lfAv, lfMv = self._aircraftModule:CalCentralPetWorkSkill()
    -- local newAtmosphere = atmosphere + math.floor(atmosphere * lfMv) + math.floor(lfAv)
    -- -- self._textAtmosphere:SetText(atmosphere .. "+" .. (newAtmosphere - atmosphere))
    -- self._textAtmosphere:SetText(newAtmosphere)
    -- --摆放数量
    -- local useNum = self._aircraftModule:GetUseFurnitureItemNumByItemID(self._itemID)
    -- --剩余数量
    -- local remainsNum = self._aircraftModule:GetRemainsFurnitureItemNumByItemID(self._itemID)
    -- self._txtCount:SetText(remainsNum)
    -- --new
    -- self._newObj:SetActive(self._item:IsNewFurniture())
    -- --已配置
    -- self._alreadyObj:SetActive(useNum > 0)
    -- local useGray = false
    -- if useNum == 0 then
    --     --没有摆放的家居
    --     self._bg.sprite = self._atlas:GetSprite("home_jiaju_kuang11")
    -- else
    --     if remainsNum == 0 then
    --         --全部摆放完
    --         self._bg.sprite = self._atlas:GetSprite("home_jiaju_kuang13")
    --         if not self._EMIMatResRequest then
    --             self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset("ui_image_gray.mat", LoadType.Mat)
    --             self._EMIMat = self._EMIMatResRequest.Obj
    --         end
    --         useGray = true
    --     else
    --         --摆了  没摆完
    --         self._bg.sprite = self._atlas:GetSprite("home_jiaju_kuang12")
    --     end
    -- end
    -- if useGray then
    --     self._bgAlready.material = self._EMIMat
    --     self._bgAtmosphere.material = self._EMIMat
    --     self._rawImage.material:SetFloat("GrayScale Amount", 1)
    -- else
    --     self._bgAlready.material = nil
    --     self._bgAtmosphere.material = nil
    --     self._rawImage.material:SetFloat("GrayScale Amount", 0)
    -- end
    -- --选中
    -- self._selectObj:SetActive(false)
    -- UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._rectTransform)
end
