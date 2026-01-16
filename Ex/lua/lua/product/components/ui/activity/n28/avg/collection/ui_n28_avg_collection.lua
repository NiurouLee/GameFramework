---@class UIN28AVGCollection:UIController
_class("UIN28AVGCollection", UIController)
UIN28AVGCollection = UIN28AVGCollection

function UIN28AVGCollection:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
    self.mItem = GameGlobal.GetModule(ItemModule)
end

function UIN28AVGCollection:OnShow(uiParams)
    self.redTabBadge = self:GetGameObject("redTabBadge")
    self.newTabBadge = self:GetGameObject("newTabBadge")
    self.newTabEvidence = self:GetGameObject("newTabEvidence")
    ---@type UnityEngine.UI.ScrollRect
    self.sv = self:GetUIComponent("ScrollRect", "sv")
    ---@type UICustomWidgetPool
    self.poolContent = self:GetUIComponent("UISelectObjectPath", "Content")
    self.poolContentTrans = self:GetUIComponent("RectTransform", "Content")
    self.badge = self:GetGameObject("badge")
    self.badgeSelect = self:GetGameObject("badgeSelect")
    self.evidenceSelect = self:GetGameObject("evidenceSelect")
    self.badge:SetActive(false)

    self.evience = self:GetGameObject("evience")
    ---@type UICustomWidgetPool
    self.poolEvidence = self:GetUIComponent("UISelectObjectPath", "poolEvidence")
    ---@type UILocalizationText
    self.evidenceTitle = self:GetUIComponent("UILocalizationText", "evidenceTitle")
    ---@type UILocalizationText
    self.evidenceDetail = self:GetUIComponent("UILocalizationText", "evidenceDetail")
    ---@type UILocalizationText
    self.evidenceSelectCount = self:GetUIComponent("UILocalizationText", "evidenceSelectCount")
    self.evidenceSelectCountObj = self:GetGameObject("evidenceSelectCount")
    ---@type RawImageLoader
    self.evidenceIconImage= self:GetUIComponent("RawImageLoader", "evidenceIconImage")

    self.cg = self:GetGameObject("cg")
    self.cg:SetActive(false)
    ---@type UILocalizationText
    self.txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
    ---@type UILocalizationText
    self.evidenceTxtCount = self:GetUIComponent("UILocalizationText", "evidenceTxtCount")
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
    self.timeNotGet = self:GetGameObject("timeNotGet")
    ---@type UILocalizationText
    self.txtGetTime = self:GetUIComponent("UILocalizationText", "txtGetTime")
    ---@type RawImageLoader
    self.imgCG = self:GetUIComponent("RawImageLoader", "imgCG")
    self.imgCGObj = self:GetGameObject("imgCG")
    self.suo = self:GetGameObject("suo")
    self.btnShowCG = self:GetGameObject("btnShowCG")
    self.btnShowCG:SetActive(false)
    ---@type UILocalizationText
    self.txtGetCondition = self:GetUIComponent("UILocalizationText", "txtGetCondition")
    ---@type UICustomWidgetPool
    self.poolCGAward = self:GetUIComponent("UISelectObjectPath", "cgAward")
    self.poolItemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._tips = self.poolItemInfo:SpawnObject("UISelectInfo")
    self.got = self:GetGameObject("got")
    self.canGet = self:GetGameObject("canGet")
    self.goBigCG = self:GetGameObject("goBigCG")
    self.evidenceDescPanel = self:GetGameObject("evidenceDescPanel")
    self.evidenceNotGetPanel = self:GetGameObject("evidenceNotGetPanel")
    self.evidencePanelBtnsObj = self:GetGameObject("evidencePanelBtns")
    self.evidenceLeftBtnObj = self:GetGameObject("evidenceLeftBtn")
    self.evidenceRightBtnObj = self:GetGameObject("evidenceRightBtn")
    self.goBigCG:SetActive(false)
    ---@type RawImageLoader
    self.imgBigCG = self:GetUIComponent("RawImageLoader", "imgBigCG")
    self.evidenceContent = self:GetUIComponent("RectTransform", "evidenceContent")
    self.evidencePanelAnim = self:GetUIComponent("Animation", "evidencePanelAnim")
    --界面切换动效
    self.contentAnimCfg = 
    {
        [0] = 
        {
            anim = "badgeAnim",
            animIn = "uieff_UIN28AVGCollection_Badge_in", 
            animOut = "uieff_UIN28AVGCollection_Badge_out"
        },
        [1] = 
        {
            anim = "evienceAnim",
            animIn = "uieff_UIN28AVGCollection_evience_in", 
            animOut = "uieff_UIN28AVGCollection_evience_out"
        },
        [2] = 
        {
            anim = "cgAnim",
            animIn = "uieff_UIN28AVGMain_cg_in", 
            animOut = "uieff_UIN28AVGMain_cg_out"
        }
    }
    --证据界面动效
    self:AttachEvent(GameEventType.AVGSelectCollectionEvidenceItem, self.OnSelectEvidenceType)
    self:FlushTab()
    self.curEndId = -1
    self.poolEvidenceTypeMap = {}
    self.evidenceTypeOrderList = {}
    self.hasGotEvidenceCount = 0
    self.curSelectEvidenceType = nil
    self.curSelectEvidenceIdx = nil
    self.curEvidenceHasCount = 0
    self.curEvidenceMaxCountCount = 0
    self.curHasEvidenceList = {}
    self:InitEvidenceTypeMap()
    self:AutoSelectTab()
