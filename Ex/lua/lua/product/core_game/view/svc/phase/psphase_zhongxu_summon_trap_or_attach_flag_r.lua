require "play_skill_phase_base_r"
---@class PlaySkillZhongxuSummonTrapOrAttachFlagPhase: PlaySkillPhaseBase
_class("PlaySkillZhongxuSummonTrapOrAttachFlagPhase", PlaySkillPhaseBase)
PlaySkillZhongxuSummonTrapOrAttachFlagPhase = PlaySkillZhongxuSummonTrapOrAttachFlagPhase

---@param phaseParam SkillPhaseZhongxuSummonTrapOrAttachFlagParam
function PlaySkillZhongxuSummonTrapOrAttachFlagPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local waitTaskIDs = {}

    local checkTrapIDList = phaseParam:GetCheckTrapIDList()
    if checkTrapIDList and (#checkTrapIDList > 0) then
        ---@type SkillSummonTrapEffectResult[]
        local trapResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonTrap)
        if trapResultArray then
            for i = 1, #trapResultArray do
                local result = trapResultArray[i]
                local summonTrapID = result:GetTrapID()
                if table.icontains(checkTrapIDList,summonTrapID) then
                    local taskId = GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            self:_ShowTrapFromSummonTrap(TT, phaseParam, result)
                        end
                    )
                    table.insert(waitTaskIDs, taskId)
                end
            end
        end
    end
    
    ---@type SkillEffectResultAddMoveScopeRecordCmpt[]
    local addFlagResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddMoveScopeRecordCmpt)
    if addFlagResultArray then
        for i = 1, #addFlagResultArray do
            local result = addFlagResultArray[i]
            local hostEntityID = result:GetHostEntityID()
            --是机关 不处理
            --单格怪 挂小特效，特效切动画
            --多格怪 挂大特效，特效切动画 挂点选位置标记特效
            local hostEntity = self._world:GetEntityByID(hostEntityID)
            if hostEntity then
                if hostEntity:HasTrapID() then
                elseif hostEntity:HasMonsterID() then
                    if hostEntity:HasBodyArea() then
                        local bodyArea = hostEntity:BodyArea():GetArea()
                        if #bodyArea == 1 then
                            local taskId = GameGlobal.TaskManager():CoreGameStartTask(
                                function()
                                    self:_SingleGridMonsterPlayAddFlag(TT,phaseParam,hostEntity, result)
                                end
                            )
                            table.insert(waitTaskIDs, taskId)
                        else
                            --多格怪
                            local taskId = GameGlobal.TaskManager():CoreGameStartTask(
                                function()
                                    self:_MultiGridMonsterPlayAddFlag(TT, phaseParam,hostEntity,result)
                                end
                            )
                            table.insert(waitTaskIDs, taskId)
                        end
                    end
                elseif (self._world:MatchType() == MatchType.MT_BlackFist) and hostEntity:HasTeam() then
                    local taskId = GameGlobal.TaskManager():CoreGameStartTask(
                        function()
                            self:_SingleGridMonsterPlayAddFlag(TT, phaseParam,hostEntity,result)
                        end
                    )
                    table.insert(waitTaskIDs, taskId)
                end
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(waitTaskIDs) do
        YIELD(TT)
    end

    
end

---@param result SkillSummonTrapEffectResult
function PlaySkillZhongxuSummonTrapOrAttachFlagPhase:_ShowTrapFromSummonTrap(TT, phaseParam, result)
    local posSummon = result:GetPos()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local array = utilSvc:GetTrapsAtPos(posSummon)

    local trapID = result:GetTrapID()
    -- Log.info(self._className, "try find trap at", tostring(result:GetPos()), " id=", trapID)
    local trapEntity
    for _, eTrap in ipairs(array) do
        ---@type TrapIDComponent
        local cTrap = eTrap:TrapID()
        -- Log.info(self._className, "component=", cTrap ~= nil, " cmpt trapID=", cTrap:GetTrapID(), " hasDeadMark=",eTrap:HasDeadMark())
        if cTrap and cTrap:GetTrapID() == trapID and not eTrap:HasDeadMark() then
            trapEntity = eTrap
            break
        end
    end

    if not trapEntity then
        Log.error(self._className, "trap not found: ", tostring(result:GetPos()), " id=", trapID)
        return
    end

    self:_ShowTrap(TT, trapEntity, posSummon)
