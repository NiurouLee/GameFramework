--[[------------------------------------------------------------------------------------------
    GuidePathComponent : 划线引导组件
]] --------------------------------------------------------------------------------------------

---@class GuidePathComponent: Object
_class("GuidePathComponent", Object)

function GuidePathComponent:Constructor()
    self._guidePath = {}
    self._refreshType = GuideRefreshType.None
    self._invokeType = GuideInvokeType.None
end

function GuidePathComponent:GetInvokeType()
    return self._invokeType
end

function GuidePathComponent:SetInvokeType(invokeType)
    self._invokeType = invokeType
end

---@return GuideRefreshType
function GuidePathComponent:GetGuideRefreshType()
    return self._refreshType
end

function GuidePathComponent:SetGuideRefreshType(refreshType)
    self._refreshType = refreshType
    --Log.fatal("SetGuideRefreshType",refreshType," frame",UnityEngine.Time.frameCount,Log.traceback())
end

function GuidePathComponent:SetGuidePath(path)
    self._guidePath = {}
    ---要引导的路径点
    for k, v in ipairs(path) do
        local vec = Vector2(v[1], v[2])
        self._guidePath[#self._guidePath + 1] = vec
    end
end

function GuidePathComponent:GetGuidePath()
    return self._guidePath
end

---当前划线点是否和指定的引导路径点匹配
function GuidePathComponent:IsMatchGuidePath(chainPath)
    --return self._guidePath
end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function GuidePathComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function GuidePathComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end ---@return GuidePathComponent
--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] function Entity:GuidePath()
    return self:GetComponent(self.WEComponentsEnum.GuidePath)
end

function Entity:HasGuidePath()
    return self:HasComponent(self.WEComponentsEnum.GuidePath)
end

function Entity:AddGuidePath(newPath)
    local index = self.WEComponentsEnum.GuidePath
    local component = GuidePathComponent:New(newPath)
    self:AddComponent(index, component)
end

function Entity:ReplaceGuidePath()
    local index = self.WEComponentsEnum.GuidePath
    local cmpt = self:GuidePath()
    self:ReplaceComponent(index, cmpt)
end

function Entity:RemoveGuidePath()
    if self:HasGuidePath() then
        self:RemoveComponent(self.WEComponentsEnum.GuidePath)
    end
end