end

function UIN28AVGCollection:OnHide()
    self.imgCG:DestoryLastImage()
    self.imgBigCG:DestoryLastImage()
    self:DetachEvent(GameEventType.AVGSelectCollectionEvidenceItem, self.OnSelectEvidenceType)
end

---设置当前结局页签id，0为徽章,1为证据
function UIN28AVGCollection:SetCurEndId(endId)
    if endId == self.curEndId then
        return
    end
    local uis = self.poolContent:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        --cg
        if endId == ui:EndId() then
            ui:FlushSelect(true)
        else
            ui:FlushSelect(false)
        end
    end
    local fromAnimID = self.curEndId == -1 and self.curEndId or self:GetChangeContentAnimID(self.curEndId)
    local targetAnimID = self:GetChangeContentAnimID(endId)
    self.curEndId = endId
    --选择徽章
    if endId == 0 then
        self.evidenceSelect:SetActive(false)
        self.badgeSelect:SetActive(true)
        self:DoChangeContentAnimation(fromAnimID, targetAnimID, 
        function()
            self.evience:SetActive(false)
            self.cg:SetActive(false)
        end,
        function()
            self.badge:SetActive(true)
            self:FlushBadge()
            self:FlushTabBadgeNewEffect()
        end)
    --选择证据
    elseif endId == 1 then
        self.badgeSelect:SetActive(false)
        self.evidenceSelect:SetActive(true)
        self:DoChangeContentAnimation(fromAnimID, targetAnimID, 
        function()
            self.badge:SetActive(false)
            self.cg:SetActive(false)
        end,
        function()
            self.evience:SetActive(true)
            self:FlushEvidence(true)
        end)
    --CG
    else
        self.evidenceSelect:SetActive(false)
        self.badgeSelect:SetActive(false)
        self:DoChangeContentAnimation(fromAnimID, targetAnimID, 
        function()
            self.evience:SetActive(false)
            self.badge:SetActive(false)
        end,
        function()
            self.cg:SetActive(true)
            self:FlushCG()
            self:FlushTabCgNew()
        end)
    end
    self:FlushTabPos()
end

function UIN28AVGCollection:_ShowRewardTips(id, pos)
    self._tips:SetData(id, pos)
end


function UIN28AVGCollection:GetChangeContentAnimID(endID)
    return (endID == 0 or endID == 1) and endID or 2
end

