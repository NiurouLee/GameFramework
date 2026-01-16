require "bounce_controller"
--小游戏入口uicontroller
---@class UIBounceMainController : UIController
_class("UIBounceMainController", UIController)
UIBounceMainController = UIBounceMainController

function UIBounceMainController:Constructor()
    ---@type BounceController
    self.coreController = nil
    self.levelId = 0
    self.isBoss = false 
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._loginModule = self:GetModule(LoginModule)

    self.aniName = 
    {
       [1] =  "uieff_UIBounceMainController_in_aniBgs",
       [2] =  "uieff_UIBounceMainController_in_boss"
    }
end

---@param res AsyncRequestRes
function UIBounceMainController:LoadDataOnEnter(TT, res)
    self._campaign = UIActivityCampaign:New()
    local campaignModule = self:GetModule(CampaignModule)
    self._campaignModule = campaignModule
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N28_MINI_GAME,
        ECampaignN28MiniGameComponentID.ECAMPAIGN_BOUNCE_MISSION
    )
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end

    self._component = self._campaign:GetComponent(ECampaignN28MiniGameComponentID.ECAMPAIGN_BOUNCE_MISSION)
    self._componentInfo = self._campaign:GetComponentInfo(ECampaignN28MiniGameComponentID.ECAMPAIGN_BOUNCE_MISSION)
    local openTime = self._componentInfo.m_unlock_time
    local closeTime = self._componentInfo.m_close_time
    local nowtime = self._svrTimeModule:GetServerTime() / 1000
    if nowtime < openTime then
        res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
        campaignModule:ShowErrorToast(res.m_result, true)
        return
    end
    if nowtime > closeTime then
        res.m_result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
        campaignModule:ShowErrorToast(res.m_result, true)
        return
    end
end

--初始化
function UIBounceMainController:OnShow(uiParams)
    self.levelId = uiParams[1]
    self.selectPlayer = uiParams[2]
    self.historyBestScore = uiParams[3]
    self.isBoss = self.levelId == 6 or self.levelId == 7 
    self:InitWidget()
    self:InitView()
    self:InitCore()
    self:StartAnim()
end

function UIBounceMainController:OnUpdate(deltaTimeMS) 
    if self.coreController then
        self.coreController:OnUpdate(deltaTimeMS)
    end
    if self.inputView then
        self.inputView:OnUpdate()
    end 
end

