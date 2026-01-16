--region 时间/日期相关（逻辑运算）
_G._NOW0 = os.time
local CS_TIME_DELTA = 0 --与CS时间差

local newGetCurLanguage = Localization.GetCurLanguage
Localization.GetCurLanguage = function()
	return newGetCurLanguage(true)
end

LanguageType = {
	zh = "zh",		--简体中文
	tw = "tw",    	--繁体中文，台湾
	us = "us",    	--美国  
	kr = "kr",    	--韩国
	jp = "jp",    	--日本
	pt = "pt",  	--葡萄牙语
	es = "es",   	--西班牙语
	idn = "idn",   	--印尼语
	th = "th",		--泰语
}

local language = Localization.GetCurLanguage()
local toint = math.tointeger

---@return int 得到服务器当前时间（utc），参与跟服务器有关计算时，都用这个值
_G._now = function( unit ) --同步CS时间
	local t0 = _NOW0( unit )
	local t1 = t0 + CS_TIME_DELTA
	return t1
end

---将一个utc时间转换为客户端本地时间
---@param t utc时间
---@return table 年月日时分秒周
_G._time = function(t)
	return os.date("*t", t)
end

---将一个utc时间转换为utc格式时间，不受时区印象
---@param t utc时间
---@return table 年月日时分秒周
_G._utcTime = function(t)
	return os.date("!*t", t)
end

---将一个utc格式的日期转换为客户端本地日期
---@param data table year = 2020, month = 12, day = 2, hour= 11, min = 20, sec = 0, wday = 0, yday = 0, isdst = false
---@return string
_G._utc2Local = function(data)
	local now = os.time(data)
	local diff = os.difftime(_NOW0(), _NOW0(_utcTime(_NOW0())))
	local t = diff/3600
	now = now + diff
	return os.date("%Y-%m-%d %H:%M:%S", now)
end

---返回客户端当前时区
_G._curTimeZone = function()
	return os.difftime(_NOW0(), _NOW0(_utcTime(_NOW0())))/3600
end

function _G.AdjustTimeCS(servertime) --同步CS服务端时间 秒级
	CS_TIME_DELTA = servertime - _NOW0()
end

---两个s时间是否同日
function _G.SameDay(t1,t2)
	local d1 = _time(t1)
	local d2 = _time(t2)
	return d1.year==d2.year and d1.month==d2.month and d1.day==d2.day
end

---两个s时间是否同周
function _G.SameWeek(t1,t2)
	local d1 = _time(t1)
	local d2 = _time(t2)
	local w1 = d1.wday
	local w2 = d2.wday
	if w1==0 then w1=7 end
	if w2==0 then w2=7 end
	d1 = _time(t1-w1*86400)
	d2 = _time(t2-w2*86400)
	return d1.year==d2.year and d1.month==d2.month and d1.day==d2.day
end

---两个ms时间是否同月
function _G.SameMonth(t1,t2)
	local d1 = _time(t1)
	local d2 = _time(t2)
	return d1.year==d2.year and d1.month==d2.month
end

---取得当指定时间的0点时间
function _G.Day0time(t)
	local l_GMT_zero_time = math.floor(t/86400) * 86400	--0时区0点
	local l_time_zone_diff = _curTimeZone() * 3600 -- 时差
	local l_zone_zero_time = l_GMT_zero_time - l_time_zone_diff -- 当前时区的0点
	--修正时间
	if t - l_zone_zero_time >= 86400 then
		l_zone_zero_time = l_zone_zero_time + 86400
	end
	return l_zone_zero_time	--今日0点
end

---已经过去的秒数（零时起）!!当前时区
function _G.TodayPastTimeSec(t)
	local t1 = t or _NOW0()
	local l_today_sec = t1 - Day0time(t1)
	return l_today_sec
end



---取得当指定时间的24点时间
function _G.Day24time(t)
	return math.ceil((t or _NOW0())/86400)*86400--今日24点
end

