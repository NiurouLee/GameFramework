---@class DirectionType
---@field Up
---@field Right
---@field Down
---@field Left
local DirectionType = {
    None = 0,
    Up = 1, --上
    Right = 2, --右
    Down = 3, --下
    Left = 4, --左
    LeftUp = 5, --左上
    LeftDown = 6, --左下
    RightUp = 7, --右上
    RightDown = 8, --右下
    END = 9999
}
_enum("DirectionType",DirectionType)