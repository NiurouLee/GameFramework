--[[-----------------------------
    EffectService: 特效Service
--]] -----------------------------
_class("EffectService", Object)
---@class EffectService:Object
EffectService = EffectService

function EffectService:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = world:GetService("Config")
end

function EffectService:Initialize()
    ---@type RenderEntityService
    self._renderEntityService = self._world:GetService("RenderEntity")
end

---@param e Entity
function EffectService:DestroyStaticEffect(e)
    local cEffectHolder = e:EffectHolder()
    if not cEffectHolder then
        return
    end
    local permanentEffectList = cEffectHolder:GetPermanentEffect()
    self:_DestroyEffectArray(permanentEffectList)

    local idleEffectList = cEffectHolder:GetIdleEffect()
    self:_DestroyEffectArray(idleEffectList)

    local weakEffectList = cEffectHolder:GetWeakEffect()
    self:_DestroyEffectArray(weakEffectList)

    local effectIDEntityDic = cEffectHolder:GetEffectIDEntityDic()
    for _, entityIDList in pairs(effectIDEntityDic) do
        for _, entityID in pairs(entityIDList) do
            local effectEntity = self._world:GetEntityByID(entityID)
            if effectEntity ~= nil then
                self._world:DestroyEntity(effectEntity)
            end
        end
    end
    --
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

function EffectService:_DestroyEffectArray(effectIDArray)
    for _, effectID in ipairs(effectIDArray) do
        local effectEntity = self._world:GetEntityByID(effectID)
        if effectEntity ~= nil then
            self._world:DestroyEntity(effectEntity)
        end
    end
end

function EffectService:GetEffectHolder(effectID)
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        return "caster"
    end
    return effectConfigItem.Holder
end

---@return Entity
function EffectService:CreateEffectEntity()
    local e = self._renderEntityService:CreateRenderEntity(EntityConfigIDRender.Effect)
    return e
end

---@param holderEntity Entity
---@return Entity 特效entity
function EffectService:CreateEffect(effectID, holderEntity, state)
    local eInitialHolder = holderEntity
    local eAvatar
    if holderEntity:HasEffectHolder() then
        local cEffectHolder = holderEntity:EffectHolder()
        local teAvatar = cEffectHolder:GetEffectList("BuffViewShowHidePetRoot") or {}
        if teAvatar[1] then
            eAvatar = teAvatar[1]
            holderEntity = eAvatar
        end
    end

    local show = true
    if state ~= nil then
        show = state
    end
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        Log.fatal("EffectService CreateEffect failed:", effectID, " ", Log.traceback())
        return nil
    end

    if effectConfigItem.ResPath == nil then
        Log.fatal("cannot find effect res ,effectID is", effectID)
    end

    --Log.fatal("创建特效:"..effectID)
    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath, show))
    effectEntity:AddEffectController(
        holderEntity,
        effectConfigItem.BindPos,
        effectConfigItem.Duration,
        effectConfigItem.Type
    )
    local effCtrl = effectEntity:EffectController()
    if effectConfigItem.FollowMove ~= nil then
        effCtrl:SetFollowMove(effectConfigItem.FollowMove)
    end
    if effectConfigItem.FollowRotate ~= nil then
        effCtrl:SetFollowRotate(effectConfigItem.FollowRotate)
    end
    if effectConfigItem.BindLayer then
        effCtrl:SetBindLayer(effectConfigItem.BindLayer)
    end
    if effectConfigItem.FollowRotateCaster then
        effCtrl:SetFollowRotateCaster(effectConfigItem.FollowRotateCaster)
    end
    local effectHolder = holderEntity:EffectHolder()
    if not effectHolder then
        holderEntity:AddEffectHolder()
        effectHolder = holderEntity:EffectHolder()
    end
    effectHolder:AttachEffectByEffectID(effectID, effectEntity:GetID())

    if eAvatar then
        if not eInitialHolder:HasEffectHolder() then
            eInitialHolder:AddEffectHolder()
        end
        local cInitialEffectHolder = eInitialHolder:EffectHolder()
        cInitialEffectHolder:AttachEffectByEffectID(effectID, effectEntity:GetID())
        effectHolder:AttachEffect("EffectHolderReplacedByAvatar", effectEntity)
    end

    return effectEntity
