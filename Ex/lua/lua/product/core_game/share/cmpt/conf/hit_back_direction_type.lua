--[[------------------------------------------------------------------------------------------
    HitBackDirectionType : 技能击退方向参数
]] --------------------------------------------------------------------------------------------

---@class HitBackDirectionType
---@field CoffinMusume number
HitBackDirectionType = {
    None                    = 0, --
    Up                      = 1, --上
    Right                   = 2, --右
    Down                    = 3, --下
    Left                    = 4, --左
    UpDown                  = 5, --上下
    LeftRight               = 6, --左右
    EightDir                = 7, --八方向
    RightUp                 = 8, --右上
    RightDown               = 9, --右下
    LeftDown                = 10, --左下
    LeftUp                  = 11, --左上
    Cross                   = 12, --上下左右
    SelectCanUseDir         = 13, --选择一个可以使用的方向，按照上、右、下、左的顺序选择
    FaceFront               = 14, ---面前
    SelectSquareRingFarest  = 15, --选择一个可以使用的方向，按照目标点方形环周围一圈8个格子，距离施法者最远的顺序选择
    SpecifyXCoordinate      = 16, --击退到指定X坐标
    SelectCanUse8Dir        = 17, --选择一个可以使用的方向，钻地怪定制,只支持来自四方向的击退,按照击退方向,优先级不同
    SelectNearestOutOfRange = 18, --逆时针选择范围外最近的点
    AntiEightDir            = 19, --反八方向 与八方向相比只影响排序
    SelectCanUseDirAndDis   = 20, --17的扩展，根据攻击方向确定选择的四方向，并支持按圈数查找可击退位置，返回击退距离
    CoffinMusume            = 21, --N23棺材娘技能1专用，参见https://wiki.h3d.com.cn/pages/viewpage.action?pageId=74768251
    CasterDir2Edge          = 22, --施法者方向到版边
    Front3Dir               = 23, --动态的面前三方向不包括身后
    AttackFront2Edge        = 24, --施法者攻击的正前方至版边
    EightDirAndCasterAround = 25, --目标八方向击退,没有就在施法者周围一圈选一个点
    Butterfly               = 26, --神性蝴蝶专属，根据实际情况选择朝向和位置
    END                     = 9999 --
}
_enum("HitBackDirectionType", HitBackDirectionType)

HitBackDirectionTypeHelper = {}

---将方向枚举转为一个二维向量
function HitBackDirectionTypeHelper.ConvertDirTypeToVector(dirType)
    local vectorRes = Vector2(0, 0)
    if dirType == HitBackDirectionType.Up then
        vectorRes = Vector2(0, 1)
    elseif dirType == HitBackDirectionType.Right then
        vectorRes = Vector2(1, 0)
    elseif dirType == HitBackDirectionType.Down then
        vectorRes = Vector2(0, -1)
    elseif dirType == HitBackDirectionType.Left then
        vectorRes = Vector2(-1, 0)
    end

    return vectorRes
end

function HitBackDirectionTypeHelper.ConvertDirTypeToVectorEight(dirType)
    local vectorRes = Vector2(0, 0)
    if dirType == HitBackDirectionType.Up then
        vectorRes = Vector2(0, 1)
    elseif dirType == HitBackDirectionType.Right then
        vectorRes = Vector2(1, 0)
    elseif dirType == HitBackDirectionType.Down then
        vectorRes = Vector2(0, -1)
    elseif dirType == HitBackDirectionType.Left then
        vectorRes = Vector2(-1, 0)
    elseif dirType == HitBackDirectionType.RightUp then
        vectorRes = Vector2(1, 1)
    elseif dirType == HitBackDirectionType.RightDown then
        vectorRes = Vector2(1, -1)
    elseif dirType == HitBackDirectionType.LeftUp then
        vectorRes = Vector2(-1, 1)
    elseif dirType == HitBackDirectionType.LeftDown then
        vectorRes = Vector2(-1, -1)
    end

    return vectorRes
end

---处理两个枚举方向的叠加
function HitBackDirectionTypeHelper.OverlapHitbackDir(firstDirType, secondDirType)
    local firstVector = HitBackDirectionTypeHelper.ConvertDirTypeToVector(firstDirType)
    local secondVector = HitBackDirectionTypeHelper.ConvertDirTypeToVector(secondDirType)

    local vectorResult = firstVector + secondVector

    if vectorResult.x > 0 then
        if vectorResult.y > 0 then
            return HitBackDirectionType.RightUp
        else
            return HitBackDirectionType.RightDown
        end
    elseif vectorResult.x < 0 then
        if vectorResult.y > 0 then
            return HitBackDirectionType.LeftUp
        else
            return HitBackDirectionType.LeftDown
        end
    elseif vectorResult.x == 0 and vectorResult.y == 0 then
        return HitBackDirectionType.None
    end

    Log.fatal("OverlapHitbackDir is nil")
end

--根据攻击朝向，返回八方向
function HitBackDirectionTypeHelper.NormalizeDirType(attackDir)
    local tempDir = Vector2(attackDir.x, attackDir.y)
    tempDir = GameHelper.ComputeLogicDir(tempDir)

    if tempDir.x ~= 0 then
        local sign = tempDir.x / math.abs(tempDir.x)
        tempDir.x = math.floor(math.abs(tempDir.x) + 0.5) * sign
    end
    if tempDir.y ~= 0 then
        local sign = tempDir.y / math.abs(tempDir.y)
        tempDir.y = math.floor(math.abs(tempDir.y) + 0.5) * sign
    end
    return tempDir
end
