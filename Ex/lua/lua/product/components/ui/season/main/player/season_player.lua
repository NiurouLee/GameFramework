---@class SeasonPlayer:Object
_class("SeasonPlayer", Object)
SeasonPlayer = SeasonPlayer

function SeasonPlayer:Constructor()
    ---@type SeasonModule
    self._module = GameGlobal.GetModule(SeasonModule)
    self._cfg = Cfg.cfg_season_map_player[self._module:GetCurSeasonID()]
    if not self._cfg then
        Log.fatal("SeasonPlayer not cfg!")
    end
    local curObj = self._module:GetCurSeasonObj()
    ---@type SeasonMissionComponentInfo
    local missionCptInfo = curObj:GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
    ---@type SeasonMissionClientInfo
    local posInfo = missionCptInfo.m_client_info
    local defaultPos
    if posInfo and posInfo.m_x ~= 0 and posInfo.m_z ~= 0 then
        defaultPos = Vector3(posInfo.m_x, self._cfg.Position[2], posInfo.m_z) --y坐标不同步 固定读配置
        Log.info("从服务器获取默认位置:", defaultPos)
    else
        defaultPos = Vector3(self._cfg.Position[1], self._cfg.Position[2], self._cfg.Position[3])
        Log.info("读配置获取默认位置:", defaultPos)
    end
    self._crossFadeTime = 0.2
    self._resName = self._cfg.PlayerRes
    self._resRequest = ResourceManager:GetInstance():SyncLoadAsset(self._resName, LoadType.GameObject)
    if not self._resRequest then
        Log.error("SeasonPlayer load player modle res fail.", self._resName)
    end
    ---@type UnityEngine.GameObject
    self._gameObject = self._resRequest.Obj
    ---@type UnityEngine.Transform
    self._transform = self._gameObject.transform
    ---@type UnityEngine.Transform
    self._rootTransform = self._transform:Find("Root")
    self:_AddShadow()
    self:_AddRootEffect()
    ---@type UnityEngine.Animation
    self._animation = self._gameObject:GetComponentInChildren(typeof(UnityEngine.Animation))
    ---@type UnityEngine.GameObject
    self._playerRoot = GameObjectHelper.CreateEmpty("SeasonPlayer", nil) --角色父节点
    ---@type UnityEngine.GameObject
    self._agent = GameObjectHelper.CreateEmpty("Agent", nil)             --Agent
    ---@type UnityEngine.Transform
    self._agentTransform = self._agent.transform
    self._agentTransform:SetParent(self._playerRoot.transform)
    self._transform:SetParent(self._playerRoot.transform)
    ---@type UnityEngine.AI.NavMeshAgent
    self._navMeshAgent = self._agent:AddComponent(typeof(UnityEngine.AI.NavMeshAgent))
    self._navMeshAgent.agentTypeID = HelperProxy:GetInstance():GetNavAgentID(AircraftNavAgent.Normal)
    self._navMeshAgent.angularSpeed = 0
    self._navMeshAgent.acceleration = 0
    self._navMeshAgent.speed = self._cfg.Speed
    self._navMeshAgent.stoppingDistance = 0.1
    self._navMeshAgent.autoBraking = false
    self._navMeshAgent.enabled = false
    self._navMeshAgent.areaMask = 1
    self._agentTransform.position = defaultPos
    self._transform.position = self._agentTransform.position
    self._transform.rotation = Quaternion.Euler(self._cfg.Rotation[1], self._cfg.Rotation[2], self._cfg.Rotation[3])
    self._transform.localScale = Vector3.one * self._cfg.Scale
    self:_AddLineRenderer()
    self._gameObject:SetActive(true)
    self._angle = self._agent.transform.eulerAngles.y
    ---@type SeasonManager
    self._seasonManger = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    ---@type SeasonSceneLayerBuilding
    self._buildingLayer = self._seasonManger:SeasonSceneManager():GetLayer(SeasonSceneLayer.Building)
    ---@type SeasonSceneLayerZoneFlag
    self._zoneFlagLayer = self._seasonManger:SeasonSceneManager():GetLayer(SeasonSceneLayer.ZoneFlag)
    ---@type SeasonSceneLayerMaterial
    self._mapMaterialLayer = self._seasonManger:SeasonSceneManager():GetLayer(SeasonSceneLayer.SoundMaterial)
    ---@type SeasonMapMaterial
    self._curMapMaterial = SeasonMapMaterial.Default
    self._syncPosTimer = 0
    self._syncPosDuration = 10 * 1000 --10秒一次
    ---@type SeasonZone
    self._curZone = SeasonZone.One
    self:_CheckPosition(0)
    self:_CheckBuildingCover()
    self:_UpdateMaterialProperty()
