---@class Algorithm
Algorithm = Algorithm
_staticClass( "Algorithm" )

--[[------------------------------------------------------------------------------------------
    排序
]]--------------------------------------------------------------------------------------------


--如果object1 < object2，object1排在object2前面
--使用Algorithm.LessComparer做为比较函数
Algorithm.COMPARE_LESS = 1
--如果object1 > object2，object1排在object2前面
--使用Algorithm.GreaterComparer做为比较函数
Algorithm.COMPARE_GREATER = 2
--需要提供一个自定义函数custom_comparer，custom_comparer(object1, object2) > 0，object1排在object2前面
Algorithm.COMPARE_CUSTOM = 3


--[[-------------------------------------------
    比较函数
对object1和object2进行排序比较时，约定这么一种比较函数: function func(object1, object2)，它返回一个整数result    
    --如果result > 0，object1排在object2前面
    --如果result < 0，object1排在object2后面
    --如果result == 0，object1与object2完全相同（请从逻辑上避免）
]]---------------------------------------------

--[[-------------------------------------------
    小的在前
]]---------------------------------------------
function Algorithm.LessComparer(object1, object2)
    if object1 < object2 then
        return 1
    elseif object1 > object2 then
        return -1
    else
        return 0
    end
end

--[[-------------------------------------------
    大的在前
]]---------------------------------------------
function Algorithm.GreaterComparer(object1, object2)
    if object1 > object2 then
        return 1
    elseif object1 < object2 then
        return -1
    else
        return 0
    end
end