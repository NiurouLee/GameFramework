--[[-------------------------------------------
-----------------------------------------------
    所有数学函数归为以下几类：
        math：LUA源码自带，C
        mathext：LUA源码扩展，C++
        intmath：LUA源码扩展，整数运算，C++
        lmathext：LUA扩展，LUA
        lintmath：LUA扩展，整数运算，LUA
-----------------------------------------------
]]---------------------------------------------
local floor = math.floor
local pow = math.pow

_G.MAX_INT_32 = 2147483647

lmathext = {}

lmathext.deg2rad = math.pi / 180  --有现成函数math.rad
lmathext.rad2deg = 180 / math.pi  --有现成函数math.deg
lmathext.epsilon = 1.401298e-45

function lmathext.round(num)
	return floor(num + 0.5)
end

function lmathext.round_with_precision(what, precision)
   return floor(what * pow(10, precision) + 0.5) / pow(10, precision)
end

function lmathext.sign(num)  
	if num > 0 then
		return 1
	elseif num < 0 then
		return -1
	else 
		return 0
	end
end

function lmathext.isnan(number)
	return not (number == number)
end

function lmathext.clamp(num, min, max)
	if num < min then
		num = min
	elseif num > max then
		num = max    
	end	
	return num
end
local clamp = lmathext.clamp

function lmathext.lerp(from, to, t)
	return from + (to - from) * clamp(t, 0, 1)
end

function lmathext.RandomRange(n, m)
	local range = m - n	
	return math.random() * range + n
end

function lmathext.Approximately(a, b)
	return abs(b - a) < math.max(1e-6 * math.max(abs(a), abs(b)), 1.121039e-44)
end
