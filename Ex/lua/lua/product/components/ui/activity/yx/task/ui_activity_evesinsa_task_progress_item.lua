---@class UIActivityEveSinsaTaskProgressItem:UICustomWidget
_class("UIActivityEveSinsaTaskProgressItem", UICustomWidget)
UIActivityEveSinsaTaskProgressItem = UIActivityEveSinsaTaskProgressItem

function UIActivityEveSinsaTaskProgressItem:_GetComponents()
    -- UI Left
    self._apItemIcon = self:GetUIComponent("RawImageLoader", "_apItemIcon")
    self._apProgresslTex = self:GetUIComponent("UILocalizationText", "_apProgresslTex")

    -- UI Middle
    self._apProgressImg = self:GetUIComponent("Image", "_apProgressImg")
    self._apProgressImgRect = self:GetUIComponent("RectTransform", "_apProgressImg")
    self._apProgressBgImg = self:GetUIComponent("Image", "_apProgressBgImg")
    self._apProgressBgImgRect = self:GetUIComponent("RectTransform", "_apProgressBgImg")
    self._apProgressEffectImgObj = self:GetGameObject("_apProgressEffectImg")
    self._apProgressEffectImgRect = self:GetUIComponent("RectTransform", "_apProgressEffectImg")
    self._apProgressBlackLine = self:GetGameObject("_apProgressBlackLine")

    -- UI Right
    self._ItemPool = self:GetUIComponent("UISelectObjectPath", "_ItemPool")

    self._canGetRewardObj = self:GetGameObject("_canGetReward")
    self._canGetRewardTex = self:GetUIComponent("UILocalizationText", "_canGetRewardTex")
    self._canGetRewardTexEn = self:GetUIComponent("UILocalizationText", "_canGetRewardTexEn")
    self._canGetRewardTexEnObj = self:GetGameObject("_canGetRewardTexEn")

    self._receivedRewardObj = self:GetGameObject("_receivedReward")
    self._receivedRewardTex = self:GetUIComponent("UILocalizationText", "_receivedRewardTex")
    self._receivedRewardTexEn = self:GetUIComponent("UILocalizationText", "_receivedRewardTexEn")
    self._receivedRewardTexEnObj = self:GetGameObject("_receivedRewardTexEn")

    self._numColorLine = self:GetGameObject("_colorLine")
    self._numNormalLine = self:GetGameObject("_normalLine")
end

function UIActivityEveSinsaTaskProgressItem:SetData(
    index,
    count,
    itemInfo,
    componentInfo,
    callback,
    itemCallBack,
    specificData,
    numColor,
    gotStr,
    canGetStr)
    self:_GetComponents()
    self._index = index
    self._totalCellCount = count
    self._itemInfo = itemInfo
    ---@type PersonProgressComponentInfo
    self._componentInfo = componentInfo
    self._callback = callback
    self._itemCallback = itemCallBack
    self._specificData = specificData
    -- self._numColor = numColor
    -- self._gotStr = gotStr
    -- self._canGetStr = canGetStr
    self:_OnValue()
end

function UIActivityEveSinsaTaskProgressItem:_OnValue()
    if not self.atlas then
        local atlasName = self._specificData:GetSpriteAtlasName()
        self.atlas = self:GetAsset(atlasName, LoadType.SpriteAtlas)
    end
    
    local index = self._index
    local prev = self._itemInfo.prev
    local target = self._itemInfo.target
    local count = self._itemInfo.count

    -- UI Left
    local itemId = self._componentInfo.m_item_id
    self:_SetItemIcon(itemId)
    self:_SetProgressText(target)

    -- UI Middle
    local cur = self._componentInfo.m_current_progress
    local rate = self:_CalcRate(prev, target, cur)
    local effectShow = ((rate ~= 0) and (rate ~= 1)) or ((rate == 0) and (cur == prev))
    local blackShow = (index ~= count)
    self:_SetProgressImgRes()--处理圆角
    self:_SetProgressImg(rate, effectShow, blackShow)

    -- UI Right
    local rewards = self._componentInfo.m_progress_rewards[target]
    self:_SetRewardItem(rewards, "UIActivityEveSinsaTaskRewardItem")

    -- 活跃度的领取状态 0-未达到，1-未领取，2-已领取
    local received = self._componentInfo.m_received_progress
    local state = self:_CalcState(target, cur, received)
    self:_SetStateCanGetReward(state == 1)
    self:_SetStateReceivedReward(state == 2)
    self:_FillNumAre(state, target)

end

function UIActivityEveSinsaTaskProgressItem:OnShow(uiParams)
end

function UIActivityEveSinsaTaskProgressItem:OnHide()
end

--region UI Left
function UIActivityEveSinsaTaskProgressItem:_SetItemIcon(itemId)
    local cfgItem = Cfg.cfg_item[itemId]
    if not cfgItem then
        return
    end
    -- self._itemNameText:SetText(StringTable.Get(cfgItem.Name))
    self._apItemIcon:LoadImage(cfgItem.Icon)
end

function UIActivityEveSinsaTaskProgressItem:_FillNumAre(state, target)
    local colorNum = false
    if state == 1 or state == 2 then
        colorNum = true
    end
    self:_SetProgressText(target, colorNum)
    self:_SetNumLine(colorNum)
end

function UIActivityEveSinsaTaskProgressItem:_SetProgressText(point, colorNum)
    local color = "FFFFFF"
    if colorNum then
        color = self._specificData:GetQuestNumSpecialColor()--self._numColor
    end
    local formatStr = "<color=#%s>%s</color>"
    local showStr = string.format(formatStr, color, point)
    self._apProgresslTex:SetText(showStr)
end

