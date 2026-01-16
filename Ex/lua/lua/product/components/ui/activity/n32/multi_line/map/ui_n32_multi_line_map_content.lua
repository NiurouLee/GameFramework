--
---@class UIN32MultiLineMapContent : UICustomWidget
_class("UIN32MultiLineMapContent", UICustomWidget)
UIN32MultiLineMapContent = UIN32MultiLineMapContent
--初始化
function UIN32MultiLineMapContent:OnShow(uiParams)
    self:InitWidget()
     ---@type MissionModule
     self._missionModule = self:GetModule(MissionModule)

     ---@type CampaignModule
    self._campModule = GameGlobal.GetModule(CampaignModule)
    self.lineSpeed = 590 --线移动速度，590像素每秒
end

--获取ui组件
function UIN32MultiLineMapContent:InitWidget()
    ---@type UnityEngine.GameObject
    self.lines = self:GetGameObject("lines")
    ---@type UnityEngine.GameObject
    self.waypoints = self:GetGameObject("waypoints")
    self.lineAni = self:GetUIComponent("Animation", "lineEff")
    self.lineEffRt = self:GetUIComponent("RectTransform", "lineEff")
    self.arriveAni = self:GetUIComponent("Animation", "arriveEff")
    self.arriveEffRt = self:GetUIComponent("RectTransform", "arriveEff")
end

--设置数据
function UIN32MultiLineMapContent:SetData(index, cfg, multilineData, isMatch, isWin)
    self._index = index
    self._cfg = cfg
    self._multiLineData = multilineData
   
    local bCheckUnlock = isMatch --检查是否解锁了新关卡
    self:InitData(bCheckUnlock)
    self:RefreshMainNodeAndline()
    self:RefreshBranchNodeAndline()
 
    self.unlockNode, self.unlockLine, self.unlockBranchNodes = self:GetUnlockNodeAndLine()
    if self.unlockNode and self.unlockLine then
        self.unlockNode:SetVisible(false)
        self.unlockLine.gameObject:SetActive(false)
        for k, v in pairs(self.unlockBranchNodes) do
            v:SetVisible(false)
        end
    end
end

