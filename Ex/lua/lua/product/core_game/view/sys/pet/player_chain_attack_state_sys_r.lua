--[[----------------------------------------------------------
    PlayerChainAttackStateSystem_Render 处理玩家连锁攻击状态
]] ------------------------------------------------------------
require("pet_chain_skill_self_attack_r")
require("pet_chain_skill_shadow_attack_r")
require("pet_chain_skill_agent_attack_r")

---@class PlayerChainAttackStateSystem_Render:ReactiveSystem
_class("PlayerChainAttackStateSystem_Render", ReactiveSystem)
PlayerChainAttackStateSystem_Render = PlayerChainAttackStateSystem_Render

---@param world World
function PlayerChainAttackStateSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = world:GetService("Config")
end

---@param world World
function PlayerChainAttackStateSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.ChainSkillFlag)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PlayerChainAttackStateSystem_Render:Filter(entity)
    if not entity:HasMoveFSM() then
        return false
    end

    local move_fsm_cmpt = entity:MoveFSM()
    local cur_state_id = move_fsm_cmpt:GetMoveFSMCurStateID()
    if cur_state_id == PlayerActionStateID.ChainSkillAttack then
        return true
    end

    return false
end

function PlayerChainAttackStateSystem_Render:ExecuteEntities(entities)
    local len = #entities
    for i = 1, len do
        self:HandleAttack(entities[i])
    end
end

---@param entity Entity
function PlayerChainAttackStateSystem_Render:HandleAttack(entity)
    local chain_skill_cmpt = entity:ChainSkill()
    if chain_skill_cmpt == nil then
        self._world:EventDispatcher():Dispatch(GameEventType.ChainSkillAttackFinish, 1, entity:GetID())
        return
    end

    local chainNum = chain_skill_cmpt:GetChainNum()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    local chain_skill_id = chainAtkResCmpt:GetPetCastChainSkillID(entity:GetID())

    --检查连锁技的技能ID是否合法
    if chain_skill_id <= 0 then
        self._world:EventDispatcher():Dispatch(GameEventType.ChainSkillAttackFinish, 1, entity:GetID())
        return
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    playSkillService:ShowCasterEntity(entity:GetID())

    ---连锁技语音
    self:_PlayChainAttackVoice(entity)

    ---UA埋点
    self:_UAReportChainAttack(entity, chain_skill_id, chainNum)

    TaskManager:GetInstance():CoreGameStartTask(
        self._DoPlayChainAttack,
        self,
        entity,
        chain_skill_id
    )
end

