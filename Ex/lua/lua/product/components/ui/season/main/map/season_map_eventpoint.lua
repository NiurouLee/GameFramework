---@class SeasonMapEventPoint:Object
_class("SeasonMapEventPoint", Object)
SeasonMapEventPoint = SeasonMapEventPoint

function SeasonMapEventPoint:Constructor(owner, cfgMission, cfgEventPoint)
    self._owner = owner --该事件点属于某个区还是日常关
    ---@type cfg_season_mission
    self._cfgMission = cfgMission
    self._groupID = self._cfgMission.GroupID
    ---@type UISeasonLevelDiff
    self._diff = self._cfgMission.OrderID
    self._cfgEventPoint = cfgEventPoint
    self._id = self._cfgEventPoint.ID
    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    ---@type UISeasonModule
    self._uiSeasonModule = GameGlobal.GetUIModule(SeasonModule)
    self._seasonManger = self._uiSeasonModule:SeasonManager()
    ---@type SeasonMissionComponentInfo
    self._componentInfo = self._seasonModule:GetCurSeasonObj():GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
    ---@type cfg_season_map_eventpoint
    self._modelRes = self._cfgEventPoint.ModelRes
    self._interactionRange = self._cfgEventPoint.InteractionRange
    ---@type SeasonEventPointType
    self._eventPointType = self._cfgEventPoint.EventPointType
    self._dailyPRID = 1 --日常关当前坐标池的ID
    local position, rotation = self:_GetInitPR()
    self._position = position
    self._rotation = rotation
    ---@type table<SeasonEventPointProgress, SeasonMapCondition>
    self._conditions = {}
    ---@type SeasonEventPointProgress
    self._progress = SeasonEventPointProgress.SEPP_NotStart
    ---@type table<SeasonEventPointProgress, SeasonMapExpress>
    self._progressExpress = {} --每个阶段对应的表现
    self._animationEffect = {} --每个阶段常驻动画和特效
    self._assetReq = nil
    self._isLevel = false
    self._isUnLock = false
    self._show = false                 --资源加载完成之后是否显示
    self._expressShow = false          --当前表现中包含显示
    self._obstacleOpen = true
    ---@type SeasonMapExpress
    self._curProgressExpress = nil     --当前阶段的表现
    self._isLastMainLevelGroup = false --最靠后的已解锁可完成但未首通的主线战斗关卡组
    self:_CreateConditions()
    self:_CreateExpresses()
    self:_AnimationEffect()
    self:_CheckUnLock()
    self:_CalcCurProgressExpress()
    self:_CalcFirstModel()
    self:_CalcLastMainLevelGroup()
end

function SeasonMapEventPoint:_CalcFirstModel()
    if not self._modelRes then
        return
    end
    self._curModelRes = self._modelRes[self._progress]
    if self._curModelRes then
        return
    end
    for key, value in pairs(SeasonEventPointProgress) do
        self._curModelRes = self._modelRes[value]
        if self._curModelRes then
            return
        end
    end
end

function SeasonMapEventPoint:GetID()
    return self._id
end

--难度条件满足
---@return boolean
function SeasonMapEventPoint:DiffAble()
    if self._diff and self._diff > 0 then
        return self._diff == self._uiSeasonModule:GetCurrentSeasonLevelDiff()
    end
    return true
end

--有为空的情况。例如宝箱，机关这些是没有难度选项的
---@type UISeasonLevelDiff
function SeasonMapEventPoint:Diff()
    return self._diff
end

function SeasonMapEventPoint:GetResName()
    return self._curModelRes
end

function SeasonMapEventPoint:InteractionRange()
    return self._interactionRange
end

---@return SeasonEventPointType
function SeasonMapEventPoint:EventPointType()
    return self._eventPointType
end

function SeasonMapEventPoint:PRID()
    return self._dailyPRID
end

function SeasonMapEventPoint:Position()
    return self._position
end