function UIN28AVGCollection:DoChangeContentAnimation(fromID, targetID, cbOut, cbIn)
    local t = self.contentAnimCfg[targetID]
    local f = self.contentAnimCfg[fromID]
    local key = "UIN28AVGCollection_DoChangeContentAnimation"
    self:Lock(key)
    if f then
        UIWidgetHelper.PlayAnimation(self, f.anim, f.animOut, 160, function()
            cbOut()
            cbIn()
            UIWidgetHelper.PlayAnimation(self, t.anim, t.animIn, 200, function()
                self:UnLock(key)
            end)
        end)
    else
        cbIn()
        UIWidgetHelper.PlayAnimation(self, t.anim, t.animIn, 100, function()
            self:UnLock(key)
        end)
    end
end

function UIN28AVGCollection:FlushTab()
    ---@type N28AVGEnding[]
    local notBEs = {}
    for index, ending in ipairs(self.data.endings) do
        if not ending.isBE then
            table.insert(notBEs, ending)
        end
    end
    local len = table.count(notBEs)
    self.poolContent:SpawnObjects("UIN28AVGCollectionItem", len)
    ---@type UIN28AVGCollectionItem[]
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
    self:FlushTabEvidenceNew()
end

function UIN28AVGCollection:FlushTabBadgeRed()
    local isShow = self.data:HasRedBadge()
    self.redTabBadge:SetActive(isShow)
end

function UIN28AVGCollection:FlushTabBadgeNew()
    local isShow = self.data:HasNewBadge()
    self.newTabBadge:SetActive(isShow)
end

function UIN28AVGCollection:FlushTabEvidenceNew()
    local isShow = self.data:HasNewEvidence()
    self.newTabEvidence:SetActive(isShow)
end

---自动选择New页签，只在界面打开时调用
function UIN28AVGCollection:AutoSelectTab()
    --优先选中徽章页签
    if self.data:HasNewBadge() then
        self:SetCurEndId(0)
        return
    end
    if self.data:HasNewEvidence() then
        self:SetCurEndId(1)
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

function UIN28AVGCollection:FlushBadge()
    local countReach, count = 0, 0
    for _, badge in ipairs(self.data.badges) do
        count = count + 1
        if badge:HasGot() then
            countReach = countReach + 1
        end
    end
    self.txtCount:SetText("<color=#29b4e5>" .. countReach .. "</color>/" .. count)
    self.sldProgress.maxValue = count
    self.sldProgress.value = countReach
    --徽章奖励
    local len = table.count(self.data.badgeStages)
    self.poolProgress:SpawnObjects("UIN28AVGBadgeProgressItem", len)
    ---@type UIN28AVGBadgeProgressItem[]
    local uis = self.poolProgress:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local badgeStage = self.data.badgeStages[i]
        ui:Flush(
            badgeStage.id,
            function()
                local state = badgeStage:State()
                if state == N28AVGAwardState.CanGet then
                    self:StartTask(
                        function(TT)
                            self:Lock("UIN28AVGCollection_HandleGetBadgeReward")
                            local c = self.data:GetComponentAVG()
                            local res = AsyncRequestRes:New()
                            local ret = c:HandleGetBadgeReward(TT, res, badgeStage.id) --【消息】领取徽章奖励
                            if N28AVGData.CheckCode(res) then
                                UIActivityHelper.ShowUIGetRewards(badgeStage.awards)
                                self:FlushTab()
                                self:FlushBadge()
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGFlushNewRed)
                            end
                            self:UnLock("UIN28AVGCollection_HandleGetBadgeReward")
                        end
                    )
                else
                    local itemid = badgeStage.awards[1].assetid
                    self:_ShowRewardTips(itemid, ui:GetGameObject().transform.position)
                    --self:ShowDialog("UIItemTips", award, ui:GetGameObject(), "UIN28AVGCollection", Vector2(-377, 0))
                end
            end
        )
        local pos = Vector2(self.rtProgress.rect.width * badgeStage.count / count, 0)
        ui:FlushPos(pos)
    end
    --徽章
    len = table.count(self.data.badges)
    self.poolBadge:SpawnObjects("UIN28AVGBadgeItem", len)
    ---@type UIN28AVGBadgeItem[]
    local uis = self.poolBadge:GetAllSpawnList()
    for i = 1, #uis do
        local ui = uis[i]
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
            ui:BtnOnClick()
        end
    end
