---@class UIQuestAchTypeBtnItem:UICustomWidget
_class("UIQuestAchTypeBtnItem", UICustomWidget)
UIQuestAchTypeBtnItem = UIQuestAchTypeBtnItem

function UIQuestAchTypeBtnItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)

    ---@type QuestModule
    self._module = GameGlobal.GetModule(QuestModule)
    if self._module == nil then
        Log.fatal("[quest] error --> module is nil !")
        return
    end

    self:AttachEvent(GameEventType.UIQuestOnBigTypeBtnClick, self.OnBigTypeBtnClick)
    --self:AttachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.QuestUpdate, self.CheckQuestRedPoint)
    self:AttachEvent(GameEventType.ItemCountChanged, self.CheckQuestRedPoint)

    self:AttachEvent(GameEventType.RolePropertyChanged, self.CheckQuestRedPoint)
end

--data就是cfg数据
function UIQuestAchTypeBtnItem:SetData(index, data, callback, changeLayout)
    self:_GetComponents()
    self._index = index
    --self._currIndexTab = currIndexTab
    self._data = data
    self._callback = callback
    self._changeLayout = changeLayout
    self._isOpen = false
    self._tweenTime = 0.2
    self:_OnValue()

    --[[
        --开始时自动点击
        old
        --开始时需要点击的按钮，大类，小类
        if self._currIndexTab[1] == self._index then
            self:bgOnClick()
            if self._currIndexTab[2] then
                self:ItemBtnClick(self._currIndexTab[2])
            end
        end
        ]]
end

--按钮的点击（被调用）
function UIQuestAchTypeBtnItem:BtnBeClick(smallIdx)
    self:SelectTab()
    if smallIdx == 0 then
        return
    end
    if self._hasSmallType then
        self:ItemBtnClick(smallIdx)
    end
end

function UIQuestAchTypeBtnItem:ItemRectTransform()
    return self._rect
end

function UIQuestAchTypeBtnItem:_GetComponents()
    self._rect = self:GetUIComponent("RectTransform", "rect")

    self._sing_bigTypeTex = self:GetUIComponent("UILocalizationText", "sing_bigTypeTex")
    self._mult_bigTypeTex = self:GetUIComponent("UILocalizationText", "mult_bigTypeTex")

    self._sing_bigTypeTexEn = self:GetUIComponent("UILocalizationText", "sing_bigTypeTexEn")
    self._mult_bigTypeTexEn = self:GetUIComponent("UILocalizationText", "mult_bigTypeTexEn")

    --self._arrowImg = self:GetUIComponent("Image", "arrowImg")

    self._smallBtnPool = self:GetUIComponent("UISelectObjectPath", "smallBtnPool")

    ---@type UnityEngine.UI.GridLayoutGroup
    self._grid = self:GetUIComponent("GridLayoutGroup", "smallBtnPool")

    self._moveRect = self:GetUIComponent("RectTransform", "smallBtnPool")

    self._mask = self:GetUIComponent("RectTransform", "mask")

    self._red = self:GetGameObject("red")
    --self._imgbg = self:GetGameObject("imgbg")

    --self._bgImg = self:GetUIComponent("Image", "bg")

    self._sing_Icon1 = self:GetUIComponent("Image", "sing_icon1")
    self._sing_Icon2 = self:GetUIComponent("Image", "sing_icon2")
    self._mult_Icon1 = self:GetUIComponent("Image", "mult_icon1")

    self._mult_Icon2 = self:GetUIComponent("Image", "mult_icon2")

    self._select = self:GetGameObject("select")

    self._mult = self:GetGameObject("mult")
    self._sing = self:GetGameObject("single")
end

function UIQuestAchTypeBtnItem:CheckRed(enum)
    local redInfo = self._module:GetRedPoint()
    if table.count(redInfo[QuestType.QT_Achieve]) > 0 then
        for i = 1, table.count(redInfo[QuestType.QT_Achieve]) do
            if redInfo[QuestType.QT_Achieve][i] == enum then
                return true
            end
        end
    end
    return false
end