function SeasonMapEventPoint:ObstacleRadius()
    if self._navMeshObstacle then
        return self._navMeshObstacle.radius
    end
    return 0
end

function SeasonMapEventPoint:ObstaclePosition()
    if self._obstacle then
        return self._obstacle.transform.position
    end
    return self._position
end

function SeasonMapEventPoint:GroupID()
    return self._groupID
end

function SeasonMapEventPoint:EventMapIcon()
    return self._cfgEventPoint.MapEventIcon
end

function SeasonMapEventPoint:IsUnLock()
    return self._isUnLock
end

function SeasonMapEventPoint:Dispose()
    if self._assetReq then
        self._assetReq:Dispose()
        self._assetReq = nil
    end
    if self._shadowResRequestShadow then
        self._shadowResRequestShadow:Dispose()
        self._shadowResRequestShadow = nil
    end
    if self._effectReq then
        self._effectReq:Dispose()
        self._effectReq = nil
    end
    for progress, express in pairs(self._progressExpress) do
        express:Dispose()
    end
    table.clear(self._progressExpress)
    table.clear(self._conditions)
    table.clear(self._animationEffect)
    UnityEngine.Object.Destroy(self._gameObject)
    if self._obstacle then
        UnityEngine.Object.Destroy(self._obstacle)
    end
    self._materialPropertyBlock = nil
    self._renderers = nil
end

--有模型的异步加载模型然后显示
---@param req SeasonMapEventPointRequestAsync
function SeasonMapEventPoint:OnShow(req)
    ---@type SeasonMapEventPointRequestAsync
    self._assetReq = req
    self:_OnLoadFinish(req:GameObject())
    self:_TryResumeExpress()
    self:_PlayCurProgressExpress()
end

---@param gameObject UnityEngine.GameObject
function SeasonMapEventPoint:_OnLoadFinish(gameObject)
    ---@type UnityEngine.GameObject
    self._gameObject = gameObject
    self._gameObject.layer = SeasonLayerMask.Stage
    self._gameObject.name = tostring(self._id)
    ---@type UnityEngine.Transform
    self._transform = self._gameObject.transform
    self._transform:SetParent(self._seasonManger:SeasonSceneManager():GetEventPointRootTransform())
    if self:_NeedShadow() then
        self._rootTransform = self._transform:Find("Root")
        self:_AddShadow()
        ---@type UnityEngine.Animation
        self._animation = self._rootTransform.gameObject:GetComponent(typeof(UnityEngine.Animation))
    else
        self._animation = self._gameObject:GetComponent(typeof(UnityEngine.Animation))
    end
    self._transform.position = Vector3(self._position.x, self._position.y, self._position.z)
    self._transform.rotation = self._rotation
    self._transform.localScale = Vector3(self._cfgEventPoint.Scale, self._cfgEventPoint.Scale, self._cfgEventPoint.Scale)
    ---@type UnityEngine.GameObject
    self._obstacle = GameObjectHelper.CreateEmpty(self._gameObject.name .. "_Obstacle", self._transform.parent) --Agent
    self._obstacle.layer = SeasonLayerMask.Stage
    ---@type UnityEngine.AI.NavMeshObstacle
    self._navMeshObstacle = self._obstacle:AddComponent(typeof(UnityEngine.AI.NavMeshObstacle))
    self._navMeshObstacle.shape = UnityEngine.AI.NavMeshObstacleShape.Capsule
    self._navMeshObstacle.radius = self._cfgEventPoint.ObstacleRadius
    self._navMeshObstacle.carving = true
    self._navMeshObstacle.enabled = true
    self._obstacle.transform.position = self._position
    ---@type UnityEngine.CapsuleCollider
    self._capsuleCollider = self._gameObject:AddComponent(typeof(UnityEngine.CapsuleCollider))
    self._capsuleCollider.center = Vector3(0, 0.5, 0)
    self._capsuleCollider.radius = self._interactionRange
    self:_Show(self._expressShow and self:DiffAble())
