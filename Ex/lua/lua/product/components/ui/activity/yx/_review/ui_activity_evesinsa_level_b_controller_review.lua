---@class UIActivityEveSinsaLevelBController_Review:UIController
_class("UIActivityEveSinsaLevelBController_Review", UIController)
UIActivityEveSinsaLevelBController_Review = UIActivityEveSinsaLevelBController_Review

---@class EveSinsaTreeMissionType
local EveSinsaTreeMissionType = {
    Small = 1,
    Middle = 2,
    Final = 3
}
_enum("EveSinsaTreeMissionType", EveSinsaTreeMissionType)

function UIActivityEveSinsaLevelBController_Review:_GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIActivityEveSinsaMainController_Review,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end,
        nil
    )

    -- local exchangeRewardBtn = self:GetUIComponent("UISelectObjectPath", "_exchangeRewardBtn")
    -- ---@type UIActivityEveSinsaShopBtn
    -- self._exchangeRewardBtn = exchangeRewardBtn:SpawnObject("UIActivityEveSinsaShopBtn")
    -- self._exchangeRewardBtn:SetData(self._campaign)

    local secondTitle = self:GetUIComponent("UISelectObjectPath", "_secondTitle")
    ---@type UIActivityEveSinsaSecondTitle_Review
    self._secondTitle = secondTitle:SpawnObject("UIActivityEveSinsaSecondTitle_Review")
    self._secondTitle:SetData(self._campaign, 1)

    ---@type UnityEngine.GameObject
    self._finalStageRoot = self:GetGameObject("FinalStage")
    ---@type UnityEngine.UI.Image
    self._finalStageImage = self:GetUIComponent("Image", "FinalIcon")

    ---@type table<number, UnityEngine.GameObject>
    self._middleStageRootList = {}
    self._middleStageRootList[1] = self:GetGameObject("MiddleStageRoot1")
    self._middleStageRootList[2] = self:GetGameObject("MiddleStageRoot2")
    self._middleStageRootList[3] = self:GetGameObject("MiddleStageRoot3")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "ScreenShot")
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityEveSinsaLevelBController_Review:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- -- 获取活动 以及本窗口需要的组件
    -- ---@type UIActivityCampaign
    -- self._campaign = UIActivityCampaign:New()
    -- self._campaign:LoadCampaignInfo(
    --     TT,
    --     res,
    --     ECampaignType.CAMPAIGN_TYPE_EVERESCUEPLAN,
    --     ECampaignEvaRescuePlanComponentID.ECAMPAIGN_EVARESCUEPLAN_TREE_MISSION
    -- )

    ---@type UICampaignModule
    local uiModule = GameGlobal.GetUIModule(CampaignModule)
    ---@type UIReviewActivityN1
    local n1 = uiModule:GetReviewData():GetActivityByType(ECampaignType.CAMPAIGN_TYPE_REVIEW_N1)
    n1:ReqDetailInfo(TT, res)
    self._campaign = n1:GetDetailInfo()

    if res and res:GetSucc() then
        ---@type TreeMissionComponent
        self._camp =
            self._campaign:GetComponent(
            ECampaignReviewEvaRescuePlanComponentID.ECAMPAIGN_REVIEW_EVARESCUEPLAN_TREE_MISSION
        )
        ---@type TreeMissionComponentInfo
        self._campInfo = self._camp:GetComponentInfo()

        -- 活动没结束，但是关卡组件已关闭时，显示活动已关闭
        self._phase = UIActivityEveSinsaHelper.CheckTimePhase(self._campaign)
        if
            self._phase ~= EActivityEveSinsaTimePhase.EPhase_Over and
                not self._campaign:CheckComponentOpen(
                    ECampaignReviewEvaRescuePlanComponentID.ECAMPAIGN_REVIEW_EVARESCUEPLAN_TREE_MISSION
                )
         then
            res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_UNLOCK
            campaignModule:ShowErrorToast(res.m_result, true)
            return
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIActivityEveSinsaLevelBController_Review:OnShow(uiParams)
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)

    self:_GetComponents()
    self:_SetBg()
    self:_SetBgSpine()
    self:_SetMainTex()

    ---界面显示数据
    self:_FillData()
    ---界面显示
    self:_InitUI()
    self:_OpenUIRecord()
