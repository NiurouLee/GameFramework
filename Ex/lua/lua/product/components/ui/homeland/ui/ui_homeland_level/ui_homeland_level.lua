---@class UIHomelandLevel:UIController
_class("UIHomelandLevel", UIController)
UIHomelandLevel = UIHomelandLevel

function UIHomelandLevel:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetHomelandLevelData()
end

---@param res AsyncRequestRes
function UIHomelandLevel:LoadDataOnEnter(TT, res, uiParams)
    local reqRes = self.mHomeland:HomelandGetSignInfo(TT)
    if reqRes:GetSucc() then
        res:SetSucc(true)
    else
        ToastManager.ShowHomeToast(reqRes:GetResult())
        res:SetSucc(false)
    end
end

function UIHomelandLevel:OnShow(uiParams)
    self.redAward = self:GetGameObject("redAward")
    self.redAward:SetActive(false)

    self.btnImageLevel = self:GetUIComponent("Image", "btnLevel")
    self.btnImageAward = self:GetUIComponent("Image", "btnAward")
    self.btnTextLevel = self:GetUIComponent("UILocalizationText", "btnLevelTxt")
    self.btnTextAward = self:GetUIComponent("UILocalizationText", "btnAwardTxt")

    self.level = self:GetGameObject("level")
    ---@type UILocalizationText
    self.txtLevel = self:GetUIComponent("UILocalizationText", "txtLevel")
    ---@type UnityEngine.UI.Slider
    self.sldExp = self:GetUIComponent("Slider", "sldExp")
    ---@type UILocalizationText
    self.txtExp = self:GetUIComponent("UILocalizationText", "txtExp")
    ---@type UILocalizationText
    self.txtLiveable = self:GetUIComponent("UILocalizationText", "txtLiveable")
    ---@type UILocalizationText
    self.txtSignExp = self:GetUIComponent("UILocalizationText", "txtSignExp")
    ---@type UILocalizationText
    self.txtGetBtn = self:GetUIComponent("UILocalizationText", "btnGettxt")

    self.award = self:GetGameObject("award")
    ---@type UnityEngine.UI.ScrollRect
    self.sv = self:GetUIComponent("ScrollRect", "sv")
    ---@type UICustomWidgetPool
    self.cLevels = self:GetUIComponent("UISelectObjectPath", "cLevels")
    ---@type UICustomWidgetPool
    self.cDescs = self:GetUIComponent("UISelectObjectPath", "cDescs")
    ---@type UICustomWidgetPool
    self.cAwards = self:GetUIComponent("UISelectObjectPath", "cAwards")
    ---@type UnityEngine.UI.ScrollRect
    self.awardsv = self:GetUIComponent("ScrollRect", "awardsv")
    self.awardRect = self:GetUIComponent("RectTransform", "cAwards")
    self.signRed = self:GetGameObject("signRed")
    self.redSignAward = self:GetGameObject("redSignAward")
    self.stateimg = self:GetUIComponent("Image", "stateimg")
    self.signintext =  self:GetGameObject("signintext")
    self.signintext1 =  self:GetGameObject("signintext1")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIHomelandLevel.spriteatlas", LoadType.SpriteAtlas)

    self:AttachEvent(GameEventType.HomelandLevelClickLevelItem, self.HomelandLevelClickLevelItem)
    self:AttachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self.HomelandLevelOnLevelInfoChange)

    self.tabIdx = 1 --【1】家园等级；【2】等级奖励
    self.curSelectLevel = 1 --当前选中的等级
    self:Init()
    self:Flush()
    self:RegisterTimeEvent()
    self:_CheckGuide()

    local matObj = self:GetAsset("uieff_n17_homeland_level.mat", LoadType.Mat)
    local levelTip = self:GetUIComponent("UILocalizedTMP", "LevelTMP")
    local mat = levelTip.fontMaterial
    levelTip.fontMaterial = matObj
    levelTip.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end
function UIHomelandLevel:OnHide()
    self:CancelTimerEvent()
    self:DetachEvent(GameEventType.HomelandLevelClickLevelItem, self.HomelandLevelClickLevelItem)
    self:DetachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self.HomelandLevelOnLevelInfoChange)
end

--region Init
function UIHomelandLevel:Init()
    self:InitAward()
end
function UIHomelandLevel:InitAward()
    local len = table.count(self.data.levels)
    self.cLevels:SpawnObjects("UIHomelandLevelItem", len)
end
--endregion

