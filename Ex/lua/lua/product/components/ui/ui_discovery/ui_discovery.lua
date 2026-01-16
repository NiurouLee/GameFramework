---@class UIDiscovery:UIController
_class("UIDiscovery", UIController)
UIDiscovery = UIDiscovery

function UIDiscovery:Constructor()
    self:CreateMapList()

    self._module = self:GetModule(MissionModule)
    self._data = self._module:GetDiscoveryData()
    self._module:InitDiscoveryData() --用于更新到解锁时间开启的路点
    self._module:UpdateChapterData() --更新章节奖励服务器数据
    self._data.chapterAwardData:Init()
    self._reach = true
    ---@type DiscoveryNode[] dict
    self._nodes = {} --路点信息字典
    for _, chapter in pairs(self._data:GetChapters()) do
        for _, node in ipairs(chapter.nodes) do
            self._nodes[node.id] = node
        end
    end
end
function UIDiscovery:CreateMapList()
    self._mapList = {}
    local mapList1 = {"first_map_01","first_map_02","first_map_03","first_map_04","first_map_05","first_map_06"}
    local mapList2 = {"part_map_01","part_map_02","part_map_03","part_map_04","part_map_05","part_map_06"}
    local mapList3 = {"second_map_01","second_map_02","second_map_03","second_map_04","second_map_05","second_map_06"}
    local mapList4 = {"diff_map_01","diff_map_02","diff_map_03","diff_map_04","diff_map_05","diff_map_06"}
    self._mapList[1] = mapList1
    self._mapList[2] = mapList2
    self._mapList[3] = mapList3
    self._mapList[4] = mapList4
end
--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIDiscovery:LoadDataOnEnter(TT, res, uiParams)
    --拉取最新活动数据更新主界面活动信息
    self.mCampaign = self:GetModule(CampaignModule)
    self._latestCampObj = self.mCampaign:GetLatestCampaignObj(TT)

    self.grassData = self.mCampaign:GetGraveRobberData()
    self.grassData:RequestCampaign(TT)

    ---@type DifficultyMissionModule
    local diffModule = GameGlobal.GetModule(DifficultyMissionModule)
    local res = diffModule:HandleGetDifficultyMissionData(TT)
    if res:GetSucc() then
        ---@type UIDiffMissionModule
        local uiDiffModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        uiDiffModule:Init()
    end
end

function UIDiscovery:Dispose()
    self._data = nil

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end

    UIDiscovery.super:Dispose()
end

--region StateDiscovery
StateDiscovery = {
    Init = 0,
    SwitchChapter = 1,
    Move2GrassNode = 2, --风船移动到活动路点
    Move2MainNode = 3 --风船移动到主线路点
}
--endregion
function UIDiscovery:ChangeDiff(diff)
    self._isDiff = diff
    self:ShowDiffOrNorm()
    self:InitMap()
end
function UIDiscovery:ShowDiffOrNorm()
    self._diffRoot:SetActive(self._isDiff)
    self._normRoot:SetActive(not self._isDiff)
    self._diffBtn:SetActive(false)
    self._normBtn:SetActive(false)
    self._plotBtnGo:SetActive(not self._isDiff)
    self._awardBtnGo:SetActive(not self._isDiff)
