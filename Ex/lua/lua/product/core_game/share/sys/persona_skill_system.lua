--[[------------------------------------------------------------------------------------------
    PersonaSkillSystem：
    1.主流程中的P5合击技（后扩展到各种模块技能）施法状态
    2.跨度是从玩家按下发动按钮后，直到技能施法完成
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class PersonaSkillSystem:MainStateSystem
_class("PersonaSkillSystem", MainStateSystem)
PersonaSkillSystem = PersonaSkillSystem

---重载函数，返回模块技状态标识码
---@return GameStateID 状态标识
function PersonaSkillSystem:_GetMainStateID()
    return GameStateID.PersonaSkill
end

---模块技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function PersonaSkillSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type FeatureSkillComponent
    local featureSkillCmpt = teamEntity:FeatureSkill()
    local skillID = featureSkillCmpt:GetFeatureSkillID()
    local featureType = featureSkillCmpt:GetFeatureType()
    local casterEntityID = featureSkillCmpt:GetFeatureSkillCasterEntityID()
    local casterEntity = self._world:GetEntityByID(casterEntityID)--lsvcFeature:GetPersonaSkillHolderEntity()
    ---模块技开始时的统一的表现行为，现在只做了两件事儿
    ---打开Effect相机
    ---重置技能等待协程ID的队列
    self:_DoRenderPreFeatureSkillStart(TT)

    ---保存施法者位置，后面处理瞬移效果时会用到--队伍位置
    --local posCasterOld = casterEntity:GetGridPosition()
    local posCasterOld = teamEntity:GetGridPosition()

    ---计算模块技效果，触发光灵BUFF，通知表现层结果
    self:_DoLogicCastFeatureSkill(teamEntity, casterEntity)

    ---模块技的施法过程中，可能会导致某些机关的死亡，这里需要结算一次
    self:_DoLogicTrapDeadSkill()

    ---模块技的施法过程中，可能会导致某些怪物的死亡，这里结算死亡怪物逻辑
    self:_DoLogicFeatureSkillMonsterDead(teamEntity, casterEntity)

    ---模块技开始的表现通知
    self:_DoRenderNotifyFeatureSkillStart(TT, teamEntity, casterEntity)

    ---计算最后一击，应该是个表现函数，现在是作为逻辑函数在执行
    local isFinalAttack = self:_DoLogicCalcIsFinalAttack()

    ---播放模块技
    local castSkillTaskID = self:_DoRenderPlayFeatureSkill(isFinalAttack, teamEntity, casterEntity)

    ---------------------------模块技施法的等待-------------------------------------
    ---以下可以合并成一个函数

    ---等待模块技施法结束
    self:_WaitTasksEnd(TT, {castSkillTaskID})

    ---等待技能施法协程结束
    self:_DoRenderWaitPlaySkillTaskFinish(TT)
    -------------------------------------------------------------------------------

    ---重置格子动画表现
    self:_DoRenderResetPieceAnim(TT, teamEntity, casterEntity)

    ---重置预览
    self:_DoRenderResetPreview(TT, teamEntity, casterEntity)

    ---设置统计数据
    self:_DoLogicUpdateBattleStat(teamEntity, casterEntity)

    ---怪物死亡刷新 表现
    self:_DoRenderMonsterDead(TT, teamEntity, casterEntity)

    ---通知表现模块技施法结束
    self:_DoRenderNotifyFeatureSkillFinish(TT, teamEntity, casterEntity,featureType,skillID)

    ---需要在模块技流程结束后，做的表现
    ---取消暗屏等
    self:_DoRenderShowAfterFeatureSkill(TT, teamEntity, casterEntity)


    ---逻辑 等待主动技瞬移完成  检查触发机关
    ---todo:需要检查下这个逻辑所对应的需求
    local listTrapTrigger = self:_DoLogicWaitTeleportFinish(teamEntity, casterEntity, posCasterOld)
    self:_DoLogicMonsterDead() ---怪物死亡刷新 逻辑
    self:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity, casterEntity) ---表现  等待主动技瞬移完成  检查触发机关

    -- 这里再刷一次，是因为主动技瞬移触发的机关会打死额外的怪物
    self:_DoRenderMonsterDead(TT, teamEntity, casterEntity)

    ---机关死亡逻辑
    self:_DoLogicTrapDie()
    ---机关死亡表现
    self:_DoRenderTrapDie(TT)
    -- 这里再刷一次
    self:_DoLogicMonsterDead()
    self:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
    --------------------------------------------------------------

    ---------------------------模块技结束后刷怪-------------------------------------
    ---比如情报关，当玩家释放完模块技后，需要根据场上的怪物存量，决定是否要刷新怪出来
    ---刷怪逻辑
    --local traps, monsters = self:_DoLogicSpawnInWaveMonsters(MonsterWaveInternalTime.FeatureSkill)
    ---刷怪表现
    --self:_DoRenderInWave(TT, traps, monsters)
    ------------------------------------------------------------------------------

    ---重置逻辑拾取组件数据
    self:_DoLogicResetPickUp(teamEntity)

    ---重置表现拾取组件
    self:_DoRenderResetPickUp()

    self:_DoLogicFeatureSkillEnd(teamEntity, casterEntity)
    self:_DoRenderFeatureSkillEnd(TT,teamEntity, casterEntity)
    --同步格子颜色
    self:_DoLogicSyncPieceType()

    --------------------------------------------------------------

    ---主状态机切换
    self:_DoLogicSwitchMainState(teamEntity)
end

function PersonaSkillSystem:_DoLogicFeatureSkillMonsterDead(teamEntity, casterEntity)
    local deadMonsterList = self:_DoLogicMonsterDead()
end

----------------------------------------------------------------
---逻辑行为
---处理模块技计算逻辑的主流程
---如果有机会重构的话，应该拆成三个小函数
---计算模块技、针对宝宝的BUFF通知、通知表现层逻辑结果
----------------------------------------------------------------
function PersonaSkillSystem:_DoLogicCastFeatureSkill(teamEntity, casterEntity)
    ---@type FeatureSkillComponent
    local featureSkillCmpt = teamEntity:FeatureSkill()
    local skillID = featureSkillCmpt:GetFeatureSkillID()
    local featureType = featureSkillCmpt:GetFeatureType()

    --备注：通知 合击技开始
    
    ---清理玩家身上的技能数据，有可能还挂着上一次放技能时的数据
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    skillEffectResultContainer:Clear()

    Log.debug("CastPersonaSkill skillID=", skillID)

    ---实际的技能计算行为
    ---@type SkillLogicService
    local logicService = self._world:GetService("SkillLogic")
    logicService:CalcSkillEffect(casterEntity, skillID, SkillType.FeatureSkill)

    --备注：通知 技能造成伤害等
    --技能结束
    local notifyData = NTFeatureSkillAttackEnd:New(featureType,skillID)
    self._world:GetService("Trigger"):Notify(notifyData)

    ------------------通知表现层模块技结果 服务端不需要 可以改掉-------------------
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RFeatureAttackData(casterEntity,skillID)

    --模块技结束后的格子颜色变化同步表现
    svc:L2RBoardLogicData()
    ----------------------------------------------------------------------------
end

function PersonaSkillSystem:_DoLogicUpdateBattleStat(teamEntity, casterEntity)
    
end

function PersonaSkillSystem:_DoLogicCalcIsFinalAttack()
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local isFinalAttack = battleService:IsFinalAttack()
    return isFinalAttack
end

---模块技计算完毕后单独结算伤害打死的机关的死亡技
function PersonaSkillSystem:_DoLogicTrapDeadSkill()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:CalcActiveSkillDeadTrapDeadSkill()
    self:_DoLogicTrapDie()
end

function PersonaSkillSystem:_DoLogicResetPickUp(teamEntity)
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    logicPickUpCmpt:ResetLogicPickUp()
end

function PersonaSkillSystem:_DoLogicSwitchMainState(teamEntity)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local isTriggerDimension = boardServiceLogic:IsPlayerOnDimension(teamEntity)
    --local levelFinish = battleService:CheckLevelFinish()

    local nextState = self:_DoCheckNextState(teamEntity)

    ---触发任意门
    if isTriggerDimension then
        if nextState == 2 then
            self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.RoundResult)
        elseif nextState == 1 then
            self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.WaitInput)
        end
        self._world:EventDispatcher():Dispatch(GameEventType.PersonaSkillFinish, 3)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.PersonaSkillFinish, nextState)
    end