---@return int toint(yymmdd)
function _G.GetDayKeyNum(t)
	local now = t or _now()
	local d = _time(now)
	local dk = d.year*10000+d.month*100+d.day
	return dk
end

---@return int t2-t1
function _G.DaysBetweenTwoDate(t1, t2) 
	local oldtime=_time(t1)
	local newtime=_time(t2)
	if oldtime.year==newtime.year then
		return newtime.yday-oldtime.yday
	elseif oldtime.year>newtime.year then
		return -DaysBetweenTwoDate(t2,t1)
	else
		local day=0
		for i=oldtime.year,newtime.year do
			local isLeap = (i%4==0 and i%100~=0) and i%400==0   --判断是否是闰年
			if i==oldtime.year then day=day+ (isLeap and 365 or 366)-oldtime.yday
				elseif i~=newtime.year then day=day+(isLeap and 365 or 366)
					else day=day+newtime.yday
			end
		end
		return day
	end
end

function _G.InDayTime(range,now)
	local t0 = Day0time(now)/60000
	local s = t0 + range[1]*600 + range[2]
	local e = t0 + range[3]*600 + range[4]
	return s <= t0 and t0 <= e
end

function _G.DaysInclude(t1, t2, hour)
	return SameDay(t1-hour*60*60*1000, t2-hour*60*60*1000)
end
--endregion

--region 时间/日期相关（界面显示）

if language ~= LanguageType.us then
	--秒级
	function _G.TimeToDate(t, s)
		local d = _time(t)
		if not s or s == "sec" then
			return string.format('%04d-%02d-%02d %02d:%02d:%02d',d.year,d.month,d.day,d.hour,d.min,d.sec)
		elseif s == 'day' then
			return string.format('%04d-%02d-%02d',d.year,d.month,d.day)
		elseif s == 'hour' then
			return string.format('%04d-%02d-%02d %02d',d.year,d.month,d.day,d.hour)
		elseif s == 'min' then
			return string.format('%04d-%02d-%02d %02d:%02d',d.year,d.month,d.day,d.hour,d.min)
		end
	end

	---没有年的日期格式
	function _G.TimeToDateNoY(s)  
		local d = _time(s)
		return string.format('%02d-%02d %02d:%02d',d.month, d.day, d.hour, d.min)
	end
else
	--秒级
	function _G.TimeToDate(t, s)
		local d = _time(t)
		if not s or s == "sec" then
			return string.format('%04d/%02d/%02d %02d:%02d:%02d',d.year,d.month,d.day,d.hour,d.min,d.sec)
		elseif s == 'day' then
			return string.format('%04d/%02d/%02d',d.year,d.month,d.day)
		elseif s == 'hour' then
			return string.format('%04d/%02d/%02d %02d',d.year,d.month,d.day,d.hour)
		elseif s == 'min' then
			return string.format('%04d/%02d/%02d %02d:%02d',d.year,d.month,d.day,d.hour,d.min)
		end
	end

	---没有年的日期格式
	function _G.TimeToDateNoY(s)  
		local d = _time(s)
		return string.format('%02d/%02d %02d:%02d',d.month, d.day, d.hour, d.min)
	end
end

--- 秒转化成天
function _G.ToDay(sec)
	local day = (sec / 86400) - (sec / 86400) % 1
	local hour =  sec / 86400 % 1 * 60 * 24 * 1
	-- return day .. "天" .. ToHour(hour)
	return string.format(StringTable.Get("str_common_days"), day) .. ToHour(hour)
end

-- 秒转化成小时 eg: 4206 --> 01:10:06
function _G.ToHour(seconds) 
	local hour = seconds/3600 - (seconds/3600) % 1
	local min =  seconds / 3600 % 1 * 60 * 60 * 1
	return hour..":"..ToMinutes(min)
end

