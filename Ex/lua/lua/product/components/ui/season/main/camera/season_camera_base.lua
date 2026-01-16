---@class SeasonCameraBase:Object
_class("SeasonCameraBase", Object)
SeasonCameraBase = SeasonCameraBase

function SeasonCameraBase:Constructor(seasonID)
    self._cameraSeasonCfg = Cfg.cfg_season_camera[seasonID]
    self._seasonMapCfg = Cfg.cfg_season_map[seasonID]
    self._cameraSizeMin = self._cameraSeasonCfg.CameraSizeMin
    self._cameraSizeMax = self._cameraSeasonCfg.CameraSizeMax
    self._mapLeft = self._seasonMapCfg.MapDragRange[1]
    self._mapTop = self._seasonMapCfg.MapDragRange[2]
    self._mapRight = self._seasonMapCfg.MapDragRange[3]
    self._mapBottom = self._seasonMapCfg.MapDragRange[4]
    self._cameraSpeed = 0.005
    self._cameraSizeSpeed = 0.005
    self._dragValue = 50               --启动拖拽的临界值
    self._startPosition = Vector3.zero --拖拽的起点
    self._endPosition = Vector3.zero   --拖拽的终点
    self._draging = false
    self._inputPhase = SeasonInputPhase.None
    self._touchFingerID = nil
    self._targetPosition = nil
    self._deltaPosition = nil
    self._recordSize = nil
    self._sizeTweenTime = 1
    self._cameraSize = SeasonTool:GetInstance():GetLocalDBFloat("SeasonCameraSize", self._cameraSeasonCfg.DefaultSize)
    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()
    ---@type SeasonCameraMode
    self._mode = SeasonCameraMode.Follow
    ---@type UnityEngine.GameObject
    self._cameraGO = UnityEngine.GameObject.Find("Main Camera") --UnityEngine.Camera.main.gameObject
    if not self._cameraGO then
        Log.fatal("SeasonCameraBase can not found MainCamera!")
    end
    ---@type UnityEngine.Camera
    self._camera = self._cameraGO:GetComponent("Camera")
    ---@type UnityEngine.Transform
    self._cameraTransform = self._cameraGO.transform
    ---@type SeasonManager
    self._seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    ---@type SeasonPlayer
    self._player = self._seasonManager:SeasonPlayerManager():GetPlayer()
    ---@type UnityEngine.GameObject
    self._rtCameraGO = self._cameraTransform:Find("RTCamera")
    ---@type UnityEngine.Camera
    self._rtCamera = self._rtCameraGO:GetComponent("Camera")
    local rt = self._rtCamera.targetTexture
    self._cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width * 0.25, UnityEngine.Screen.height * 0.25, 16)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, self._cache_rt)
            self._rtCamera.targetTexture = self._cache_rt
            UnityEngine.Shader.SetGlobalTexture("_RTMask", self._rtCamera.targetTexture)
            UnityEngine.Shader.SetGlobalTexture("_RTMask1", self._rtCamera.targetTexture)
        end
    )
end

function SeasonCameraBase:Update(deltaTime)
    if self._camera then
        local size = Mathf.Lerp(self._camera.orthographicSize, self._cameraSize, deltaTime * self._cameraSizeSpeed)
        self._camera.orthographicSize = size
        self._rtCamera.orthographicSize = size
    end
    if self._cameraTransform then
        local position = self._cameraTransform.position
        if self._mode == SeasonCameraMode.Follow then
            position = Vector3(self._player:Position().x, self._cameraTransform.position.y, self._player:Position().z)
            position = Vector3.Lerp(self._cameraTransform.position, position, deltaTime * self._cameraSpeed)
        elseif self._mode == SeasonCameraMode.Drag then
            if self._targetPosition then
                position = Vector3.Lerp(self._cameraTransform.position, self._targetPosition, deltaTime * self._cameraSpeed)
            end
        end
        self._cameraTransform.position = self:ConstraintPosition(position)
    end
end

function SeasonCameraBase:Dispose()
    if not self._recordSize then
        SeasonTool:GetInstance():SetLocalDBFloat("SeasonCameraSize", self._camera.orthographicSize)
    end
    self._input.multiTouchEnabled = false
    self._camera = nil
    self._cameraTransform = nil
    self._player = nil
    self._targetPosition = nil
    self._deltaPosition = nil
    self._recordSize = nil
end

---@param mode SeasonCameraMode
function SeasonCameraBase:SwitchMode(mode)
    self._mode = mode
end

function SeasonCameraBase:Camera()
    return self._camera
end

function SeasonCameraBase:IsDraging()
    return self._draging
end

function SeasonCameraBase:Focus(position)
    self:SwitchMode(SeasonCameraMode.Drag)
    self:SetPosition(position)
end

---@return UnityEngine.Transform
function SeasonCameraBase:Transform()
    return self._cameraTransform
end

---@return UnityEngine.Vector3
function SeasonCameraBase:Position()
    return self._cameraTransform.position
end

function SeasonCameraBase:SetPosition(position)
    self._targetPosition = Vector3(position.x, self._cameraTransform.position.y, position.z)
end

function SeasonCameraBase:SetPositionForce()
    local position = Vector3(self._player:Position().x, self._cameraTransform.position.y, self._player:Position().z)
    self._cameraTransform.position = self:ConstraintPosition(position)
end

---@return UnityEngine.RenderTexture
function SeasonCameraBase:RenderTexture()
    return self._rtCamera.targetTexture
end

--根据地图的边缘计算给定坐标被约束后的坐标
---@param position Vector3
---@return Vector3
function SeasonCameraBase:ConstraintPosition(position)
    local aspect = self._camera.aspect
    local size = self._camera.orthographicSize
    local width = size * aspect
    local height = size
    local topLeft = Vector3(width, 0, -height)
    local bottomRight = Vector3(-width, 0, height)
    local expectTopLeft = topLeft + position
    local expectBottomRight = bottomRight + position
    if expectTopLeft.x >= self._mapLeft then
        position.x = self._mapLeft - width
    end
    if expectTopLeft.z <= self._mapTop then
        position.z = self._mapTop + height
    end
    if expectBottomRight.x <= self._mapRight then
        position.x = self._mapRight + width
    end
    if expectBottomRight.z >= self._mapBottom then
        position.z = self._mapBottom - height
    end
    return position
end

function SeasonCameraBase:Size()
    return self._camera.orthographicSize
end

function SeasonCameraBase:MinSize()
    return self._cameraSizeMin
end

function SeasonCameraBase:MaxSize()
    return self._cameraSizeMax
end

function SeasonCameraBase:SetSize(size)
    self._cameraSize = size
end

function SeasonCameraBase:GetSize()
    return self._cameraSize
end

function SeasonCameraBase:SetRecordSize(size)
    self._recordSize = size
end

function SeasonCameraBase:GetRecordSize()
    return self._recordSize
end