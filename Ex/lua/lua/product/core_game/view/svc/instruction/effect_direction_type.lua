--[[------------------------------------------------------------------------------------------
    EffectDirectionType : 特效方向类型定义
]] --------------------------------------------------------------------------------------------

---@type EffectDirectionType
EffectDirectionType = {
    None = 0,
    Up = 1, --上
    Right = 2, --右
    Down = 3, --下
    Left = 4, --左
    UpDown = 5, --上下
    LeftRight = 6, --左右
    EightDir = 7, --八方向
    RightUp = 8, --右上
    RightDown = 9, --右下
    LeftDown = 10, --左下
    LeftUp = 11, --左上
    Cross = 12 --上下左右
}
_enum("EffectDirectionType", EffectDirectionType)