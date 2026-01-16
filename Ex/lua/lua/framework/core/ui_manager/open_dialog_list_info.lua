--[[
    OpenDialogListInfo : 切换UIState同时打开多层dialog的所需参数
]]

---@class OpenDialogListInfo: Object
_class( "OpenDialogListInfo", Object )
OpenDialogListInfo = OpenDialogListInfo

function OpenDialogListInfo:Constructor()
    ---@type table<number, table<string, table<number, object>>> ui信息 {序号,{ui名,{参数列表}}}
    self._uiList = {}
end

function OpenDialogListInfo:AddUIInfo(uiname, ...)
    self._uiList[#self._uiList + 1] = {uiname, {...}}
end

function OpenDialogListInfo:GetUIList()
    return self._uiList
end