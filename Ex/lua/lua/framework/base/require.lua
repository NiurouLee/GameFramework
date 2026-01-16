--lua 版require和requireall实现，想脱离unity引擎跑lua代码做测试的话，打开下面这段代码，然后去拿带有lfs的luadll，p4路径：//h3d_mobile/unity_lua/tests/tools/lua版本requiredll/tolua.dll
--[[local originalPath  = lfs.currentdir()
local filePaths = {}
local luaPath = originalPath .. "\\PublishResources\\lua" -- "E:\\h3d_mobile\\unity_lua\\tests\\unity_lua\\client\\PublishResources\\lua"
local ignoreDir = {"unit_test", "PublishResources\\lua\\lua_api"}
function SearchforStringInWhichFile (path)
	for file in lfs.dir(path) do
		if file ~= "." and file ~= ".." then
			local f = path..'\\'..file
			local attr = lfs.attributes (f) 
			assert (type(attr) == "table")
			if attr.mode == "directory" then
				SearchforStringInWhichFile(f) 
			elseif attr.mode == "file" then
				local bfind = false
				for _, ignore in next, ignoreDir do
					if string.find(f, ignore) then
						bfind = true
						break
					end
				end
				if not bfind then
					local _, _, head = string.find(file, "(.*)%.lua$")
					if head then
						local _, _, p = string.find(f, "(PublishResources.*)%.lua$")
						filePaths[string.lower(head)] = p
					end
				end
			end
		end
	end
end
SearchforStringInWhichFile(luaPath)

local oldRequire = require

function require(name)
	local path = filePaths[name]
	if not path then
		return oldRequire(name)
	else
		return oldRequire(path)
	end
end

local excludeFiles = {"start", "launch"}
function LuaRequireAll(excludeDir)
	for file, path in pairs(filePaths) do
		local bfind = false
		for _, exclude in next, excludeDir do
			if string.find(path, exclude) then
				bfind = true
				break
			end
		end
		if not bfind then
			local b = false;
			for _, v in next, excludeFiles do
				if string.find(file, v) then
					b = true;
					break;
				end
			end
			if not b then
				local ok, err = pcall(oldRequire, path)
				if not ok then
					Log.fatal(err)
				end
			end
		end
	end
end
]]--