end

function UIN28AVGCollection:InitEvidenceTypeMap()
    for i = 1, #self.data.allEvidences do
        local evidence = self.data.allEvidences[i]
        local type = evidence.type
        if not self.poolEvidenceTypeMap[type] then
            table.insert(self.evidenceTypeOrderList, type)
            self.poolEvidenceTypeMap[type] = {}
        end
        table.insert(self.poolEvidenceTypeMap[type], evidence)
        if evidence:HasGot() then
            self.hasGotEvidenceCount = self.hasGotEvidenceCount + 1
        end
    end
end

function UIN28AVGCollection:FlushEvidence(selectDefault)
    local len = #self.evidenceTypeOrderList
    self.poolEvidence:SpawnObjects("UIN28AVGStoryCollectionEvidenceItem", len)
    local uis = self.poolEvidence:GetAllSpawnList()
    local firstEvidenceType = nil
    for i = 1, len do
        local type = self.evidenceTypeOrderList[i]
        local evidenceList = self.poolEvidenceTypeMap[type]
        firstEvidenceType = i == 1 and type or firstEvidenceType
        --处理证据状态
        uis[i]:SetData(type, evidenceList)
    end
    --默认选中第一个
    if selectDefault then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGSelectCollectionEvidenceItem, firstEvidenceType)
    end
    local maxCount = #self.data.allEvidences
    self.evidenceTxtCount:SetText("<color=#29b4e5>" .. self.hasGotEvidenceCount .. "</color>/" .. maxCount)
end

function UIN28AVGCollection:OnSelectEvidenceType(type)
    --展示UI信息
    if self.curSelectEvidenceType == type then
        return
    end
    local anim = true
    local isLeft = true
    if self.curSelectEvidenceType == nil then
        anim = false
    else
        isLeft = self.curSelectEvidenceType > type
    end
    self.curSelectEvidenceType = type
    local evidenceList = self.poolEvidenceTypeMap[type]
    self.curEvidenceMaxCountCount = #evidenceList
    self.curEvidenceHasCount = 0
    self.curHasEvidenceList = {}
    for _, evidence in pairs(evidenceList) do
        if evidence:HasGot() then
            self.curEvidenceHasCount = self.curEvidenceHasCount + 1
            self.curHasEvidenceList[self.curEvidenceHasCount] = evidence
            if evidence:HasNew() then
                evidence:SetNew()
                self:FlushTab()
                self:FlushEvidence()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AVGFlushNewRed)
            end
        end
    end
    self.curSelectEvidenceIdx = self.curEvidenceHasCount
    if self.curSelectEvidenceIdx > 0 then
        self.evidenceDescPanel:SetActive(true)
        self.evidenceNotGetPanel:SetActive(false)
        self:FlushEvidencePanel(self.curHasEvidenceList[self.curSelectEvidenceIdx], isLeft, anim)
        self.evidencePanelBtnsObj:SetActive(self.curSelectEvidenceIdx > 1)
    else
        --没解锁
        self.evidencePanelBtnsObj:SetActive(false)
        self.evidenceDescPanel:SetActive(false)
        self.evidenceNotGetPanel:SetActive(true)
    end
end

---字符转义
---目前支持如下 $$ -> $ | PlayerName -> 玩家姓名
---@param strContent string
---@return string
function UIN28AVGCollection:_DoEscape(strContent)
    strContent = string.gsub(strContent, "$$", "$")
    local name = GameGlobal.GetModule(RoleModule):GetName()
    if string.isnullorempty(name) then
        name = StringTable.Get("str_guide_moren_name")
    end
    strContent = string.gsub(strContent, "PlayerName", name) -- GameGlobal.GetModule("RoleModule").m_char_info.nick) 不知何时可用
    return strContent
