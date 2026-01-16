---@class EffectType
local EffectType = {
    Bind = 1, --绑定节点特效
    FollowHead = 2, --头顶跟随
    Path = 3, --直线路径
    UI = 4, --UI特效
    VirtualBind = 5, --虚拟挂载点，初始化时参照绑定点的位置设置一次，姿态按照攻击者设置
    ScreenEffPoint = 6, --区别于UI的相机特效挂点，表现类似于2D特效
    Hit = 7, --被击特效
    MAx = 99. --
}
_enum("EffectType", EffectType)