--- 秒转分钟 eg:1200  ->     20:00
function _G.ToMinutes(seconds) 
	local minutes= (seconds / 60) - (seconds / 60) % 1
	seconds = (seconds / 60 % 1 * 60) - (seconds / 60 % 1 * 60) % 1 -- （分钟小数部分 * 60 ） 再精确到秒钟整数部分
	if seconds <= 9 then
		seconds = "0" .. seconds
	end
	if minutes <= 9 then
		minutes = "0" .. minutes
	end
	return minutes .. ":" .. seconds
end

function _G.ToTiming(seconds)
	if seconds > 86400 then
		return ToDay(seconds)
	elseif seconds > 3600 then
		return ToHour(seconds)
	elseif seconds > 60 then
		return ToMinutes(seconds)
	else
		return '' .. seconds
	end
end

if language ~= LanguageType.us then
	---格式：x时x分x秒；x分x秒；x秒
	function _G.ToTimingFormat2(seconds) 
		if seconds > 3600 then
			local format
			local hour = seconds/3600 - (seconds/3600) % 1
			local min =  seconds / 3600 % 1 * 60 * 60
			local minutes = (min / 60) - (min / 60) % 1
			seconds = (min / 60 % 1 * 60) - (min / 60 % 1 * 60) % 1
			--format = hour .. '时'.. minutes .. '分'.. seconds .. '秒'
			format = StringTable.Get("str_common_hhmmss",  toint(hour),  toint(minutes), toint(seconds))
			return format
		elseif seconds > 60 then
			local format
			local minutes = (seconds / 60) - (seconds / 60) % 1
			seconds = (seconds / 60 % 1 * 60) - (seconds / 60 % 1 * 60) % 1
			-- format = minutes .. '分'.. seconds .. '秒'
			format = StringTable.Get("str_common_mmss", toint(minutes), toint(seconds))
			return format
		else
			-- local format = seconds .. '秒'
			local format = StringTable.Get("str_common_ss", seconds)
			return format
		end
	end
else
	---格式：x:x:x；x:x；x
	function _G.ToTimingFormat2(seconds) 
		if seconds > 3600 then
			local format
			local hour = seconds/3600 - (seconds/3600) % 1
			local min =  seconds / 3600 % 1 * 60 * 60
			local minutes = (min / 60) - (min / 60) % 1
			seconds = (min / 60 % 1 * 60) - (min / 60 % 1 * 60) % 1
			format = toint(hour)..":"..toint(minutes)..":"..toint(seconds)
			return format
		elseif seconds > 60 then
			local format
			local minutes = (seconds / 60) - (seconds / 60) % 1
			seconds = (seconds / 60 % 1 * 60) - (seconds / 60 % 1 * 60) % 1
			format = toint(minutes)..":"..toint(seconds)
			return format
		else
			local format = seconds
			return format
		end
	end
end

---1格式：00:00:00 / 00:00
function _G.ToTimingFormat(seconds) 
	if seconds > 3600 then
		local format
		local hour = seconds/3600 - (seconds/3600) % 1
		local min =  seconds / 3600 % 1 * 60 * 60
		if math.floor(hour/10) == 0 then
			format = '0' .. hour .. ':'
		else
			format = hour .. ':'
		end
		local minutes = (min / 60) - (min / 60) % 1
		seconds = (min / 60 % 1 * 60) - (min / 60 % 1 * 60) % 1
		if math.floor(minutes/10) == 0 then
			format = format .. '0' .. minutes .. ':'
		else
			format = format .. minutes .. ':'
		end
		if math.floor(seconds/10) == 0 then
			format = format .. '0' .. seconds
		else
			format = format .. seconds
		end
		return format
	elseif seconds > 60 then
		local format
		local minutes = (seconds / 60) - (seconds / 60) % 1
		seconds = (seconds / 60 % 1 * 60) - (seconds / 60 % 1 * 60) % 1
		if math.floor(minutes/10) == 0 then
			format = '0' .. minutes .. ':'
		else
			format = minutes .. ':'
		end
		if math.floor(seconds/10) == 0 then
			format = format .. '0' .. seconds
		else
			format = format .. seconds
		end
		return format
	else
		local format
		if math.floor(seconds/10) == 0 then
			format = '0' .. seconds
		else
			format = seconds
		end
		return '00:' .. format
	end
