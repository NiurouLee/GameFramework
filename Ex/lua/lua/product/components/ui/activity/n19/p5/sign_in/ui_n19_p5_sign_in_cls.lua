--- @class UIN19P5SignInStatus
local UIN19P5SignInStatus = {
    Lock = 0, --锁
    Get = 1, --可领取
    Finish = 2,--已领取
}
_enum("UIN19P5SignInStatus", UIN19P5SignInStatus)
--- @class UIN19P5SignInPosType
local UIN19P5SignInPosType = {
    Up = 0, --上
    Current = 1, --中
    Down = 2,--下
}
_enum("UIN19P5SignInPosType", UIN19P5SignInPosType)