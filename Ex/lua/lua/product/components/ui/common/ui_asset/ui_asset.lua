require("ui_asset_config")
---@class UIAsset:UICustomWidget
_class("UIAsset", UICustomWidget)
UIAsset = UIAsset

function UIAsset:OnShow()
    self._componentRoot = nil
    self._disableRoot = nil
    
    self._uiCommonAtlas = self:RootUIOwner():GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
    self._iconObj = self:GetGameObject("icon")
    self._txt = self:GetUIComponent("UILocalizationText", "txt")
    self._txtObj = self:GetGameObject("txt")
    self._quality = self:GetUIComponent("Image", "quality")
    self._qualityObj = self:GetGameObject("quality")
    self._bg = self:GetUIComponent("Image", "bg")
    self._bgObj = self:GetGameObject("quality")
    self._transform = self:GetGameObject().transform
    self._componentRoot = self:GetGameObject("Components").transform
end

function UIAsset:OnHide()

end

function UIAsset:ComponentRoot()
    return self._componentRoot
end

function UIAsset:SetBgImage(bImage)
    if bImage then
        self._bg.sprite = self._uiCommonAtlas:GetSprite("spirit_dikuang10_frame")
    else
        self._bg.sprite = self._uiCommonAtlas:GetSprite("spirit_dikuang1_frame")
    end
end

function UIAsset:SetData(itemId, scale)
    if self._id then
        --复用
        self:_RemoveAllComponent() --考虑复用的时候id没变可以不移除所有组件
    else
        --初次设置
        self._id = itemId
        ---@type UIAssetComponentBase[] 数组
        self._components = {}
        ---@type table<string, UIAssetComponentBase>
        self._disableComponent = {}
    end
end

function UIAsset:SetItemData(param)
    param = param or {}
    --背景图
    self._bgObj:SetActive(param.showBG)
    --图标
    if param.icon then
        self._icon:LoadImage(param.icon)
        self._iconObj:SetActive(true)
    else
        self._iconObj:SetActive(false)
    end
    --文本
    if param.text then
        if type(param.text) == "number" then
            local num = param.text
            self._txt:SetText(HelperProxy:GetInstance():FormatItemCount(num))
        elseif type(param.text) == "string" then
            self._txt:SetText(param.text)
        end
        self._txtObj:SetActive(true)
    else
        self._txtObj:SetActive(false)
    end
    --质量
    if param.quality then
        if param.quality < 0 then
            self._qualityObj:SetActive(false)
            return
        end
        local qualityName = UIEnum.ItemColorFrame(param.quality)
        if qualityName ~= "" then
            self._qualityObj:SetActive(true)
            self._quality.sprite = self._uiCommonAtlas:GetSprite(qualityName)
        else
            self._qualityObj:SetActive(false)
        end
    else
        self._qualityObj:SetActive(false)
    end
end

function UIAsset:SetScale(scale)
    if not scale then
        scale = 1
    end
    if self._transform then
        self._transform.localScale = Vector3(scale, scale, scale)
    end
end

---@param type T
---@return T 获取组件 返回nil说明没有
function UIAsset:GetComponent(type)
    for _, component in ipairs(self._components) do
        if component._className == type._className then
            return component
        end
    end
    return nil
end

---@param type T
---@return boolean 是否包含某个组件
function UIAsset:ContainsComponent(type)
    return self:GetComponent(type) ~= nil
end

---@param type T
---@return T 添加组件 返回组件实例 返回nil说明重复添加
function UIAsset:AddComponent(type, ...)
    ---@type UIAssetComponentBase
    local c = self:GetComponent(type)
    if c then
        Log.error("重复的组件")
        return nil
    end
    local typeName = type._className
    local index = #self._components + 1
    if self._disableComponent[typeName] then
        c = self._disableComponent[typeName]
        self._disableComponent[typeName] = nil
        c:Reset(self._id, index, { ... })
    else
        c = type:New(self, self._id, index, { ... })
        c:LoadPrefab(UIAssetConfig.GetComponentPrefab(type))
        c:OnInit()
    end
    self._components[index] = c
    -- c:SetActive(true)
    c:OnAdd()
    return c
end

---@param type T
---@return T 移除组件 组件并不会销毁 放在了disable列表里 返回已经失效的组件实例 返回nil说明没有该组件
function UIAsset:RemoveComponent(type)
    ---@type UIAssetComponentBase
    local c = self:GetComponent(type)
    if not c then
        Log.error("不包含组件，无法移除")
        return
    end
    local typeName = type._className
    c:OnRemove()
    self._components[typeName] = nil
    table.remove(self._components, c:Index())
    self._disableComponent[typeName] = c
    return c
end

--移除所有组件 内部方法 在复用的时候会先移除已有的组件
function UIAsset:_RemoveAllComponent()
    --倒着移除
    for i = #self._components, 1, -1 do
        local c = self._components[i]
        c:OnRemove()
        table.remove(self._components, i)
        self._disableComponent[c._className] = c
    end
end

function UIAsset:GetBtn()
    local eventComponent = self:GetComponent(UIAssetComponentEvent)
    if eventComponent then
        return eventComponent:GetBtnObject()
    end
end