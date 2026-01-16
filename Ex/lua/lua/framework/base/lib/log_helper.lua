---@param args table
---@param split string
---@return string
local args2str = function(args, split)
	local len = table.maxn(args)
	if len == 0 then
		return ''
	elseif len == 1 then
		return tostring(args[1])
	else
		local tb = {}
		if split == nil then
			for i = 1, len do
				table.insert(tb, tostring(args[i]))
			end
		else
			table.insert(tb, tostring(args[1]))
			for i = 2, len do
				table.insert(tb, split)
				table.insert(tb, tostring(args[i]))
			end
		end
		return table.concat(tb)
	end
end
local traceback = debug.traceback
--local _iowrite = _iowrite
local nowtime = {}
local dumpvisited
local dumpfrom = ""

local function indented(level, ...)
    -- if PUBLIC then return end
    --logdebug(table.concat({ ('  '):rep(level), ...}))
    local s = table.concat({("  "):rep(level), ...})
    table.insert(tsss, s)
end
local function dumpval(level, name, value, limit)
    local index
    if type(name) == "number" then
        index = string.format("[%d] = ", name)
    elseif
        type(name) == "string" and
            (name == "__VARSLEVEL__" or name == "__ENVIRONMENT__" or name == "__GLOBALS__" or name == "__UPVALUES__" or
                name == "__LOCALS__")
     then
        --ignore these, they are debugger generated
        return
    elseif type(name) == "string" and string.find(name, "^[_%a][_.%w]*$") then
        index = name .. " = "
    else
        index = string.format("[%q] = ", tostring(name))
    end
    if type(value) == "table" then
        if dumpvisited[value] then
            indented(level, index, string.format("ref%q,", dumpvisited[value]))
        else
            dumpvisited[value] = tostring(value)
            if (limit or 0) > 0 and level + 1 >= limit then
                indented(level, index, dumpvisited[value])
            else
                indented(level, index, "{  -- ", dumpvisited[value])
                for n, v in pairs(value) do
                    dumpval(level + 1, n, v, limit)
                end
                dumpval(level + 1, ".meta", getmetatable(value), limit)
                indented(level, "},")
            end
        end
    else
        if type(value) == "string" then
            if string.len(value) > 40 then
                indented(level, index, "[[", value, "]];")
            else
                indented(level, index, string.format("%q", value), ",")
            end
        else
            indented(level, index, tostring(value), ",")
        end
    end
end

local function dumpvar(value, limit, name)
    dumpvisited = {}
    dumpval(0, name or tostring(value), value, limit)
    dumpvisited = nil
end

---@class ELogLevel
ELogLevel = {
    All = 0, -- 不过滤
    Trace = 1, -- 函数出入口
    Debug = 2, -- 调试
    Info = 3, --重要信息
    Warning = 4, -- 警告
    Error = 5, --错误
    Fatal = 6, -- 致命错误
    Exception = 7,
    None = 8 -- 全过滤
}

debug.dumpdepth = 5
function dump(v, depth)
    -- if PUBLIC then return end
    if Log.loglevel > ELogLevel.Debug then
        return
    end
    local info = debug.getinfo(2)
    dumpfrom = info.source .. "|" .. info.currentline --info.currentline
    _G.tsss = {}
    dumpvar(v, (depth or debug.dumpdepth) + 1, tostring(v))
    local file = string.match(info.short_src, "([%w_]+%.%w+)$")
    logdebug(args2str({"[dump] ", file, ":", info.currentline, "\t", table.concat(_G.tsss, "\n")}))
end

Log = {}
Log.loglevel = ELogLevel.Debug
Log.loglevel_table = ELogLevel

Log.logkeys = {}
Log.enableassert = false
Log.enableexception = false
Log.enableprofile = false

Log.init = function()
	Log.setkey('assert', true)
	Log.setkey('exception', true)
	Log.setkey('profile', true)
end

Log.setlevel = function(level)
	if level and LogWrapper.GetLevel() ~= level then
		LogWrapper.SetLevel(level)
		level = LogWrapper.GetLevel()
		if level == 'all' then
			Log.loglevel = ELogLevel.All
		elseif level == 'trace' then
			Log.loglevel = ELogLevel.Trace
		elseif level == 'debug' then
			Log.loglevel = ELogLevel.Debug
		elseif level == 'info' then
			Log.loglevel = ELogLevel.Info
		elseif level == 'warning' then
			Log.loglevel = ELogLevel.Warning
		elseif level == 'error' then
			Log.loglevel = ELogLevel.Error
		elseif level == 'fatal' then
			Log.loglevel = ELogLevel.Fatal
		elseif level == 'exception' then
			Log.loglevel = ELogLevel.Exception
		elseif level == 'none' then
			Log.loglevel = ELogLevel.None
		end
	end
