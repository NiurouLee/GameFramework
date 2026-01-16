--[[
    活动辅助类
]]
---@class UIN25IdolGameHelper:Object
_class("UIN25IdolGameHelper", Object)
UIN25IdolGameHelper = UIN25IdolGameHelper

-- 偶像游戏界面状态
--- @class IdolGameState
local IdolGameState = {
    None = 0, --初始化
    Begin = 1, --回合开始
    Train = 2, --训练
    Agreed = 3, --约定事件
    Weekend = 4, --周末偶像活动强弹
    Concert = 5, --演唱会
    TurnEnd = 6 --回合结束
}
_enum("IdolGameState", IdolGameState)

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState(component, forceActOpened,froceConcertOpened,callback)
    local breakInfo = component.m_component_info.break_info
    local roundState = breakInfo.round_state

    ---@type IdolGameState
    local state
    local req
    if roundState == IdolRoundState.IdolRoundState_None then
        req = UIN25IdolGameHelper.CheckState_None(component)
        state = IdolGameState.None
    elseif roundState == IdolRoundState.IdolRoundState_Begin then
        UIN25IdolGameHelper.CheckState_Begin(component)
        state = IdolGameState.Begin
    elseif roundState == IdolRoundState.IdolRoundState_Play then
        UIN25IdolGameHelper.CheckState_Train(component)
        state = IdolGameState.Train
    elseif roundState == IdolRoundState.IdolRoundState_End then
        if UIN25IdolGameHelper.CheckState_Agreed(component) then
            state = IdolGameState.Agreed
        elseif UIN25IdolGameHelper.CheckState_Weekend(component, forceActOpened) then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN25IdolCheckState)

            state = IdolGameState.Weekend
        elseif UIN25IdolGameHelper.CheckState_Concert(component,froceConcertOpened) then
            state = IdolGameState.Concert
        else
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN25IdolCheckState)

            req = UIN25IdolGameHelper.CheckState_TurnEnd(component)
            state = IdolGameState.TurnEnd
        end
    end

    if req then
        component:Start_HandleIdolTrain(req.round, req.state, req.trainType, callback)
        state = (state % IdolGameState.TurnEnd) + 1
    elseif callback then
        callback()
    end

    Log.info("UIN25IdolGameHelper.CheckState() state = ", state)
    return state
end
---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_None(component)
    local breakInfo = component.m_component_info.break_info

    local req = {}
    req.round = breakInfo.round_index
    req.state = IdolRoundState.IdolRoundState_Begin
    req.trainType = IdolTrainType.IdolTrainType_None
    return req
end

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_Begin(component)
end

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_Train(component)
    local breakInfo = component.m_component_info.break_info
    local trainType = breakInfo.train_type
    GameGlobal.UIStateManager():ShowDialog("UIN25IdolGameTraining", trainType)
end

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_Agreed(component)
    local breakInfo = component.m_component_info.break_info
    local trainType = breakInfo.train_type
    local eventId = component:UI_CheckAgreedEvent(trainType)
    if eventId then
        GameGlobal.UIStateManager():ShowDialog("UIN25IdolApController", eventId)
        return true
    end
end

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_Weekend(component, forceActOpened)
    local isOpen = (not forceActOpened) and component:UI_CheckActOnWeekend()
    if isOpen then
        CutsceneManager.ExcuteCutsceneIn(
            "UIN25Idol_Common_Switch",
            function()
                GameGlobal.UIStateManager():ShowDialog("UIN25IdolAct", true)

                -- CutsceneManager.ExcuteCutsceneOut(function()
                --     GameGlobal.UIStateManager():ShowDialog("UIN25IdolAct", true)
                -- end)
            end)
    end
    return isOpen
end

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_Concert(component,froceConcertOpened)
    if froceConcertOpened then
        return false
    end
    
    --检查播没播过演唱会
    local breakInfo = component.m_component_info.break_info
    local isConcertDone = breakInfo.isConcertDone
    if isConcertDone then
        --检查开启天数
        local isOpenNextDay = UIN25IdolGameHelper.OpenDayState(component.m_component_info)
        if not isOpenNextDay then
            CutsceneManager.ExcuteCutsceneIn(
            "UIN25Idol_Common_Switch",
            function()
                GameGlobal.UIStateManager():ShowDialog("UIN25IdolNotOpenNextDay")
            end)
        end
        return false
    end

    local roundIndex = breakInfo.round_index
    local isToday, fansEnough, gapFans = component:UI_CheckConcert()
    if isToday then
        if fansEnough then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN25IdolCheckState)

            -- 进入演唱会的转场
            GameGlobal.UIStateManager():ShowDialog("UIN25IdolConcertEnter", roundIndex)
        else
            -- 演唱会失败
            CutsceneManager.ExcuteCutsceneIn(
            "UIN25Idol_Common_Switch",
            function()
                GameGlobal.UIStateManager():ShowDialog("UIN25IdolConcertResult", false, roundIndex,gapFans)
            end)
        end
        -- 还有一些 UI 的处理在 UIN25IdolGame:_SetConcert()
    end
    return isToday
end

---@type component IdolMiniGameComponent
function UIN25IdolGameHelper.CheckState_TurnEnd(component)
    local breakInfo = component.m_component_info.break_info

    local req = {}
    req.round = breakInfo.round_index + 1
    req.state = IdolRoundState.IdolRoundState_Begin
    req.trainType = IdolTrainType.IdolTrainType_None
    return req
end
function UIN25IdolGameHelper.OpenDayState(cInfo)
    local unlockTime = cInfo.m_unlock_time
    local breakInfo = cInfo.break_info
    local nextTurn = breakInfo.round_index+1
    local secondsPerDay = 24*60*60

    local state = UIN25IdolGameHelper.ComponentState(cInfo)
    
    if state == UISummerOneEnterBtnState.NotOpen then
    elseif state == UISummerOneEnterBtnState.Normal then
        local nowTimestamp = UICommonHelper.GetNowTimestamp()
        local curStage = math.floor((nowTimestamp - unlockTime)/secondsPerDay)  + 1 

        local cfgs = Cfg.cfg_component_idol_round{Round=nextTurn}
        if cfgs and #cfgs > 0 then
            local cfg_round = cfgs[1]
            if cfg_round then
                local day = cfg_round.UnlockTime
                if curStage>=day then
                    return true
                end
            end
        end
    elseif state == UISummerOneEnterBtnState.Closed then
    end
    return false
end
function UIN25IdolGameHelper.ComponentState(cInfo)
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < cInfo.m_unlock_time then --未开启
        return UISummerOneEnterBtnState.NotOpen
    elseif nowTimestamp > cInfo.m_close_time then --已关闭
        return UISummerOneEnterBtnState.Closed
    else --进行中
        if cInfo.m_b_unlock then --是否已解锁，可能有关卡条件
            return UISummerOneEnterBtnState.Normal
        else
            local cfgv = Cfg.cfg_campaign_mission[cInfo.m_need_mission_id]
            if cfgv then
                return UISummerOneEnterBtnState.Locked
            else
                return UISummerOneEnterBtnState.Normal
            end
        end
    end
end