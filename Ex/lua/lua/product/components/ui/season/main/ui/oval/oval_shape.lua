---处理椭圆 默认焦点在x轴上
---@class OvalShape:Object
_class("OvalShape", Object)
OvalShape = OvalShape

local EPSINON = 1E-5
local abs = math.abs
local sqrt = math.sqrt
local function equal(a, b)
    return abs(a - b) < EPSINON
end


function OvalShape:Constructor(a, b)
    if a < b or a < 0 or b < 0 then
        Log.exception("椭圆参数错误:", a, b)
    end
    Log.info("初始化椭圆:", a, b)
    self._a = a --长半轴
    self._b = b --短半轴
    self._aa = a * a
    self._bb = b * b
    self._longAxis = 2 * a             --椭圆长轴长度
    local focusX = sqrt(a * a - b * b)
    self._focus1 = Vector2(-focusX, 0) --焦点1
    self._focus2 = Vector2(focusX, 0)  --焦点2
end

---@param point Vector2 点坐标
---@return boolean 点是否在椭圆内
function OvalShape:IsInside(point)
    if point.x <= -self._a or point.x >= self._a then
        return false
    elseif point.y <= -self._b or point.y >= self._b then
        return false
    end

    --点到两个焦点距离之和小于长轴距离 则点在椭圆内
    local distance = Vector2.Distance(point, self._focus1) + Vector2.Distance(point, self._focus2)
    return distance < self._longAxis
end

---@param target Vector2 坐标点与椭圆中心点连线线段与椭圆的交点 这个点一定是在椭圆外
---@return Vector2
function OvalShape:CrossPoint(target)
    if equal(target.x, 0) then
        --竖线 无斜率
        if target.y > 0 then
            return Vector2(0, self._b)
        else
            return Vector2(0, -self._b)
        end
    else
        local k = target.y / target.x --斜率
        local b = 0                   --经过原点
        --经过原点的直线与椭圆的交点
        local x = sqrt((self._aa * self._bb) / (self._bb + k * k * self._aa))
        if target.x < 0 then
            x = -x
        end
        local y = k * x
        return Vector2(x, y)
    end
end
