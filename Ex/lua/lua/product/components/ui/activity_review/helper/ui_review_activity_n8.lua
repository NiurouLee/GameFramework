---n8活动 回顾信息
---@class UIReviewActivityN8:UIReviewActivityBase
_class("UIReviewActivityN8", UIReviewActivityBase)
UIReviewActivityN8 = UIReviewActivityN8

function UIReviewActivityN8:Constructor(id, sample) 

    local campaignModule = GameGlobal.GetModule(CampaignModule)
    self._n8Campaign = UIActivityCampaign:New()
    local res = AsyncRequestRes:New()
    TaskManager:GetInstance():StartTask(function(TT)
        self._n8Campaign:LoadCampaignInfo(
            TT,
            res,
            ECampaignType. CAMPAIGN_TYPE_REVIEW_N8,
            ECampaignReviewN8ComponentID.ECAMPAIGN_REVIEW_ReviewN8_LINE_MISSION
        )
        self._n8Campaign:ReLoadCampaignInfo_Force(TT, res)

        if res and not res:GetSucc() then
            Log.fatal("获取n8活动信息失败")
        end
    end, self)

end

function UIReviewActivityN8:AssetPackageID()
    return 8
end

function UIReviewActivityN8:ActivityOnOpen()
    ---@type UIActivityReview
    local controller = GameGlobal.UIStateManager():GetController("UIActivityReview")
    local rt = controller:GetShotImage()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    cache_rt.format = UnityEngine.RenderTextureFormat.RGB111110Float
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityN8MainController_Review, cache_rt)
        end
    )
end

-- function UIReviewActivityN8:ActivityOnOpen()
--     TaskManager:GetInstance():StartTask(self.OpenActivity, self)
-- end

-- function UIReviewActivityN8:OpenActivity(TT)
--     GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityN8MainController_Review)
-- end

function UIReviewActivityN8:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    if comID == ECampaignReviewN8ComponentID.ECAMPAIGN_REVIEW_ReviewN8_LINE_MISSION then
        return UIStateType.UIActivityN8LineMissionController_Review, nil
    end
end

---@return boolean 是否已完成
function UIReviewActivityN8:IsFinished()
    if self:IsUnlock() then
        ---@type LineMissionComponent
        local lineComp = self._n8Campaign:GetComponent(ECampaignReviewN8ComponentID.ECAMPAIGN_REVIEW_ReviewN8_LINE_MISSION)
        ---@type LineMissionComponentInfo
        local lineInfo = self._n8Campaign:GetComponentInfo(ECampaignReviewN8ComponentID.ECAMPAIGN_REVIEW_ReviewN8_LINE_MISSION)

        if not lineInfo then
            --活动未解锁 信息未下发
            return false
        end

        local cmpID = lineComp:GetComponentCfgId()
        local missionCfgs_temp = Cfg.cfg_component_line_mission { ComponentID = cmpID }

        --所有配置,以id为索引
        local missionCfgs = {}
        for _, cfg in pairs(missionCfgs_temp) do
            missionCfgs[cfg.CampaignMissionId] = cfg
        end

        for Id,v in pairs(missionCfgs) do
            if not lineInfo.m_pass_mission_info[Id] then
                return false
            end
        end
        return true
    else
        return false
    end
end

--[[
function UIReviewActivityN8:FinishLast(TT)
        ---@type CampaignModule
        local campModule = GameGlobal.GetModule(CampaignModule)
        local componentId_LineMission = 
        
        local res = AsyncRequestRes:New()
        ---@type UIActivityCampaign
        self._campaign = UIActivityCampaign:New()
        self._campaign:LoadCampaignInfo(TT, res,
            ECampaignType.CAMPAIGN_TYPE_REVIEW_N8,
            self._componentId_LineMission)

        self.campaign:ReLoadCampaignInfo_Force(TT, res)
    
        if res and res:GetSucc() then
            ---@type LineMissionComponent
            self._line_component = self.campaign:GetComponent(self._componentId_LineMission)
            --- @type LineMissionComponentInfo
            self._line_info = self._line_component:GetComponentInfo()

            local cmpID = self._line_component:GetComponentCfgId()
            local missionCfgs_temp = Cfg.cfg_component_line_mission { ComponentID = cmpID }
            --所有配置,以id为索引
            local missionCfgs = {}
            for _, cfg in pairs(missionCfgs_temp) do
                missionCfgs[cfg.CampaignMissionId] = cfg
            end
        
            for Id,v in pairs(missionCfgs) do
                if self._line_info.m_pass_mission_info[Id] then
                    self.allFinish = true
                else
                    self.allFinish = false
                end
            end
            return self.allFinish
        else
            self.allFinish = false
            --self._campModule:CheckErrorCode(res.m_result, self.campaign._id, nil, nil)
        end
end

]]