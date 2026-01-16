--[[
    回顾的活动上下文信息基类
    理想的情况是每次回顾1个活动只新增1个子类对象，不改动其他逻辑
]]
---@class UIReviewActivityBase:Object
_class("UIReviewActivityBase", Object)
UIReviewActivityBase = UIReviewActivityBase

---@param sample CampaignObj 活动对象，包含简易信息，可能为空，未解锁时服务器不下发CampaignObj
function UIReviewActivityBase:Constructor(id, obj, idx)
    self._id = id
    self._idx = idx
    self._camg_cfg = Cfg.cfg_campaign[self._id]
    if not self._camg_cfg then
        ReviewError("找不到回顾活动配置:", self._id)
    end
    self:UpdateCampaignObj(obj)
end

--region Set
---更新活动简易信息
function UIReviewActivityBase:UpdateCampaignObj(obj)
    ---@type CampaignObj
    self._campObj = obj
end
---@return UIActivityCampaign 请求活动详细信息，返回详细信息对象
function UIReviewActivityBase:ReqDetailInfo(TT, res)
    if not self:IsUnlock() then
        ReviewError("回顾活动没有解锁，不能获取详细信息")
    end
    -- local coms = self:ComponentList()
    --通用的活动对象
    self._campaign = UIActivityCampaign:New()
    if not res then
        res = AsyncRequestRes:New()
    end
    self._campaign:LoadCampaignInfo(TT, res, self:ActivityType())
    self._campaign:ReLoadCampaignInfo_Force(TT, res, self:ActivityType())
    if res:GetSucc() then
        return self._campaign
    else
        self._campaign = nil
        return nil
    end
end

function UIReviewActivityBase:ClearDetailInfo()
    self._campaign = nil --只在进入活动界面的时候需要详细信息，退出之后可以清空
end
--endregion

--region Get
---@return CampaignComType[] 返回该活动所有组件的数组，请求详细信息的时候用，每个活动必须重写此方法
-- function UIReviewActivityBase:ComponentList()
--     --已废弃
--     ReviewError(self._className .. "未重写ComponentList()方法：", debug.traceback())
-- end

---@return number 返回该活动下载的资源包id，对应工程中ActivityResConfig.asset文件中的配置
function UIReviewActivityBase:AssetPackageID()
    ReviewError(self._className .. "未重写AssetPackageID()方法：", debug.traceback())
end
--进入活动入口
function UIReviewActivityBase:ActivityOnOpen()
    ReviewError(self._className .. "未重写ActivityOnOpen()方法：", debug.traceback())
end
--获取退局参数，参考CampaignConst.GetCampaignUIStateParams()，活动回顾在子类中扩展而不是elseif
function UIReviewActivityBase:GetBattleExitParam(comID, missionCreateInfo, isWin, battleresultRt)
    ReviewError(self._className .. "未重写GetBattleExitParam()方法：", debug.traceback())
end

---@return number
function UIReviewActivityBase:ActivityID()
    return self._id
end
---@return number 索引
function UIReviewActivityBase:Index()
    return self._idx
end
---@return ECampaignType
function UIReviewActivityBase:ActivityType()
    if self:IsUnlock() then
        return self._campObj:GetSampleInfo().camp_type
    end
end
---@return string
function UIReviewActivityBase:Title()
    return StringTable.Get(self._camg_cfg.CampaignName)
end
---@return boolean 是否有红点
function UIReviewActivityBase:HasRedPoint()
     if self:IsUnlock() then
         return self._campObj:GetSampleInfo():GetStepStatus(ECampaignStep.CAMPAIGN_STEP_REWARD) --有未领取的进度奖励
     end
    return false
end
---@return boolean 是否可解锁但未解锁
function UIReviewActivityBase:CanUnlock()
    if self:IsUnlock() then
        return false --已经解锁了
    end
    if self:IsOpen() then --到开放时间
        local asset = self:UnlockCost()
        local have = GameGlobal.GetModule(ItemModule):GetItemCount(asset.assetid)
        return have >= asset.count
    end
    return false
end
---@return RoleAsset 解锁消耗，根据策划需求，只有1个
function UIReviewActivityBase:UnlockCost()
    local cfg = Cfg.cfg_campaign[self:ActivityID()]
    if cfg.CostItem == nil or #cfg.CostItem == 0 then
        ReviewError("回顾活动配置错误，必须有解锁消耗CostItem:", self:ActivityID())
    end
    local id = cfg.CostItem[1][1]
    local count = cfg.CostItem[1][2]
    return NewRoleAsset(id, count)
