require("base_ins_r")
---这条指令用于自己控制场上不在技能技能结果中的其他怪物或者机关。直接搜索活着的monsterID trapID
---@class PlayEntityBindEffectInstruction: BaseInstruction
_class("PlayEntityBindEffectInstruction", BaseInstruction)
PlayEntityBindEffectInstruction = PlayEntityBindEffectInstruction

function PlayEntityBindEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])

    self._monsterClassID = tonumber(paramList["monsterClassID"]) or 0
    self._trapID = tonumber(paramList["trapID"]) or 0
end

---@param casterEntity Entity
function PlayEntityBindEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local entityList = {}

    if self._trapID and self._trapID > 0 then
        local trapGroup = world:GetGroup(world.BW_WEMatchers.Trap)
        for _, e in ipairs(trapGroup:GetEntities()) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            if trapRenderCmpt and not trapRenderCmpt:GetHadPlayDestroy() and self._trapID == trapRenderCmpt:GetTrapID() then
                table.insert(entityList, e)
            end
        end
    end

    if self._monsterClassID and self._monsterClassID > 0 then
        local monsterGroup = world:GetGroup(world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(monsterGroup:GetEntities()) do
            if e:HasView() and not e:HasShowDeath() and self._monsterClassID == e:MonsterID():GetMonsterClassID() then
                table.insert(entityList, e)
            end
        end
    end

    ---@type EffectService
    local effectService = world:GetService("Effect")
    for _, e in ipairs(entityList) do
        local effect = effectService:CreateEffect(self._effectID, e)
    end
end

function PlayEntityBindEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
