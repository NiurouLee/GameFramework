--[[------------------------------------------------------------------------------------------
    BattleEnterSystem：主状态机进入战场的流程
    此阶段现在负责了一个庞大的流程，为了方便维护，应该做如下拆分
    BattleEnter ：负责初始化各种组件、创建队伍、强化BUFF、被动技等逻辑
    OpeningShow ：负责宝宝的开场表演部分
    可以在后续某次的帧率优化时，把上述内容做了
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class BattleEnterSystem:MainStateSystem
_class("BattleEnterSystem", MainStateSystem)
BattleEnterSystem = BattleEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function BattleEnterSystem:_GetMainStateID()
    return GameStateID.BattleEnter
end

---@param TT token 协程识别码，服务端是nil
function BattleEnterSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---初始化BattleState组件
    self:_DoLogicInitBattleState()

    ---客户端执行表现部分
    self:_DoRenderShowBattleEnter(TT, teamEntity)

    ---客户端执行的棋盘展示函数
    local type,dir = self:_DoLogicGetPieceRefreshType()
    self:_DoRenderShowBoard(TT,type,dir)

    ---组装feature的逻辑
    self:_DoLogicAssembleFeature()

    ---组装feature的表现
    self:_DoRenderAssembleFeature(TT)

    ---构造一个强化BuffMap 当挂buff的时候判断是否需要修改参数
    self:_DoCreateIntensifyBuffMap()

    ---设置星灵的强化buff--挂载强化buff时也应用了装备精炼里的强化
    self:_DoLogicSetPetIntensifyBuff()

    --------------------------------装备精炼-------------------------------
    ---装备精炼的buff列表
    self:_DoLogicSetEquipRefineBuff()

    ---装备精炼修改的buff参数
    self:_DoLogicCreateEquipRefineIntensifyBuffMap()
    --------------------------------装备精炼End-------------------------------

    ---设置星灵的被动技能
    self:_DoLogicSetPetPassiveSkill()

    ---通知光灵创建结束
    self:_DoLogicNotifyPetCreate(teamEntity)

    ---客户端表现，这里之前的逻辑也没有卡主流程
    self:_DoRenderShowPet(TT, teamEntity)

    ---切换主状态机状态
    self:_DoLogicSwitchMainFsmState()
end

---初始化battleState [TODO 放到service初始化中]
function BattleEnterSystem:_DoLogicInitBattleState()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local turnCount = levelConfigData:GetLevelRoundCount()
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Maze then
        local mazeService = self._world:GetService("Maze")
        turnCount = mazeService:GetLightCount()
    end
    battleStatCmpt:InitLevelRound(turnCount)

    battleStatCmpt:SetTotalWaveCount(levelConfigData:GetWaveCount())

    ---获取当前关卡Id:mission_id
    if self._world.BW_WorldInfo.matchType == MatchType.MT_Mission or
            self._world.BW_WorldInfo.matchType == MatchType.MT_Campaign
     then
        local threeStarConditions = {}
        if self._world.BW_WorldInfo.matchType == MatchType.MT_Mission then
            threeStarConditions = configService:GetMission3StarCondition(self._world.BW_WorldInfo.missionID)
        elseif self._world.BW_WorldInfo.matchType == MatchType.MT_Campaign then
            threeStarConditions = configService:GetCampaignMission3StarCondition(self._world.BW_WorldInfo.missionID)
        end
        ---获取三星进度计算服务Star3CalcService
        ---@type Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:BeZeroProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    elseif self._world.BW_WorldInfo.matchType == MatchType.MT_ExtMission then
        local threeStarConditions =
            configService:GetExtMission3StarCondition(self._world.BW_WorldInfo.ext_mission_task_id)
        ---获取三星进度计算服务Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    elseif self._world.BW_WorldInfo.matchType == MatchType.MT_Season then
        local threeStarConditions =
            configService:GetSeasonMission3StarCondition(self._world.BW_WorldInfo.missionID)
        ---获取三星进度计算服务Star3CalcService
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
            battleStatCmpt:UpdateA3StarProgress(conditionId, ret)
        end
    end

    battleStatCmpt._matchResult = {}
end

---切换主状态
function BattleEnterSystem:_DoLogicSwitchMainFsmState()
    self._world:EventDispatcher():Dispatch(GameEventType.BattleEnterFinish, 1)
end

function BattleEnterSystem:_DoCreateIntensifyBuffMap()
    local petGroup = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID)
    local pets = petGroup:GetEntities()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    for _, petEntity in ipairs(pets) do
        ---@type BuffIntensifyParam[]
        local equipIntensifyParams = petEntity:SkillInfo():GetEquipIntensifyParam()
        if equipIntensifyParams then
            battleStatCmpt:AddBuffIntensifyParam(equipIntensifyParams)
        end
    end
end

--被动技能
function BattleEnterSystem:_DoLogicSetPetPassiveSkill()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local teamEntities = self._world:Player():GetAllTeamEntities()
    for _, teamEntity in ipairs(teamEntities) do
        buffLogicService:BuildPetPassiveSkill(teamEntity)
    end
end

function BattleEnterSystem:_DoLogicSetPetIntensifyBuff()
    local teamEntities = self._world:Player():GetAllTeamEntities()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    for _, teamEntity in ipairs(teamEntities) do
        buffLogicService:BuildPetIntensifyBuff(teamEntity)
    end
end

function BattleEnterSystem:_DoLogicGetPieceRefreshType()
    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    return affixSvc:ReplacePieceRefreshType()
end

---逻辑组装feature
function BattleEnterSystem:_DoLogicAssembleFeature()
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        if featureLogicSvc:CanEnableFeature() then
            featureLogicSvc:DoInitFeatureList()
        end
    end
end

-----------------------------------装备精炼-----------------------------------
function BattleEnterSystem:_DoLogicCreateEquipRefineIntensifyBuffMap()
    local petGroup = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID)
    local pets = petGroup:GetEntities()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    for _, petEntity in ipairs(pets) do
        ---@type BuffIntensifyParam[]
        local equipIntensifyParams = petEntity:EquipRefine():GetEquipRefineIntensifyParam()
        if equipIntensifyParams then
            battleStatCmpt:AddBuffEquipRefineParam(equipIntensifyParams)
        end
    end
