---@class UIItemForm
UIItemForm = {
    Base = 1, -- 基础形态
    PetLevelUp = 2, -- 星灵升级
    PetGrade = 3, -- 星灵觉醒
    PetFavorability = 4, -- 星灵好感度
    ResInstance = 5, -- 资源本
    Stage = 6, -- 关卡详情 番外详情
    Result = 7, -- 结算
    Tower = 8, -- 尖塔
    Tactic = 9, --战术卡带
    BackPack = 10, --背包物品
    PetLevelUpFast = 11,
    N33Lottery = 12, -- N33活动商店
}
_enum("UIItemForm", UIItemForm)

---@class UIItemNode
local UIItemNode = {
    Normal = 1, -- 正常
    Exp = 2, -- exp
    Res = 3, -- x2
    Reduce = 4, -- 减少
    Love = 5, -- 减少
    Award = 6, -- 奖励
    Result = 7, -- 结算
    TopAward = 8, -- 顶部奖励
    Activity = 9, -- 活动
    ReturnHelp = 10, --回流
    Toggle = 11,  -- 选择toggle
    ItemUseCount = 12,  -- 快速添加
    N33Lottery = 13, -- N33活动商店
}
_enum("UIItemNode", UIItemNode)

---@class UIItemCustomer
local UIItemCustomer = {
    [UIItemForm.Base] = {UIItemNode.Normal, UIItemNode.Activity}, -- 基础
    [UIItemForm.PetLevelUp] = {UIItemNode.Normal, UIItemNode.Exp, UIItemNode.Reduce}, --星灵升级
    [UIItemForm.PetGrade] = {{UIItemNode.Normal, UIItemNode.Level}}, -- 星灵觉醒
    [UIItemForm.PetFavorability] = {UIItemNode.Normal, UIItemNode.Love, UIItemNode.Reduce}, -- 星灵好感度
    [UIItemForm.ResInstance] = {UIItemNode.Normal, UIItemNode.Res, UIItemNode.Activity}, --资源本
    [UIItemForm.Stage] = {UIItemNode.Normal, UIItemNode.Award, UIItemNode.TopAward, UIItemNode.Activity}, --关卡详情 番外详情
    [UIItemForm.Result] = {UIItemNode.Normal, UIItemNode.Result, UIItemNode.Activity, UIItemNode.ReturnHelp}, --结算
    [UIItemForm.Tower] = {UIItemNode.Normal, UIItemNode.Award}, --尖塔
    [UIItemForm.Tactic] = {UIItemNode.Normal, UIItemNode.TopAward}, --战术卡带
    [UIItemForm.BackPack] = {UIItemNode.Normal, UIItemNode.Activity, UIItemNode.Toggle}, --背包物品
    [UIItemForm.PetLevelUpFast] = {UIItemNode.Normal, UIItemNode.Exp, UIItemNode.ItemUseCount}, --快速升级
    [UIItemForm.N33Lottery] = {UIItemNode.N33Lottery}, --N33活动商店
}
_enum("UIItemCustomer", UIItemCustomer)

---@class UIItemScale
local UIItemScale = {
    Level1 = 1,
    Level2 = 0.9,
    Level3 = 0.8,
    Level4 = 0.7
}
_enum("UIItemScale", UIItemScale)

---物品数据
---@class UIItemData
_class("UIItemData", Object)
UIItemData = UIItemData

function UIItemData:Constructor()
    self:Reset()
end

