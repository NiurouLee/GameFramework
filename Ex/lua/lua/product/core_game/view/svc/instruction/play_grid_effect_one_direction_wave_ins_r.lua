require("base_ins_r")
---@class PlayGridEffectOneDirectionWaveInstruction: BaseInstruction
_class("PlayGridEffectOneDirectionWaveInstruction", BaseInstruction)
PlayGridEffectOneDirectionWaveInstruction = PlayGridEffectOneDirectionWaveInstruction

function PlayGridEffectOneDirectionWaveInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._intervalTime = tonumber(paramList["intervalTime"])
    self._waveDirection = tonumber(paramList["waveDirection"])
    self._waveWidth = tonumber(paramList["waveWidth"])
end

function PlayGridEffectOneDirectionWaveInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridEffectOneDirectionWaveInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")

    local casterPos = casterEntity:GridLocation().Position

    if self._waveWidth == 1 then
        self:_PlayOneLineGridEffect(casterEntity)
    else
    end
end

---@param casterEntity Entity
function PlayGridEffectOneDirectionWaveInstruction:_PlayOneLineGridEffect(casterEntity)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")

    local casterPos = casterEntity:GridLocation().Position

    if self._waveDirection == InstructionConst.WidthWise then
        local row = casterPos.y
    elseif self._waveWidth == InstructionConst.HeightWise then
        local effectX = casterPos.x
        ---todo:这个effectDir需要重构
        local effectDir = Vector2(1, 0)
        ---@type UtilDataServiceShare
        local utilDataSvc = world:GetService("UtilData")
        local boardMaxY = utilDataSvc:GetCurBoardMaxY()
        for row = 1, boardMaxY do
            local effectPos = Vector2(effectX, row)
            effectService:CreateWorldPositionDirectionEffect(self._effectID, effectPos, effectDir)
            YIELD(TT, self._intervalTime)
        end
    end
end
