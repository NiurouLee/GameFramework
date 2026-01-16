if UnityEngine.Application.isPlaying  and IsUnityEditor() then
	HotReload = {}

	HotReload.reloadUIController = function (filePath)
		local file = io.open(filePath, 'r')
		Log.debug("Reload lua ",filePath)
		if file then
			local content = file:read('a')
			file:close()

			local classNameList = ArrayList:New()
			for className in string.gmatch(content, [[_class%(%s*"(%w+)"]]) do
				classNameList:PushBack(className)
			end

			local isUIController = false
			for id=1, classNameList:Size() do
				if IsSubClassOf(classNameList:GetAt(id), "UIController") then
					isUIController = true

					break
				end
			end

			if not isUIController then
				return
			end

			for id=1, classNameList:Size() do
				_removeClass(classNameList:GetAt(id))
			end

			local fileName = HotReload.getLuaName(filePath)
			package.loaded[fileName] = nil
			require(fileName)
		end
	end

	HotReload.reloadConfig = function (filePath)
		local cfgName = HotReload.getLuaName(filePath)
		CfgClear(cfgName)

		-- 该配置因为在 C# 中也 require 了，所以此处需要特殊处理下
		if cfgName == "cfg_lod" then
			package.loaded[cfgName] = nil
			require(cfgName)
		end
	end

	-- 获取不带后缀的文件名
	HotReload.getLuaName = function (filePath)
		local _, _, fileName = string.find(filePath, "/([^/]+)%.lua$")
		return fileName
	end
end
