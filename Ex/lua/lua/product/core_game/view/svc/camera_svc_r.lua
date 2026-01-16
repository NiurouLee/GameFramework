--[[------------------
    相机相关服务
--]]
------------------
---@class CameraService:BaseService
_class("CameraService", BaseService)
CameraService = CameraService

function CameraService:Constructor(world)
    ---@type World
    self.world = world
    ---@type TimeService
    self._timeService = self.world:GetService("Time")
end

---播放震屏效果
---@param shakeParam CameraShakeParams
function CameraService:PlayCameraShake(shakeParam)
    GameGlobal.TaskManager():CoreGameStartTask(self.UpdateCameraShake, self, shakeParam)
end

---@param shakeParam CameraShakeParams
function CameraService:UpdateCameraShake(TT, shakeParam)
    local delay = shakeParam.delay
    local duration = shakeParam.duration
    local timeElapsed = 0
    while delay > 0 do
        if self._timeService:GetDeltaTimeMs() > delay then
            duration = duration - delay
            timeElapsed = timeElapsed + delay
        end

        delay = delay - self._timeService:GetDeltaTimeMs()
        YIELD(TT)
    end

    ---@type MainCameraComponent
    local mainCameraCmpt = self.world:MainCamera()
    local oriPos = mainCameraCmpt:Camera().transform.position
    while duration > 0 do
        local offset = self:CalcShake(timeElapsed, shakeParam)
        mainCameraCmpt:ShakeCamera(oriPos, offset)
        timeElapsed = timeElapsed + self._timeService:GetDeltaTimeMs()
        duration = duration - self._timeService:GetDeltaTimeMs()
        YIELD(TT)
    end
end

---@return Vector3
---@param shakeParam CameraShakeParams
function CameraService:CalcShake(timeElapsed, shakeParam)
    local damp = self:Damp(shakeParam, timeElapsed)
    local offset = self:LinearVib(shakeParam.period, timeElapsed)
    local dir = Quaternion.Euler(0, 0, shakeParam.mainVibAngle):MulVec3(Vector3(1, 0, 0))
    local mainVib = dir * shakeParam.intenseRandomness * offset

    local randomVib = Vector3(0, 0, 0)
    if Mathf.Abs(shakeParam.intenseRandomness) > 0.000001 then
        randomVib = self:EmitRandomVib(shakeParam)
    end
    return (mainVib + randomVib) * damp
end

---@return number
---@param shakeParam CameraShakeParams
function CameraService:Damp(shakeParam, timeElapsed)
    local periodElapsed = 0
    while timeElapsed > shakeParam.period do
        timeElapsed = timeElapsed - shakeParam.period
        periodElapsed = periodElapsed + 1
    end
    return Mathf.Pow(1 - shakeParam.decayRate, periodElapsed)
end

function CameraService:LinearVib(period, timeElapsed)
    while timeElapsed > period do
        timeElapsed = timeElapsed - period
    end

    local offset
    if timeElapsed < 0.25 * period then
        offset = 4 / period * timeElapsed
    elseif timeElapsed < 0.75 * period then
        offset = 2 - 4 / period * timeElapsed
    else
        offset = -4 + 4 / period * timeElapsed
    end
    return offset
end

---@return Vector3
---@param shakeParam CameraShakePamams
function CameraService:EmitRandomVib(shakeParam)
    ---@type RandomServiceRender
    local randomSvc = self._world:GetService("RandomRender")
    local angle = randomSvc:RenderRand( -shakeParam.angleRandomness, shakeParam.angleRandomness)
    local intense = randomSvc:RenderRand( -shakeParam.intenseRandomness, shakeParam.intenseRandomness)
    if intense > 0 then
        angle = shakeParam.mainVibAngle + 90 + angle
    else
        angle = shakeParam.mainVibAngle - 90 + angle
    end
    return (Quaternion.Euler(0, 0, angle):MulVec3(Vector3(1, 0, 0))) * Mathf.Abs(intense)
end

