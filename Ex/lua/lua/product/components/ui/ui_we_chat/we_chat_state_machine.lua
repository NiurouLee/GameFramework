require "fsm_state_machine"
require "we_chat_state"

--[[
	@微信状态机
--]]
---@class WeChatStateMachine
_class("WeChatStateMachine", FSMStateMachine)
WeChatStateMachine = WeChatStateMachine

--界面状态
---@class WeChatState
local WeChatState = {
    Empty = -1, -- 空状态
    Normal = 1, -- 正常状态不需要回复
    Reply = 2, -- 可回复状态
    AddAnswer = 3, -- 添加回复
    Wait = 4, -- 等待动画开始
    WaitEnd = 5, -- 等待结束
    Voice = 6 -- 语音
}
_enum("WeChatState", WeChatState)

---@class WeChatStateName
local WeChatStateName = {
    [WeChatState.Empty] = "Empty", -- Empty
    [WeChatState.Normal] = "Normal", -- 正常状态不需要回复
    [WeChatState.Reply] = "Reply", -- 可回复状态
    [WeChatState.AddAnswer] = "AddAnswer", --添加回复
    [WeChatState.Wait] = "Wait", -- 等待动画开始
    [WeChatState.WaitEnd] = "WaitEnd", -- 等待结束
    [WeChatState.Voice] = "Voice" -- 语音
}
_enum("WeChatStateName", WeChatStateName)
function WeChatStateMachine:OnInit()
    self:Add(WeChatEmptyState:New(WeChatState.Empty, self))
    self:Add(WeChatNormalState:New(WeChatState.Normal, self))
    self:Add(WeChatReplyState:New(WeChatState.Reply, self))
    self:Add(WeChatAddAnswerState:New(WeChatState.AddAnswer), self)
    self:Add(WeChatWaitState:New(WeChatState.Wait), self)
    self:Add(WeChatWaitEndState:New(WeChatState.WaitEnd), self)
    self:Add(WeChatVoiceState:New(WeChatState.Voice, self))
end