--获取ui组件
function UIBounceMainController:InitWidget()
    self._atlas = self:GetAsset("UIN28MinigameIn.spriteatlas", LoadType.SpriteAtlas) 
    ---@type UnityEngine.RectTransform
    self.gameCanvasRt = self:GetUIComponent("RectTransform","gameCanvas")
    ---@type UnityEngine.GameObject
    self.uiGo = self:GetGameObject("ui")
    ---@type UnityEngine.GameObject
    self.backBtnGo = self:GetGameObject("backBtn")

    ---@type UnityEngine.GameObject
    self.scoreGo = self:GetGameObject("score")
    ---@type UILocalizationText
    self.txtCurScore = self:GetUIComponent("UILocalizationText", "txtCurScore")
    ---@type UILocalizationText
    self.txtHistoryScore = self:GetUIComponent("UILocalizationText", "txtHistoryScore")
    ---@type UnityEngine.GameObject
    self.historyScoreGo = self:GetGameObject("historyScore")

    ---@type UICustomWidgetPool
    local inputPool = self:GetUIComponent("UISelectObjectPath", "input")
    self.inputView = inputPool:SpawnObject("UIBounceInput")
    self.inputGo = self:GetGameObject("input")
    
    ---@type UICustomWidgetPool
    local preparePool = self:GetUIComponent("UISelectObjectPath", "prepare")
    self.prepareView = preparePool:SpawnObject("UIBouncePrepare")
    self.prepareGo = self:GetGameObject("prepare")

    ---@type UICustomWidgetPool
    local resultPool = self:GetUIComponent("UISelectObjectPath", "result")
    self.resultView = resultPool:SpawnObject("UIBounceResult")
    self.resultGo = self:GetGameObject("result")

    ---@type UICustomWidgetPool
    local resumePool = self:GetUIComponent("UISelectObjectPath", "resume")
    self.resumeView = resumePool:SpawnObject("UIBounceResume")
    self.resumeGo = self:GetGameObject("resume")

    ---@type UICustomWidgetPool
    local pausePool = self:GetUIComponent("UISelectObjectPath", "pause")
    self.pauseView = pausePool:SpawnObject("UIBouncePause")
    self.pauseGo = self:GetGameObject("pause")
    self.backBtn = self:GetGameObject("backBtn")
    self.historyScore = self:GetGameObject("historyScore")
    self.curScore = self:GetGameObject("curScore")
    self._anim = self:GetUIComponent("Animation", "root")
   
    self.historyScoreItems = {}
    self.curScoreItems = {}
    for i = 1, 4, 1 do
        self.historyScoreItems[i] = self.historyScore.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
        self.curScoreItems[i] = self.curScore.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
    end

    -- boss
    ---@type Slider
    self.slider = self:GetUIComponent("Slider", "slider")
    self.historyScorePar = self:GetGameObject("historyScorePar")
    self.hpGo = self:GetGameObject("HP")
    self.aniBgs = self:GetGameObject("aniBgs")
    self.bossBgs = self:GetGameObject("bossBgs")
    self.nowGo = self:GetGameObject("now")
    self.maxGo = self:GetGameObject("max")
    self.lv1Go = self:GetGameObject("LV1")
    self.lv2Go = self:GetGameObject("LV2")
    self.night =  self:GetGameObject("night")
    self.bossImage =  self:GetUIComponent("RawImageLoader", "bossBg")
    self.nowHp = {}
    self.maxHp = {}
    for i = 1, 2, 1 do
        self.nowHp[i] = self.nowGo.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
        self.maxHp[i] = self.maxGo.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
    end

    self.bgRaws = {}
    for i = 1,   self.lv1Go.transform.childCount, 1 do
        self.bgRaws[i] =   self.lv1Go.transform:GetChild(i-1):GetComponent(typeof(RawImageLoader))
    end
    self.bgImgs = {}
    for i = 1,   self.lv2Go.transform.childCount, 1 do
        self.bgImgs[i] = self.lv2Go.transform:GetChild(i-1):GetComponent(typeof(UnityEngine.UI.Image))
    end


    
    self.guideRt = {}
    for i = 1, 8, 1 do
        local key = "guide118008"..i
        ---@type UnityEngine.RectTransform
        local guideRt = self:GetUIComponent("RectTransform",key)
        self.guideRt[key] = guideRt
    end

    for i = 1, 6, 1 do
        local key = "guide118009"..i
        ---@type UnityEngine.RectTransform
        local guideRt = self:GetUIComponent("RectTransform",key)
        self.guideRt[key] = guideRt
    end
    self.guideRt["guide1180111"] = self:GetUIComponent("RectTransform", "guide1180111")
    self.guideRt["guide1180121"] = self:GetUIComponent("RectTransform", "guide1180121")
end