function UIActivityEveSinsaTaskProgressItem:_SetNumLine(colorNum)
    if self._numColorLine and self._numNormalLine then
        self._numColorLine:SetActive(colorNum)
        self._numNormalLine:SetActive(not colorNum)
    end
end
--endregion

--region UI Middle
function UIActivityEveSinsaTaskProgressItem:_SetProgressImgRes()
    if self.atlas and self._specificData then
        if self._specificData:IsProgressImgNeedChange() then
            if self:_IsFirstCell() then
                if self._apProgressBgImgRect and self._apProgressImgRect then
                    self._apProgressBgImgRect.sizeDelta = Vector2(self._apProgressBgImgRect.sizeDelta.x,self._specificData:GetProgressFirstCellImgHeight())
                    self._apProgressImgRect.sizeDelta = Vector2(self._apProgressImgRect.sizeDelta.x,self._specificData:GetProgressFirstCellImgHeight())
                end
                self._apProgressImg.sprite = self.atlas:GetSprite(self._specificData:GetTopProgressImg())
                self._apProgressBgImg.sprite = self.atlas:GetSprite(self._specificData:GetTopProgressBgImg())
            elseif self:_IsEndCell() then
                if self._apProgressBgImgRect and self._apProgressImgRect then
                    self._apProgressBgImgRect.sizeDelta = Vector2(self._apProgressBgImgRect.sizeDelta.x,self._specificData:GetProgressNormalCellImgHeight())
                    self._apProgressImgRect.sizeDelta = Vector2(self._apProgressImgRect.sizeDelta.x,self._specificData:GetProgressNormalCellImgHeight())
                end
                self._apProgressImg.sprite = self.atlas:GetSprite(self._specificData:GetBottomProgressImg())
                self._apProgressBgImg.sprite = self.atlas:GetSprite(self._specificData:GetBottomProgressBgImg())
            else
                if self._apProgressBgImgRect and self._apProgressImgRect then
                    self._apProgressBgImgRect.sizeDelta = Vector2(self._apProgressBgImgRect.sizeDelta.x,self._specificData:GetProgressNormalCellImgHeight())
                    self._apProgressImgRect.sizeDelta = Vector2(self._apProgressImgRect.sizeDelta.x,self._specificData:GetProgressNormalCellImgHeight())
                end
                self._apProgressImg.sprite = self.atlas:GetSprite(self._specificData:GetNormalProgressImg())
                self._apProgressBgImg.sprite = self.atlas:GetSprite(self._specificData:GetNormalProgressBgImg())
            end
        end
    end
end
function UIActivityEveSinsaTaskProgressItem:_SetProgressImg(rate, effectShow, blackShow)
    self._apProgressImg.fillAmount = rate

    local height = self._apProgressImgRect.sizeDelta.y
    local offset = self._apProgressEffectImgRect.sizeDelta.y / 2
    local posY = -1 * rate * height - offset
    local oriX = self._apProgressEffectImgRect.anchoredPosition.x
    self._apProgressEffectImgRect.anchoredPosition = Vector2(oriX, posY)

    self._apProgressEffectImgObj:SetActive(effectShow)

    self._apProgressBlackLine:SetActive(blackShow)
end
--endregion

--region UI Right
function UIActivityEveSinsaTaskProgressItem:_SetRewardItem(infoList, classType)
    self._ItemPool:SpawnObjects(classType, table.count(infoList))
    ---@type UIActivityEveSinsaTaskRewardItem[]
    local itemList = self._ItemPool:GetAllSpawnList()
    for i = 1, table.count(infoList) do
        itemList[i]:SetData(i, infoList[i], self._itemCallback)
    end
end

function UIActivityEveSinsaTaskProgressItem:_SetStateCanGetReward(isShow)
    local EnglishFlag = HelperProxy:GetInstance():IsInEnglish()
    self._canGetRewardTexEnObj:SetActive(EnglishFlag)

    self._canGetRewardObj:SetActive(isShow)
    local canGetStr = self._specificData:GetQuestCanGetStr()
    self._canGetRewardTex:SetText(StringTable.Get(canGetStr))
    self._canGetRewardTexEn:SetText(StringTable.Get(canGetStr))
end

function UIActivityEveSinsaTaskProgressItem:_SetStateReceivedReward(isShow)
    local EnglishFlag = HelperProxy:GetInstance():IsInEnglish()
    self._receivedRewardTexEnObj:SetActive(EnglishFlag)

    self._receivedRewardObj:SetActive(isShow)
    local gotStr = self._specificData:GetQuestGotStr()
    self._receivedRewardTex:SetText(StringTable.Get(gotStr))
    self._receivedRewardTexEn:SetText(StringTable.Get(gotStr))
end
--endregion

--region UI Event
function UIActivityEveSinsaTaskProgressItem:GetRewardBtnOnClick()
    if self._callback then
        self._callback(self._index)
    end
end
--endregion

--region help
function UIActivityEveSinsaTaskProgressItem:_CalcRate(low, hi, cur)
    -- rate 范围 0 ~ 1
    if cur <= low then
        return 0
    elseif cur >= hi then
        return 1
    else
        return (cur - low) / (hi - low)
    end
end

function UIActivityEveSinsaTaskProgressItem:_CalcState(target, cur, received)
    local state = 0
    if cur >= target then
        state = 1
        for _, x in pairs(received) do
            if x == target then
                state = 2
            end
        end
    end
    return state
end
function UIActivityEveSinsaTaskProgressItem:_IsFirstCell()--处理进度条原角 是否是顶部格子
    return self._index == 1
end
function UIActivityEveSinsaTaskProgressItem:_IsEndCell()--处理进度条原角 是否是底部格子
    return self._index == self._totalCellCount
end
--endregion