end

function SeasonMapEventPoint:_PlayCurProgressExpress()
    if self._curProgressExpress and self._curProgressExpress:TriggerType() == SeasonExpressTriggerType.Passive then
        self:PlayNextExpress()
    end
end

function SeasonMapEventPoint:_NeedShadow()
    local shadow = self._cfgEventPoint.Shadow[self._progress]
    if shadow ~= nil then
        return shadow
    end
    return false
end

---没有模型的创建一个虚拟点
function SeasonMapEventPoint:CreateVirtualPoint()
    ---@type UnityEngine.GameObject
    self._gameObject = GameObjectHelper.CreateEmpty(tostring(self._id), self._seasonManger:SeasonSceneManager():GetEventPointRootTransform())
    self._gameObject.layer = SeasonLayerMask.Stage
    ---@type UnityEngine.Transform
    self._transform = self._gameObject.transform
    self._transform.position = Vector3(self._position.x, 1, self._position.z)
    self:_Show(self._expressShow and self:DiffAble())
    self:_TryResumeExpress()
end

---计算事件点初始进度
function SeasonMapEventPoint:_CalcCurProgressExpress()
    if not self._isUnLock then
        self:ExpressShow(false)
        return
    end
    local map = self._componentInfo.m_stage_info
    if map and map[self._id] then
        self._progress = map[self._id] --取历史记录
    end
    --检测有没有满足新的进度
    for progress, _condition in pairs(self._conditions) do
        if _condition then
            if _condition:OnCheck(map) then
                if progress > self._progress then
                    self._progress = progress
                end
            end
        end
    end
    self._curProgressExpress = self._progressExpress[self._progress]
    if self._curProgressExpress then
        local result, content = self._curProgressExpress:ContainExpress(SeasonExpressType.Show)
        if result and content ~= nil then
            self._expressShow = content
        end
    end
    self:ExpressShow(self._expressShow)
end

---@return SeasonMapExpress
function SeasonMapEventPoint:CurProgressExpress()
    return self._curProgressExpress
end

function SeasonMapEventPoint:ExpressShow(expressShow)
    self._expressShow = expressShow
    self:_Show(self._expressShow and self:DiffAble())
end

function SeasonMapEventPoint:_Show(show)
    self._show = show
    if self._gameObject then
        self._gameObject:SetActive(show)
    end
    if self._obstacle then
        self._obstacle:SetActive(show and self._obstacleOpen)
    end
    if self._show then
        self:_SetAnimationEffect()
    end
end

function SeasonMapEventPoint:IsShow()
    return self._show
end

function SeasonMapEventPoint:OpenObstacle(open)
    self._obstacleOpen = open
    if self._obstacle then
        self._obstacle:SetActive(self._obstacleOpen)
    end
end

function SeasonMapEventPoint:_AddShadow()
    self._shadowResRequestShadow = ResourceManager:GetInstance():SyncLoadAsset("SCShadowPlane.prefab",
        LoadType.GameObject)
    if not self._shadowResRequestShadow then
        Log.error("SeasonEventPoint add shadow fail. SCShadowPlane.prefab load fail.")
        return
    end
    ---@type UnityEngine.GameObject
    local shadowGO = self._shadowResRequestShadow.Obj
    ---@type UnityEngine.Transform
    self._shadowPlane = shadowGO.transform
    self._shadowPlane.parent = self._rootTransform
    if APPVER_EXPLORE then
        ---@type PlaneShadowComponent
        local planeShadowComponent = self._rootTransform.gameObject:AddComponent(typeof(PlaneShadowComponent));
        planeShadowComponent.shadowPlane = self._shadowPlane;
        planeShadowComponent.maxDistanceToMainCamera = 50;
    end
    SeasonTool:GetInstance():DisenableMeshRender(shadowGO)
    ---@type UnityEngine.MaterialPropertyBlock
    self._materialPropertyBlock = UnityEngine.MaterialPropertyBlock:New()
    ---@type UnityEngine.Renderer[]
    self._renderers = self._rootTransform.gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
    SeasonTool:GetInstance():SetMaterialProperty(self._shadowPlane, self._renderers, self._materialPropertyBlock)
    shadowGO:SetActive(true)