end
function UIActivityEveSinsaLevelBController_Review:_OpenUIRecord()
    local loginModule = self:GetModule(LoginModule)
    if LocalDB.GetInt("ACTIVITY_EVE_SINA_P2_NEWFLAG_REVIEW" .. loginModule:GetRoleShowID(), 0) <= 0 then
        LocalDB.SetInt("ACTIVITY_EVE_SINA_P2_NEWFLAG_REVIEW" .. loginModule:GetRoleShowID(), 1)
    end
end
function UIActivityEveSinsaLevelBController_Review:OnHide()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
end

function UIActivityEveSinsaLevelBController_Review:_FillData()
    ---关卡信息
    local cfgID =
        self._camp:GetComponetCfgId(
        self._camp:GetComponentInfo().m_campaign_id,
        self._camp:GetComponentInfo().m_component_id
    )
    local finalStageConfigList =
        Cfg.cfg_component_tree_mission {ComponentID = cfgID, Type = EveSinsaTreeMissionType.Final}

    if #finalStageConfigList == 0 then
        ToastManager.ShowToast(
            "can't find stage config ComponentID:" .. cfgID .. " Type:" .. EveSinsaTreeMissionType.Final
        )
        self:CloseDialog()
        return
    end

    local finalStageConfig = finalStageConfigList[1]
    self._finalStageID = finalStageConfig.CampaignMissionId
    self._middleStageIDList = {}
    self._smallStageIDTable = {}
    for i = 1, #finalStageConfig.NeedMissionList do
        local missionID = finalStageConfig.NeedMissionList[i]
        self._middleStageIDList[i] = missionID
        local middleStageConfig = Cfg.cfg_component_tree_mission {CampaignMissionId = missionID}

        if #middleStageConfig == 0 then
            ToastManager.ShowToast("can't find stage config CampaignMissionId:" .. missionID)
            self:CloseDialog()
        end

        self._smallStageIDTable[i] = {}
        for j = 1, #middleStageConfig[1].NeedMissionList do
            self._smallStageIDTable[i][j] = middleStageConfig[1].NeedMissionList[j]
        end
    end

    ---@type table<number, cam_mission_info> 完成的关卡数据<missionID, cam_mission_info>
    self._passInfo = self._campInfo.m_pass_mission_info
end

function UIActivityEveSinsaLevelBController_Review:_InitUI()
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIActivityEveSinsa.spriteatlas", LoadType.SpriteAtlas)
    self._stageBGGOList = {}
    local middleStagePassCount = 0
    --配置的middle关卡顺序即左中右的顺序
    for i = 1, #self._middleStageIDList do
        self:_InitMiddleStageUI(i, self._middleStageIDList[i])

        if self._passInfo[self._middleStageIDList[i]] then
            middleStagePassCount = middleStagePassCount + 1
        end
    end

    if middleStagePassCount == 3 then
        for i = 1, #self._stageBGGOList do
            self._stageBGGOList[i]:SetActive(false)
        end

        self:_InitFinalStageUI()
    end
end