end
function UIDiscovery:OnShow(uiParams)
    CutsceneManager.ExcuteCutsceneOut()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIDiscovery)
    UnityEngine.Input.multiTouchEnabled = true
    self._srRT = self:GetUIComponent("RectTransform", "ScrollView")
    ---@type UnityEngine.UI.Image
    self._imgSR = self:GetUIComponent("Image", "ScrollView")
    local scaleX = self._srRT.rect.width / (self._data.cell_size.x * self._data.col)
    local scaleY = self._srRT.rect.height / (self._data.cell_size.y * self._data.row)
    local scaleXY = Mathf.Max(scaleX, scaleY)
    local scaleValue = Cfg.cfg_global["ui_discovery_content_scale"].ArrayValue
    self._scaleMin = Mathf.Max(scaleValue[1], scaleXY)
    self._scaleMax = scaleValue[2]
    self._defaultScale = scaleValue[3]
    self._darkThreshold = scaleValue[4]
    self._scaleStep = 0.5
    self._data.mapScale = self._scaleMin
    --困难模式
    self._isDiff = false
    --
    --困难关退局回到大地图
    local isDiff = self._data:GetDiffNodeInfo()
    if isDiff then
        self._isDiff = true
    end

    self:InitUI()
        --判断是否在关卡
    ---@type UIStateType
    -- local currentStateUI = GameGlobal.UIStateManager():CurUIStateType()
    -- if currentStateUI == UIStateType.UIMain then
        
    -- end
    --检查回流活动是否开启
    self:StartTask(self.CheckReturnBackOpen, self)

    --设置cellSize
    ---@type UnityEngine.UI.GridLayoutGroup
    self._contentGLG.cellSize = self._data.cell_size
    self._contentGLG.constraintCount = self._data.row

    ---@type DG.Tweening.Tweener
    self._cameraTweener = nil --相机移动Tweener

    local c = self._data:GetCurPosChapter()
    self._chapterId = c.id

    self:InitMap()

    self:_CheckGuide()
    self:CheckDiffBtn()
    ---@type UICommonTopButton
    self._backBtns = self._ltBtn:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            if GameGlobal.UIStateManager():IsShow("UIStage") then
                GameGlobal.UIStateManager():CloseDialog("UIStage")
            else
                -- 设置跳转返回数据
                local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
                if not jumpData:JumpBack() then
                    self:SwitchState(UIStateType.UIMain)
                end
            end
        end,
        function()
            local param
            if self._isDiff then
                param = "UIDiffMission"
            else
                param = "UIDiscovery"
            end
            self:ShowDialog("UIHelpController", param)
        end
    )
    self.uiCanvas = self:GetGameObject("UICanvas")
    self._uiCanvasGroup = self.uiCanvas.transform:GetComponent("CanvasGroup")
    self._uiCanvasGroup.alpha = 1
    ---@type UICustomWidgetPool
    local enter = self:GetUIComponent("UISelectObjectPath", "enter")
    ---@type UIDiscoveryEnters
    self.uiDiscoveryEnters = enter:SpawnObject("UIDiscoveryEnters")
    self.uiDiscoveryEnters:Flush(self._data, self._scaleMax, self._uiCanvasGroup, self._latestCampObj)
    self:Flush()
    --滚动缩放地图
    self._sr:Init(Vector2(self._scaleMin, self._scaleMax), self._scaleStep)
    --事件
    self:AttachEvent(GameEventType.DiscoveryCameraMove, self.CameraMoveTo)
    self:AttachEvent(GameEventType.DiscoveryPlayerMove, self.GoWalkAlong)
    self:AttachEvent(GameEventType.UpdateChapterAwardData, self.FlushRedChapterAward)
    self:AttachEvent(GameEventType.DiscoveryFlushChapter, self.DiscoveryFlushChapter)
    self:AttachEvent(GameEventType.DiscoveryFlushLines, self.FlushLines)
    self:AttachEvent(GameEventType.DiscoveryShowHideUICanvas, self.ShowHideUICanvas)
    self:AttachEvent(GameEventType.FlushChapterPreview, self.FlushChapterPreview)
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnUIOpenClose)
    self:AttachEvent(GameEventType.FlushDiffNodes, self.FlushDiffNodes)
    self:_PickPetTaskReward()
    self:FlushChapterPreview()

    if EDITOR or IsPc() then
        local contentScale = 1
        self:SetUIEventTrigger( --滚轮
            self._sr.gameObject,
            UIEventTriggerType.Scroll,
            function(ped)
                contentScale =
                    Mathf.Clamp(contentScale + ped.scrollDelta.y * self._scaleStep, self._scaleMin, self._scaleMax)
                self._sr:UpdateContentScale(contentScale)
            end
        )
    end

    if EngineGameHelper.EnableAppleVerifyBulletin() then
        -- 审核服环境
        self:GetExtEntryBtn():SetActive(false)
        self:GetTowerBtn():SetActive(false)
        self:GetMazeEntryBtn():SetActive(false)
        self:GetWorldBossBtn():SetActive(false)
    end

    -- MSG9891
    GameGlobal.UIStateManager():ShowBusy(false)

    self.fsm = StateMachineManager:GetInstance():CreateStateMachine("StateDiscovery", StateDiscovery)
    self.fsm:SetData(self)
    self.fsm:Init(StateDiscovery.Init)
end

function UIDiscovery:OnHide()
    self.fsm:SetData(nil)
    StateMachineManager:GetInstance():DestroyStateMachine(self.fsm.Id)
    self.fsm = nil

    UnityEngine.Input.multiTouchEnabled = false
    self._backBtns = nil
    self._sr.OnContentPosChanged = nil
    self._sr.onContentScaleChanged = nil
    self:DetachEvent(GameEventType.DiscoveryCameraMove, self.CameraMoveTo)
    self:DetachEvent(GameEventType.DiscoveryPlayerMove, self.GoWalkAlong)
    self:DetachEvent(GameEventType.UpdateChapterAwardData, self.FlushRedChapterAward)
    self:DetachEvent(GameEventType.DiscoveryFlushChapter, self.DiscoveryFlushChapter)
    self:DetachEvent(GameEventType.DiscoveryFlushLines, self.FlushLines)
    self:DetachEvent(GameEventType.DiscoveryShowHideUICanvas, self.ShowHideUICanvas)
    self:DetachEvent(GameEventType.FlushChapterPreview, self.FlushChapterPreview)
    self:DetachEvent(GameEventType.AfterUILayerChanged, self.OnUIOpenClose)
    if self._cameraTweener then
        self._cameraTweener:Kill()
    end
    self:UnLock("UIDiscoveryPetStory")
    self:UnLock("UIDiscoveryWalkDragon") --保证关闭大地图时UI锁必然关闭，防止UI锁死
    UIHelper.RemoveCameraBlur(self._bgCamera)

    if EDITOR then
        self:RemoveUIEventTrigger(self._sr.gameObject, UIEventTriggerType.Scroll) --滚轮
    end

    if self._eff then
        UIHelper.DestroyGameObject(self._eff)
        self._eff = nil
    end
    if self._shot then
       self._shot:CleanRenderTexture() 
    end

    -- 清除跳转数据
    local sModule = GameGlobal.GetModule(SerialAutoFightModule)
    if sModule then
        local jumpData = sModule:GetJumpData()
        if jumpData then
            jumpData:Jump_Clear()
        end
    end
end

