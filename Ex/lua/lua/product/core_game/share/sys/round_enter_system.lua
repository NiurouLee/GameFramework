--[[------------------------------------------------------------------------------------------
    RoundEnterSystem：回合开始状态
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class RoundEnterSystem:MainStateSystem
_class("RoundEnterSystem", MainStateSystem)
RoundEnterSystem = RoundEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function RoundEnterSystem:_GetMainStateID()
    return GameStateID.RoundEnter
end

---@param TT token 协程识别码，服务端是nil
function RoundEnterSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    Log.debug("RoundEnterSystem GameTurn=", GetEnumKey("GameTurnType", self._world:GetGameTurn()))

    --回合计数(极光时刻不增加回合数)
    local incRound, curWaveRound = self:_DoLogicIncRoundCount()

    ---MSG49015：增加空惩罚回合
    local damageInfo, isWarnRound = self:_DoLogicTryPunishmentRoundEnter()
    self:_DoRenderPunishmentRoundEnter(TT, damageInfo, isWarnRound)

    ---MSG50474，回合数不足的扣血机制需要另外判断是否直接结束，内部有判断逻辑
    if self:_ShouldGotoNextStateForPunishmentRound() then
        self:_DoLogicGotoNextStateForPunishmentRound()
        return
    end

    ---计算玩家行动前机关AI
    self:_DoLogicTrapBeforePlayer()
    ---表现玩家行动前机关AI
    self:_DoRenderTrapBeforePlayer(TT)

    --怪物死亡结算
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)

    ---显示玩家头像列表
    self:_DoRenderShowPetUI(TT, curWaveRound)

    ---显示玩家回合
    self:_DoRenderShowPetTurnTips(TT)

    --黑拳赛不加回合数也要计算buff（我和敌方在一个回合）
    local calcBuff = false
    if self._world:MatchType() == MatchType.MT_BlackFist then
        calcBuff = not self._world:BattleStat():IsRoundAuroraTime()
    else
        calcBuff = incRound
    end

    if calcBuff then
        ---更新Buff
        -- 这里返回的是通知生效前的teamOrder（复制品），因为这个没有表现数据，逻辑执行后会发生改变
        local formerTeamOrder = self:_DoLogicPlayerTurnBuff(teamEntity)

        ---通知Buff表现
        self:_DoRenderPlayerTurnBuff(TT, teamEntity, formerTeamOrder)
    end
    if self._world:MatchType() == MatchType.MT_Chess then
        ---所有棋子刷新buff回合
        self:_DoLogicChessTurnBuff()
        self:_DoRenderChessTurnBuff(TT)
    end
	
    --怪物死亡结算
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT)
    self:_DoLogicTrapDie()
    self:_DoRenderTrapDie(TT)

    local ntTeamOrderChange = self:_DoLogicPetDead(teamEntity)
    self:_DoRenderPetDead(TT, teamEntity, ntTeamOrderChange)

    ---先等待所有动画结束
    self:_DoRenderWaitDeathEnd(TT)

    ---清理所有带DeadFlag的Entity
    self:_DoLogicClearDeadEntity()

    ---更新星灵的CD
    if incRound then
        local tAllNotifyArray = self:_DoLogicUpdatePetPower(teamEntity, incRound)
        self:_DoRenderUpdatePetPower(TT, tAllNotifyArray)
    end
    self:_DoLogicSaveRoundBeginPlayerPos(teamEntity)
    self:_DoRenderSaveRoundBeginPlayerPos(TT, teamEntity)

    if self._world:MatchType() == MatchType.MT_Chess then
        ---所有棋子刷新状态
        self:_DoLogicResetChessPetFinishState()
        self:_DoRenderResetChessPetFinishState(TT)
    end
    ---模块
    self:_DoLogicFeatureOnRoundEnter(incRound)
    self:_DoRenderFeatureOnRoundEnter(TT)

    --刷新怪物反制状态
    if incRound then
        self:_DoLogicRefreshMonsterAntiActiveSkill()
        self:_DoRenderRefreshMonsterAntiActiveSkill(TT)
    end

    --记录当前的快照
    self:_DoLogicTakeSnapshot()

    --状态切换
    self:_DoLogicGotoNextState()
