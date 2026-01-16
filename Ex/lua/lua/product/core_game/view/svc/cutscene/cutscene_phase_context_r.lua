--[[------------------------------------------------------------------------------------------
    CutscenePhaseContext：单个phase的上下文，存储临时数据
]] --------------------------------------------------------------------------------------------

_class("CutscenePhaseContext", Object)
---@class CutscenePhaseContext: Object
CutscenePhaseContext = CutscenePhaseContext

function CutscenePhaseContext:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---等待队列，应该是极少会用到，目前有击退
    self._waitTaskList = {}
end

function CutscenePhaseContext:GetCutsceneWorld()
    return self._world
end

function CutscenePhaseContext:AddPhaseTask(taskID)
    self._waitTaskList[#self._waitTaskList + 1] = taskID
end

function CutscenePhaseContext:GetPhaseTaskList()
    return self._waitTaskList
end