function UIItemData:Reset()
    --------  基础 ---------
    self.text1 = nil
    self.showNumber = false
    self.text2 = nil
    self.text2Color = nil
    self.quality = 0
    self.itemId = 0
    self.icon = nil
    self.iconGrey = -1 -- [-1] = 不处理， [0] = 还原， [1] = 设置为灰色
    self.level = -1
    self.showNew = false
    --------  基础 ---------

    --------  经验 ---------
    self.exp = nil
    --------  经验 ---------
    self.changePos = false
    self.isUp = false
    --------- 资源本---------
    self.showRes = false
    --------- 资源本---------

    --------  减少 ---------
    self.reduceNum = 0
    self.reduceCallBack = nil
    self.reduceLongPressOnOff = false
    self.reducePressTime = 0
    --------  减少 ---------

    --------  好感度--------
    self.showLove = false
    --------  好感度--------

    --------  奖励文字--------
    self.awardText = 0
    --------  奖励文字--------

    --------  结算--------
    self.resultType = UIItemResultType.None
    self.resultText = ""
    self.normalText = ""
    --------  结算--------

    ------顶部奖励 -------
    self.topText = ""

    ------ 活动 -------
    self.activityText = ""

    ------ 回流 -------
    self.returnHelpText = ""
    self.useNum = 0
end

function UIItemData:SetParams(params)
    for varName, value in pairs(params) do
        self[varName] = value
    end
    self:CorrectParams()
end

function UIItemData:CorrectParams()
    -- 等级显示和icon互斥
    if self.level >= 0 then
        self.icon = ""
    end
end

--region基本形态
--[[
    OnInit() 资源引用初始化
    OnShow() 数据控制显示UI
    OnHide() 清理状态
]]
---@class UIItemNodeBase
_class("UIItemNodeBase", Object)
UIItemNodeBase = UIItemNodeBase

---@param owner UIItem
function UIItemNodeBase:Constructor(uiView, owner)
    self._uiView = uiView
    self._owner = owner
    self._transform = self._uiView.transform
    ---@type UIItemData
    self._uiItemData = nil
    self._uicustomEventListener = UICustomUIEventListener:New()
    self:OnInit()
end

function UIItemNodeBase:OnInit()
end

function UIItemNodeBase:Show(uiItemData, itemForm)
    self._uiItemData = uiItemData
    self._itemForm = itemForm
    self:Enable(true)
    self:OnShow()
end

---@protected
function UIItemNodeBase:OnShow()
end

function UIItemNodeBase:Hide(enable)
    self:Enable(false)
    self:OnHide()
    self._uicustomEventListener:Dispose()
end

---@protected
function UIItemNodeBase:OnHide()
end

function UIItemNodeBase:Enable(enable)
    if self._transform then
        self._transform.gameObject:SetActive(enable)
    end
end
--endregion基类

--region 基本形态
---@class UIItemNormalBase
_class("UIItemNormalNode", UIItemNodeBase)
UIItemNormalNode = UIItemNormalNode
function UIItemNormalNode:OnInit()
    self._icon = self._uiView:GetUIComponent("RawImageLoader", "icon")
    self._iconRawImg = self._uiView:GetUIComponent("RawImage", "icon")
    self._iconRect = self._uiView:GetUIComponent("RectTransform", "icon")
    self._iconRectDefaultSize = Vector2(self._iconRect.sizeDelta.x, self._iconRect.sizeDelta.y)
    self._iconGO = self._uiView:GetGameObject("icon")
    self._quality = self._uiView:GetUIComponent("Image", "quality")
    self._qualityRect = self._uiView:GetUIComponent("RectTransform", "quality")
    self._qualityGO = self._uiView:GetGameObject("quality")
    self._text1 = self._uiView:GetUIComponent("UILocalizationText", "txt1")
    self._text1GO = self._uiView:GetGameObject("txt1")
    self._text2 = self._uiView:GetUIComponent("UILocalizationText", "txt2")
    self._text2GO = self._uiView:GetGameObject("txt2")
    self._text1BgGO = self._uiView:GetGameObject("diban")
    self._levelGO = self._uiView:GetGameObject("g_level")
    self._levelTxt = self._uiView:GetUIComponent("UILocalizationText", "et_levelnum")
    self._desPanel = self._uiView:GetGameObject("despanel")
    self._desLabel = self._uiView:GetUIComponent("UILocalizationText", "des")
    self._newGO = self._uiView:GetGameObject("new")
    self._uiCommonAtlas = self._owner:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._affinityGO = self._uiView:GetGameObject("affinity")
