--region dc define

--- @class GameMatchError
local GameMatchError = {
    GME_Succ = 0,
    GME_Failed = 1,
    GME_OutOfTime = 2, --匹配超时
    GME_InMatchQueue = 3, --正在匹配
    GME_InMatch = 4, --正在对局中
    GME_CreateMatchFailed = 5,
    GME_CreateGroupFailed = 6,
}
_enum("GameMatchError", GameMatchError)

--endregion dc define
