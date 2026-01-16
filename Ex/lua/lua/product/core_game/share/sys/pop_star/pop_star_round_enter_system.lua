--[[------------------------------------------------------------------------------------------
    PopStarRoundEnterSystem：消灭星星回合开始状态
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

---@class PopStarRoundEnterSystem:MainStateSystem
_class("PopStarRoundEnterSystem", MainStateSystem)
PopStarRoundEnterSystem = PopStarRoundEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarRoundEnterSystem:_GetMainStateID()
    return GameStateID.PopStarRoundEnter
end

---@param TT token 协程识别码，服务端是nil
function PopStarRoundEnterSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    --回合计数
    local incRound, curWaveRound = self:_DoLogicIncRoundCount()

    ---计算玩家行动前机关AI
    self:_DoLogicTrapBeforePlayer()
    ---表现玩家行动前机关AI
    self:_DoRenderTrapBeforePlayer(TT)

    ---显示玩家头像列表
    self:_DoRenderShowPetUI(TT, curWaveRound)

    ---回合增加，计算Buff
    if incRound then
        ---更新Buff
        -- 这里返回的是通知生效前的teamOrder（复制品），因为这个没有表现数据，逻辑执行后会发生改变
        local formerTeamOrder = self:_DoLogicPlayerTurnBuff(teamEntity)

        ---通知Buff表现
        self:_DoRenderPlayerTurnBuff(TT, teamEntity, formerTeamOrder)
    end

    --机关死亡结算
    self:_DoLogicTrapDie()
    self:_DoRenderTrapDie(TT)

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

    ---模块
    self:_DoLogicFeatureOnRoundEnter(incRound)
    self:_DoRenderFeatureOnRoundEnter(TT)

    --记录当前的快照
    self:_DoLogicTakeSnapshot()

    --状态切换
    self:_DoLogicSwitchState()
end

function PopStarRoundEnterSystem:_DoLogicIncRoundCount()
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
    --Log.debug("PopStarRoundEnterSystem IncGameRoundCount = ", cnt)
    battleStatCmpt:ClearCurRoundDoActiveSkillTimes() --每回合开始清理光灵放主动技次数记录
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local connectRate = boardServiceLogic:GetConnectRate()
    self._world:GetDataLogger():AddDataLog("OnRoundStart", connectRate)
    return true, curWaveRound
end

function PopStarRoundEnterSystem:_DoLogicTrapBeforePlayer()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:TrapActionBeforePlayer()
end

---@param teamEntity Entity
function PopStarRoundEnterSystem:_DoLogicPlayerTurnBuff(teamEntity)
    if teamEntity == nil then
        return
    end
    local formerTeamOrder = teamEntity:Team():CloneTeamOrder()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:CalcPlayerBuffTurn(teamEntity)
    return formerTeamOrder
end

--region 刷新光灵CD
---@param teamEntity Entity
---@param incRound boolean
function PopStarRoundEnterSystem:_DoLogicUpdatePetPower(teamEntity, incRound)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if not battleStatCmpt:IsFirstRound() then
        return self:_UpdateAllPetPower(teamEntity, incRound)
    end
end

---@param teamEntity Entity
---@param incRound boolean
function PopStarRoundEnterSystem:_UpdateAllPetPower(teamEntity, incRound)
    local tAllNotifyArray = {}
    local group = self._world:GetGroup(self._world.BW_WEMatchers.Pet)
    for _, petEntity in ipairs(group:GetEntities()) do
        local tNotify = self:_UpdatePetPower(teamEntity, petEntity, incRound)
        table.appendArray(tAllNotifyArray, tNotify)
    end
    return tAllNotifyArray
end

---@param teamEntity Entity
---@param petEntity Entity
---@param incRound boolean
function PopStarRoundEnterSystem:_UpdatePetPower(teamEntity, petEntity, incRound)
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    ---@type AttributesComponent
    local attributesComponent = petEntity:Attributes()

    local localSkillID = petEntity:SkillInfo():GetActiveSkillID()
    if not localSkillID then
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        localSkillID = petData:GetPetActiveSkill()
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(localSkillID, petEntity)

    local previousReady = attributesComponent:GetAttribute("Ready") == 1
    local ready = 0
    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        --传说光灵
        local legendPower = attributesComponent:GetAttribute("LegendPower")
        if legendPower >= skillConfigData:GetSkillTriggerParam() then
            ready = 1
        end
        self._world:GetSyncLogger():Trace(
            { key = "Update LegendPet Power", entityID = petEntity:GetID(), legendPower = legendPower, ready = ready }
        )

        if legendPower > BattleConst.LegendPowerMax then
            legendPower = BattleConst.LegendPowerMax
        end

        attributesComponent:Modify("LegendPower", legendPower)
        self._world:EventDispatcher():Dispatch(GameEventType.PetLegendPowerChange, petPstID, legendPower, false)
    elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
        ---BuffLayer的技能CD不在此更新
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
        local delayChangePowerValue = petEntity:BuffComponent():GetBuffValue("DelayChangePowerValue")
        if delayChangePowerValue and delayChangePowerValue ~= 0 then
            power = power + delayChangePowerValue
            petEntity:BuffComponent():SetBuffValue("DelayChangePowerValue", 0)
        end
        ---@type BattleStatComponent
        local battleStatComponent = self._world:BattleStat()
        if power > 0 then
            local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID)
            local curRound = battleStatComponent:GetLevelTotalRoundCount()
            if lastDoActiveSkillRound then
                ---由于现在是WaitInPut处理的CD 所以要大于1
                if (curRound - lastDoActiveSkillRound) > 1 then
                    power = power - 1
                end
            else
                if incRound then
                    power = power - 1
                end
            end
        end
        if power <= 0 then
            power = 0
            ready = 1
        end

        self._world:GetSyncLogger():Trace(
            { key = "UpdatePetPower", entityID = petEntity:GetID(), power = power, ready = ready }
        )
        attributesComponent:Modify("Power", power)
        self._world:EventDispatcher():Dispatch(GameEventType.PetPowerChange, petPstID, power, false)
        --怪物攻击玩家增加CD，有个UI红光动画
        local isAddPetPower = petEntity:BuffComponent():GetBuffValue("AddPetPower") or 0
        if isAddPetPower == 1 then
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, petPstID)
            petEntity:BuffComponent():SetBuffValue("AddPetPower", 0)
        end
    end

    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    buffSvc:ChangePetActiveSkillReady(petEntity, ready)

    local tNotifyArray = {}
    if ready == 1 then
        --cd积攒回合数
        teamEntity:ActiveSkill():AddPowerfullRoundCount(petEntity:GetID(), 1)
        if previousReady then
            teamEntity:ActiveSkill():AddPreviousReadyRoundCount(petEntity:GetID(), 1)
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, false)
            local notify = NTPetActiveSkillPreviousReady:New(petEntity)
            table.insert(tNotifyArray, notify)
            self._world:GetService("Trigger"):Notify(notify)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, true)
            ---@type GuideServiceRender
            local guideService = self._world:GetService("Guide")
            if guideService ~= nil then
                guideService:Trigger(GameEventType.ShowGuidePowerReady, petEntity)
            end
            local notify = NTPowerReady:New(petEntity)
            table.insert(tNotifyArray, notify)
            self._world:GetService("Trigger"):Notify(notify)
        end
    end
    return tNotifyArray
