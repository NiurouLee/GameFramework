---@class StateAVGStoryNext : StateAVGStoryBase
_class("StateAVGStoryNext", StateAVGStoryBase)
StateAVGStoryNext = StateAVGStoryNext

function StateAVGStoryNext:OnEnter(TT, ...)
    self:Init()
    self._storyManager = self.data:StoryManager()
    local paragraphIdTarget, sectionIdxTarget = self:GetNext()
    if paragraphIdTarget and sectionIdxTarget then
        self:JumpTo()
    else
        if self.data.notRemindJump then
            self:JumpTo()
        else
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.OkCancel, --1
                "", --2
                StringTable.Get("str_avg_n20_jump_2_next_story"), --3
                function()
                    self:JumpTo()
                end, --4
                nil, --5
                function()
                    self:ChangeState(StateAVGStory.Play)
                end, --6
                nil, --7
                nil, --8
                nil, --9
                nil, --10
                function()
                    self.data.notRemindJump = true
                end --11
            )
        end
    end
end

function StateAVGStoryNext:OnExit(TT)
end

-- function StateAVGStoryNext:OnUpdate(deltaTimeMS)
--     self:UpdateDriveByState(deltaTimeMS)
-- end

function StateAVGStoryNext:JumpTo()
    self.key = "StateAVGStoryNextOnEnter"
    GameGlobal.UIStateManager():Lock(self.key)
    local lastParagraphId, lastSectionIdx = self:GetLast()
    self._storyManager:JumpTo(lastParagraphId, lastSectionIdx)
    GameGlobal.UIStateManager():UnLock(self.key)
    self:ChangeState(StateAVGStory.Play)
end

---@return number, number 获取本story下一个有选项的段落id，小节index;
function StateAVGStoryNext:GetNext()
    local storyId = self._storyManager:GetCurStoryID()
    local node = self.data:GetNodeByStoryId(storyId)
    local curParagraphId = self._storyManager:GetCurParagraphID()
    local curSectionIdx = self._storyManager:GetCurSectionIndex()
    for _, paragraph in ipairs(node.paragraphs) do
        if paragraph.id >= curParagraphId then
            for _, dialog in ipairs(paragraph.dialogs) do
                if dialog.sectionIdx > curSectionIdx then
                    local visibleOptions = dialog:GetVisibleOptions()
                    if visibleOptions and table.count(visibleOptions) > 0 then
                        return paragraph.id, dialog.sectionIdx
                    end
                end
            end
        end
    end
end
---@return number, number 获取本story最后一个段落id，小节index
function StateAVGStoryNext:GetLast()
    local storyId = self._storyManager:GetCurStoryID()
    local node = self.data:GetNodeByStoryId(storyId)
    local lenParagraph = table.count(node.paragraphs)
    local lastParagraph = node.paragraphs[lenParagraph]
    local lenDialog = table.count(lastParagraph.dialogs)
    local lastDialog = lastParagraph.dialogs[lenDialog]
    local lastParagraphId, lastSectionIdx = lastParagraph.id, lastDialog.sectionIdx
    return lastParagraphId, lastSectionIdx
end