function UIBounceMainController:InitView()
    --result
    self.resultView:Init(
        function () -- exitGame
            if self:CheckActivityOver()  then
                self:SwitchState(UIStateType.UIMain)
                return 
            end 
            self:QuickGame()
        end,
        function () --restartGame
            if self:CheckActivityOver()  then
               return 
            end 
            self:RestartGame()
        end
    )
    --resume
    self.resumeView:Init(
        function () --resume finish
            self.coreController:ChgFsmState(StateBounce.Battle)
        end
    )
    --pause
    self.pauseView:Init(
        function() --exit game
            if not self.coreController:IsOvering() then
                self.backBtn:SetActive(true)
                self.coreController:ChgFsmState(StateBounce.Over)
            end
        end,
        function () --continue game
            if not self.coreController:IsOvering() then
                self.backBtn:SetActive(true)
                self.coreController:ChgFsmState(StateBounce.Resume)
            end
        end
    )
    --input
    self.inputView:Init(
        function(fromPC) --attack cmd
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
            self.coreController:OnAttack(fromPC)
        end,
        function (fromPC) --jump cmd
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
            self.coreController:OnJump(fromPC)
        end
    )

    for i = 1, 4, 1 do
        self.historyScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..0)
        self.curScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..0)
    end
    for i = 1, 2, 1 do
        self.maxHp[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure1"..9)
        self.nowHp[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure1"..0)
    end

    self.aniBgs:SetActive(not self.isBoss)
    self.bossBgs:SetActive(self.isBoss)
    self.hpGo:SetActive(false)

    local index = math.random(1, 3)
    for  i = 1, #self.bgRaws do 
        local str =UIN28GronruGameConst.bgData[index][1][i]
        self.bgRaws[i]:LoadImage(str)
    end 
    for  i = 1, #self.bgImgs do 
        local str = UIN28GronruGameConst.bgData[index][2][i]
        self.bgImgs[i].sprite = self._atlas:GetSprite(str)
    end 
    self.night:SetActive(index == 3)
    local str = self.levelId == 7 and "N28_yrj_gzdt_cbbg06" or "N28_yrj_gzdt_cbbg01"
    self.bossImage:LoadImage(str)
end

function UIBounceMainController:InitCore()
    ---@type BounceController
    self.coreController = BounceController:New()
    self.coreController:Init(self, self.levelId, self.selectPlayer, self.historyBestScore)
    --无尽关 特殊处理
    self.historyScorePar:SetActive( self.levelId == 7)
    self:SetHistoryScore()
end

function UIBounceMainController:GetPrepareView()
    return self.prepareView, self.prepareGo
end

function UIBounceMainController:GetResultView()
    return self.resultView, self.resultGo
end

---@type UIBounceResume
function UIBounceMainController:GetResumeView()
    return self.resumeView, self.resumeGo
end

---@type UIBouncePause
function UIBounceMainController:GetPauseView()
    return self.pauseView, self.pauseGo
end

function UIBounceMainController:SetViewVisibleByBouceState(state)
    self.prepareGo:SetActive(state == StateBounce.Prepare)
    self.resultGo:SetActive(false)
    self.resumeGo:SetActive(state == StateBounce.Resume)
    self.pauseGo:SetActive(state == StateBounce.Pause)
    self.inputGo:SetActive(true)
end


--按钮点击
function UIBounceMainController:BackBtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
    if self.coreController:IsOvering() then
        return
    end
    self.backBtn:SetActive(false)
    self.coreController:ChgFsmState(StateBounce.Pause)
end

--退出游戏
function UIBounceMainController:QuickGame()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
    self.coreController:OnQuick()
    self:SwitchState(UIStateType.UIN28GronruGameLevel)
end

--重新挑战
function UIBounceMainController:RestartGame()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
    for i = 1, 4, 1 do
        self.curScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..0)
    end
    self.coreController:GetGameData():AddHistoryBestScore()
    self.coreController:OnRestartGame()
    self:SetHistoryScore()
    self.hpGo:SetActive(false)
    self.slider.value = 1
end


function UIBounceMainController:GetCanvasRt()
    return self.gameCanvasRt
end

---怪物死亡
function UIBounceMainController:MonsterDead(monsterId)
    --todo
end

---积分变化
function UIBounceMainController:ScoreChange(score)
    local res = UIN28GronruGameConst.GetScoreFont(score)
    for i = 1, 4, 1 do
        self.curScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..res[i])
    end
end

