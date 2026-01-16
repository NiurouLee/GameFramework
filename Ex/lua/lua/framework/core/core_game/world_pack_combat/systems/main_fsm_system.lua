
---@class MainFSMSystem:Object
_class( "MainFSMSystem", Object )

---@param world World
function MainFSMSystem:Constructor(world)
    self.world = world
    self.group = world:GetGroup(world.BW_WEMatchers.MainFSM)
end

function MainFSMSystem:Execute()
    self.group:HandleForeach(self, self.UpdateFSM)
end

---@param e Entity
function MainFSMSystem:UpdateFSM(e)
    local component = e:MainFSM()
    local deltaTime = 0.03
    component:Update(deltaTime)
end