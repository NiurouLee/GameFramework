require("base_ins_r")
---@class PlayTargetRefreshBuffViewInstruction: BaseInstruction
_class("PlayTargetRefreshBuffViewInstruction", BaseInstruction)
PlayTargetRefreshBuffViewInstruction = PlayTargetRefreshBuffViewInstruction

function PlayTargetRefreshBuffViewInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetRefreshBuffViewInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    if not targetEntityID then
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local targetEntity = world:GetEntityByID(targetEntityID)
    ---@type BuffViewComponent
    local buffViewComponent = targetEntity:BuffView()

    if not buffViewComponent then
        return
    end
    local curIndex = phaseContext:GetCurBuffResultIndex()

    local buffResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ModifyBuffValue)
    if buffResultArray == nil or table.count(buffResultArray) < curIndex then
        Log.fatal("add buff instruction ,buff result is nil")
        return
    end

    ---@type SkillModifyBuffValueResult
    local buffResult = buffResultArray[curIndex]

    ---@type BuffViewInstance
    local viewInstance = buffViewComponent:GetBuffViewInstance(buffResult:GetBuffSeq())
    if viewInstance then
        viewInstance:SetLayerCount(TT, buffResult:GetBuffLayer())
    end
    local entity = viewInstance:Entity()
    world:GetService("PlayBuff"):PlayUIChangeBuff(entity)
end
