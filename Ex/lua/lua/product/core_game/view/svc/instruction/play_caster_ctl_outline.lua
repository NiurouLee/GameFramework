require("base_ins_r")
---@class PlayCasterControlOutLineInstruction: BaseInstruction
_class("PlayCasterControlOutLineInstruction", BaseInstruction)
PlayCasterControlOutLineInstruction = PlayCasterControlOutLineInstruction

function PlayCasterControlOutLineInstruction:Constructor(paramList)
    self._enable = tonumber(paramList["enable"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterControlOutLineInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if casterEntity:MonsterID() then
        ---@type MainWorld
        local world = casterEntity:GetOwnerWorld()
        ---@type MonsterIDComponent
        local monsterIDCmpt = casterEntity:MonsterID()
        monsterIDCmpt:SetNeedOutLineEnable(self._enable == 1 )
        ---@type RenderEntityService
        local renderEntityService = world:GetService("RenderEntity")
        if self._enable == 1 then
            renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
            renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
        else
            renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
        end
    end
end
