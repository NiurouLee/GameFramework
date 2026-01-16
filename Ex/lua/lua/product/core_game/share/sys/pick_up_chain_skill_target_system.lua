--[[------------------------------------------------------------------------------------------
    等待拾取连锁技目标 PickUpChainSkillTargetSystem
]] --------------------------------------------------------------------------------------------

---这个系统不会在服务端运行，客户端也只用来设置状态，因此代码保持原状，没有做C/S分离
---@class PickUpChainSkillTargetSystem:UniqueReactiveSystem
_class("PickUpChainSkillTargetSystem", UniqueReactiveSystem)

function PickUpChainSkillTargetSystem:Constructor(world)

end

function PickUpChainSkillTargetSystem:IsInterested(index, previousComponent, component)
    if component == nil then
        return false
    end
    if not GameFSMComponent:IsInstanceOfType(component) then
        return false
    end
    if component:CurStateID() == GameStateID.WaitInputChain then
        return true
    end
    return false
end

function PickUpChainSkillTargetSystem:Filter(world)
    return true
end

function PickUpChainSkillTargetSystem:ExecuteWorld(world)
    self._world = world
end