end

---检查下一个切换过的状态机
function PersonaSkillSystem:_DoCheckNextState(teamEntity)
    local battleStatCmpt = self._world:BattleStat()

    local nextState = 0
    if battleStatCmpt:AssignWaveResult() then
        nextState = 1
    else
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        local allMonsterDead = battleService:CheckAllMonstersDead(teamEntity)
        local specificTrapDead = battleService:CheckSpecificTrapDead()

        if allMonsterDead and specificTrapDead then
            local isLastWave = battleStatCmpt:IsLastWave()
            if isLastWave then
                nextState = 1
            else
                nextState = 2
            end
        else
            nextState = 1
        end

        local waveFinish = battleService:BattleCalculation(teamEntity)
        if waveFinish then
            nextState = 2
        end
    end

    return nextState
end

function PersonaSkillSystem:_DoLogicFeatureSkillEnd(teamEntity, casterEntity)
    --清理拾取组件
    casterEntity:RemoveActiveSkillPickUpComponent()

    ---@type FeatureSkillComponent
    local featureSkillCmpt = teamEntity:FeatureSkill()
    featureSkillCmpt:SetFeatureSkillID(nil,nil, nil)
end

---@return Entity[]
function PersonaSkillSystem:_DoLogicWaitTeleportFinish(teamEntity, casterEntity, posCasterOld)
    ---触发瞬移后的机关表现
    --local posCasterNew = casterEntity:GetGridPosition()
    local posCasterNew = teamEntity:GetGridPosition()
    local bHaveTeleport = posCasterNew ~= posCasterOld
    if not bHaveTeleport then
        local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
        ---@type SkillEffectResult_Teleport
        local teleportResultNew = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, 1)
        if teleportResultNew then
            bHaveTeleport = true
        end
    end
    local listTrapTrigger = nil
    if bHaveTeleport then
        ---@type TrapServiceLogic
        local sTrapLogic = self._world:GetService("TrapLogic")
        listTrapTrigger = sTrapLogic:TriggerTrapByTeleport(teamEntity, true) --宝宝瞬移触发机关时只传队伍实体
    end
    return listTrapTrigger
