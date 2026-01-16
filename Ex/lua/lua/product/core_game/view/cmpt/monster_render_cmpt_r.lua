--[[
    MonsterRenderComponent : 用于存储怪物表现数据的组件
]]

---@class MonsterRenderComponent: Object
_class( "MonsterRenderComponent", Object )
MonsterRenderComponent = MonsterRenderComponent

function MonsterRenderComponent:Constructor()

end


---@param owner Entity
function MonsterRenderComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function MonsterRenderComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end



--[[
    Entity Extensions
]]
---@return MonsterRenderComponent
function Entity:MonsterRender()
    return self:GetComponent(self.WEComponentsEnum.MonsterRender)
end


function Entity:HasMonsterRender()
    return self:HasComponent(self.WEComponentsEnum.MonsterRender)
end


function Entity:AddMonsterRender()
    local index = self.WEComponentsEnum.MonsterRender;
    local component = MonsterRenderComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplaceMonsterRender()
    local index = self.WEComponentsEnum.MonsterRender;
    local component = MonsterRenderComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemoveMonsterRender()
    if self:HasMonsterRender() then
        self:RemoveComponent(self.WEComponentsEnum.MonsterRender)
    end
end