require("base_ins_r")
---@class PlaySelectCenterGridEffectInstruction: BaseInstruction
_class("PlaySelectCenterGridEffectInstruction", BaseInstruction)
PlaySelectCenterGridEffectInstruction = PlaySelectCenterGridEffectInstruction

function PlaySelectCenterGridEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._intervalTime = tonumber(paramList["intervalTime"])
    self._overrideScopeByEffectType = tonumber(paramList["overrideScopeByEffectType"])

    self._isFacingMonsterOnGrid = tonumber(paramList["isFacingMonsterOnGrid"]) == 1
end

function PlaySelectCenterGridEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
function PlaySelectCenterGridEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    --获取攻击范围
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    if self._overrideScopeByEffectType then
        local fxResultDict = skillEffectResultContainer:GetEffectResultDict()
        local allResults = fxResultDict[self._overrideScopeByEffectType]
        if allResults and allResults.array[1] then
            scopeResult = allResults.array[1]:GetSkillEffectScopeResult()
        end
    end
    if not scopeResult then
        return
    end
    -- 中心格
    local centerPos = scopeResult:GetCenterPos()
    if not centerPos then
        return
    end

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local worldPos = boardServiceRender:GridPos2RenderPos(centerPos)

    --创建特效
    ---@type EffectService
    local effectService = world:GetService("Effect")
    local effectEntity = effectService:CreatePositionEffect(self._effectID, worldPos)

    if self._isFacingMonsterOnGrid then
        ---@type BoardServiceRender
        local brsvc = world:GetService("BoardRender")

        ---@type Entity|nil
        local lookAtEntity

        local GLOBALmonsterEntities = world:GetGroupEntities(world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(GLOBALmonsterEntities) do
            local tv2Body = e:BodyArea():GetArea()
            if #tv2Body > 1 then
                -- local v2GridPos = e:GetGridPosition()
                local v3RenderPos = e:GetPosition()
                local v2GridPos = brsvc:BoardRenderPos2FloatGridPos_New(v3RenderPos)
                v2GridPos.x = math.floor(v2GridPos.x)
                v2GridPos.y = math.floor(v2GridPos.y)
                for _, v2RelativeBody in ipairs(tv2Body) do
                    if centerPos == v2RelativeBody + v2GridPos then
                        lookAtEntity = e
                        break
                    end
                end
            end

            if lookAtEntity then
                break
            end
        end

        if lookAtEntity then
            local v2TargetPos = brsvc:BoardRenderPos2FloatGridPos_New(lookAtEntity:GetPosition())
            local v2FxPos = brsvc:BoardRenderPos2FloatGridPos_New(effectEntity:GetPosition())
            local v2Dir = v2TargetPos - v2FxPos

            local rotatedDir = Vector2.New((-1) * v2Dir.y, v2Dir.x) --[[直接设置方向有90度的偏差]]

            effectEntity:View():GetGameObject().transform.rotation = Vector3.zero
            effectEntity:SetDirection(rotatedDir)
        end
    end

    YIELD(TT, self._intervalTime)
end
