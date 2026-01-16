--[[

]]
---@class UIHauteCoutureData:Object
_class("UIHauteCoutureData", Object)
UIHauteCoutureData = UIHauteCoutureData

function UIHauteCoutureData:Constructor()
    self.hauteCouture = {
        [1038] = UIHauteCoutureKR, --卡戎
        [1041] = UIHauteCoutureBLH, --伯利恒
        [1048] = UIHauteCoutureQT, -- 青瞳
        [1114] = UIHauteCouturePLM, --普律玛
        ["END"] = nil
    }
    self.hauteCoutureReview = {
        [1040] = UIHauteCoutureKL_Review, --卡莲复刻
        [1086] = UIHauteCoutureGL_Review, --贡露复刻
        [1051] = UIHauteCoutureKR_Review, --卡戎复刻
        [1111] = UIHauteCoutureBLH_Review, --伯利恒复刻
        ["END"] = nil
    }

    ----------------------------------------------------------------------

    self:RefreshCurInfo()
end

---@return UIHauteCoutureDataBase 获取当前开放的高级时装数据，没有开放中的返回nil
function UIHauteCoutureData:GetCurHauteCouture()
    return self._curHauteCouture
end

---@return UIHauteCoutureDataBase 获取当前开放的高级时装复刻数据，没有开放中的返回nil
function UIHauteCoutureData:GetCurHauteCoutureReview()
    return self._curReviewHauteCouture
end

function UIHauteCoutureData:RefreshCurInfo()
    local module = GameGlobal.GetModule(CampaignModule)
    local campSample = module:GetSampleByType(ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN)
    if campSample then
        local id = campSample.id
        if not self._curHauteCouture or self._curHauteCouture:CampaignID() ~= id then
            if self.hauteCouture[id] then
                ---@type UIHauteCoutureDataBase
                self._curHauteCouture = self.hauteCouture[id]:New(id)
                Log.info("[HauteCouture] 更新高级时装数据:", id)
            else
                Log.exception("[HauteCouture] 高级时装活动未注册:", id)
            end
        else
            Log.info("[HauteCouture] 高级时装数据不用更新:", id)
        end
    else
        if self._curHauteCouture ~= nil then
            self._curHauteCouture = nil
            Log.info("[HauteCouture] 当前没有开放中的高级时装活动,将数据置空")
        end
        Log.info("[HauteCouture] 当前没有开放中的高级时装活动")
    end

    local campReviewSample = module:GetSampleByType(ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN_COPY)
    if campReviewSample then
        local id = campReviewSample.id
        if not self._curReviewHauteCouture or self._curReviewHauteCouture:CampaignID() ~= id then
            if self.hauteCoutureReview[id] then
                ---@type UIHauteCoutureDataBase
                self._curReviewHauteCouture = self.hauteCoutureReview[id]:New(id)
                Log.info("[HauteCouture] 更新高级时装复刻数据:", id)
            else
                Log.exception("[HauteCouture] 高级时装复刻活动未注册:", id)
            end
        else
            Log.info("[HauteCouture] 高级时装复刻数据不用更新:", id)
        end
    else
        if self._curReviewHauteCouture ~= nil then
            self._curReviewHauteCouture = nil
            Log.info("[HauteCouture] 当前没有开放中的高级复刻时装活动,将数据置空")
        end
        Log.info("[HauteCouture] 当前没有开放中的高级时装复刻活动")
    end
end