--显示血条
function UIBounceMainController:ShowHPProgress(serializeId, maxValue)
    --todo
    local nums = UIN28GronruGameConst.GetScoreFont(maxValue)
    for i = 1, 2, 1 do
        self.nowHp[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure1"..nums[i + 2])
        self.maxHp[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure1"..nums[i + 2 ])
    end
    self.hpGo:SetActive(true)
end

--隐藏血条
function UIBounceMainController:HideHPProgress(serializeId)
    --todo
    self.hpGo:SetActive(false)
end

--血条数据变化
function UIBounceMainController:HPProgressChange(serializeId, currentValue, maxValue)
    --todo
    local nums
    for i = 1, 2, 1 do
        nums = UIN28GronruGameConst.GetScoreFont(currentValue)
        self.nowHp[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure1"..nums[i + 2])
        nums = UIN28GronruGameConst.GetScoreFont(maxValue)
        self.maxHp[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure1"..nums[i + 2])
    end
    self.slider.value = currentValue/maxValue
end
-- 积分请求
function UIBounceMainController:BounceMissionSettle(missionId, killNum, killBossNum, cost_time,callback)
    self:StartTask(function (TT) 
        local asyncRes = AsyncRequestRes:New()
        asyncRes =  self._component:HandleBounceMissionSettle(TT, asyncRes, missionId, killNum, killBossNum, cost_time,callback)
        if asyncRes and asyncRes:GetSucc() then 
            if callback then
               -- callback()
            end 
        end 
    end )
end
-- 显示结果
function UIBounceMainController:ShowResult()
    local data =  self.coreController:GetGameData().targetMonster
    self:StartTask( function(TT)
        self:Lock("UIBounceMainController:ShowResult")
        local res = AsyncRequestRes:New()
        self._campaign:ReLoadCampaignInfo_Force(TT, res)

        self:PlayMissionStory(self.levelId )

        self:UnLock("UIBounceMainController:ShowResult")
    end,
    self
    )
end


function UIBounceMainController:PlayMissionStory(index)
    local roleId =  self._loginModule:GetRoleShowID()
    local key = index

    if  UIN28GronruGameConst.CheckStoryLocalDb(roleId,key,false)  then
        self.resultGo:SetActive(true)
        self.resultView:FlushUI(self.coreController:GetGameData())
        return
    end

    local storyId =  self.coreController:GetGameData().levelCfg.LastStoryId
    if storyId then
        -- boss关特殊处理
        if index == 6  then
            if self.coreController:GetGameData():GetKilledBoss() then 
                GameGlobal.GetModule(StoryModule):StartStory(
                    storyId,
                    function()
                        UIN28GronruGameConst.SetStoryLocalDb(roleId,key,false) 
                        self.resultGo:SetActive(true)
                        self.resultView:FlushUI(self.coreController:GetGameData())
                    end
                )
            else 
                self.resultGo:SetActive(true)
                self.resultView:FlushUI(self.coreController:GetGameData())
            end 
        else 
            GameGlobal.GetModule(StoryModule):StartStory(
                storyId,
                function()
                    UIN28GronruGameConst.SetStoryLocalDb(roleId,key,false) 
                    self.resultGo:SetActive(true)
                    self.resultView:FlushUI(self.coreController:GetGameData())
                end
            )
        end 
    else 
        self.resultGo:SetActive(true)
        self.resultView:FlushUI(self.coreController:GetGameData())
    end 
end

function UIBounceMainController:SetHistoryScore()
    local data =  self.coreController:GetGameData()
    local res = UIN28GronruGameConst.GetScoreFont(data.historyBestScore)
    for i = 1, 4, 1 do
        self.historyScoreItems[i].sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..res[i])
    end
end


function UIBounceMainController:StartAnim() 
    self:StartTask(function (TT)
        self:Lock("UIBounceMainController:StartAnim")
        local anistr =  self.levelId >= 6 and self.aniName[2] or self.aniName[1]
        self._anim:Play(anistr)
        YIELD(TT,333)
        self:UnLock("UIBounceMainController:StartAnim")
        end)
end 


function UIBounceMainController:GetGuideRt(guideStepKey)
    return self.guideRt[guideStepKey] 
end

function UIBounceMainController:SetGuideStepShow(guideStepKey)
    local rt = self.guideRt[guideStepKey]
    if rt then
        rt.gameObject:SetActive(true)
    end
end

function UIBounceMainController:SetGuidePosition(key, position)
    local rt = self:GetGuideRt(key)
    if rt then
        rt.anchoredPosition = position
    end
end

function UIBounceMainController:CheckActivityOver()
    local closeTime = self._componentInfo.m_close_time
    local nowtime = self._svrTimeModule:GetServerTime() / 1000
    if nowtime > closeTime then
        self._campaignModule:ShowErrorToast(CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED, true)
        return true 
    end
    return false 
end