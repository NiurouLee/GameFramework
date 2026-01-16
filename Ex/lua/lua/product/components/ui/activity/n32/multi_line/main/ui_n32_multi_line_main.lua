---@class UIN32MultiLineMain : UIController
_class("UIN32MultiLineMain", UIController)
UIN32MultiLineMain = UIN32MultiLineMain

function UIN32MultiLineMain:Constructor()
    self.unlockFolderNum = 0
    self.bUnlockNewFoler = false
    self.bPassedAll = false;
    self.unlockCfgs = {}
    self.mCampaignModule = self:GetModule(CampaignModule)

    --已缓存的路点节点
    self.wayPointWidget={}
end


---@param res AsyncRequestRes
function UIN32MultiLineMain:LoadDataOnEnter(TT, res)
    local comType = ECampaignType.CAMPAIGN_TYPE_N32
    local comId = ECampaignN32ComponentID.ECAMPAIGN_N32_MULTILINE_MISSION

    self.multiLineData = UIMultiLineData:New()
    if not self.multiLineData:LoadData(TT, res, comType, comId) then
        self.mCampaignModule:CheckErrorCode(res.m_result, self.mCampaignModule._id, nil, nil)
        return
    end 
    self._component , self._comInfo = self.multiLineData:GetComponent()  
    res:SetSucc(true)
end

--初始化
function UIN32MultiLineMain:OnShow(uiParams)
    self._isMathch = uiParams[1] --战斗后返回
    local shotTexture = uiParams[2]
    self:Init()
    self:InitCommonWidget()
    self:CheckData()
    local playFolderUnlockAni = nil
    --从战斗依次解锁回来，需要判断是否解锁了新周目，用来播放动画
    if self._isMathch then
        if UIMultiLineData.lastPassFolderNum and UIMultiLineData.lastPassFolderNum > self:GetUnlockFolderNum() then
            playFolderUnlockAni = true
        end
    end
    self._shotTexture.gameObject:SetActive(shotTexture ~= nil)
    if shotTexture then
        self._shotTexture.texture = shotTexture
    end
    self:RefreshUI(playFolderUnlockAni)
    self:PlayEnterAni()
end

function UIN32MultiLineMain:OnHide()
    if self._shot then
        self._shot:CleanRenderTexture() 
     end
end

function UIN32MultiLineMain:PlayEnterAni()
    self:StartTask(function (TT)
        local lockName = "UIN32MultiLineMain_Ani"
        self:Lock(lockName)
        self.animation:Play("uieff_UIN32MultiLineMain_in")
        YIELD(TT, 1000)
        for i, widget in ipairs(self.wayPointWidget) do
            widget:CheckAndPlayUnReadEff()
        end
        YIELD(TT, 1633-1000)
        self:UnLock(lockName)
        self:_CheckGuide()
    end)
end

function UIN32MultiLineMain:PlayOutAni()
    self:StartTask(function (TT)
        local lockName = "UIN32MultiLineMain_Ani"
        self:Lock(lockName)
        self.animation:Play("uieff_UIN32MultiLineMain_clickout")
        YIELD(TT, 600)
        self:UnLock(lockName)
    end)
end

function UIN32MultiLineMain:PlayOutAniDirect()
    self.animation:Play("uieff_UIN32MultiLineMain_clickout")
end

function UIN32MultiLineMain:Init()
    self:InitCommonCfg()
end

function UIN32MultiLineMain:InitCommonCfg()
    self.commonCfg =
    {
        wayPointNum = 3,--路点数量
        passDesc = "str_n32_multiline_desc_pass",--通关描述
        passBgSpine = "shuijingqiubai_n31_spine_idle"--通关后spine
    }
end

function UIN32MultiLineMain:GetNodeWigetName()
    return "UIN32MultiLineMainNode"
end

--获取ui组件
function UIN32MultiLineMain:InitCommonWidget()
    ---@type SpineLoader
    self.spineLoader = self:GetUIComponent("SpineLoader", "spineLoader")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    ---@type UICustomWidgetPool
    self.backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self.animation = self:GetUIComponent("Animation", "animation")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    self._shotTexture = self:GetUIComponent("RawImage", "shotImage")

    --Init way point and lines
    self.wayPointPools = {}
    self.lineGoes={}
    local wayPointCount = self.commonCfg.wayPointNum
    for i = 1,wayPointCount, 1 do
        local wayPointPool = self:GetUIComponent("UISelectObjectPath", "m"..i)
        local lineGo = self:GetGameObject("line"..i)
        lineGo:SetActive(false)

        table.insert(self.wayPointPools, wayPointPool)
        table.insert(self.lineGoes, lineGo)
    end

    --topButton
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            if self:CheckComponentTime() then
                self.mCampaignModule:CampaignSwitchState(
                    true,
                    UIStateType.UIActivityN32MainController,
                    UIStateType.UIMain,
                    nil,
                    self.multiLineData:GetCampaignId()
                )
            end
        end,
        function ()
            if self:CheckComponentTime() then
                self:ShowDialog("UIIntroLoader", "UIN32MultilineMainIntro")
            end
        end,
        nil,
        true
    )
end

function UIN32MultiLineMain:GetWayPointPool(index)
    return self.wayPointPools[index]
end

function UIN32MultiLineMain:GetLinePoint(index)
    return self.lineGoes[index]
