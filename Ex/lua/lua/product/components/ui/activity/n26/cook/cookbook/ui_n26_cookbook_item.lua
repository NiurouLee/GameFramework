---@class UIN26CookBookItem : UICustomWidget
_class("UIN26CookBookItem", UICustomWidget)
UIN26CookBookItem = UIN26CookBookItem

function UIN26CookBookItem:Constructor()
    self._foodData = nil
    self._callback = nil
    self._isSelected = false
end

--初始化
function UIN26CookBookItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIN26Cook.spriteatlas", LoadType.SpriteAtlas)
    self._lockColor = Color(36/255,31/255,29/255)
    self._unLockColor = Color(80/255,34/255,16/255)
    self._index = 1
    self:_GetComponents()
end

--获取ui组件
function UIN26CookBookItem:_GetComponents()
    self._icon = self:GetUIComponent("RawImageLoader","Icon")
    self._name = self:GetUIComponent("UILocalizationText","name")
    self._selectObj = self:GetGameObject("Selected")
    self._isGetObj = self:GetGameObject("IsGet")
    self._lockObj = self:GetGameObject("lock")
    self._nameBg = self:GetUIComponent("Image","nameBg")
    self._circleOutline = self:GetUIComponent("H3D.UGUI.CircleOutline", "name")
    self._nameBgRect = self:GetUIComponent("RectTransform","nameBg")
    self._nameBgSizeFitter = self:GetUIComponent("ContentSizeFitter","nameBg")
    self._delay = 50
end

---@param status NewYearDinner_Status
function UIN26CookBookItem:SetData(data,status,callback,index)
    self._foodData = data
    self._status = status
    self._callback = callback
    self._index = index
    local delayTime = self._delay * math.floor((index - 1) / 3)
    self:_SetAnimation(delayTime)

    self:_InitData()
end

--初始化数据
function UIN26CookBookItem:_InitData()
    self._icon:LoadImage(self._foodData.Icon)
    self._name:SetText(StringTable.Get(self._foodData.Name))

    local isGet = false
    local isLock = false
    if self._status == NewYearDinner_Status.E_NewYearDinner_Status_LOCK then
        isLock = true
        self._nameBg.sprite = self._atlas:GetSprite("n26_food_di03")
        self._circleOutline.effectColor = self._lockColor
    elseif self._status == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
        self._nameBg.sprite = self._atlas:GetSprite("n26_food_di04")
        self._circleOutline.effectColor = self._unLockColor
    elseif self._status == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
        self._nameBg.sprite = self._atlas:GetSprite("n26_food_di04")
        self._circleOutline.effectColor = self._unLockColor
        isGet = true
    elseif self._status == NewYearDinner_Status.E_NewYearDinner_Status_RECVED then
        self._nameBg.sprite = self._atlas:GetSprite("n26_food_di04")
        self._circleOutline.effectColor = self._unLockColor
        isGet = true
    end
    self._isGetObj:SetActive(isGet)
    self._lockObj:SetActive(isLock)

    GameGlobal.TaskManager():StartTask(self._SetNameBgSize,self)
end

--设置是否被选中
function UIN26CookBookItem:SetSelect(isSelected)
    self._isSelected = isSelected
    self._selectObj:SetActive(isSelected)
end

function UIN26CookBookItem:_SetAnimation(delay)
    UIWidgetHelper.PlayAnimationInSequence(self,
        "anim",
        "anim",
        "uieff_N26_CookBookItem",
        delay,
        500,
        nil)
end

--获得数据
function UIN26CookBookItem:GetInfo()
    return self._foodData
end

--获得id
function UIN26CookBookItem:GetID()
    return self._foodData.ID
end

--获得解锁状态
function UIN26CookBookItem:GetStatus()
    return self._status
end

function UIN26CookBookItem:SetDone()
    self._status = NewYearDinner_Status.E_NewYearDinner_Status_RECVED
    self._nameBg.sprite = self._atlas:GetSprite("n26_food_di04")
    self._circleOutline.effectColor = self._unLockColor
    self._isGetObj:SetActive(true)
end

function UIN26CookBookItem:_SetNameBgSize(TT)
    self:Lock("UIN26CookBookItem")
    YIELD(TT,10)
    if self._nameBgRect.sizeDelta.x > 208 then
        self._nameBgSizeFitter.enabled = false
        self._nameBgRect.sizeDelta = Vector2(208,42)
    end
    self:UnLock("UIN26CookBookItem")
end

function UIN26CookBookItem:ItemBtnOnClick()
    self:SetSelect(true)
    if self._callback then
        self._callback(self)
    end
end

