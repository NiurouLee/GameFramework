---@class UIN20AVGCollection:UIController
_class("UIN20AVGCollection", UIController)
UIN20AVGCollection = UIN20AVGCollection

function UIN20AVGCollection:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
    self.mItem = GameGlobal.GetModule(ItemModule)
end

function UIN20AVGCollection:OnShow(uiParams)
    self.redTabBadge = self:GetGameObject("redTabBadge")
    self.newTabBadge = self:GetGameObject("newTabBadge")
    ---@type UnityEngine.UI.ScrollRect
    self.sv = self:GetUIComponent("ScrollRect", "sv")
    ---@type UICustomWidgetPool
    self.poolContent = self:GetUIComponent("UISelectObjectPath", "Content")
    self.badge = self:GetGameObject("badge")
    self.badgeSelect = self:GetGameObject("badgeSelect")
    self.badge:SetActive(false)
    self.cg = self:GetGameObject("cg")
    self.cg:SetActive(false)
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    ---@type UnityEngine.UI.Slider
    self.sldProgress = self:GetUIComponent("Slider", "sldProgress")
    ---@type UnityEngine.RectTransform
    self.rtProgress = self:GetUIComponent("RectTransform", "sldProgress")
    ---@type UICustomWidgetPool
    self.poolProgress = self:GetUIComponent("UISelectObjectPath", "poolProgress")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    ---@type UICustomWidgetPool
    self.poolBadge = self:GetUIComponent("UISelectObjectPath", "poolBadge")
    self.time = self:GetGameObject("time")
    ---@type UILocalizationText
    self.txtGetTime = self:GetUIComponent("UILocalizationText", "txtGetTime")
    ---@type RawImageLoader
    self.imgCG = self:GetUIComponent("RawImageLoader", "imgCG")
    self.suo = self:GetGameObject("suo")
    self.btnShowCG = self:GetGameObject("btnShowCG")
    self.btnShowCG:SetActive(false)
    ---@type UILocalizationText
    self.txtGetCondition = self:GetUIComponent("UILocalizationText", "txtGetCondition")
    ---@type UICustomWidgetPool
    self.poolCGAward = self:GetUIComponent("UISelectObjectPath", "cgAward")
    self.got = self:GetGameObject("got")
    self.canGet = self:GetGameObject("canGet")
    self.goBigCG = self:GetGameObject("goBigCG")
    self.goBigCG:SetActive(false)
    ---@type RawImageLoader
    self.imgBigCG = self:GetUIComponent("RawImageLoader", "imgBigCG")

    self:FlushTab()
    self.curEndId = -1
    self:AutoSelectTab()
end

function UIN20AVGCollection:OnHide()
    self.imgCG:DestoryLastImage()
    self.imgBigCG:DestoryLastImage()
end

---设置当前结局页签id，0为徽章
function UIN20AVGCollection:SetCurEndId(endId)
    if endId == self.curEndId then
        return
    end
    self.curEndId = endId
    ---@type UIN20AVGCollectionItem[]
    local uis = self.poolContent:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        if endId == ui:EndId() then
            ui:FlushSelect(true)
            self.badge:SetActive(false)
            self.cg:SetActive(true)
            self:FlushCG()
        else
            ui:FlushSelect(false)
        end
    end
    if endId == 0 then
        self.badgeSelect:SetActive(true)
        self.badge:SetActive(true)
        self.cg:SetActive(false)
        self:FlushBadge()
        self:FlushTabBadgeNewEffect()
    else
        self.badgeSelect:SetActive(false)
        self:FlushTabCgNew()
    end
end

function UIN20AVGCollection:FlushTab()
    ---@type AVGEnding[]
    local notBEs = {}
    for index, ending in ipairs(self.data.endings) do
        if not ending.isBE then
            table.insert(notBEs, ending)
        end
    end
    local len = table.count(notBEs)
    self.poolContent:SpawnObjects("UIN20AVGCollectionItem", len)
    ---@type UIN20AVGCollectionItem[]
    local uis = self.poolContent:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local ending = notBEs[i]
        local endId = ending.id
        ui:Flush(
            endId,
            function()
                self:SetCurEndId(endId)
            end
        )
    end
    self:FlushTabBadgeRed()
    self:FlushTabBadgeNew()
end

function UIN20AVGCollection:FlushTabBadgeRed()
    local isShow = self.data:HasRedBadge()
    self.redTabBadge:SetActive(isShow)
end

function UIN20AVGCollection:FlushTabBadgeNew()
    local isShow = self.data:HasNewBadge()
    self.newTabBadge:SetActive(isShow)
end

---自动选择New页签，只在界面打开时调用
function UIN20AVGCollection:AutoSelectTab()
    --优先选中徽章页签
    if self.data:HasNewBadge() then
        self:SetCurEndId(0)
        return
    end
    --其次选中CG页签
    for index, ending in ipairs(self.data.endings) do
        if ending:HasNew() then
            self:SetCurEndId(ending.id)
            return
        end
    end
    self:SetCurEndId(0) --没有new默认显示徽章
end