end

function RoundEnterSystem:_DoLogicGotoNextState()
    ---检查是不是战斗结束
    local isBattleEnd = self:_IsBattleEnd()
    if isBattleEnd then
        self._world:EventDispatcher():Dispatch(GameEventType.RoundEnterFinish, 2)
        return
    end
    ---检查是不是需要开局选圣物
    local isChooseRelic = self:_NeedChooseRelicInOpening()
    if isChooseRelic then
        self._world:EventDispatcher():Dispatch(GameEventType.RoundEnterFinish, 3)
        return
    end
    --切换到waitinput
    self._world:EventDispatcher():Dispatch(GameEventType.RoundEnterFinish, 1)
end

function RoundEnterSystem:_DoLogicIncRoundCount()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local curRound = battleStatCmpt:GetLevelTotalRoundCount()
    local curWaveRound = battleStatCmpt:GetCurWaveRound()
    local followRound = battleStatCmpt:GetGameRoundCount()
    if curRound == followRound then
        return false, curWaveRound
    end
    if self._world:GetGameTurn() ~= GameTurnType.LocalPlayerTurn then
        return false, curWaveRound
    end
    local cnt = battleStatCmpt:IncGameRoundCount()
    --Log.debug("RoundEnterSystem IncGameRoundCount = ", cnt)
    battleStatCmpt:ClearCurRoundDoActiveSkillTimes()--每回合开始清理光灵放主动技次数记录
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local connectRate = boardServiceLogic:GetConnectRate()
    self._world:GetDataLogger():AddDataLog("OnRoundStart", connectRate)
    return true, curWaveRound
end

---@param teamEntiy Entity
function RoundEnterSystem:_DoLogicPlayerTurnBuff(teamEntiy)
    if teamEntiy == nil then
        return
    end
    local formerTeamOrder = teamEntiy:Team():CloneTeamOrder()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")

    buffLogicService:RefreshLockHPLogic()

    buffLogicService:CalcPlayerBuffTurn(teamEntiy)
    return formerTeamOrder
end

function RoundEnterSystem:_DoLogicChessTurnBuff()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    --buffLogicService:RefreshLockHPLogic()
    buffLogicService:CalcChessBuffTurn()
end

---刷新星灵CD
function RoundEnterSystem:_DoLogicUpdatePetPower(teamEntiy, incread)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if not battleStatCmpt:IsFirstRound() then
        return self:_UpdateAllPetPower(teamEntiy, incread)
    end
end
---@param teamEntity Entity
function RoundEnterSystem:_UpdateAllPetPower(teamEntity, incread)
    local tAllNotifyArray = {}
    --teamEntity:Team():GetTeamPetEntities()
    --黑拳赛模式：在我方回合所有队伍的光灵CD-1
    local group = self._world:GetGroup(self._world.BW_WEMatchers.Pet)
    for _, e in ipairs(group:GetEntities()) do
        local tNotify = self:_UpdatePetPower(teamEntity, e, incread)
        table.appendArray(tAllNotifyArray, tNotify)
    end
    return tAllNotifyArray
