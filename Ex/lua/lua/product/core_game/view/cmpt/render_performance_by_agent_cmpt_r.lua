--[[
    RenderPerformanceByAgentComponent : （N29BOSS钻探者，本体隐藏，被击表现由指定的怪代替）
]]

---@class RenderPerformanceByAgentComponent: Object
_class( "RenderPerformanceByAgentComponent", Object )
RenderPerformanceByAgentComponent = RenderPerformanceByAgentComponent

---
function RenderPerformanceByAgentComponent:Constructor(agentEntityID)
    self._agentEntityID = agentEntityID
end
function RenderPerformanceByAgentComponent:GetAgentEntityID()
    return self._agentEntityID
end
---
---@param owner Entity
function RenderPerformanceByAgentComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end
---
function RenderPerformanceByAgentComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end



--[[
    Entity Extensions
]]
---@return RenderPerformanceByAgentComponent
function Entity:RenderPerformanceByAgent()
    return self:GetComponent(self.WEComponentsEnum.RenderPerformanceByAgent)
end

---
function Entity:HasRenderPerformanceByAgent()
    return self:HasComponent(self.WEComponentsEnum.RenderPerformanceByAgent)
end

---
function Entity:AddRenderPerformanceByAgent()
    local index = self.WEComponentsEnum.RenderPerformanceByAgent;
    local component = RenderPerformanceByAgentComponent:New()
    self:AddComponent(index, component)
end

---
function Entity:ReplaceRenderPerformanceByAgent(agentEntityID)
    local index = self.WEComponentsEnum.RenderPerformanceByAgent;
    local component = RenderPerformanceByAgentComponent:New(agentEntityID)
    self:ReplaceComponent(index, component)
end

---
function Entity:RemoveRenderPerformanceByAgent()
    if self:HasRenderPerformanceByAgent() then
        self:RemoveComponent(self.WEComponentsEnum.RenderPerformanceByAgent)
    end
end