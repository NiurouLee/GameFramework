---@class UIAircraft3DPet:Object 建筑视图的操作及数据处理：房间内物体，角色动作及交互处理
_class("UIAircraft3DPet", Object)
UIAircraft3DPet = UIAircraft3DPet

---@class AircraftPetActionState
local AircraftPetActionState = {
    Idle = 0, --待机
    Moving = 1, --移动中
    Pressing = 2, --被按下中
    Dragging = 3, --被拖拽中
    Dropping = 4, --拖拽松手后下落中
    Responding = 5, --点击响应中
    Interacting = 6, --交互点交互中
    ReadyToMove = 7, --准备移动
    Stop = 8 --停止状态
}
_enum("AircraftPetActionState", AircraftPetActionState)
AircraftPetActionState = AircraftPetActionState

---@class AircraftPetState
local AircraftPetState = {
    Normal = 0,
    Selected = 1,
    Interactive = 2
}
_enum("AircraftPetState", AircraftPetState)
AircraftPetState = AircraftPetState

---@class AircraftPetFaceID
local AircraftPetFaceID = {
    Blink = 1, --眨眼
    Click = 1 --被点击
}
_enum("AircraftPetFaceID", AircraftPetFaceID)
AircraftPetFaceID = AircraftPetFaceID

function UIAircraft3DPet:Constructor(resRequest, petGameObject, petData, room)
    --@type AircraftPetState
    self._aircraftPetState = AircraftPetState.Normal
    ---@type table<number,ResRequest>
    self._resRequests = resRequest
    ---@type UnityEngine.GameObject
    self._petGO = petGameObject
    ---@type Pet
    self._petData = petData
    self._standIdle = self._petData:GetPetAircraftIdle()
    ---@type UIAircraftRoomBase
    self._room = room
    ---@type UnityEngine.Animator
    self._animator = petGameObject.transform:Find("Root"):GetComponent(typeof(UnityEngine.Animator))
    ---@type Vector3
    self._bubbleOffset = Vector3(0, 3, 0)
    self._bubbleCfgOffset = Vector3.zero

    local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(self._petGO)
    if skinnedMeshRender ~= nil then
        local meshExtents = GameObjectHelper.FindFirstSkinedMeshRenderBoundsExtent(self._petGO)
        self._bubbleOffset = Vector3(0, meshExtents.x * 2 * self._petGO.transform.localScale.y, 0)
    end

    ---简单的随机行为控制逻辑参数
    ---@type number
    self._nextActionCountdown = 0
    ---@type number AircraftPetActionState
    self._currentActionState = AircraftPetActionState.Stop

    ---@type number 交互点表情持续计时
    self._interactFaceCountdown = 0
    ---@type number 交互点待机计时
    self._interactIdleCountdown = 0

    ---const
    ---@type number 每次行为间隔的倒计时随机范围
    self._nextActionCountdownMin = 1
    self._nextActionCountdownMax = 6
    ---@type number 交互行为时长的倒计时随机范围
    self._interactCountdownMin = 10
    self._interactCountdownMax = 20
    ---@type number 交互区idle时长
    self._interactIdleTime = 1

    self.animName = {}
    self.animName.walk = "Walk"
    self.animName.click = "Click01"

    ---@type UnityEngine.BoxCollider
    local collider = self._petGO:AddComponent(typeof(UnityEngine.BoxCollider))
    collider.size = Vector3(0.5, 1.2, 0.5)
    collider.center = Vector3(0, 0.6, 0)

    --被点击之后的响应时长
    self.respondTime = -1

    self.lastState = nil

    self.pickUpHeight = Cfg.cfg_aircraft_camera["petPickupHeight"].Value
    --正在行走的星灵被点击，播完动作后的等待时间(ms)
    self.clickWaitTime = Cfg.cfg_aircraft_camera["clickWaitTime"].Value * 1000

    ---@type MaterialAnimation
    self._MaterialAnimation = self._petGO:GetComponent(typeof(MaterialAnimation))
    if not self._MaterialAnimation then
        self._MaterialAnimation = self._petGO:AddComponent(typeof(MaterialAnimation))
    end
    self._MaterialAnimationContainer =
        ResourceManager:GetInstance():SyncLoadAsset("globalShaderEffects.asset", LoadType.Asset)
    self._MaterialAnimation:AddClips(self._MaterialAnimationContainer.Obj)

    --navmeshAgent
    ---@type UnityEngine.AI.NavMeshAgent
    self._navMeshAgent = self._petGO:AddComponent(typeof(UnityEngine.AI.NavMeshAgent))
    self._navMeshAgent.angularSpeed = 1000
    self._navMeshAgent.stoppingDistance = 0.1
    self._navMeshAgent.speed = 1.1
    self._navMeshAgent.radius = 0.5
    self._navMeshAgent.autoBraking = false
    self._navMeshAgent.areaMask = 1 << self._room:GetNavLayerBySpaceID(self._room:SpaceID())

    --navmeshObstacle
    ---@type UnityEngine.AI.NavMeshObstacle
    self._navMeshObstacle = self._petGO:AddComponent(typeof(UnityEngine.AI.NavMeshObstacle))
    self._navMeshObstacle.shape = UnityEngine.AI.NavMeshObstacleShape.Capsule
    self._navMeshObstacle.radius = 0.5
    self._navMeshObstacle.carving = true
    self._navMeshObstacle.enabled = false

    ---navmesh agent speed control
    self._velocityCheckTimer = 0
    self._lowVelocity = false
    self._movePauseTimer = 0
    self._pauseDone = false
    ---const
    self._velocityCheckInterval = 500
    self._velocitySqrThreshold = self._navMeshAgent.speed * self._navMeshAgent.speed * 0.5
    self._movePauseTimeMin = 1000
    self._movePauseTimeMax = 2000
    ---end

    ---@type boolean
    self._hasOccupiedPoint = false

    ---@type UIAircraftInteractiveArea
    self._occupiedArea = nil

    ---@type UIAircraftInteractivePoint
    self._occupiedPoint = nil

    self._arrivedAreaAndPoint = {}

    -- self:_Init()

    --点击特效
    self.clickEffCfg = Cfg.cfg_aircraft_click_eff[self._petData:GetTemplateID()]
    if self.clickEffCfg and self.clickEffCfg.EffName then
        self.clickEffReq =
            ResourceManager:GetInstance():SyncLoadAsset(self.clickEffCfg.EffName .. ".prefab", LoadType.GameObject)
        self.clickEff = self.clickEffReq.Obj
        self.clickEff.transform:SetParent(self._petGO.transform)
        self.clickEff.transform.localRotation = Quaternion.identity
        self.clickEff.transform.localScale = Vector3.one
        local cfgPos = self.clickEffCfg.PosOffset
        self.clickEff.transform.localPosition = Vector3(cfgPos[1], cfgPos[2], cfgPos[3])
        self.clickEffEvent = nil
    end

    --增加好感度特效
    self._addAffinityEffectName = "ui_click.prefab"
    self._addAffinityEffectReq =
        ResourceManager:GetInstance():SyncLoadAsset(self._addAffinityEffectName, LoadType.GameObject)
    self._addAffinityEffect = self._addAffinityEffectReq.Obj
    self._addAffinityEffect:SetActive(false)

    ---end---

    local face_name = tostring(self._petData:GetTemplateID()) .. "_face"
    local face = GameObjectHelper.FindChild(self._petGO.transform, face_name)
    if face then
        local render = face.gameObject:GetComponent(typeof(UnityEngine.SkinnedMeshRenderer))
        if not render then
            Log.fatal("星灵" .. self._petData:GetTemplateID() .. "面部mesh缺失，无法正确显示表情")
        else
            ---@type UnityEngine.Material
            self._faceMat = self:GetMaterial(render)
        end
    end
    self._mainCamera = UnityEngine.GameObject.Find("Main Camera"):GetComponent("Camera")

    --默认表情眨眼
    self:SetPetFace(AircraftPetFaceID.Blink)

    self._interactFaceID = AircraftPetFaceID.Blink

    self._petDataChangeHandler = GameHelper:GetInstance():CreateCallback(self._petDataChange, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.PetDataChangeEvent, self._petDataChangeHandler)