end

function BattleEnterSystem:_DoLogicSetEquipRefineBuff()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local teamEntities = self._world:Player():GetAllTeamEntities()
    for _, teamEntity in ipairs(teamEntities) do
        buffLogicService:BuildPetEquipRefineBuff(teamEntity)
    end
end

function BattleEnterSystem:_DoLogicSetEquipRefineIntensifyBuff()
end
-----------------------------------装备精炼End-----------------------------------
function BattleEnterSystem:_DoLogicNotifyPetCreate(teamEntity)
    if not teamEntity then 
        Log.warn("no team entity created")
        return 
    end

    local teamEntities = teamEntity:Team():GetTeamPetEntities()
    for _, petEntity in ipairs(teamEntities) do
        ---@type ElementComponent
        local elementComponent = petEntity:Element()
        local element = elementComponent:GetPrimaryType()
        ---@type PetPstIDComponent
        local petPstIDComponent = petEntity:PetPstID()
        local campID = petPstIDComponent:GetPetCampID()
        self._world:GetService("Trigger"):Notify(NTPetCreate:New(element, campID, petEntity))
    end
end

------------------------------------表现接口----------------------------------

---客户端的表现函数
function BattleEnterSystem:_DoRenderShowBattleEnter(TT, teamEntity)
end
---客户端重写此表现方法
function BattleEnterSystem:_DoRenderShowBoard(TT)
end

---展示玩家开场，由客户端实现
function BattleEnterSystem:_DoRenderShowPet(TT, teamEntity)
end

---组装feature的表现
function BattleEnterSystem:_DoRenderAssembleFeature(TT)
end