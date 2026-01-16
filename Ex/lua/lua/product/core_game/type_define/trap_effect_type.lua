---@class TrapEffectType
local TrapEffectType = {
    None = 0,       --没有，不加注释报错
    Auras =1 ,      ---光环型机关，相同类型的框要合并
    RuneChange = 5, --- 符文变化
    EnhancePiece = 6 ,--强化格子
    ShowCountDownType = 7, --显示倒计时，按回合销毁
}
_enum("TrapEffectType", TrapEffectType)
TrapEffectType = TrapEffectType

---@class TrapHeadShowType
local TrapHeadShowType={
    HeadShowRound = 1, --头顶显示回合计时
    GridShowRound = 2, --格子显示回合计时
    GridShowAnim =3,   --格子显示动画
    HeadShowLevel =4,   --头顶显示等级（法官雕像）
    HeadShowSummonIndex =5,   --头顶显示召唤序号
}
_enum(  "TrapHeadShowType",TrapHeadShowType)
