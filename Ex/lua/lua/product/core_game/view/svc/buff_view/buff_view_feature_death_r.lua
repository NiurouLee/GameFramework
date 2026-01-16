_class("BuffViewFeatureDeath", BuffViewBase)
BuffViewFeatureDeath = BuffViewFeatureDeath

---
function BuffViewFeatureDeath:PlayView(TT)
    ---@type Entity
    local entity = self._entity
    ---@type BuffResultFeatureDeath
    local result = self._buffResult

    if entity:HasMonsterID() then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = self._world:GetService("MonsterShowRender")
        sMonsterShowRender:DoOneMonsterFeatureDead(TT, entity)
    elseif entity:HasTrapID() then
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        trapServiceRender:DestroyTrap(TT, entity)
    end
end

---
function BuffViewFeatureDeath:IsNotifyMatch(notify)
    -- if self._buffResult:GetEntityID() == notify:GetNotifyEntity():GetID() then
    --     return true
    -- end
    return true
end