function UIQuestAchTypeBtnItem:_OnValue()
    --self._imgbg:SetActive(self._data.SmallTypeCount > 0)

    self._red:SetActive(self:CheckRed(self._data.BigTypeEnum))

    if self._data.SmallTypeCount > 0 then
        self._mult:SetActive(true)
        self._sing:SetActive(false)

        self._mult_bigTypeTex:SetText(StringTable.Get(self._data.BigTypeName))

        self._mult_bigTypeTexEn:SetText(StringTable.Get(self._data.BigTypeNameEn))
        self._mult_Icon1.sprite = self._atlas:GetSprite(self._data.Icon)
        self._mult_Icon2.sprite = self._atlas:GetSprite(self._data.Icon)

        self._hasSmallType = true

        self._smallBtnPool:SpawnObjects("UIQuestAchSmallTypeBtnItem", self._data.SmallTypeCount)
        ---@type UIQuestAchSmallTypeBtnItem[]
        self._items = self._smallBtnPool:GetAllSpawnList()
        for i = 1, self._data.SmallTypeCount do
            local sprite = self._atlas:GetSprite(self._data.SmallIcon[i])
            local selectSprite = self._atlas:GetSprite(self._data.SmallSelectIcon[i])

            self._items[i]:SetData(
                i,
                self._data.SmallTypeName[i],
                self._data.SmallTypeEnum[i],
                sprite,
                selectSprite,
                function(idx)
                    self:ItemBtnClick(idx)
                end,
                self._checkRedCallback
            )
        end
    else
        self._hasSmallType = false

        self._mult:SetActive(false)
        self._sing:SetActive(true)

        self._sing_bigTypeTex:SetText(StringTable.Get(self._data.BigTypeName))

        self._sing_bigTypeTexEn:SetText(StringTable.Get(self._data.BigTypeNameEn))
        self._sing_Icon1.sprite = self._atlas:GetSprite(self._data.Icon)
        self._sing_Icon2.sprite = self._atlas:GetSprite(self._data.Icon)
    end

    self._mask.gameObject:SetActive(self._hasSmallType)

    ---@type UnityEngine.RectOffset
    local left = self._grid.padding.left
    local right = self._grid.padding.right
    local Top = self._grid.padding.top
    local Bottom = self._grid.padding.bottom

    self._mask.sizeDelta =
        Vector2(
        left + self._grid.cellSize.x + right,
        Top + Bottom + self._grid.cellSize.y * self._data.SmallTypeCount +
            self._grid.spacing.y * (self._data.SmallTypeCount - 1)
    )
end

function UIQuestAchTypeBtnItem:bgOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    self:SelectTab()
end

function UIQuestAchTypeBtnItem:SelectTab()
    if self._hasSmallType then
        if self._changeLayout then
            self._changeLayout(self._index, self._mask.sizeDelta.y)
        end
        --self._isOpen = not self._isOpen
        if self._isOpen then
            self:ItemBtnClick(1)
        end
    else
        if self._callback then
            self._callback(self._data.BigTypeEnum)
            self._changeLayout(self._index, 0)
        end
    end
end

function UIQuestAchTypeBtnItem:OnBigTypeBtnClick(idx)
    if idx == self._index then
        -- self._bgImg.sprite = self._atlas:GetSprite("task_chengjiu_btn2")
    else
        -- self._bgImg.sprite = self._atlas:GetSprite("task_chengjiu_btn1")
    end
    self._select:SetActive(idx == self._index)
end

--给父级查看子按钮个数
function UIQuestAchTypeBtnItem:HasItems()
    return self._hasSmallType
end

function UIQuestAchTypeBtnItem:ItemBtnClick(idx)
    local enum = self._data.SmallTypeEnum[idx]
    if self._callback then
        self._callback(enum)
    end
    if self._data.SmallTypeCount > 0 then
        for i = 1, #self._items do
            self._items[i]:Flush(idx)
        end
    end
end

function UIQuestAchTypeBtnItem:CloseMovePos()
    if self._hasSmallType then
        self._isOpen = false

        local moveToPos = Vector2(-7.7, 0)

        --self._arrowImg.sprite = self._atlas:GetSprite("task_chengjiu_icon1")
        if self._tween then
            self._tween:Kill(true)
            self._tween = nil
        end
        self._tween = self._moveRect:DOAnchorPos(moveToPos, self._tweenTime)
    end
end

function UIQuestAchTypeBtnItem:OpenMovePos()
    if self._hasSmallType then
        self._isOpen = true

        local moveToPos = Vector2(0, -self._moveRect.sizeDelta.y)

        --self._arrowImg.sprite = self._atlas:GetSprite("task_chengjiu_icon2")
        if self._tween then
            self._tween:Kill(true)
            self._tween = nil
        end
        self._tween = self._moveRect:DOAnchorPos(moveToPos, self._tweenTime)
    end
end

function UIQuestAchTypeBtnItem:OnHide()
    --self:DetachEvent(GameEventType.UIQuestOnBigTypeBtnClick, self.OnBigTypeBtnClick)
    --self:DetachEvent(GameEventType.CheckQuestRedPoint, self.CheckQuestRedPoint)
    --self:DetachEvent(GameEventType.RolePropertyChanged, self.CheckQuestRedPoint)
end

function UIQuestAchTypeBtnItem:CheckQuestRedPoint()
    self._red:SetActive(self:CheckRed(self._data.BigTypeEnum))
    --[[
        if type == nil then
        elseif type == QuestType.QT_Achieve then
            self._red:SetActive(self:CheckRed(self._data.BigTypeEnum))
        end
        ]]
end
