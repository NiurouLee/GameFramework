--N25 入口按钮小游戏偶像养成
---@class UIN25EntryBtnIdol : UIN25EntryBtnBase
_class("UIN25EntryBtnIdol", UIN25EntryBtnBase)
UIN25EntryBtnIdol = UIN25EntryBtnIdol

--初始化
function UIN25EntryBtnIdol:OnShow(uiParams)
    self:InitWidget()
    self.stageCount = 0 --阶段数量
    self.secondsPerDay = 24*60*60
end
function UIN25EntryBtnIdol:OnHide()
    self:CancelTimeEvent()
end

---@param activityConst UIActivityN25Const 
function UIN25EntryBtnIdol:RefreshState(activityConst)
    self.activityConst = activityConst
    self:RefreshStageCount()
    self:RefreshStateInternal()
    self:CancelTimeEvent()

     -- 开启倒计时
     self._timeEvent = UIActivityHelper.StartTimerEvent(
        self._timeEvent,
        function()
            self:RefreshStateInternal()
        end
    )
end

--刷新阶段数量
function UIN25EntryBtnIdol:RefreshStageCount()
    self.stageCount = 1
    local c, cInfo  = self.activityConst:GetIdolComponent()
    if nil == cInfo then
        return
    end
    local cId = cInfo.m_campaign_id * 100000 + cInfo.m_component_type * 100 + cInfo.m_component_id
    local cfgs = Cfg.cfg_component_idol_round{ComponentID = cId}
    for k, v in pairs(cfgs) do
        if v.UnlockTime and v.UnlockTime > self.stageCount then
            self.stageCount = v.UnlockTime
        end
    end
end

function UIN25EntryBtnIdol:RefreshStateInternal()
    local idol_open_state = 0
    local idol_open_state_key = "UIN15IdolOpenStateKey"

    local c, cInfo  = self.activityConst:GetIdolComponent()
    if nil == cInfo then
        return
    end
    local new = self.activityConst:CheckGameIdolNew()
    local red = self.activityConst:CheckGameIdolRed()
    self:SetLock(true)
   
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    local unlockTime = cInfo.m_unlock_time
    local closeTime = cInfo.m_close_time
    local state = self.activityConst:GetStateGameIdol()
    if state == UISummerOneEnterBtnState.NotOpen then
        local unlockTime = cInfo.m_unlock_time
        local seconds = math.floor((unlockTime - nowTimestamp))
        -- local seconds = UICommonHelper.CalcLeftSeconds(closeTime)
        local timeStr = UIActivityN25Const.GetTimeString(seconds)
        local timeTips = StringTable.Get("str_n25_activity_remain_open_time", timeStr)
        self:SetLeftTime(timeTips)
    elseif state == UISummerOneEnterBtnState.Normal then
        self:SetLock(false)
        local nowTimestamp = UICommonHelper.GetNowTimestamp()
        local curStage = math.floor((nowTimestamp - unlockTime)/self.secondsPerDay)  + 1 
        local timeTips = nil

        --qa MSG54070	（QA_卢晨阳）N25偶像小游戏入口QA	5	QA-开发制作中	李学森, 1958	12/05/2022	
        --如果是第一阶段
        if curStage <= 1 then
            -- 1
            idol_open_state = 1
        elseif curStage <= 2 then
            -- 2
            idol_open_state = 2
        else
            -- 3
            idol_open_state = 3
        end
        local val = LocalDB.GetInt(idol_open_state_key,0)
        if not red then
            if idol_open_state == 1 then
                --曹芸鸣 12-5 14:45:47
                --一阶段和活动一起开的
                --曹芸鸣 12-5 14:45:48
                --哥哥
            elseif idol_open_state == 2 then
                red = (idol_open_state~=val)
            else
                red = (idol_open_state~=val)
            end
        end

        local timeGo = self:GetGameObject("leftTime")
        local showTime = false
        if idol_open_state == 3 then
            --三阶段开启后	无关玩家行为	下方不显示倒计时，啥也不显示

        else
            if idol_open_state~=val then
                -- 在n开启至n+1开启期间	玩家未点击进入	下方不显示倒计时，啥也不显示

            else
                if idol_open_state == 1 then
                    -- 1阶段开启 2、3阶段未开启状态	玩家在这个期间点进去了 下方显示二阶段倒计时多语言1
                    showTime = true
                elseif idol_open_state == 2 then
                    -- 2阶段开启 3阶段未开启状态 玩家在这个期间点进去了	下方显示3阶段倒计时多语言1
                    showTime = true
                end
            end
        end
        timeGo:SetActive(showTime)
        if showTime then
            local seconds = math.floor( unlockTime + curStage * self.secondsPerDay - nowTimestamp)
            local timeStr = UIActivityN25Const.GetTimeString(seconds)
            timeTips = StringTable.Get("str_n25_activity_next_open", timeStr)
        end

        --old
        -- if curStage >= self.stageCount then
        --     --最后一个阶段
        --     local seconds = UICommonHelper.CalcLeftSeconds(closeTime)
        --     local timeStr = UIActivityN25Const.GetTimeString(seconds)
        --     timeTips = StringTable.Get("str_n25_activity_remain_time", timeStr)
        -- else
        --     local seconds = math.floor( unlockTime + curStage * self.secondsPerDay - nowTimestamp)
        --     local timeStr = UIActivityN25Const.GetTimeString(seconds)
        --     timeTips = StringTable.Get("str_n25_activity_next_open", timeStr)
        -- end
        
        self:SetLeftTime(timeTips)
    elseif state == UISummerOneEnterBtnState.Closed then
        self:SetLeftTime(StringTable.Get("str_n25_activity_end"))
        self:CancelTimeEvent()
    end
    self:SetNewAndRed(new, red)
end

function UIN25EntryBtnIdol:CancelTimeEvent()
    self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end