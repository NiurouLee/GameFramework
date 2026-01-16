--弹跳小游戏全局状态机
local StateBounce= {
    Init = 0, --初始化
    Prepare = 1, --准备
    Battle = 2, --战斗中
    Pause = 3, --暂停
    Resume = 4, --恢复
    Over = 5 --结束
}
_enum("StateBounce", StateBounce)