---@return Vector2[]
---@param casterEntity Entity
function PlayerChainAttackStateSystem_Render:GetPetForward(casterEntity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type Vector2
    local casterPos = casterEntity:GridLocation().Position
    ---@type SkillDamageEffectResult[]
    local damageResultList = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if not damageResultList then
        return Vector2(0, 1)
    end
    local function get_index(c, p)
        if p.x - c.x == 0 and p.y - c.y > 0 then
            return 1
        end
        if p.x - c.x > 0 and p.y - c.y > 0 then
            return 2
        end
        if p.x - c.x > 0 and p.y - c.y == 0 then
            return 3
        end
        if p.x - c.x > 0 and p.y - c.y < 0 then
            return 4
        end
        if p.x - c.x == 0 and p.y - c.y < 0 then
            return 5
        end
        if p.x - c.x < 0 and p.y - c.y < 0 then
            return 6
        end
        if p.x - c.x < 0 and p.y - c.y == 0 then
            return 7
        end
        if p.x - c.x < 0 and p.y - c.y > 0 then
            return 8
        end
        return 1
    end
    ---@type table<number,Vector2>
    local damagePosList = {}
    for i, result in ipairs(damageResultList) do
        damagePosList[i] = result:GetGridPos()
    end
    local cmpFunc = function(damageResultPos1, damageResultPos2)
        local dis1 = Vector2.Distance(damageResultPos1, casterPos)
        local dis2 = Vector2.Distance(damageResultPos2, casterPos)
        if dis1 == dis2 then
            return get_index(casterPos, damageResultPos1) < get_index(casterPos, damageResultPos2)
        else
            return dis1 < dis2
        end
    end
    table.sort(damagePosList, cmpFunc)
    local dir = damagePosList[1] - casterPos
    return dir
end

function PlayerChainAttackStateSystem_Render:_DoPlayChainAttack(TT, casterEntity, skillID)
    ---等待机关技能表现结束
    self:_WaitChainAttackTrapTaskEnd(TT)

    local chainTaskIDList = {}
    ---@type PetChainSkillSelfAttack
    local selfAttack = PetChainSkillSelfAttack:New(self._world)
    local selfAttackTaskID =
        TaskManager:GetInstance():CoreGameStartTask(
        selfAttack.DoPlayPetSelfChainAttack,
        selfAttack,
        casterEntity,
        skillID
    )
    if selfAttackTaskID > 0 then
        chainTaskIDList[#chainTaskIDList + 1] = selfAttackTaskID
    end

    ---@type PetChainSkillShadowAttack
    local shadowAttack = PetChainSkillShadowAttack:New(self._world)
    local shadowAttackTaskID =
        TaskManager:GetInstance():CoreGameStartTask(
        shadowAttack.DoPlayPetShadowChainAttack,
        shadowAttack,
        casterEntity,
        skillID
    )
    if shadowAttackTaskID > 0 then
        chainTaskIDList[#chainTaskIDList + 1] = shadowAttackTaskID
    end

    ---@type PetChainSkillAgentAttack
    local agentAttack = PetChainSkillAgentAttack:New(self._world)
    local agentAttackTaskID =
        TaskManager:GetInstance():CoreGameStartTask(
        agentAttack.DoPlayPetAgentChainAttack,
        agentAttack,
        casterEntity,
        skillID
    )
    if agentAttackTaskID > 0 then
        chainTaskIDList[#chainTaskIDList + 1] = agentAttackTaskID
    end

    ---等待所有连锁技协程结束
    while not TaskHelper:GetInstance():IsAllTaskFinished(chainTaskIDList, true) do
        YIELD(TT)
    end

    ---------------新手引导 连锁技结束站那↓-------------------------
    local guideService = self._world:GetService("Guide")
    local guideTaskId =
        guideService:Trigger(GameEventType.GuidePlayerSkillFinish, GuidePlaySkillFinish.ChainSkillFinish, casterEntity)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId, true) do
        YIELD(TT)
    end
    ---------------新手引导 连锁技结束站那↑-------------------------

    --头像缩回去
    local pstId = casterEntity:PetPstID():GetPstID()
    self._world:EventDispatcher():Dispatch(GameEventType.InOutQueue, pstId, false)

    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideChainSkillCG, pstId, false)

    self._world:EventDispatcher():Dispatch(GameEventType.ChainSkillAttackFinish, 1, casterEntity:GetID())
end

function PlayerChainAttackStateSystem_Render:_WaitChainAttackTrapTaskEnd(TT)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    while not trapServiceRender:IsTrapViewTaskOver() do
        YIELD(TT)
    end

    trapServiceRender:ClearTrapViewTask()
end

function PlayerChainAttackStateSystem_Render:_PlayChainAttackVoice(casterEntity)
    local tplID = casterEntity:PetPstID():GetTemplateID()
    --播放语音
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:PlayPetAudio("ChainSkill", tplID)
end

function PlayerChainAttackStateSystem_Render:_UAReportChainAttack(casterEntity, skillID, chainNum)
    local tplID = casterEntity:PetPstID():GetTemplateID()

    GameGlobal.UAReportForceGuideEvent(
        "FightSpellChainSkill",
        {
            skillID,
            chainNum,
            tplID
        },
        false,
        true
    )
end