end

Log.setpath = function(path)
	if path and LogWrapper.GetPath() ~= path then
		LogWrapper.SetPath(path)
	end
end

Log.setconsole = function(enable)
	if enable and LogWrapper.GetConsole() ~= enable then
		LogWrapper.SetConsole(enable)
	end
end

Log.setkey = function(key, enable)
	if key then
		LogWrapper.SetKey(key, enable)
		if enable then
			Log.logkeys[key] = true
			if key == 'assert' then Log.enableassert = true
			elseif key == 'exception' then Log.enableexception = true
			elseif key == 'profile' then Log.enableprofile = true
			end
		else
			Log.logkeys[key] = nil
			if key == 'assert' then Log.enableassert = false
			elseif key == 'exception' then Log.enableexception = false
			elseif key == 'profile' then Log.enableprofile = false
			end
		end
	end
end

Log.getkey = function(key)
	if key then
		return Log.logkeys[key] == true
	end
	return false
end

Log.resetkeys = function()
	LogWrapper.ResetKeys()
	Log.logkeys = {}
end

Log.enablelevel = function(level)
	return Log.loglevel <= level
end



Log.sys = function(...)
	if not Log.enablelevel(ELogLevel.Info) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	logtrace(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.traceback = function(thread, message, level)
	if not Log.enablelevel(ELogLevel.Debug) then return end
    	return traceback(thread, message, level)
end

Log.debug = function(...)
	if not Log.enablelevel(ELogLevel.Debug) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	logdebug(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.notice = function(...)
	if not Log.enablelevel(ELogLevel.Info) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
    	local logContent = "<color=#FFD700><b>" .. args2str({file, ":", info.currentline, "\t", ...}) .. "</b></color>"
    	logdebug(logContent)
end

Log.warn = function(...)
	if not Log.enablelevel(ELogLevel.Warning) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	logwarn(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.error = function(...)
	if not Log.enablelevel(ELogLevel.Error) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	logerror(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.info = function(...)
	if not Log.enablelevel(ELogLevel.Info) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
    	loginfo(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.fatal = function(...)
	if not Log.enablelevel(ELogLevel.Fatal) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
    	logfatal(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.assert = function(cond, ...)
	if cond == true then
		return 
	end
	if not Log.enableexception then return end
	if not Log.enablelevel(ELogLevel.Exception) then return end
    	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	
	local csui = UnityEngine.GameObject.Find("CSUI")
    if csui then
        local csuiTran = csui.transform
        local cameraFrameworkTran = csuiTran:Find("FrameworkUI/CameraFramework")
        if cameraFrameworkTran then
            local cameraFramework = cameraFrameworkTran:GetComponent("Camera")
            if cameraFramework then
                cameraFramework.enabled = true
            end
        end
    end

	logexception(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.exception = function(...)
	if not Log.enableexception then return end
	if not Log.enablelevel(ELogLevel.Exception) then return end
    	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	
	local csui = UnityEngine.GameObject.Find("CSUI")
    if csui then
        local csuiTran = csui.transform
        local cameraFrameworkTran = csuiTran:Find("FrameworkUI/CameraFramework")
        if cameraFrameworkTran then
            local cameraFramework = cameraFrameworkTran:GetComponent("Camera")
            if cameraFramework then
                cameraFramework.enabled = true
            end
        end
    end

	logexception(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.showexception = function(msg, path)
	PopupManager.Alert("UICommonMessageBox", PopupPriority.System, PopupMsgBoxType.Ok, "", msg)
end

Log.key = function(key, ...)
	if not Log.getkey(key) then return end
	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	logkey(key, args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

Log.prof = function(...)
    	if not _G.EnalbeProfLog then 
        	return 
    	end
    
    	if not Log.enableprofile then return end
    
    	if not Log.enablelevel(ELogLevel.Fatal) then return end

	local info = debug.getinfo(2)
	local file = string.match(info.short_src, '([%w_]+%.%w+)$')
	logprof(args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
end

local programmers = {'ylw', 'yqq', 'zn', 'cj'}
for i, v in pairs(programmers) do
	_G['_' .. v] = function(...)
		-- if PUBLIC then return end
		if not Log.enablelevel(ELogLevel.Info) then return end
		if not Log.getkey(v) then return end
		local info = debug.getinfo(2)
		local file = string.match(info.short_src, '([%w_]+%.%w+)$')
		logkey(v, args2str({file, ':', info.currentline, '\t', args2str({...}, ' ')}))
	end
end

---禁掉print
print = function()
	error('print is forbidden')
end

debug.traceback = function(...)
    return Log.traceback(...)
end
