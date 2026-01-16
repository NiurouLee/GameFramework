--[[------------------------------------------------------------------------------------------
    WaitInputSystem：等待玩家输入
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class WaitInputSystem:MainStateSystem
_class("WaitInputSystem", MainStateSystem)
WaitInputSystem = WaitInputSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function WaitInputSystem:_GetMainStateID()
    return GameStateID.WaitInput
end

---@param TT token 协程识别码，服务端环境下是nil
function WaitInputSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    self:ClearPreviewChainPathData()
    ---传送门的预览效果会有个BUG，没有清理掉，msg19942
    ---这里临时改一下，强制删除传送门的预览效果
    ---传送门的预览机制需要重构
    self:_DoRenderStopPortalPreview(TT)

    self:_DoLogicPetClearSelectTeamPos()

    ---计算三星进度
    self:_DoLogicCalc3StarProgress()

    ---计算三星奖励
    self:_DoLogicCalcBonusObjective()

    ---重置表现的战斗状态
    self:_DoRenderResetBattleState()

    ---重置一些战斗状态
    self:_DoLogicRestBattleState()

    ---重置格子动画
    self:_DoRenderPieceAnimation(TT)

    --TODO 大地图模式相机跟随
    --self:_DoRenderCameraFollowHero()

    --触发buff
    self:_DoLogicWaitInputBuff()
    self:_DoRenderPlayWaitInputBuff(TT)

    ---直接显示玩家头像列表
    self:_DoRenderShowPetHeadUI(TT)

    ---先等待所有动画结束
    self:_DoRenderWaitDeathEnd(TT)

    local isStun = self:_DoLogicCheckPlayerStun(teamEntity)
    if isStun then
        self:_DoLogicPlayerBuffDelayed(teamEntity)
        self:_DoRenderPlayerBuffDelayed(TT, teamEntity)
        ---等待玩家眩晕
        self:_DoRenderWaitStun(TT)
        --回合结束
        self:_GotoNextTurn()
        return
    end

    --[[ 备注
    此处有坑，会调用两次，后续若有Bug可从此处入手
    _DoRenderGuidePlayer触发引导极光时刻，但在下面的函数_DoRenderShowAuroraTime中会被再次调用
    查看代码提交记录，此接口在状态机调整过程中被删掉，后又被加回，多次代码迭代，无法明确真实原因
    目前无BUG，所以暂不修改]]
    --触发引导
    self:_DoRenderGuidePlayer(TT)

    --极光时刻表现
    self:_DoRenderShowAuroraTime(TT)

    ---处理进入玩家回合后的表现
    self:_DoRenderShowPlayerTurnInfo(TT, teamEntity)

    --逻辑表现棋盘数据同步
    self:_DoL2RBoardLogicData()

    --比对逻辑血量和表现血量
    self:_DoRenderCompareHPLog(TT)

    --对比格子类型数据
    self:_DoRenderComparePieceType(TT)

    --设置预览队伍
    self:_DoRenderSetPreviewTeam(teamEntity)

    self:_DoLogicUpdateMatchData(teamEntity)

    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        ---重启输入
        self:_DoLogic_EnableHandleInput()
    else --敌方回合
        self:_DoRenderAutoFight(TT, teamEntity)
    end
end

function WaitInputSystem:_GotoNextTurn()
    if self._world:MatchType() == MatchType.MT_BlackFist then
        --跳转对方回合
       self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 5)
    else
        --跳转怪物回合
       self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 4)
    end
end

--允许输入
function WaitInputSystem:_DoLogic_EnableHandleInput()
    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    gameFsmCmpt:EnableHandleInput(true)
    self._world:EventDispatcher():Dispatch(GameEventType.BanAutoFightBtn, false)
    self._world:GetDataLogger():AddDataLog("OnShowEnd")
    self._world:GetDataLogger():AddDataLog("OnLinkStart")
end

function WaitInputSystem:_DoLogicCalc3StarProgress()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

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
        local star3CalcService = self._world:GetService("Star3Calc")
        for _, conditionId in ipairs(threeStarConditions) do
            local ret = star3CalcService:CalcProgress(conditionId)
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
end

