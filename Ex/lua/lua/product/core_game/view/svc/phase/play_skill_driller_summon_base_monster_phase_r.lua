require "play_skill_phase_base_r"

---@class PlaySkillDrillerSummonBaseMonsterPhase: PlaySkillPhaseBase
_class("PlaySkillDrillerSummonBaseMonsterPhase", PlaySkillPhaseBase)
PlaySkillDrillerSummonBaseMonsterPhase = PlaySkillDrillerSummonBaseMonsterPhase

---@param phaseParam SkillPhaseDrillerSummonBaseMonsterParam
---@param casterEntity Entity
function PlaySkillDrillerSummonBaseMonsterPhase:PlayFlight(TT, casterEntity, phaseParam, phaseIndex, phaseAdapter)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = self._world:GetService("PlaySkillInstruction")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    --位置朝向调整
    ---@type SkillEffectResult_Teleport
    local teleportResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport)
    --吸收精密零件 
    ---@type SkillEffectDestroyTrapResult[]
    local sacrificeResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyTrap,1)
    --摧毁要召唤的底座怪占位范围内的机关
    ---@type SkillEffectDestroyTrapResult[]
    local destroyResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyTrap,2)
    --可能有击退玩家
    ---@type SkillHitBackEffectResult
    local hitBackResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.HitBack)
    --召唤底座怪
    ---@type SkillEffectResult_SummonEverything[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)

    --隐藏血条
    self:SetHPVisible(casterEntity,false)
    YIELD(TT)
    
    --本体动作
    local starAction = phaseParam:GetStartAction()
    casterEntity:SetAnimatorControllerTriggers({starAction})
    local upEffAnim = phaseParam:GetUpEffAnim()
    casterEntity:PlayMaterialAnim(upEffAnim)
    --上升拖尾特效
    local upTailEffectID = phaseParam:GetUpTailEffectID()
    if (upTailEffectID) and (upTailEffectID ~= 0) then
        effectService:CreateEffect(upTailEffectID, casterEntity)
    end
    --连线
    if sacrificeResultArray and #sacrificeResultArray > 0 then
        local lineTraps = {}
        for index, sacrificeResult in ipairs(sacrificeResultArray) do
            local trapEntityID=  sacrificeResult:GetEntityID()
            local trapEntity = self._world:GetEntityByID(trapEntityID)
            table.insert(lineTraps,trapEntity)
        end
        local lineEffectID = phaseParam:GetLineEffectID()
        local lineEffectCasterBone = phaseParam:GetLineEffectCasterBone()
        local lineEffectTrapBone = phaseParam:GetLineEffectTrapBone()
        if lineEffectID then
            effectService:CreateLineEffects(TT,lineEffectID,casterEntity,lineEffectCasterBone,lineTraps,lineEffectTrapBone)
        end
    end
    if sacrificeResultArray and #sacrificeResultArray > 0 then
        for index, sacrificeResult in ipairs(sacrificeResultArray) do
            local trapEntityID=  sacrificeResult:GetEntityID()
            local eTrap = self._world:GetEntityByID(trapEntityID)
            local donotPlayDie = false
            GameGlobal.TaskManager():CoreGameStartTask(
                function()
                    trapServiceRender:PlayTrapDieSkill(TT, {eTrap},donotPlayDie)
                end
            )
        end
    end
    --等上天后 
    local showDropDelay = phaseParam:GetShowDropDelay()
    YIELD(TT,showDropDelay)
    local downTailEffectID = phaseParam:GetDownTailEffectID()
    if teleportResult then
        --消失
        playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportHide, false, teleportResult)
        ---瞬移
        playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportMove, false, teleportResult)
        ---延时
        --YIELD(TT, phaseParam.stealthDuration)
        ---出现
        playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportShow, false, teleportResult)
        self:SetHPVisible(casterEntity,false)
        ---buff
        playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.BuffNotify, false, teleportResult)
    end
    casterEntity:SetViewVisible(false)
    local baseMonsterEntity = nil
    if summonResultArray and #summonResultArray > 0 then
        ---@type SkillEffectResult_SummonEverything
        local summonRes = summonResultArray[1]
        playSkillInstructionService:ShowSummonAction(TT, self._world, summonRes)
        local tmpData = summonRes:GetMonsterData()
        local entityWorkID = tmpData.m_entityWorkID
        ---@type Entity
        local entityWork = self._world:GetEntityByID(entityWorkID)
        baseMonsterEntity = entityWork
        baseMonsterEntity:SetViewVisible(false)
        --隐藏血条
        self:SetHPVisible(baseMonsterEntity,false)
        YIELD(TT)
        baseMonsterEntity:SetViewVisible(true)
        self:SetHPVisible(baseMonsterEntity,false)
    end
    --下落
    if baseMonsterEntity then
        local downAction = phaseParam:GetDownAction()
        baseMonsterEntity:SetAnimatorControllerTriggers({downAction})
        --下降拖尾特效
        local downTailEffectID = phaseParam:GetDownTailEffectID()
        if (downTailEffectID) and (downTailEffectID ~= 0) then
            effectService:CreateEffect(downTailEffectID, baseMonsterEntity)
        end
        local downEffAnim = phaseParam:GetDownEffAnim()
        baseMonsterEntity:PlayMaterialAnim(downEffAnim)
        local landDelay = phaseParam:GetLandDelay()
        YIELD(TT,landDelay)
        --特效
        local landEffectID = phaseParam:GetLandEffectID()
        if (landEffectID) and (landEffectID ~= 0) then
            effectService:CreateEffect(landEffectID, baseMonsterEntity)
        end
        --销毁
        --临时
        
        if destroyResultArray and #destroyResultArray > 0 then
            for index, destroyResult in ipairs(destroyResultArray) do
                local trapEntityID=  destroyResult:GetEntityID()
                local eTrap = self._world:GetEntityByID(trapEntityID)
                local donotPlayDie = false
                --trapServiceRender:PlayTrapDieSkill(TT, {eTrap},donotPlayDie)
                GameGlobal.TaskManager():CoreGameStartTask(
                    function()
                        trapServiceRender:PlayTrapDieSkill(TT, {eTrap},donotPlayDie)
                    end
                )
            end
        end
        --击退
        if hitBackResult then
            local hitBackSpeed = 10
            local processHitTaskID = nil
            local targetEntityID = hitBackResult:GetTargetID()
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            if hitBackResult and not targetEntity:HasHitback() and not hitBackResult:GetHadPlay() then
                hitBackResult:SetHadPlay(true)
                processHitTaskID = self:SkillService():ProcessHit(casterEntity, targetEntity, hitBackResult, hitBackSpeed)
            end
            ---等待击退/撞墙等处
            if processHitTaskID then
                while not TaskHelper:GetInstance():IsTaskFinished(processHitTaskID) do
                    YIELD(TT)
                end
            end
            YIELD(TT)
            if hitBackResult then
                local pieceService = self._world:GetService("Piece")
                pieceService:RemovePrismAt(hitBackResult:GetPosTarget())
            end
        end
        --给隐藏的boss挂组件，被击由底座怪表现
        casterEntity:ReplaceRenderPerformanceByAgent(baseMonsterEntity:GetID())
        YIELD(TT)
        self:SetHPVisible(casterEntity,true)
        self:SetHPVisible(baseMonsterEntity,true)
        baseMonsterEntity:ReplaceHPComponent()
        YIELD(TT)
    end
end

function PlaySkillDrillerSummonBaseMonsterPhase:SetHPVisible(entity,bVisible)
    local hpCmpt = entity:HP()
    if hpCmpt then
        local sliderEntityID = entity:HP():GetHPSliderEntityID()
        local sliderEntity = self._world:GetEntityByID(sliderEntityID)
        if sliderEntity then
            hpCmpt:SetHPBarTempHide(not bVisible)
            hpCmpt:SetHPPosDirty(true)
            --sliderEntity:SetViewVisible(bVisible)
        end
    end
end