end

--------------------------------------表现接口-----------------------------------------
---
function PersonaSkillSystem:_DoRenderPreFeatureSkillStart(TT)
end

function PersonaSkillSystem:_DoRenderNotifyFeatureSkillStart(TT, teamEntity, casterEntity)
end

function PersonaSkillSystem:_DoRenderWaitPlaySkillTaskFinish(TT)
end
function PersonaSkillSystem:_DoRenderWaitTeleportFinish(TT, listTrapTrigger, teamEntity, casterEntity)
end
function PersonaSkillSystem:_DoRenderResetPieceAnim(TT, teamEntity, casterEntity)
end

function PersonaSkillSystem:_DoRenderResetPreview(TT, teamEntity, casterEntity)
end

function PersonaSkillSystem:_DoRenderNotifyFeatureSkillFinish(TT, teamEntity, casterEntity,featureType,skillID)
end

function PersonaSkillSystem:_DoRenderShowAfterFeatureSkill(TT, teamEntity, casterEntity)
end

function PersonaSkillSystem:_DoRenderPlayFeatureSkill(isFinalAttack, teamEntity, casterEntity)
end

-- function PersonaSkillSystem:_DoRenderInWave(TT, traps, monsters)
-- end

function PersonaSkillSystem:_DoRenderMonsterDead(TT, teamEntity, casterEntity)
end

function PersonaSkillSystem:_DoRenderResetPickUp()
end
function PersonaSkillSystem:_DoRenderFeatureSkillEnd(TT,teamEntity, casterEntity)
end