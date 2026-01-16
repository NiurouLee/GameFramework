require("base_ins_r")
---@class PlayTrapSummonMonsterInstruction: BaseInstruction
_class("PlayTrapSummonMonsterInstruction", BaseInstruction)
PlayTrapSummonMonsterInstruction = PlayTrapSummonMonsterInstruction

function PlayTrapSummonMonsterInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._materialAnimName = paramList["materialAnimName"]
end

function PlayTrapSummonMonsterInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end


---@param casterEntity Entity
function PlayTrapSummonMonsterInstruction:DoInstruction(TT,casterEntity,phaseContext)
    self._world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectTrapSummonMonsterResult[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.TrapSummonMonster)
    if not resultArray or not resultArray[1] then
        return
    end
    ---@type SkillEffectTrapSummonMonsterResult
    local result = resultArray[1]
    if not result:GetSummonEntityID() then
        return
    end
    local entityID = result:GetSummonEntityID()
    local transformParam = result:GetMonsterTransformParam()
    ---@type Entity
    local summonEntity = self._world:GetEntityByID(entityID)
    local gridPos = summonEntity:GetGridPosition()
    summonEntity:SetPosition(gridPos)
    summonEntity:SetLocationHeight(0)
    summonEntity:SetViewVisible(true)
    ---@type EffectService
    local effectSvc =self._world:GetService("Effect")
    effectSvc:CreateWorldPositionDirectionEffect(self._effectID,gridPos)
    ---@type MonsterShowRenderService
    local monsterShowRenderSvc = self._world:GetService("MonsterShowRender")
    summonEntity:PlayMaterialAnim(self._materialAnimName)
    monsterShowRenderSvc:ShowSummonMonster(TT,  summonEntity,transformParam )
end