--[[
    播放减少伤害
]]
_class("BuffViewHarmReduction", BuffViewBase)
BuffViewHarmReduction = BuffViewHarmReduction

function BuffViewHarmReduction:PlayView(TT)
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    if coreGameStateID == GameStateID.WaveEnter then
        return
    end

    ---@type BuffResultHarmReduction
    local buffResult = self._buffResult
    local e = self._viewInstance:Entity()
    local entityID = e:GetID()
    local layer = buffResult:GetLayer()
    -- self:BuffViewInstance():SetLayerCount(TT, layer)
    local viewValue = self:BuffViewInstance():GetLayerCount() or 0

    --修改BOSS周身特效
    local destoryEffectList = {}

    --表现里的层数  取的以前的特效
    local oldEffectID = self:GetEffectID(viewValue)
    local createEffectID = self:GetEffectID(layer)

    --设置新的显示层
    self:BuffViewInstance():SetLayerCount(TT, layer)

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    --特效是0  1~8   9
    if createEffectID ~= oldEffectID or createEffectID == 0 then
        ---@type EffectHolderComponent
        local effectHolderCmpt = e:EffectHolder()
        table.insert(destoryEffectList, BattleConst.HarmReductionNormal)
        table.insert(destoryEffectList, BattleConst.HarmReductionInvincible)
        effectService:DestroyEntityEffectByID(e, destoryEffectList)

        if createEffectID and createEffectID > 0 then
            local effect = effectService:CreateEffect(createEffectID, e)
            effectHolderCmpt:AttachPermanentEffect(effect:GetID())
        end
    end

    if buffResult:GetPreviewSkillID() > 0 then
        --取消当前技能预览
        PlayCloseMonsterPreviewRangeInstruction:_HideMonsterAction(e)

        --创建新的技能预览
        local skillHolder = buffResult:GetPreviewSkillHolder()
        ---@type PlaySkillService
        local playSkillSvc = self._world:GetService("PlaySkill")
        local configSvc = self._world:GetService("Config")
        local skillConfigData = configSvc:GetSkillConfigData(buffResult:GetPreviewSkillID(), skillHolder)
        local skillPhaseArray = skillConfigData:GetSkillPhaseArray()
        playSkillSvc:_SkillRoutineTask(TT, skillHolder, skillPhaseArray, buffResult:GetPreviewSkillID())
    end

    self._world:EventDispatcher():Dispatch(GameEventType.UpdateBossHarmReduction, buffResult)
end

function BuffViewHarmReduction:GetEffectID(layer)
    local effectID = 0
    if layer > 0 and layer < 9 then
        effectID = BattleConst.HarmReductionNormal
    elseif layer == 9 then
        effectID = BattleConst.HarmReductionInvincible
    end

    return effectID
end
