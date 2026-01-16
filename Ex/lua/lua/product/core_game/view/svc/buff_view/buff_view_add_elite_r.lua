--[[
    添加精英词缀
]]
---@class BuffViewAddElite:BuffViewBase
_class("BuffViewAddElite", BuffViewBase)
BuffViewAddElite = BuffViewAddElite

function BuffViewAddElite:PlayView(TT)
    ---@type BuffResultAddElite
    local buffRes = self._buffResult
    local eliteIDArray = buffRes:GetEliteIDArray()
    if #eliteIDArray == 0 then
        return
    end

    ---@type BodyAreaComponent
    local bodyAreaCmpt = self._entity:BodyArea()
    local bodyAreaCount = bodyAreaCmpt:GetAreaCount()
    local oriEliteEffID = BattleConst.EliteMonsterPermanentEffectBodyArea1
    if bodyAreaCount ~= 1 then
        oriEliteEffID = BattleConst.EliteMonsterPermanentEffectBodyArea4
    end

    ---获取精英词缀所携带的精英特效ID
    ---@type MonsterShowRenderService
    local monsterShowSvc = self._world:GetService("MonsterShowRender")
    local effectIDList = monsterShowSvc:GetEliteEffectIDList(self._entity, eliteIDArray)

    ---检查是否需要终止精英怪初始特效和材质动画
    local playTrailEffectEx = false
    if #effectIDList == 0 then
        playTrailEffectEx = true
    elseif #effectIDList == 1 and effectIDList[1] == oriEliteEffID then
        playTrailEffectEx = true
    end
    self:_PlayTrailEffect(self._entity, playTrailEffectEx)

    self:_PlayEliteEffect(self._entity, effectIDList, oriEliteEffID)

    ---精英词缀附加的Buff
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    local buffArray = buffRes:GetAddBuffSeqArray()
    for _, seq in pairs(buffArray) do
        ---@type BuffViewInstance
        local buffViewInst = self._entity:BuffView():GetBuffViewInstance(seq)
        if buffViewInst then
            playBuffService:PlayAddBuff(TT, buffViewInst, self._entity:GetID())
        end
    end

    ---通知UI血条，刷新精英词条信息
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local hpBarType = utilDataSvc:GetHPBarTypeByEntity(self._entity)
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.UpdateBossNameAndElement,
        self._entity:MonsterID():GetMonsterID(),
        hpBarType,
        self._entity:GetID()
    )
end

---@param targetEntity Entity
function BuffViewAddElite:_PlayTrailEffect(targetEntity, isPlay)
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
function BuffViewAddElite:_PlayEliteEffect(targetEntity, effectIDList, oriEliteEffID)
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