end

---@param summonRes SkillEffectResult_SummonEverything
function PlaySkillZhongxuSummonTrapOrAttachFlagPhase:_ShowTrap(TT, trapEntity, posSummon)
    trapEntity:SetPosition(posSummon)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)

    if self._effectID and self._effectID > 0 then
        local effectService = self._world:GetService("Effect")
        effectService:CreateWorldPositionDirectionEffect(self._effectID, posSummon)
    end
end
function PlaySkillZhongxuSummonTrapOrAttachFlagPhase:_SingleGridMonsterPlayAddFlag(TT, phaseParam,entity, result)
    local effectDelay = phaseParam:GetSingeGridMonsterEffectDelay()
    local effectID = phaseParam:GetSingeGridMonsterEffectID()
    local loopAnim = phaseParam:GetSingeGridMonsterEffectLoopAnim()
    local loopAnimDelay = phaseParam:GetSingeGridMonsterEffectLoopAnimDelay()
    YIELD(TT,effectDelay)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --施法特效
    local effectEntity = effectService:CreateEffect(effectID, entity)
    YIELD(TT,loopAnimDelay)
    local effectGo = effectEntity:View():GetGameObject()
    ---@type UnityEngine.Animation
    local anim = effectGo:GetComponentInChildren(typeof(UnityEngine.Animation))
    if anim then
        anim:Play(loopAnim)
    end
    YIELD(TT)
end
---@param result SkillEffectResultAddMoveScopeRecordCmpt
function PlaySkillZhongxuSummonTrapOrAttachFlagPhase:_MultiGridMonsterPlayAddFlag(TT, phaseParam,entity, result)
    local effectDelay = phaseParam:GetMultiGridMonsterEffectDelay()
    local effectID = phaseParam:GetMultiGridMonsterEffectID()
    local loopAnim = phaseParam:GetMultiGridMonsterEffectLoopAnim()
    local loopAnimDelay = phaseParam:GetMultiGridMonsterEffectLoopAnimDelay()
    local flagEffectID = phaseParam:GetMultiGridMonsterFlagEffectID()
    YIELD(TT,effectDelay)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --施法特效
    local effectEntity = effectService:CreateEffect(effectID, entity)
    local flagEffectEntity = effectService:CreateEffect(flagEffectID, entity)
    ----@type EffectControllerComponent
    local effectControllerComponent = flagEffectEntity:EffectController()
    if effectControllerComponent then
        local gridOffSet = result:GetOffSet()
        local hostPos = entity:GetGridPosition()
        local flagPos = hostPos + gridOffSet
        local csgo = entity:View().ViewWrapper.GameObject
        local csTransformRoot = csgo.transform:Find("Root")
        if csTransformRoot then
            local rootPos = csTransformRoot.position
            ---@type BoardServiceRender
            local boardServiceRender = self._world:GetService("BoardRender")
            local flagRenderPos = boardServiceRender:GridPos2RenderPos(flagPos)
            local off = flagRenderPos - rootPos
            --local renderOffSet = Vector3(gridOffSet.x,0,gridOffSet.y)
            local renderOffSet = Vector3(off.x,0,off.z)
            effectControllerComponent:SetPosOffSet(renderOffSet)
        end
        
    end
    
    YIELD(TT,loopAnimDelay)
    local effectGo = effectEntity:View():GetGameObject()
    ---@type UnityEngine.Animation
    local anim = effectGo:GetComponentInChildren(typeof(UnityEngine.Animation))
    if anim then
        anim:Play(loopAnim)
    end
    YIELD(TT)
end