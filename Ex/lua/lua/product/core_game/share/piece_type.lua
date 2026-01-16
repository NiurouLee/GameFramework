---@class PieceType
local PieceType = {
    None = 0, --无色
    Blue = 1, --蓝色(水)
    Red = 2, --红色(火)
    Green = 3, --绿色(森)
    Yellow = 4, --黄色(雷)
    Any = 5, --万色(任意)
 }
 PieceType = PieceType
_enum("PieceType", PieceType)

---@class PieceEffectType
local PieceEffectType = {
    Normal = 0, --无效果
    Prism = 1, --棱镜效果(连线沿线方向3格变为此格子颜色)
    PrismEffect = 2, --十字棱镜效果(特效表现，不是格子动画)
    MAX = 9
}
_enum("PieceEffectType", PieceEffectType)

--判断两种格子是否可以匹配
function CanMatchPieceType(t1, t2)
    if t1 == PieceType.None or t2 == PieceType.None then
        return false
    end
    if t1 == PieceType.Any or t2 == PieceType.Any then
        return true
    end

    return t1 == t2
end

--判断格子是否匹配
function CanMatchPieceTypeList(type, typeList)
    if type == PieceType.None then
        return false
    end
    if type == PieceType.Any then
        return true
    end

    return table.icontains(typeList, type)
end

--消灭星星模式下判断两种格子是否可以匹配
function PopStarCanMatchPieceType(t1, t2, tOri)
    if t1 == PieceType.None or t2 == PieceType.None then
        return false
    end

    if t2 == PieceType.Any then
        return true
    end

    return t1 == t2
end

--克制关系
ElementRelation = {
    [PieceType.Blue] = {
        lt = PieceType.Yellow,--被黄色克制
        bt = PieceType.Red --克制红色
    },
    [PieceType.Red] = {
        lt = PieceType.Blue,
        bt = PieceType.Green
    },
    [PieceType.Green] = {
        lt = PieceType.Red,
        bt = PieceType.Yellow
    },
    [PieceType.Yellow] = {
        lt = PieceType.Green,
        bt = PieceType.Blue
    }
}
---@class ElementRelationFlag
local ElementRelationFlag = {
    Counter = 0, --克制
    BeCountered = 1, --被克制
    Normal = 2, --无克制关系
 }
 ElementRelationFlag = ElementRelationFlag
_enum("ElementRelationFlag", ElementRelationFlag)