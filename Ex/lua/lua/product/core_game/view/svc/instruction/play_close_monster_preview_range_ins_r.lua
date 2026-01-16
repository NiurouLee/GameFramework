require("base_ins_r")
---@class PlayCloseMonsterPreviewRangeInstruction: BaseInstruction
_class("PlayCloseMonsterPreviewRangeInstruction", BaseInstruction)
PlayCloseMonsterPreviewRangeInstruction = PlayCloseMonsterPreviewRangeInstruction

function PlayCloseMonsterPreviewRangeInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCloseMonsterPreviewRangeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    self:_HideMonsterAction(casterEntity)
end

---删除怪物行动预览
function PlayCloseMonsterPreviewRangeInstruction:_HideMonsterAction(casterEntity)
    local monsterEntityID = casterEntity:GetID()

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterPreviewAreaOutlineEntity()
    ---@type PreviewActiveSkillService
    local previewActiveSkillSvc = world:GetService("PreviewActiveSkill")
    --previewActiveSkillSvc:AllPieceDoConvert("Normal")
    world:GetService("MonsterShowRender"):MonsterGridAnimDown()

    ---@type Entity
    local previewEntity = world:GetPreviewEntity()
    ---@type RenderStateComponent
    local renderStatCmpt = previewEntity:RenderState()

    local skillTipsEntityID = renderStatCmpt:GetSkillTipsEntityID()
    if skillTipsEntityID ~= -1 then
        local skillTipsEntity = world:GetEntityByID(skillTipsEntityID)
        skillTipsEntity:SetViewVisible(false)
    end
    -- self:_RemoveMonsterAttackText(world,monsterEntityID)

    local monsterEntity = world:GetEntityByID(monsterEntityID)
    ---@type EffectHolderComponent
    local holderCmp = monsterEntity:EffectHolder()
    if not holderCmp then
        return
    end
    local idDic = holderCmp:GetEffectIDEntityDic()
    local entityList = idDic[BattleConst.MonsterAttackRangeTextEffect]
    if entityList then
        for k, entityId in pairs(entityList) do
            local entity = world:GetEntityByID(entityId)
            if entity then
                world:DestroyEntity(entity)
            end
        end
        idDic[BattleConst.MonsterAttackRangeTextEffect] = nil
    end
end

function PlayCloseMonsterPreviewRangeInstruction:_RemoveMonsterAttackText(world, monsterEntityID)
    local monsterEntity = world:GetEntityByID(monsterEntityID)
    ---@type EffectHolderComponent
    local holderCmp = monsterEntity:EffectHolder()
    if not holderCmp then
        return
    end
    local idDic = holderCmp:GetEffectIDEntityDic()
    local entityList = idDic[BattleConst.MonsterAttackRangeTextEffect]
    if entityList then
        for k, entityId in pairs(entityList) do
            local entity = world:GetEntityByID(entityId)
            if entity then
                world:DestroyEntity(entity)
            end
        end
        idDic[BattleConst.MonsterAttackRangeTextEffect] = nil
    end
end
