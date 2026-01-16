--region UIActivityCampaign 活动中的 Campaign 帮助类
---@class UIActivityCampaign:Object
_class("UIActivityCampaign", Object)
UIActivityCampaign = UIActivityCampaign

function UIActivityCampaign:Constructor()
    self._campaign_module = GameGlobal.GetModule(CampaignModule)
    self._campaign_manager = self._campaign_module.m_campaign_manager

    self._type = -1
    self._id = -1
end

-----------------------------------------------------------------
--region Load
-- 加载活动数据
-- 通过活动类型得到活动id，如果已有活动信息，不会向服务器请求
function UIActivityCampaign:LoadCampaignInfo(TT, res, campaignType, ...)
    self._type = campaignType
    self._id = self._campaign_module:GetCampaignInfo(TT, res, campaignType, ...)
end

-- 加载活动数据
-- 通过活动类型得到活动id，使用本地已获取的数据，不会向服务器请求
function UIActivityCampaign:LoadCampaignInfo_Local(campaignType, ...)
    self._type = campaignType
    self._id = self._campaign_module:GetCampaignInfo_Local(campaignType, ...)
end

-- 加载活动数据
-- 指定活动ID
function UIActivityCampaign:LoadCampaignInfo_Id(TT, res, campaignId, ...)
    self._id = campaignId
    self:ReLoadCampaignInfo_Force(TT, res)
end

-- 加载活动数据
-- 指定活动ID
function UIActivityCampaign:LoadCampaignInfo_Id_Local(campaignId)
    self._id = campaignId

    ---@type campaign_sample
    local sample = self:GetSample()
    if not sample then
        return
    end

    self._type = sample.camp_type
end

-- 强制加载活动数据
-- 通过活动id，向服务器请求活动数据
function UIActivityCampaign:ReLoadCampaignInfo_Force(TT, res)
    local lockName = "UIActivityCampaign:ReLoadCampaignInfo_Force() id = " .. self._id
    GameGlobal.UIStateManager():Lock(lockName)

    self._campaign_module:CampaignComProtoLoadInfo(TT, res, self._id)

    GameGlobal.UIStateManager():UnLock(lockName)

    if res and res:GetSucc() then
        --- @type CampaignObj
        local obj = self._campaign_manager:GetCampaignObj(self._id)

        -- 通过活动ID拉取数据时，得到活动Type
        ---@type campaign_sample
        local sample = self:GetSample()
        if not sample then
            return
        end

        self._type = sample.camp_type

        local localProcess = self:GetLocalProcess()
        localProcess:InitComponent(obj)
    end
end

--endregion

-----------------------------------------------------------------
--region Get
function UIActivityCampaign:GetLocalProcess()
    return self._campaign_module:GetCampaignLocalProcessByCampaignId_Local(self._type, self._id)
end

-- 获取活动 sample
---@return campaign_sample
function UIActivityCampaign:GetSample()
    if not self._campaign_manager then
        return nil
    end
    
    if self._id ~= -1 then
        return self._campaign_manager:GetSampleByID(self._id)
    end

    return self._sample or self._campaign_manager:GetSampleByType(self._type)
end

-- 获取组件
function UIActivityCampaign:GetComponent(componentId)
    local localProcess = self:GetLocalProcess()
    return localProcess and localProcess:GetComponent(componentId)
end

-- 获取组件信息
function UIActivityCampaign:GetComponentInfo(componentId)
    local localProcess = self:GetLocalProcess()
    return localProcess and localProcess:GetComponentInfo(componentId)
end

--获得活动类型
function UIActivityCampaign:GetCampaignType()
    return self._type
end

--endregion

-----------------------------------------------------------------
--region get component
function UIActivityCampaign:_GetComponentIdByType(type, idx)
    if not self._componentDict then
        local tb = {}
        local i = 1
        while true do
            local component = self:GetComponent(i)
            if component == nil then
                break
            end
            ---@type CampaignComType
            local type = component:GetComponentType()
            if not tb[type] then
                tb[type] = {}
            end
            table.insert(tb[type], i)
            i = i + 1
        end
        self._componentDict = tb
    end

    idx = idx or 1
    return self._componentDict[type] and self._componentDict[type][idx]
end

-- 通过组件类型和定义顺序来获得组件
function UIActivityCampaign:GetComponentByType(type, idx)
    return self:GetComponent(self:_GetComponentIdByType(type, idx))
end

-- 通过组件类型和定义顺序来获得组件信息
function UIActivityCampaign:GetComponentInfoByType(type, idx)
    return self:GetComponentInfo(self:_GetComponentIdByType(type, idx))
end

--endregion

-----------------------------------------------------------------
--region help

