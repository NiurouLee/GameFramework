--[[------------------------------------------------------------------------------------------
    CustomNode Static
]]--------------------------------------------------------------------------------------------
require "algorithm"
require "array_list"
require "sorted_array"
require "sorted_dictionary"

_staticClass("CustomNodeStatic")
---@param interfaceList ArrayList
---@param funcName string
---@param obj ICustomNode
function CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, node)
    if node == nil then
        return
    end
    if node.CollectInterface then
        node:CollectInterface(interfaceList, funcName)
    end
    if node.CollectInterfaceInChildren then
        node:CollectInterfaceInChildren(interfaceList, funcName)
    end
end


--[[------------------------------------------------------------------------------------------
    CustomNodeConfig Static
]]--------------------------------------------------------------------------------------------
_staticClass("CustomNodeConfigStatic")

--这里定义节点静态配置基本正确性的检验函数
CustomNodeConfigStatic.NodeConfigChecker = SortedDictionary:New()

function CustomNodeConfigStatic.AddChecker(nodeType, cfgCheckFunc)
    CustomNodeConfigStatic.NodeConfigChecker:Insert(nodeType, cfgCheckFunc)
end


--[[------------------------------------------------------------------------------------------
    CLHelper Static
]]--------------------------------------------------------------------------------------------
CLHelper = {}

function CLHelper.Assert(condition, logMsg)
    if condition then
        return true
    end
    if logMsg then
        Log.fatal(logMsg)
    end
    assert(condition)
    return false
end