end
---@param e Entity
function RoundEnterSystem:_UpdatePetPower(teamEntity, e, incread)
    if e:HasPetDeadMark() then
        return
    end
    local petPstIDComponent = e:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    ---@type AttributesComponent
    local attributesComponent = e:Attributes()

    local localSkillID = e:SkillInfo():GetActiveSkillID()
    if not localSkillID then
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        localSkillID = petData:GetPetActiveSkill()
    end
    local extraSkillIDList = e:SkillInfo():GetExtraActiveSkillIDList()
    if extraSkillIDList and #extraSkillIDList > 0 then
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(localSkillID, e)

    local previousReady = attributesComponent:GetAttribute("Ready") == 1
    local ready = 0
    --
    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        --传说光灵
        local legendPower = attributesComponent:GetAttribute("LegendPower")
        -- legendPower = legendPower + BattleConst.RoundAddLegendPower --5点
        if legendPower >= skillConfigData:GetSkillTriggerParam() then
            ready = 1
        end
        self._world:GetSyncLogger():Trace(
            {key = "Update LegendPet Power", entityID = e:GetID(), legendPower = legendPower, ready = ready}
        )
        if legendPower > BattleConst.LegendPowerMax then
            legendPower = BattleConst.LegendPowerMax
        end
        attributesComponent:Modify("LegendPower", legendPower)
        self._world:EventDispatcher():Dispatch(GameEventType.PetLegendPowerChange, petPstID, legendPower, false)
    elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
        -- do nothing here. buff layers do not increased in this way
        ready = attributesComponent:GetAttribute("Ready")
    else
        --光灵
        local power = attributesComponent:GetAttribute("Power")
        local maxPower = skillConfigData:GetSkillTriggerParam()

        if maxPower == 0 then
            ---@type BattleStatComponent
            local battleStatComponent = self._world:BattleStat()
            local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID)
            local curRound = battleStatComponent:GetLevelTotalRoundCount()
            previousReady = previousReady and ((curRound - 1) ~= (lastDoActiveSkillRound))
        end
        ---延迟修改的到回合开始才生效
        local delayChangePowerValue = e:BuffComponent():GetBuffValue("DelayChangePowerValue")
        if delayChangePowerValue and delayChangePowerValue~=0  then
            power = power + delayChangePowerValue
            e:BuffComponent():SetBuffValue("DelayChangePowerValue",0)
        end
        ---@type BattleStatComponent
        local battleStatComponent = self._world:BattleStat()
        if power > 0 then
            -- power = power + 1
            local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID)
            local curRound = battleStatComponent:GetLevelTotalRoundCount()
            -- 需求：放过主动技之后的下一个回合有特殊处理，从灰色cd标志变成满冷却。MSG61097
            if lastDoActiveSkillRound then
                ---由于现在是WaitInPut处理的CD 所以要大于1
                if (curRound - lastDoActiveSkillRound) > 1 then
                    power = power - 1
                end
            else
                if incread then
                    power = power - 1
                end
            end
        end
        if power <= 0 then
            power = 0
            ready = 1
        end

        self._world:GetSyncLogger():Trace({key = "UpdatePetPower", entityID = e:GetID(), power = power, ready = ready})
        attributesComponent:Modify("Power", power)
        self._world:EventDispatcher():Dispatch(GameEventType.PetPowerChange, petPstID, power, false)
        --怪物攻击玩家增加CD，有个UI红光动画
        local isAddPetPower = e:BuffComponent():GetBuffValue("AddPetPower") or 0
        if isAddPetPower == 1 then
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, petPstID)
            e:BuffComponent():SetBuffValue("AddPetPower", 0)
        end
    end

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    blsvc:ChangePetActiveSkillReady(e, ready)

    local tNotifyArray = {}
    if ready == 1 then
        --cd积攒回合数
        teamEntity:ActiveSkill():AddPowerfullRoundCount(e:GetID(), 1)
        if previousReady then
            teamEntity:ActiveSkill():AddPreviousReadyRoundCount(e:GetID(), 1)
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, false)
            local notify = NTPetActiveSkillPreviousReady:New(e)
            table.insert(tNotifyArray, notify)
            self._world:GetService("Trigger"):Notify(notify)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, true)
            ---@type GuideServiceRender
            local guideService = self._world:GetService("Guide")
            if guideService ~= nil then
                local guideTaskId = guideService:Trigger(GameEventType.ShowGuidePowerReady, e)
            end
            local notify = NTPowerReady:New(e)
            table.insert(tNotifyArray, notify)
            self._world:GetService("Trigger"):Notify(notify)
        end
    end
    self:_UpdatePetExtraSkillPower(teamEntity,e,incread,tNotifyArray)
    return tNotifyArray
