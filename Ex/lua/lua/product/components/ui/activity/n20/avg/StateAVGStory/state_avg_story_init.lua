---@class StateAVGStoryInit : StateAVGStoryBase
_class("StateAVGStoryInit", StateAVGStoryBase)
StateAVGStoryInit = StateAVGStoryInit

function StateAVGStoryInit:OnEnter(TT, ...)
    self.key = "StateAVGStoryInitOnEnter"
    GameGlobal.UIStateManager():Lock(self.key)
    self:Init()
    self:InitStoryManager()
    self.data:InitNodes()
    self:ClearPassSectionIds() --重置passSectionIds
    self.ui:ClearSelectedOptionIds()
    local nodeId = self:NodeId()
    local node = self.data:GetNodeById(nodeId)
    self:NextNodeId(node.defaultNextId) ---初始化下一个结点id
    self:HandleSetCurrentLocation(
        TT,
        node.id,
        function()
            self.fsm:ChangeState(StateAVGStory.Play)
        end
    )
    AVGLog("------------Story start------------", nodeId, node.storyId)
end

function StateAVGStoryInit:OnExit(TT)
    GameGlobal.UIStateManager():UnLock(self.key)
end
