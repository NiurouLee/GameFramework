require("base_ins_r")
---@class PlayMultiTractionInstruction: BaseInstruction
_class("PlayMultiTractionInstruction", BaseInstruction)
PlayMultiTractionInstruction = PlayMultiTractionInstruction

function PlayMultiTractionInstruction:Constructor(paramList)
    self._targetEffectID = tonumber(paramList.targetEffectID) or 0
    self._moveSpeed = paramList.moveSpeed or BattleConst.TractionSpeed
end

function PlayMultiTractionInstruction:GetCacheResource()
    local t = {}
    if self._targetEffectID and self._targetEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._targetEffectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMultiTractionInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    self._world = world
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    -- 同一技能内不存在多重牵引
    ---@type SkillEffectMultiTractionResult
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.MultiTraction)
    if not result then
        return
    end
    local taskIDs = {}
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")

    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type RenderEntityService
    local entityRenderService = world:GetService("RenderEntity")

    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    local teamTractionData
    local teamEntity
    local array = result:GetResultArray()
    for _, info in ipairs(array) do
        local entity = world:GetEntityByID(info.entityID)
        if entity then
            ---被牵引且位置发生改变才更新怪物位置及阻挡信息
            if info.beginPos ~= info.finalPos then
                if self._targetEffectID > 0 then
                    effectService:CreateEffect(self._targetEffectID, entity)
                end

                local currentPos = boardServiceRender:GetRealEntityGridPos(entity)
                entity:SetDirection(info.finalPos - currentPos)
                entity:SetAnimatorControllerBools({ [BattleConst.DefaultMovementAnimatorBool] = true })
                local gridPos = boardServiceRender:GetRealEntityGridPos(entity)
                entity:AddGridMove(self._moveSpeed, info.finalPos, gridPos)

                entityRenderService:DestroyMonsterAreaOutLineEntity(entity)
                pieceService:RefreshMonsterPiece(entity, true)
                local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._CheckMoveFinish, self, entity)
                table.insert(taskIDs, taskID)

                -- 队长出发瞬间把原点格刷新
                if entity:HasTeam() then
                    teamTractionData = info
                    teamEntity = entity
                    local supply = result:GetSupplyPlayerPiece()
                    if supply then
                        boardServiceRender:ReCreateGridEntity(supply.color, info.beginPos)
                        ---@type PlayBuffService
                        local svcPlayBuff = world:GetService("PlayBuff")
                        svcPlayBuff:_SendNTGridConvertRender(TT, info.beginPos, supply.color,
                            SkillEffectType.MultiTraction)
                        local colorNew = result:GetColorNew()
                        boardServiceRender:ReCreateGridEntity(colorNew, info.finalPos)
                    end
                end
            end
            
            ---@type PlayBuffService
            local svcPlayBuff = self._world:GetService("PlayBuff")
            svcPlayBuff:PlayBuffView(TT, NTTractionEnd:New(casterEntity, entity, info.beginPos, info.finalPos))
        end
    end

    while (not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs)) do
        YIELD(TT)
    end

    -- 队长被移到位置之后，将新的脚下置灰
    if teamTractionData then
        local posOld = teamTractionData.beginPos
        local posNew = teamTractionData.finalPos

        local pets = teamEntity:Team():GetTeamPetEntities()
        ---@param petEntity Entity
        for i, petEntity in ipairs(pets) do
            petEntity:SetLocation(posNew)
        end

        teamEntity:SetLocation(posNew)
        boardServiceRender:ReCreateGridEntity(PieceType.None, posNew)
    end

    if self._targetEffectID > 0 then
        effectService:DestroyEffectByID(self._targetEffectID)
    end

    -- 触发型机关的触发
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    for _, info in ipairs(array) do
        local entity = world:GetEntityByID(info.entityID)
        if entity and (info.beginPos ~= info.finalPos) then -- 没能移动的目标不会重复触发机关
            local listTrapTrigger = info:GetTriggerTraps()
            trapServiceRender:PlayTrapTriggerSkillTasks(TT, listTrapTrigger, false, entity)
        end
    end

    return
end

---@param entity Entity
function PlayMultiTractionInstruction:_CheckMoveFinish(TT, entity)
    while (entity:HasGridMove()) do
        YIELD(TT)
    end

    ---@type MainWorld
    local world = entity:GetOwnerWorld()
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")

    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")

    local realPos = boardServiceRender:GetRealEntityGridPos(entity)

    ---@type RenderEntityService
    local entityRenderService = world:GetService("RenderEntity")
    pieceService:RefreshMonsterPiece(entity, false)
    entityRenderService:CreateMonsterAreaOutlineEntity(entity)
    trapServiceRender:ShowHideTrapAtPos(realPos, false)
    entity:SetAnimatorControllerBools({[BattleConst.DefaultMovementAnimatorBool] = false})
end