end
--临时只处理 能量点的附加技能（仲胥二技能） 不发通知 sjs_todo
function RoundEnterSystem:_UpdatePetExtraSkillPower(teamEntity, e, incread,tNotifyArray)
    if e:HasPetDeadMark() then
        return
    end
    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local petPstIDComponent = e:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    ---@type AttributesComponent
    local attributesComponent = e:Attributes()

    local extraSkillIDList = e:SkillInfo():GetExtraActiveSkillIDList()
    ---@type SkillInfoComponent
    local skillInfoCmpt = e:SkillInfo()
    if extraSkillIDList and #extraSkillIDList > 0 then
        for index, localSkillID in ipairs(extraSkillIDList) do
            local ignoreUpdate = skillInfoCmpt:IsExtraSkillIgnoreCdUpdate(index)
            if not ignoreUpdate then
                ---@type SkillConfigData
                local skillConfigData = configService:GetSkillConfigData(localSkillID, e)

                local readyAttr = utilData:GetPetSkillReadyAttr(e,localSkillID)
                local previousReady = (readyAttr == 1)
                local ready = 0
                --
                if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
                    --传说光灵
                    local legendPower = attributesComponent:GetAttribute("LegendPower")
                    -- legendPower = legendPower + BattleConst.RoundAddLegendPower --5点
                    
                    local minCost = blsvc:CalcMinCostByExtraParam(e,localSkillID)
                    if legendPower >= minCost then
                        ready = 1
                    end
                    -- self._world:GetSyncLogger():Trace(
                    --     {key = "Update LegendPet Power", entityID = e:GetID(), legendPower = legendPower, ready = ready}
                    -- )
                    if legendPower > BattleConst.LegendPowerMax then
                        legendPower = BattleConst.LegendPowerMax
                    end
                    attributesComponent:Modify("LegendPower", legendPower)
                    self._world:EventDispatcher():Dispatch(GameEventType.PetLegendPowerChange, petPstID, legendPower, false)
                --其他类型附加主动技暂不处理 sjs_todo
                elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
                    -- do nothing here. buff layers do not increased in this way
                    ready = attributesComponent:GetAttribute("Ready")
                else
                    --光灵
                    local power = utilData:GetPetPowerAttr(e,localSkillID)
                    local maxPower = utilData:GetPetMaxPowerAttr(e,localSkillID)

                    if maxPower == 0 then
                        ---@type BattleStatComponent
                        local battleStatComponent = self._world:BattleStat()
                        local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID,index)
                        local curRound = battleStatComponent:GetLevelTotalRoundCount()
                        previousReady = previousReady and ((curRound - 1) ~= (lastDoActiveSkillRound))
                    end
                    ---延迟修改的到回合开始才生效
                    -- local delayChangePowerValue = e:BuffComponent():GetBuffValue("DelayChangePowerValue")
                    -- if delayChangePowerValue and delayChangePowerValue~=0  then
                    --     power = power + delayChangePowerValue
                    --     e:BuffComponent():SetBuffValue("DelayChangePowerValue",0)
                    -- end
                    ---@type BattleStatComponent
                    local battleStatComponent = self._world:BattleStat()
                    if power > 0 then
                        -- power = power + 1
                        local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID,index)
                        local curRound = battleStatComponent:GetLevelTotalRoundCount()
                        if lastDoActiveSkillRound then
                            ---由于现在是WaitInPut处理的CD 所以要大于1
                            if (curRound - lastDoActiveSkillRound) > 1 then
                                power = power - 1
                            end
                        else
                            if incread then
                                power = power - 1
                            end
                        end
                    end
                    if power <= 0 then
                        power = 0
                        ready = 1
                    end

                    self._world:GetSyncLogger():Trace({key = "UpdatePetPower", entityID = e:GetID(), power = power, ready = ready})
                    --attributesComponent:Modify("Power", power)
                    utilData:SetPetPowerAttr(e,power,localSkillID)
                    self._world:EventDispatcher():Dispatch(GameEventType.PetExtraPowerChange, petPstID, localSkillID, power, false)
                    --怪物攻击玩家增加CD，有个UI红光动画
                    -- local isAddPetPower = e:BuffComponent():GetBuffValue("AddPetPower") or 0
                    -- if isAddPetPower == 1 then
                    --     self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, petPstID)
                    --     e:BuffComponent():SetBuffValue("AddPetPower", 0)
                    -- end
                end

                ---@type BuffLogicService
                local blsvc = self._world:GetService("BuffLogic")
                blsvc:ChangePetActiveSkillReady(e, ready,localSkillID)
                if ready == 1 then
                    --cd积攒回合数
                    --teamEntity:ActiveSkill():AddPowerfullRoundCount(e:GetID(), 1)
                    if previousReady then
                        --teamEntity:ActiveSkill():AddPreviousReadyRoundCount(e:GetID(), 1)
                        self._world:EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillGetReady, petPstID, localSkillID, false)
                        -- local notify = NTPetActiveSkillPreviousReady:New(e)
                        -- table.insert(tNotifyArray, notify)
                        -- self._world:GetService("Trigger"):Notify(notify)
                    else
                        self._world:EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillGetReady, petPstID, localSkillID, true)
                        ---@type GuideServiceRender
                        -- local guideService = self._world:GetService("Guide")
                        -- if guideService ~= nil then
                        --     local guideTaskId = guideService:Trigger(GameEventType.ShowGuidePowerReady, e)
                        -- end
                        -- local notify = NTPowerReady:New(e)
                        -- table.insert(tNotifyArray, notify)
                        -- self._world:GetService("Trigger"):Notify(notify)
                    end
                end
                --通知也暂不处理 sjs_todo
                -- if ready == 1 then
                --     --cd积攒回合数
                --     teamEntity:ActiveSkill():AddPowerfullRoundCount(e:GetID(), 1)
                --     if previousReady then
                --         teamEntity:ActiveSkill():AddPreviousReadyRoundCount(e:GetID(), 1)
                --         self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, false)
                --         local notify = NTPetActiveSkillPreviousReady:New(e)
                --         table.insert(tNotifyArray, notify)
                --         self._world:GetService("Trigger"):Notify(notify)
                --     else
                --         self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, true)
                --         ---@type GuideServiceRender
                --         local guideService = self._world:GetService("Guide")
                --         if guideService ~= nil then
                --             local guideTaskId = guideService:Trigger(GameEventType.ShowGuidePowerReady, e)
                --         end
                --         local notify = NTPowerReady:New(e)
                --         table.insert(tNotifyArray, notify)
                --         self._world:GetService("Trigger"):Notify(notify)
                --     end
                -- end
            end
        end
    end
    