end

function SeasonMapEventPoint:_UpdateMaterialProperty()
    if not APPVER_EXPLORE then
        if self._shadowPlane and self._renderers and self._materialPropertyBlock then
            SeasonTool:GetInstance():SetMaterialProperty(self._shadowPlane, self._renderers, self._materialPropertyBlock)
        end
    end
end

---设置当前进度的常驻动画和特效
function SeasonMapEventPoint:_SetAnimationEffect()
    if not self._transform then
        return
    end
    if self._effectReq then
        self._effectReq:Dispose()
        self._effectReq = nil
    end
    local animationEffect = self._animationEffect[self._progress]
    if animationEffect then
        local anim = animationEffect.anim
        local holder = animationEffect.holder
        local effect = animationEffect.effect
        self:PlayAnimation(anim)
        if effect then
            self._effectReq = ResourceManager:GetInstance():SyncLoadAsset(effect, LoadType.GameObject)
            if self._effectReq then
                local bone = self:GetBoneNode(holder)
                local effectGO = self._effectReq.Obj
                effectGO:SetActive(true)
                effectGO.transform:SetParent(bone)
                effectGO.transform.localPosition = Vector3.zero
                effectGO.transform.localRotation = Quaternion.Euler(0, 0, 0)
            end
        end
    end
end

function SeasonMapEventPoint:_SetAnimation()
    local animationEffect = self._animationEffect[self._progress]
    if animationEffect then
        self:PlayAnimation(animationEffect.anim)
    end
end

---@return SeasonEventPointProgress
function SeasonMapEventPoint:Progress()
    return self._progress
end

---创建该事件点所有进度的条件
function SeasonMapEventPoint:_CreateConditions()
    self:_CreatePerCondition(SeasonEventPointProgress.SEPP_Show, self._cfgMission.Condition1)
    self:_CreatePerCondition(SeasonEventPointProgress.SEPP_Interaction, self._cfgMission.Condition2)
    self:_CreatePerCondition(SeasonEventPointProgress.SEPP_Finish, self._cfgMission.Condition3)
end

---@param progress SeasonEventPointProgress
function SeasonMapEventPoint:_CreatePerCondition(progress, conditionStr)
    self._conditions[progress] = SeasonMapCondition:New(conditionStr)
end

---创建该事件点所有进度的表现
function SeasonMapEventPoint:_CreateExpresses()
    self:_CreatePerExpress(SeasonEventPointProgress.SEPP_Show, self._cfgEventPoint.Express1TriggerType,
        self._cfgEventPoint.Express1)
    self:_CreatePerExpress(SeasonEventPointProgress.SEPP_Interaction, self._cfgEventPoint.Express2TriggerType,
        self._cfgEventPoint.Express2)
    self:_CreatePerExpress(SeasonEventPointProgress.SEPP_Finish, self._cfgEventPoint.Express3TriggerType,
        self._cfgEventPoint.Express3)
end

---@param progress SeasonEventPointProgress
---@param triggerType SeasonExpressTriggerType
function SeasonMapEventPoint:_CreatePerExpress(progress, triggerType, expressArr)
    if triggerType and expressArr then
        if not self._progressExpress[progress] then
            local express = SeasonMapExpress:New(self, triggerType, expressArr)
            self._isLevel = express:IsLevel()
            self._progressExpress[progress] = express
        end
    end
end