end

--添加阴影
function SeasonPlayer:_AddShadow()
    self._shadowReq = ResourceManager:GetInstance():SyncLoadAsset("SCShadowPlane.prefab", LoadType.GameObject)
    if not self._shadowReq then
        Log.error("SeasonPlayer add shadow fail. SCShadowPlane.prefab load fail.")
        return
    end
    ---@type UnityEngine.GameObject
    local shadowGO = self._shadowReq.Obj
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

function SeasonPlayer:_UpdateMaterialProperty()
    if not APPVER_EXPLORE then
        if self._shadowPlane and self._renderers and self._materialPropertyBlock then
            SeasonTool:GetInstance():SetMaterialProperty(self._shadowPlane, self._renderers, self._materialPropertyBlock)
        end
    end
end

function SeasonPlayer:_AddLineRenderer()
    self._lineRendererReq =
        ResourceManager:GetInstance():SyncLoadAsset('eff_scene_daohangxian.prefab', LoadType.GameObject)
    if not self._lineRendererReq then
        Log.error('SeasonPlayer load eff_scene_daohangxian.prefab fail.')
        return
    end
    ---@type UnityEngine.GameObject
    self._lineRendererGO = self._lineRendererReq.Obj
    self._lineRendererGO.transform:SetParent(self._playerRoot.transform)
    ---@type UnityEngine.LineRenderer
    self._lineRendererGO.transform.position = Vector3(0, 0, 0)
    self._lineRendererGO.transform.rotation = Vector3(0, 0, 0)
    self._lineRendererList = {}
    local lineRenderchildCount = self._lineRendererGO.transform.childCount
    if lineRenderchildCount > 0 then
        for i = 0, lineRenderchildCount - 1 do
            local lineRenderGO = self._lineRendererGO.transform:GetChild(i)
            if lineRenderGO ~= nil and lineRenderGO:GetComponent(typeof(UnityEngine.LineRenderer)) ~= nil then
                local lineRender = lineRenderGO:GetComponent(typeof(UnityEngine.LineRenderer))
                lineRender.transform.position = Vector3(0, 0, 0)
                lineRender.transform.rotation = Vector3(0, 0, 0)
                table.insert(self._lineRendererList, lineRender)
            end
        end
    end
    for _, lineRenderer in ipairs(self._lineRendererList) do
        lineRenderer.numCornerVertices = 0
    end
    self._lineRendererGO:SetActive(true)
end


function SeasonPlayer:_AddRootEffect()
    self._rootEffectReq = ResourceManager:GetInstance():SyncLoadAsset(self._cfg.FootEffect, LoadType.GameObject)
    if not self._rootEffectReq then
        Log.error("SeasonPlayer load rooteffect fail.")
        return
    end
    ---@type UnityEngine.GameObject
    self._rootEffectGO = self._rootEffectReq.Obj
    self._rootEffectGO.transform:SetParent(self._rootTransform)
    self._rootEffectGO:SetActive(true)
end

function SeasonPlayer:Dispose()
    self:_SyncPosition(true)
    if self._resRequest then
        self._resRequest:Dispose()
        self._resRequest = nil
    end
    if self._shadowReq then
        self._shadowReq:Dispose()
        self._shadowReq = nil
    end
    if self._lineRendererReq then
        self._lineRendererReq:Dispose()
        self._lineRendererReq = nil
    end
    if self._rootEffectReq then
        self._rootEffectReq:Dispose()
        self._rootEffectReq = nil
    end
    UnityEngine.Object.Destroy(self._playerRoot)
    UnityEngine.Object.Destroy(self._lineRendererGO)
    self._transform = nil
    self._agent = nil
    self._navMeshAgent = nil
    self._buildingLayer = nil
    self._materialPropertyBlock = nil
    self._renderers = nil
end

