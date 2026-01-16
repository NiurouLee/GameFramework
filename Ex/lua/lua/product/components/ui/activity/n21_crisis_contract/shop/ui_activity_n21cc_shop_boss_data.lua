
_class("UIActivityN21CCShopBossData", Object)
---@class UIActivityN21CCShopBossData:Object
UIActivityN21CCShopBossData = UIActivityN21CCShopBossData

---@param progressComponent PersonProgressComponent
---@param progressComponentInfo PersonProgressComponentInfo
function UIActivityN21CCShopBossData:Constructor(progressComponent, progressComponentInfo)
    ---@type PersonProgressComponent
    self._progressComponent = progressComponent
    self._rewardDatas = {}
    local progressRewards = progressComponentInfo.m_progress_rewards -- <进度，奖励> map<int64,list<RoleAsset>>
    local currentProgress = progressComponentInfo.m_current_progress -- 当前进度 int64
    local receivedProgress = progressComponentInfo.m_received_progress -- 已经领取奖励的进度 list<int64>
    for k, v in pairs(progressRewards) do
        local progress = k
        local rewards = v
        local status = UIActivityN21CCShopRewardStatus.UnComplete
        if currentProgress >= progress then
            status = UIActivityN21CCShopRewardStatus.UnGet
            for i = 1, #receivedProgress do
                if progress == receivedProgress[i] then
                    status = UIActivityN21CCShopRewardStatus.HasGet
                    break
                end
            end
        end
        self._rewardDatas[#self._rewardDatas + 1] = UIActivityN21CCShopItemData:New(progress, status, rewards, self._progressComponent)
    end
    self._totalScore = currentProgress
    self._isOpen = progressComponent:ComponentIsOpen()
    local componentId = progressComponent:GetComponentCfgId()
    local cfg = Cfg.cfg_activity_person_progress_client[componentId]
    if cfg then
        self._tabName = StringTable.Get(cfg.Name)
        self._tabIcon = cfg.SmallIcon
        self._topIcon = cfg.BigIcon
        self._missionIds = cfg.MissionIds
    end
    self:Refresh()
end

function UIActivityN21CCShopBossData:GetProgressComponent()
    return self._progressComponent
end

function UIActivityN21CCShopBossData:Refresh()
    table.sort(self._rewardDatas, function(a, b)
        return a:GetPriority() < b:GetPriority()        
    end)
end

function UIActivityN21CCShopBossData:GetRewardDatas()
    return self._rewardDatas
end

function UIActivityN21CCShopBossData:GetTotalScore()
    return self._totalScore
end

function UIActivityN21CCShopBossData:HasCanGetReward()
    if not self:IsOpen() then
        return false
    end
    for i = 1, #self._rewardDatas do
        ---@type UIActivityN21CCShopItemData
        local rewardData = self._rewardDatas[i]
        if rewardData:GetStatus() == UIActivityN21CCShopRewardStatus.UnGet then
            return true
        end
    end
    return false
end

function UIActivityN21CCShopBossData:GetAllRewards()
    for i = 1, #self._rewardDatas do
        ---@type UIActivityN21CCShopItemData
        local rewardData = self._rewardDatas[i]
        if rewardData:GetStatus() == UIActivityN21CCShopRewardStatus.UnGet then
            rewardData:SetStatus(UIActivityN21CCShopRewardStatus.HasGet)
        end
    end
end

function UIActivityN21CCShopBossData:IsOpen()
    return self._isOpen
end

function UIActivityN21CCShopBossData:IsMission(missionId)
    if not self._missionIds then
        return false
    end
    for i = 1, #self._missionIds do
        if missionId == self._missionIds[i] then
            return true
        end
    end
    return false
end

function UIActivityN21CCShopBossData:GetBossName()
    return self._tabName
end

function UIActivityN21CCShopBossData:GetBossSmallIcon()
    return self._tabIcon
end

function UIActivityN21CCShopBossData:GetBossBigIcon()
    return self._topIcon
end
