---
---@class UISeasonObj:Object
_class("UISeasonObj", Object)
UISeasonObj = UISeasonObj

--- @param sample campaign_sample
--- @param obj CampaignObj
function UISeasonObj:Constructor(sample, obj)
    self._sample = sample
    self._campaignObj = obj
    self._seasonID = self._sample.id
    self._seasonType = self._sample.camp_type

    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    self._campaign_module = GameGlobal.GetModule(CampaignModule)

    ---@type SeasonMissionComponent
    self._missionCpt = self:GetComponent(ECCampaignSeasonComponentID.SEASON_MISSION)
end

--对应活动类型
function UISeasonObj:GetSeasonType()
    return self._seasonType
end

--对应活动id
function UISeasonObj:GetSeasonID()
    return self._seasonID
end

--取mission组件配置id
function UISeasonObj:GetSeasonMissionComponentCfgID()
    -- return 800107201
    return self._missionCpt:GetComponentCfgId()
end

function UISeasonObj:GetLocalProcess()
    local proccess = self._seasonModule:GetLocalProcess(self._seasonType, self._seasonID)
    return proccess
end

---@param cptID ECCampaignSeasonComponentID
function UISeasonObj:GetComponent(cptID)
    local proccess = self:GetLocalProcess()
    return proccess and proccess:GetComponent(cptID)
end

---@param cptID ECCampaignSeasonComponentID
function UISeasonObj:GetComponentInfo(cptID)
    local localProcess = self._seasonModule:GetLocalProcess(self._seasonType, self._seasonID)
    return localProcess and localProcess:GetComponentInfo(cptID)
end

function UISeasonObj:CheckComponentOpen(...)
    return self._campaign_module:CheckComponentOpen(self:GetLocalProcess(), ...)
end

function UISeasonObj:CheckErrorCode(result, refreshCallback, closeCallback)
    self._campaign_module:CheckErrorCode(result, self._id, refreshCallback, closeCallback)
end