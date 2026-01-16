require("base_ins_r")
---@class PlayCasterLaserGunAndExtendInstruction: BaseInstruction
_class("PlayCasterLaserGunAndExtendInstruction", BaseInstruction)
PlayCasterLaserGunAndExtendInstruction = PlayCasterLaserGunAndExtendInstruction

function PlayCasterLaserGunAndExtendInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._extendEffectID = tonumber(paramList["extendEffectID"])
    self._extendWaitTime = tonumber(paramList["extendWaitTime"]) or 0
    self._limitExtendCount = tonumber(paramList["limitExtendCount"]) or 99
end

---@param casterEntity Entity
function PlayCasterLaserGunAndExtendInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()

    ---@type EffectService
    local effectService = world:GetService("Effect")

    ---@type Entity
    local effect = effectService:CreateEffect(self._effectID, casterEntity)

    YIELD(TT, self._extendWaitTime)

    --机关扩散
    local casterDir = casterEntity:GridLocation():GetGridDir()
    local casterrPos = casterEntity:GridLocation().Position

    local dirCross = {}
    if casterDir.x == 0 and casterDir.y ~= 0 then
        table.insert(dirCross, Vector2(1, 0))
        table.insert(dirCross, Vector2(-1, 0))
    elseif casterDir.x ~= 0 and casterDir.y == 0 then
        table.insert(dirCross, Vector2(0, 1))
        table.insert(dirCross, Vector2(0, -1))
    end

    local dirDoubleCross = {}
    table.insert(dirDoubleCross, Vector2(1, 1))
    table.insert(dirDoubleCross, Vector2(1, -1))
    table.insert(dirDoubleCross, Vector2(-1, 1))
    table.insert(dirDoubleCross, Vector2(-1, -1))

    ---@type UtilDataServiceShare
    local utilSvc = world:GetService("UtilData")
    local attackRange = {}
    local hadExtendCount = 0
    for i = 1, 9 do
        local nextPos = Vector2(casterrPos.x + (i * casterDir.x), casterrPos.y + (i * casterDir.y))
        if utilSvc:IsValidPiecePos(nextPos) then
            table.insert(attackRange, nextPos)
        end
    end

    local trapExtend = {}
    for _, pos in ipairs(attackRange) do
        local array = utilSvc:GetTrapsAtPos(pos)
        for _, eTrap in ipairs(array) do
            if eTrap:TrapRender() and not eTrap:HasDeadMark() and eTrap:HasTrapExtendSkillScope() then
                local entityID = eTrap:GetID()
                table.insert(trapExtend, eTrap)

                hadExtendCount = hadExtendCount + 1
            end
        end

        if hadExtendCount >= self._limitExtendCount then
            break
        end
    end

    for _, trapEntity in ipairs(trapExtend) do
        ---@type TrapExtendSkillScopeComponent
        local trapExtendSkillScope = trapEntity:TrapExtendSkillScope()
        local scopeType = trapExtendSkillScope:GetScopeType()
        local scopeParam = trapExtendSkillScope:GetScopeParam()
        local pos = trapEntity:GridLocation().Position

        for _, dir in ipairs(dirCross) do
            -- local extendEffect = effectService:CreateEffect(self._extendEffectID, trapEntity)
            -- extendEffect:SetDirection(dir)
            effectService:CreateWorldPositionDirectionEffect(self._extendEffectID, pos, dir)
        end

        --基础四方向后 一定创建的
        if scopeType == SkillScopeType.DoubleCross then
            for _, dir in ipairs(dirDoubleCross) do
                -- local extendEffect = effectService:CreateEffect(self._extendEffectID, trapEntity)
                -- extendEffect:SetDirection(dir)
                effectService:CreateWorldPositionDirectionEffect(self._extendEffectID, pos, dir)
            end
        end
    end
end

function PlayCasterLaserGunAndExtendInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    if self._extendEffectID and self._extendEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._extendEffectID].ResPath, 4})
    end
    return t
end