---@param cameraParam CameraParam
function CameraService:InitializeSceneCamera()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local cameraParam = levelConfigData:GetCameraParam()

    --配置相机
    local camera_cmpt = self._world:MainCamera()
    ---@type UnityEngine.Camera
    local main_camera = camera_cmpt:Camera()
    main_camera.fieldOfView = cameraParam:GetFov()
    main_camera.nearClipPlane = cameraParam:GetNearClipDistance()
    main_camera.farClipPlane = cameraParam:GetFarClipDistance()
    main_camera.transform.position = cameraParam:GetCameraPosition()
    main_camera.transform.rotation = cameraParam:GetCameraRotation()

    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()
    mainCameraCmpt:LoadHUDCamera()
    mainCameraCmpt:LoadDarkCamera()
    mainCameraCmpt:LoadEffectCamera()
    mainCameraCmpt:LoadSceneCamera()
    mainCameraCmpt:LoadAuroraTimeFx()
    mainCameraCmpt:AttachScreenEffPoint()

    ---重置后处理配置
    self:ReplacePostProcessingProfile()

    --初始化震屏管理器
    HelperProxy:GetInstance():InitCameraShake()
end

function CameraService:CameraFollowHero(oldPos, newPos)
    --配置相机
    local camera_cmpt = self._world:MainCamera()
    ---@type UnityEngine.Camera
    local main_camera = camera_cmpt:Camera()
    local camPos = main_camera.transform.position
    local diff = newPos - oldPos
    local tarPos = Vector3(camPos.x + diff.x, camPos.y, camPos.z + diff.y)
    Log.error("board center " .. tostring(oldPos) .. "->" .. tostring(newPos))
    --Log.error("main camera move " .. tostring(camPos) .. "->" .. tostring(tarPos))

    --修改相机位置
    self._world:MainCamera():SetCameraPos(tarPos)
    ---@type Transform
    local trans = main_camera.transform
    trans:DOMove(tarPos, 0.5)
end

---主相机关闭/打开
function CameraService:BlinkMainCamera(enabled)
    local cMainCamera = self._world:MainCamera()
    local camera = cMainCamera:Camera()
    camera.enabled = enabled
end

---替换主相机的后处理配置文件
function CameraService:ReplacePostProcessingProfile()
    local postObjName = "PostTemp"
    local tmpObj = UnityEngine.GameObject.Find(postObjName)
    if not tmpObj then
        return
    end

    local tmpPostProcessingCmpt = tmpObj:GetComponent("UnityEngine.H3DPostProcessing.PostProcessing")
    local tmpProfile = tmpPostProcessingCmpt.profile

    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()
    mainCameraCmpt:SetPostProcessingProfile(tmpProfile)

    ---@type UnityEngine.GameObject
    local goEffRuchangActorpoint = UnityEngine.GameObject.Find(GameResourceConst.EffRuchangActorpoint)
    if goEffRuchangActorpoint then
        local camera = goEffRuchangActorpoint:GetComponentInChildren(typeof(UnityEngine.Camera), true)
        if camera then
            local pp = camera.gameObject:GetComponent("UnityEngine.H3DPostProcessing.PostProcessing")
            if pp then
                pp.profile = tmpProfile
            end
        end
    end
    tmpObj:SetActive(false)
end

--折叠屏手机分辨率变化后刷新相机fov
function CameraService:ResetFov_ForFoldableDevice()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local cameraParam = levelConfigData:GetCameraParam()
    cameraParam:ResetFov()

    --配置相机
    local camera_cmpt = self._world:MainCamera()
    ---@type UnityEngine.Camera
    local main_camera = camera_cmpt:Camera()
    main_camera.fieldOfView = cameraParam:GetFov()

    local camera_cmp = self._world:MainCamera()
    camera_cmp:ResetFov_ForFoldableDevice()
end

-----------------------------------------------------------------------------------------------------

--region 震屏参数
---@class CameraShakeParams:Object
_class("CameraShakeParams", Object)
CameraShakeParams = CameraShakeParams

---@param delay number
---@param intensity number
---@param mainVibAngle number
---@param duration number
---@param vibrato number
---@param period number
---@param decayRate number
---@param angleRandomness number
---@param intenseRandomness number
function CameraShakeParams:Constructor(
    delay,
    intensity,
    mainVibAngle,
    duration,
    vibrato,
    decayRate,
    angleRandomness,
    intenseRandomness)
    ---@type number
    self.delay = delay
    ---@type number
    self.intensity = intensity
    ---@type number
    self.mainVibAngle = mainVibAngle
    ---@type number
    self.duration = duration
    ---@type number
    self.vibrato = vibrato
    ---@type number
    self.period = duration / vibrato
    ---@type number
    self.decayRate = decayRate
    if self.decayRate > 1 and self.decayRate < 100 then
        self.decayRate = self.decayRate / 100
    end
    ---@type number
    self.angleRandomness = angleRandomness
    ---@type number
    self.intenseRandomness = intenseRandomness
end

--endregion