end
---被击特效统一处理
---@param damageShowType DamageShowType
function EffectService:CreateBeHitEffect(hitEffectID, holderEntity, damageShowType, gridPos)
    if damageShowType and damageShowType == DamageShowType.Grid then
        ---@type MonsterConfigData
        local monsterConfigData = self._configService:GetMonsterConfigData()
        if
            holderEntity:MonsterID() and
                monsterConfigData:GetMonsterOffSetWithBindPos(holderEntity:MonsterID():GetMonsterID())
         then
            self:CreateGridEffectWithBindPos(hitEffectID, gridPos, holderEntity)
        else
            return self:CreateEffect(hitEffectID, holderEntity)
        end
    else
        return self:CreateEffect(hitEffectID, holderEntity)
    end
end

---@param isShow boolean 默认创建是否显示，不传默认显示
---@return Entity 定点特效entity
function EffectService:CreateWorldPositionEffect(effectID, grid_pos, isShow)
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        return nil
    end

    ---@type Entity
    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath, isShow))
    effectEntity:SetPosition(grid_pos)
    effectEntity:AddEffect(effectConfigItem.Duration)
    return effectEntity
end

---@return Entity 定点定向特效entity
---@param grid_pos Vector2 是格子坐标
---@param grid_dir Vector2 是格子坐标方向
function EffectService:CreateWorldPositionDirectionEffect(effectID, grid_pos, grid_dir)
    ---@type Entity
    local entity = self:CreateWorldPositionEffect(effectID, grid_pos)
    if entity then
        entity:SetDirection(grid_dir)
    end
    return entity
end

function EffectService:CreateTransformEffect(effectID, grid_pos, grid_dir, localScale)
    ---@type Entity
    local entity = self:CreateWorldPositionEffect(effectID, grid_pos)
    if entity then
        entity:SetDirection(grid_dir)
    end
end

---@param monsterEntity Entity
---@return Entity
function EffectService:CreateGridEffectWithEffectHolder(effectID, girdPos, monsterEntity)
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        Log.fatal("EffectService CreateGridEffectWithBindPos failed EffectID:", effectID, " ", Log.traceback())
        return nil
    end

    if effectConfigItem.ResPath == nil then
        Log.fatal("cannot find effect res ,effectID is", effectID)
    end

    --Log.fatal("创建特效:"..effectID)
    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath))
    effectEntity:SetPosition(girdPos)
    --effectEntity:AddEffectController(
    --            monsterEntity,
    --            effectConfigItem.BindPos,
    --            effectConfigItem.Duration,
    --            effectConfigItem.Type
    --    )
    --
    --local effCtrl = effectEntity:EffectController()
    --if effectConfigItem.FollowMove ~= nil then
    --    effCtrl:SetFollowMove(effectConfigItem.FollowMove)
    --end
    --if effectConfigItem.FollowRotate ~= nil then
    --    effCtrl:SetFollowRotate(effectConfigItem.FollowRotate)
    --end
    --if effectConfigItem.BindLayer then
    --    effCtrl:SetBindLayer(effectConfigItem.BindLayer)
    --end
    --if effectConfigItem.FollowRotateCaster then
    --    effCtrl:SetFollowRotateCaster(effectConfigItem.FollowRotateCaster)
    --end
    ---@type EffectHolderComponent
    local effectHolder = monsterEntity:EffectHolder()
    if not effectHolder then
        monsterEntity:AddEffectHolder()
        effectHolder = monsterEntity:EffectHolder()
    end
    effectHolder:AttachEffectByEffectID(effectID, effectEntity:GetID())
    return effectEntity
end