end

function UIItemNormalNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetText1(uiItemData.text1, uiItemData.showNumber)
    self:SetText2(uiItemData.text2)
    self:SetText2Color(uiItemData.text2Color)
    self:SetQuality(uiItemData.quality)
    self:SetIcon(uiItemData.icon, uiItemData.itemId)
    self:SetIconGrey(uiItemData.icon, uiItemData.iconGrey)
    self:SetLevel(uiItemData.level)
    self:ShowNew(uiItemData.showNew)
    if uiItemData.des then
        self._desPanel:SetActive(true)
        self._desLabel.text = uiItemData.des
    else
        self._desPanel:SetActive(false)
    end
    if uiItemData.showAffinity then
        self:ShowAffinityGO(true)
    else
        self:ShowAffinityGO(false)
    end
end

---显示文字1
function UIItemNormalNode:ShowText1(show)
    self._text1GO:SetActive(show)
    self._text1BgGO:SetActive(show)
    self:SetOffset(show)
end

---设置文字1
function UIItemNormalNode:SetText1(text, showNumber)
    if text ~= nil then
        local show = false
        if type(text) == "number" then
            local num = text
            show = num > 0 or showNumber
            self._text1:SetText(HelperProxy:GetInstance():FormatItemCount(num))
        elseif type(text) == "string" then
            show = not string.isnullorempty(text)
            self._text1:SetText(text)
        end
        self:ShowText1(show)
    else
        self:ShowText1(false)
    end
end

---显示文字2
function UIItemNormalNode:ShowText2(show)
    self._text2GO:SetActive(show)
end

---设置文字2
function UIItemNormalNode:SetText2(text)
    if string.isnullorempty(text) then
        self:ShowText2(false)
    else
        self:ShowText2(true)
        self._text2:SetText(text)
    end
end

--显示好感度
function UIItemNormalNode:ShowAffinityGO(show)
    self._affinityGO:SetActive(show)
end

function UIItemNormalNode:SetText2Color(color)
    if color then
        self._text2.color = color
    end
end

function UIItemNormalNode:ShowQuality(show)
    self._qualityGO:SetActive(show)
end

function UIItemNormalNode:SetQuality(quality)
    if quality <= 0 then
        self:ShowQuality(false)
        return
    end
    local qualityName = UIEnum.ItemColorFrame(quality)
    if qualityName ~= "" then
        self:ShowQuality(true)
        self._quality.sprite = self._uiCommonAtlas:GetSprite(qualityName)
    else
        self:ShowQuality(false)
    end
end

function UIItemNormalNode:ShowIcon(show, itemId)
    self._iconGO:SetActive(show)
    self:SetIconOffset(itemId)
end

function UIItemNormalNode:SetIcon(name, itemId)
    if not string.isnullorempty(name) then
        self:ShowIcon(true, itemId)
        self._icon:LoadImage(name)

        local isHead = false
        if itemId >= 3750000 and itemId <= 3759999 then
            isHead = true
        end
        if isHead then
            local whRate = 1
            --MSG23427	【必现】（测试_朱文科）累计签到查看头像和邮件发送头像时会有变形，附截图	4	新缺陷	李学森, 1958	05/22/2021
            --没有资源接口临时处理
            if itemId >= 3751000 and itemId <= 3751999 then
                whRate = 160 / 190
            elseif itemId >= 3752000 and itemId <= 3752999 then
                whRate = 138 / 216
            elseif itemId >= 3753000 and itemId <= 3753999 then
                whRate = 138 / 216
            end

            self._iconRect.sizeDelta = Vector2(self._iconRect.sizeDelta.x, self._iconRect.sizeDelta.x * whRate)
        else
            self._iconRect.sizeDelta = self._iconRectDefaultSize
        end
    else
        self:ShowIcon(false)
    end