end

--endregion 刷新光灵CD

---@param teamEntity Entity
function PopStarRoundEnterSystem:_DoLogicSaveRoundBeginPlayerPos(teamEntity)
    if teamEntity == nil then
        return
    end

    local playerPos = teamEntity:GetGridPosition()
    self._world:BattleStat():SetRoundBeginPlayerPos(playerPos)
    self._world:GetService("Trigger"):Notify(NTSaveRoundBeginPlayerPosEnd:New(teamEntity))
end

---模块处理
function PopStarRoundEnterSystem:_DoLogicFeatureOnRoundEnter(incRound)
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        if featureLogicSvc:CanEnableFeature() then
            featureLogicSvc:DoFeatureOnRoundEnter(incRound)
        end
    end
end

function PopStarRoundEnterSystem:_DoLogicTakeSnapshot()
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
    self._world:GetSyncLogger():Trace({ key = "BlockFlags", blockFlags = blockLog })

    --颜色信息
    local pieceLog = {}
    for x, row in pairs(pieceTypes) do
        for y, v in pairs(row) do
            pieceLog[x * 100 + y] = v
        end
    end
    self._world:GetSyncLogger():Trace({ key = "PieceTypes", pieceTypes = pieceLog })
    if self._world and self._world:IsDevelopEnv() then
        Log.debug("PopStarRoundEnterSystem BoardPieceTypes:", echo_one_line(ELogLevel.Debug, pieceLog))
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
    self._world:GetSyncLogger():Trace({ key = "EntityHP", entityHP = hpLog })

    --位置信息
    local posLog = {}
    local posGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridLocation)
    for i, e in ipairs(posGroup:GetEntities()) do
        local pos = e:GridLocation():GetGridPos()
        if e:GetID() < 100000000 and not e:Piece() then
            posLog[e:GetID()] = math.floor(pos.x * 100 + pos.y)
        end
    end
    self._world:GetSyncLogger():Trace({ key = "EntityPos", entityPos = posLog })
end

function PopStarRoundEnterSystem:_DoLogicSwitchState()
    ---检查是不是战斗结束
    local isBattleEnd = self:_IsBattleEnd()
    if isBattleEnd then
        self._world:EventDispatcher():Dispatch(GameEventType.PopStarRoundEnterFinish, 2)
        return
    end

    --切换到waitinput
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarRoundEnterFinish, 1)
end

------------------------------------表现接口----------------------------------

function PopStarRoundEnterSystem:_DoRenderTrapBeforePlayer(TT)
end

function PopStarRoundEnterSystem:_DoRenderShowPetUI(TT, curWaveRound)
end

function PopStarRoundEnterSystem:_DoRenderPlayerTurnBuff(TT)
end

function PopStarRoundEnterSystem:_DoRenderUpdatePetPower(TT, tNotifyArray)
end

function PopStarRoundEnterSystem:_DoRenderSaveRoundBeginPlayerPos(TT, teamEntity)
end

---模块
function PopStarRoundEnterSystem:_DoRenderFeatureOnRoundEnter(TT)
end