---@param stageIndex number
function UIActivityEveSinsaLevelBController_Review:_InitMiddleStageUI(stageIndex, stageID)
    ---@type UnityEngine.Transform
    local stagesRootTrans = self._middleStageRootList[stageIndex].transform
    local smallStageIDList = self._smallStageIDTable[stageIndex]
    self._stageBGGOList[stageIndex] = stagesRootTrans:Find("StageBG").gameObject
    local stageBGHighlight = stagesRootTrans:Find("BGHighlight").gameObject
    stageBGHighlight:SetActive(false) -- auto load 之后隐藏
    local stageMask = stagesRootTrans:Find("BGMask").gameObject

    local passCount = 0
    for i = 1, #smallStageIDList do
        --data
        local smallStageID = smallStageIDList[i]
        local stageCfg = Cfg.cfg_campaign_mission[smallStageID]

        --ui
        ---@type UnityEngine.GameObject
        local smallStageGO = stagesRootTrans:Find("Stage" .. i).gameObject
        ---@type UnityEngine.UI.Image
        local smallStageBG = smallStageGO:GetComponentInChildren(typeof(UnityEngine.UI.Image))
        ---@type UILocalizationText
        local stageTxt = smallStageGO:GetComponentInChildren(typeof(UILocalizationText))
        if self._passInfo[smallStageID] then
            smallStageBG.sprite = self._atlas:GetSprite("event_eve_di60")
            stageTxt:SetText("CLEAR")
            stageTxt.color = Color(1, 225 / 255, 60 / 255)
            passCount = passCount + 1
        else
            smallStageBG.sprite = self._atlas:GetSprite("event_eve_di59")
            stageTxt:SetText(StringTable.Get(stageCfg.Name))
            stageTxt.color = Color(24 / 255, 24 / 255, 24 / 255)
        end
    end

    local middleStageCfg = Cfg.cfg_campaign_mission[stageID]

    local challengeRoot = stagesRootTrans:Find("StageFinal/Challenge").gameObject
    local LockRoot = stagesRootTrans:Find("StageFinal/Lock").gameObject
    if passCount == 3 then
        --可挑战
        challengeRoot:SetActive(true)
        LockRoot:SetActive(false)
        stageMask:SetActive(false)

        local stageNameTxt =
            challengeRoot.transform:Find("StageName").gameObject:GetComponent(typeof(UILocalizationText))
        stageNameTxt:SetText(StringTable.Get(middleStageCfg.Name))

        local TintTxt = challengeRoot.transform:Find("Tint").gameObject:GetComponent(typeof(UILocalizationText))
        local redPoint = challengeRoot.transform:Find("RedPoint").gameObject
        if self._passInfo[stageID] then
            TintTxt:SetText(StringTable.Get("str_activity_evesinsa_level_clear"))
            redPoint:SetActive(false)

            challengeRoot:GetComponent(typeof(UnityEngine.UI.Image)).sprite =
                LockRoot:GetComponent(typeof(UnityEngine.UI.Image)).sprite
            challengeRoot.transform:Find("LeftArrow").gameObject:SetActive(false)
            challengeRoot.transform:Find("RightArrow").gameObject:SetActive(false)
        else
            TintTxt:SetText(StringTable.Get("str_activity_evesinsa_level_open"))
            redPoint:SetActive(true)
        end

        local etl1 = challengeRoot
        local highlight1 = stagesRootTrans:Find("StageFinal/Challenge/Highlight").gameObject
        local etl2 = stagesRootTrans:Find("BG").gameObject
        local highlight2 = stageBGHighlight
        self:_SetUIHighlight(etl1, highlight1, highlight2)
        self:_SetUIHighlight(etl2, highlight1, highlight2)

        local rawbg = stagesRootTrans:Find("BG").gameObject:GetComponent(typeof(UnityEngine.UI.RawImage))
        rawbg.raycastTarget = true
    else
        --不可挑战
        challengeRoot:SetActive(false)
        LockRoot:SetActive(true)
        stageMask:SetActive(true)

        local stageNameTxt = LockRoot.transform:Find("StageName").gameObject:GetComponent(typeof(UILocalizationText))
        stageNameTxt:SetText(StringTable.Get(middleStageCfg.Name))

        local formatStr = "<color=#%s>%s</color>/3"
        local colorStr = "FFD200"
        local progressTxt = LockRoot.transform:Find("StageProgress").gameObject:GetComponent(typeof(UILocalizationText))
        progressTxt:SetText(string.format(formatStr, colorStr, passCount))
    end
end

function UIActivityEveSinsaLevelBController_Review:_InitFinalStageUI()
    self._finalStageRoot:SetActive(true)
    self._finalStageImageNormal = self._finalStageImage.sprite
    self._finalStageImageLight = self._atlas:GetSprite("event_eve_icon15")

    local etl = self._finalStageRoot
    local highlight = self._finalStageRoot.transform:Find("Highlight").gameObject

    self:_SetUIHighlight(etl, highlight, nil)