end
---设置灰色
function UIItemNormalNode:SetIconGrey(name, gray)
    if string.isnullorempty(name) or gray == -1 then
        return
    end

    if not self._EMIMat then
        self._EMIMat = UnityEngine.Material:New(self._iconRawImg.material)
    end

    -- LoadImage(name) 会将同样图片的 material 设置为同一个
    -- 需要替换独立的 material 然后设置灰度
    local texture = self._iconRawImg.material.mainTexture
    self._iconRawImg.material = self._EMIMat
    self._iconRawImg.material.mainTexture = texture

    if gray == 1 then
        self._iconRawImg.material:SetFloat("_LuminosityAmount", 1)
    else
        self._iconRawImg.material:SetFloat("_LuminosityAmount", 0)
    end
    self._iconGO:SetActive(false)
    self._iconGO:SetActive(true)
end

function UIItemNormalNode:_IsPet(id)
    local cfg = Cfg.cfg_pet {ID = id}
    return cfg and true or false
end

function UIItemNormalNode:SetOffset(showText1)
    if showText1 then
        self._qualityRect.anchoredPosition = Vector2(0, 0)
    else
        self._qualityRect.anchoredPosition = Vector2(0, -20)
    end
end

function UIItemNormalNode:SetIconOffset(itemId)
    if self:_IsPet(itemId) then
        self._iconRect.anchoredPosition = Vector2(0, 0)
    else
        self._iconRect.anchoredPosition = Vector2(0, 5)
    end
end

function UIItemNormalNode:ShowLevel(show)
    self._levelGO:SetActive(show)
end

function UIItemNormalNode:SetLevel(level)
    if level < 0 then
        self:ShowLevel(false)
    else
        self:ShowLevel(true)
        self._levelTxt:SetText(level)
    end
end

function UIItemNormalNode:ShowNew(showNew)
    self._newGO:SetActive(showNew)
end
--endregion 基本形态

--region 经验形态
---@class UIItemNormalBase
_class("UIItemExpNode", UIItemNodeBase)
UIItemExpNode = UIItemExpNode
function UIItemExpNode:OnInit()
    self._upPos = Vector2(-51, 58)
    self._downPos = Vector2(-51, 4.5)
    self._tweener = nil

    ---@type UnityEngine.RectTransform
    self._rect = self._uiView:GetUIComponent("RectTransform", "g_exp")
    self._expTxt = self._uiView:GetUIComponent("UILocalizationText", "exp")
end

function UIItemExpNode:ChangePos(changePos, isUp)
    if not changePos then
        return
    end

    local targetPos

    if isUp then
        targetPos = self._upPos
    else
        targetPos = self._downPos
    end
    if self._tweener then
        self._tweener:Kill()
    end
    self._tweener = self._rect:DOAnchorPos(targetPos, 0.2)
end

function UIItemExpNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetExpNum(uiItemData.exp)

    self:ChangePos(uiItemData.changePos, uiItemData.isUp)
end
function UIItemExpNode:OnHide()
end

function UIItemExpNode:ShowExp(show)
    self:Enable(show)
end

function UIItemExpNode:SetExpNum(text)
    if string.isnullorempty(text) then
        self:ShowExp(false)
    else
        self:ShowExp(true)
        self._expTxt:SetText(text)
    end
end
--endregion 经验形态

--region 资源本node
---@class UIItemResNode
_class("UIItemResNode", UIItemNodeBase)
UIItemResNode = UIItemResNode
function UIItemResNode:OnInit()
end

function UIItemResNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:ShowRes(uiItemData.showRes)
end

function UIItemResNode:ShowRes(show)
    self:Enable(show)
end

--endregion 资源本node

--region 经验形态
---@class UIItemReduceNode:UIItemNodeBase
_class("UIItemReduceNode", UIItemNodeBase)
UIItemReduceNode = UIItemReduceNode
--endregion 经验形态

function UIItemReduceNode:OnInit()
    self._reduceNum = self._uiView:GetUIComponent("UILocalizationText", "reducenum")
    self._reduceNumBtn = self._uiView:GetGameObject("g_reduce_btn")

    self._uicustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._reduceNumBtn),
        UIEvent.Click,
        function(go)
            local clickCallBack = self._uiItemData.reduceCallBack
            if clickCallBack then
                clickCallBack()
            end
        end
    )