end

function RoundEnterSystem:_DoLogicTakeSnapshot()
    --对局记录日志
    local logger = self._world:GetMatchLogger()
    logger:TakeSnapshot()

    if not _G.ENABLE_SYNC_LOG then
        return
    end
    --同步日志
    ---@type BoardEntity
    local boardEntity = self._world:GetBoardEntity()
    local blockFlags = boardEntity:Board():GetBlockFlagArray()
    local pieceTypes = boardEntity:Board().Pieces
    --阻挡信息
    local blockLog = {}
    for x, row in pairs(blockFlags) do
        for y, v in pairs(row) do
            local block = v:GetBlock()
            if block > 0 then
                blockLog[x * 100 + y] = block
            end
        end
    end
    self._world:GetSyncLogger():Trace({key = "BlockFlags", blockFlags = blockLog})

    --颜色信息
    local pieceLog = {}
    for x, row in pairs(pieceTypes) do
        for y, v in pairs(row) do
            pieceLog[x * 100 + y] = v
        end
    end
    self._world:GetSyncLogger():Trace({key = "PieceTypes", pieceTypes = pieceLog})
    if self._world and self._world:IsDevelopEnv() then
        Log.debug("RoundEnterSystem BoardPieceTypes:", echo_one_line(ELogLevel.Debug,pieceLog))
    end

    --血量信息
    local hpLog = {}
    local attrGroup = self._world:GetGroup(self._world.BW_WEMatchers.Attributes)
    for i, e in ipairs(attrGroup:GetEntities()) do
        local val = e:Attributes():GetCurrentHP()
        if val then
            hpLog[e:GetID()] = val
        end
    end
    self._world:GetSyncLogger():Trace({key = "EntityHP", entityHP = hpLog})

    --位置信息
    local posLog = {}
    local posGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridLocation)
    for i, e in ipairs(posGroup:GetEntities()) do
        local pos = e:GridLocation():GetGridPos()
        if e:GetID() < 100000000 and not e:Piece() then
            posLog[e:GetID()] = math.floor(pos.x * 100 + pos.y)
        end
    end
    self._world:GetSyncLogger():Trace({key = "EntityPos", entityPos = posLog})