--region Init
function UIHomelandLevel:Flush()
    self:FlushAwardRed()
    if self.tabIdx == 1 then
        self:SetBtnStyle(true, self.btnImageLevel, self.btnTextLevel)
        self.level:SetActive(true)

        self:SetBtnStyle(false, self.btnImageAward, self.btnTextAward)
        self.award:SetActive(false)
        self:FlushLevel()
    elseif self.tabIdx == 2 then
        self:SetBtnStyle(false, self.btnImageLevel, self.btnTextLevel)
        self.level:SetActive(false)

        self:SetBtnStyle(true, self.btnImageAward, self.btnTextAward)
        self.award:SetActive(true)
        self:FlushAward()
    else
        Log.warn("### invalid tabIdx:", self.tabIdx)
    end
end

---@param image UnityEngine.UI.Image
---@param text UILocalizationText
function UIHomelandLevel:SetBtnStyle(active, image, text)
    if active then
        image.sprite = self._atlas:GetSprite("n17_level_btn1")
        text.color = Color.white
    else
        image.sprite = self._atlas:GetSprite("n17_level_btn2")
        text.color = Color(73 / 255, 73 / 255, 73 / 255)
    end
end

---家园等级红点
function UIHomelandLevel:FlushAwardRed()
    self.redAward:SetActive(self.data:HasLevelAward())
    self.redSignAward:SetActive(self.data:HasSignAward())
end
function UIHomelandLevel:FlushLevel()
    self.txtLevel:SetText(self.data.level)
    local curLevelData = self.data:GetHomelandLevelItemDataByLevel(self.data.level)
    self.sldExp.minValue = curLevelData.expLow
    self.sldExp.maxValue = curLevelData.expHigh
    self.sldExp.value = self.data.exp
    if self.data:IsLevelMax() then
        self.txtExp:SetText(StringTable.Get("str_homeland_level_full"))
    else
        self.txtExp:SetText("<color=#FF9600>" .. self.data.exp .. "</color>/" .. curLevelData.expHigh)
    end

    self.txtLiveable:SetText(self.data.liveable)
    -- local count = 0
    -- if not self.data.signedToday then
    --     count = self.data.awardSign.count
    -- end
    -- self.txtSignExp:SetText(count)

    self.signRed:SetActive(self.data:HasSignAward())
    self.signintext:SetActive(not self.data:HasSignedToday())
    self.signintext1:SetActive(self.data:HasSignedToday())
    if  self.data:HasSignedToday()  then
        self.stateimg.sprite = self._atlas:GetSprite("n17_level_unget")
    else
        self.stateimg.sprite = self._atlas:GetSprite("n17_level_get")
       
    end
