---@class UIActivityCustomConst : Object
_class("UIActivityCustomConst", Object)
UIActivityCustomConst = UIActivityCustomConst

function UIActivityCustomConst:Constructor(campaignType, components)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type ECampaignType
    self._campaignType = campaignType
    self._componentTypes = components
    self._components = {}
    self._componentInfos = {}
    self._activeEndTime = 0
    self._plotId = nil
    self._localProcess = nil
    self._name = ""
    self._subName = ""
end

---@param res AsyncRequestRes
function UIActivityCustomConst:LoadData(TT, res)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self._campaignType, table.unpack(self._componentTypes))
    self._initSucc = false 
    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        res:SetSucc(false)
        return
    end

    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        res:SetSucc(false)
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    --战斗通行证
    local bpRes = AsyncRequestRes:New()
    bpRes:SetSucc(true)
    ---@type UIActivityCampaign
    self._battlepassCampaign = UIActivityCampaign:New()
    self._battlepassCampaign:LoadCampaignInfo(TT, bpRes, ECampaignType.CAMPAIGN_TYPE_BATTLEPASS)
    if not bpRes:GetSucc() then
        Log.info("获取战斗通行证数据失败")
    end

    --获取组件
    for k, v in pairs(self._componentTypes) do
        self._components[v] = self._localProcess:GetComponent(v)
        self._componentInfos[v] = self._localProcess:GetComponentInfo(v)
    end
    
    --配置
    local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    --标题数据
    self._name = StringTable.Get(cfg_campaign.CampaignName)
    self._subName = StringTable.Get(cfg_campaign.CampaignSubtitle)
    local plotIdList = cfg_campaign.FirstEnterStoryID
    self._plotId = nil
    if plotIdList and #plotIdList > 0 then
        self._plotId = plotIdList[1]
    end
    
    --活动结束时间
    local sample = self._campaign:GetSample()
    if not sample then
        return
    end

    local nowTime = self._timeModule:GetServerTime() / 1000
    --活动时间
    self._activeEndTime = sample.end_time
    self._initSucc = true 
    if nowTime > self._activeEndTime then
        Log.error("Time error!")
        return
    end
end

function UIActivityCustomConst:ForceUpdate(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

function UIActivityCustomConst:GetCampaign()
    return self._campaign
end

function UIActivityCustomConst:GetCampaignId()
    return self._campaign._id
end

--标题
function UIActivityCustomConst:GetName()
    return self._name
end

--副标题
function UIActivityCustomConst:GetSubName()
    return self._subName
end

--活动结束时间
function UIActivityCustomConst:GetActiveEndTime()
    return self._activeEndTime
end

--获取剧情id
function UIActivityCustomConst:GetPlotId()
    return self._plotId
end

function UIActivityCustomConst:PlayPlot()
    UIActivityHelper.PlayFirstPlot_Campaign(self._campaign)
end

--活动是否开启
function UIActivityCustomConst:IsActivityEnd()
    if not self._activeEndTime then
       return true 
    end
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(self._activeEndTime - nowTime)
    if seconds <= 0 then
        return true
    end
    return false
end

--获取组件
function UIActivityCustomConst:GetComponent(componentId)
    return self._components[componentId], self._componentInfos[componentId]
end

--获取组件状态
function UIActivityCustomConst:GetComponentStatus(componentId)
    if self:IsActivityEnd() then
        return ActivityComponentStatus.ActivityEnd, 0
    end
    return UIActivityCustomHelper.CheckComponentStatus(self._components[componentId])
end

--是否显示组件New
function UIActivityCustomConst:IsShowComponentNew(componentId)
    local status, time = self:GetComponentStatus(componentId)
    if status ~= ActivityComponentStatus.Open then
        return false
    end

    return UIActivityCustomHelper.GetNewFlagStatus("ACTIVITY_NEW" .. self._campaignType .. componentId)
end

--清除组件New
function UIActivityCustomConst:ClearComponentNew(componentId)
    UIActivityCustomHelper.SetNewFlagStatus("ACTIVITY_NEW" .. self._campaignType .. componentId)
end

--入口NEW
function UIActivityCustomConst:IsShowEntryNew(ignoreComponents)
    local enterNew = UIActivityCustomHelper.GetNewFlagStatus("ACTIVITY_ENTER_NEW" .. self._campaignType)
    if enterNew then
        return true 
    end
    
    for k, v in pairs(self._components) do
        local ignore = false
        if ignoreComponents then
            for i = 1, #ignoreComponents do
                if ignoreComponents[i] == k then
                    ignore = true
                    break
                end
            end
        end
        
        if ignore == false and self:IsShowComponentNew(k) then
            return true
        end
    end

    return false
end

--清除入口NEW
function UIActivityCustomConst:ClearEnterNew()
    UIActivityCustomHelper.SetNewFlagStatus("ACTIVITY_ENTER_NEW" .. self._campaignType, false)
end

--是否显示红点红点
function UIActivityCustomConst:IsShowComponentRed(componentId)
    local status, time = self:GetComponentStatus(componentId)
    if status ~= ActivityComponentStatus.Open then
        return false
    end
   
    return self._campaign:CheckComponentRed(componentId)
end

--战斗通行证红点
function UIActivityCustomConst:IsShowBattlePassRed()
    if self:IsActivityEnd() then
        return false
    end

    if self._battlepassCampaign then
        return UIActivityHelper.CheckCampaignSampleRedPoint(self._battlepassCampaign)
    end
    return false
end

--入口红点
function UIActivityCustomConst:IsShowEntryRed(ignoreComponents)
    if self:IsActivityEnd() then
        return false
    end

    for k, v in pairs(self._components) do
        local ignore = false
        if ignoreComponents then
            for i = 1, #ignoreComponents do
                if ignoreComponents[i] == k then
                    ignore = true
                    break
                end
            end
        end
        if ignore == false and self:IsShowComponentRed(k) then
            return true
        end
    end

    return false
end


function UIActivityCustomConst:GetInitState()
    return self._initSucc
end