---@private
function UIDiscovery:InitUI()
    self._scaleCloud = 0.8

    self._diffRoot = self:GetGameObject("diff")
    self._normRoot = self:GetGameObject("norm")
    self._diffNodePool = self:GetUIComponent("UISelectObjectPath", "diffNodePool")
    self._diffRoot:SetActive(self._isDiff)
    self._normRoot:SetActive(not self._isDiff)

    --map
    ---@type ScalableScrollRect
    self._sr = self:GetUIComponent("ScalableScrollRect", "ScrollView")
    self._sr.OnContentPosChanged = function()
        self:UpdateIgnLayoutPos()
    end
    self._sr.onContentScaleChanged = function(scale)
        self._data.mapScale = scale
        self._ignLayout.localScale = Vector3.one * scale
        self._svCloud.content.localScale =
            Vector3.one *
            (self._scaleCloud -
                (self._scaleMax - scale) / (self._scaleMax - self._scaleMin) * (self._scaleCloud - self._scaleMin))
        --蒙版效果
        local div = 1
        if self._scaleMax > self._darkThreshold then
            div = (self._scaleMax - scale) / (self._scaleMax - self._darkThreshold)
        end
        local divNew = 1 - Mathf.Clamp01(div)
        if scale < self._darkThreshold then
            UIHelper.EnableCameraBlur(self._bgCamera, false)
        else
            UIHelper.EnableCameraBlur(self._bgCamera, true)
            UIHelper.UpdateCameraBlurAlpha(self._bgCamera, divNew)
        end
    end
    self.preX = 0
    self.preY = 0
    self._horizontalNormalizedPosition = 0
    self._verticalNormalizedPosition = 0

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")

    ---@type UnityEngine.RectTransform
    self._content = self:GetUIComponent("RectTransform", "Content")
    self._contentGLG = self:GetUIComponent("GridLayoutGroup", "Content")
    self._contentPos = Vector2.zero
    self._glo = self:GetUIComponent("UISelectObjectPath", "Content")
    self._ignLayout = self:GetUIComponent("RectTransform", "IgnoreLayout")
    ---@type UICustomWidgetPool
    self._linesPool = self:GetUIComponent("UISelectObjectPath", "Lines")
    ---@type UICustomWidgetPool
    self.poolNodePool = self:GetUIComponent("UISelectObjectPath", "NodePool")
    ---@type UIDiscoveryNodePool
    self.uiDiscoveryNodePool = self.poolNodePool:SpawnObject("UIDiscoveryNodePool")
    self.uiDiscoveryNodePool:Init(self)

    ---@type UICustomWidgetPool
    self._linesNextPool = self:GetUIComponent("UISelectObjectPath", "LinesNext")
    local effRoot = self:GetGameObject("effRoot").transform
    self._eff = UIHelper.GetGameObject("UIEff_daditu.prefab")
    self._eff.transform:SetParent(effRoot, false)

    ---@type UnityEngine.UI.ScrollRect
    self._svCloud = self:GetUIComponent("ScrollRect", "svCloud")
    local effCloud = UIHelper.GetGameObject("UIEff_Cloud.prefab")
    effCloud.transform:SetParent(self._svCloud.content, false)
    self._svCloud.content.sizeDelta =
        Vector2(self._data.cell_size.x * self._data.col, self._data.cell_size.y * self._data.row)
    --ui
    ---@type UnityEngine.CanvasGroup
    self._cg = self:GetUIComponent("CanvasGroup", "SafeArea")
    if self._data.showUIStage then
        self._cg.alpha = 1
    else
        self._cg.alpha = 0
        self._cg:DOFade(1, 1)
    end

    ---@type UICustomWidgetPool
    self._ltBtn = self:GetUIComponent("UISelectObjectPath", "ltBtn")
    ---@type UICustomWidgetPool
    local btnChapter = self:GetUIComponent("UISelectObjectPath", "btnChapter")
    ---@type UIDiscoveryChapterEnter
    self.uiDiscoveryChapterEnter = btnChapter:SpawnObject("UIDiscoveryChapterEnter")
    self.uiDiscoveryChapterEnter:Init(false)

    ---@type UICustomWidgetPool
    local poolActivityIntro = self:GetUIComponent("UISelectObjectPath", "activityIntro")
    poolActivityIntro:SpawnObject("UIDiscoveryIntroEnter")
    --lb
    ---@type UnityEngine.Canvas
    local bgCanvas = self:GetUIComponent("Canvas", "BGCanvas")
    self._bgCamera = bgCanvas.worldCamera
    --[[
    ---@type UnityEngine.RectTransform
    local tranBGSafeArea = self:GetUIComponent("RectTransform", "BGSafeArea")
    ---@type UnityEngine.RectTransform
    local tranSafeArea = self:GetUIComponent("RectTransform", "SafeArea")
    tranBGSafeArea.anchorMin = tranSafeArea.anchorMin
    tranBGSafeArea.anchorMax = tranSafeArea.anchorMax
    tranBGSafeArea.sizeDelta = tranSafeArea.sizeDelta
    ]]--
    --红点
    self._imgRedChapterAward = self:GetGameObject("imgRedChapterAward")
    self._imgRedChapterAward:SetActive(false)
    UIHelper.AddCameraBlur(self._bgCamera, "map_bantou13_frame", 0)
    --秘境/资源打开的时候  不再关闭UICanvas  而是挑选关闭
    self._showHideInUICanvas = {}
    local linesPoolGo = self:GetGameObject("Lines")
    table.insert(self._showHideInUICanvas, linesPoolGo)
    local anchorLeftTop = self:GetGameObject("AnchorLeftTop")
    local anchorTop = self:GetGameObject("AnchorTop")
    local anchorCenter = self:GetGameObject("AnchorCenter")
    local anchorRightBottom = self:GetGameObject("AnchorRightBottom")
    local anchorBottom = self:GetGameObject("AnchorBottom")
    table.insert(self._showHideInUICanvas, anchorLeftTop)
    table.insert(self._showHideInUICanvas, anchorTop)
    table.insert(self._showHideInUICanvas, anchorCenter)
    table.insert(self._showHideInUICanvas, anchorRightBottom)
    table.insert(self._showHideInUICanvas, anchorBottom)

    ---@type UnityEngine.Animation
    self.uiAnim = self:GetUIComponent("Animation", "uiAnim")
    self.uiAnim:Play("uieff_Discovery_In")

    --diff
    self._diffBtn = self:GetGameObject("diffEnter")

    self._normBtn = self:GetGameObject("normEnter")
    self._btnsPos = self:GetUIComponent("RectTransform", "btnsPos")
    self._plotBtnGo = self:GetGameObject("btnPlot")
    self._awardBtnGo = self:GetGameObject("btnChapterAward")
    self.goEffect = self:GetGameObject("effect")
    self.goEffect:SetActive(false)
    self._chapterAwardTxt = self:GetUIComponent("UILocalizationText","chapterAwardTxt")

    self._downBg = self:GetUIComponent("RawImageLoader","downBg")

    self._returnBackIntro = self:GetGameObject("returnBackIntro")
    self._diffBtns = self:GetUIComponent("UISelectObjectPath", "diffBtns")
    self:ShowDifficultBtns()