end

function UIActivityEveSinsaLevelBController_Review:_SetUIHighlight(obj, highlight1, highlight2)
    local etl = UICustomUIEventListener.Get(obj)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Press,
        function(go)
            highlight1:SetActive(true)
            if highlight2 then
                highlight2:SetActive(true)
            end
        end
    )
    --[[
    self:AddUICustomEventListener(
        etl,
        UIEvent.Unhovered,
        function(go)
            self._finalStageImage.sprite = self._finalStageImageNormal
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Hovered,
        function(go)
            self._finalStageImage.sprite = self._finalStageImageLight
        end
    )]]
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            highlight1:SetActive(false)
            if highlight2 then
                highlight2:SetActive(false)
            end
        end
    )
end

function UIActivityEveSinsaLevelBController_Review:_EnterMiddleStage(stageIndex)
    self:_DoScreenShot(stageIndex)
    local middleStageID = self._middleStageIDList[stageIndex]
    -- self:ShowDialog(
    --     "UIActivityStage",
    --     middleStageID,
    --     self._passInfo[middleStageID],
    --     self._camp,
    --     self._rt,
    --     self._offset * self._scale,
    --     self._width,
    --     self._height,
    --     self._scale,
    --     false
    -- )

    self:ShowDialog(
        "UIActivityLevelStageNew",
        middleStageID,
        self._passInfo[middleStageID],
        self._camp,
        false,
        nil, --行动点组件
        true, --隐藏顶条
        true --隐藏体力图标
    )
end

function UIActivityEveSinsaLevelBController_Review:_EnterSmallStage(middleStageIndex, smallStageIndex)
    self:_DoScreenShot(middleStageIndex)
    local smallStageID = self._smallStageIDTable[middleStageIndex][smallStageIndex]
    --if not self._passInfo[smallStageID] then 25651 伊芙活动QA_二阶段小关卡通关后还可以进_20210624
    -- self:ShowDialog(
    --     "UIActivityStage",
    --     smallStageID,
    --     self._passInfo[smallStageID],
    --     self._camp,
    --     self._rt,
    --     self._offset * self._scale,
    --     self._width,
    --     self._height,
    --     self._scale,
    --     false
    -- )

    self:ShowDialog(
        "UIActivityLevelStageNew",
        smallStageID,
        self._passInfo[smallStageID],
        self._camp,
        false,
        nil, --行动点组件
        true, --隐藏顶条
        true --隐藏体力图标
    )
    --end
end

function UIActivityEveSinsaLevelBController_Review:_DoScreenShot(middleStageIndex)
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local shotRect = self:GetUIComponent("RectTransform", "ScreenShot")
    self._width = shotRect.rect.width
    self._height = shotRect.rect.height

    self._shot.width = self._width
    self._shot.height = self._height
    self._shot.blurTimes = 0
    self._scale = 1.2

    self._shot:CleanRenderTexture()
    self._rt = self._shot:RefreshBlurTexture()

    local maxOffset = 1058 / 2 -- UIActivityStage rt 的遮罩大小
    local posX = -self._middleStageRootList[middleStageIndex].transform.localPosition.x
    local posY = -self._middleStageRootList[middleStageIndex].transform.localPosition.y
    posX = math.max(math.min(posX, maxOffset), -maxOffset)
    self._offset = Vector2(posX, posY)
end

function UIActivityEveSinsaLevelBController_Review:_SetBg()
    self._mainBg = self:GetUIComponent("RawImageLoader", "_mainBg")
    local phase = EActivityEveSinsaTimePhase.EPhase_Tree

    local url = UIActivityEveSinsaHelper.GetPhaseBgUrl(self._campaign, phase)
    if url then
        self._mainBg:LoadImage(url)
    end
end