function SeasonMapEventPoint:_AnimationEffect()
    self._animationEffect[SeasonEventPointProgress.SEPP_Show] = self._cfgEventPoint.AnimationEffect1
    self._animationEffect[SeasonEventPointProgress.SEPP_Interaction] = self._cfgEventPoint.AnimationEffect2
    self._animationEffect[SeasonEventPointProgress.SEPP_Finish] = self._cfgEventPoint.AnimationEffect3
end

function SeasonMapEventPoint:GetCurExpressIndex()
    if self._progressExpress[self._progress] then
        return self._progressExpress[self._progress]:CurExpressIndex()
    end
    return nil
end

---播放该事件点当前进度下的表现,从头开始播放
---@param progress SeasonEventPointProgress
---@param triggerType SeasonExpressTriggerType
function SeasonMapEventPoint:PlayExpress(progress, triggerType, param)
    self._progress = progress
    local nextProgressExpress = self._progressExpress[self._progress]
    if self._curProgressExpress ~= nextProgressExpress then
        self._curProgressExpress = nextProgressExpress
        self:_CheckUnLock()
        self:_CalcLastMainLevelGroup()
    end
    if self._curProgressExpress then
        if self._curProgressExpress:TriggerType() == triggerType then
            self:_StopAudio(true)
            self._curProgressExpress:Reset()
            self:PlayNextExpress(param)
        else
            if self._curProgressExpress:TriggerType() == SeasonExpressTriggerType.Active then --至少显示模型
                local result, content = self._curProgressExpress:ContainExpress(SeasonExpressType.Show)
                if result and content ~= nil then
                    self:ExpressShow(content)
                end
            end
        end
    end
end

function SeasonMapEventPoint:_StopAudio(stop)
    local seasonAudio = self._seasonManger:SeasonAudioManager():GetSeasonAudio()
    if seasonAudio then
        seasonAudio:PlayVoice(stop)
    end
end

--播放该事件点当前进度下的表现,顺序播放下一个
function SeasonMapEventPoint:PlayNextExpress(param)
    if self._curProgressExpress then
        local isEnd = self._curProgressExpress:PlayNext(param)
        if isEnd then
            self:SyncProgress(self._progress)
            self:_StopAudio(false)
            self:_RandomNextPR()
            self._curProgressExpress:Reset()
            --如果表现中包含锁定输入的，播放完所有表现之后强制解锁输入一次
            local result, content = self._curProgressExpress:ContainExpress(SeasonExpressType.LockInput)
            if result then
                self._uiSeasonModule:SeasonManager():ClearLocks()
            end
        end
    end
end

--同步事件点状态
function SeasonMapEventPoint:SyncProgress(progress)
    local map = self._componentInfo.m_stage_info
    if map and map[self._id] and map[self._id] == progress then
        return
    end
    Log.debug("SeasonMapEventPoint play all expresses end.", self._id, progress)
    GameGlobal.UIStateManager():Lock("SeasonMapEventPointPlayEnd")
    TaskManager:GetInstance():StartTask(
        function(TT)
            local res = self._seasonModule:HandleSeasonClientStageData(TT, self._id, progress)
            if res:GetSucc() then
                self:_OnSyncSuccess()
                self:_TrySyncProgressNormal(progress)
            else
                Log.error("SeasonMapEventPoint sync progress fail!", self._id, progress)
            end
            GameGlobal.UIStateManager():UnLock("SeasonMapEventPointPlayEnd")
        end,
        self
    )
end

--如果是关卡类型的，高难关同步进度的时候强制把对应的普通关进度同步到和困难关一致
function SeasonMapEventPoint:_TrySyncProgressNormal(progress)
    if self:IsLevel() and self._diff == UISeasonLevelDiff.Hard then
        local normalCfg = Cfg.cfg_season_mission { GroupID = self._groupID, OrderID = UISeasonLevelDiff.Normal }
        if normalCfg then
            local normalEventPoint = self._uiSeasonModule:SeasonManager():SeasonMapManager():GetEventPoint(normalCfg[1]
                .ID)
            if normalEventPoint and normalEventPoint:Progress() <= progress then
                normalEventPoint:SyncProgress(progress)
                return
            end
        end
    end
