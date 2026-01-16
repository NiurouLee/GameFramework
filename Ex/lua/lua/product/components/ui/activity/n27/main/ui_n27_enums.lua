---@class N27ComponetStatus
local N27ComponetStatus = {
    NotStart = 1,--未开启
    OverTime = 2,--已关闭
    Lock = 3,--未解锁
    Other = 4,--其他
    Open = 5--开启
}
_enum("N27ComponetStatus", N27ComponetStatus)