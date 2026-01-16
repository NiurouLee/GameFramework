--region ChapterAwardData 所有章
---@class ChapterAwardData:Object
_class("ChapterAwardData", Object)
ChapterAwardData = ChapterAwardData

function ChapterAwardData:Constructor()
    ---@type ChapterAwardChapter[]
    self.chapter_data = {} --第一章到当前章的星数奖励数据
    self.cfg = Cfg["cfg_mission_chapter_award"]()
end

function ChapterAwardData:Init()
    for k, v in pairs(self.cfg) do
        --章
        ---@type ChapterAwardChapter
        local c = ChapterAwardChapter:New()
        self.chapter_data[v.ChapterID] = c
        local serverChapterData = self:GetServerChapterDataByChapterId(v.ChapterID)
        if serverChapterData then
            c:UpdateStarCount(serverChapterData.star_count)
        end
        ----档
        c.grades = {}
        for i, iv in ipairs(v.AwardItemIDList) do
            ---@type ChapterAwardGrade
            local g = ChapterAwardGrade:New()
            table.insert(c.grades, g)
            --奖励
            g.chapter_id = v.ChapterID
            g.star_count = iv.StarCount
            g.awards = {}
            local arr = self:GetSortedArr(iv.AwardItemList)
            if arr then
                for i, v in ipairs(arr) do
                    table.insert(g.awards, v)
                end
            end
            g:UpdateCollected(serverChapterData)
        end
        c.previewAward = {}
        if v.previewAward then
            for index, iv in ipairs(v.previewAward) do
                local g = ChapterAwardPreview:New()
                g.startMissionId = iv[1]
                g.endMissionId = iv[2]
                g.index = iv[3]
                g.awardIndex = iv[4]
                table.insert(c.previewAward, g)
            end
        end
    end
end

--region 奖励排序
---@param list Table ItemID=XXX, Count=XXX
function ChapterAwardData:GetSortedArr(list)
    if not list then
        return
    end
    local vecSort = SortedArray:New(Algorithm.COMPARE_CUSTOM, DiscoveryStage._LessComparer)
    for i, v in ipairs(list) do
        local award = Award:New()
        award:InitWithCount(v.ItemID, v.Count)
        vecSort:Insert(award)
    end
    return vecSort.elements
end
---奖励物品排序规则：品质降序，id升序
---@param nItemIDA Award
---@param nItemIDB Award
ChapterAwardData._LessComparer = function(nItemIDA, nItemIDB)
    local cfgItemA = Cfg.cfg_item[nItemIDA.id]
    local cfgItemB = Cfg.cfg_item[nItemIDB.id]
    if not cfgItemA or not cfgItemB then
        return 0
    end
    if cfgItemA.Color < cfgItemB.Color then
        return -1
    elseif cfgItemA.Color > cfgItemB.Color then
        return 1
    else
        if nItemIDA.id < nItemIDB.id then
            return 1
        elseif nItemIDA.id > nItemIDB.id then
            return -1
        else
            return 0
        end
    end
end
--endregion

---@private
---@param chapterId number 章节id
---@return mission_chapter_award_info
---根据章id获取服务器该章信息
function ChapterAwardData:GetServerChapterDataByChapterId(chapterId)
    ---@type MissionModule
    local module = GameGlobal.GetModule(MissionModule)
    ---@type mission_chapter_award_info[]
    local serverData = module:GetChapterInfo()
    for i, v in pairs(serverData) do
        if chapterId == v.chapter_id then
            return v
        end
    end
end

---@return ChapterAwardChapter
---根据章id获取该章数据
function ChapterAwardData:GetChapterAwardChapterByChapterId(chapterId)
    return self.chapter_data[chapterId]
end
--endregion

--region ChapterAwardChapter 章
---@class ChapterAwardChapter:Object
_class("ChapterAwardChapter", Object)
ChapterAwardChapter = ChapterAwardChapter

function ChapterAwardChapter:Constructor()
    self.star_count = 0 --该章获得的星数
    ---@type ChapterAwardGrade[]
    self.grades = {} --该章的档列表
end

function ChapterAwardChapter:UpdateStarCount(star_count)
    self.star_count = star_count
end

---是否有可领取奖励
function ChapterAwardChapter:CanCollect()
    for i, v in ipairs(self.grades) do
        if v:CanCollect(self.star_count) then --如果该档尚未领取，并且该档星数小于等于该章已有星数，就表示该章可领取
            return true
        end
    end
    return false
end
--endregion

--region ChapterAwardGrade 档
---@class ChapterAwardGrade:Object
_class("ChapterAwardGrade", Object)
ChapterAwardGrade = ChapterAwardGrade

function ChapterAwardGrade:Constructor()
    self.chapter_id = 0 --章节id
    self.star_count = 0 --该档星数
    ---@type Award[]
    self.awards = {} --该档奖励
    self.collected = false --是否领取
end

---@param serverChapterData mission_chapter_award_info
---更新该档是否已领取
function ChapterAwardGrade:UpdateCollected(serverChapterData)
    if not serverChapterData then
        return
    end
    for i, v in ipairs(serverChapterData.receive_star_award_list) do
        if self.star_count == v then
            self.collected = true
            break
        end
    end
end

---@param chapterStarCount number 该章已获取的星数
function ChapterAwardGrade:CanCollect(chapterStarCount)
    if not self.collected and self.star_count <= chapterStarCount then --如果该档尚未领取，并且该档星数小于等于该章已有星数，就表示该档可领取
        return true
    end
    return false
end
--endregion

--region ChapterAwardPreview 大地图章节奖励预览
---@class ChapterAwardPreview:Object
_class("ChapterAwardPreview", Object)
ChapterAwardPreview = ChapterAwardPreview

function ChapterAwardPreview:Constructor()
    self.startMissionId = 0 --触发missionid
    self.endMissionId = 0 -- 结束missionid
    self.index = 1
    self.awardIndex = 1
end
