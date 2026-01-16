--region N28AVGStoryNode 结点类
---@class N28AVGStoryNode:Object
---@field id number 结点Id
---@field defaultNextId number 默认后置结点id，-1表示没有后续结点
---@field endId number 如果是结局，则为结局Id；如果不是结局，为0
---@field storyId number 对应剧情Id
---@field pos number 结点坐标
---@field title number 结点标题
---@field desc number 结点描述
---@field hideEvidenceBook number 是否隐藏律师笔记
---@field cg number 结点详情界面的CG图，End结点的缩略图从AVGCGInfo中拿
---@field cgCanPlay number 未达成的结点详情界面的CG图，End结点的缩略图从AVGCGInfo中拿
---@field paragraphs N28AVGStoryParagraph[] 该结点段落列表
---@field hideVisibleCondition N28AVGCondition 【隐藏结点】的可见条件。nil为普通结点/结局结点；非nil为【隐藏结点】
---@field hideStartArchive number[] 隐藏结点的初始存档
---@field state N28AVGStoryNodeState 结点状态
_class("N28AVGStoryNode", Object)
N28AVGStoryNode = N28AVGStoryNode

function N28AVGStoryNode:Constructor()
    self.id = 0
    self.defaultNextId = -1
    self.endId = 0
    self.storyId = 0
    self.pos = Vector2.zero
    self.title = ""
    self.desc = ""
    self.cg = ""
    self.cgCanPlay = ""
    self.paragraphs = {}
    self.hideEvidenceBook = 1
    self.hideVisibleCondition = nil
    self.hideStartArchive = {}
    self.hideStartEvidences = {}
    self.state = nil

    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end

