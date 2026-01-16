--region Teams define
---@class Teams:Object
_class("Teams", Object)
Teams = Teams

function Teams:Constructor()
    self.list = {}
end

---@param serverData formation_info[]
function Teams:Init(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end
---@param serverData maze_formation_detail[]
function Teams:_InitDiffTeams(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end
function Teams:_InitCampDiffTeams(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end
---@param serverData maze_formation_detail[]
function Teams:_InitMazeTeams(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end

---@param serverData TacticFormationInfo[]
function Teams:_InitAirTeams(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end
---@param serverData SeasonFormationItem[]
function Teams:_InitSeasonTeams(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end
function Teams:InitTrailTeams(serverData)
    self.list = {}
    for i, v in ipairs(serverData) do
        local team = Team:New()
        team:Init(v.id, v.name, v.pet_list)
        self.list[v.id] = team
    end
end

---@param serverData ChallengeFormationItem
function Teams:InitN21CCTeams(serverData, levelIndex)
    self.list = {}
    local team = Team:New()
    if serverData then
        team:Init(serverData.id, serverData.name, serverData.pet_list)
    else
        team:Init(levelIndex, "", {})
    end
    self.list[levelIndex] = team
end

---@param serverData TeamCache
function Teams:InitSailingTeams(serverData, levelIndex)
    self.list = {}
    local team = Team:New()
    if serverData then
        team:Init(levelIndex, "", serverData.pet_list)
    else
        team:Init(levelIndex, "", {})
    end
    self.list[levelIndex] = team
end

function Teams:InitVampireTeams()
    self.list = {}
    local team = Team:New()
    team:Init(1, "", {})
    self.list[1] = team
end

---@return number 编队数
function Teams:TeamCount()
    return table.count(self.list)
end

---@param id number 队伍id
---@return Team
---根据id获取队伍
function Teams:Get(id)
    return self.list[id]
end
---@param team Team 队伍
---更新队伍
function Teams:UpdateTeam(team)
    self.list[team.id] = team
end

--endregion

--region Team define
---@class Team:Object
---@field teamSlotCount number 编队槽位数
---@field id number 编队id
---@field name string 编队名
---@field pets number[] 队员id列表
_class("Team", Object)
Team = Team

function Team:Constructor()
    self.teamSlotCount = 5
    self.id = 0
    self.name = ""
    self.pets = {}
end
---@param pets number[]
function Team:Init(id, name, pets)
    self.id = id
    self.name = name
    for i = 1, self.teamSlotCount do
        self.pets[i] = pets[i] or 0
    end
end
function Team:UpdateName(name)
    self.name = name
end
---@return boolean
---队伍中有没有宠物
function Team:HasPet()
    for i, v in ipairs(self.pets) do
        if v > 0 then
            return true
        end
    end
end
---交换队员位置
function Team:Swap(slot1, slot2)
    local tmp = self.pets[slot1]
    self.pets[slot1] = self.pets[slot2]
    self.pets[slot2] = tmp
end
---拷贝队伍
function Team:Clone()
    local team = Team:New()
    team.teamSlotCount = self.teamSlotCount
    team:Init(self.id, self.name, self.pets)
    return team
end
---清空队员
function Team:ClearPet()
    for i = 1, self.teamSlotCount do
        self.pets[i] = 0
    end
end
---获取第一个非空宠物id
function Team:Get1stPetId()
    for i, v in ipairs(self.pets) do
        if v > 0 then
            return v
        end
    end
end
---获取队长宠物id
function Team:GetLeaderPetId()
    if self.pets then
        return self.pets[FormationPetLeaderSeat.LeaderSeat]
    end
end

function Team:GetID()
    return self.id
end

function Team:GetName()
    return self.name
end

function Team:GetPets()
    return self.pets
end

--endregion

--region TeamsTeamId
---@class TeamsTeamId:Object
---@field teams  Teams 所有编队
---@field teamId  number 当前编队Id，默认第1编队
_class("TeamsTeamId", Object)
TeamsTeamId = TeamsTeamId

function TeamsTeamId:Constructor()
    self.teams = {}
    self.teamId = 1
end
--endregion

--region TeamsContext 编队逻辑上下文数据
---@class TeamsContext:Object
---@field teamOpenerType  TeamOpenerType
---@field param  table
---@field curSlot  number 当前编队的slot
---@field tmpTeam  Team 临时队伍
---@field _isFightAgain boolean 是否再次挑战
---
---@field teams  Teams  常规编队信息
---@field curTeamId  number 当前主线、番外、资源本编队id
---
---@field towerTeams  TeamsTeamId[] 尖塔编队，进入尖塔时初始化
---@field towerTeamCeiling  number 尖塔编队中的光灵数没达到该值的不允许对战
---
---@field mazeTeam  Teams 秘境编队
---@field mazeTeamId  number 秘境编队id
---
---@field trailTeam  Teams 试炼关卡编队
---@field trailTeamId  number 试炼关卡编队id
---
---@field summerTwoTeam  Teams 夏活二期关卡编队
---@field summerTwoTeamId  number 夏活二期关卡编队id
---
---@field airTeam  Teams 战术模拟器编队
---@field airTeamId  number 战术模拟器编队id
---
---@field worldBossTeam  Teams WorldBoss编队
---@field worldBossTeamId  number WorldBoss编队id
_class("TeamsContext", Object)
TeamsContext = TeamsContext

function TeamsContext:Constructor()
    self.teamOpenerType = TeamOpenerType.Stage
    self.param = 0
    self.teams = Teams:New()
    self.towerTeams = nil
    self.towerTeamCeiling = 0
    self.curTeamId = 1
    self.mazeTeam = Teams:New()
    self.mazeTeamId = 1
    self.trailTeam = Teams:New()
    self.trailTeamId = 1
    self.summerTwoTeam = Teams:New()
    self.summerTwoTeamId = 1
    self.airTeam = Teams:New()
    self.airTeamId = 1
    self.worldBossTeam = Teams:New()
    self.worldBossTeamId = 1
    self.n21CCTeam = Teams:New()
    self.n21CCTeamId = 1
    self.sailingTeam = Teams:New()
    self.sailingTeamId = 1
    self.vampireTeam = Teams:New()
    self.vampireTeamId = 1
    self.curSlot = 0
    self.fastSelect = false
    self.tmpTeam = nil
    self.diffTeam = Teams:New()
    self.diffTeamId = 1
    self.campDiffTeam = Teams:New()
    self.campDiffTeamId = 1
    self.eightPetsTeam = Teams:New()
    self.eightPetsTeamId = 1
    self.seasonTeam = Teams:New()
    self.seasonTeamId = 1
    self._isFightAgain = false
end

---@param serverData formation_info[] 编队信息
---用服务器数据初始化编队数据
function TeamsContext:InitByServerData(serverData)
    self.teams:Init(serverData)
end

--进入尖塔时初始化尖塔编队
---@param serverData mul_tower_formations
function TeamsContext:InitTowerTeam(serverData)
    ---@type each_tower_formation_info[][]
    local mapElementPetList = {
        [TowerElementType.TowerElementType_Blue] = serverData.mul_water_pet_lists,
        [TowerElementType.TowerElementType_Red] = serverData.mul_fire_pet_lists,
        [TowerElementType.TowerElementType_Green] = serverData.mul_wood_pet_lists,
        [TowerElementType.TowerElementType_Yellow] = serverData.mul_thunder_pet_lists,

        [TowerElementType.TowerElementType_Difficulty_Blue] = serverData.difficulty_mul_water_pet_lists,
        [TowerElementType.TowerElementType_Difficulty_Red] = serverData.difficulty_mul_fire_pet_lists,
        [TowerElementType.TowerElementType_Difficulty_Green] = serverData.difficulty_mul_wood_pet_lists,
        [TowerElementType.TowerElementType_Difficulty_Yellow] = serverData.difficulty_mul_thunder_pet_lists
    }
    local len = table.count(mapElementPetList)
    if self.towerTeams and table.count(self.towerTeams) == len then
    else
        self.towerTeams = {}
        for element, formation_info_towers in pairs(mapElementPetList) do
            self.towerTeams[element] = TeamsTeamId:New()
        end
    end
    ---@type formation_info_towers each_tower_formation_info[]
    for element, formation_info_towers in pairs(mapElementPetList) do
        local teams = Teams:New()
        local fis = {}
        for _, formation_info_tower in pairs(formation_info_towers) do
            local fi = formation_info:New() --队伍信息
            fi.id = formation_info_tower.id
            fi.name = formation_info_tower.name
            fi.pet_list = formation_info_tower.pet_list
            table.insert(fis, fi)
        end
        teams:Init(fis)
        self.towerTeams[element].teams = teams
    end
end

--初始化秘境编队
---@param serverData maze_formation_info
function TeamsContext:InitMazeTeam(serverData)
    self.mazeTeam:_InitMazeTeams(serverData.fromation_list)
end

--初始化风船编队
---@param serverData CEventChangeTacticFormationInfoResult
function TeamsContext:InitAirTeam(serverData)
    self.airTeam:_InitAirTeams(serverData.tactic_formation_list)
end
function TeamsContext:InitDiffTeam(serverData)
    self.diffTeam:_InitDiffTeams(serverData)
end

function TeamsContext:InitCampDiffTeam(serverData)
    self.campDiffTeam:_InitCampDiffTeams(serverData)
end

function TeamsContext:InitTrailTeam(serverData)
    self.trailTeam:InitTrailTeams(serverData)
end
function TeamsContext:InitWorldBossTeams(serverData)
    self.worldBossTeam:Init(serverData)
end
function TeamsContext:InitSeasonTeam(serverData)
    self.seasonTeam:_InitSeasonTeams(serverData)
end
---@param serverData ChallengeFormationItem
function TeamsContext:InitN21CCTeams(serverData, levelIndex)
    self.n21CCTeamId = levelIndex
    self.n21CCTeam:InitN21CCTeams(serverData, levelIndex)
end
---@param serverData TeamCache
function TeamsContext:InitSailingTeams(serverData)
    self.sailingTeamId = 1
    self.sailingTeam:InitSailingTeams(serverData, self.sailingTeamId)
end

function TeamsContext:InitVampireTeams()
    self.vampireTeamId = 1
    self.vampireTeam:InitVampireTeams()
end
---@param teamOpenerType TeamOpenerType 跳转类型
---@param param number 主线/番外：关卡id；随机事件：事件id
---初始化编队上下文数据，从哪跳转
function TeamsContext:Init(teamOpenerType, param)
    self.teamOpenerType = teamOpenerType
    self.param = param
end

function TeamsContext:GetTeamOpenerType()
    return self.teamOpenerType
end

function TeamsContext:CheckTeamOpenerType(openerType)
    return self.teamOpenerType == openerType
end

function TeamsContext:GetParam()
    return self.param
end

--设置尖塔编队上下文
function TeamsContext:SetTowerContext(ceiling, element, layerID)
    self.towerTeamCeiling = ceiling
    if element > 4 then
        self.towerElement = element - 4
    else
        self.towerElement = element
    end
    self.towerLayerID = layerID
end

function TeamsContext:GetTowerTeamCeiling()
    return self.towerTeamCeiling
end

function TeamsContext:GetTowerElement()
    return self.towerElement
end

function TeamsContext:GetTowerLayerID()
    return self.towerLayerID
end

---@param curSlot number
---初始化编队选取类型
function TeamsContext:InitTeamMemberSelect(curSlot)
    self.curSlot = curSlot
    self.fastSelect = false
    if self.teamOpenerType == TeamOpenerType.Tower then
        local teamId = self:GetTowerTeamId(self.towerElement)
        self.tmpTeam = self:GetTowerTeam():Get(teamId)
    elseif self.teamOpenerType == TeamOpenerType.Maze then
        self.tmpTeam = self.mazeTeam:Get(self.mazeTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Trail then
        self.tmpTeam = self.trailTeam:Get(self.trailTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Sailing then
        self.tmpTeam = self.sailingTeam:Get(self.sailingTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Vampire then
        self.tmpTeam = self.vampireTeam:Get(self.vampireTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.WorldBoss then
        self.tmpTeam = self.worldBossTeam:Get(self.worldBossTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.N21CC then
        self.tmpTeam = self.n21CCTeam:Get(self.n21CCTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Air then
        self.tmpTeam = self.airTeam:Get(self.airTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Diff then
        self.tmpTeam = self.diffTeam:Get(self.diffTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Camp_Diff then
        self.tmpTeam = self.campDiffTeam:Get(self.campDiffTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.EightPets then
        self.tmpTeam = self.eightPetsTeam:Get(self.eightPetsTeamId):Clone()
    elseif self.teamOpenerType == TeamOpenerType.Season then
        self.tmpTeam = self.seasonTeam:Get(self.seasonTeamId):Clone()
    else
        local curTeamId = self:GetCurrTeamId()
        self.tmpTeam = self.teams:Get(curTeamId):Clone()
    end
end

function TeamsContext:InitTeamFastSelect()
    self:InitTeamMemberSelect(-1)
    self.fastSelect = true
end

---@return boolean 快速编队模式
function TeamsContext:IsFastSelect()
    return self.fastSelect
end

function TeamsContext:ClearFastSelect()
    self.fastSelect = false
end

---@return Teams
---获取编队数据ganjue
function TeamsContext:Teams()
    if self.teamOpenerType == TeamOpenerType.Tower then
        local now_type = self.towerElement;
        if now_type > 4 then
            self.towerElement =self.towerElement - 4
        end 
        local teamId = self:GetTowerTeamId(self.towerElement)
        local team = self:GetTowerTeam():Get(teamId)

        local teams = self:RawGetTowerTeam(self.towerElement)
        teams:UpdateTeam(team) --拿爬塔队伍时更新下缓存，爬塔队伍可能有人数限制
        return teams
    elseif self.teamOpenerType == TeamOpenerType.Maze then
        return self:GetMazeTeam()
    elseif self.teamOpenerType == TeamOpenerType.Air then
        return self.airTeam
    elseif self.teamOpenerType == TeamOpenerType.Trail then
        return self.trailTeam
    elseif self.teamOpenerType == TeamOpenerType.Sailing then
        return self.sailingTeam
    elseif self.teamOpenerType == TeamOpenerType.Vampire then
        return self.vampireTeam
    elseif self.teamOpenerType == TeamOpenerType.WorldBoss then
        return self.worldBossTeam
    elseif self.teamOpenerType == TeamOpenerType.N21CC then
        return self.n21CCTeam
    elseif self.teamOpenerType == TeamOpenerType.Diff then
        return self.diffTeam
    elseif self.teamOpenerType == TeamOpenerType.Camp_Diff then
        return self.campDiffTeam
    elseif self.teamOpenerType == TeamOpenerType.EightPets then
        return self.eightPetsTeam
    elseif self.teamOpenerType == TeamOpenerType.Season then
        return self.seasonTeam
    else
        return self.teams
    end
end

---@return Teams
function TeamsContext:GetTowerTeam()
    local teams = self:RawGetTowerTeam(self.towerElement)
    local clone = Teams:New()
    for id, team in pairs(teams.list) do
        local cTeam = Team:New()
        cTeam.id = team.id
        cTeam.name = team.name
        cTeam.teamSlotCount = team.teamSlotCount
        cTeam.pets = {}
        --不能超过上限
        for i = 1, #team.pets do
            if i > self.towerTeamCeiling then
                cTeam.pets[i] = 0
            else
                cTeam.pets[i] = team.pets[i]
            end
        end
        clone.list[id] = cTeam
    end
    return clone
end
---@return Teams
function TeamsContext:RawGetTowerTeam(element)
    local teamsTeamId = self.towerTeams[element]
    local teams = teamsTeamId.teams
    return teams
end

---@return number
function TeamsContext:GetTowerTeamId(element)
    local teamsTeamId = self.towerTeams[element]
    return teamsTeamId.teamId
end
function TeamsContext:SetTowerTeamId(element, teamId)
    local teamsTeamId = self.towerTeams[element]
    teamsTeamId.teamId = teamId
end

---@return Teams
function TeamsContext:GetMazeTeam()
    return self.mazeTeam
end

---@return Teams
function TeamsContext:GetAirTeam()
    return self.airTeam
end

--region CurTeamId
---获取当前显示的队伍id
function TeamsContext:GetCurrTeamId()
    if self.teamOpenerType == TeamOpenerType.Maze then
        return self.mazeTeamId
    elseif self.teamOpenerType == TeamOpenerType.Air then
        return self.airTeamId
    elseif self.teamOpenerType == TeamOpenerType.Tower then
        local teamId = self:GetTowerTeamId(self.towerElement)
        return teamId
    elseif self.teamOpenerType == TeamOpenerType.Trail then
        local key = self:GetCurrTrailTeamIdKey()
        local teamId = UnityEngine.PlayerPrefs.GetInt(key, self.trailTeamId)
        return teamId
    elseif self.teamOpenerType == TeamOpenerType.Sailing then
        return self.sailingTeamId
    elseif self.teamOpenerType == TeamOpenerType.Vampire then
        return self.vampireTeamId
    elseif self.teamOpenerType == TeamOpenerType.WorldBoss then
        return self.worldBossTeamId
    elseif self.teamOpenerType == TeamOpenerType.N21CC then
        return self.n21CCTeamId
    elseif self.teamOpenerType == TeamOpenerType.Diff then
        return self.diffTeamId
    elseif self.teamOpenerType == TeamOpenerType.Camp_Diff then
        return self.campDiffTeamId
    elseif self.teamOpenerType == TeamOpenerType.EightPets then
        return self.eightPetsTeamId
    elseif self.teamOpenerType == TeamOpenerType.Season then
        return self.seasonTeamId
    else
        local key = self:GetCurrTeamIdKey()
        local teamId = UnityEngine.PlayerPrefs.GetInt(key, self.curTeamId)
        return teamId
    end
end
---设置当前显示的队伍id
function TeamsContext:SetCurrTeamId(teamId)
    if self.teamOpenerType == TeamOpenerType.Maze then
        self.mazeTeamId = teamId
    elseif self.teamOpenerType == TeamOpenerType.Air then
        self.airTeamId = teamId
    elseif self.teamOpenerType == TeamOpenerType.Tower then
        self:SetTowerTeamId(self.towerElement, teamId)
    elseif self.teamOpenerType == TeamOpenerType.WorldBoss then
    elseif self.teamOpenerType == TeamOpenerType.N21CC then
    elseif self.teamOpenerType == TeamOpenerType.Diff then
    elseif self.teamOpenerType == TeamOpenerType.Sailing then
    elseif self.teamOpenerType == TeamOpenerType.Vampire then
    elseif self.teamOpenerType == TeamOpenerType.Trail then
        local key = self:GetCurrTrailTeamIdKey()
        UnityEngine.PlayerPrefs.SetInt(key, teamId)
        self.trailTeamId = teamId
    elseif self.teamOpenerType == TeamOpenerType.Camp_Diff then
    elseif self.teamOpenerType == TeamOpenerType.EightPets then
        self.eightPetsTeamId = teamId
    elseif self.teamOpenerType == TeamOpenerType.Season then
        self.seasonTeamId = teamId
    else --主线、番外、资源本需要持久化
        local key = self:GetCurrTeamIdKey()
        UnityEngine.PlayerPrefs.SetInt(key, teamId)
        self.curTeamId = teamId
    end
end
---@private
function TeamsContext:GetCurrTeamIdKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "CurrTeamId"
    return key
end

function TeamsContext:GetCurrTrailTeamIdKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "CurrTrailTeamId"
    return key
end

function TeamsContext:GetCurrSummerTwoTeamIdKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "CurrSummerTwoTeamId"
    return key
end

function TeamsContext:ShowDialogUITeams(isState)
    local teamsName = "UITeams"
    local stateType = UIStateType.UITeams

    local stageId = 0
    if self.teamOpenerType == TeamOpenerType.Stage then
        stageId = self.param
    elseif self.teamOpenerType == TeamOpenerType.ExtMission then
        stageId = self.param[2]
    elseif self.teamOpenerType == TeamOpenerType.Trail then
        stageId = self.param
    elseif self.teamOpenerType == TeamOpenerType.Sailing then
        stageId = self.param[2]
    elseif self.teamOpenerType == TeamOpenerType.Vampire then
        stageId = self.param[1]
    elseif self.teamOpenerType == TeamOpenerType.Campaign then
        stageId = self.param[1]
    elseif self.teamOpenerType == TeamOpenerType.LostLand then
        stageId = self.param
    elseif self.teamOpenerType == TeamOpenerType.Conquest then
        stageId = self.param[1]
    elseif self.teamOpenerType == TeamOpenerType.WorldBoss then
        stageId = self.param[1]
    elseif self.teamOpenerType == TeamOpenerType.N21CC then
        stageId = self.param[1]
    elseif self.teamOpenerType == TeamOpenerType.Air then
        stageId = self.param[1]
    elseif self.teamOpenerType == TeamOpenerType.Diff then
        stageId = self.param[2]
    elseif self.teamOpenerType == TeamOpenerType.Camp_Diff then
        stageId = self.param[2]
    elseif self.teamOpenerType == TeamOpenerType.Season then
        stageId = self.param[1]
    end
    if DiscoveryStage.IsGuideStageId(stageId) then
        teamsName = "UITeamsGuide"
        stateType = UIStateType.UITeamsGuide
    end

    if isState then
        GameGlobal.UIStateManager():SwitchState(stateType)
    else
        GameGlobal.UIStateManager():ShowDialog(teamsName)
    end
end

---@return number 编队数
---秘境挑战 风船战术室 8
---尖塔 4
function TeamsContext:GetTeamCount()
    local teamCount = 4
    if
        self.teamOpenerType == TeamOpenerType.WorldBoss or self.teamOpenerType == TeamOpenerType.Diff or
            self.teamOpenerType == TeamOpenerType.N21CC or
            self.teamOpenerType == TeamOpenerType.Sailing or
            self.teamOpenerType == TeamOpenerType.Vampire or
            self.teamOpenerType == TeamOpenerType.Camp_Diff
     then
        teamCount = 1
    elseif self.teamOpenerType == TeamOpenerType.Tower or self.teamOpenerType == TeamOpenerType.Trail then
        teamCount = 4
    elseif self.teamOpenerType == TeamOpenerType.Maze or self.teamOpenerType == TeamOpenerType.Air then
        teamCount = 8
    else
        teamCount = Cfg.cfg_global["FormationCount"].IntValue
        if self.teams:TeamCount() < teamCount then
            teamCount = self.teams:TeamCount()
        end
    end
    return teamCount
end

---@param team Team
---@return TOWER_RESULT_CODE, mul_tower_formations
---修改尖塔队列消息
function TeamsContext:ReqTowerChangeMulFormationInfo(TT, team)
    local module = GameGlobal.GetModule(TowerModule)
    local nId = self:GetTowerLayerID()
    local reqTeamInfo = each_tower_formation_info:New()
    reqTeamInfo.id = team.id
    reqTeamInfo.name = team.name
    reqTeamInfo.pet_list = team.pets
    local res, data = module:ReqTowerChangeMulFormationInfo(TT, nId, reqTeamInfo)
    return res, data
end

-- region 再次挑战
---@param isFightAgain boolean
function TeamsContext:SetFightAgain(isFightAgain)
    self._isFightAgain = isFightAgain
end
---@return boolean
function TeamsContext:GetFightAgain()
    return self._isFightAgain
end
-- endregion
--endregion

--- @class TeamOpenerType
TeamOpenerType = {
    Main = 0, --来自主界面
    Stage = 1, --来自关卡详情
    ExtMission = 3, --来自番外副本
    SmallMap = 4, --来自小地图
    ResInstance = 5, -- 来自资源副本
    Maze = 6, --秘境探索
    Tower = 7, --尖塔副本
    ReFight = 8, --重新挑战
    Trail = 9, --试炼关卡
    Campaign = 10, --活动关卡 (使用主线的编队等数据)
    LostLand = 11, --迷失之地
    Conquest = 12, --无双关（随机波次）
    BlackFist = 13, --黑拳赛
    WorldBoss = 14, --世界boss
    Air = 15, --风船战术模拟器
    Diff = 16, --diff
    N21CC = 17, --N21危机合约
    Sailing = 18, --大航海
    Vampire = 19, --吸血鬼
    Camp_Diff = 20, --活动黑匣困难关
    Season = 21, --探索
    EightPets = 998, --N33八人编队玩法
    NONE = 999
}
