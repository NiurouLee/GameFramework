--[[
    活动数据加载类 通用活动
]]

require("ui_activity_data_loader_base")

---@class UIActivityDataLoader_Campaign:UIActivityDataLoaderBase
_class("UIActivityDataLoader_Campaign", UIActivityDataLoaderBase)
UIActivityDataLoader_Campaign = UIActivityDataLoader_Campaign


function UIActivityDataLoader_Campaign:SetData(params)
    self._campaignType = params and params.campaign_type
    self._componentIds = params and params.component_ids or {}
    self._campaignId = params and params.campaign_id
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityDataLoader_Campaign:LoadData(TT, res)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    if not self._campaignId then
        self._campaign:LoadCampaignInfo(TT, res, self._campaignType, table.unpack(self._componentIds))
    else
        self._campaign:LoadCampaignInfo_Id(TT, res, self._campaignId, table.unpack(self._componentIds))
    end

    -- 活动已开启，检查组件是否开启
    -- if res and res:GetSucc() then
    --     if not self._campaign:CheckComponentOpen(table.unpack(self._componentIds)) then
    --         res.m_result = self._campaign:CheckComponentOpenClientError(table.unpack(self._componentIds))
    --     end
    -- end

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
    end

    return self._campaign
end
