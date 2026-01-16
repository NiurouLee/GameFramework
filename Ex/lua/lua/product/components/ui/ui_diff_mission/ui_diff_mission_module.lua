---@class UIDiffMissionModule:UIModule
_class("UIDiffMissionModule", UIModule)
UIDiffMissionModule = UIDiffMissionModule
function UIDiffMissionModule:Constructor()
    ---@type table<number,DiffMissionNode>
    self._nodeMap = {}
    ---@type table<number,DiffMissionChapter>
    self._chapterMap = {}
end
--词条描述
function UIDiffMissionModule:CreateEntiesDesc()
    if not self._entiesType2paramTex then
        self._entiesType2paramTex = {
            [EntiesType.ElementType_Prof] = {
                [PetProfType.PetProf_Color] = "str_pet_tag_job_name_color_change",
                [PetProfType.PetProf_Blood] = "str_pet_tag_job_name_return_blood",
                [PetProfType.PetProf_Attack] = "str_pet_tag_job_name_attack",
                [PetProfType.PetProf_Function] = "str_pet_tag_job_name_function"
            },
            [EntiesType.ElementType_Force] = {
                [PetForceType.PetForce_BaiYeCheng] = "str_pet_tag_faction_name_1",
                [PetForceType.PetForce_BaiYeXiaCheng] = "str_pet_tag_faction_name_2",
                [PetForceType.PetForce_QiGuang] = "str_pet_tag_faction_name_3",
                [PetForceType.PetForce_BeiJing] = "str_pet_tag_faction_name_4",
                [PetForceType.PetForce_HongYouBanShou] = "str_pet_tag_faction_name_5",
                [PetForceType.PetForce_TaiYangJiaoTuan] = "str_pet_tag_faction_name_6",
                [PetForceType.PetForce_YouMin] = "str_pet_tag_faction_name_7",
                [PetForceType.PetForce_RiShi] = "str_pet_tag_faction_name_8"
            },
            [EntiesType.ElementType_Elem] = {
                [ElementType.ElementType_Blue] = "str_pet_filter_water_element",
                [ElementType.ElementType_Red] = "str_pet_filter_fire_element",
                [ElementType.ElementType_Green] = "str_pet_filter_sen_element",
                [ElementType.ElementType_Yellow] = "str_pet_filter_electricity_element"
            }
        }
    end
    if not self._entiesType2tex then
        self._entiesType2tex = {
            [EntiesType.ElementType_None] = "str_diff_mission_enties_desc_3001",
            [EntiesType.ElementType_Prof] = {
                [EntiesCompareType.ElementCompareType_All] = "str_diff_mission_enties_desc_3002_1",
                [EntiesCompareType.ElementCompareType_No] = "str_diff_mission_enties_desc_3002_2",
                [EntiesCompareType.ElementCompareType_Less] = "str_diff_mission_enties_desc_3002_3",
                [EntiesCompareType.ElementCompareType_More] = "str_diff_mission_enties_desc_3002_4",
                [EntiesCompareType.ElementCompareType_Equal] = "str_diff_mission_enties_desc_3002_5"
            },
            [EntiesType.ElementType_Force] = {
                [EntiesCompareType.ElementCompareType_All] = "str_diff_mission_enties_desc_3004_1",
                [EntiesCompareType.ElementCompareType_No] = "str_diff_mission_enties_desc_3004_2",
                [EntiesCompareType.ElementCompareType_Less] = "str_diff_mission_enties_desc_3004_3",
                [EntiesCompareType.ElementCompareType_More] = "str_diff_mission_enties_desc_3004_4",
                [EntiesCompareType.ElementCompareType_Equal] = "str_diff_mission_enties_desc_3004_5"
            },
            [EntiesType.ElementType_Star] = {
                [EntiesCompareType.ElementCompareType_All] = "str_diff_mission_enties_desc_3005_1",
                [EntiesCompareType.ElementCompareType_No] = "str_diff_mission_enties_desc_3005_2",
                [EntiesCompareType.ElementCompareType_Less] = "str_diff_mission_enties_desc_3005_3",
                [EntiesCompareType.ElementCompareType_More] = "str_diff_mission_enties_desc_3005_4",
                [EntiesCompareType.ElementCompareType_Equal] = "str_diff_mission_enties_desc_3005_5"
            },
            [EntiesType.ElementType_Elem] = {
                [EntiesCompareType.ElementCompareType_All] = "str_diff_mission_enties_desc_3006_1",
                [EntiesCompareType.ElementCompareType_No] = "str_diff_mission_enties_desc_3006_2",
                [EntiesCompareType.ElementCompareType_Less] = "str_diff_mission_enties_desc_3006_3",
                [EntiesCompareType.ElementCompareType_More] = "str_diff_mission_enties_desc_3006_4",
                [EntiesCompareType.ElementCompareType_Equal] = "str_diff_mission_enties_desc_3006_6"
            },
            [EntiesType.ElementType_Level_Count] = "str_diff_mission_enties_desc_3007"
        }
    end
