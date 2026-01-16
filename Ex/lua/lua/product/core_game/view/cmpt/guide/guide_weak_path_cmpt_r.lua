--[[------------------------------------------------------------------------------------------
    GuideWeakPathComponent : 弱划线引导组件
]] --------------------------------------------------------------------------------------------

---@class GuideWeakPathComponent: Object
_class("GuideWeakPathComponent", Object)

function GuideWeakPathComponent:Constructor()
    self._guidePath = {}
    self._refreshType = GuideRefreshType.None
end

---@return GuideRefreshType
function GuideWeakPathComponent:GetGuideRefreshType()
    return self._refreshType
end

function GuideWeakPathComponent:SetGuideRefreshType(refreshType)
    self._refreshType = refreshType
    --Log.fatal("SetGuideRefreshType",refreshType," frame",UnityEngine.Time.frameCount,Log.traceback())
end

function GuideWeakPathComponent:SetGuidePath(path)
    self._guidePath = {}
    ---要引导的路径点
    for k, v in ipairs(path) do
        self._guidePath[#self._guidePath + 1] = v
    end
end

function GuideWeakPathComponent:GetGuidePath()
    return self._guidePath
end

---当前划线点是否和指定的引导路径点匹配
function GuideWeakPathComponent:IsMatchGuidePath(chainPath)
    --return self._guidePath
end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function GuideWeakPathComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function GuideWeakPathComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end ---@return GuideWeakPathComponent
--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
function Entity:GuideWeakPath()
    return self:GetComponent(self.WEComponentsEnum.GuideWeakPath)
end

function Entity:HasGuideWeakPath()
    return self:HasComponent(self.WEComponentsEnum.GuideWeakPath)
end

function Entity:AddGuideWeakPath(newPath)
    local index = self.WEComponentsEnum.GuideWeakPath
    local component = GuideWeakPathComponent:New(newPath)
    self:AddComponent(index, component)
end

function Entity:ReplaceGuideWeakPath()
    local index = self.WEComponentsEnum.GuideWeakPath
    local cmpt = self:GuideWeakPath()
    self:ReplaceComponent(index, cmpt)
end

function Entity:RemoveGuideWeakPath()
    if self:HasGuideWeakPath() then
        self:RemoveComponent(self.WEComponentsEnum.GuideWeakPath)
    end
end
