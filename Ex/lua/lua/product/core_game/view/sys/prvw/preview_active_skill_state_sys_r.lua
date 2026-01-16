--[[------------------------------------------------------------------------------------------
    主状态机：主动技能预览阶段system
]]--------------------------------------------------------------------------------------------

---这个系统不会在服务端运行，客户端也只用来设置状态，因此代码保持原状，没有做C/S分离
---@class PreviewActiveSkillStateSystem_Render:UniqueReactiveSystem
_class("PreviewActiveSkillStateSystem_Render", UniqueReactiveSystem )
function PreviewActiveSkillStateSystem_Render:Constructor(world)
    self._world = world
end

function PreviewActiveSkillStateSystem_Render:TearDown()
    self._world = nil
end

function PreviewActiveSkillStateSystem_Render:IsInterested(index, previousComponent, component)
    if(component == nil) then
        return false;
    end

    if(not GameFSMComponent:IsInstanceOfType(component)) then
        return false;
    end

    if(component:CurStateID() == GameStateID.PreviewActiveSkill) then
        return true
    end
    return false
end


function PreviewActiveSkillStateSystem_Render:Filter(world)
    return true
end

function PreviewActiveSkillStateSystem_Render:ExecuteWorld(world)
    Log.notice("PreviewActiveSkillStateSystem_Render ExecuteWorld")
end