end


function UIN28AVGCollection:FlushEvidencePanel(evidence, isLeft, anim)
    local showInfo = function()
        --显示证据信息
        self.evidenceTitle:SetText(evidence.name)
        local info = self:_DoEscape(evidence.desc)
        self.evidenceDetail:SetText(info)
        self.evidenceIconImage:LoadImage(evidence.icon)
        self.evidenceSelectCount:SetText(self.curSelectEvidenceIdx .. "/" .. self.curEvidenceMaxCountCount)
        local showCount = self.curEvidenceMaxCountCount > 1
        self.evidenceSelectCountObj:SetActive(showCount)
    end
    if anim then
        if isLeft then
            self.evidencePanelAnim:Play("uieff_UIN28AVGCollection_evidencePanel_R_out")
            self:StartTask(
                function(TT)
                    self:Lock("UIN28AVGCollection_EvidencePanel")
                    YIELD(TT, 333)
                    self:UnLock("UIN28AVGCollection_EvidencePanel")
                    self.evidencePanelAnim:Play("uieff_UIN28AVGCollection_evidencePanel_R_in")
                    showInfo()
                end
            )
        else
            self.evidencePanelAnim:Play("uieff_UIN28AVGCollection_evidencePanel_L_in")
            self:StartTask(
                function(TT)
                    self:Lock("UIN28AVGCollection_EvidencePanel")
                    YIELD(TT, 333)
                    self:UnLock("UIN28AVGCollection_EvidencePanel")
                    self.evidencePanelAnim:Play("uieff_UIN28AVGCollection_evidencePanel_L_out")
                    showInfo()
                end
            )
        end
    else
        showInfo()
    end
    --处理箭头显示
    self.evidenceLeftBtnObj:SetActive(self.curSelectEvidenceIdx ~= 1)
    self.evidenceRightBtnObj:SetActive(self.curSelectEvidenceIdx ~= self.curEvidenceHasCount)
end

function UIN28AVGCollection:GetEvidenceCfg(eid)
    local evidenceCfg = Cfg.cfg_component_avg_evidence{ID = eid}
    if evidenceCfg then
        return evidenceCfg[1]
    end
    return {}
end

function UIN28AVGCollection:EvidenceLeftBtnOnClick()
    if self.curEvidenceHasCount == 0 then
        return
    end
    self.curSelectEvidenceIdx = self.curSelectEvidenceIdx - 1
    self:FlushEvidencePanel(self.curHasEvidenceList[self.curSelectEvidenceIdx], true, true)
end

function UIN28AVGCollection:EvidenceRightBtnOnClick()
    if self.curEvidenceHasCount == 0 then
        return
    end
    self.curSelectEvidenceIdx = self.curSelectEvidenceIdx + 1
    self:FlushEvidencePanel(self.curHasEvidenceList[self.curSelectEvidenceIdx], false, true)
end