function SeasonPlayer:Update(deltaTime)
    if self._navMeshAgent and self._navMeshAgent.enabled then
        if Vector3.Distance(self._navMeshAgent.destination, self._agentTransform.position) <= self._navMeshAgent.stoppingDistance then
            self:Stop(true)
        else
            self:_CheckPosition(deltaTime)
            local length = self._navMeshAgent.path.corners.Length
            if length >= 2 then
                local nextPosition = Vector3(self._navMeshAgent.path.corners[1].x, self._agentTransform.position.y, self._navMeshAgent.path.corners[1].z)
                local direction = nextPosition - self._agentTransform.position
                self._agentTransform:Translate(direction.normalized * UnityEngine.Time.deltaTime * self._navMeshAgent.speed, UnityEngine.Space.World)
                local angle = Vector3.Angle(self._agentTransform.forward, direction)
                local cross = Vector3.Cross(self._agentTransform.forward, direction)
                if cross.y < 0 then
                    angle = -angle
                end
                self._agentTransform:Rotate(self._agentTransform.up, angle * UnityEngine.Time.deltaTime * 10, UnityEngine.Space.Self);
                self._transform:Rotate(self._agentTransform.up, angle * UnityEngine.Time.deltaTime * 10, UnityEngine.Space.Self)
            end
            self._transform.position = Vector3(self._agentTransform.position.x, self._transform.position.y,
                self._agentTransform.position.z)
        end
        self:_CheckBuildingCover(deltaTime)
        self:_UpdateLineRenderer()
        self:_CheckSyncPosition(deltaTime)
        self:_UpdateMaterialProperty(deltaTime)
    end
end

---@return UnityEngine.Transform
function SeasonPlayer:Transform()
    return self._agentTransform
end

function SeasonPlayer:Position()
    return self._agentTransform.position
end

---@return UnityEngine.Transform
function SeasonPlayer:RealTransform()
    return self._transform
end

--模型的真实坐标
---@return UnityEngine.Vector3
function SeasonPlayer:RealPosition()
    return self._transform.position
end

function SeasonPlayer:GetLastCorners()
    local length = self._navMeshAgent.path.corners.Length
    if length >= 1 then
        return self._navMeshAgent.path.corners[length - 1]
    end
    return nil
end

--玩家当前所在区
---@return SeasonZone
function SeasonPlayer:CurZone()
    return self._curZone
end

function SeasonPlayer:SetDestination(destination, play_move_click_sound, moveDoneCallback)
    self._moveTimer = 0
    self._isPlayMoveVoice = false
    self._moveDoneCallback = moveDoneCallback
    if Vector3.Distance(self._navMeshAgent.destination, self._transform.position) > self._navMeshAgent.stoppingDistance then
        self._navMeshAgent.enabled = true
        self._navMeshAgent:SetDestination(destination)
        self:PlayAnimation(SeasonPlayerAnimation.Move)
        if play_move_click_sound then
            self._seasonManger:SeasonAudioManager():GetSeasonAudio():PlaySound(SeasonCriAudio.Destination)--点击目的地测试音
        end
    end
end

function SeasonPlayer:IsMoveing()
    return self._navMeshAgent.enabled
end

---@return UnityEngine.AnimationState
function SeasonPlayer:PlayAnimation(name)
    if not self._animation or not name then
        return
    end
    ---@type UnityEngine.AnimationState
    local animationState = self._animation:get_Item(name)
    if animationState then
        self._animation:CrossFade(animationState.name, self._crossFadeTime)
    else
        Log.error("SeasonPlayer PlayAnimation error. not exist animation", name)
    end
    return animationState
end

--角色遮挡检测
function SeasonPlayer:_CheckBuildingCover(deltaTime)
    self._buildingLayer:OnCoverCheck(self._transform.position)
end

---@param name string
---@return UnityEngine.Transform
function SeasonPlayer:GetBoneNode(name)
    local boneTransform = GameObjectHelper.FindChild(self._transform, name)
    if boneTransform then
        return boneTransform
    end
    return self._transform
end

--转向某个坐标
function SeasonPlayer:RotateToPosition(position)
    local targetPosition = Vector3(position.x, self._agentTransform.position.y, position.z)
    local direction = targetPosition - self._agentTransform.position
    local angle = Vector3.Angle(self._agentTransform.forward, direction)
    local cross = Vector3.Cross(self._agentTransform.forward, direction)
    if cross.y < 0 then
        angle = -angle
    end
    self._agentTransform:Rotate(self._agentTransform.up, angle, UnityEngine.Space.Self);
    self._transform:Rotate(self._agentTransform.up, angle, UnityEngine.Space.Self)
end

function SeasonPlayer:OnMoveStop(playExpress)
    self._moveTimer = 0
    self._isPlayMoveVoice = false
    self:_PlayEventPointExpress(playExpress)
    if self._moveDoneCallback then
        self._moveDoneCallback()
        self._moveDoneCallback = nil
    end
end