end
function UIAircraft3DPet:GetMaterial(render)
    -- if render.sharedMaterial then
    --     return render.sharedMaterial
    -- end
    return render.material
end
function UIAircraft3DPet:_Init()
    self:_ReleaseCurrentPoint()
    local areaList, pointList = self._room:GetAvailableAreaAndPoints()
    local sum = #areaList + #pointList
    if sum > 0 then
        self._hasOccupiedPoint = true
        local ran = math.random(1, sum)
        if ran <= #areaList then
            --Log.fatal("起点 area:"..self._room:GetAreaIndex(self._occupiedArea))
            self._occupiedArea = areaList[ran]
            self._occupiedPoint = self._occupiedArea:GetAndOccupyAvailablePoint()
            self._petGO.transform.position = self._occupiedPoint:GetPos()
            self._petGO.transform.forward = self._occupiedPoint:GetForward()
            self._arrivedAreaAndPoint[#self._arrivedAreaAndPoint + 1] = self._occupiedArea
        else
            --Log.fatal("起点 point:"..self._occupiedPoint:GetIndex())
            self._occupiedPoint = pointList[ran - #areaList]
            self._petGO.transform.position = self._occupiedPoint:GetPos()
            self._room:OccupyRestPoint(self._occupiedPoint:GetIndex())
            local randomRot = math.random(-180, 180)
            self._petGO.transform.rotation = Quaternion.Euler(0, randomRot, 0)
            self._arrivedAreaAndPoint[#self._arrivedAreaAndPoint + 1] = self._occupiedPoint
        end
    else
        Log.fatal("风船房间(space id：" .. self._room:GetRoomLogicData():SpaceId() .. ")没有足够的点位初始化宝宝")
    end

    self._nextActionCountdown = math.random(self._nextActionCountdownMin, self._nextActionCountdownMax)
    self._currentActionState = AircraftPetActionState.Idle
end

function UIAircraft3DPet:Dispose()
    self._MaterialAnimationContainer:Dispose()

    for _, req in ipairs(self._resRequests) do
        req:Dispose()
    end

    -- if self._bubbleReq then
    --     self._bubbleReq:Dispose()
    -- end

    if self.clickEffEvent then
        GameGlobal.Timer():CancelEvent(self.clickEffEvent)
        self.clickEffEvent = nil
    end
    if self.clickEffReq then
        self.clickEffReq:Dispose()
    end

    if self._addAffinityEffectReq then
        self._addAffinityEffectReq:Dispose()
    end

    self:UnloadBubbleEffect()

    if self._petDataChangeHandler then
        GameGlobal.EventDispatcher():RemoveCallbackListener(
            GameEventType.PetDataChangeEvent,
            self._petDataChangeHandler
        )
    end
end

function UIAircraft3DPet:StartNavi()
    self:_Init()
end

function UIAircraft3DPet:ForceInitAnimator()
    --修改动画状态机必须等到游戏物体active时
    self:SetPetAnim(AircraftPetActionState.Idle)
    if self._standIdle and self._standIdle ~= "" then
        --不修改状态机，强制跳过动画融合
        self._animator:CrossFade("stand", 0)
    end
end

function UIAircraft3DPet:StopNavi()
    self._currentActionState = AircraftPetActionState.Stop
end

function UIAircraft3DPet:Update(deltaTimeMS)
    self:_UpdateFace(deltaTimeMS)
    if self._aircraftPetState == AircraftPetState.Selected then
        return
    end
    if self._aircraftPetState == AircraftPetState.Interactive then
        if self._currentActionState == AircraftPetActionState.Responding then
            if self.respondTime < 0 then
                local animStateInfo = self._animator:GetNextAnimatorStateInfo(0)
                if animStateInfo:IsName("click01") then
                    self.respondTime = animStateInfo.length + 0.1
                end
            else
                self.respondTime = self.respondTime - deltaTimeMS / 1000
                if self.respondTime < 0 then
                    self._currentActionState = AircraftPetActionState.Idle
                    self.respondTime = -1
                end
            end
        end
        return
    end
    if self._currentActionState == AircraftPetActionState.Stop then
        return
    end

    if self._currentActionState == AircraftPetActionState.Moving then
        --基于NavMesh的移动流程
        if self._movePauseTimer > 0 then
            self._movePauseTimer = self._movePauseTimer - deltaTimeMS
            if self._movePauseTimer <= 0 then
                self._pauseDone = true
                self._navMeshObstacle.enabled = false
            end
        elseif self._pauseDone then
            self._navMeshAgent.enabled = true
            self._navMeshAgent.isStopped = false
            self._navMeshAgent.destination = self._occupiedPoint:GetPos()
            if not self._navMeshAgent.destination then
                Log.error("1111")
            end
            self._pauseDone = false
            self:SetPetAnim(AircraftPetActionState.Moving)
        elseif
            self._petGO.activeInHierarchy and self._navMeshAgent.enabled and
                self._navMeshAgent.remainingDistance < self._navMeshAgent.stoppingDistance
         then
            local forward = self._occupiedPoint:GetForward()
            if forward then
                self._petGO.transform.forward = forward
            end
            self._navMeshAgent.isStopped = true
            self._navMeshAgent.enabled = false
            self._navMeshObstacle.enabled = true
            self:_SwitchToInteractState()
        else ---moving
            self._velocityCheckTimer = self._velocityCheckTimer + deltaTimeMS
            if self._velocityCheckTimer > self._velocityCheckInterval then
                self._velocityCheckTimer = 0
                local velocitySqr = self._navMeshAgent.velocity:SqrMagnitude()
                if velocitySqr < self._velocitySqrThreshold then
                    if self._lowVelocity then
                        --Log.fatal(self._petGO.name.." pause!")
                        ---速度连续低于阈值 需要处理
                        self._movePauseTimer = Mathf.Lerp(self._movePauseTimeMin, self._movePauseTimeMax, math.random())
                        self._navMeshAgent.isStopped = true
                        self._navMeshAgent.enabled = false
                        self._navMeshObstacle.enabled = true
                        self._lowVelocity = false
                        self._velocityCheckTimer = 0
                        self._pauseDone = false
                        self:SetPetAnim(AircraftPetActionState.Idle)
                    else
                        self._lowVelocity = true
                    end
                end
            end
        end
    elseif self._currentActionState == AircraftPetActionState.Idle then
        --基于NavMesh的目标点计算
        self._nextActionCountdown = self._nextActionCountdown - deltaTimeMS / 1000
        if self._nextActionCountdown <= 0 and self._petGO.activeInHierarchy then
            self._navMeshObstacle.enabled = false
            self._currentActionState = AircraftPetActionState.ReadyToMove
        end
    elseif self._currentActionState == AircraftPetActionState.Responding then
        -- self.respondTime = self.respondTime - deltaTimeMS / 1000
        -- if self.respondTime < 0 then
        --     self._currentActionState = self.lastState
        --     self.lastState = nil
        -- end
        if self.respondTime < 0 then
            local animStateInfo = self._animator:GetNextAnimatorStateInfo(0)
            if animStateInfo:IsName("click01") then
                self.respondTime = animStateInfo.length - 0.25
            end
        else
            self.respondTime = self.respondTime - deltaTimeMS / 1000
            if self.respondTime < 0 then
                self._currentActionState = self.lastState
                if self.lastState == AircraftPetActionState.Moving then
                    self._movePauseTimer = self.clickWaitTime
                -- self._navMeshAgent.isStopped = false
                end
                self:SetPetFace(AircraftPetFaceID.Blink)
                self.lastState = nil
                self.respondTime = -1
                if self.clickEff then
                    self.clickEff:SetActive(false)
                end
            end
        end
    elseif self._currentActionState == AircraftPetActionState.Interacting then
        --交互点表情气泡逻辑
        local deltaTime = deltaTimeMS / 1000
        self._nextActionCountdown = self._nextActionCountdown - deltaTime
        if self._nextActionCountdown <= 0 and self._petGO.activeInHierarchy then
            self:SetPetFace(AircraftPetFaceID.Blink)
            self._navMeshObstacle.enabled = false
            self._currentActionState = AircraftPetActionState.ReadyToMove
        else
            if self._interactFaceCountdown > 0 then
                --表情计时
                self._interactFaceCountdown = self._interactFaceCountdown - deltaTime
                if self._interactFaceCountdown < 0 then
                    self:SetPetFace(1)
                    self._interactIdleCountdown = self._interactIdleTime
                end
            elseif self._interactIdleCountdown > 0 then
                --无表情待机计时
                self._interactIdleCountdown = self._interactIdleCountdown - deltaTime
                if self._interactIdleCountdown < 0 then
                    self._interactFaceCountdown = self:SetPetFace(self._interactFaceID) or 0
                end
            end
        end
    elseif self._currentActionState == AircraftPetActionState.ReadyToMove then
        self:_MoveToNextPoint()
    end

    self:_UpdateBubble()
end

function UIAircraft3DPet:_ReleaseCurrentPoint()
    if self._hasOccupiedPoint then
        if self._occupiedArea then
            self._occupiedArea:ReleasePoint(self._occupiedPoint:GetIndex())
            self._occupiedArea = nil
        else
            self._room:ReleaseRestPoint(self._occupiedPoint:GetIndex())
        end
        self._occupiedPoint = nil
    end
end

function UIAircraft3DPet:_MoveToNextPoint()
    self:_ReleaseCurrentPoint()

    --不放回抽样
    if #self._arrivedAreaAndPoint >= self._room:GetAreaAndRestPointCount() then
        --Log.fatal("全部走过一遍")
        self._arrivedAreaAndPoint = {}
    end
    local areaList, pointList = self._room:GetAvailableAreaAndPoints()
    local filteredAreaList, filteredPointList = self:_FilterAreaPointList(areaList, pointList)
    local sum = #filteredAreaList + #filteredPointList
    if sum ~= 0 then
        areaList = filteredAreaList
        pointList = filteredPointList
    else
        sum = #areaList + #pointList
    end
    if sum > 0 then
        self._navMeshAgent.enabled = true
        local ran = math.random(1, sum)
        if ran <= #areaList then
            --Log.fatal("Next area:"..self._room:GetAreaIndex(self._occupiedArea))
            self._occupiedArea = areaList[ran]
            self._occupiedPoint = self._occupiedArea:GetAndOccupyAvailablePoint()
            self._navMeshAgent.destination = self._occupiedPoint:GetPos()
            if not self._navMeshAgent.destination then
                Log.error("1111")
            end
            self._arrivedAreaAndPoint[#self._arrivedAreaAndPoint + 1] = self._occupiedArea
        else
            --Log.fatal("Next point:"..self._occupiedPoint:GetIndex())
            self._occupiedPoint = pointList[ran - #areaList]
            self._navMeshAgent.destination = self._occupiedPoint:GetPos()
            if not self._navMeshAgent.destination then
                Log.error("1111")
            end
            self._room:OccupyRestPoint(self._occupiedPoint:GetIndex())
            self._arrivedAreaAndPoint[#self._arrivedAreaAndPoint + 1] = self._occupiedPoint
        end
        self._navMeshAgent.isStopped = false
        self:_SwitchToMovingState()
    else
        Log.fatal("风船房间(space id：" .. self._room:GetRoomLogicData():SpaceId() .. ")没有足够的点位给宝宝移动 待机30秒")
        self._nextActionCountdown = 30
    end
end

function UIAircraft3DPet:_FilterAreaPointList(areaList, pointList)
    local filteredAreaList = {}
    local filteredPointList = {}
    for i = 1, #areaList do
        local area = areaList[i]
        if not table.icontains(self._arrivedAreaAndPoint, area) then
            filteredAreaList[#filteredAreaList + 1] = area
        end
    end
    for i = 1, #pointList do
        local point = pointList[i]
        if not table.icontains(self._arrivedAreaAndPoint, point) then
            filteredPointList[#filteredPointList + 1] = point
        end
    end
    return filteredAreaList, filteredPointList
end

function UIAircraft3DPet:_SwitchToIdleState()
    self._currentActionState = AircraftPetActionState.Idle
    self:SetPetAnim(AircraftPetActionState.Idle)
    self._nextActionCountdown = math.random(self._nextActionCountdownMin, self._nextActionCountdownMax)
end

function UIAircraft3DPet:_SwitchToMovingState()
    self._currentActionState = AircraftPetActionState.Moving
    self:SetPetAnim(AircraftPetActionState.Moving)
    self:SetPetFace(AircraftPetFaceID.Blink)
    self._velocityCheckTimer = 0
    self._movePauseTimer = 0
end

function UIAircraft3DPet:_SwitchToInteractState()
    self._currentActionState = AircraftPetActionState.Interacting
    self:SetPetAnim(AircraftPetActionState.Idle)
    self._nextActionCountdown = math.random(self._interactCountdownMin, self._interactCountdownMax)
    self._interactIdleCountdown = self._interactIdleTime

    if self._occupiedPoint then
        local faceIDList = self._occupiedPoint:GetFaceIDList()
        local randomRes = math.random(1, #faceIDList)
        self._interactFaceID = faceIDList[randomRes]
        self._interactFaceCountdown = self:SetPetFace(self._interactFaceID) or 0
    end
end

---@return UnityEngine.GameObject
function UIAircraft3DPet:PetGameObject()
    return self._petGO
end

function UIAircraft3DPet:GetPetData()
    return self._petData
end

function UIAircraft3DPet:PstID()
    return self._petData:GetPstID()
end

function UIAircraft3DPet:CurrentState()
    return self._currentActionState
end

function UIAircraft3DPet:InteractiveClick()
    if self._currentActionState == AircraftPetActionState.Responding then
        return
    end
    self:_CreateClickInteractiveEffect(self._petGO.transform.position)
    self._currentActionState = AircraftPetActionState.Responding
    self:SetPetAnim(AircraftPetActionState.Idle)
    self:SetPetAnim(AircraftPetActionState.Responding)
    --为了不修改状态机，保证星灵播完点击动作后，一定回到idle动作
    self.respondTime = -1

    --播放交互语音
    local tplID = self._petData:GetTemplateID()
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:PlayPetAudio("AircraftInteract", tplID)

    --播放特效（如果有）
    if self.clickEff then
        GameGlobal.Timer():AddEvent(
            self.clickEffCfg.DelayTime,
            function()
                self.clickEff:SetActive(false)
                self.clickEff:SetActive(true)
            end
        )
    end

    GameGlobal.TaskManager():StartTask(self.SendPetAddAffinity, self)
end

function UIAircraft3DPet:_CreateAddAffinityEffect()
    self._addAffinityEffect:SetActive(false)
    self._addAffinityEffect.transform.position = self._petGO.transform.position
    self._addAffinityEffect:SetActive(true)
end

function UIAircraft3DPet:_CreateClickInteractiveEffect(pos)
    --点击交互特效
    local effectName = "ui_click_01.prefab"
    local delayTime = 1000
    local effectReq = ResourceManager:GetInstance():SyncLoadAsset(effectName, LoadType.GameObject)
    local effect = effectReq.Obj
    effect.transform.position = pos
    effect:SetActive(true)
    GameGlobal.Timer():AddEvent(
        delayTime,
        function()
            effectReq:Dispose()
        end
    )
end

function UIAircraft3DPet:SendPetAddAffinity(TT)
    if not self._petModule then
        self._petModule = GameGlobal.GetModule(PetModule)
    end
    local res, addValue = self._petModule:RequestPetAddAffinity(TT, self._petData:GetPstID())
    if res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftAddPetFavorable, addValue)
        self:_CreateAddAffinityEffect()
    end
end

function UIAircraft3DPet:EnterInteractiveState()
    self._aircraftPetState = AircraftPetState.Interactive
    self.lastState = self._currentActionState
    self._currentActionState = AircraftPetActionState.Idle
    self:SetPetAnim(AircraftPetActionState.Idle)
    local delta = self._mainCamera.transform.position - self._petGO.transform.position
    delta.y = 0
    self._petGO.transform.rotation = Quaternion.LookRotation(delta)
    self:HidFaceBubble()
    if self._navMeshAgent.enabled then
        if not self._navMeshAgent.isStopped then
            self._navMeshAgent.isStopped = true
        end
        self._navMeshAgent.enabled = false
    end

    if not self._navMeshObstacle.enabled then
        self._navMeshObstacle.enabled = true
    end
end

function UIAircraft3DPet:ExitInteractiveState()
    self._aircraftPetState = AircraftPetState.Normal
    self._addAffinityEffect:SetActive(false)
    self:RefreshFaceBubble()
end

function UIAircraft3DPet:_petDataChange()
    --1001是剧情，2001是可触发、2002是已接、2003是可完成
    if self._faceId == 1001 or self._faceId == 2001 or self._faceId == 2002 or self._faceId == 2003 then
        self:RefreshFaceBubble()
        return
    end
end

function UIAircraft3DPet:RefreshFaceBubble()
    self:SetPetFace(AircraftPetFaceID.Blink)
    if self._bubbleGo then
        self._bubbleGo:SetActive(true)
    end
end

function UIAircraft3DPet:HidFaceBubble()
    if self._bubbleGo then
        self._bubbleGo:SetActive(false)
    end
end

function UIAircraft3DPet:OnClick()
    self:EnterSelectedState()
end

function UIAircraft3DPet:EnterSelectedState()
    self._aircraftPetState = AircraftPetState.Selected
    self._currentActionState = AircraftPetActionState.Idle
    self:SetPetAnim(AircraftPetActionState.Idle)
    local delta = self._mainCamera.transform.position - self._petGO.transform.position
    delta.y = 0
    self._petGO.transform.rotation = Quaternion.LookRotation(delta)
    self:HidFaceBubble()
    if self._navMeshAgent.enabled then
        if not self._navMeshAgent.isStopped then
            self._navMeshAgent.isStopped = true
        end
        self._navMeshAgent.enabled = false
    end

    if not self._navMeshObstacle.enabled then
        self._navMeshObstacle.enabled = true
    end

    --播放点击语音
    local tplID = self._petData:GetTemplateID()
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:PlayPetAudio("AircraftClick", tplID)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftSelectPetEvent, self._room, self)
end

function UIAircraft3DPet:ExitSelectedState()
    self._aircraftPetState = AircraftPetState.Normal
    self:RefreshFaceBubble()
end

--长按开始
function UIAircraft3DPet:OnPressBegin()
    self.lastState = self._currentActionState
    self._currentActionState = AircraftPetActionState.Pressing
    if self._navMeshAgent.enabled and not self._navMeshAgent.isStopped then
        self._navMeshAgent.isStopped = true
    end
    self:SetPetAnim(AircraftPetActionState.Pressing)
    self:SetPetFace(AircraftPetFaceID.Blink)
end

function UIAircraft3DPet:CalSliderWorldPos()
    local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(self._petGO)
    local offset = Vector3(0, self._petData:GetHPOffset(), 0)
    -- return self._petGO.transform.position + offset
    if skinnedMeshRender ~= nil then
        local skinnedMeshPosition = skinnedMeshRender.transform.position + offset
        local meshExtents = GameObjectHelper.FindFirstSkinedMeshRenderBoundsExtent(self._petGO)
        local convertExtents = Vector3(0, meshExtents.x * 2 * self._petGO.transform.localScale.y, 0)
        local targetPos = skinnedMeshPosition + convertExtents

        return targetPos
    else
        Log.fatal("Pet", self._petGO.name, "has no skinned mesh")
        return self._petGO.transform.position + offset
    end
end

function UIAircraft3DPet:PickUp()
    self._navMeshAgent.enabled = false
    self._navMeshObstacle.enabled = false
    self._petGO.transform.localPosition = self._petGO.transform.localPosition + Vector3(0, self.pickUpHeight, 0)
    --self.fadeCpt.viewType = ActorViewType.Ghost
    self._MaterialAnimation:Play("common_select")
    self._animator.speed = 0
end

function UIAircraft3DPet:OnDrag(_worldPos)
    self._petGO.transform.position = _worldPos + Vector3(0, self.pickUpHeight, 0)
end

--在读条过程中，结束长按，设置回之前的状态
function UIAircraft3DPet:OnCountEnd()
    self._currentActionState = self.lastState
    if self.lastState == AircraftPetActionState.Moving then
        self._navMeshAgent.isStopped = false
        self:SetPetAnim(AircraftPetActionState.Moving)
    end
    self.lastState = nil
end

--读条完成后，未发生拖拽后放下，需要找到一个最近的逻辑点
function UIAircraft3DPet:OnPressEnd()
    --self.fadeCpt.viewType = ActorViewType.Normal
    self._MaterialAnimation:Stop()
    self._navMeshAgent.enabled = true
    self._petGO.transform.localPosition = self._petGO.transform.localPosition + Vector3(0, -self.pickUpHeight, 0)

    self:_SwitchToIdleState()
    self._animator.speed = 1
end

--发生拖拽之后，放下
function UIAircraft3DPet:OnDrop()
    --self.fadeCpt.viewType = ActorViewType.Normal
    self._MaterialAnimation:Stop()
    self._animator.speed = 1

    self._navMeshAgent.enabled = true
    self._petGO.transform.localPosition = self._petGO.transform.localPosition + Vector3(0, -self.pickUpHeight, 0)
    self._navMeshAgent:Move(Vector3.zero)
    self._navMeshAgent.enabled = false
    self._navMeshObstacle.enabled = true

    self:_SwitchToIdleState()
end

---@param state AircraftPetActionState
function UIAircraft3DPet:SetPetAnim(state)
    if state == AircraftPetActionState.Idle then
        if self._standIdle and self._standIdle ~= "" then
            self._animator:SetBool(self._standIdle, true)
        end
        self._animator:SetBool(self.animName.walk, false)
    elseif state == AircraftPetActionState.Moving then
        if self._standIdle and self._standIdle ~= "" then
            self._animator:SetBool(self._standIdle, false)
        end
        self._animator:SetBool(self.animName.walk, true)
    elseif state == AircraftPetActionState.Responding then
        -- if self._standIdle then
        --     self._animator:SetBool(self._standIdle, true)
        -- end
        self._animator:SetTrigger(self.animName.click)
    elseif state == AircraftPetActionState.Pressing then
        --同idle
        if self._standIdle and self._standIdle ~= "" then
            self._animator:SetBool(self._standIdle, true)
        end
        self._animator:SetBool(self.animName.walk, false)
    else
    end
end

--region 表情及气泡相关-------
--播放表情
function UIAircraft3DPet:SetPetFace(id)
    local taskId = self._petData:GetTriggeredTaskId()
    local storyId = self._petData:GetTriggeredStoryId()

    local hasPlot = storyId and storyId ~= 0
    local hasEvent = taskId and taskId ~= 0

    --1001是剧情，2001是可触发、2002是已接、2003是可完成
    if hasPlot then
        id = 1001
    elseif hasEvent then
        local taskInfo = self._petData:GetFirstTaskInfo()
        if taskInfo then
            local state = taskInfo.state
            if state == PetTaskState.PetTS_Active then --可触发
                id = 2001
            elseif state == PetTaskState.PetTS_Accept then --已接
                id = 2002
            elseif state == PetTaskState.PetTS_Finish then --可完成
                id = 2003
            end
        else
            id = 2001
        end
    end

    local cfg = Cfg.cfg_aircraft_pet_face[id]
    if not cfg then
        Log.fatal("[Aircraft] SetPetFace config id not find ", id)
        return
    end

    if self._faceId == id then
        return
    end

    --气泡
    self:UnloadBubbleEffect()
    if cfg.BubbleEffect then
        local bubbleRequest = self:LoadBubbleEffect(cfg.BubbleEffect)
        if bubbleRequest then
            local bubble = bubbleRequest.Obj
            local effectParentName = cfg.BubbleNode
            local effectParent = nil
            if effectParentName then
                effectParent = GameObjectHelper.FindChild(self._petGO.transform, effectParentName)
            end
            if effectParent then
                bubble.transform:SetParent(effectParent)
                local pos = Vector3(table.unpack(cfg.BubbleOffset))
                bubble.transform.position = effectParent.position + pos
            else
                bubble.transform:SetParent(self._petGO.transform)
                bubble.transform.position = self:CalcBubblePos()
            end
            bubble.transform.rotation = self:CalcBubbleRotation()
            self._bubbleGo = bubble
            self._bubbleReq = bubbleRequest
        end

        self._bubbleCfgOffset = Vector3(table.unpack(cfg.BubbleOffset))
    end

    --表情
    self._faceId = id
    self._faceSeqIdx = 1
    self._faceSeqIdxTime = 0 --表情累计时间
    self._faceLastTime = 100 --表情持续时间

    return cfg.Length / 1000
end

--更新表情
function UIAircraft3DPet:_UpdateFace(deltaTimeMS)
    if not self._faceId or not self._faceMat or self._faceLastTime <= 0 then
        return
    end

    self._faceSeqIdxTime = self._faceSeqIdxTime + deltaTimeMS
    if self._faceSeqIdxTime > self._faceLastTime then
        self._faceSeqIdxTime = 0
        local cfg = Cfg.cfg_aircraft_pet_face[self._faceId]

        self._faceSeqIdx = self._faceSeqIdx + 1
        if self._faceSeqIdx > #cfg.FaceSeq then
            self._faceSeqIdx = 1
        end

        local seq = cfg.FaceSeq[self._faceSeqIdx]
        local face_frame = seq[1]
        self._faceLastTime = seq[2]

        self._faceMat:SetInt("_Frame", face_frame)
    -- Log.warn("face frame=", face_frame)
    end
end

--更新气泡
function UIAircraft3DPet:_UpdateBubble()
    local bubble = self._bubbleGo
    if bubble then
        -- bubble.transform.position = self:CalcBubblePos()
        bubble.transform.rotation = self:CalcBubbleRotation()
    end
end

--加载资源
function UIAircraft3DPet:LoadBubbleEffect(resPath)
    local request = ResourceManager:GetInstance():SyncLoadAsset(resPath, LoadType.GameObject)
    if request == nil then
        Log.fatal("Load Effect failed", resPath)
        return
    end
    local u3dGo = request.Obj
    u3dGo:SetActive(true)
    return request
end

--删除资源
function UIAircraft3DPet:UnloadBubbleEffect()
    if self._bubbleReq then
        self._bubbleReq:Dispose()
        self._bubbleReq = nil
    end
    self._bubbleGo = nil
end

function UIAircraft3DPet:CalcBubbleRotation()
    local qbase = self._mainCamera.transform.rotation
    local vforward = self._mainCamera.transform.forward
    local vplane_normal = Vector3(0, 1, 0)
    local vproject = Vector3.ProjectOnPlane(vforward, vplane_normal)
    local target = qbase * Quaternion.FromToRotation(vforward, vproject)

    return target
end

function UIAircraft3DPet:CalcBubblePos()
    local slot = GameObjectHelper.FindChild(self._petGO.transform, "EffectSlot")
    local pos = slot.position + self._bubbleOffset + self._bubbleCfgOffset
    return pos
end

function UIAircraft3DPet:CalcBubblePos2(bubble_offset)
    local pos = self._petGO.transform.position
    local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(self._petGO)
    if skinnedMeshRender ~= nil then
        local skinnedMeshPosition = skinnedMeshRender.transform.position + Vector3(bubble_offset.x, bubble_offset.y, 0)
        local meshExtents = GameObjectHelper.FindFirstSkinedMeshRenderBoundsExtent(self._petGO)
        local convertExtents = Vector3(0, meshExtents.x * 2, 0)
        pos = skinnedMeshPosition + convertExtents
    else
        Log.fatal("pet ", self._petGO.name, " has no skinned mesh")
    end

    return pos
end
--endregion 表情及气泡相关----