--region 根据剧情配置初始化
--剧情配置结构
--[[
storyConfig = {
    Paragraphs = { --段落结点
        [01] = { --段落索引
            Sections = { --小节结点
                [18] = { --小节索引
                    [01] = { --小节元素索引
                        DialogContentStr = "ui_story_1_4_A2_dialog_content", --有DialogContentStr表示该小节元素为对话
                        Options = { --选项结点
                            [01] = { --选项索引
                                Content = "ui_story_1_4_7_option_content", --选项内容
                                NextParagraphID = 2 --选项指向段落
                            },
                        }
                    }
                }
            }
        }
    }
}
]]
---@param cfgSectionExcel table cfg_component_avg_story_section
---@param cfgOptionExcel table cfg_component_avg_story_manual
function N28AVGStoryNode:Init(cfgSectionExcel, cfgOptionExcel)
    local storyManager = self.data:StoryManager()
    self.paragraphs = {}
    local cfgStory = storyManager._storyConfig
    local cfgParagraphs = cfgStory.Paragraphs
    for paragraphId, cfgParagraph in ipairs(cfgParagraphs) do
        local paragraph = N28AVGStoryParagraph:New()
        table.insert(self.paragraphs, paragraph) --insert段落-----------------------------------
        paragraph.id = paragraphId
        local cfgSections = cfgParagraph.Sections
        -- local lastSection = cfgSections[#cfgSections]
        -- for _, cfgSectionElement in ipairs(lastSection) do
        --     if cfgSectionElement.DialogContentStr then
        --         if cfgSectionElement.Events == nil and cfgSectionElement.Options == nil then
        --             paragraph.isEnd = true
        --         end
        --     else
        --         paragraph.isEnd = true
        --     end
        -- end
        for sectionIdx, cfgSection in ipairs(cfgSections) do
            for elementIdx, cfgSectionElement in ipairs(cfgSection) do
                if cfgSectionElement.DialogContentStr then --如果有DialogContentStr表示为对话
                    local dialog = N28AVGStoryDialog:New()
                    table.insert(paragraph.dialogs, dialog) --insert对话-----------------------------------
                    dialog.sectionIdx = sectionIdx
                    dialog.refEntityId = cfgSectionElement.RefEntityID
                    dialog.events = cfgSectionElement.Events or {}
                    --Execl配置
                    local cfgvSectionExcel =
                        self:GetCfgvSectionExcel(cfgSectionExcel, self.storyId, paragraphId, sectionIdx)
                    if cfgvSectionExcel then
                        dialog.id = cfgvSectionExcel.ID
                        dialog.beCondition = N28AVGCondition:New(cfgvSectionExcel.BECondition)
                        dialog.beId = cfgvSectionExcel.BE
                        dialog.valueChange = cfgvSectionExcel.ValueChange
                    end
                    --选项
                    local cfgOptions = cfgSectionElement.Options
                    if cfgOptions then
                        for optionIdx, cfgOption in ipairs(cfgOptions) do
                            local option = N28AVGStoryOption:New()
                            table.insert(dialog.options, option) --insert选项-----------------------------------
                            option.storyId = self.storyId
                            option.paragraphId = paragraphId
                            option.sectionIdx = sectionIdx
                            option.index = optionIdx
                            option.content = StringTable.Get(cfgOption.Content)
                            option.nextParagraphId = cfgOption.NextParagraphID
                            --Execl配置
                            local cfgvOptionExcel =
                                self:GetCfgvOptionExcel(
                                cfgOptionExcel,
                                self.storyId,
                                paragraphId,
                                sectionIdx,
                                optionIdx
                            )
                            if cfgvOptionExcel then
                                option.id = cfgvOptionExcel.ID
                                local influenceValue = cfgvOptionExcel.InfluenceValue
                                if influenceValue then
                                    for i, influence in ipairs(influenceValue) do
                                        if i == 1 then
                                            option.influenceLeader = influence
                                        else
                                            option.influencePartners[i - 1] = influence
                                        end
                                    end
                                end
                                local influence = cfgvOptionExcel.Influence
                                if influence then
                                    option.influence = StringTable.Get(influence)
                                end
                                local keyUnlockConditionDesc = cfgvOptionExcel.UnlockConditionDesc
                                if string.isnullorempty(keyUnlockConditionDesc) then
                                    option.unlockConditionDesc = ""
                                else
                                    option.unlockConditionDesc = StringTable.Get(keyUnlockConditionDesc)
                                end
                                option.unlockCondition = N28AVGCondition:New(cfgvOptionExcel.UnlockCondition, true) --默认true，解锁
                                option.visibleCondition = N28AVGCondition:New(cfgvOptionExcel.ShowCondition, true) --默认true，可见
                                option.nextNodeId = cfgvOptionExcel.NextNodeId or 0
                            -- else
                            --     AVGLog("GetCfgvOptionExcel failed.", self.storyId, paragraphId, sectionIdx, optionIdx)
                            end
                        end
                    end
                end
            end
        end
    end
    --存一份初始证据数据在这
    local hp, strategies, evidence = self:StartData()
    --节点的证据存档数据
    self.cacheUserEvidences = evidence
end
function N28AVGStoryNode:GetCfgvSectionExcel(cfgSectionExcel, storyId, paragraphId, sectionIdx)
    if cfgSectionExcel then
        for key, cfgv in pairs(cfgSectionExcel) do
            local sign = cfgv.SectionSign
            if sign[1] == storyId and sign[2] == paragraphId and sign[3] == sectionIdx then
                return cfgv
            end
        end
    end
end
function N28AVGStoryNode:GetCfgvOptionExcel(cfgOptionExcel, storyId, paragraphId, sectionIdx, optionIdx)
    if cfgOptionExcel then
        for key, cfgv in pairs(cfgOptionExcel) do
            local sign = cfgv.OptionSign
            if sign[1] == storyId and sign[2] == paragraphId and sign[3] == sectionIdx and sign[4] == optionIdx then
                return cfgv
            end
        end
    end
end
--endregion

---是否结局结点
function N28AVGStoryNode:IsEnd()
    return self.endId > 0
end

--region 隐藏结点
---@return boolean 是否隐藏结点
function N28AVGStoryNode:IsHide()
    if self.hideVisibleCondition then
        return true
    end
    return false
end
---@return boolean 隐藏结点是否有New标签——没点过的隐藏结点必定显示New，点过的隐藏结点会存在mission_datas中
function N28AVGStoryNode:IsHideNew()
    if self:IsHide() and self:IsSatisfyVisible() then
        local serverNodeInfo = self.data:GetServerNodeDataByNodeId(self.id)
        if serverNodeInfo then
            return serverNodeInfo.new_mark
        else
            return true
        end
    end
    return false
end
---@return boolean 隐藏结点是否满足可见条件
function N28AVGStoryNode:IsSatisfyVisible()
    if self:IsHide() then
        return self.hideVisibleCondition:IsSatisfy()
    end
    return true
end
---@return number, number[] 隐藏结点的数据
function N28AVGStoryNode:GetHideStartArchive()
    local hp = 0
    local strategies = {}
    if self.hideStartArchive then
        for index, value in ipairs(self.hideStartArchive) do
            if index == 1 then
                hp = value
            else
                table.insert(strategies, value)
            end
        end
    end
    return hp, strategies
end
--endregion
---@return number, number[] 隐藏结点的证据数据
function N28AVGStoryNode:GetHideStartEvidence()
    local hideStartEvidences = {}
    if self.hideStartEvidences then
        for _, value in ipairs(self.hideStartEvidences) do
            table.insert(hideStartEvidences, value)
        end
    end
    return hideStartEvidences
end

function N28AVGStoryNode:GetEvidenceData()
    return self.cacheUserEvidences
end

---@return number, number[] 获取本结点初始数据：主角血量，队员攻略度
function N28AVGStoryNode:StartData()
    local hp, strategies, evidences = 0, {}, {}
    if self:IsHide() then --隐藏结点使用配置的初始值
        for i, value in ipairs(self.hideStartArchive) do
            if i == 1 then
                hp = value
            else
                table.insert(strategies, value)
            end
        end
        evidences = self:GetHideStartEvidence()
    else
        local fstNodeId = self.data:FirstNodeId()
        if fstNodeId == self.id then --如果是第1个结点，初始数据即为default
            hp = self.data.actorLeader.default
            for index, partner in ipairs(self.data.actorPartners) do
                table.insert(strategies, partner.default)
            end
            evidences = self.data.defaultEvidences or {}
        else --非第1个结点
            local serNodeData = self.data:GetServerNodeDataByNodeId(self.id)
            if serNodeData then --如果有同步的数据，表示打过该结点，使用同步的值
                hp = serNodeData.end_formation_info.leader_hp
                strategies = serNodeData.end_formation_info.teammate_affinity
                evidences = serNodeData.end_formation_info.evidence
            end
        end
    end
    ---拷贝
    local strategiesCopy = {}
    for index, value in ipairs(strategies) do
        strategiesCopy[index] = value
    end
    local evidencesCopy = {}
    for index, value in ipairs(evidences) do
        evidencesCopy[index] = value
    end
    return hp, strategiesCopy, evidencesCopy
end

---@return number 获取存档时间戳
function N28AVGStoryNode:GetSaveTimestamp()
    if self.data:FirstNodeId() == self.id then --第1个结点
        return 0
    end
    if self:IsHide() then
        return 0
    end
    local serverNodeInfo = self.data:GetServerNodeDataByNodeId(self.id)
    if serverNodeInfo then
        return serverNodeInfo.update_time
    else
        return 0
    end
end

---@return boolean 结点是否完成
function N28AVGStoryNode:IsComplete()
    local info = self.data:GetComponentInfoAVG()
    if table.icontains(info.conplated_node_ids, self.id) then
        return true
    end
end

---@return N28AVGStoryNodeState 返回该结点状态
function N28AVGStoryNode:State()
    return self.state
end

---@return N28AVGStoryParagraph
function N28AVGStoryNode:GetParagraphByParagraphId(paragraphId)
    for index, paragraph in ipairs(self.paragraphs) do
        if paragraph.id == paragraphId then
            return paragraph
        end
    end
end

--- @class N28AVGStoryNodeState
---@field nil nil 不可见
---@field CantPlay number 可见不可打
---@field CanPlay number 可打
---@field Complete number 完成
local N28AVGStoryNodeState = {
    CantPlay = 0,
    CanPlay = 1,
    Complete = 2
}
_enum("N28AVGStoryNodeState", N28AVGStoryNodeState)
--endregion

--region N28AVGStoryParagraph 段落类
---@class N28AVGStoryParagraph:Object
---@field id number 段落Id，剧情配置中的段落索引
---@field dialogs N28AVGStoryDialog[] 对话列表
_class("N28AVGStoryParagraph", Object)
N28AVGStoryParagraph = N28AVGStoryParagraph

function N28AVGStoryParagraph:Constructor()
    self.id = 0
    self.isEnd = false
    self.dialogs = {}
end

---@return N28AVGStoryDialog
function N28AVGStoryParagraph:GetDialogBySectionIdx(sectionIdx)
    for index, dialog in ipairs(self.dialogs) do
        if dialog.sectionIdx == sectionIdx then
            return dialog
        end
    end
end
--endregion

--region N28AVGStoryDialog 对话类
---@class N28AVGStoryDialog:Object
---@field id number 对话id，即cfg_component_avg_story_section中的ID
---@field sectionIdx number 小节索引
---@field refEntityId number 引用的实体id
---@field options N28AVGStoryOption[] 该对话所含选项列表，对话没有选项即为空表
---@field beCondition N28AVGCondition BE触发条件
---@field beId number BEid
---@field valueChange number[] 数值变化
_class("N28AVGStoryDialog", Object)
N28AVGStoryDialog = N28AVGStoryDialog

function N28AVGStoryDialog:Constructor()
    self.id = 0
    self.sectionIdx = 0
    self.refEntityId = 0
    self.options = {}
    self.events = {}
    self.beCondition = nil
    self.beId = 0
    self.valueChange = {}
end

function N28AVGStoryDialog:ValueChange()
    return self.valueChange
end
---本对话有数值变化
---@return boolean
function N28AVGStoryDialog:HasValueChange()
    local vc = self:ValueChange()
    if vc then
        for _, value in ipairs(vc) do
            if value ~= 0 then
                return true
            end
        end
    end
    return false
end

---@return boolean
function N28AVGStoryDialog:IsSatisfyBE()
    if self.beCondition then
        return self.beCondition:IsSatisfy()
    end
    return false
end

---@return N28AVGStoryOption[] 本对话有可见选项
function N28AVGStoryDialog:GetVisibleOptions()
    local options = {}
    for index, option in ipairs(self.options) do
        if option:IsSatisfyVisible() then
            table.insert(options, option)
        end
    end
    return options
end
--endregion
--获取对话中是否存在举证项
function N28AVGStoryDialog:HaveShowEvienceEvent()
    for _, event in ipairs(self.events) do
        local cfg = Cfg.cfg_avg_phase2_event{ID = event.ID}
        if cfg then
            local ev = cfg[1]
            if ev.Type == N28StateAVGEvent.ShowEvidence then
                return true
            end
        end
    end
    return false
end

--region N28AVGStoryOption 选项类
---@class N28AVGStoryOption:Object
---@field id number 选项Id，即cfg_component_avg_story_manual中的ID
---@field storyId number
---@field paragraphId number
---@field sectionIdx number
---@field index number 选项索引
---@field content string 内容文本
---@field nextParagraphId number 该选项下一个段落id
---@field influenceLeader number 队长影响
---@field influencePartners number[] 队员影响列表
---@field influence string 影响文本
---@field unlockConditionDesc string 解锁条件文本
---@field unlockCondition N28AVGCondition 解锁条件，默认解锁
---@field visibleCondition N28AVGCondition 显示条件，默认显示
---@field nextNodeId number 选择该选项后下一个执行结点
_class("N28AVGStoryOption", Object)
N28AVGStoryOption = N28AVGStoryOption

function N28AVGStoryOption:Constructor()
    self.id = 0
    self.storyId = 0
    self.paragraphId = 0
    self.sectionIdx = 0
    self.index = 0
    self.content = ""
    self.nextParagraphId = 0

    self.influenceLeader = 0
    self.influencePartners = {}
    self.influence = ""

    self.unlockConditionDesc = ""
    self.unlockCondition = nil
    self.visibleCondition = nil
    self.nextNodeId = 0

    local mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = mCampaign:GetN28AVGData()
end

---@return string 选项内容
function N28AVGStoryOption:Content()
    return self.content
end
---@return nunmber 该选项下一个段落id
function N28AVGStoryOption:NextParagraphId()
    return self.nextParagraphId
end

---@return boolean 是否选择过
function N28AVGStoryOption:IsSelected()
    if self.data:IsSelectedOption(self.id) then
        return true
    end
end

--region influence
---@return boolean 是否有影响
function N28AVGStoryOption:IsInfluential()
    local inf = self:IsInfluentialLeader() or self:IsInfluentialPartners()
    return inf
end
function N28AVGStoryOption:IsInfluentialLeader()
    return self.influenceLeader ~= 0
end
function N28AVGStoryOption:IsInfluentialPartners()
    if self.influencePartners then
        for index, influence in ipairs(self.influencePartners) do
            if self:IsInfluentialPartner(index) then
                return true
            end
        end
    end
    return false
end
function N28AVGStoryOption:IsInfluentialPartner(index)
    return self.influencePartners[index] ~= 0
end
--endregion

---@return boolean
function N28AVGStoryOption:IsSatisfyUnlock()
    if self.unlockCondition then
        return self.unlockCondition:IsSatisfy()
    end
    return true
end

function N28AVGStoryOption:HasCondition()
    if self.unlockCondition then
        return self.unlockCondition:GetHasCondition()
    end
    return false
end

---@return boolean
function N28AVGStoryOption:IsSatisfyVisible()
    if self.visibleCondition then
        return self.visibleCondition:IsSatisfy()
    end
    return true
end
--endregion

--region N28AVGStoryLine 线类
---@class N28AVGStoryLine:Object
---@field sNodeId number 起始结点id
---@field eNodeId number 结尾结点id
---@field posS Vector2 起点位置
---@field posE Vector2 终点位置
---@field posLs Vector2[] 各拐点位置
_class("N28AVGStoryLine", Object)
N28AVGStoryLine = N28AVGStoryLine

function N28AVGStoryLine:Constructor()
    self.sNodeId = 0
    self.eNodeId = 0
    self.posS = Vector2.zero
    self.posE = Vector2.zero
    self.posLs = {}
end
--endregion