end

function SeasonMapEventPoint:_OnSyncSuccess()
    ---@type SeasonMapManager
    local seasonMapManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager():SeasonMapManager()
    seasonMapManager:OnEventPointProgressChange(self._id)
    self:_CheckModelChange()
end

function SeasonMapEventPoint:Update(deltaTime)
    if self._curProgressExpress then
        self._curProgressExpress:Update(deltaTime)
    end
    self:_UpdateMaterialProperty(deltaTime)
end

--关卡事件点
function SeasonMapEventPoint:IsLevel()
    return self._isLevel
end

---@return UnityEngine.AnimationState
function SeasonMapEventPoint:PlayAnimation(name)
    if not self._animation or not name then
        return
    end
    ---@type UnityEngine.AnimationState
    local animationState = self._animation:get_Item(name)
    if animationState then
        self._animation:Play(animationState.name)
    end
    return animationState
end

---@param name string
---@return UnityEngine.Transform
function SeasonMapEventPoint:GetBoneNode(name)
    if not name then
        return self._transform
    else
        local boneTransform = GameObjectHelper.FindChild(self._transform, name)
        if boneTransform then
            return boneTransform
        end
        return self._transform
    end
end

--当某个事件点的进度发生变化的时候，检测自己的进度有没有发生变化
---@return boolean, SeasonEventPointProgress
function SeasonMapEventPoint:CheckCondition(map)
    local result = false
    local curProgress = self._progress
    for progress, _condition in pairs(self._conditions) do
        if _condition:OnCheck(map) then
            if progress > curProgress then --新的进度
                result = true
                curProgress = progress
            end
        end
    end
    return result, curProgress
end

function SeasonMapEventPoint:CheckInteractionDistance(position)
    return Vector3.Distance(position, self._transform.position) <= self:InteractionRange()
end

function SeasonMapEventPoint:GetMissionCfg()
    return self._cfgMission
end

function SeasonMapEventPoint:GetEventPointCfg()
    return self._cfgEventPoint
end

---尝试恢复之前的表现。例如进入关卡退局出来之后
function SeasonMapEventPoint:_TryResumeExpress()
    local mgr = self._uiSeasonModule:SeasonManager():SeasonMapManager()
    local param = mgr:GetParams()
    ---@type SeasonMissionCreateInfo
    local missionCreateInfo = param[1]
    local isWin = param[2]
    if missionCreateInfo and isWin then
        local info = self._seasonModule:GetLevelExpress()
        if info then
            if info.eventPointID == self._id and self._curProgressExpress then
                local result, content, index = self._curProgressExpress:ContainExpress(info.expressType)
                if result then
                    Log.info("SeasonMapEventPoint TryResumeExpress, ", self._id, index)
                    self._curProgressExpress:ResumePlay(index, isWin)
                end
                self._seasonModule:ClearLevelExpress()
            end
        end
    end
end

--中断当前表现
function SeasonMapEventPoint:InterruptExpress()
    if self._curProgressExpress then
        self._curProgressExpress:Reset()
    end
end

---检测事件点有没有解锁
function SeasonMapEventPoint:_CheckUnLock()
    self._isUnLock = self._owner:IsUnLock()
    if not self._isUnLock then
        return
    end
    if not self._curProgressExpress then
        return
    end
    if self:EventPointType() == SeasonEventPointType.MainLevel or self:EventPointType() == SeasonEventPointType.SubLevel then
        self._isUnLock = self._curProgressExpress:ContainExpress(SeasonExpressType.Level)
    elseif self:EventPointType() == SeasonEventPointType.MainStory or self:EventPointType() == SeasonEventPointType.SubStory then
        self._isUnLock = self._curProgressExpress:ContainExpress(SeasonExpressType.Story)
    elseif self:EventPointType() == SeasonEventPointType.Box then
        self._isUnLock = self._curProgressExpress:ContainExpress(SeasonExpressType.Reward)
    end