function UIN20AVGCollection:FlushBadge()
    local countReach, count = 0, 0
    for _, badge in ipairs(self.data.badges) do
        count = count + 1
        if badge:HasGot() then
            countReach = countReach + 1
        end
    end
    self.txtCount:SetText(countReach .. "/" .. count)
    self.sldProgress.maxValue = count
    self.sldProgress.value = countReach
    --徽章奖励
    local len = table.count(self.data.badgeStages)
    self.poolProgress:SpawnObjects("UIN20AVGBadgeProgressItem", len)
    ---@type UIN20AVGBadgeProgressItem[]
    local uis = self.poolProgress:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local badgeStage = self.data.badgeStages[i]
        ui:Flush(
            badgeStage.id,
            function()
                local state = badgeStage:State()
                if state == AVGAwardState.CanGet then
                    self:StartTask(
                        function(TT)
                            local c = self.data:GetComponentAVG()
                            local res = AsyncRequestRes:New()
                            local ret = c:HandleGetBadgeReward(TT, res, badgeStage.id) --【消息】领取徽章奖励
                            if N20AVGData.CheckCode(res) then
                                UIActivityHelper.ShowUIGetRewards(badgeStage.awards)
                                self:FlushTab()
                                self:FlushBadge()
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGFlushNewRed)
                            end
                        end
                    )
                else
                    local award = badgeStage.awards[1]
                    self:ShowDialog("UIItemTips", award, ui:GetGameObject(), "UIN20AVGCollection", Vector2(-377, 0))
                end
            end
        )
        local pos = Vector2(self.rtProgress.rect.width * badgeStage.count / count, 0)
        ui:FlushPos(pos)
    end
    --徽章
    len = table.count(self.data.badges)
    self.poolBadge:SpawnObjects("UIN20AVGBadgeItem", len)
    ---@type UIN20AVGBadgeItem[]
    local uis = self.poolBadge:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local badge = self.data.badges[i]
        ui:Flush(
            badge.id,
            function()
                for i, ui in ipairs(uis) do
                    ui:FlushSelect(badge.id)
                end
                local showName
                if badge:HasGot() then
                    showName = badge.name
                else
                    showName = "???"
                end
                self.txtName:SetText(showName)
                self.txtDesc:SetText(badge.desc)
            end
        )
        ui:FlushPos(badge.pos)
        if i == 1 then
            ui:btnOnClick()
        end
    end
end

function UIN20AVGCollection:FlushTabBadgeNewEffect()
    if self.curEndId ~= 0 then
        return
    end
    self:StartTask(
        function(TT)
            if self.data:HasNewBadge() then
                local key = "UIN20AVGCollection_FlushTabBadgeNewEffect"
                self:Lock(key)
                YIELD(TT, 500) -- 第一个之前的延时

                for index, badge in ipairs(self.data.badges) do
                    if badge:HasNew() then
                        self:BadgeNewEffect(TT, index, badge)

                        local items = self.mItem:GetItemByTempId(badge.itemId) --【消息】徽章New
                        for _, item in pairs(items) do
                            local pstId = item:GetID()
                            self.mItem:SetItemUnnewOverlay(TT, pstId)
                        end
                    end
                end
                self:UnLock(key)

                self:FlushTabBadgeRed()
                self:FlushTabBadgeNew()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGFlushNewRed)
            end
        end,
        self
    )
end

-- 播放 徽章 盖章动效
function UIN20AVGCollection:BadgeNewEffect(TT, index, badge)
    ---@type UIN20AVGBadgeItem[]
    local uis = self.poolBadge:GetAllSpawnList()
    local ui = uis[index]
    self:_MoveTransform(ui)
    ui:FlushNewEffect(badge.pos)
    YIELD(TT, 800 + 700) -- 两段动效长度
end

-- 移动节点
function UIN20AVGCollection:_MoveTransform(obj)
    local trans = obj:GetGameObject():GetComponent("Transform")
    trans:SetAsLastSibling()
end

---刷新当前选中的CG
function UIN20AVGCollection:FlushCG()
    local ending = self.data:GetEndingById(self.curEndId)
    local state = ending:AwardState()
    local hasNew = ending:HasNew() -- 判断是否解锁动效

    if state then
        self.time:SetActive(true)
        local timestampGot = ending:GetTimestamp()
        local str = self.data:Timestamp2Str(timestampGot)
        self.txtGetTime:SetText(StringTable.Get("str_avg_n20_get_time", str))
        self.imgCG:LoadImage(ending.cgCollect)

        -- 解锁动效
        self.suo:SetActive(hasNew)
        if hasNew then
            UIWidgetHelper.PlayAnimation(self, "anim", "uieff_UIN20AVGCollection_cg", 2033)
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20GetCG)
        end

        self.imgBigCG:LoadImage(ending.cg)
        self.btnShowCG:SetActive(true)
    else
        self.time:SetActive(false)
        self.imgCG:LoadImage("N20_avg_sc_image01")
        self.btnShowCG:SetActive(false)
    end

    self.txtGetCondition:SetText(ending.getConditionDesc)
    local awardState = ending:AwardState()
    --CG奖励
    local len = table.count(ending.awards)
    self.poolCGAward:SpawnObjects("UIN20AVGCGAward", len)
    ---@type UIN20AVGCGAward[]
    local uis = self.poolCGAward:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local ra = ending.awards[i]
        ui:Flush(
            ra,
            function()
                self:ShowDialog("UIItemTips", ra, ui:GetGameObject(), "UIN20AVGCollection", Vector2(0, 250))
            end
        )
        ui:FlushGot(awardState == AVGAwardState.Got)
    end
    --状态
    if awardState then
        if awardState == AVGAwardState.CanGet then
            self.got:SetActive(false)
            self.canGet:SetActive(true)
        else
            self.got:SetActive(true)
            self.canGet:SetActive(false)
        end
    else
        self.got:SetActive(false)
        self.canGet:SetActive(false)
    end