end

function RoundEnterSystem:_DoLogicTrapBeforePlayer()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:TrapActionBeforePlayer()
end

---@param teamEntity Entity
function RoundEnterSystem:_DoLogicSaveRoundBeginPlayerPos(teamEntity)
    if teamEntity == nil then
        return
    end

    local playerPos = teamEntity:GetGridPosition()
    self._world:BattleStat():SetRoundBeginPlayerPos(playerPos)
    self._world:GetService("Trigger"):Notify(NTSaveRoundBeginPlayerPosEnd:New(teamEntity))
end

---重置行动标记
function RoundEnterSystem:_DoLogicResetChessPetFinishState()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for i, v in ipairs(group:GetEntities()) do
        ---@type ChessPetComponent
        local chessPetCmpt = v:ChessPet()
        ---@type BuffComponent
        local buffCmpt = v:BuffComponent()
        local isSkipTurn = buffCmpt:HasFlag(BuffFlags.SkipTurn)
        if not isSkipTurn then
            chessPetCmpt:SetChessPetFinishTurn(false)
        end
    end
end
---模块处理
function RoundEnterSystem:_DoLogicFeatureOnRoundEnter(incRound)
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        if featureLogicSvc:CanEnableFeature() then
            featureLogicSvc:DoFeatureOnRoundEnter(incRound)
        end
    end
end

---@return DamageInfo|nil
function RoundEnterSystem:_DoLogicTryPunishmentRoundEnter()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    if levelConfigData:GetOutOfRoundType() == 0 then
        return
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local punishmentRoundCount = battleStatCmpt:GetCurWavePunishmentRoundCount()
    if punishmentRoundCount == 0 then
        return
    end

    if battleStatCmpt:IsPunishmentRoundExecuted(punishmentRoundCount) then
        return
    end

    --MSG48979：第一次回合用尽为空惩罚回合
    if punishmentRoundCount == 1 then
        battleStatCmpt:MarkPunishmentRoundExecuted(punishmentRoundCount)
        return nil, true
    end

    --MSG48979：实际惩罚从第二回合开始
    local realPunishmentRoundCount = punishmentRoundCount - 1

    local punishPercent = 0
    for round, percent in pairs(BattleConst.PunishmentRoundHPPercent) do
        if round <= realPunishmentRoundCount then
            punishPercent = percent
        end
    end

    if punishPercent <= 0 then
        return
    end

    --需求没有明确提出对黑拳赛的要求
    ---@type Entity
    local eTeam = self._world:Player():GetLocalTeamEntity()
    local maxHP = eTeam:Attributes():CalcMaxHp()
    local val = maxHP * punishPercent
    ---@type CalcDamageService
    local lsvcCalcDamage = self._world:GetService("CalcDamage")
    local damageInfo = lsvcCalcDamage:DoCalcDamage(eTeam, eTeam, {
        formulaID = 130,
        hp = val,
        skillID = 0
    }, true)

    battleStatCmpt:MarkPunishmentRoundExecuted(punishmentRoundCount)

    return damageInfo
