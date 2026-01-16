---@class HomelandGlobalCameraController:Object
_class("HomelandGlobalCameraController", Object)
HomelandGlobalCameraController = HomelandGlobalCameraController

function HomelandGlobalCameraController:Constructor()
    self._resName = "HomelandGlobalCamControl"
    ---@type number 旋转移动系数
    self._rotateFacor = 5
    ---@type number X轴旋转最低角度
    self._minXAngle = 20
    ---@type number X轴旋转最高角度
    self._maxXAngle = 90
    ---@type number 焦点相对地面高度
    self._focusHeightOffset = 0
    ---@type number 缩放最近距离
    self._minScale = BuildConfig.Camera.ScaleMin
    ---@type number 缩放最远距离
    self._maxScale = BuildConfig.Camera.ScaleMax

    ---@type number 当前x轴转角
    self._xAngle = 0

    ---@type number 默认聚焦动画时长
    self._defaultFocusTime = 0.5

    self._lockCamera = nil --锁定摄像机
end

---@param homelandClient HomelandClient
function HomelandGlobalCameraController:Init(homelandClient)
    ---@type ResRequest
    self._resReq = ResourceManager:GetInstance():SyncLoadAsset(self._resName .. ".prefab", LoadType.GameObject)
    ---@type UnityEngine.GameObject
    self._camRootGO = self._resReq.Obj
    ---@type UnityEngine.Transform
    self._camRootTrans = self._camRootGO.transform
    ---@type UnityEngine.Transform
    self._camAxisXTrans = self._camRootTrans:GetChild(0)
    ---@type UnityEngine.Transform
    self._camTrans = self._camAxisXTrans:GetChild(0)
    self._camLocalPos = self._camTrans.localPosition
    self._initCamLocalPos = self._camLocalPos
    self._intCamLocalRotation = self._camTrans.localRotation

    self._xAngle = self._camAxisXTrans.localEulerAngles.x
    local runtimeRootTrans = homelandClient:SceneManager():RuntimeRootTrans()
    self._camRootTrans:SetParent(runtimeRootTrans)
    self._camRootGO:SetActive(false)
    self._cam = self._camRootGO:GetComponentInChildren(typeof(UnityEngine.Camera), false)
    self._focusHeightOffset = homelandClient:BuildManager():GetBuildHeight()
end

function HomelandGlobalCameraController:Dispose()
    self._resReq:Dispose()
    self._resReq = nil
    self._camRootGO = nil
    self._camRootTrans = nil
    self._camAxisXTrans = nil
end

---@return UnityEngine.Camera
function HomelandGlobalCameraController:CameraCmp()
    return self._cam
end

function HomelandGlobalCameraController:CameraFowardRay()
    ---@type UnityEngine.Transform
    local camTrans = self._cam.transform
    return Ray.New(camTrans.forward, camTrans.position)
end

---@return Vector3
function HomelandGlobalCameraController:GetFocusPos()
    return self._camRootTrans.position
end

---@return number 相机绝对坐标y值
function HomelandGlobalCameraController:GetCamHeight()
    return self._camTrans.position.y
end

function HomelandGlobalCameraController:SetLockCamera(lock)
    self._lockCamera = lock
end

---@param mx number 横向滑动
---@param my number 纵向滑动
function HomelandGlobalCameraController:HandleRotate(mx, my)
    if self._lockCamera then
        return
    end
    if mx ~= 0 then
        self._camRootTrans:Rotate(0, mx * self._rotateFacor, 0)
    end

    if my ~= 0 then
        local xAngle = self._xAngle - my * self._rotateFacor
        if xAngle > self._maxXAngle then
            xAngle = self._maxXAngle
        elseif xAngle < self._minXAngle then
            xAngle = self._minXAngle
        end

        self._camAxisXTrans.localRotation = Quaternion.Euler(xAngle, 0, 0)
        self._xAngle = xAngle
    end
end

---@param scale number
function HomelandGlobalCameraController:HandleScale(scale)
    if self._lockCamera then
        return
    end
    local newZ = self._camLocalPos.z + scale
    if newZ < self._minScale then
        newZ = self._minScale
    elseif newZ > self._maxScale then
        newZ = self._maxScale
    end

    self._camLocalPos.z = newZ
    self._camTrans.localPosition = self._camLocalPos
end