function SeasonPlayer:_PlayEventPointExpress(playExpress)
    local seasonInput = self._seasonManger:SeasonInputManager():GetInput()
    if playExpress then
        local curEventPoint = seasonInput:GetCurClickEventPoint()
        if curEventPoint and curEventPoint:CheckInteractionDistance(self:RealPosition()) then
            if GameGlobal.UIStateManager():IsTopUI("UISeasonMain") then
                self:RotateToPosition(curEventPoint:Position())
                curEventPoint:PlayExpress(curEventPoint:Progress(), SeasonExpressTriggerType.Active, { curEventPoint:GroupID() })
                seasonInput:SetCurClickEventPoint(nil)
            else
                Log.error("SeasonPlayer PlayEventPointExpress UISeasonMain is not top ui.")
            end
        end
    else
        seasonInput:SetCurClickEventPoint(nil)
    end
end

function SeasonPlayer:Stop(playExpress)
    self._navMeshAgent.enabled = false
    self:PlayAnimation(SeasonPlayerAnimation.Stand)
    self:OnMoveStop(playExpress)
    self:_ClearLineRender()
    self._seasonManger:SeasonInputManager():GetInput():GetClickEffect():Stop()
end

function SeasonPlayer:_CheckPosition(deltaTime)
    local mapMaterial = SeasonMapMaterial.Default
    local direction = self._agentTransform.position - self._transform.position
    local results = UnityEngine.Physics.RaycastAll(self._transform.position, direction, 1000, 1 << SeasonLayerMask.Scene)
    if results and results.Length > 0 then
        for i = 0, results.Length - 1 do
            local contain, zoneID = self._zoneFlagLayer:GetZoneID(results[i].transform.gameObject)
            if contain then
                self._curZone = zoneID
                local unlock = self._seasonManger:SeasonMapManager():IsUnLock(zoneID)
                local clickUnlock = self._seasonManger:SeasonInputManager():GetClickUnLockZone()
                if not unlock and not clickUnlock then
                    self:Stop(false)
                end
            end
            mapMaterial = self._mapMaterialLayer:GetMapMaterial(results[i].transform.gameObject)
        end
    end
    if self._curMapMaterial ~= mapMaterial then --走到了不同材质的地面上
        self._curMapMaterial = mapMaterial
    end
    if self._seasonManger:SeasonAudioManager():GetSeasonAudio() then
        self._seasonManger:SeasonAudioManager():GetSeasonAudio():PlayStepSound(self._curMapMaterial, deltaTime)
    end
end

function SeasonPlayer:_CheckSyncPosition(deltaTime)
    self._syncPosTimer = self._syncPosTimer + deltaTime
    if self._syncPosTimer > self._syncPosDuration then
        self._syncPosTimer = 0
        self:_SyncPosition()
    end
end

---向服务器同步位置
function SeasonPlayer:_SyncPosition(isDispose)
    GameGlobal.TaskManager():StartTask(self._ReqSyncPos, self, isDispose)
end

function SeasonPlayer:_ReqSyncPos(TT, isDispose)
    if self._isSyncing then
        Log.error("当前正在同步位置,不可重复同步")
        return
    end
    local pos = self:_FormatPos()
    pos.y = 0 --y坐标无需同步
    if self._lastSyncPos == pos then
        Log.info("当前位置与上次结果一致,无需同步:", self._lastSyncPos)
        return
    end
    local info = SeasonClientDataReply:New()
    info.m_x = pos.x
    info.m_y = pos.y
    info.m_z = pos.z
    self._isSyncing = true
    if isDispose then
        Log.info("退出前同步位置:", pos)
    end
    local req = self._module:HandleSeasonClientData(TT, info)
    self._isSyncing = false
    self._lastSyncPos = pos
    if req:GetSucc() then
        Log.info("同步位置成功:", pos)
    else
        Log.error("同步位置失败:", pos, req:GetResult())
    end
end

function SeasonPlayer:_FormatPos()
    local pos = self:Position()
    local x = math.floor(pos.x * 10000) / 10000
    local y = math.floor(pos.y * 10000) / 10000
    local z = math.floor(pos.z * 10000) / 10000
    return Vector3(x, y, z)
end

function SeasonPlayer:_UpdateLineRenderer()
    local bezierCorners1bend = self:_UpdateCalculateSmoothLine()

    if bezierCorners1bend ~= nil then
        local count = #bezierCorners1bend
        for _, lineRenderer in ipairs(self._lineRendererList) do
            lineRenderer.positionCount = count

            for j = count - 1, 0, -1 do
                local p = bezierCorners1bend[j + 1]
                p.y = 0.16 --略比地面高
                lineRenderer:SetPosition(j, p)
            end
        end
    else
        for _, lineRenderer in ipairs(self._lineRendererList) do
            lineRenderer.positionCount = 0
        end
    end
