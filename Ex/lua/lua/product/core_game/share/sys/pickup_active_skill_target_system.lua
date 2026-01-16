--[[------------------------------------------------------------------------------------------
    等待拾取主动技目标PickUpActiveSkillTargetSystem
]] --------------------------------------------------------------------------------------------

---这个系统不会在服务端运行，客户端也只用来设置状态，因此代码保持原状，没有做C/S分离
---@class PickUpActiveSkillTargetSystem:UniqueReactiveSystem
_class("PickUpActiveSkillTargetSystem", UniqueReactiveSystem)

function PickUpActiveSkillTargetSystem:Constructor(world)

end

function PickUpActiveSkillTargetSystem:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end

    if (not GameFSMComponent:IsInstanceOfType(component)) then
        return false
    end

    if (component:CurStateID() == GameStateID.PickUpActiveSkillTarget or component:CurStateID() ==GameStateID.PreviewActiveSkill ) then
        return true
    end
    return false
end

function PickUpActiveSkillTargetSystem:ExecuteWorld(world)
    self._world = world
    Log.notice("### PickUpActiveSkillSystem ExecuteWorld")
end

function PickUpActiveSkillTargetSystem:Filter(world)
    --Log.debug("WaitInputSystem Filter")
    return true
end