end

function UIN20AVGCollection:FlushTabCgNew()
    if self.curEndId == 0 then
        return
    end
    ---@type UIN20AVGCollectionItem[]
    local uis = self.poolContent:GetAllSpawnList()
    local len = table.count(uis)
    for i, ui in ipairs(uis) do
        if self.curEndId == ui:EndId() then
            local fz = i - 1
            local fm = len - 1
            if fm > 0 then
                self.sv.verticalNormalizedPosition = 1 - fz / fm
            else
                self.sv.verticalNormalizedPosition = 0
            end
            break
        end
    end
    self:StartTask(
        function(TT)
            local ending = self.data:GetEndingById(self.curEndId)
            if ending:HasNew() then
                local items = self.mItem:GetItemByTempId(ending.itemId) --【消息】CG New
                for _, item in pairs(items) do
                    local key = "UIN20AVGCollectionFlushTab"
                    self:Lock(key)
                    local pstId = item:GetID()
                    self.mItem:SetItemUnnewOverlay(TT, pstId)
                    self:FlushTab()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGFlushNewRed)
                    self:UnLock(key)
                end
            end
        end,
        self
    )
end

--region OnClick

function UIN20AVGCollection:btnExitOnClick(go)
    -------------------------------------------------
    -- Test
    -- self:_Test_SetCgNew()
    -- self:_Test_SetBadgeNew()
    -------------------------------------------------

    self:CloseDialog()
end

function UIN20AVGCollection:imgTabBadgeOnClick(go)
    self:SetCurEndId(0)
end

function UIN20AVGCollection:btnAwardOnClick(go)
    local ending = self.data:GetEndingById(self.curEndId)
    local awardState = ending:AwardState()
    if awardState == AVGAwardState.CanGet then
        self:StartTask(
            function(TT)
                local key = "UIN20AVGCollectionbtnAwardOnClick"
                self:Lock(key)
                local c = self.data:GetComponentAVG()
                local res = AsyncRequestRes:New()
                local res = c:HandleAcceptCgReward(TT, ending.itemIdGift) --【消息】领取CG奖励
                if N20AVGData.CheckCode(res) then
                    UIActivityHelper.ShowUIGetRewards(ending.awards)
                    self:FlushTab()
                    self:FlushCG()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGFlushNewRed)
                end
                self:UnLock(key)
            end
        )
    end
end

function UIN20AVGCollection:btnShowCGOnClick(go)
    self.goBigCG:SetActive(true)
end

function UIN20AVGCollection:imgBGOnClick(go)
    self.goBigCG:SetActive(false)
end

--endregion

--region Test

-- 测试，增加 new
function UIN20AVGCollection:_Test_SetCgNew()
    if not UIActivityHelper.CheckDebugOpen() then
        return
    end

    self:StartTask(
        function(TT)
            ---@type AVGEnding[]
            local notBEs = {}
            for index, ending in ipairs(self.data.endings) do
                if not ending.isBE then
                    local items = self.mItem:GetItemByTempId(ending.itemId) --【消息】CG New
                    for _, item in pairs(items) do
                        local key = "UIN20AVGCollectionFlushTab"
                        self:Lock(key)
                        local pstId = item:GetID()
                        self.mItem:_RequestItemOverlayFlag(TT, pstId, ItemDataFlags.Item_Flag_Is_New_Overlay, true)
                        self:UnLock(key)
                    end
                end
            end
        end,
        self
    )
end

-- 测试，增加 new
function UIN20AVGCollection:_Test_SetBadgeNew()
    if not UIActivityHelper.CheckDebugOpen() then
        return
    end

    self:StartTask(
        function(TT)
            for index, badge in ipairs(self.data.badges) do
                -- if index ~= 6 then
                local items = self.mItem:GetItemByTempId(badge.itemId) --【消息】徽章New
                for _, item in pairs(items) do
                    local key = "UIN20AVGCollectionFlushTab"
                    self:Lock(key)
                    local pstId = item:GetID()
                    self.mItem:_RequestItemOverlayFlag(TT, pstId, ItemDataFlags.Item_Flag_Is_New_Overlay, true)
                    self:UnLock(key)
                end
                -- end
            end
        end,
        self
    )
end

--endregion