end

function UIDiscovery:_SetAwardStar()
    ---@type ChapterAwardChapter
    local chapterData = self._data.chapterAwardData:GetChapterAwardChapterByChapterId(self._chapterId)
    
    if not chapterData then
        Log.warn("### no award in chapter:", self._chapterId)
    else
        local totalStar = chapterData.grades[table.count(chapterData.grades)].star_count

        self._chapterAwardTxt:SetText(chapterData.star_count.."/"..totalStar)
    end
end

function UIDiscovery:UpdateIgnLayoutPos()
    self._ignLayout.anchoredPosition = self._content.anchoredPosition
    self._svCloud.content.anchoredPosition = self._content.anchoredPosition * self._scaleCloud
end

--region InitMap
---@private
function UIDiscovery:InitMap()
    self:InitSubMap()
    self:InitDownBg()
    --设置章节星数
    self:_SetAwardStar()
end
function UIDiscovery:InitDownBg()
    local downBg
    if self._isDiff then
        downBg = "map_ditu_kuang13"
    else
        downBg = "map_ditu_kuang12"
    end
    self._downBg:LoadImage(downBg)
end
function UIDiscovery:InitSubMap()
    local section = self._data:GetDiscoverySectionByChapterId(self._chapterId)
    local mapList = self:GetMapList(section.id)
    ---@type UIMapSubItem
    self._glo:SpawnObjects("UIMapSubItem", self._data.row * self._data.col)
    for i, v in ipairs(self._glo:GetAllSpawnList()) do
        v:Flush(i, mapList[i])
    end
end
function UIDiscovery:GetMapList(id)
    if self._isDiff then
        return self._mapList[4]
    else
        return self._mapList[id]
    end
end
function UIDiscovery:GetNodeByNodeId(nodeId)
    for k, v in pairs(self._uiMapNodes) do
        local nodeInfo = v:GetNodeInfo()
        if nodeInfo.id == nodeId then
            return v:GetTip()
        end
    end
end
--endregion

function UIDiscovery:DiscoveryFlushChapter(chapterId, diff)
    self._chapterId = chapterId --要显示的章节
    local isDiff = false
    if diff then
        isDiff = true
    end
    self:ChangeDiff(isDiff)
    self:CheckDiffBtn()
    self.grassData = GameGlobal.GetModule(CampaignModule):GetGraveRobberData()
    local node = self.grassData:GetCanPlayNodeByChapterId(chapterId)
    if self.grassData:IsOpenGraveRobber() and node then
        self._data:UpdatePosByEnter(7, node.stageId)
    else
        self._data:UpdatePosByEnter(2, self._chapterId)
    end
    self.fsm:ChangeState(StateDiscovery.SwitchChapter)
end