function UIN28AVGCollection:FlushTabBadgeNewEffect()
    if self.curEndId ~= 0 then
        return
    end
    self:StartTask(
        function(TT)
            if self.data:HasNewBadge() then
                local key = "UIN28AVGCollection_FlushTabBadgeNewEffect"
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
function UIN28AVGCollection:BadgeNewEffect(TT, index, badge)
    ---@type UIN28AVGBadgeItem[]
    local uis = self.poolBadge:GetAllSpawnList()
    local ui = uis[index]
    self:_MoveTransform(ui)
    ui:FlushNewEffect(badge.pos)
    YIELD(TT, 800 + 700) -- 两段动效长度
end

-- 移动节点
function UIN28AVGCollection:_MoveTransform(obj)
    local trans = obj:GetGameObject():GetComponent("Transform")
    trans:SetAsLastSibling()
end

function UIN28AVGCollection:PlayUnlockCGAnimation()
    self:StartTask(
        function(TT)
            self.imgCGObj:SetActive(false)
            self:Lock("UIN28AVGCollection_EvidencePanel")
            YIELD(TT, 200)
            self:UnLock("UIN28AVGCollection_EvidencePanel")
            self.imgCGObj:SetActive(true)
            UIWidgetHelper.PlayAnimation(self, "cgAnim", "uieff_UIN28AVGMain_cg_lock", 400)
        end
    )
end

---刷新当前选中的CG
function UIN28AVGCollection:FlushCG()
    local ending = self.data:GetEndingById(self.curEndId)
    local state = ending:AwardState()
    local hasNew = ending:HasNew() -- 判断是否解锁动效
    if state then
        self.time:SetActive(true)
        self.timeNotGet:SetActive(false)
        local timestampGot = ending:GetTimestamp()
        local str = self.data:Timestamp2Str(timestampGot)
        self.txtGetTime:SetText(str)
        self.imgCG:LoadImage(ending.cgCollect)
        -- 解锁动效
        self.suo:SetActive(hasNew)
        if hasNew then
            self:PlayUnlockCGAnimation()
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20GetCG)
        else
            self.imgCGObj:SetActive(true)
        end

        self.imgBigCG:LoadImage(ending.cg)
        self.btnShowCG:SetActive(true)
    else
        self.time:SetActive(false)
        self.timeNotGet:SetActive(true)
        --self.imgCG:LoadImage("N28_avg_sc_image01")
        self.imgCGObj:SetActive(false)
        self.btnShowCG:SetActive(false)
    end

    self.txtGetCondition:SetText(ending.getConditionDesc)
    local awardState = ending:AwardState()
    --CG奖励
    local len = table.count(ending.awards)
    self.poolCGAward:SpawnObjects("UIN28AVGCGAward", len)
    ---@type UIN28AVGCGAward[]
    local uis = self.poolCGAward:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local ra = ending.awards[i]
        ui:Flush(
            ra,
            function()
                local itemid = ra.assetid
                self:_ShowRewardTips(itemid, ui:GetGameObject().transform.position - Vector3(0.1, 0, 0))
                --self:ShowDialog("UIItemTips", ra, ui:GetGameObject(), "UIN28AVGCollection", Vector2(0, 250))
            end
        )
        ui:FlushGot(awardState == N28AVGAwardState.Got)
    end
    --状态
    if awardState then
        if awardState == N28AVGAwardState.CanGet then
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

function UIN28AVGCollection:GetTabIndex(endId)
    local uis = self.poolContent:GetAllSpawnList()
    if self.curEndId < 0 then
        return 1
    elseif self.curEndId < 2 then
        return self.curEndId + 1
    else
        for i, ui in ipairs(uis) do
            if endId == ui:EndId() then
                return i + 2
            end
        end
    end
end

function UIN28AVGCollection:FlushTabPos()
    --写死的，需要和外面组件尺寸保持一致
    local maxh = 764
    local svh = self.poolContentTrans.sizeDelta.y
    local svmaxh = svh > maxh and svh - maxh or 0
    if svmaxh == 0 then
        return
    end
    local h = 222
    local spacing = 20
    --local top = 11
    local uis = self.poolContent:GetAllSpawnList()
    local len = table.count(uis) + 2
    local idx = self:GetTabIndex(self.curEndId)
    local curPosY = self.poolContentTrans.anchoredPosition.y
    local minY = (idx - 1)*h + (idx - 1)*spacing
    local maxY = svmaxh - (len - idx)*h + (len - idx)*spacing
    local targetY = nil
    if curPosY > minY  then
        targetY = minY
    elseif curPosY < maxY then
        targetY = maxY
    end
    if targetY then
        self:Lock("UIN28AVGCollection_FlushTabPos")
        self.poolContentTrans:DOAnchorPosY(targetY, 0.5):OnComplete(function()
            self:UnLock("UIN28AVGCollection_FlushTabPos")
        end)
    end
    -- if self.curEndId <= 1 then
    --     self.sv.verticalNormalizedPosition = 1
    -- else
    --     local uis = self.poolContent:GetAllSpawnList()
    --     local len = table.count(uis)
    --     for i, ui in ipairs(uis) do
    --         if self.curEndId == ui:EndId() then
    --             local fz = i - 1
    --             local fm = len - 1
    --             if fm > 0 then
    --                 self.sv.verticalNormalizedPosition = 1 - fz / fm
    --             else
    --                 self.sv.verticalNormalizedPosition = 0
    --             end
    --             break
    --         end
    --     end
    -- end
