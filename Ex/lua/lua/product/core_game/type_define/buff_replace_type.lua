---@class BuffReplaceType
BuffReplaceType = {
    Exclusive = 1, --互斥
    CoExist = 2, --共存
    RoundOverlap = 3, --回合数叠加
    EffectOverlap = 4, --效果叠加
    Replace = 5, --替换
    LayerLimit = 6, --添加buff时检测层数叠加，如果超出最大层数，直接不添加
}
