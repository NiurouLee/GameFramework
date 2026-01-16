---@class GridTouchStateID
GridTouchStateID = GridTouchStateID
_enum("GridTouchStateID", {
    Invalid = 0,
    BeginDrag = 1,
    Drag = 2,
    EndDrag = 3,
    DoubleClick = 4,
    PLLBeginDrag = 5, ---主动技预览阶段连线开始
    PLLDrag = 6, ---主动技预览阶段连线拖拽
    PLLEndDrag = 7, ---主动技预览阶段连线终止
})
