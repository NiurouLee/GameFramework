--[[
    活动回顾帮助类
]]
---@class UIActivityReviewData:Object
_class("UIActivityReviewData", Object)
UIActivityReviewData = UIActivityReviewData

function UIActivityReviewData:Constructor()
    local roleModule = GameGlobal.GetModule(RoleModule)
    self._isReviewLocked = not roleModule:CheckModuleUnlock(GameModuleID.MD_CAMPAIGNREVIEW)
    if self._isReviewLocked then
        return
    end
    self._camModule = GameGlobal.GetModule(CampaignModule)

    ---@type table<number,CampaignObj>
    self._allCampaignObjs = self._camModule:GetAllReviewCampaignSample()

    ---@type UIReviewActivityBase[]
    self._reviewActivities = {}
    --每新增1个活动加1行
    self:RegisterActivity(19001, UIReviewActivityN1)
    self:RegisterActivity(19002, UIReviewActivityN2)
    self:RegisterActivity(19003, UIReviewActivityN3)
    self:RegisterActivity(19004, UIReviewActivityN4)
    self:RegisterActivity(19005, UIReviewActivityN5)
    self:RegisterActivity(19006, UIReviewActivityN6)
    self:RegisterActivity(19007, UIReviewActivityN7)
    self:RegisterActivity(19008, UIReviewActivityN8)
    self:RegisterActivity(19009, UIReviewActivityN9)
    self:RegisterActivity(19011, UIReviewActivityN11)
    self:RegisterActivity(19012, UIReviewActivityN12)
    self:RegisterActivity(19013, UIReviewActivityN13)
    self:RegisterActivity(19014, UIReviewActivityN14)
    self:RegisterActivity(19015, UIReviewActivityN15)
    self:RegisterActivity(19016, UIReviewActivityN16)
end

function UIActivityReviewData:RegisterActivity(id, type)
    ---@type UIReviewActivityBase
    local instance = _createInstance(type._className, id, self._allCampaignObjs[id], #self._reviewActivities + 1)
    table.insert(self._reviewActivities, instance)
end

---@return boolean 返回true为锁定
function UIActivityReviewData:IsLocked()
    return self._isReviewLocked
end
---@return boolean 是否有可解锁的活动
function UIActivityReviewData:HasUnlockableItem()
    if self:IsLocked() then
        return false
    end
    for index, activity in ipairs(self._reviewActivities) do
        if activity:CanUnlock() then
            return true
        end
    end
    return false
end
---@return boolean 是否有可领取奖励的活动
function UIActivityReviewData:HasCollectableItem()
    if self:IsLocked() then
        return false
    end
    for index, activity in ipairs(self._reviewActivities) do
        if activity:HasRedPoint() then
            return true
        end
    end
    return false
end
---@return UIReviewActivityBase[]
function UIActivityReviewData:GetListAll()
    return self._reviewActivities
end

---@return UIReviewActivityBase[] 获取所有已开放的活动
function UIActivityReviewData:GetAllOpenedList()
    if self:IsLocked() then
        return nil
    end
    local list = {}
    for index, value in ipairs(self._reviewActivities) do
        if value:IsOpen() then
            table.insert(list, value)
        end
    end
    return list
end

function UIActivityReviewData:GetBattleExitParam(campType, comID, missionCreateInfo, isWin, battleresultRt)
    if self:IsLocked() then
        return nil
    end
    for index, value in ipairs(self._reviewActivities) do
        if value:ActivityType() == campType then
            return value:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
        end
    end
end

---@param data UIReviewActivityBase
function UIActivityReviewData:OnActivityUnlock(data)
    self._allCampaignObjs = self._camModule:GetAllReviewCampaignSample()
    local obj = self._allCampaignObjs[data:ActivityID()]
    if not obj then
        ReviewError("活动解锁成功，但module中获取不到活动Obj：", data:ActivityID())
    end
    data:UpdateCampaignObj(obj)
end

---@param type ECampaignType
---@return UIReviewActivityBase
function UIActivityReviewData:GetActivityByType(type)
    if self:IsLocked() then
        return nil
    end
    for index, value in ipairs(self._reviewActivities) do
        if value:ActivityType() == type then
            return value
        end
    end
end

function UIActivityReviewData:ContainsID(campID)
    if self:IsLocked() then
        return false
    end
    for index, value in ipairs(self._reviewActivities) do
        if value:ActivityID() == campID then
            return true
        end
    end
    return false
end
------------------------------------------------------------------------------------
function ReviewError(...)
    if EDITOR then
        Log.exception("[Review] ", ...)
    else
        Log.error("[Review] ", ...)
    end
end

---@return RoleAsset
function NewRoleAsset(id, count)
    local asset = RoleAsset:New()
    asset.assetid = id
    asset.count = count
    return asset
end