end

---格式：00:00:00 前面的00会保留
function _G.ToTimingFormat3(seconds)  
	if seconds > 3600 then
		local format
		local hour = seconds/3600 - (seconds/3600) % 1
		local min =  seconds / 3600 % 1 * 60 * 60
		if math.floor(hour/10) == 0 then
			format = '0' .. hour .. ':'
		else
			format = hour .. ':'
		end
		local minutes = (min / 60) - (min / 60) % 1
		seconds = (min / 60 % 1 * 60) - (min / 60 % 1 * 60) % 1
		if math.floor(minutes/10) == 0 then
			format = format .. '0' .. minutes .. ':'
		else
			format = format .. minutes .. ':'
		end
		if math.floor(seconds/10) == 0 then
			format = format .. '0' .. seconds
		else
			format = format .. seconds
		end
		return format
	elseif seconds > 60 then
		local format
		local minutes = (seconds / 60) - (seconds / 60) % 1
		seconds = (seconds / 60 % 1 * 60) - (seconds / 60 % 1 * 60) % 1
		if math.floor(minutes/10) == 0 then
			format = '00:0' .. minutes .. ':'
		else
			format = '00:' .. minutes .. ':'
		end
		if math.floor(seconds/10) == 0 then
			format = format .. '0' .. seconds
		else
			format = format .. seconds
		end
		return format
	else
		local format
		if math.floor(seconds/10) == 0 then
			format = '0' .. seconds
		else
			format = seconds
		end
		return '00:00:' .. format
	end
end

--格式：00:00:00:00 时:分:秒:10毫秒
function _G.ToTimingFormat4(miliSeconds)
	local tenMiliSeconds = math.floor((miliSeconds % 1000) / 10)
	local seconds = math.floor(miliSeconds / 1000)
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)
	
	return string.format('%02d:%02d:%02d:%02d', hours % 100, minutes % 60, seconds % 60, tenMiliSeconds)
end

function _G.TimeToDate2(t, s)
	local d = _time(t)
	if not s  or s == "sec" then
		return string.format('%04d-%02d-%02d %02d-%02d-%06.3f',d.year,d.month,d.day,d.hour,d.min,d.sec)
	elseif s == 'day' then
		return string.format('%04d-%02d-%02d',d.year,d.month,d.day)
	elseif s == 'hour' then
		return string.format('%04d-%02d-%02d %02d',d.year,d.month,d.day,d.hour)
	elseif s == 'min' then
		return string.format('%04d-%02d-%02d %02d-%02d',d.year,d.month,d.day,d.hour,d.min)
	end
end

function _G.TimeToDate3(t, s)
	local d = _time(t)
	if not s  or s == "sec" then
		return string.format('%04d/%02d/%02d %02d/%02d/%06.3f',d.year,d.month,d.day,d.hour,d.min,d.sec)
	elseif s == 'day' then
		return string.format('%04d/%02d/%02d',d.year,d.month,d.day)
	elseif s == 'hour' then
		return string.format('%04d/%02d/%02d %02d',d.year,d.month,d.day,d.hour)
	elseif s == 'min' then
		return string.format('%04d/%02d/%02d %02d:%02d',d.year,d.month,d.day,d.hour,d.min)
	end
end

function _G.TimeToDate4(t, s)
	local d = _time(t)
	if not s  or s == "sec" then
		return string.format('%04d.%02d.%02d %02d.%02d.%06.3f',d.year,d.month,d.day,d.hour,d.min,d.sec)
	elseif s == 'day' then
		return string.format('%04d.%02d.%02d',d.year,d.month,d.day)
	elseif s == 'hour' then
		return string.format('%04d.%02d.%02d %02d',d.year,d.month,d.day,d.hour)
	elseif s == 'min' then
		return string.format('%04d.%02d.%02d %02d:%02d',d.year,d.month,d.day,d.hour,d.min)
	end
end
--endregion