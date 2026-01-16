---同步模式类型
---@class SyncModeType
SyncModeType = {
    NoSync  = 0,    ---没有同步校验
    Release = 1,    ---正式版同步
    Debug   = 2,    ---调试版同步
    Cehua   = 3,    ---策划调试数值的对局：只启动Match的对局
}
_enum("SyncModeType", SyncModeType)