end
function UIHomelandLevel:FlushAward()
    ---@type UIHomelandLevelItem[]
    local uis = self.cLevels:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local item = self.data.levels[i]
        if item then
            ui:Flush(item.level)
            ui:FlushSelect(self.curSelectLevel)
        end
    end

    local levelDescs = self.data:GetLevelDescs(self.curSelectLevel)
    self.cDescs:SpawnObjects("UIHomelandLevelDescItem", #levelDescs)
    ---@type UIHomelandLevelDescItem[]
    local uis = self.cDescs:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        ui:Flush(levelDescs[i])
    end

    local curLevelData = self.data:GetHomelandLevelItemDataByLevel(self.curSelectLevel)
    local len = table.count(curLevelData.awards)
    self.cAwards:SpawnObjects("UIItemHomeland", len)
    ---@type UIItemHomeland[]
    local uis = self.cAwards:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local item = curLevelData.awards[i]
        if item then
            ui:Flush(item)
        end
    end
    UIHelper.RefreshLayout(self.awardRect)
    self.awardsv.horizontalNormalizedPosition = 0

    if curLevelData.state == nil then
        self.txtGetBtn:SetText(StringTable.Get("str_homeland_level_btn_down"))
    elseif curLevelData.state == HomelandLevelItemDataState.HasGot then
        self.txtGetBtn:SetText(StringTable.Get("str_homeland_level_got"))
    elseif curLevelData.state == HomelandLevelItemDataState.CanGet then
        self.txtGetBtn:SetText(StringTable.Get("str_homeland_level_receive_awards"))
    end
end
--endregion

function UIHomelandLevel:RegisterTimeEvent()
    self:CancelTimerEvent()
    local stampNext = self.data:GetNextSignTime()
    local stampNow = UICommonHelper.GetNowTimestamp()
    local delay = stampNext - stampNow
    if delay < 0 then
        delay = 1
    else
        delay = delay + 1
    end
    self.te =
        GameGlobal.Timer():AddEventTimes(
        delay * 1000,
        TimerTriggerCount.Once,
        function()
            Log.fatal("### UIHomelandLevel RegisterTimeEvent delay=", delay)
            self:StartTask(self.HomelandGetSignInfo, self)
        end
    )
end
function UIHomelandLevel:CancelTimerEvent()
    if self.te then
        GameGlobal.Timer():CancelEvent(self.te)
    end
end
function UIHomelandLevel:HomelandGetSignInfo(TT)
    local key = "UIHomelandLevelHomelandGetSignInfo"
    self:Lock(key)
    local res = self.mHomeland:HomelandGetSignInfo(TT)
    if UIHomelandLevelData.CheckCode(res:GetResult()) then
        self.data:Init()
        self:Flush()
    end
    self:UnLock(key)
    self:RegisterTimeEvent()
end

function UIHomelandLevel:HomelandLevelClickLevelItem(level)
    if self.curSelectLevel ~= level then
        self.curSelectLevel = level
        self:FlushAward()
    end
end

function UIHomelandLevel:HomelandLevelOnLevelInfoChange()
    self.curSelectLevel = self.data.level
    self:Flush()
    self:CLevelsMove2CurLevel()
end

function UIHomelandLevel:CLevelsMove2CurLevel()
    local len = table.count(self.data.levels)
    if len > 1 then
        self.sv.horizontalNormalizedPosition = (self.data.level - 1) / (len - 1)
    else
        self.sv.horizontalNormalizedPosition = 0
    end
end

--region OnClick
function UIHomelandLevel:btnCloseOnClick(go)
    self:CloseDialog()
end

function UIHomelandLevel:btnLevelOnClick(go)
    if self.tabIdx ~= 1 then
        self.tabIdx = 1
        self:Flush()
    end
end
function UIHomelandLevel:btnAwardOnClick(go)
    if self.tabIdx ~= 2 then
        self.tabIdx = 2
        self.curSelectLevel = self.data.level
        self:Flush()
        self:CLevelsMove2CurLevel()
    end
end
function UIHomelandLevel:imgSignOnClick(go)
    if self.data:CheckSignedToday() then
        return
    end

    local call = function()
        self:StartTask(
            function(TT)
                local key = "UIHomelandLevelimgSignOnClick"
                self:Lock(key)
                local res = self.mHomeland:HomelandSign(TT)
                if UIHomelandLevelData.CheckCode(res:GetResult()) then
                    local awardSigns = self.data.awardSign
                    if awardSigns and table.count(awardSigns) > 0 then
                        local title = StringTable.Get("str_homeland_level_signed_award")
                        self:ShowDialog("UIHomeShowAwards", awardSigns, nil, true, title)
                    end
                    self.data:Init()
                    self:Flush()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomeAfterCollectLevelReward)
                end
                self:UnLock(key)
            end,
            self
        )
    end
    local showAward = false 
    local award = nil 
    for i = 1, #self.data.awardSign do
        if self.data.awardSign[i].assetid == UIHomelandShopHelper.GetCoinItemId() then 
            showAward = true 
            award = self.data.awardSign[i]
        end 
    end
    if showAward then 
        UIHomelandShopHelper.CheckCoinOverflow(award.count, call)
    else 
        call()
    end 
end
function UIHomelandLevel:btnSignTipOnClick(go)
    self:ShowDialog("UIHomelandLevelSignPop")
end

function UIHomelandLevel:expFormBtnOnClick(go)
    self:ShowDialog("UIHomelandLevelExpTips")
end

function UIHomelandLevel:btnGetOnClick(go)
    local curLevelData = self.data:GetHomelandLevelItemDataByLevel(self.curSelectLevel)
    if not curLevelData.state then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_level_not_reach"))
        return
    elseif curLevelData.state == HomelandLevelItemDataState.HasGot then
        return
    end
    self:StartTask(
        function(TT)
            local key = "UIHomelandLevelbtnGetOnClick"
            self:Lock(key)
            local res, assets = self.mHomeland:HomelandLevelReward(TT, self.curSelectLevel)
            if UIHomelandLevelData.CheckCode(res:GetResult()) then
                if assets and table.count(assets) > 0 then
                    self:ShowDialog("UIHomeShowAwards", assets, nil, true, StringTable.Get("str_homeland_level_award"))
                end
                self.data:Init()
                self:Flush()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.HomeAfterCollectLevelReward)
            end
            self:UnLock(key)
        end,
        self
    )
end
--endregion

--N17 家园等级引导
function UIHomelandLevel:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIHomelandLevel)
end
