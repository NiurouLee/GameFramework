require "fsm_state"

--region 普通状态
_class("WeChatEmptyState", FSMState)
WeChatEmptyState = WeChatEmptyState

--region 普通状态
_class("WeChatNormalState", FSMState)
WeChatNormalState = WeChatNormalState

function WeChatNormalState:Enter(speakerId)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatNormalState, speakerId)
end

--endregion

--region 可回复状态
_class("WeChatReplyState", FSMState)
WeChatReplyState = WeChatReplyState

function WeChatReplyState:Enter(speakerId)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatReplyState, speakerId)
end

--endregion

--region 语音状态
_class("WeChatVoiceState", FSMState)
WeChatVoiceState = WeChatVoiceState

function WeChatVoiceState:Constructor()
end

--endregion

--region 添加回复状态
_class("WeChatAddAnswerState", FSMState)
WeChatAddAnswerState = WeChatAddAnswerState

function WeChatAddAnswerState:Enter(data)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatAddAnswerState, data)
end

--endregion

--region 等待状态
_class("WeChatWaitState", FSMState)
WeChatWaitState = WeChatWaitState

function WeChatWaitState:Enter(data, time)
    if not time then
        time = 500
    end
    self.time = time
    self.data = data
    self.startTime = GameGlobal:GetInstance():GetCurrentTime()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatWaitState, self.data)
end

function WeChatWaitState:Excute()
    local nowTime = GameGlobal:GetInstance():GetCurrentTime()
    -- 3秒后等待动画结束
    if nowTime - self.startTime > self.time then
        self:ChangeState(WeChatState.WaitEnd, self.data)
    end
end

--endregion

--region 等待状态结束
_class("WeChatWaitEndState", FSMState)
WeChatWaitEndState = WeChatWaitEndState
function WeChatWaitEndState:Enter(data)
    AudioHelperController.PlayRequestedUISound(CriAudioIDConst.WeChatRecvMessage)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.WeChatWaitEndState, data)
end

--endregion