---创建一个格子绑点特效 主要针对异形怪
---@param monsterEntity Entity
function EffectService:CreateGridEffectWithBindPos(effectID, girdPos, monsterEntity)
    if monsterEntity:HasMonsterID() and monsterEntity:BodyArea() then
        local monsterID = monsterEntity:MonsterID():GetMonsterID()
        local monsterGridPos = monsterEntity:GridLocation().Position
        ---@type MonsterConfigData
        local monsterConfigData = self._configService:GetMonsterConfigData()
        local ret =
            monsterConfigData:GetMonsterBindPos(monsterID, monsterGridPos, girdPos, monsterEntity:BodyArea():GetArea())
        if not ret then
            Log.fatal("### get monster bindpos failed. monsterID=", monsterID, ", effectID=", effectID)
            return
        end
        local effectConfigItem = Cfg.cfg_effect[effectID]
        if not effectConfigItem then
            Log.fatal("EffectService CreateGridEffectWithBindPos failed EffectID:", effectID, " ", Log.traceback())
            return nil
        end

        if effectConfigItem.ResPath == nil then
            Log.fatal("cannot find effect res ,effectID is", effectID)
        end

        --Log.fatal("创建特效:"..effectID)
        local effectEntity = self:CreateEffectEntity()
        effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath))
        if ret.bindPos then
            effectEntity:AddEffectController(
                monsterEntity,
                ret.BindPos,
                effectConfigItem.Duration,
                effectConfigItem.Type
            )
        else
            effectEntity:AddEffectController(
                monsterEntity,
                effectConfigItem.BindPos,
                effectConfigItem.Duration,
                effectConfigItem.Type
            )
        end
        if ret.useEffectConfig then
            ----@type EffectControllerComponent
            local effectControllerComponent = effectEntity:EffectController()
            ---@type BoardServiceRender
            local boardServiceRender = self._world:GetService("BoardRender")
            local gridRenderPos = boardServiceRender:GridPos2RenderPos(girdPos)
            --Log.fatal("GridPos:", tostring(girdPos))
            effectControllerComponent:SetGirdRenderPos(gridRenderPos)
        end
        local effCtrl = effectEntity:EffectController()
        if effectConfigItem.FollowMove ~= nil then
            effCtrl:SetFollowMove(effectConfigItem.FollowMove)
        end
        if effectConfigItem.FollowRotate ~= nil then
            effCtrl:SetFollowRotate(effectConfigItem.FollowRotate)
        end
        if effectConfigItem.BindLayer then
            effCtrl:SetBindLayer(effectConfigItem.BindLayer)
        end
        if effectConfigItem.FollowRotateCaster then
            effCtrl:SetFollowRotateCaster(effectConfigItem.FollowRotateCaster)
        end
        ---@type EffectHolderComponent
        local effectHolder = monsterEntity:EffectHolder()
        if not effectHolder then
            monsterEntity:AddEffectHolder()
            effectHolder = monsterEntity:EffectHolder()
        end
        effectHolder:AttachEffectByEffectID(effectID, effectEntity:GetID())
    end
end

--创建一个格子特效
---@param gridPos Vector2
function EffectService:CreateCommonGridEffect(effectID, gridPos, gridDir)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local renderPos = boardServiceRender:GridPos2RenderPos(gridPos)

    renderPos = Vector3(renderPos.x, renderPos.y, renderPos.z)

    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        return nil
    end

    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath))
    effectEntity:SetLocation(renderPos, gridDir)
    effectEntity:AddEffect(effectConfigItem.Duration)
    return effectEntity
end

---创建一个世界坐标的点
function EffectService:CreatePositionEffect(effectID, renderPos)
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        return nil
    end

    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath))
    effectEntity:SetPosition(renderPos)
    effectEntity:AddEffect(effectConfigItem.Duration)
    return effectEntity
end

---@param casterEntity Entity
---@param girdPos Vector2
---创建UI特效 第三个参数表示特效固定在一个格子坐标对应的渲染坐标上，镜头移动特效固定不动
function EffectService:CreateUIEffect(casterEntity, effectID, girdPos)
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        return nil
    end

    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath))
    effectEntity:AddEffect(effectConfigItem.Duration)
    effectEntity:EffectController():SetTargetGridPos(girdPos)
    effectEntity:EffectController():SetEffectType(tonumber(effectConfigItem.Type))
    local effectHolder = casterEntity:EffectHolder()
    if not effectHolder then
        casterEntity:AddEffectHolder()
        effectHolder = casterEntity:EffectHolder()
    end
    effectHolder:AttachEffectByEffectID(effectID, effectEntity:GetID())
    return effectEntity
end

--region 显隐EffectHolder特效
function EffectService:ShowEffect(idleEffectArray, isShow)
    if not idleEffectArray then
        return
    end
    for _, effectID in ipairs(idleEffectArray) do
        local effectEntity = self._world:GetEntityByID(effectID)
        if effectEntity then 
            ---@type ViewComponent
            local effectViewCmpt = effectEntity:View()
            if effectViewCmpt then
                effectEntity:SetViewVisible(isShow)
            end
        else
            Log.fatal("Show Effect Error,can not find effect entity!")
        end
    end
end
---@param targetEntity Entity
function EffectService:ShowIdleEffect(targetEntity, isShow)
    local cEffectHolder = targetEntity:EffectHolder()
    if cEffectHolder then
        self:ShowEffect(cEffectHolder:GetIdleEffect(), isShow)
    end
end

