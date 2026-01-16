--弹跳小游戏角色状态机

--- @class StateBouncePlayer
local StateBouncePlayer= {
    Init = 0, --初始
    Walk = 1, --行走
    Attack = 2, --攻击
    Jump = 3, --基础跳跃（上升）
    Down = 4, --普通下落
    JumpAttack = 5, --跳跃二攻击
    AccDown = 6, --加速下落
    Dead = 7 --死亡
}
_enum("StateBouncePlayer", StateBouncePlayer)