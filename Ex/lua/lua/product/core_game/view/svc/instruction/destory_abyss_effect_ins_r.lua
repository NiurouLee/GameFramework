--深渊出场技专用，加载深渊特效
require("base_ins_r")

---@class DestroyAbyssEffectInstruction: BaseInstruction
_class("DestroyAbyssEffectInstruction", BaseInstruction)
DestroyAbyssEffectInstruction = DestroyAbyssEffectInstruction

function DestroyAbyssEffectInstruction:Constructor(paramList)
end

---@param casterEntity Entity
function DestroyAbyssEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type Entity
    self._casterEntity = casterEntity
    if not casterEntity:HasTrapID() then
        return
    end

    local cEffectHolder = casterEntity:EffectHolder()
    if not cEffectHolder then
        casterEntity:AddEffectHolder()
    end
    cEffectHolder = casterEntity:EffectHolder()
    local dictEffectId = cEffectHolder:GetDictEffectId()
    if dictEffectId then
        for key, list in pairs(dictEffectId) do
            for index, id in ipairs(list) do
                local eEffect = self._world:GetEntityByID(id)
                if eEffect then
                    self._world:DestroyEntity(eEffect)
                end
            end
        end
    end
end