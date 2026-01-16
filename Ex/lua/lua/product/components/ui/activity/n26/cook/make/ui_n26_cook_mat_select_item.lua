--
---@class UIN26CookMatSelectItem : UICustomWidget
_class("UIN26CookMatSelectItem", UICustomWidget)
UIN26CookMatSelectItem = UIN26CookMatSelectItem

--初始化
function UIN26CookMatSelectItem:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIN26CookMatSelectItem:InitWidget()
    ---@type UILocalizationText
    self.matNameTxt = self:GetUIComponent("UILocalizationText", "matNameTxt")
    ---@type UILocalizationText
    self.matNumTxt = self:GetUIComponent("UILocalizationText", "matNumTxt")
    self.iconLoader = self:GetUIComponent("RawImageLoader", "icon")
    self.iconTrans  = self:GetUIComponent("RectTransform", "icon")
    self.iconGo = self:GetGameObject("icon")

   -- self.addNumBtn = self:GetGameObject("AddNumBtn")
    self.subNumBtn = self:GetGameObject("subNumBtn")
    self.addNumBtn = self:GetGameObject("addNumBtn")
    self.animation = self:GetUIComponent("Animation","animation")

    -- --长按
    -- local addBtn = UILongPressTriggerListener.Get(self.addNumBtn)
    -- addBtn.onLongPress = function(go)
    --     if self._isAddMouseDown == false then
    --         self._isAddMouseDown = true
    --     end
    -- end
    -- addBtn.onLongPressEnd = function(go)
    --     if self._isAddMouseDown == true then
    --         self._isAddMouseDown = false
    --     end
    -- end
    -- addBtn.onClick = function(go)
    --     self:OnAddBtnClick()
    -- end

    -- ----------------
    -- local subBtn = UILongPressTriggerListener.Get(self.subNumBtn)
    -- subBtn.onLongPress = function(go)
    --     if self._isSubMouseDown == false then
    --         self._isSubMouseDown = true
    --     end
    -- end
    -- subBtn.onLongPressEnd = function(go)
    --     if self._isSubMouseDown == true then
    --         self._isSubMouseDown = false
    --     end
    -- end
    -- subBtn.onClick = function(go)
    --     self:OnSubBtnClick()
    -- end

    -- self._updateTime = 0
    -- self._pressTime = 200 -- Cfg.cfg_global["sale_and_use_press_long_deltaTime"].IntValue

end

-- --长按操作
-- function UIN26CookMatSelectItem:OnUpdate(deltaTimeMS)
--     if not self._isAddMouseDown and not self._isAddMouseDown then
--         return
--     end

--     self._updateTime = self._updateTime + deltaTimeMS
--     if self._updateTime > self._pressTime then
--         self._updateTime = self._updateTime - self._pressTime
--         if self._isAddMouseDown then
--             self:itemaddOnClick()
--         end
--         if self._isSubMouseDown then
--             self:itemsubOnClick()
--         end
--     end
-- end

function UIN26CookMatSelectItem:AddNumBtnOnClick()
    if self.selectMatFun() == self.matLimit then
        --已经达到上限
        ToastManager.ShowToast(StringTable.Get("str_n26_cook_mat_limit"))
        return
    end
    if self.remainMatFun() == 0 then
        --没有材料 
        ToastManager.ShowToast(StringTable.Get("str_n26_cook_mat_empty"))
        return
    end

    self.curMatCount = self.curMatCount + 1
    self:RefreshSelectText()
    if self.onChangeFun then
        self.onChangeFun(self.curMatCount)
    end
end

function UIN26CookMatSelectItem:SubNumBtnOnClick()
    if self.curMatCount == 0 then
        return
    end
    self.curMatCount = self.curMatCount - 1
    self:RefreshSelectText()
    if self.onChangeFun then
        self.onChangeFun(self.curMatCount)
    end
end

function UIN26CookMatSelectItem:RefreshSelectText()
    if self.curMatCount > 0 then
        self.matNumTxt:SetText("x".. self.curMatCount)
        self.subNumBtn:SetActive(true)
        
    else
        self.matNumTxt:SetText("")
        self.subNumBtn:SetActive(false)
    end
end

--设置数据
function UIN26CookMatSelectItem:SetData(data, matLimit, selectMatFun, remainMatFun, onChangeFun)
    self.curMatCount = 0
    self.matLimit = matLimit
    self.selectMatFun = selectMatFun
    self.remainMatFun = remainMatFun
    self.onChangeFun = onChangeFun
    self:RefreshSelectText()
    
    local cfg = Cfg.cfg_dinner_food_material[data.id]
    if cfg then
        --self.matNameTxt:SetText(StringTable.Get(cfg.Name))
        self.iconLoader:LoadImage(cfg.Icon)
    end
end

function UIN26CookMatSelectItem:SetAsEmpty()
    self.iconGo:SetActive(false)
    self.matNumTxt:SetText("")
    self.subNumBtn:SetActive(false)
    self.addNumBtn:SetActive(false)
end

function UIN26CookMatSelectItem:GetIconTrans()
    return self.iconTrans
end

function UIN26CookMatSelectItem:GetMatCount()
    return self.curMatCount or 0
end


function UIN26CookMatSelectItem:PlayEnterAni()
    self:SetVisible(true)
    self.animation:Play() 
 end

 function UIN26CookMatSelectItem:SetVisible(visible)
    self:GetGameObject():SetActive(visible)
end