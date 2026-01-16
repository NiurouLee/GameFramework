--[[------------------------------------------------------------------------------------------
    ICustomNode
]]--------------------------------------------------------------------------------------------
---@class ICustomNode:Object
_class( "ICustomNode", Object )
ICustomNode = ICustomNode

function ICustomNode:InitializeNode(staticConfig, runtimeContext)end

function ICustomNode:Activate() end

function ICustomNode:Deactivate() end

function ICustomNode:IsActive() end


---@class CustomNodeContext:Object
_class( "CustomNodeContext", Object )
CustomNodeContext = CustomNodeContext

function CustomNodeContext:Constructor(genInfo, rootNode, configMng)
    self.GenInfo = genInfo
    ---@type CustomLogic
    self.Logic = rootNode
    self.ConfigMng = configMng
    self.World=genInfo.World
end


--[[------------------------------------------------------------------------------------------
    CustomNode
]]--------------------------------------------------------------------------------------------

---@class CustomNode:ICustomNode
_class( "CustomNode", ICustomNode )
CustomNode = CustomNode

function CustomNode:Constructor()
    self.isActive = false
    self.varLibRef = nil
end

function CustomNode:Destroy()
    self:Deactivate()
    self.varLibRef = nil
end

---@param cfg table
---@param context CustomNodeContext
function CustomNode:InitializeNode(cfg, context)
    self.varLibRef = context.Logic.varLibImp
    self.Config = cfg
    self.Logic = context.Logic
end

function CustomNode:Activate()
    self.isActive = true
end

function CustomNode:Deactivate()
    self.isActive = false
end

function CustomNode:IsActive()
    return self.isActive
end

---@param interfaceList ArrayList
---@param funcName string
function CustomNode:CollectInterface(interfaceList, funcName)
    if self[funcName] then
        interfaceList:PushBack(self)
    end
end

---@param interfaceList ArrayList
---@param funcName string
function CustomNode:CollectInterfaceInChildren(interfaceList, funcName)
    --如果有子节点，重载实现这个方法
end

function CustomNode:Parse(param)
    if not param then
        return nil
    end
    if type(param) == 'string' then
        --如果带有前缀，说明是需要将其作为Key去黑板中读取数据
        local i,j = string.find(param, "BB#")
        if not j then
            return param
        else
            local bb_key = string.sub(param, j+1, -1)
            return self.varLibRef[bb_key]
        end
    else
        return param
    end
end

function CustomNode:CloneVarLibRef()
    local cloned = {}
    for k,v in pairs(self.varLibRef) do
        cloned[k] = v
    end
    return cloned
end