end

--按钮点击
function UIN32MultiLineMain:BtnReviewOnClick(go)
    if  not self:CheckComponentTime() then
        return
    end
    local firstStoryId = self._comInfo.m_first_story_id
    if not firstStoryId or firstStoryId < 1 then
        Log.error("UIN32MultiLineMain 未配置firstStoryId")
        return
    end
    self:ShowDialog("UIStoryController", firstStoryId)
end

--按钮点击
function UIN32MultiLineMain:SpineBtnOnClick(go)
end


--子类指定脚本
function UIN32MultiLineMain:GetNodeWigetName()
    return "UIN32MultiLineMainNode"
end


--检查目录数据
--已解锁配置表，是否有新解锁内容，是否全部解锁，是否全部都通关
function UIN32MultiLineMain:CheckData()
    if self.bPassedAll then --上次检查到已经全部通关，就不用再次检查
        self.bUnlockNewFoler = false
        return
    end

    local cfgs = self.multiLineData:GetMultiLineFolderCfgs()
    if self.commonCfg.wayPointNum ~= #cfgs then
        Log.error("err cfg_component_multiline_mission_main 配置表中的数量 是: ".. #cfgs .. "controlle wayPointNum 是 " .. self.commonCfg.wayPointNum )
    end
        
    table.clear(self.unlockCfgs)
    for k, subCfg in ipairs(cfgs) do
        if(self.multiLineData:IsMultiLineFolderUnlock(subCfg)) then
            table.insert(self.unlockCfgs, subCfg)
        else
            break
        end
    end

    self.unlockFolderNum =  #self.unlockCfgs
    self.bPassedAll = false;
    if self.unlockFolderNum == #cfgs then
        local lastCfg = cfgs[self.unlockFolderNum]
        local levels = lastCfg.MainMission
        local lasLevel = levels[#levels]
        local cfgLevel = Cfg.cfg_component_multiline_mission[lasLevel]

        self.bPassedAll = self.multiLineData:GetPassMissionInfo(cfgLevel.MissionID) ~= nil 
    end
end

function UIN32MultiLineMain:GetUnlockFolderNum()
    return self.unlockFolderNum
end

function UIN32MultiLineMain:GetUnlockCfgs()
    return self.unlockCfgs
end

function UIN32MultiLineMain:IsUnlockNewFoler()
    return self.bUnlockNewFoler
end

function UIN32MultiLineMain:IsPassedAll()
    return self.bPassedAll
end

function UIN32MultiLineMain:RefreshUI(playFolderUnlockAni)
    self:RefreshDescAndBgSpine()
    self:RefreshNodeAndLines()
end

function UIN32MultiLineMain:RefreshDescAndBgSpine()
    if self.bPassedAll then
        self.txtDesc:SetText(StringTable.Get(self.commonCfg.passDesc))
        self.spineLoader:LoadSpine(self.commonCfg.passBgSpine)
    else
        local lastCfg = self.unlockCfgs[self.unlockFolderNum]

        self.txtDesc:SetText(StringTable.Get(lastCfg.Desc))
        self.spineLoader:LoadSpine(lastCfg.BgSpine)
    end
end

function UIN32MultiLineMain:RefreshNodeAndLines()
    for i = 1, self.commonCfg.wayPointNum, 1 do
        if i <= self.unlockFolderNum then
            local cfg = self.unlockCfgs[i]
            local isRead = self.multiLineData:IsForlderHasRead(cfg.ID)
            --已解锁

            --线
            self.lineGoes[i]:SetActive(true)
            self:SetLineState(self.lineGoes[i], isRead)

            --路点
            if self.wayPointWidget[i] then
                --已经缓存过，直接刷新
                self.wayPointWidget[i]:SetData(i, cfg, self.multiLineData, isRead)
            else
                local pool = self.wayPointPools[i]
                local newWidge = pool:SpawnObject(self:GetNodeWigetName())
                table.insert(self.wayPointWidget, newWidge)
                newWidge:SetData(i, cfg, self.multiLineData, isRead)
            end
        end
    end
end      

function UIN32MultiLineMain:SetLineState(go, isRead)
    local readGo = go.transform:Find("read")
    local unReadGo = go.transform:Find("unRead")
    readGo.gameObject:SetActive(isRead)
    unReadGo.gameObject:SetActive(not isRead)
end

function UIN32MultiLineMain:CheckComponentTime()
    if self.multiLineData:IsComponentTimeEnd() then
        self.mCampaignModule:CampaignSwitchState(
                true,
                UIStateType.UIActivityN32MainController,
                UIStateType.UIMain,
                nil,
                self.multiLineData:GetCampaignId()
            )
        
        ToastManager.ShowToast(StringTable.Get("str_activity_error_107"))
        return false
    end
    return true
end

function UIN32MultiLineMain:GetRenderTexture(callback)
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local rt = self._shot:RefreshBlurTexture()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float
    self:StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            if callback then
                callback(cache_rt)
            end
        end
    )
end

function UIN32MultiLineMain:GetName()
    return "UIN32MultiLineMain"
end

function UIN32MultiLineMain:GetFirstFolderBtn()
    return self.wayPointWidget[1]:GetBtn()
end

function UIN32MultiLineMain:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN32MultiLineMain)
end