---@param targetEntity Entity
function EffectService:ShowPermanentEffect(targetEntity, isShow)
    local cEffectHolder = targetEntity:EffectHolder()
    if cEffectHolder then
        self:ShowEffect(cEffectHolder:GetPermanentEffect(), isShow)
    end
end

---星灵在连线移动中显示的特效
---@param petEntity Entity
function EffectService:ShowChainMoveEffect(petEntity, show)
    local petData = petEntity:MatchPet():GetMatchPet()
    --是否配置
    local chainMoveEffect = petData:GetChainMoveEffect()
    if not chainMoveEffect or table.count(chainMoveEffect) == 0 then
        return
    end

    local cEffectHolder = petEntity:EffectHolder()
    if not cEffectHolder then
        petEntity:AddEffectHolder()
        cEffectHolder = petEntity:EffectHolder()
    end

    --查看EffectHolder里是否存储
    local effectList = cEffectHolder:GetEffectList("ChainMove")
    if not effectList then
        local effEntity = self:CreateEffect(chainMoveEffect.EffectID, petEntity)
        if effEntity then
            local effEntityId = effEntity:GetID()
            cEffectHolder:AttachEffect("ChainMove", effEntityId)
            effectList = cEffectHolder:GetEffectList("ChainMove")
        end
    end

    --匹配动作延时
    local delay = 0
    if show then
        delay = chainMoveEffect.ShowDelay or 0
    else
        delay = chainMoveEffect.HideDelay or 0
    end

    if delay == 0 then
        self:ShowEffect(effectList, show)
    else
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                YIELD(TT, delay)
                self:ShowEffect(effectList, show)
            end
        )
    end
end

--endregion

function EffectService:DestroyWeakEffect(targetEntity)
    ---@type EffectHolderComponent
    local effectHolderCmpt = targetEntity:EffectHolder()
    if effectHolderCmpt == nil then
        return
    end

    local weakEffectArray = effectHolderCmpt:GetWeakEffect()
    for _, effectID in ipairs(weakEffectArray) do
        local effectEntity = self._world:GetEntityByID(effectID)
        if effectEntity ~= nil then
            self._world:DestroyEntity(effectEntity)
        end
        --Log.fatal("Destroy Entity")
    end
end
---删除特定Entity上所有的特效 2020-03-17 韩玉信修改
function EffectService:DestroyEffectIDEntityDicEffect(targetEntity)
    if not targetEntity then
        return
    end
    ---@type EffectHolderComponent
    local effectHolderCmpt = targetEntity:EffectHolder()
    if effectHolderCmpt == nil then
        return
    end
    local effDict = effectHolderCmpt:GetEffectIDEntityDic()
    for k, v in pairs(effDict) do
        self:_DestroyEffectArray(v)
    end

    effectHolderCmpt:ClearEffectIDEntityDic()
end

function EffectService:ClearEntityEffect(targetEntity)
    if not targetEntity then
        Log.error(self._className, " ClearEntityEffect: requires entity param. ")
        return
    end
    ---@type EffectHolderComponent
    local cFxHolder = targetEntity:EffectHolder()
    if cFxHolder == nil then
        Log.warn(self._className, " ClearEntityEffect: no EffectHolderComponent on provided entity. ")
        return
    end

    local tIdleFx = cFxHolder:GetIdleEffect()
    self:_DestroyEffectArray(tIdleFx)
    cFxHolder:ClearIdleEffectList()

    local tWeakFx = cFxHolder:GetWeakEffect()
    self:_DestroyEffectArray(tWeakFx)
    cFxHolder:ClearWeakEffectList()

    local tFxDict = cFxHolder:GetEffectIDEntityDic()
    for k, v in pairs(tFxDict) do
        self:_DestroyEffectArray(v)
    end
    cFxHolder:ClearEffectIDEntityDic()

    local dicFx = cFxHolder:GetDictEffectId()
    for _, t in pairs(dicFx) do
        self:_DestroyEffectArray(t)
    end
    cFxHolder:ClearDictEffectID()

    local tBindFx = cFxHolder:GetBindEffectIDArray()
    self:_DestroyEffectArray(tBindFx)
    cFxHolder:ClearBindEffectID()
end