end
---@return boolean 返回true为已解锁
function UIReviewActivityBase:IsUnlock()
    return self._campObj ~= nil
end
---@return boolean 是否已下载资源
function UIReviewActivityBase:IsDownloaded()
    if EDITOR or not APPVER1110 then --编辑器和旧客户端不需要下载
        return true
    end
    return not HotUpdate.ActivityLuaProxy.HasDownloadList(self:AssetPackageID())
end
---@return boolean 是否已完成
---！！！注意:此方法不允许子类重写！！！
function UIReviewActivityBase:IsFinished()
    if self:IsUnlock() then
        return self:ProgressPercent() >= 100 and not self:HasRedPoint()
    end
    return false
end

---@return boolean 是否到达了开放时间
function UIReviewActivityBase:IsOpen()
    local openTime
    if self._campObj then
        openTime = self._campObj:GetSampleInfo().begin_time
    else
        openTime =
            GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(
            self._camg_cfg.BeginTime,
            Enum_DateTimeZoneType.E_ZoneType_GMT
        )
    end
    return openTime <= GetSvrTimeNow()
end

---@return number 进度百分比，0-100，整数，向下取整
---！！！注意:此方法不允许子类重写！！！
function UIReviewActivityBase:ProgressPercent()
    if self:IsUnlock() then
        return self._campObj:GetSampleInfo().m_extend_info[CampainExtendKey.E_CAMPAIGN_EXTEND_KEY_POINT_PROGRESS]
    end
    -- return -1
end
---@return UIActivityCampaign 获取详细信息
function UIReviewActivityBase:GetDetailInfo()
    return self._campaign
end

--开始下载
function UIReviewActivityBase:Download()
    local packageID = self:AssetPackageID()
    if HotUpdate.ActivityLuaProxy.IsDownloaderBusy() then
        local curID = HotUpdate.ActivityLuaProxy.CurrProcessingActivityID()
        if curID == packageID then
            ToastManager.ShowToast(StringTable.Get("str_review_tip1"))
        else
            ToastManager.ShowToast(StringTable.Get("str_review_tip2"))
        end
        return
    end
    HotUpdate.ActivityLuaProxy.AddListener(
        function(callbackType, activityId, unityActionCallBack)
            if
                callbackType == HotUpdate.ActivityDownloaderCallbackType.DownloadError or
                    callbackType == HotUpdate.ActivityDownloaderCallbackType.FatalError
             then --失败
                ToastManager.ShowToast(StringTable.Get("str_review_tip6"))
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UIReviewOnDownloadStateChanged, packageID)
                ReviewError("下载活动包失败：", packageID)
            elseif callbackType == HotUpdate.ActivityDownloaderCallbackType.Finish then --完成
                ToastManager.ShowToast(StringTable.Get("str_review_tip3", self:Title()))
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UIReviewOnDownloadStateChanged, packageID)
                Log.debug("下载活动包完成:", packageID)
            elseif callbackType == HotUpdate.ActivityDownloaderCallbackType.SpaceNotEnough then --磁盘不足
                ToastManager.ShowToast(StringTable.Get("str_review_tip4"))
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UIReviewOnDownloadStateChanged, packageID)
                ReviewError("下载活动包失败，磁盘空间不足:", packageID)
            elseif callbackType == HotUpdate.ActivityDownloaderCallbackType.NotUseWifi then --未使用wifi，只可能在下载开始时调用
                ToastManager.ShowToast(StringTable.Get("str_review_tip5"))
                Log.debug("使用4G下载活动包:", packageID)
                unityActionCallBack:DynamicInvoke(true)
            end
        end
    )
    Log.debug("开始下载活动资源包:", packageID)
    HotUpdate.ActivityLuaProxy.StartDownload(packageID)
end
function UIReviewActivityBase:IsDownLoading()
    return HotUpdate.ActivityLuaProxy.CurrProcessingActivityID() == self:AssetPackageID()
end
--下载进度0-1
function UIReviewActivityBase:DownloadProgress()
    if self:IsDownLoading() then
        return HotUpdate.ActivityLuaProxy.GetProgress()
    end
end
--资源包尺寸（字节数）
function UIReviewActivityBase:DownloadPackageSize()
    local size = HotUpdate.ActivityLuaProxy.GetTotalSize(self:AssetPackageID())
    return tonumber(size)
end
--已下载尺寸（字节数）
function UIReviewActivityBase:DownloadedSize()
    if self:IsDownLoading() then
        return HotUpdate.ActivityLuaProxy.GetDownloadedSize()
    end
end

--endregion
