require("base_ins_r")
---@class PlayGridRangeEffectInstruction: BaseInstruction
_class("PlayGridRangeEffectInstruction", BaseInstruction)
PlayGridRangeEffectInstruction = PlayGridRangeEffectInstruction

function PlayGridRangeEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._delayTime = tonumber(paramList["delayTime"]) or 0
    local strIsRotate = paramList["isRotate"]
    if strIsRotate then
        self._isRotate = tonumber(strIsRotate) == 1
    else
        self._isRotate = false
    end
    local strStep = paramList["step"] --步长
    if strStep then
        self._step = tonumber(strStep)
    else
        self._step = 1
    end
    local strOffset = paramList["offset"] --特效偏移
    if strOffset then
        local arr = string.split(strOffset, "|")
        self._offset = Vector2(tonumber(arr[1]), tonumber(arr[2]))
    else
        self._offset = Vector2.zero
    end
    local randomRotate = paramList["randomRotate"] --随机朝向
    if randomRotate then
        self._randomRotate = tonumber(randomRotate)
    else
        self._randomRotate = nil
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridRangeEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local scopeGridRange = phaseContext:GetScopeGridRange()
    if not scopeGridRange then
        return InstructionConst.PhaseEnd
    end
    local maxScopeRangeCount = phaseContext:GetMaxRangeCount()
    if not maxScopeRangeCount then
        return InstructionConst.PhaseEnd
    end
    local curScopeGridRangeIndex = phaseContext:GetCurScopeGridRangeIndex()
    if curScopeGridRangeIndex > maxScopeRangeCount then
        return
    end
    local casterPos = casterEntity:GridLocation():GetGridPos()
    --播放特效
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")

    for _, range in pairs(scopeGridRange) do
        if range then
            local posList = range[curScopeGridRangeIndex]
            if posList then
                local len = table.count(posList)
                for i = 1, len, self._step do
                    local pos = posList[i]
                    local targetPos = pos + self._offset --加偏移
                    --偏移
                    if self._isRotate then
                        effectService:CreateWorldPositionDirectionEffect(
                            self._effectID,
                            targetPos,
                            targetPos - casterPos
                        )
                    elseif self._randomRotate then
                        --以格子为中心 随机方向偏移
                        local randomPos =
                        Vector2(math.random(0, self._randomRotate), math.random(0, self._randomRotate))

                        effectService:CreateWorldPositionDirectionEffect(self._effectID, targetPos, randomPos)
                    else
                        effectService:CreateWorldPositionEffect(self._effectID, targetPos)
                    end
                    if self._delayTime > 0 then
                        YIELD(TT, self._delayTime)
                    end
                end
            end
        end
    end
end

function PlayGridRangeEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._effectID].ResPath, 10 })
    end
    return t
end
