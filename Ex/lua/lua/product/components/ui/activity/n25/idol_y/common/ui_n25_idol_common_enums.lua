--完成状态
--- @class UIIdolStatus
local UIIdolStatus = {
    GoTo = 1, --可完成
    Not = 2, --实力不足
    Finish = 3, --已完成
}
_enum("UIIdolStatus", UIIdolStatus)
--约定事件的状态
--- @class UIIdolApEventStatus
local UIIdolApEventStatus = {
    Ready = 1, --可完成
    Pass = 2, --已过期
    Finish = 3, --已完成
}
_enum("UIIdolApEventStatus", UIIdolApEventStatus)
--UIResultType
--- @class UIIdolResultType
local UIIdolResultType = {
    Training = 1, --训练
    Act = 2, --偶像活动
    ConcertSucc = 3,--演唱会成功
    ConcertFail = 4,--演唱会失败
}
_enum("UIIdolResultType", UIIdolResultType)