end

function SeasonMapEventPoint:_CheckModelChange()
    if not self._modelRes then
        return
    end
    local modelRes = self._modelRes[self._progress]
    if modelRes and self._curModelRes ~= modelRes then
        self._curModelRes = modelRes
        self:ReloadModel()
    end
end

function SeasonMapEventPoint:ReloadModel()
    if self._assetReq then
        self._assetReq:Dispose()
        self._assetReq = nil
    end
    if self._shadowResRequestShadow then
        self._shadowResRequestShadow:Dispose()
        self._shadowResRequestShadow = nil
    end
    if self._effectReq then
        self._effectReq:Dispose()
        self._effectReq = nil
    end
    if self._gameObject then
        UnityEngine.Object.Destroy(self._gameObject)
    end
    if self._obstacle then
        UnityEngine.Object.Destroy(self._obstacle)
    end
    self._assetReq = ResourceManager:GetInstance():SyncLoadAsset(self._curModelRes, LoadType.GameObject)
    if not self._assetReq or self._assetReq.Obj then
        Log.error("SeasonPlayer load player modle res fail.", self._curModelRes)
        return
    end
    self._materialPropertyBlock = nil
    self._renderers = nil
    self:_OnLoadFinish(self._assetReq.Obj)
end

---@param diff UISeasonLevelDiff
function SeasonMapEventPoint:SwitchDiff(diff)
    if self._isUnLock then
        self:_Show(self._expressShow and self:DiffAble())
        self:_SetAnimation()
        self:_CalcLastMainLevelGroup()
    end
end

function SeasonMapEventPoint:IsLastMainLevelGroup()
    return self._isLastMainLevelGroup
end

function SeasonMapEventPoint:_CalcLastMainLevelGroup()
    if self._eventPointType == SeasonEventPointType.MainLevel then
        local map = self._componentInfo.m_stage_info
        local groups = {}
        local isLastGroup = true
        local cfgs = Cfg.cfg_season_mission {}
        for key, cfg in pairs(cfgs) do
            if cfg.GroupID > 0 then
                if not groups[cfg.GroupID] then
                    groups[cfg.GroupID] = {}
                end
                table.insert(groups[cfg.GroupID], cfg.ID)
            end
        end
        local lastGroupID = self._groupID
        for groupID, t in pairs(groups) do
            local groupPass = false
            for _, id in pairs(t) do
                if map[id] then
                    groupPass = true
                    break
                end
            end
            if groupPass then
                if groupID >= lastGroupID then
                    isLastGroup = false
                    break
                end
            end
        end
        if isLastGroup then
            local canChallenge = false
            if self._isUnLock and self:DiffAble() then
                if self._curProgressExpress then
                    canChallenge = self._curProgressExpress:ContainExpress(SeasonExpressType.Level)
                end
            end
            isLastGroup = canChallenge
        end
        self._isLastMainLevelGroup = isLastGroup
    end
end

---自动移动到该事件点
function SeasonMapEventPoint:AutoMoveToMe(callBack)
    local player = self._uiSeasonModule:SeasonManager():SeasonPlayerManager():GetPlayer()
    local clickPosition = Vector3(self:ObstaclePosition().x, player:Position().y, self:ObstaclePosition().z)
    local direction = player:Position() - clickPosition
    direction = direction.normalized * self:ObstacleRadius() * 2
    local targetPosition = clickPosition + direction
    local result, navMeshHit = UnityEngine.AI.NavMesh.Raycast(targetPosition, clickPosition, nil,
        UnityEngine.AI.NavMesh.AllAreas)
    if result then
        player:SetDestination(navMeshHit.position, false, callBack)
    else
        player:SetDestination(clickPosition, false, callBack)
    end
end