---删除特定Entity上的特定特效 2020-03-17 韩玉信添加
---@param nEffectID table or number
function EffectService:DestroyEntityEffectByID(targetEntity, nEffectID)
    if not nEffectID or not targetEntity then
        return
    end
    ---@type EffectHolderComponent
    local effectHolderCmpt = targetEntity:EffectHolder()
    if effectHolderCmpt == nil then
        return
    end
    local effDict = effectHolderCmpt:GetEffectIDEntityDic()
    if nil == effDict then
        return
    end
    local listWorkID = {}
    if type(nEffectID) == "table" then
        listWorkID = nEffectID
    else
        listWorkID[1] = nEffectID
    end
    for _, nID in pairs(nEffectID) do
        local entityList = effDict[nID]
        if entityList then
            self:_DestroyEffectArray(entityList)
        end
    end
end
---删除特定特效 2020-03-17 韩玉信添加
---@param nEffectID table or number
function EffectService:DestroyEffectByID(nEffectID)
    local listWorkID = {}
    if type(nEffectID) == "table" then
        listWorkID = nEffectID
    else
        listWorkID[1] = nEffectID
    end
    return self:_DestroyEffectArray(listWorkID)
end

function EffectService:GetPetShowEffIdByEntity(elementType)
    return GameResourceConst.PetAppearEff[elementType]
end

function EffectService:GetMonsterShowEffIdByEntity(e, elementType, isBoss)
    if isBoss then
        return
    end

    local count = e:BodyArea():GetAreaCount()
    if count > 4 then
        return
    end
    if count >= 4 then
        return GameResourceConst.MonsterAppearEffMultiBodyArea[elementType]
    end
    return GameResourceConst.MonsterAppearEffSingleBodyArea[elementType]
end

---@param effectID number 特效ID
function EffectService:CreateScreenEffPointEffect(effectID)
    local effectConfigItem = Cfg.cfg_effect[effectID]
    if not effectConfigItem then
        return nil
    end
    local effectEntity = self:CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(effectConfigItem.ResPath))
    effectEntity:AddEffectType(effectConfigItem.Type, effectConfigItem.Duration)
    return effectEntity
end

function EffectService:GetEffectResPath(effectID)
    local cfgItem = Cfg.cfg_effect[effectID]
    if not cfgItem then
        return nil
    end

    return cfgItem.ResPath
end
function EffectService:CreateLineEffects(TT,effectID, holderEntity,holderBone, startEntitys,startBone,holderPosOff,startPosOff)
    --连线点 施法者身上的绑点
    local targetRoot = GameObjectHelper.FindChild(holderEntity:View().ViewWrapper.GameObject.transform, holderBone)
    if not targetRoot then
        return
    end

    for i, entity in ipairs(startEntitys) do
        ---@type EffectLineRendererComponent
        local effectLineRenderer = entity:EffectLineRenderer()
        --没有初始化EffectLineRenderer组件的
        if entity:IsViewVisible() then
            local entityViewRoot = entity:View().ViewWrapper.GameObject.transform
            local curRoot = GameObjectHelper.FindChild(entityViewRoot, startBone)
            --找的到目标点菜添加组件
            if curRoot then
                --添加EffectLineRenderer组件
                if not effectLineRenderer then
                    entity:AddEffectLineRenderer()
                    effectLineRenderer = entity:EffectLineRenderer()
                end
                ---@type EffectHolderComponent
                local effectHolderCmpt = entity:EffectHolder()
                if not effectHolderCmpt then
                    entity:AddEffectHolder()
                    effectHolderCmpt = entity:EffectHolder()
                end

                local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[effectID]
                local effect
                if effectEntityIdList then
                    effect = self._world:GetEntityByID(effectEntityIdList[1])
                end
                if not effect then
                    --需要创建连线特效
                    effect = self:CreateEffect(effectID, entity)
                    effectHolderCmpt:AttachPermanentEffect(effect:GetID())
                end

                --等待一帧才有View()
                --YIELD(TT)
                local effView = effect:View()
                if effView then
                    --获取特效GetGameObject上面的LineRenderer组件
                    local go = effect:View():GetGameObject()
                    local renderers
                    renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)
                    for i = 0, renderers.Length - 1 do
                        local line = renderers[i]
                        if line then
                            line.gameObject:SetActive(true)
                        end
                    end

                    effectLineRenderer:InitEffectLineRenderer(
                        holderEntity:GetID(),
                        curRoot,
                        targetRoot,
                        entityViewRoot,
                        renderers,
                        effect:GetID()
                    )
                    effectLineRenderer:SetEffectLineRendererShow(holderEntity:GetID(), true)
                    if startPosOff then
                        effectLineRenderer:SetCurrentRootOff(startPosOff)
                    end
                    if holderPosOff then
                        effectLineRenderer:SetTargetRootOff(holderPosOff)
                    end
                end
            end
        end
    end
end