function UIActivityEveSinsaLevelBController_Review:_SetBgSpine()
    self._spineGo = self:GetGameObject("_spine")
    self._spineGo:SetActive(true)
    self._spine = self:GetUIComponent("SpineLoader", "_spine")
    self._spine:LoadSpine("yifuhuodong_spine_idle")
end

---region callbacks
function UIActivityEveSinsaLevelBController_Review:Stage11OnClick()
    self:_EnterSmallStage(1, 1)
end

function UIActivityEveSinsaLevelBController_Review:Stage12OnClick()
    self:_EnterSmallStage(1, 2)
end

function UIActivityEveSinsaLevelBController_Review:Stage13OnClick()
    self:_EnterSmallStage(1, 3)
end

function UIActivityEveSinsaLevelBController_Review:Stage21OnClick()
    self:_EnterSmallStage(2, 1)
end

function UIActivityEveSinsaLevelBController_Review:Stage22OnClick()
    self:_EnterSmallStage(2, 2)
end

function UIActivityEveSinsaLevelBController_Review:Stage23OnClick()
    self:_EnterSmallStage(2, 3)
end

function UIActivityEveSinsaLevelBController_Review:Stage31OnClick()
    self:_EnterSmallStage(3, 1)
end

function UIActivityEveSinsaLevelBController_Review:Stage32OnClick()
    self:_EnterSmallStage(3, 2)
end

function UIActivityEveSinsaLevelBController_Review:Stage33OnClick()
    self:_EnterSmallStage(3, 3)
end

function UIActivityEveSinsaLevelBController_Review:StageMid1OnClick()
    self:_EnterMiddleStage(1)
end

function UIActivityEveSinsaLevelBController_Review:StageMidBG1OnClick()
    self:_EnterMiddleStage(1)
end

function UIActivityEveSinsaLevelBController_Review:StageMid2OnClick()
    self:_EnterMiddleStage(2)
end

function UIActivityEveSinsaLevelBController_Review:StageMidBG2OnClick()
    self:_EnterMiddleStage(2)
end

function UIActivityEveSinsaLevelBController_Review:StageMid3OnClick()
    self:_EnterMiddleStage(3)
end

function UIActivityEveSinsaLevelBController_Review:StageMidBG3OnClick()
    self:_EnterMiddleStage(3)
end

function UIActivityEveSinsaLevelBController_Review:FinalStageOnClick()
    local storyID = self:GetModule(MissionModule):GetStoryByStageIdStoryType(self._finalStageID, StoryTriggerType.Node)
    if not storyID then
        ToastManager.ShowToast("final stage story ID not exist!")
        return
    end

    --刷新一下通关情况
    self._passInfo = self._campInfo.m_pass_mission_info

    self:ShowDialog(
        "UIStoryController",
        storyID,
        function()
            if self._passInfo[self._finalStageID] then
                return
            end

            self:StartTask(
                function(TT)
                    self:Lock("UIActivityEveSinsaLevelBController_Review:FinalStageOnClick")
                    local res = AsyncRequestRes:New()
                    ---@type table<number, RoleAsset>
                    local reward = self._camp:HandleCompleteStoryTreeMission(TT, res, self._finalStageID)

                    if res:GetResult() == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS then
                        self:ShowDialog("UIGetItemController", reward)
                    else
                        ToastManager.ShowToast("Finish Final Stage Error:" .. res:GetResult())
                    end
                    self:UnLock("UIActivityEveSinsaLevelBController_Review:FinalStageOnClick")
                end,
                self
            )
        end
    )
end

function UIActivityEveSinsaLevelBController_Review:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end
---region end

function UIActivityEveSinsaLevelBController_Review:_SetMainTex()
    local panelObj = self:GetGameObject("Panel")
    local panel = GameObjectHelper.FindFirstSkinedMeshRender(panelObj)

    local imageMat = panel.materials[0]
    if imageMat == nil then
        return
    end

    local matName = "event_eve_di64"
    local rawimageHelper = RawImageLoaderHelper:New()
    rawimageHelper:Init(1)
    local mat = rawimageHelper:GetMat(matName)
    imageMat:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end
