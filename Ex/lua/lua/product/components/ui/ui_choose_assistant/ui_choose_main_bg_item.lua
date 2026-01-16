---@class UIChooseMainBgItem:UICustomWidget
_class("UIChooseMainBgItem", UICustomWidget)
UIChooseMainBgItem = UIChooseMainBgItem

function UIChooseMainBgItem:OnShow()
    self:AttachEvent(GameEventType.ChangeMainBg, self.Select)
    self:_GetComponents()
end

---@param pet Pet
---@param currPet Pet
function UIChooseMainBgItem:SetData(id,itemid, using, bgName, name, callback)
    self._id = id
    self._itemid = itemid
    self._using = using
    self._name = name
    self._bgName = bgName
    self._callback = callback
    self:_OnValue()
end

function UIChooseMainBgItem:_GetComponents()
    self._nameTex = self:GetUIComponent("UILocalizationText", "name")
    self._bg = self:GetUIComponent("RawImageLoader", "bg")
    self._select = self:GetGameObject("select")
    self._usingGo = self:GetGameObject("using")
    self._red = self:GetGameObject("red")
    self._empty = self:GetGameObject("empty")
    self._rect = self:GetGameObject("rect")
end

function UIChooseMainBgItem:_OnValue()
    self._empty:SetActive(self._id == 99999)
    self._rect:SetActive(self._id ~= 99999)
    if self._id == 99999 then
        
    else
        if self._bgName then
            self._bg:LoadImage(self._bgName)
        end
        
        if self._name then
            self._nameTex:SetText(StringTable.Get(self._name))
        end
        self._usingGo:SetActive(self._using)
        self._select:SetActive(self._using)
        
        self:SetRed()
    end
end
function UIChooseMainBgItem:SetRed()
    self._redState = false
    if self._itemid then
        local itemModule = GameGlobal.GetModule(ItemModule)
        ---@type Item
        local item_data
        local items = itemModule:GetItemByTempId(self._itemid)
        if items and table.count(items)>0 then
            for key, value in pairs(items) do
                item_data = value
                break
            end
        end
        self._redState = item_data:IsNewOverlay()
        self._pstid = item_data:GetID()
    end
    self._red:SetActive(self._redState)
end

function UIChooseMainBgItem:bgOnClick(go)
    if self._callback then
        self._callback(self._id)
    end
    if self._redState then
        self:StartTask(
            function(TT)
                if self._itemid and self._pstid then
                    local itemModule = GameGlobal.GetModule(ItemModule)
                    itemModule:SetItemUnnewOverlay(TT, self._pstid)                    
                end
            end
        )
        self._redState = false
        self._red:SetActive(self._redState)
    end
end

function UIChooseMainBgItem:Select(id)
    local select = (self._id == id)
    self._select:SetActive(select)
end
