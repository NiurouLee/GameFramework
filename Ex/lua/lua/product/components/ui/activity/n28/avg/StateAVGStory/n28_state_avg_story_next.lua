---@class N28StateAVGStoryNext : N28StateAVGStoryBase
_class("N28StateAVGStoryNext", N28StateAVGStoryBase)
N28StateAVGStoryNext = N28StateAVGStoryNext

function N28StateAVGStoryNext:OnEnter(TT, ...)
    self:Init()
    self.uiDialog = table.unpack({...})
    self._storyManager = self.data:StoryManager()
    -- local paragraphIdTarget, sectionIdxTarget = self:GetNext()
    -- if paragraphIdTarget and sectionIdxTarget then
    --     self:JumpTo()
    -- else

    -- end
    if self.data.notRemindJump then
        self:JumpTo()
    else
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel, --1
            "", --2
            StringTable.Get("str_avg_n28_jump_2_next_story"), --3
            function()
                self:JumpTo()
            end, --4
            nil, --5
            function()
                self:ChangeState(N28StateAVGStory.Play)
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

function N28StateAVGStoryNext:OnExit(TT)
end

-- function N28StateAVGStoryNext:OnUpdate(deltaTimeMS)
--     self:UpdateDriveByState(deltaTimeMS)
-- end

function N28StateAVGStoryNext:JumpTo()
    local lastParagraphId, lastSectionIdx = self:GetLast()
    local curParagraphId = self._storyManager:GetCurParagraphID()
    local curSectionIdx = self._storyManager:GetCurSectionIndex()
    if curParagraphId == lastParagraphId and lastSectionIdx <= curSectionIdx then
        self:ChangeState(N28StateAVGStory.Play)
        return
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28AVGJumpDialog)
    self:ShowJumpAnim(function()
        self._storyManager:JumpTo(lastParagraphId, lastSectionIdx)
        self:ChangeState(N28StateAVGStory.Play)
        self.ui:ShowHideJumpBtn(false)
    end)
end

---@return number, number 获取本story下一个有选项或举证的段落id，小节index;
function N28StateAVGStoryNext:GetNext()
    local storyId = self._storyManager:GetCurStoryID()
    local node = self.data:GetNodeByStoryId(storyId)
    local curParagraphId = self._storyManager:GetCurParagraphID()
    local curSectionIdx = self._storyManager:GetCurSectionIndex()
    for _, paragraph in ipairs(node.paragraphs) do
        if paragraph.id >= curParagraphId then
            for _, dialog in ipairs(paragraph.dialogs) do
                if dialog.sectionIdx > curSectionIdx then
                    local visibleOptions = dialog:GetVisibleOptions()
                    local showEvidenceEvent = dialog:HaveShowEvienceEvent()
                    --选项
                    if visibleOptions and table.count(visibleOptions) > 0 then
                        return paragraph.id, dialog.sectionIdx
                    end
                    --举证
                    if showEvidenceEvent then
                        return paragraph.id, dialog.sectionIdx
                    end
                end
            end
        end
    end
end

---@return number, number 获取本story最后一个段落id，小节index
function N28StateAVGStoryNext:GetLast()
    local storyId = self._storyManager:GetCurStoryID()
    local node = self.data:GetNodeByStoryId(storyId)
    -- for _, v in pairs(node.paragraphs) do
    --     if v.isEnd then
    --         local lenDialog = table.count(v.dialogs)
    --         local lastDialog = v.dialogs[lenDialog]
    --         local lastParagraphId, lastSectionIdx = v.id, lastDialog.sectionIdx
    --         return lastParagraphId, lastSectionIdx
    --     end
    -- end
    local lenParagraph = table.count(node.paragraphs)
    local lastParagraph = node.paragraphs[lenParagraph]
    local lenDialog = table.count(lastParagraph.dialogs)
    local lastDialog = lastParagraph.dialogs[lenDialog]
    local lastParagraphId, lastSectionIdx = lastParagraph.id, lastDialog.sectionIdx
    return lastParagraphId, lastSectionIdx
end
