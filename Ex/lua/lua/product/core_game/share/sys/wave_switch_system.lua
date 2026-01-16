--[[------------------------------------------------------------------------------------------
    WaveSwitchSystem：波次切换表现
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class WaveSwitchSystem:MainStateSystem
_class("WaveSwitchSystem", MainStateSystem)
WaveSwitchSystem = WaveSwitchSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function WaveSwitchSystem:_GetMainStateID()
    return GameStateID.WaveSwitch
end

---@param TT token 协程识别码，服务端是nil
function WaveSwitchSystem:_OnMainStateEnter(TT)
    ---判断机关生命周期[机关有存活波次，这里会删除到期的机关]
    local calcStateTraps = self:_DoLogicCalcTrap()

    ---显示机关生命周期
    self:_DoRenderTrapState(TT, calcStateTraps)

    ---更新battleState组件
    self:_DoLogicCalcBattleState()

    ---波次固定地板刷新
    local waveBoard = self:_DoLogicRefreshWaveBoard()
    ---波次切换中的表现
    self:_DoRenderShowSwitch(TT, waveBoard)

    self:_DoLogicAddWaveSwitchBuff()

    self:_DoRenderAddWaveSwitchBuff(TT)

    ---更新显示星灵CD
    local petPowerStateList = self:_DoLogicRefreshPetPower()
    self:_DoRenderRefreshPetPower(TT, petPowerStateList)

    ---切换到波次进入状态
    self:_DoLogicSwitchToWaveEnter()
end

---判断机关生命周期
function WaveSwitchSystem:_DoLogicCalcTrap()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    return trapServiceLogic:CalcTrapState(TrapDestroyType.DestoryByWave)
end

function WaveSwitchSystem:_DoLogicCalcBattleState()
    local boardEntity = self._world:GetBoardEntity()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:MoveToNextWave()
end

function WaveSwitchSystem:_DoLogicSwitchToWaveEnter()
    self._world:EventDispatcher():Dispatch(GameEventType.WaveSwitchFinish, 1)
end

function WaveSwitchSystem:_GetWaveBoard()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type number
    local waveNum = battleStatCmpt:GetCurWaveIndex()
    --波次刷新格子
    local waveBoard = nil
    if self._world._matchType == MatchType.MT_Conquest then
        local boardID = self._world.BW_WorldInfo.boardIDList[waveNum]
        if boardID then
            local cfg = Cfg.cfg_preset_board[boardID]
            if cfg then
                waveBoard = cfg.Board
            end
        end
    else
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type LevelConfigData
        local levelConfigData = configService:GetLevelConfigData()
        waveBoard = levelConfigData:GetWaveBoard(waveNum)
    end
    return waveBoard
end

function WaveSwitchSystem:_DoLogicRefreshWaveBoard()
    --波次刷新格子
    local waveBoard = self:_GetWaveBoard()
    if not waveBoard then
        return
    end

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    --逻辑转色的结果，剔除不可转色的坐标
    local waveBoardResult = {}

    --buff通知
    local tConvertInfo = {}

    for x, row in pairs(waveBoard) do
        for y, color in pairs(row) do
            local posWork = Vector2(x, y)
            if boardServiceLogic:GetCanConvertGridElement(posWork) then
                if not waveBoardResult[x] then
                    waveBoardResult[x] = {}
                end
                waveBoardResult[x][y] = color

                local oldColor = utilData:FindPieceElement(posWork)
				boardServiceLogic:SetPieceTypeLogic(color, posWork)
                local convertInfo = NTGridConvert_ConvertInfo:New(posWork, oldColor, color)
                table.insert(tConvertInfo, convertInfo)
            end
        end
    end

    --施法者传的boardEntity
    local boardEntity = self._world:GetBoardEntity()
    triggerService:Notify(NTGridConvert:New(boardEntity, tConvertInfo))

    return waveBoardResult
end

function WaveSwitchSystem:_DoLogicAddWaveSwitchBuff()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    if self._world._matchType == MatchType.MT_Conquest then
        ---@type BuffLogicService
        local buffLogic = self._world:GetService("BuffLogic")
        local buffList = configService:GetN5WaveBuff()
        if buffList then
            for i, param in ipairs(buffList) do
                buffLogic:AddBuffByTargetType(param.BuffID, param.BuffTargetType, param.BuffTargetParam)
            end
        end
    end

    local waveIndex = self._world:BattleStat():GetCurWaveIndex()
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(NTWaveSwitch:New(waveIndex))
end

function WaveSwitchSystem:_DoLogicRefreshPetPower()
    local petPowerStateList = {}
    local group = self._world:GetGroup(self._world.BW_WEMatchers.Pet)
    for _, e in ipairs(group:GetEntities()) do
        local tNotify = self:_LogicRefreshPetPower(e, petPowerStateList)
    end
    return petPowerStateList
end

function WaveSwitchSystem:_LogicRefreshPetPower(e, petPowerStateList)
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

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(localSkillID)

    --
    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        --传说光灵/威能
    else
        --光灵
        local power = attributesComponent:GetAttribute("Power")
        local ready = attributesComponent:GetAttribute("Ready")

        if not petPowerStateList[petPstID] then
            petPowerStateList[petPstID] = {}
        end
        petPowerStateList[petPstID].petEntityID = e:GetID()
        petPowerStateList[petPstID].petPstID = petPstID
        petPowerStateList[petPstID].ready = ready
        petPowerStateList[petPstID].power = power
    end

    --region 跨波次光灵从灰表变成CD的补丁
    --现象：击杀怪物进入下一波次后，吃减少CD的buff没有用，buff那边不知道跨回合这边把灰表变成数字CD了
    --原因1：跨波次的时候灰表会变成CD数字，而CD数字不会减少，【2021上线前就有】，虽然是设计bug，但策划不想改这个
    --原因2：2023策划将灰表设计成了一个状态

    --修改需求1：在跨波次前就是灰表的，新波次变成CD以后，吃了buff需要立刻减少CD
    --修改需求2：在跨波次后才灰表的，吃了buff需要从灰表变成CD状态，CD不减少
    --解决：跨波次检测 [petPstID][当前回合][光灵主动技]是否有值。如果有值则设置 “灰表” [petPstID][当前回合][光灵主动技]。设置的这个值是buff那边检测灰表状态的值

    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local curRound = battleStatComponent:GetLevelTotalRoundCount()
    local curWaveIndex = battleStatComponent:GetCurWaveIndex()
    local lastWaveIndex = curWaveIndex - 1
    local curWaveRoundHadCastSkillList = battleStatComponent:GetPetDoActiveSkillRecord(petPstID, curRound)
    if curWaveRoundHadCastSkillList and table.count(curWaveRoundHadCastSkillList) > 0 then
        local activeSkillID = e:SkillInfo():GetActiveSkillID()
        local keyStr = "HadSaveSkillGrayWatch" .. "_Round_" .. tostring(curRound) .. "_Skill_" .. tostring(activeSkillID)

        ---@type BuffComponent
        local buffComponent = e:BuffComponent()
        buffComponent:SetBuffValue(keyStr, true)
        battleStatComponent:SetLastDoActiveSkillRound(petPstID, nil)
    end
    --endregion 跨波次光灵从灰表变成CD的补丁
end

------------------------------------------------------------------------------------------

function WaveSwitchSystem:_DoRenderShowSwitch(TT, waveBoard)
end

function WaveSwitchSystem:_DoRenderTrapState(TT, calcStateTraps)
end

function WaveSwitchSystem:_DoRenderAddWaveSwitchBuff(TT)
end

function WaveSwitchSystem:_DoRenderRefreshPetPower(TT, petPowerStateList)
end