--region 回流二期
--检查回流活动是否开启
function UIDiscovery:CheckReturnBackOpen(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    local campaignType = ECampaignType.CAMPAIGN_TYPE_BACK_PHASE_II

    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    campaign:LoadCampaignInfo(TT, res, campaignType)

    if res:GetSucc() then
        if campaign:CheckCampaignOpen() then
            --- @type Power2ItemComponent
            local component = UIActivityReturnSystemHelper.GetComponentByTabName(campaign, "shop", 2)
            ---@type Power2ItemComponentInfo
            local power2ItemInfo = component:GetComponentInfo()
            
            local endTime = power2ItemInfo.m_close_time
            --- @type SvrTimeModule
            local svrTimeModule = self:GetModule(SvrTimeModule)
            local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
            local stamp = endTime - curTime
            if stamp > 0 then
                self._returnBackIntro:SetActive(true)
            else
                self._returnBackIntro:SetActive(false)
            end
            return
        end
    end
    self._returnBackIntro:SetActive(false)
end

--回流信息按钮
function UIDiscovery:ReturnBackBtnOnClick()
    self:ShowDialog("UIActivityReturnSystemTipController")
end
--endregion

--region Flush
function UIDiscovery:Flush()
    self.uiDiscoveryNodePool:Flush(self._chapterId)
    self:FlushUIDrag()
    self:FlushLines()
    self:FlushCamera() ---刷新相机位置
    self:FlushRed() ---刷新红点
    self:FlushUIStage() --决定是否打开关卡界面
    self.uiDiscoveryNodePool:FlushNextChapter()
    self.uiDiscoveryChapterEnter:Flush(self._chapterId)

    --刷新困难关路点，排期不够了就写这把
    self:DiffNodeRoot()
    --是否打开困难关卡
    self:FlushDiffStage()
end
function UIDiscovery:FlushDiffStage()
    if self._data._showDiffStage then
        self._data._showDiffStage = false
    else
        return
    end
    ---@type UIDiffMissionModule
    local uiDiffModule = GameGlobal.GetUIModule(DifficultyMissionModule)
    local chapter = uiDiffModule:GetDiffChapterFromMission(self._chapterId)
    local nodeid = self._data._showNodeID
    local node = uiDiffModule:GetNode(nodeid)
    self:ShowDialog("UIDiffStage",chapter,node)
end
function UIDiscovery:FlushUIDrag()
    ---@type UIDrag[]
    local uiDrags = self._ignLayout:GetComponentsInChildren(typeof(UIDrag))
    if uiDrags then
        for i = 0, uiDrags.Length - 1 do
            local uiDrag = uiDrags[i]
            uiDrag.ScalableSR = self._sr
        end
    end
end

function UIDiscovery:FlushLines()
    if not self._data then
        return
    end
    local chapter = self._data:GetChapterByChapterId(self._chapterId)
    if not chapter then
        return
    end
    if not chapter.lines or table.count(chapter.lines) <= 0 then
        return
    end

    --只显示Nomal路点上的线
    local tLine = {}
    local len = 0
    for i, node in ipairs(chapter.nodes) do
        if node:State() == DiscoveryStageState.Nomal then
            local tNodeId = chapter.lines[node.id]
            if tNodeId then
                local count = table.count(tNodeId)
                if count > 0 then
                    tLine[node.id] = tNodeId
                    len = len + count
                end
            end
        end
    end

    self._linesPool:SpawnObjects("UIMapPathItem", len)
    ---@type UIMapPathItem[]
    local spawnLines = self._linesPool:GetAllSpawnList()
    local i = 1
    for sNodeId, t in pairs(tLine) do
        local sNode = self._nodes[sNodeId]
        for _, eNodeId in ipairs(t) do
            local eNode = self._nodes[eNodeId]
            if sNode == nil or eNode == nil then
                Log.error("[discovery] s", sNodeId, "e ", eNodeId)
            end
            spawnLines[i]:Flush(sNode, eNode, false)
            i = i + 1
        end
    end
end

function UIDiscovery:FlushCamera()
    if not self._data then
        return
    end
    local node = self._data:GetCurPosNode()
    local mCampaign = GameGlobal.GetModule(CampaignModule)
    local grassData = mCampaign:GetGraveRobberData()
    local grassNodeFirst = grassData:GrassNodeFirst()
    if grassData:IsOpenGraveRobber() and grassNodeFirst then
        grassData:SaveLastNode(grassNodeFirst)
    end
    --相机
    local targetPos = Vector2.zero
    if self._isDiff then
        --困难模式
        ---@type UIDiffMissionModule
        local uiDiffModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        local diffChapterID = uiDiffModule:GetDiffCIDByMissionCID(self._chapterId)
        local pos = uiDiffModule:GetMoveNodePos(diffChapterID)
        targetPos = pos
        self._startDiffNodeID = nil
    else
        --主线模式
        if grassData:IsOpenGraveRobber() and grassNodeFirst then --如果长草开启并且有可打长草路点
            grassData:SaveGrassNodeFirst(nil)
            local pos = grassNodeFirst.pos
            targetPos:Set(pos.x, pos.y)
        else
            targetPos:Set(node.pos.x, node.pos.y)
        end
    end
    --[[
    local duration = 1
    if self._data.showUIStage then
        duration = 0
    end
    --]]
    self:CameraMoveTo(targetPos, 0, self._defaultScale)
end

function UIDiscovery:FlushRed()
    self:FlushRedChapterAward()
end

function UIDiscovery:FlushUIStage()
    if not self._data then
        return
    end
    if self._data.showUIStage then
        self._data.showUIStage = false
    else
        return
    end

    local node = self._data:GetCurPosNode()
    local stage = node.stages[1]
    local stageType = node:GetStageType()
    if stageType == DiscoveryStageType.Plot then
        self:CloseUIStage()
        self:ShowDialog("UIPlotEnter", node, stage,self._chapterId)
        return
    end

    self:OpenOrFlushStage(self._again)
    self._again = false
end

function UIDiscovery:FlushRedChapterAward()
    if not self._data then
        return
    end
    --章节奖励按钮红点
    local chapterAwardData = self._data.chapterAwardData
    local c = chapterAwardData:GetChapterAwardChapterByChapterId(self._chapterId)
    if c then
        self._imgRedChapterAward:SetActive(c:CanCollect())
    else
        Log.fatal("### no ChapterAwardChapter in ChapterAwardData. chapterId = ", self._chapterId)
    end
end

--endregion

--region OnClick

function UIDiscovery:btnPlotOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIDiscoveryClick", {"PlotOn"}, true)
    local node = self._data:GetCurPosNode()
    --过滤掉不可玩的关卡，得到可玩的关卡id数组
    local _canPlayStages = node:GetCanPlayStages()
    local lenStages = table.count(_canPlayStages)
    local _curStage
    if _canPlayStages and lenStages > 0 then
        local _curIdx = lenStages
        _curStage = _canPlayStages[_curIdx]
    end

    local canReviewStages = self._data:GetCanReviewStorys()
    if not canReviewStages or table.count(canReviewStages) <= 0 then
        ToastManager.ShowToast(StringTable.Get("str_discovery_no_can_review_plot"))
        return
    end
    self:ShowDialog("UIPlot", _curStage, canReviewStages)
end

function UIDiscovery:ShowHideUICanvas(isShow)
    --self.uiCanvas:SetActive(isShow)
    for i, v in ipairs(self._showHideInUICanvas) do
        v.gameObject:SetActive(isShow)
    end
end

function UIDiscovery:btnChapterAwardOnClick(go)
    GameGlobal.UAReportForceGuideEvent("UIDiscoveryClick", {"ChapterAward"}, true)
    self:ShowDialog("UIChapterAward", self._chapterId)
end

--endregion OnClick
local function outBackCurve(t, b, c, d, s)
    s = s or 1.70158
    t = t / d - 1

    return c * (t * t * ((s + 1) * t + s) + 1) + b
end

---@param target Vector2 目标位置坐标
---@param duration float 移动时长，0表示瞬移
---@param targetScale float 地图目标缩放值，为nil表示不进行缩放
---@param callback function 移动完成后的回调
---@param paramsTabel table 回调参数
function UIDiscovery:CameraMoveTo(target, duration, targetScale, callback, paramsTabel, ignoreLimit, outBack)
    if self:IsHandlingMap() then --操作地图的时候不允许移动相机
        return
    end
    if self._cameraTweener and self._cameraTweener:IsPlaying() then --相机移动过程不会被打断
        return
    end

    if callback then
        callback(paramsTabel)
        return
    end


    local endPos = self:GetContentMoveVector(target)
    local beginScale = self._data.mapScale
    if not ignoreLimit then
        if targetScale then
            targetScale = Mathf.Clamp(targetScale, self._scaleMin, self._scaleMax) --保证缩放值在范围之内
        end
    end
    if duration == -1 then --时间的为1的最远距离  小于则在0-1之间  大于则=1
        local moveMaximumDistance = 1000
        local currentDistance = (self._content.anchoredPosition - endPos).magnitude
        duration = Mathf.Lerp(0, 1, currentDistance / moveMaximumDistance)
    end
    --相机移动过程中开启UI锁
    if duration > 0 then
        local lockStr = "UIDiscoveryCameraMoveTo"
        self:StartTask(
            function(TT)
                self:Lock(lockStr)
                YIELD(TT, duration * 1000) --ms
                self:UnLock(lockStr)
            end,
            self
        )
    end

    local tempScale = 0
    local lockStr = "UIDiscoveryCameraMoveTo"
    self:Lock(lockStr)
    self._cameraTweener =
        self._content:DOAnchorPos(endPos, duration):OnUpdate(
        function()
            self:UpdateIgnLayoutPos()
            if targetScale then
                local value = 0
                if outBack then
                    if self._cameraTweener:ElapsedDirectionalPercentage() < 0.5 then
                        value = beginScale + 0.5 * self._cameraTweener:ElapsedDirectionalPercentage()
                        tempScale = value
                    else
                        value =
                            tempScale + (targetScale - tempScale) * self._cameraTweener:ElapsedDirectionalPercentage()
                    end
                else
                    value = beginScale + (targetScale - beginScale) * self._cameraTweener:ElapsedDirectionalPercentage()
                end
                self._sr:UpdateContentScale(value)
            end
        end
    ):OnComplete(function()
        self:UnLock(lockStr)
        if callback then
            callback(paramsTabel)
        end
    end)
end

function UIDiscovery:GetContentMoveVector(target)
    local endPos = Vector2.zero - target --既然是相机不动地图动，那么就该是地图沿着相机移动向量的反向量移动
    if self._content.sizeDelta.x ~= 0 then
        local limitX = self._content.sizeDelta.x * self._defaultScale / 2 - ResolutionManager.ScreenWidth() / 2
        local limitY = self._content.sizeDelta.y * self._defaultScale / 2 - ResolutionManager.ScreenHeight() / 2
        endPos.x = Mathf.Clamp(endPos.x, -limitX, limitX)
        endPos.y = Mathf.Clamp(endPos.y, -limitY, limitY)
    end
    return endPos
end

function UIDiscovery:GoWalkAlong(targetNodeId)
    local mCampaign = GameGlobal.GetModule(CampaignModule)
    local grassData = mCampaign:GetGraveRobberData()
    local nodeGrass = grassData:LastNode()
    if nodeGrass then
        self.fsm:ChangeState(
            StateDiscovery.Move2MainNode,
            targetNodeId,
            function()
                self:WalkOver(targetNodeId)
            end
        ) --切换到从活动路点到主线路点的状态
    else
        self:WalkAlong(targetNodeId)
    end
end

---@return Vector2 相机中心点所对的地图坐标
function UIDiscovery:CameraPos()
    local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local posScreen = Vector2(UnityEngine.Screen.width, UnityEngine.Screen.height) / 2
    local res, pos =
        UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._content, posScreen, camera, nil)
    Log.fatal("### CameraPos", pos)
    return pos