function SeasonMapEventPoint:GuideMove(callback)
    GameGlobal.UIStateManager():Lock("SeasonMapEventPoint:GuideMove")
    self._uiSeasonModule:SeasonManager():Lock("guide")
    self:AutoMoveToMe(function()
        self._uiSeasonModule:SeasonManager():UnLock("guide")
        if callback then
            callback()
        end
        GameGlobal.UIStateManager():UnLock("SeasonMapEventPoint:GuideMove")
    end)
end

function SeasonMapEventPoint:IsPlaying()
    if self._curProgressExpress then
        return self._curProgressExpress:IsPlaying(), self._id
    end
    return false
end

---获取初始坐标
function SeasonMapEventPoint:_GetInitPR()
    if self._eventPointType == SeasonEventPointType.DailyLevel then
        if self._componentInfo.m_daily_info then
            if self._componentInfo.m_daily_info.m_save_info then
                local serverPR = self._componentInfo.m_daily_info.m_save_info[self._id]
                if serverPR then
                    self._dailyPRID = serverPR
                else
                    if self._cfgEventPoint.PRP then
                        self:RandomPR(self._cfgEventPoint.PRP)
                    end
                end
                local cfg = Cfg.cfg_season_map_eventpoint_pr[self._dailyPRID]
                if cfg then
                    local position = Vector3(cfg.Position[1], cfg.Position[2], cfg.Position[3])
                    local rotation = Quaternion.Euler(cfg.Rotation[1], cfg.Rotation[2], cfg.Rotation[3])
                    return position, rotation
                else
                    Log.error("SeasonMapEventPoint:_GetInitPR error.", self._dailyPRID)
                end
            end
        end
    else
        local position = Vector3(self._cfgEventPoint.Position[1], self._cfgEventPoint.Position[2], self._cfgEventPoint.Position[3])
        local rotation = Quaternion.Euler(self._cfgEventPoint.Rotation[1], self._cfgEventPoint.Rotation[2], self._cfgEventPoint.Rotation[3])
        return position, rotation
    end
end

function SeasonMapEventPoint:_RandomNextPR()
    if self._eventPointType == SeasonEventPointType.DailyLevel then
        ---@type SeasonMapDaily
        local seasonMapDaily = self._owner
        local cfg = Cfg.cfg_season_map_eventpoint_pr[self._dailyPRID]
        if cfg and cfg.Next then
            self:RandomPR(cfg.Next)
            seasonMapDaily:TrySyncPRIDs(function ()
                self:ResetPR()
                Log.debug("SeasonMapEventPoint RandomNextPR Success.")
            end)
        end
    end
end

--日常关随机坐标
function SeasonMapEventPoint:RandomPR(pool)
    if pool and #pool > 0 then
        ---@type SeasonMapDaily
        local mapDaily = self._owner
        local ids = mapDaily:GetAllPRIDs()
        local randomPRIDs = {}
        for _, id in pairs(pool) do
            if not table.icontains(ids, id) then
                table.insert(randomPRIDs, id)
            end
        end
        local count = #randomPRIDs
        if count > 0 then
            self._dailyPRID = randomPRIDs[math.random(1, count)]
        else
            Log.error("SeasonMapEventPoint:_RandomPR error.", self._dailyPRID)
        end
    end
end

function SeasonMapEventPoint:ResetPR()
    if self._eventPointType == SeasonEventPointType.DailyLevel then
        local cfg = Cfg.cfg_season_map_eventpoint_pr[self._dailyPRID]
        if cfg then
            self._position = Vector3(cfg.Position[1], cfg.Position[2], cfg.Position[3])
            self._rotation = Quaternion.Euler(cfg.Rotation[1], cfg.Rotation[2], cfg.Rotation[3])
            self._transform.position = self._position
            self._transform.rotation = self._rotation
            self._obstacle.transform.position = self._position
            self._uiSeasonModule:SeasonManager():SeasonUIManager():Refresh()
            Log.debug("SeasonMapEventPoint ResetPR.")
        end
    end
end