---结算三星奖励是否完成
function WaitInputSystem:_DoLogicCalcBonusObjective()
    ---@type BonusCalcService
    local bonusCalcService = self._world:GetService("BonusCalc")
    local star3CalcService = self._world:GetService("Star3Calc")
    local conditionParser = ObjectiveConditionParamParser:New()
    local calcResultArray = {}

    local conditionIDArray = self._world.BW_WorldInfo.bonusCondition
    for _, conditionID in ipairs(conditionIDArray) do
        local conditionData = Cfg.cfg_threestarcondition[conditionID]
        if conditionData == nil then
            return
        end
        local conditionType = conditionData.ConditionType
        --local conditionParamArray = conditionData.ConditionNumber
        local conditionParamArray = star3CalcService:GetConditionNumber(conditionID)
        local conditionParam = conditionParser:ParseObjectiveConditionParam(conditionType, conditionParamArray)
        if conditionParam == nil then
            calcResultArray[#calcResultArray + 1] = conditionID
        else
            local matchRes = bonusCalcService:CalcCondition(conditionType, conditionParam)
            if matchRes == true then
                calcResultArray[#calcResultArray + 1] = conditionID
            end
        end
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetBonusMatchResult(calcResultArray)
end

function WaitInputSystem:_DoLogicRestBattleState()
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    ---进入等待输入状态，可以清理一次数据
    battleService:SetLogicComboNum(0)
    battleService:SetLogicChainNum(0)

    --计数（用于调试，客户端和服务器不一样）
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:IncWaitInputCount()
end


function WaitInputSystem:_DoLogicCheckPlayerStun(teamEntity)
    if teamEntity == nil then 
        return false
    end

    ---@type BuffComponent
    local buffCmpt = teamEntity:BuffComponent()
    local isStun = buffCmpt:HasFlag(BuffFlags.SkipTurn)
    return isStun
end

function WaitInputSystem:_DoLogicWaitInputBuff()
    self._world:GetService("Trigger"):Notify(NTWaitInput:New())
end

function WaitInputSystem:_DoL2RBoardLogicData()
    --更新逻辑数据
    local t = self._world:GetService("BoardLogic"):CalcPieceEntities()
    self._world:GetBoardEntity():Board():SetPieceEntities(t)

    --多面棋盘更新
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local multiBoard = levelConfigData:GetMultiBoard()
    if multiBoard and table.count(multiBoard) > 0 then
        ---@type BoardMultiServiceLogic
        local boardMultiServiceLogic = self._world:GetService("BoardMultiLogic")
        ---@type BoardMultiComponent
        local boardMultiComponent = self._world:GetBoardEntity():BoardMulti()
        local entities = boardMultiServiceLogic:GetEntityGroup()
        for i, boardInfo in ipairs(multiBoard) do
            local boardIndex = boardInfo.index
            local pieceEntities = boardMultiServiceLogic:CalcPieceEntities(entities, boardIndex)
            boardMultiComponent:SetPieceEntities(boardIndex, pieceEntities)
        end
        boardMultiServiceLogic:SaveMonsterIDCmptOnOutsideRegion()
    end
    --离场怪处理 （符文刺客）
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    boardSvc:SaveMonsterIDCmptOffBoard()
    --更新表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end

function WaitInputSystem:_DoLogicUpdateMatchData(teamEntity)
    if self._world:RunAtServer() then
        ---@type CoreGameLogic
        local logic = self._world:GetCoreGameLogic()
        if logic:IsRunningAI() then
            local actorID=logic:GetActorID()
            local data = logic:GetAIData()
            update_match_state(actorID, data)
            
            --测试一下，原地双击
            ---@type BattleStatComponent
            local battleStatCmpt = self._world:BattleStat()
            local cmd = MovePathDoneCommand:New()
            cmd:SetChainPath({teamEntity:GetGridPosition()})
            cmd:SetElementType(0)
            cmd.EntityID = 2
            cmd.RoundCount = battleStatCmpt:GetGameRoundCount()
            cmd.IsAutoFight = battleStatCmpt:GetAutoFight()
            cmd.ClientWaitInput = battleStatCmpt:GetWaitInputCount()
            logic:DoAICommand(cmd)
        end
    end
end

function WaitInputSystem:_DoLogicPetClearSelectTeamPos()
    local groupEntity = self._world:GetGroupEntities(self._world.BW_WEMatchers.Team)
    for _, e in ipairs(groupEntity) do
        e:Team():ClearSelectedTeamOrderPosition()
    end
end

function WaitInputSystem:_DoLogicPlayerBuffDelayed(teamEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:CalcPlayerBuffDelayedTurn(teamEntity)
end

----------------------------------表现接口-----------------------------------
function WaitInputSystem:_DoRenderStopPortalPreview(TT)
end

function WaitInputSystem:_DoRenderPieceAnimation(TT)
end

function WaitInputSystem:_DoRenderGuidePlayer(TT)
end

function WaitInputSystem:_DoRenderWaitStun(TT)
end

function WaitInputSystem:_DoRenderShowPlayerTurnInfo(TT, teamEntity)
end

function WaitInputSystem:_DoRenderShowAuroraTime(TT)
end

function WaitInputSystem:_DoRenderCameraFollowHero(TT)
end

function WaitInputSystem:_DoRenderShowPetHeadUI(TT)
end

function WaitInputSystem:_DoRenderCompareHPLog(TT)
end

function WaitInputSystem:_DoRenderResetBattleState(TT)
end

function WaitInputSystem:_DoRenderPlayWaitInputBuff(TT)
end

function WaitInputSystem:_DoRenderComparePieceType(TT)
end
function WaitInputSystem:ClearPreviewChainPathData()
end

function WaitInputSystem:_DoRenderAutoFight(TT, teamEntity)
end

function WaitInputSystem:_DoRenderSetPreviewTeam(teamEntity)
end
function WaitInputSystem:_DoRenderPlayerBuffDelayed(TT)
end