end

---@param targetNodeId int 目标路点ID
---@param speedReciprocal float 速度的倒数
function UIDiscovery:WalkAlong(targetNodeId, speedReciprocal)
    --local node = self:GetCurPosNode()
--
    --speedReciprocal = speedReciprocal or 0.001
    --local curPos = self:CameraPos()
    --local targetPos = self._data:GetPosByNodeId(targetNodeId)
    --local dis = Vector2.Distance(self:GetContentMoveVector(curPos), self:GetContentMoveVector(targetPos))
    --local duration = dis * speedReciprocal

    self:StartWalk(targetNodeId)
    self:CameraMoveTo(
        nil,
        nil,
        nil,
        function()
            self:WalkOver(targetNodeId)
        end
    )

    ---这么写保证UI锁会关闭
    --if duration > 0 then
    --    local lockStr = "UIDiscoveryWalkDragon"
    --    self:StartTask(
    --        function(TT)
    --            self:Lock(lockStr)
    --            YIELD(TT, duration * 1000)
    --            self:UnLock(lockStr)
    --        end,
    --        self
    --    )
    --end
end

---获取当前位置所处的主线路点
---@return DiscoveryNode
function UIDiscovery:GetCurPosNode()
    local node = self._data:GetCurPosNode()
    -- local chapter = node:GetChapter()
    -- local prevNode = chapter:PrevNode(node.id)
    -- if prevNode then
    --     node = prevNode
    -- end
    return node
end
---计算移动时长（两点）
function UIDiscovery:CalcWalkDuration(posStart, posEnd, speedReciprocal)
    speedReciprocal = speedReciprocal or 0.001
    local duration = 0
    local dis = Vector2.Distance(posStart, posEnd)
    duration = dis * speedReciprocal
    return duration
end

---@private
function UIDiscovery:StartWalk(targetNodeId)
    local node = self._data:GetCurPosNode()
    if node.id == targetNodeId then
        return --如果当前路点与目标路点一样
    end
    self._data:SetCurPosNodeId(targetNodeId)
    self:CloseUIStage()
end