function UIN32MultiLineMapContent:GetUnlockNodeAndLine()
   if  self.unlockNewLevel  then
        local unlockNode = self.mainNodeWidgets[#self.mainNodeWidgets]
        local unlockLine = self.mainLineObj[#self.mainLineObj]
        local lastFightNode = self.mainNodeWidgets[#self.mainNodeWidgets - 1]
        local unlockBranchs = self:GetUnlockBranch(lastFightNode:GetMissionID())
        return unlockNode, unlockLine, unlockBranchs
   end
end

function UIN32MultiLineMapContent:GetUnlockBranch(missionId)
    local unLockBranchs = {}
    if self.branchNodeWidgets then
        for k, v in pairs(self.branchNodeWidgets) do
            local levelId= v:GetLevelId()
            local cfg = Cfg.cfg_component_multiline_mission[levelId]
            local needMissionID = cfg.NeedMissionId
            if  needMissionID and needMissionID == missionId then
                table.insert(unLockBranchs, v)
            end
        end
    end
    return unLockBranchs
end

function UIN32MultiLineMapContent:CheckAndPlayUnlockAni(TT)
    -- ---test
    -- if self.branchNodeWidgets then
    --     for k, v in pairs(self.branchNodeWidgets) do
    --         v:PlayEnterAni()
    --     end
    --     YIELD(TT, 100)

    --     for k, v in pairs(self.branchNodeWidgets) do

    --         v:SetVisible(false)
    --     end
    --     YIELD(TT, 2300)
    --     for k, v in pairs(self.branchNodeWidgets) do
    --         v:SetVisible(true)
    --     end

    --     for k, v in pairs(self.branchNodeWidgets) do
    --         v:PlayEnterAni()
    --     end
    --     return 
    -- end
    -- --end test
    local unlockNode = self.unlockNode
    local unlockLine = self.unlockLine
    if not unlockNode or not unlockLine then
        return
    end
    unlockLine.gameObject:SetActive(true)

    local lineRt = self:FindGameObject(unlockLine, "line")
    local effRt = self:FindGameObject(unlockLine, "line/eff")
    self.lineEffRt.gameObject:SetActive(true)
    self.lineEffRt:SetParent(effRt)
    self.lineEffRt.localPosition = Vector3.zero
    local lineSize = lineRt.sizeDelta
    local lineWidth =  lineSize.x 
    lineSize.x = 0
    lineRt.sizeDelta = lineSize
    
    local duration = lineWidth/self.lineSpeed
    duration = math.max(0.3, duration) 
    DG.Tweening.DOVirtual.Float(0, lineWidth, duration, function (x)
            lineSize.x = x
            lineRt.sizeDelta = lineSize
    end):SetEase(DG.Tweening.Ease.Linear)
    YIELD(TT, duration * 1000 - 100)
    self.lineAni:Play("uieff_UIN32MultiLineMapController_line_end")
    unlockNode:SetVisible(true)
    self.arriveEffRt.gameObject:SetActive(true)
    self.arriveEffRt.position = unlockNode:GetPosition()
    YIELD(TT, 500)
    self.arriveEffRt.gameObject:SetActive(false)
    self.lineEffRt.gameObject:SetActive(false)
    if self.unlockBranchNodes then
        for k, v in pairs(self.unlockBranchNodes) do
            v:SetVisible(true)
        end
        for k, v in pairs(self.unlockBranchNodes) do
            v:PlayEnterAni()
        end
    end
    YIELD(TT, 300)
    if self.unlockBranchNodes and #self.unlockBranchNodes > 0 then
        self:_CheckGuide()
    end
end


function UIN32MultiLineMapContent:InitData(bCheckUnlock)
    self._MainLevels = {}
    self._BranchLevels = {}

    --主线关
    self:_CheckUnlockLevels(self._cfg.MainMission, self._MainLevels)
    --支线关
    self:_CheckUnlockLevels(self._cfg.BranchMission, self._BranchLevels)

    --检查新解锁的主线与支线
    self.unlockNewLevel = false
    if bCheckUnlock and #self._MainLevels > 1 then
        local lastLevelId  = self._MainLevels[#self._MainLevels - 1]
        if lastLevelId == UIMultiLineData.LastFightLevelId  and not UIMultiLineData.LastFightLevelIsPass then
            local cfgLevel = Cfg.cfg_component_multiline_mission[lastLevelId]
            local passInfo = self._multiLineData:GetPassMissionInfo(cfgLevel.MissionID)
            self.unlockNewLevel = passInfo ~= nil
        end
    end
end

function UIN32MultiLineMapContent:_CheckUnlockLevels(checkIdList, outTable)
    for k, levelId  in pairs(checkIdList) do
        local cfg = Cfg.cfg_component_multiline_mission[levelId]
        local needMissionID = cfg.NeedMissionId
        if not needMissionID or needMissionID < 1 then
            table.insert(outTable, levelId)
        else
            if self._multiLineData:GetPassMissionInfo(needMissionID) then
                table.insert(outTable, levelId)
            else
                break
            end
        end
    end
end

--刷新主线关路点和线
function UIN32MultiLineMapContent:RefreshMainNodeAndline()
    local len = #self._MainLevels

    if not self.mainNodeWidgets then
        self.mainNodeWidgets = {}
    end
    for i = 1, len, 1 do
        local widget = self.mainNodeWidgets[i]
        if not widget then
            local pool = self:GetUIComponent("UISelectObjectPath", "m"..i)
            widget = pool:SpawnObject("UIN32MultiLineMapNormalNode")
            table.insert(self.mainNodeWidgets, widget)
        end
        local levelId = self._MainLevels[i]
        local cfg = Cfg.cfg_component_multiline_mission[levelId]
        widget:SetData(levelId, self._multiLineData, function (levelId, missionId,  isStory, worldPos)
            self:OnMainLevelClicked(levelId, missionId,  isStory, worldPos)
        end)
    end


    --主线路点连接线
    local mainLinesObjList = self:FindGameObjectList(self.lines.transform, 2, len, function (index)
        return "m"..index.."line"
    end)
    self.mainLineObj = mainLinesObjList

    for i, lineObj in ipairs(mainLinesObjList) do
        lineObj.gameObject:SetActive(true)
        local levelId = self._MainLevels[i+1]
        local cfg = Cfg.cfg_component_multiline_mission[levelId]
        local passInfo = self._multiLineData:GetPassMissionInfo(cfg.MissionID)
        self:SetLineState(lineObj, passInfo ~= nil)
    end
end

--刷新支线关路点和线
function UIN32MultiLineMapContent:RefreshBranchNodeAndline()
    local len = #self._BranchLevels

    --支线路点
    if not self.branchNodeWidgets then
        self.branchNodeWidgets = {}
    end
    
    for i = 1, len, 1 do
        local widget = self.branchNodeWidgets[i]
        if not widget then
            local pool = self:GetUIComponent("UISelectObjectPath", "b"..i)
            widget = pool:SpawnObject("UIN32MultiLineMapDialoglNode")
            table.insert(self.branchNodeWidgets, widget)
        end
        
        local levelId = self._BranchLevels[i]
        local cfg = Cfg.cfg_component_multiline_mission[levelId]
        local passInfo = self._multiLineData:GetPassMissionInfo(cfg.MissionID)
        local isPass = passInfo ~= nil
        widget:SetData(levelId, cfg.MissionID, isPass,function (levelId, missionId)
            self:OnBranchLevelClicked(levelId, missionId)
        end)
    end

    -- --支线连接线
    -- local branchLinesObjList = self:FindGameObjectList(self.lines.transform, 1, len, function (index)
    --     return "b"..index.."line"
    -- end)

    -- for i, branchLineGo in ipairs(branchLinesObjList) do
    --     branchLineGo.gameObject:SetActive(true)
    --     local levelId = self._BranchLevels[i]
    --     local cfg = Cfg.cfg_component_multiline_mission[levelId]
    --     local passInfo = self._multiLineData:GetPassMissionInfo(cfg.MissionID)
    --     local isPass = passInfo ~= nil
    --     self:SetLineState(branchLineGo, isPass)
    -- end
end

function UIN32MultiLineMapContent:FindGameObjectList(rootRt, startIndex, endIndex, nameCall)
    local ret = {}
    for i = startIndex, endIndex, 1 do
        local name = nameCall(i)
        local find = rootRt:Find(name)
        if find then
            table.insert(ret, find)
        else
            Log.fatal("err: UIN32MultiLineMapContent cant FindGameObject " .. name)
        end
    end
    return ret
end

function UIN32MultiLineMapContent:FindGameObject(rootRt, name)
    local find = rootRt:Find(name)
    return find
end

function UIN32MultiLineMapContent:SetLineState(go, isPass)
    local passGo = go:Find("line/pass")
    local unPassGo = go:Find("line/unpass")
    passGo.gameObject:SetActive(isPass)
    unPassGo.gameObject:SetActive(not isPass)
end

--主线关点击
function UIN32MultiLineMapContent:OnMainLevelClicked(levelId, missionId,  isStory, worldPos)
    if not self:RootUIOwner():CheckComponentTime() then
        return
    end

    if not self:_CheckOverTips(levelId, missionId) then
        return 
    end

    if isStory then
        --剧情关
        local missionCfg = Cfg.cfg_campaign_mission[missionId]
        local titleId = StringTable.Get(missionCfg.Title)
        local titleName = StringTable.Get(missionCfg.Name)
        local storyId = self._missionModule:GetStoryByStageIdStoryType(missionId, StoryTriggerType.Node)
        if not storyId then
            Log.exception("配置错误,找不到剧情,关卡id:", missionId)
            return
        end
        self._multiLineData:SnapMultilineContextBeforeFight(self._index, levelId)
        self:ShowDialog(
            "UIActivityPlotEnter",
            titleId,
            titleName,
            storyId,
            function()
                local isPlot = true
                self:PlotOrDialogEndCallback(missionId, isPlot)
            end
        )
        return
    end

    --战斗关
    self._multiLineData:SnapMultilineContextBeforeFight(self._index, levelId)
    self:EnterStage(missionId, worldPos) -- 直接进入关卡
end

--检查最后一个主线关点击提示
--策划约定，最后一个主线关不解锁任何支线
function UIN32MultiLineMapContent:_CheckOverTips(levelId, missionId)
    local len = #self._cfg.MainMission
    if self._cfg.MainMission[len] ~= levelId then
        return true
    end
    if self._multiLineData:IsForlderBranchUnReadHasTipsed(self._index) then
        return true
    end
    local unPassNumM, unPassNumB = self._multiLineData:CheckFolderState(self._index)
    if unPassNumB > 0 then
        self._multiLineData:SetFolderBranchUnReadTips(self._index)
        self:ShowDialog("UIN32MultiLineOverTips", unPassNumB)
        return false
    end

    return true
end

function UIN32MultiLineMapContent:EnterStage(stageId, worldPos)
    local missionCfg = Cfg.cfg_campaign_mission[stageId]
    local autoFightShow = self:CheckSerialAutoFightShow(missionCfg.Type, stageId)
    
    local multiLineCom, multilineComInfo = self._multiLineData:GetComponent()
    local passInfo = self._multiLineData:GetPassMissionInfo(stageId)

    self:ShowDialog(
        "UIActivityLevelStageNew",
        stageId,
        passInfo,
        multiLineCom,
        autoFightShow,
        nil,
        nil,
        nil,
        nil,
        nil,
        false,
        true
    )
end


function UIN32MultiLineMapContent:CheckSerialAutoFightShow(stageType, stageId)
    local autoFightShow = false
    if stageType == DiscoveryStageType.Plot then
        autoFightShow = false
    else
        local missionCfg = Cfg.cfg_campaign_mission[stageId]
        if missionCfg then
            local enableParam = missionCfg.EnableSerialAutoFight
            if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE then
                autoFightShow = false
            elseif
                enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE or
                    enableParam ==
                        CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK
             then
                autoFightShow = true
            end
        end
    end
    return autoFightShow
end


--支线关点击
function UIN32MultiLineMapContent:OnBranchLevelClicked(levelId, missionId)
    if not self:RootUIOwner():CheckComponentTime() then
        return
    end
    local passInfo = self._multiLineData:GetPassMissionInfo(missionId)
    self:ShowDialog("UIN32MultiLineDialogueDetails", missionId, passInfo ~= nil, function(missionId)
        self:PlotOrDialogEndCallback(missionId)
    end)
end


--剧情关与对话框返回
function UIN32MultiLineMapContent:PlotOrDialogEndCallback(missionId,  isPlot)
    local multiLineCom, multiLineComInfo = self._multiLineData:GetComponent()

    local isActive = multiLineCom:IsPassCamMissionID(missionId)
    if isActive then --已激活的就不再发激活消息
        return
    end

    self:StartTask(
        function(TT)
            multiLineCom:SetMissionStoryActive(TT, missionId, ActiveStoryType.ActiveStoryType_BeforeBattle)

            local res = AsyncRequestRes:New()
            local itemReward, petDocReward = multiLineCom:HandleMultiLineMissionSettle(TT, res, missionId)
            if not res:GetSucc() then
                self._campModule:CheckErrorCode(res.m_result, self._multiLineData:GetCampaignId(), nil, nil)
            else
                self:CheckAndShowPetDocReward(petDocReward, itemReward, function ()
                    if isPlot then
                        self:RootUIOwner():RefreshAfterPlot()
                        --self:SwitchState(self:GetLineLevelState(), self._index,  true, true)
                    else
                        self:RootUIOwner():RefreshAfterDialog()
                        -- self:SwitchState(self:GetLineLevelState(), self._index)
                    end
                end)
            end
        end,
        self
    )
end


function UIN32MultiLineMapContent:CheckAndShowPetDocReward(petDocReward, itemReward, cb)
    if petDocReward and petDocReward > 0 then
        self:ShowDialog(
            "UIN32MultiLinePetUnlock",
            petDocReward,
            function() 
                self:CheckAndShowItemReward(itemReward, cb)
            end
        )
    else
        self:CheckAndShowItemReward(itemReward, cb)
    end
end

function UIN32MultiLineMapContent:CheckAndShowItemReward(itemReward, finshCallback)
    if table.count(itemReward) ~= 0 then
        self:ShowDialog(
            "UIGetItemController",
            itemReward,
            function() 
                finshCallback()
            end
        )
    else
        finshCallback()
    end
end

function UIN32MultiLineMapContent:GetLineLevelState()
    return UIStateType.UIN32MultiLineMapController
end


function UIN32MultiLineMapContent:PlayEnterAni()
    if self.mainNodeWidgets then
        for k, mainNode in pairs(self.mainNodeWidgets) do
            if mainNode ~= self.unlockNode then
                mainNode:PlayEnterAni()
            end
        end
    end

    if self.branchNodeWidgets then
        for k, branchNode in pairs(self.branchNodeWidgets) do
            local isNewUnlock  = false
            if self.unlockBranchNodes then
                for a, node in pairs(self.unlockBranchNodes) do
                    if branchNode == node then
                        isNewUnlock = true
                        break
                    end
                end
            end
            if not isNewUnlock then
                branchNode:PlayEnterAni()
            end
        end
    end
end

function UIN32MultiLineMapContent:GetFirstDialogBtn()
    return self.branchNodeWidgets[1]:GetBtn()
end


function UIN32MultiLineMapContent:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN32MultiLineMapController)
end