require("base_ins_r")
---@class PlayAttachMonsterInstruction: BaseInstruction
_class("PlayAttachMonsterInstruction", BaseInstruction)
PlayAttachMonsterInstruction = PlayAttachMonsterInstruction

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAttachMonsterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectAttachMonsterResult
    local attachMonsterRes = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.AttachMonster)
    if not attachMonsterRes then
        return
    end

    local eliteIDArray = attachMonsterRes:GetEliteIDArray()
    if #eliteIDArray == 0 then
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type Entity
    local targetEntity = world:GetEntityByID(attachMonsterRes:GetTargetID())
    if targetEntity == nil then
        return
    end
    ---@type BodyAreaComponent
    local bodyAreaCmpt = targetEntity:BodyArea()
    local bodyAreaCount = bodyAreaCmpt:GetAreaCount()
    local oriEliteEffID = BattleConst.EliteMonsterPermanentEffectBodyArea1
    if bodyAreaCount ~= 1 then
        oriEliteEffID = BattleConst.EliteMonsterPermanentEffectBodyArea4
    end

    ---获取附身精英词缀所携带的精英特效ID
    ---@type MonsterShowRenderService
    local monsterShowSvc = world:GetService("MonsterShowRender")
    local effectIDList = monsterShowSvc:GetEliteEffectIDList(targetEntity, eliteIDArray)

    ---检查是否需要终止精英怪初始特效和材质动画
    local playTrailEffectEx = false
    if #effectIDList == 0 then
        playTrailEffectEx = true
    elseif #effectIDList == 1 and effectIDList[1] == oriEliteEffID then
        playTrailEffectEx = true
    end
    self:_PlayTrailEffect(targetEntity, playTrailEffectEx)

    self:_PlayEliteEffect(targetEntity, effectIDList, oriEliteEffID)

    ---精英词缀附加的Buff
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    local buffArray = attachMonsterRes:GetAddBuffSeqArray()
    for _, seq in pairs(buffArray) do
        ---@type BuffViewInstance
        local buffViewInst = targetEntity:BuffView():GetBuffViewInstance(seq)
        if buffViewInst then
            playBuffService:PlayAddBuff(TT, buffViewInst, casterEntity:GetID())
        end
    end
end

---@param targetEntity Entity
function PlayAttachMonsterInstruction:_PlayTrailEffect(targetEntity, isPlay)
    if targetEntity and targetEntity:HasView() then
        ---@type UnityEngine.GameObject
        local go = targetEntity:View():GetGameObject()
        local rootTF = go.transform:Find("Root")
        local trailEffectExCmpt = rootTF.gameObject:GetComponent(typeof(TrailsFX.TrailEffectEx))
        if isPlay == false then
            if trailEffectExCmpt then
                UnityEngine.Object.Destroy(trailEffectExCmpt)
            end
            targetEntity:RemoveTrailEffectEx()
            return
        end

        ---已经处于播放状态，直接返回
        if trailEffectExCmpt and targetEntity:TrailEffectEx() then
            return
        end

        local trailEffect = BattleConst.EliteMonsterTrialEffect
        if targetEntity:HasMonsterID() then
            local monsterClassID = targetEntity:MonsterID():GetMonsterClassID()
            local cfg_monster_class = Cfg.cfg_monster_class[monsterClassID]
            if cfg_monster_class.TrailEffect then
                trailEffect = cfg_monster_class.TrailEffect
            end
        end

        trailEffectExCmpt = rootTF.gameObject:AddComponent(typeof(TrailsFX.TrailEffectEx))

        ---@type MainWorld
        local world = targetEntity:GetOwnerWorld()
        local resServ = world.BW_Services.ResourcesPool
        local containerTrailEffect = resServ:LoadAsset(trailEffect)
        if not containerTrailEffect then
            resServ:CacheAsset(trailEffect, 1)
            containerTrailEffect = resServ:LoadAsset(trailEffect)
        end
        assert(containerTrailEffect)

        targetEntity:AddTrailEffectEx(containerTrailEffect, trailEffectExCmpt)
    end
end

---@param targetEntity Entity
function PlayAttachMonsterInstruction:_PlayEliteEffect(targetEntity, effectIDList, oriEliteEffID)
    ---@type EffectHolderComponent
    local effectHolderCmpt = targetEntity:EffectHolder()

    local oriEffEntityID = effectHolderCmpt:GetEliteEffEntityID(oriEliteEffID)

    local needCreateEffIDList = {}
    if #effectIDList == 1 and effectIDList[1] == oriEliteEffID then
        if oriEffEntityID then
            ---已播放默认精英特效，则返回
            return
        else
            ---需要创建后播放的特效
            needCreateEffIDList[#needCreateEffIDList + 1] = oriEliteEffID
        end
    else
        ---获取需要播放的特效
        for _, effID in ipairs(effectIDList) do
            if not effectHolderCmpt:GetEliteEffEntityID(effID) then
                needCreateEffIDList[#needCreateEffIDList + 1] = effID
            end
        end
    end

    ---@type EffectService
    local effectSvc = targetEntity:GetOwnerWorld():GetService("Effect")

    ---需要隐藏默认精英特效
    if oriEffEntityID then
        effectSvc:ShowEffect({ oriEffEntityID }, false)
    end

    ---创建新特效
    for _, effID in ipairs(needCreateEffIDList) do
        local effectEntity = effectSvc:CreateEffect(effID, targetEntity)
        effectHolderCmpt:AttachPermanentEffect(effectEntity:GetID())
        effectHolderCmpt:AddEliteEffID(effID, effectEntity:GetID())
    end
end