end

function UIItemReduceNode:SetReduceLongPressCallBack(sec)
    self._reducePressTime = sec
    self._longTrigger = false

    ----------------------
    self._uicustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._reduceNumBtn),
        UIEvent.Press,
        function(go)
            if GuideHelper.IsUIGuideShow() then
                return
            end
            if not self._reduceTimerEvent then
                self._longTrigger = true
                self._reduceTimerEvent =
                    GameGlobal.Timer():AddEventTimes(
                    self._reducePressTime,
                    TimerTriggerCount.Infinite,
                    function()
                        local clickCallBack = self._uiItemData.reduceCallBack
                        if clickCallBack then
                            clickCallBack()
                        end
                    end
                )
            end
        end
    )
    self._uicustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._reduceNumBtn),
        UIEvent.Unhovered,
        function(go)
            self._longTrigger = false
            if self._reduceTimerEvent then
                GameGlobal.Timer():CancelEvent(self._reduceTimerEvent)
                self._reduceTimerEvent = nil
            end
        end
    )
    self._uicustomEventListener:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._reduceNumBtn),
        UIEvent.Release,
        function(go)
            self._longTrigger = false
            if self._reduceTimerEvent then
                GameGlobal.Timer():CancelEvent(self._reduceTimerEvent)
                self._reduceTimerEvent = nil
            end
        end
    )
end

function UIItemReduceNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetReduceNum(uiItemData.reduceNum)
end

function UIItemReduceNode:ShowReduce(show)
    self:Enable(show)
end

function UIItemReduceNode:SetReduceNum(count)
    if not count or count <= 0 then
        self:ShowReduce(false)
        self._owner:Select(false)

        if self._longTrigger then
            self._longTrigger = false
            if self._reduceTimerEvent then
                GameGlobal.Timer():CancelEvent(self._reduceTimerEvent)
                self._reduceTimerEvent = nil
            end
        end
    else
        self:ShowReduce(true)
        self._owner:Select(true)
        self._reduceNum:SetText(count)
    end
end

--------------------- 好感度 -----------
---@class UIItemLoveNode
_class("UIItemLoveNode", UIItemNodeBase)
UIItemLoveNode = UIItemLoveNode

function UIItemLoveNode:OnInit()
    self._upPos = Vector2(-62, 72)
    self._downPos = Vector2(-62, 8)

    ---@type UnityEngine.RectTransform
    self._rect = self._uiView:GetUIComponent("RectTransform", "love")
end

function UIItemLoveNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData

    self:ShowLove(uiItemData.showLove)

    self:ChangePos(uiItemData.changePos, uiItemData.isUp)
end

function UIItemLoveNode:ChangePos(changePos, isUp)
    if not changePos then
        return
    end

    local targetPos

    if isUp then
        targetPos = self._upPos
    else
        targetPos = self._downPos
    end
    if self._tweener then
        self._tweener:Kill()
    end
    self._tweener = self._rect:DOAnchorPos(targetPos, 0.2)
end

function UIItemLoveNode:OnHide()
end

function UIItemLoveNode:ShowLove(show)
    self._isLoveShow = show
    self:Enable(show)
end
--------------------- 好感度 -----------

---------------------  奖励-----------
---@class UIItemAwardNode
_class("UIItemAwardNode", UIItemNodeBase)
UIItemAwardNode = UIItemAwardNode

function UIItemAwardNode:OnInit()
    self._awardTxt = self._uiView:GetUIComponent("UILocalizationText", "txt3Star")
end

function UIItemAwardNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetAwardText(uiItemData.awardText)
end

function UIItemAwardNode:SetAwardText(awardText)
    self._awardTxt:SetText(awardText)
end
---------------------  奖励-----------