end

function SeasonPlayer:_ClearLineRender()
    for _, lineRenderer in ipairs(self._lineRendererList) do
        lineRenderer.positionCount = 0
    end
end

function SeasonPlayer:_UpdateCalculateSmoothLine()
    local count = self._navMeshAgent.path.corners.Length
    local navPoints = self._navMeshAgent.path.corners
    local splitPoints = {}
    local controlPoints = {}

    if count == 0 or count == 1 then
        return nil
    end
    -----------------------筛选过近坐标---------------------------------
    for i = 0, count - 1 do
        table.insert(splitPoints, navPoints[i])
    end
    -----------------------筛选过近坐标---------------------------------

    -----------------------开始按照长度对坐标进行插值----------------------

    table.insert(controlPoints, splitPoints[1] + (splitPoints[1] - splitPoints[2]) * 0.05)
    table.insert(controlPoints, splitPoints[1])

    for l = 1, #splitPoints - 1 do
        local splitCont = self:_GetStraightLineSplit(splitPoints[l], splitPoints[l + 1])
        for m = 1, #splitCont do
            table.insert(controlPoints, splitCont[m])
        end
    end
    table.insert(controlPoints, navPoints[count - 1])

    table.insert(controlPoints, navPoints[count - 1] + (navPoints[count - 1] - splitPoints[#splitPoints - 1]) * 0.05)
    -----------------------结束按照长度对坐标进行插值----------------------
    -----------------------生成光滑弯曲的线的顶点坐标----------------------
    -- 设置线段数和宽度
    local numPoints = 3
    local positions = {}
    table.insert(positions, navPoints[0])
    for k = 2, #controlPoints - 2 do
        local p0 = controlPoints[k - 1]
        local p1 = controlPoints[k]
        local p2 = controlPoints[k + 1]
        local p3 = controlPoints[k + 2]
        local romDist = Vector3.Distance(p1, p2)
        if romDist < 0.1 and p2 == #controlPoints - 2 then
            table.insert(positions, controlPoints[k + 1])
        else
            numPoints = math.ceil(romDist / 0.2)
            numPoints = math.max(3, numPoints)
            for j = 1, numPoints do
                local t = j / (numPoints)
                local point = self:_CatmullRomPoint(p0, p1, p2, p3, t)
                table.insert(positions, point)
            end
        end
    end
    -----------------------生成光滑弯曲的线的顶点坐标----------------------
    return positions
end

function SeasonPlayer:_CatmullRomPoint(p0, p1, p2, p3, t)
    return p0 * (-0.5 * t * t * t + t * t - 0.5 * t) + p1 * (1.5 * t * t * t - 2.5 * t * t + 1.0) +
        p2 * (-1.5 * t * t * t + 2.0 * t * t + 0.5 * t) +
        p3 * (0.5 * t * t * t - 0.5 * t * t)
end

function SeasonPlayer:_GetStraightLineSplit(p1, p2)
    local pointList = {}

    local spliteCount = 2
    local mSvrTime = GameGlobal.GetModule(SvrTimeModule)
    local lineArg = mSvrTime:GetServerTime() / 1000 --当前时间
    spliteCount = math.ceil(Vector3.Distance(p1, p2) / 0.25)
    spliteCount = math.max(2, spliteCount)
    local vectorX = Vector3(1, p1.y, 0)
    local vectorZ = Vector3(0, p1.y, 1)

    for i = 1, spliteCount do
        local lerp = (1 / spliteCount * i)
        if lerp > 0 and lerp < 1 then
            local x = p1.x * (1 - lerp) + p2.x * lerp
            local z = p1.z * (1 - lerp) + p2.z * lerp

            local splitPoint = Vector3(x, p1.y, z)
            local dotX =math.abs (Vector3.Dot(vectorX.normalized, splitPoint.normalized))
            local dotZ =math.abs (Vector3.Dot(vectorZ.normalized, splitPoint.normalized))

            local tDistX = (math.sin((lineArg + splitPoint.z * 2))) * dotX * 0.18
            local tDistz = (math.sin((lineArg + splitPoint.x * 2))) * dotZ * 0.18
            splitPoint.x = splitPoint.x + tDistX
            splitPoint.z = splitPoint.z + tDistz
            table.insert(pointList, splitPoint)
        end
    end

    return pointList
end