end

function UIN28AVGCollection:FlushTabCgNew()
    if self.curEndId == 0 then
        return
    end
    ---@type UIN28AVGCollectionItem[]
    -- local uis = self.poolContent:GetAllSpawnList()
    -- local len = table.count(uis)
    -- for i, ui in ipairs(uis) do
    --     if self.curEndId == ui:EndId() then
    --         local fz = i - 1
    --         local fm = len - 1
    --         if fm > 0 then
    --             self.sv.verticalNormalizedPosition = 1 - fz / fm
    --         else
    --             self.sv.verticalNormalizedPosition = 0
    --         end
    --         break
    --     end
    -- end
    self:StartTask(
        function(TT)
            local ending = self.data:GetEndingById(self.curEndId)
            if ending:HasNew() then
                local items = self.mItem:GetItemByTempId(ending.itemId) --【消息】CG New
                for _, item in pairs(items) do
                    local key = "UIN28AVGCollectionFlushTab"
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

function UIN28AVGCollection:BtnExitOnClick(go)
    -------------------------------------------------
    -- Test
    -- self:_Test_SetCgNew()
    -- self:_Test_SetBadgeNew()
    -------------------------------------------------

    self:CloseDialog()
end

function UIN28AVGCollection:ImgTabBadgeOnClick(go)
    self:SetCurEndId(0)
end

function UIN28AVGCollection:ImgTabEvidenceOnClick(go)
    self:SetCurEndId(1)
end

function UIN28AVGCollection:BtnAwardOnClick(go)
    local ending = self.data:GetEndingById(self.curEndId)
    local awardState = ending:AwardState()
    if awardState == N28AVGAwardState.CanGet then
        self:StartTask(
            function(TT)
                local key = "UIN28AVGCollectionbtnAwardOnClick"
                self:Lock(key)
                local c = self.data:GetComponentAVG()
                local res = AsyncRequestRes:New()
                local res = c:HandleAcceptCgReward(TT, ending.itemIdGift) --【消息】领取CG奖励
                if N28AVGData.CheckCode(res) then
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

function UIN28AVGCollection:BtnShowCGOnClick(go)
    self.goBigCG:SetActive(true)
end

function UIN28AVGCollection:ImgBGOnClick(go)
    self.goBigCG:SetActive(false)
end

--endregion

--region Test

-- 测试，增加 new
function UIN28AVGCollection:_Test_SetCgNew()
    if not UIActivityHelper.CheckDebugOpen() then
        return
    end

    self:StartTask(
        function(TT)
            ---@type N28AVGEnding[]
            local notBEs = {}
            for index, ending in ipairs(self.data.endings) do
                if not ending.isBE then
                    local items = self.mItem:GetItemByTempId(ending.itemId) --【消息】CG New
                    for _, item in pairs(items) do
                        local key = "UIN28AVGCollectionFlushTab"
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
function UIN28AVGCollection:_Test_SetBadgeNew()
    if not UIActivityHelper.CheckDebugOpen() then
        return
    end

    self:StartTask(
        function(TT)
            for index, badge in ipairs(self.data.badges) do
                -- if index ~= 6 then
                local items = self.mItem:GetItemByTempId(badge.itemId) --【消息】徽章New
                for _, item in pairs(items) do
                    local key = "UIN28AVGCollectionFlushTab"
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
