--[[----------------------------------------------------------
    PetChainSkillShadowAttack：宝宝虚影的连锁技
]] ------------------------------------------------------------
require("pet_chain_skill_attack_r")
_class("PetChainSkillShadowAttack", PetChainSkillAttack)
---@class PetChainSkillShadowAttack:PetChainSkillAttack
PetChainSkillShadowAttack = PetChainSkillShadowAttack

---播放全息投影的连锁技表现
---@param casterEntity Entity 宝宝本体
function PetChainSkillShadowAttack:DoPlayPetShadowChainAttack(TT, casterEntity, skillID)
    ---@type SkillChainAttackData[]
    local shadowChainAttackDataList = self:_GetPetShadowChainAttackDataByEntityID(casterEntity:GetID())

    local chainAttackCount = #shadowChainAttackDataList
    if chainAttackCount <= 0 then
        return
    end

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")

    ---@type Entity
    local shadowEntity = self:_GetCasterShadowEntity(casterEntity)
    if not shadowEntity then
        return
    end

    shadowEntity:SetViewVisible(true)

    self:_SetShadowEntityLocationByPetEntity(casterEntity, shadowEntity)

    if not self:_IsCasterHasShadowChainSkillPro(casterEntity) then
        shadowEntity:PlayMaterialAnim("common_shadoweff")
    end

    local skillPhaseArray = self:_GetChainSkillPhaseArray(casterEntity, skillID)

    local playSkillTaskIDList = {}
    for chainIndex = 1, chainAttackCount do
        ---本次连锁技致死的目标 添加DeadFlag标志
        self:_OnResultDeadEntityAddDeadFlag(casterEntity:GetID(), chainIndex)

        shadowEntity:SkillRoutine():ClearSkillRoutine()

        local shadowData = shadowChainAttackDataList[chainIndex]

        ---@type SkillEffectResultContainer
        local skillResult = SkillEffectResultContainer:New()
        local results = shadowData:GetEffectResultDict()
        skillResult:SetEffectResultDict(results)
        skillResult:SetScopeResult(shadowData:GetScopeResult())

        --最后一击判定
        local isFinalAttack = shadowData:IsFinalAttack()
        if chainAttackCount == chainIndex and isFinalAttack then
            self:_CheckFinalAttack(skillResult, casterEntity)
        end
        shadowEntity:SkillRoutine():SetResultContainer(skillResult)
        local taskid = playSkillService:StartSkillRoutine(shadowEntity, skillPhaseArray, skillID)
        playSkillTaskIDList[#playSkillTaskIDList + 1] = taskid

        while not TaskHelper:GetInstance():IsTaskFinished(taskid, true) do
            YIELD(TT)
        end

        playBuffSvc:PlayBuffView(TT, NTSingleChainSkillAttackFinish:New(casterEntity, chainIndex))
        
        self:_ShowChainAttackMonsterDead(TT)
    end

    ---@type BuffViewComponent
    local buffViewCmpt = casterEntity:BuffView()
    --放完连锁技隐藏
    if
        buffViewCmpt:HasBuffEffect(BuffEffectType.ShadowChainSKill) or
            buffViewCmpt:HasBuffEffect(BuffEffectType.ShadowChainSKillPro)
     then
        local shadowEntityID = buffViewCmpt:GetBuffValue("ShadowChainEntityID")
        ---@type Entity
        local shadowEntity = self._world:GetEntityByID(shadowEntityID)
        shadowEntity:SetViewVisible(false)
    end
end

---提取虚影的连锁技逻辑结果
---@param casterEntityID number 施法者的EntityID
---@return SkillChainAttackData[] 连锁技数据列表
function PetChainSkillShadowAttack:_GetPetShadowChainAttackDataByEntityID(casterEntityID)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    ---@type SkillChainAttackData[]
    local shadowChainAttackData = chainAtkResCmpt:GetPetShadowChainSkillDataList(casterEntityID)
    return shadowChainAttackData
end

---提取施法者的虚影Entity
---@param casterEntity Entity 施法者
---@return Entity 如果没有虚影，返回的是nil
function PetChainSkillShadowAttack:_GetCasterShadowEntity(casterEntity)
    ---@type BuffViewComponent
    local buffViewCmpt = casterEntity:BuffView()
    local hasShadowChainSKill = buffViewCmpt:HasBuffEffect(BuffEffectType.ShadowChainSKill)
    local hasShadowChainSKillPro = buffViewCmpt:HasBuffEffect(BuffEffectType.ShadowChainSKillPro)
    if hasShadowChainSKill or hasShadowChainSKillPro then
        local shadowEntityID = buffViewCmpt:GetBuffValue("ShadowChainEntityID")
        ---@type Entity
        local shadowEntity = self._world:GetEntityByID(shadowEntityID)
        return shadowEntity
    end

    ---没有虚影，返回nil
    return
end

---施法者是否有虚影连锁技pro标记
---@param casterEntity Entity 施法者
function PetChainSkillShadowAttack:_IsCasterHasShadowChainSkillPro(casterEntity)
    ---@type BuffViewComponent
    local buffViewCmpt = casterEntity:BuffView()
    local hasShadowChainSKillPro = buffViewCmpt:HasBuffEffect(BuffEffectType.ShadowChainSKillPro)
    return hasShadowChainSKillPro
end

---设置虚影的状态
---@param casterEntity Entity 宝宝Entity
---@param shadowEntity Entity 虚影Entity
function PetChainSkillShadowAttack:_SetShadowEntityLocationByPetEntity(casterEntity, shadowEntity)
    ---@type BuffViewComponent
    local buffViewCmpt = casterEntity:BuffView()
    local shadowPos = buffViewCmpt:GetBuffValue("ShadowChainPos")
    local shadowDir = casterEntity:GridLocation():GetGridDir()
    shadowEntity:SetLocation(shadowPos, shadowDir)
end
