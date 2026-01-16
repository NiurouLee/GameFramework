--[[
    抽卡星灵信息加载器，支持3种样式的控件，逻辑一样
]]
---@class UIDrawCardPetInfoLoader:UICustomWidget
_class("UIDrawCardPetInfoLoader", UICustomWidget)
UIDrawCardPetInfoLoader = UIDrawCardPetInfoLoader

function UIDrawCardPetInfoLoader:OnShow()
    self._prefabs = {
        [1] = "UIDrawCardPetInfoItem1.prefab",
        [2] = "UIDrawCardPetInfoItem2.prefab",
        [3] = "UIDrawCardPetInfoItem3.prefab",
        [4] = "UIDrawCardPetInfoItem2.prefab",
        [5] = "UIDrawCardPetInfoItem3.prefab",
        [6] = "UIDrawCardPetInfoItem4.prefab",
        [7] = "UIDrawCardPetInfoItem5.prefab"
    }

    ---@type UICustomWidgetPool
    self._loader = self:GetUIComponent("UISelectObjectPath", "loader")
end

function UIDrawCardPetInfoLoader:SetData(tmpID, cfg, callback)
    local type = cfg.type
    if self._type ~= type then
        self:Clear()
        self._req = ResourceManager:GetInstance():SyncLoadAsset(self._prefabs[type], LoadType.GameObject)
        local t = self._req.Obj.transform
        t:SetParent(self:GetGameObject().transform)
        t.localPosition = Vector3.zero
        t.localRotation = Quaternion.identity
        t.localScale = Vector3.one
        self._req.Obj:SetActive(true)
        ---@type UIDrawCardPetInfoItem
        self._widget = UIDrawCardPetInfoItem:New(self._req.Obj)
        self._type = type
    end

    self._widget:SetData(tmpID, cfg, callback)
end

function UIDrawCardPetInfoLoader:Clear()
    if self._req then
        self._req:Dispose()
        self._req = nil
    end
    if self._widget then
        self._widget:Dispose()
        self._widget = nil
    end
end

function UIDrawCardPetInfoLoader:OnHide()
    self:Clear()
end