end
function UIDiffMissionModule:PetList()
    return self._catchPets
end
--进入大地图每次创建数据
function UIDiffMissionModule:Init()
    self:CreateEntiesDesc()

    ---@type ClientDifficultyMissionInfo
    self._diffMissionInfo = self:GetModule(DifficultyMissionModule).m_difficulty_mission_info

    local petList = {}
    if self._diffMissionInfo.pet_list and next(self._diffMissionInfo.pet_list) then
        petList = self._diffMissionInfo.pet_list
    end
    self:FlushTeam(petList)

    --创建章节数据
    local cfg = Cfg.cfg_difficulty_mission_chapter_desc {}
    if cfg then
        for id, value in pairs(cfg) do
            local c = DiffMissionChapter:New(id, value.PreMainChapterId)
            self._chapterMap[id] = c
        end
    end

    --创建鲁甸数据,--需要一起创建下一章路点--todo--
    --F:\project_p4\depot_matchsrpg\matchsrpg\trunk\client\PublishResources\config\client\discovery
    local cfg = Cfg.cfg_difficulty_mission_chapter {}
    if cfg then
        ---@type ParentMissionInfo
        local info = self._diffMissionInfo.infos

        for _, value in pairs(cfg) do
            local id = value.ParentMissionID
            local data = ParentMissionInfo:New()
            local nodeInfo = info[id]
            if nodeInfo then
                data = nodeInfo
            end
            local cid = value.DifficultyChapterID
            local wid = value.WayPointID
            local node = DiffMissionNode:New(id, cid, wid, data)
            self._nodeMap[id] = node
        end

        for _, value in pairs(self._nodeMap) do
            local last = value:PreMission()
            local state = DiffMissionNodeStatus.Lock
            if last ~= nil and last > 0 then
                local lastNode = self._nodeMap[last]
                if lastNode == nil then
                    Log.error("UIDiffMissionModule cant find node ", last)
                end
                local statuc = lastNode:Status()
                if statuc and statuc > 0 then
                    state = DiffMissionNodeStatus.Open
                end
            else
                state = DiffMissionNodeStatus.Open
            end
            value:SetLockState(state)
        end
    end

    --state-chapter
    for id, c in pairs(self._chapterMap) do
        local nodes = c:Nodes()
        if #nodes > 0 then 
            local lock = DiffMissionChapterStatus.Lock
            --检查这个章节的第一个鲁甸的上一个鲁甸是不是通关
            ---@type DiffMissionNode
            local node = self._nodeMap[nodes[1]]
            if node:Lock() == DiffMissionNodeStatus.Open then
                lock = DiffMissionChapterStatus.Open
            end
    
            --检查最后一个鲁甸
            local node = self._nodeMap[nodes[#nodes]]
            local status = node:Status()
            if status and status > 0 then
                lock = DiffMissionChapterStatus.Finish
            end
    
            c:SetLock(lock)
        end 
    end
end
function UIDiffMissionModule:GetChapterData(id)
    return self._chapterMap[id]
end
--某个章节全部通关
function UIDiffMissionModule:AllPass(chapterid)
    local chapterData = self._chapterMap[chapterid]
    if chapterData:Lock() == DiffMissionChapterStatus.Finish then
        return true
    end
    return false
    -- if not chapterData then
    --     Log.error("###[UIDiffMissionModule] not find chapter , id --> ",chapterid)
    --     return false
    -- end
    -- local nodes = chapterData:Nodes()
    -- for _, nodeid in pairs(nodes) do
    --     local node = self._nodeMap[nodeid]
    --     if node:Lock() == DiffMissionNodeStatus.Lock then
    --         return false
    --     end
    -- end
    -- return true
end
function UIDiffMissionModule:GetNextChapterID(diffCid)
    local cfg = Cfg.cfg_difficulty_mission_chapter_desc[diffCid + 1]
    if cfg then
        return diffCid + 1
    end
    return nil
end
--检查下一章节是否能跳
function UIDiffMissionModule:GetNextChapterCanJump(diffCid)
    local nextChapterCanJump = false
    local chapterData = self._chapterMap[diffCid]
    if chapterData:Lock() == DiffMissionChapterStatus.Lock then
        return false
    end
    return nextChapterCanJump
end
function UIDiffMissionModule:JumpNextChapter(jumpDiffCID)
    local cfg = Cfg.cfg_difficulty_mission_chapter_desc[jumpDiffCID]
    local mainCID = cfg.PreMainChapterId
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushDiffNodes, mainCID)
end
function UIDiffMissionModule:GetNode(id)
    return self._nodeMap[id]
end
function UIDiffMissionModule:GetDiffChapterFromMission(missionChapter)
    local cfgs = Cfg.cfg_difficulty_mission_chapter_desc {PreMainChapterId = missionChapter}
    if not cfgs or #cfgs <= 0 then
        return
    end
    local cfg = cfgs[1]
    local diffID = cfg.ID
    return self._chapterMap[diffID]
end
--获取缓存编队
function UIDiffMissionModule:GetTeam()
    return nil
end
function UIDiffMissionModule:FlushTeam(pets)
    self._catchPets = pets or {}
end
function UIDiffMissionModule:GetFilterPets()
    local team, stageid, stageList = self:GetTeamInfo()
    local filterPets = {}
    for id, team in pairs(stageList) do
        if id ~= stageid then
            local tmpPets = team:GetPets()
            if tmpPets and next(tmpPets) then
                for _, pstid in pairs(tmpPets) do
                    if pstid > 0 then
                        filterPets[pstid] = true
                    end
                end
            end
        end
    end
    return filterPets
end

--缓存编队信息，用于选星灵界面
--注意：主线困难关和活动困难关打开编队时都会在这里缓存编队信息
function UIDiffMissionModule:SetTeamInfo(team, id, stageInfo)
    --进入编队时设置信息
    --当前的关卡id
    --所有的关卡队伍
    --当前缓存队伍
    self._team = team
    self._stageId = id
    self._stageInfo = stageInfo
end
function UIDiffMissionModule:GetTeamInfo()
    return self._team, self._stageId, self._stageInfo
end
--nouse
function UIDiffMissionModule:SetTeamInfo_forTeam()
    ---@type Team
    local tmpTeam, id, list = self:GetTeamInfo()
    local team = {}
    local useStageID = nil
    if not tmpTeam or not next(tmpTeam) then
        local sTeam = list[id]
        if not sTeam or not next(sTeam) then
            --无缓存编队，无记录的关卡，编队为空
            team = {}
        else
            --无缓存记录，有记录的关卡，设置为关卡的编队
            useStageID = id
            team = sTeam
        end
    else
        local sTeam = list[id]
        if not sTeam or not next(sTeam) then
            --有缓存记录，无记录的关卡，使用缓存编队
            team = tmpTeam
        else
            --有缓存记录，有记录的关卡，设置为关卡编队
            useStageID = id
            team = sTeam
        end
    end

    --检查编队人物是不是能使用
    local teamDataList = {}
    for i = 1, #team do
        local pstid = team[i]
        local use = self:CheckPetCanUse(pstid)

        local data = {}
        data.use = use
        data.pstid = pstid

        teamDataList[i] = data
    end

    return teamDataList
end
function UIDiffMissionModule:GetDiffCIDByMissionCID(missionCID)
    for _, c in pairs(self._chapterMap) do
        if c:MissionChapterID() == missionCID then
            return c:ID()
        end
    end
end
--章节id
function UIDiffMissionModule:GetDiffChapterCurrentNode(chapterid)
    ---@type DiffMissionChapter
    local chapterData = self._chapterMap[chapterid]
    local nodes = chapterData:Nodes()
    for i = #nodes, 1, -1 do
        local id = nodes[i]
        local node = self:GetNode(id)
        if node:Lock() == DiffMissionNodeStatus.Open then
            return node:ID()
        end
    end
end
function UIDiffMissionModule:SetMoveNodePos(nodeid)
    self._lastBattleNodeID = nodeid
end
function UIDiffMissionModule:GetMoveNodePos(chapterid)
    local nodeid
    if self._lastBattleNodeID then
        nodeid = self._lastBattleNodeID
        self._lastBattleNodeID = nil
    else
        nodeid = self:GetDiffChapterCurrentNode(chapterid)
    end
    local node = self:GetNode(nodeid)
    return node:Pos()
end
function UIDiffMissionModule:CheckPetCanUse(pstid)
    if pstid and pstid ~= 0 then
        for id, team in pairs(self._stageInfo) do
            if id ~= self._stageId then
                for i = 1, #team do
                    local tPstid = team[i]
                    if tPstid == pstid then
                        return false
                    end
                end
            end
        end
    else
        return true
    end
end
function UIDiffMissionModule:GetDiffMissionEnties(enties)
    if not enties or not next(enties) then
        return ""
    end
    local entiesType = enties[1]
    if entiesType == EntiesType.ElementType_None then
        return StringTable.Get(self._entiesType2tex[entiesType])
    elseif entiesType == EntiesType.ElementType_Level_Count then
        local count = enties[2]
        return StringTable.Get(self._entiesType2tex[entiesType], count)
    else
        local paramType = enties[2]
        local compareType = enties[3]
        local paramNum = enties[4]

        local typeStr = self._entiesType2tex[entiesType][compareType]
        local paramStr
        if entiesType == EntiesType.ElementType_Star then
            paramStr = paramType
        else
            paramStr = StringTable.Get(self._entiesType2paramTex[entiesType][paramType])
        end
        local desc = StringTable.Get(typeStr, paramStr, paramNum)
        return desc
    end
    return ""
end