end

function RoundEnterSystem:_DoLogicRefreshMonsterAntiActiveSkill()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = configService:GetMonsterConfigData()

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local monsterID = e:MonsterID():GetMonsterID()

        --新QA 反制参数可以通过精英buff赋值，这些可以反制的怪物在配置里是没有的，所以不能再直接取monsterClass的值了
        ---@type AttributesComponent
        local attributeCmpt = e:Attributes()
        local originalMax = attributeCmpt:GetAttribute("OriginalMaxAntiSkillCountPerRound")
        if originalMax ~= 0 then
            local originalCount = attributeCmpt:GetAttribute("OriginalWaitActiveSkillCount")
            attributeCmpt:Modify("WaitActiveSkillCount", originalCount)
            attributeCmpt:Modify("MaxAntiSkillCountPerRound", originalMax)
        end

        -- --反制AI的参数 都还原成配置的
        -- local antiAttackParam = monsterConfigData:GetMonsterAntiAttackParam(monsterID)
        -- if antiAttackParam then
        --     ---@type AttributesComponent
        --     local attributeCmpt = e:Attributes()
        --     attributeCmpt:Modify("WaitActiveSkillCount", antiAttackParam.WaitActiveSkillCount)
        --     attributeCmpt:Modify("MaxAntiSkillCountPerRound", antiAttackParam.MaxAntiSkillCountPerRound)
        -- end
    end
end

function RoundEnterSystem:_ShouldGotoNextStateForPunishmentRound()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    if levelConfigData:GetOutOfRoundType() == 0 then
        return false
    end

    --[[
    路万博(@PLM) 9-27 13:32:15
    有一个需求上的问题，是只判断玩家是否死亡，还是和整体逻辑的判断一致，判断战斗是否结束（包括守护机关判断、特殊boss机制判断和胜利条件判断）

    午蔚刚 9-27 14:13:31
    这里应该只需要判断死亡，应该不会触发其他的战斗结束
    ]]

    local teamEntity = self._world:Player():GetLocalTeamEntity()
    --玩家死亡战斗结束
    if teamEntity and self:IsPlayerDead(teamEntity) then
        return true
    end
end

--[[
    午蔚刚 9-27 11:22:11
    [Photo]大航海有个bug，我想的是在回合开始扣血之后加入一个死亡的判定，如果血量为0就直接结算死亡，这个可行吗
]]
function RoundEnterSystem:_DoLogicGotoNextStateForPunishmentRound()
    self._world:EventDispatcher():Dispatch(GameEventType.RoundEnterFinish, 2)
end

---@return boolean
function RoundEnterSystem:_NeedChooseRelicInOpening()
    if self._world:MatchType() ~= MatchType.MT_MiniMaze then
        return false
    end

    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    return talentSvc:NeedChooseOpeningRelic()
end

-----------------------------------------------------------

function RoundEnterSystem:_DoRenderShowPetUI(TT, curWaveRound)
end

function RoundEnterSystem:_DoRenderShowPetTurnTips(TT)
end
function RoundEnterSystem:_DoRenderPlayerTurnBuff(TT)
end
function RoundEnterSystem:_DoRenderChessTurnBuff(TT)
end

function RoundEnterSystem:_DoRenderUpdatePetPower(TT, tNotifyArray)
end

function RoundEnterSystem:_DoRenderTrapBeforePlayer(TT)
end

---播放重置棋子行动状态的表现接口
function RoundEnterSystem:_DoRenderResetChessPetFinishState(TT)
end
---模块
function RoundEnterSystem:_DoRenderFeatureOnRoundEnter(TT)
end

function RoundEnterSystem:_DoRenderSaveRoundBeginPlayerPos(TT, teamEntity)
end

function RoundEnterSystem:_DoRenderPunishmentRoundEnter()
end

function RoundEnterSystem:_DoRenderRefreshMonsterAntiActiveSkill(TT)
end