function UIDiscovery:WalkOver(targetNodeId)
    ---@type DiscoveryNode
    local node = self._module:GetNodeDataByNodeId(targetNodeId)
    local stage = node.stages[1]
    if not stage:LevelReach() then
        self._reach = false
    else
        self._reach = true
    end
    local stageType = node:GetStageType()
    if stageType == DiscoveryStageType.Plot then
        self:CloseUIStage()
        self:ShowDialog("UIPlotEnter", node, stage,self._chapterId)
    else
        self:OpenOrFlushStage()
    end
end

function UIDiscovery:CloseUIStage()
    if GameGlobal.UIStateManager():IsShow("UIStage") then
        GameGlobal.UIStateManager():CloseDialog("UIStage")
    end
end

function UIDiscovery:ShotTest2()
    local node = self._data:GetCurPosNode()
    local stage = node.stages[1]
    local stageType = node:GetStageType()
    if stageType == DiscoveryStageType.Plot then
        self:CloseUIStage()
        self:ShowDialog("UIPlotEnter", node, stage,self._chapterId)
        return
    end
end

---如果关卡界面没打开，就打开；否则刷新关卡界面
---@param nodeId number 路点id
function UIDiscovery:OpenOrFlushStage(again)
    --local node = self:GetCurPosNode()
    --self._content.anchoredPosition = self:GetContentMoveVector(node.pos)
    --self:UpdateIgnLayoutPos()

    --self:Lock("ShowUIStage")

    self:StartTask(
        function(TT)
            --YIELD(TT)
            --self:UnLock("ShowUIStage")

            local node = self._data:GetCurPosNode()
            local stage = node.stages[1]
            local stageType = node:GetStageType()
            if stageType == DiscoveryStageType.Plot then
                self:CloseUIStage()
                self:ShowDialog("UIPlotEnter", node, stage,self._chapterId)
                return
            end
            GameGlobal.UAReportForceGuideEvent("UIDiscoveryClickMission", {node.id}, true)
            self:ShowDialog("UIStage", node.id, self._chapterId, self._reach, again)
        end,
        self
    )
end

---是否正在操作地图（单指滑动，两指缩放等）
function UIDiscovery:IsHandlingMap()
    if self._sr then
        return self._sr:IsDragging() or self._sr:IsScaling()
    end
end

function UIDiscovery:_PickPetTaskReward()
    -- local petModule = GameGlobal.GetModule(PetModule)
    -- local rewards = petModule:PickPetTaskResult()
    -- if rewards then
    --     self:ShowDialog("UIGetItemController", rewards)
    -- end
end

--------------------------章节奖励弱引导------------------------
function UIDiscovery:FlushChapterPreview()
    local missionModule = self:GetModule(MissionModule)

    if not self._chapterPreview then
        self._chapterPreview = {}
        self._chapterPreview.go = self:GetGameObject("chapterPreview")
        self._chapterPreview.icon = self:GetUIComponent("RawImageLoader", "chapteritemicon")
        self._chapterPreview.starCountTxt = self:GetUIComponent("UILocalizationText", "chapterstarcount")
        self._chapterPreview.countTxt = self:GetUIComponent("UILocalizationText", "chapteritemcount")
    end

    if not missionModule:GetShowChapterPreview() then
        self._chapterPreview.go:SetActive(false)
        return
    end
    local _data = missionModule:GetDiscoveryData()
    local chapterData = _data.chapterAwardData:GetChapterAwardChapterByChapterId(self._chapterId)
    self._chapterPreview.go:SetActive(false)
    if chapterData then
        local curMissionId = missionModule:GetCurMissionID()
        local data
        for key, v in pairs(chapterData.previewAward) do
            if curMissionId >= v.startMissionId and curMissionId < v.endMissionId then
                data = v
                break
            end
        end
        if data then
            self._chapterPreview.go:SetActive(true)
            local index = data.index
            local awardIndex = data.awardIndex
            local award = chapterData.grades[index].awards[awardIndex]
            local starCount = chapterData.grades[index].star_count
            local icon = award.icon
            local count = award.count
            self._chapterPreview.starCountTxt:SetText(starCount)
            self._chapterPreview.countTxt:SetText(count)
            self._chapterPreview.icon:LoadImage(icon)
        end
    end
end

function UIDiscovery:OnUIOpenClose()
    UnityEngine.Input.multiTouchEnabled =
        self:Manager():IsTopUI(self.name) or
        (self:Manager():GetController("UISpiritDetailLookCgAndSpineController") and
            self:Manager():IsTopUI("UISpiritDetailLookCgAndSpineController"))
end

function UIDiscovery:btnchapterpreviewOnClick()
    self:btnChapterAwardOnClick()
end

function UIDiscovery:GetResEntryBtn()
    return self.uiDiscoveryEnters and self.uiDiscoveryEnters:GetGameObject("btnResEctype")
end
function UIDiscovery:GetMazeEntryBtn()
    return self.uiDiscoveryEnters and self.uiDiscoveryEnters:GetGameObject("btnFairyLand")
end

function UIDiscovery:GetExtEntryBtn()
    return self.uiDiscoveryEnters and self.uiDiscoveryEnters:GetGameObject("btnPetStory")
end

function UIDiscovery:GetTowerBtn()
    return self.uiDiscoveryEnters and self.uiDiscoveryEnters:GetGameObject("btnTower")
end

function UIDiscovery:GetWorldBossBtn()
    return self.uiDiscoveryEnters and self.uiDiscoveryEnters:GetGameObject("btnWorldBoss")
end

function UIDiscovery:GuideToMission(missionID)
    --数据准备
    local chapterInfo = Cfg.cfg_mission_chapter {MissionID = missionID}[1]
    self._chapterId = chapterInfo.MainChapterID --要显示的章节
    self:ChangeDiff(false)
    self:CheckDiffBtn()
    self._data:UpdatePosByEnter(5, missionID)
    self:Flush()
    return self:GetNodeByNodeId(chapterInfo.WayPointID)