---@param pos Vector3
function HomelandGlobalCameraController:UpdatePos(pos, checkValid)
    if self._lockCamera then
        return
    end
    self._camRootTrans.position = Vector3(pos.x, self._focusHeightOffset, pos.z)
    --checkValid
    if checkValid then

        self._camLocalPos = self._initCamLocalPos
        self._camTrans.localPosition = self._camLocalPos
        self._camTrans.localRotation = self._intCamLocalRotation


        local xAngle = nil
        if self._xAngle > self._maxXAngle or self._xAngle < self._minXAngle  then
            xAngle = self._minXAngle + (self._maxXAngle - self._minXAngle) * 0.01
            self._camAxisXTrans.localRotation = Quaternion.Euler(xAngle, 0, 0)
            self._xAngle = xAngle
        end
    end
end

---@param pos Vector3
function HomelandGlobalCameraController:UpdatePosXZ(x, z)
    if self._lockCamera then
        return
    end
    self._camRootTrans.position = Vector3(x, self._focusHeightOffset, z)
end

---@param movement Vector3
function HomelandGlobalCameraController:Move(movement)
    if self._lockCamera then
        return
    end
    self._camRootTrans:Translate(movement, UnityEngine.Space.Self)
end

function HomelandGlobalCameraController:SetActive(active)
    self._camRootGO:SetActive(active)
end

function HomelandGlobalCameraController:Rotation()
    return self._camRootTrans.rotation
end

---@param transform UnityEngine.Transform
---@param time number
function HomelandGlobalCameraController:Focus(transform, time,callback)
    local focusTime = time
    if not focusTime then
        focusTime = self._defaultFocusTime
    end

    local position = transform.position
    local rotation = transform.rotation
    local forward = transform.forward

    local rotationY = transform.eulerAngles
    local rotationX = transform.eulerAngles

    rotationY.x = 0
    rotationX.y = 0

    GameGlobal.UIStateManager():Lock("HomelandGlobalCameraController:Focus")
    self._camTrans:DOMove(position, focusTime, false)
    self._camTrans:DORotateQuaternion(rotation, focusTime):OnComplete(
        function()
            local planePoint = self._camRootTrans.position
            local forward = forward.normalized

            local dot = Vector3.Dot(forward, Vector3.up)
            if dot == 0 then
                Log.fatal("Focus 焦点配置点不合法")
            else
                local d = Vector3.Dot(planePoint - position, Vector3.up) / dot
                self._camRootTrans.position = forward * d + position
                self._camRootTrans.eulerAngles = rotationY
                self._camAxisXTrans.localEulerAngles = rotationX

                self._camTrans.position = position
                self._camTrans.rotation = rotation
                self._camLocalPos = self._camTrans.localPosition

                self._xAngle = self._camAxisXTrans.localEulerAngles.x

            end
            GameGlobal.UIStateManager():UnLock("HomelandGlobalCameraController:Focus")
            if callback then 
                callback()
            end 
        end
    )
end


function HomelandGlobalCameraController:FocusDirect(transform)
    local position = transform.position
    local rotation = transform.rotation
    local forward = transform.forward

    local rotationY = transform.eulerAngles
    local rotationX = transform.eulerAngles

    rotationY.x = 0
    rotationX.y = 0

    self._camTrans.position = position;
    self._camTrans.rotation = rotation;
    local planePoint = self._camRootTrans.position
    local forward = forward.normalized
    local dot = Vector3.Dot(forward, Vector3.up)
    if dot == 0 then
        Log.fatal("FocusDirect 焦点配置点不合法")
    else
        local d = Vector3.Dot(planePoint - position, Vector3.up) / dot
        self._camRootTrans.position = forward * d + position
        self._camRootTrans.eulerAngles = rotationY
        self._camAxisXTrans.localEulerAngles = rotationX

        self._camTrans.position = position
        self._camTrans.rotation = rotation
        self._camLocalPos = self._camTrans.localPosition

        self._xAngle = self._camAxisXTrans.localEulerAngles.x
    end
end

function HomelandGlobalCameraController:ScalePercent()
    return (self._maxScale - self._camLocalPos.z) / (self._maxScale - self._minScale)
end

---仅供引导使用
---@param mx number 横向滑动
---@param my number 纵向滑动
function HomelandGlobalCameraController:ForceSetRotation(mx, my)
    self._camAxisXTrans.localRotation = Quaternion.Euler(my, 0, 0)
    self._camRootTrans.eulerAngles = Vector3(0, mx, 0)
end