---------------------  结算-----------
---@class UIItemResultNode
_class("UIItemResultNode", UIItemNodeBase)
UIItemResultNode = UIItemResultNode
---@class UIItemResultType
local UIItemResultType = {
    None = 0,
    Result = 1,
    ThreeStar = 2,
    First = 3,
    Ext = 4,
    Normal = 5,
    DoubleExt = 6,
    ResCoinExt = 7
}
_enum("UIItemResultType", UIItemResultType)

function UIItemResultNode:OnInit()
    self._resultGO = self._uiView:GetGameObject("ReturnPrism")
    self._threeStarGO = self._uiView:GetGameObject("ThreeStar")
    self._firstPassGO = self._uiView:GetGameObject("FirstPass")
    self._extraRewardGO = self._uiView:GetGameObject("extrareward")
    self._resultTxt = self._uiView:GetUIComponent("UILocalizationText", "ReturnTxt")
    self._normalGO = self._uiView:GetGameObject("normal")
    self._normalTxt = self._uiView:GetUIComponent("UILocalizationText", "normalTxt")
    self._doubleExtRewardGO = self._uiView:GetGameObject("doubleExtReward")
    self._resCoinExtRewardGO = self._uiView:GetGameObject("resCoinExtReward")
end

function UIItemResultNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:ShowResult(uiItemData.resultType)
    self:SetResultText(uiItemData.resultType, uiItemData.resultText)
    self:SetNormalText(uiItemData.resultType, uiItemData.normalText)
end

function UIItemResultNode:ShowResult(resultType)
    self._resultGO:SetActive(resultType == UIItemResultType.Result)
    self._threeStarGO:SetActive(resultType == UIItemResultType.ThreeStar)
    self._firstPassGO:SetActive(resultType == UIItemResultType.First)
    self._extraRewardGO:SetActive(resultType == UIItemResultType.Ext)
    self._normalGO:SetActive(resultType == UIItemResultType.Normal)
    self._doubleExtRewardGO:SetActive(resultType == UIItemResultType.DoubleExt)
    self._resCoinExtRewardGO:SetActive(resultType == UIItemResultType.ResCoinExt)
end

function UIItemResultNode:SetResultText(resultType, text)
    if resultType == UIItemResultType.Result then
        self._resultTxt:SetText(text)
    end
end

function UIItemResultNode:SetNormalText(resultType, text)
    if resultType == UIItemResultType.Normal then
        self._normalTxt:SetText(text)
    end
end
---------------------  奖励-----------

---------------------  顶条奖励-----------
---@class UIItemTopAwardNode
_class("UIItemTopAwardNode", UIItemNodeBase)
UIItemTopAwardNode = UIItemTopAwardNode
function UIItemTopAwardNode:OnInit()
    self._topText = self._uiView:GetUIComponent("UILocalizationText", "text")
    self._specailDrop = self._uiView:GetGameObject("specailDrop")
end

function UIItemTopAwardNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    if uiItemData.type == UIItemRandomType.TeBieDiaoLuo then
        self._topText.gameObject:SetActive(false)
        self._specailDrop:SetActive(true)
    else
        self:SetTopText(uiItemData.topText)
        self._specailDrop:SetActive(false)
    end
end

function UIItemTopAwardNode:ShowTopText(show)
    self:Enable(show)
end

function UIItemTopAwardNode:SetTopText(text)
    if not string.isnullorempty(text) then
        self:ShowTopText(true)
        self._topText:SetText(text)
    else
        self:ShowTopText(false)
    end
end
---------------------  顶条奖励-----------

---------------------  活动-----------
---@class UIItemActivityNode
_class("UIItemActivityNode", UIItemNodeBase)
UIItemActivityNode = UIItemActivityNode
function UIItemActivityNode:OnInit()
    self._imgbg = self._uiView:GetUIComponent("Image", "imgbg")
    self._text = self._uiView:GetUIComponent("UILocalizationText", "text")
    self._imgbgRect = self._uiView:GetUIComponent("RectTransform", "imgbg")
end

function UIItemActivityNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetText(uiItemData.activityText)
end

function UIItemActivityNode:ShowText(show)
    self:Enable(show)