end

function UIDiscovery:ShowSerialRewards()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.Finished)
end

function UIDiscovery:_GetStoryComponentRemainingTime(targettime)
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curtime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    return targettime - curtime
end

function UIDiscovery:ShowAutoTestLogs()
    if EDITOR then
        self:ShowDialog("UIBattleAutoTest")
    end
end

function UIDiscovery:NormBtnOnClick(go)
    --检查当前主线是否全部通关
    local c = self._data:GetChapterByChapterId(self._chapterId)
    local complete = c:IsThreeComplete()
    local lock
    if complete then
        --检查困难关有没有开启
        --检查当前的主线有没有困难关
        ---@type UIDiffMissionModule
        local uiDiffMissionModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        local chapter = uiDiffMissionModule:GetDiffChapterFromMission(self._chapterId)
        if not chapter then
            Log.debug("###[UIDiscovery] no diff ! id --> ", self._chapterId)
            --没有困难关
            return
        end
        lock = chapter:Lock()
        if lock == DiffMissionChapterStatus.Lock then
            --困难关未解锁
            local tips = StringTable.Get("str_diff_mission_lock_by_diff")
            ToastManager.ShowToast(tips)
        else
            self:PlayAnimChangeDiff(
                "uieff_Discovery_switch01",
                function()
                    self:ChangeDiff(true) --切换困难模式
                    self:ChangeModeUpdateCameraPos()
                end
            )
        end
    else
        --主线未通关
        local tips = StringTable.Get("str_diff_mission_lock_by_norm")
        ToastManager.ShowToast(tips)
    end
    return complete,lock
end
function UIDiscovery:DiffBtnOnClick(go)
    self:PlayAnimChangeDiff(
        "uieff_Discovery_switch02",
        function()
            self:ChangeDiff(false)
            self:ChangeModeUpdateCameraPos()
        end
    )
end
---播放切换普通关/困难关动效
---@param animName string 切换动画名
---@param callback function 回调
function UIDiscovery:PlayAnimChangeDiff(animName, callback)
    self:StartTask(
        function(TT)
            self.goEffect:SetActive(true)
            local key = "UIDiscoveryPlayAnimChangeDiff"
            self:Lock(key)
            self.uiAnim:Play(animName)
            if callback then
                callback()
            end
            YIELD(TT, 1000)
            self.goEffect:SetActive(false)
            self:UnLock(key)
        end,
        self
    )
end
--移动相机
function UIDiscovery:ChangeModeUpdateCameraPos()
    self:FlushCamera()
end
function UIDiscovery:CheckDiffBtn()
    if self._isDiff then
        self._diffBtn:SetActive(false)
        self._normBtn:SetActive(false)
        self._plotBtnGo:SetActive(false)
        self._awardBtnGo:SetActive(false)
    else
        self._diffBtn:SetActive(false)
        self._plotBtnGo:SetActive(true)
        self._awardBtnGo:SetActive(true)
        --检查现不现实按钮
        local open = self:CheckOpenDiff()
        self._normBtn:SetActive(false)
        local btnsPosY = 0
        if not open then
            btnsPosY = 118
        end
        self._btnsPos.anchoredPosition = Vector2(0, btnsPosY)
    end
    self:GetGameObject("diffBtns"):SetActive(self:CheckOpenDiff())
    self._diffBtnRoot:SetChapterId(self._chapterId,self._isDiff)
    self._diffBtnRoot:SetCallBack(function () return self:NormBtnOnClick() end  ,function () self:DiffBtnOnClick() end)
end
function UIDiscovery:CheckOpenDiff()
    -- local c = self._data:GetChapterByChapterId(self._chapterId)
    -- local complete = c:IsThreeComplete()
    -- if not complete then
    --     return false
    -- end
    --检查困难关有没有开启
    --检查当前的主线有没有困难关
    ---@type UIDiffMissionModule
    local uiDiffMissionModule = GameGlobal.GetUIModule(DifficultyMissionModule)
    local chapter = uiDiffMissionModule:GetDiffChapterFromMission(self._chapterId)
    if not chapter then
        Log.debug("###[UIDiscovery] no diff ! id --> ", self._chapterId)
        --没有困难关
        return false
    end
    return true
end
function UIDiscovery:DiffNodeRoot()
    local cfgs = Cfg.cfg_difficulty_mission_chapter_desc {PreMainChapterId = self._chapterId}
    if cfgs and #cfgs > 0 then
        --有困难关的创建路点
        local cfg = cfgs[1]
        ---@type UIDiffMissionModule
        local uiDiffModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        local chapter = uiDiffModule:GetDiffChapterFromMission(self._chapterId)
        ---@type UIDiffNodeRoot
        local pool = self._diffNodePool:SpawnObject("UIDiffNodeRoot")
        pool:SetData(chapter)
    end
end
function UIDiscovery:FlushDiffNodes(mainChapterID)
    --还要刷新主线地图
    self:DiscoveryFlushChapter(mainChapterID, true)

    --self:DiffNodeRoot()
end

function UIDiscovery:_CheckGuide()
    local cfg = Cfg.cfg_guide_const["guide_diff"]
    local guideModule = GameGlobal.GetModule(GuideModule)
    if not guideModule:IsGuideDone(5044) and cfg and cfg.IntValue == self._chapterId then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIDiscoveryHardLevel)
        self:StartTask(function(TT)
            YIELD(TT)
            if guideModule:IsGuideProcess(5044) then
                --切到第11章
                self:DiscoveryFlushChapter(12, false)
            end
        end)
    end
end

function UIDiscovery:GetScreenShotView()
    return self._shot
end
function UIDiscovery:ShowDifficultBtns()
    self._diffBtnRoot = self._diffBtns:SpawnObject("UIDiscoveryDiffChaptersWeight")
end