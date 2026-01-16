require("base_ins_r")
---@class PlayDetachMonsterInstruction: BaseInstruction
_class("PlayDetachMonsterInstruction", BaseInstruction)
PlayDetachMonsterInstruction = PlayDetachMonsterInstruction

function PlayDetachMonsterInstruction:Constructor(paramList)
    local str = paramList["delEffIDList"]
    local tmpStrIDList = string.split(str, "|")
    self._deleteEffectIDList = {} ---脱离时，需要删除宿主身上的附身特效ID列表
    for i, strID in ipairs(tmpStrIDList) do
        table.insert(self._deleteEffectIDList, tonumber(strID))
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDetachMonsterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectDetachMonsterResult
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.DetachMonster)
    if not result then
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type Entity
    local targetEntity = world:GetEntityByID(result:GetTargetID())
    if targetEntity == nil then
        return
    end

    if targetEntity:HasDeadMark() then
        return
    end

    ---删除附身时添加的特效
    if targetEntity:HasEffectHolder() then
        ---@type EffectHolderComponent
        local effectHolderCmpt = targetEntity:EffectHolder()
        local effectDictList1 = effectHolderCmpt:GetDictEffectId()
        local effectDictList2 = effectHolderCmpt:GetEffectIDEntityDic()
        self:_DeleteEffect(world, effectDictList1)
        self:_DeleteEffect(world, effectDictList2)
    end

    ---@type BodyAreaComponent
    local bodyAreaCmpt = targetEntity:BodyArea()
    local bodyAreaCount = bodyAreaCmpt:GetAreaCount()
    local oriEliteEffID = BattleConst.EliteMonsterPermanentEffectBodyArea1
    if bodyAreaCount ~= 1 then
        oriEliteEffID = BattleConst.EliteMonsterPermanentEffectBodyArea4
    end

    ---脱离时一起脱离，所以直接使用逻辑组件中的数据
    ---@type MonsterIDComponent
    local monsterIDCmpt = targetEntity:MonsterID()
    local eliteIDArray = monsterIDCmpt:GetEliteIDArray()
    if #eliteIDArray == 0 then
        ---宿主本身不是精英怪
        oriEliteEffID = nil
    end

    ---获取宿主本身的精英词缀所携带的精英特效ID
    ---@type MonsterShowRenderService
    local monsterShowSvc = world:GetService("MonsterShowRender")
    local effectIDList = #eliteIDArray > 0 and monsterShowSvc:GetEliteEffectIDList(targetEntity, eliteIDArray) or {}


    ---检查是否需要终止精英怪初始特效和材质动画
    local playTrailEffectEx = false
    if #effectIDList == 0 and #eliteIDArray > 0 then
        playTrailEffectEx = true
    elseif #effectIDList == 1 and effectIDList[1] == oriEliteEffID then
        playTrailEffectEx = true
    end
    self:_PlayTrailEffect(targetEntity, playTrailEffectEx)

    self:_PlayEliteEffect(targetEntity, effectIDList, oriEliteEffID)

    ---精英词缀附加的Buff
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    local buffArray = result:GetRemoveBuffSeqArray()
    for _, seq in pairs(buffArray) do
        ---@type BuffViewInstance
        local buffViewInst = targetEntity:BuffView():GetBuffViewInstance(seq)
        if buffViewInst then
            playBuffService:PlayRemoveBuff(TT, buffViewInst, NTBuffUnload:New())
        end
    end
end

---@param targetEntity Entity
function PlayDetachMonsterInstruction:_PlayTrailEffect(targetEntity, isPlay)
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
function PlayDetachMonsterInstruction:_PlayEliteEffect(targetEntity, effectIDList, oriEliteEffID)
    ---@type EffectHolderComponent
    local effectHolderCmpt = targetEntity:EffectHolder()
    ---@type EffectService
    local effectSvc = targetEntity:GetOwnerWorld():GetService("Effect")

    local oriEffEntityID = nil
    if oriEliteEffID then
        oriEffEntityID = effectHolderCmpt:GetEliteEffEntityID(oriEliteEffID)
    end
    if #effectIDList == 1 and effectIDList[1] == oriEliteEffID then
        if oriEffEntityID then
            effectSvc:ShowEffect({ oriEffEntityID }, true)
        end
    end

    local needDelEffIDList = {}
    local eliteDic = effectHolderCmpt:GetEliteEffIDDic()
    for effID, entityID in pairs(eliteDic) do
        if not table.icontains(effectIDList, effID) then
            effectSvc:DestroyEffectByID(entityID)
            table.insert(needDelEffIDList, effID)
        end
    end

    effectHolderCmpt:DeleteEliteEffIDDic(needDelEffIDList)
end

function PlayDetachMonsterInstruction:_DeleteEffect(world, effectList)
    for effectID, entityIDList in pairs(effectList) do
        if table.icontains(self._deleteEffectIDList, effectID) then
            for _, entityID in ipairs(entityIDList) do
                local entity = world:GetEntityByID(entityID)
                if entity then
                    world:DestroyEntity(entity)
                end
            end
        end
    end
    for effectID, entityIDList in pairs(effectList) do
        if table.icontains(self._deleteEffectIDList, effectID) then
            entityIDList = {}
        end
    end
end