end

function UIItemActivityNode:SetText(text)
    if not string.isnullorempty(text) then
        self:ShowText(true)
        self:_SetOffset()
        self._text:SetText(text)
    else
        self:ShowText(false)
    end
end

function UIItemActivityNode:_SetOffset()
    if self._itemForm == UIItemForm.Stage then
        self._imgbgRect.anchoredPosition = Vector2(-77.13, -42.7) --主线
    elseif self._itemForm == UIItemForm.ResInstance then
        self._imgbgRect.anchoredPosition = Vector2(-77.13, -62.55) --资源本
    elseif self._itemForm == UIItemForm.Result or self._itemForm == UIItemForm.Base then
        self._imgbgRect.anchoredPosition = Vector2(-85.12, 70.1) --战斗结算
    end
end
---------------------  活动-----------

------------------------ 回流 -----------
---@class UIItemReturnHelpNode
_class("UIItemReturnHelpNode", UIItemNodeBase)
UIItemReturnHelpNode = UIItemReturnHelpNode
function UIItemReturnHelpNode:OnInit()
    self._imgbg = self._uiView:GetUIComponent("Image", "imgbg")
    self._text = self._uiView:GetUIComponent("UILocalizationText", "text")
    self._imgbgRect = self._uiView:GetUIComponent("RectTransform", "imgbg")
end

function UIItemReturnHelpNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetText(uiItemData.returnHelpText)
end

function UIItemReturnHelpNode:ShowText(show)
    self:Enable(show)
end

function UIItemReturnHelpNode:SetText(text)
    if not string.isnullorempty(text) then
        self:ShowText(true)
        self._text:SetText(text)
    else
        self:ShowText(false)
    end
end
--------------------- 回流 -----------
---
---@class UIItemPackBackNode:UIItemNodeBase
_class("UIItemPackBackNode", UIItemNodeBase)
UIItemPackBackNode = UIItemPackBackNode
function UIItemPackBackNode:OnInit()
    self._toggle = self._uiView:GetUIComponent("Toggle", "toggle")
    self._toggleGo = self._uiView:GetGameObject("toggle")
    self._toggleBg = self._uiView:GetGameObject("toggleBg")
    self.OnToggleValueChanged = function (isOn) 
        if self._onValueChangedCallBack then 
            self._onValueChangedCallBack(isOn)
        end 
    end 
    self._toggle.onValueChanged:AddListener(self.OnToggleValueChanged)
end

function UIItemPackBackNode:OnShow()
    local hanveItem = self._uiItemData.itemId ~= 0
    self._toggleGo:SetActive(hanveItem)
    self._toggleBg:SetActive(true)
end

function UIItemPackBackNode:ShowText(show)

end

function UIItemPackBackNode:SetToggleGroup(group)
    self._toggle.group = group
end
function UIItemPackBackNode:SetToggleOnValueChangedCallBack(onValueChangedCallBack)
   self._onValueChangedCallBack = onValueChangedCallBack
end

function UIItemPackBackNode:SetToggleValue(isOn)
    self._toggle.isOn = isOn
end 
 

--region 快速升级
---@class PetLevelUpFastNode:UIItemNodeBase
_class("PetLevelUpFastNode", UIItemNodeBase)
PetLevelUpFastNode = PetLevelUpFastNode
--endregion 快速升级

function PetLevelUpFastNode:OnInit()
    self._go = self._uiView:GetGameObject("go")
    self._usenum = self._uiView:GetUIComponent("UILocalizationText", "usenum")
end

function PetLevelUpFastNode:OnShow()
    ---@type UIItemData
    local uiItemData = self._uiItemData
    self:SetItemUseNum(uiItemData.useNum)
end

function PetLevelUpFastNode:SetItemUseNum(count)
    if not count or count <= 0 then
        self._go:SetActive(false)
        self._owner:Select(false)
    else
        self._go:SetActive(true)
        self._owner:Select(true)
        self._usenum:SetText(count)
    end
end