function UIActivityCampaign:OpenMainUI(useStateUI)
    local cfg = Cfg.cfg_campaign[self._id]
    local uiName = cfg and cfg.MainUI
    if string.isnullorempty(uiName) then
        Log.error("UIActivityCampaign:OpenMainUI() uiName == nil")
    else
        if useStateUI then
            GameGlobal.UIStateManager():SwitchState(uiName)
        else
            GameGlobal.UIStateManager():ShowDialog(uiName)
        end
    end
end

-- 检查活动是否开启
function UIActivityCampaign:CheckCampaignOpen()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = svrTimeModule and math.floor(svrTimeModule:GetServerTime() * 0.001) or 0

    ---@type campaign_sample
    local sample = self:GetSample()
    return sample and sample:IsShow(curTime) or false
end

-- 检查活动 Sample 中的 red 信息
function UIActivityCampaign:CheckCampaignRed()
    ---@type campaign_sample
    local sample = self:GetSample()
    return sample and sample:GetStepStatus(ECampaignStep.CAMPAIGN_STEP_REWARD)
end

-- 检查活动 Sample 中的 new 信息
function UIActivityCampaign:CheckCampaignNew()
    ---@type campaign_sample
    local sample = self:GetSample()
    return sample and sample:GetStepStatus(ECampaignStep.CAMPAIGN_STEP_NEW)
end

-- 清除活动 Sample 中的 new 信息
function UIActivityCampaign:ClearCampaignNew(TT)
    if self:CheckCampaignNew() then
        local res = AsyncRequestRes:New()
        self._campaign_module:CampaignClearNewFlag(TT, res, self._id)
        Log.info("UIActivityCampaign:ClearCampaignNew() CampaignClearNewFlag res.m_result = ", res.m_result)
    end
end

-- 检查活动组件是否开放
function UIActivityCampaign:CheckComponentOpen(...)
    return self._campaign_module:CheckComponentOpen(self:GetLocalProcess(), ...)
end

-- 检查活动组件的 red 信息
function UIActivityCampaign:CheckComponentRed(...)
    return self._campaign_module:CheckComponentRed(self:GetLocalProcess(), ...)
end

--endregion


--region error help

function UIActivityCampaign:ShowErrorToast(result, hideErrorId)
    self._campaign_module:ShowErrorToast(result, hideErrorId)
end

function UIActivityCampaign:CheckErrorCode(result, refreshCallback, closeCallback)
    self._campaign_module:CheckErrorCode(result, self._id, refreshCallback, closeCallback)
end

-- 检查活动Sample关闭，根据时间计算错误码，发送事件
function UIActivityCampaign:CheckCampaignClose_ShowClientError()
    if not self:CheckCampaignOpen() then
        local result = self:_GetClientError_Campaign()
        self:CheckErrorCode(result)
        return true
    end
    return false
end

-- 检查活动组件关闭，根据时间计算错误码，发送事件
function UIActivityCampaign:CheckComponentClose_ShowClientError(...)
    if not self:CheckComponentOpen(...) then
        local result = self:_GetClientError_Component(...)
        self:CheckErrorCode(result)
        return true
    end
    return false
end

function UIActivityCampaign:_GetClientError_Campaign()
    ---@type campaign_sample
    local sample = self:GetSample()
    if sample then
        return UIActivityCampaign._CalcClientError(sample.begin_time, sample.end_time)
    end
    return CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
end

function UIActivityCampaign:_GetClientError_Component(...)
    local succ = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS

    local result = nil

    local args = {...}
    for _, v in pairs(args) do
        local componentInfo = self:GetComponentInfo(v)
        if componentInfo then
            local openTime = componentInfo.m_unlock_time
            local closeTime = componentInfo.m_close_time

            result = UIActivityCampaign._CalcClientError(openTime, closeTime)

            if result ~= succ then
                return result
            end
        else
            result = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_ID_ERROR -- 组件ID错误
            Log.error("UIActivityCampaign:CheckComponentOpenClientError() id = ", v, ", result = ", result)
            return result
        end
    end
    return succ -- 成功
end

function UIActivityCampaign._CalcClientError(openTime, closeTime)
    local curTime = GameGlobal.GetModule(SvrTimeModule):GetServerTime() / 1000
    local result = nil

    --不在开放时段内
    result = (curTime < openTime) and CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN or result -- 活动未开启
    result = (curTime > closeTime) and CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED or result -- 活动已结束

    if result then
        local s = "UIActivityCampaign_CalcClientError() curTime=%s, openTime=%s, closeTime=%s, result=%s"
        local str = string.format(s, curTime, openTime, closeTime, result)
        Log.info(str)
        return result
    end

    return CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS -- 成功
end

-- 不推荐继续使用的接口
function UIActivityCampaign:CheckComponentOpenClientError(...)
    return self:_GetClientError_Component(...)
end

--endregion