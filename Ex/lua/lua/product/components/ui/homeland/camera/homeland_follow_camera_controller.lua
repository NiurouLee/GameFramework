---@class HomelandFollowCameraController:Object
_class("HomelandFollowCameraController", Object)
HomelandFollowCameraController = HomelandFollowCameraController

function HomelandFollowCameraController:Constructor()
    ---@type number navmesh layer
    self._navmeshLayer = (1 << 21) + (1 << 22)
    ---region 静态配置
    self._resName = "HomelandFollowCamControl"

    ---@type number 相对角色偏移高度初始值
    self._OffsetYStart = 1.28
    ---@type number 水平旋转移动系数
    self._rotateFacorX = 5
    ---@type number 垂直旋转移动系数
    self._rotateFacorY = 5
    ---@type number X轴旋转最低角度
    self._minXAngle = -20
    ---@type number X轴旋转最高角度
    self._maxXAngle = 60
    ---@type number 缩放最远距离
    self._minScale = -9.5
    ---@type number 缩放最近距离
    self._maxScale = -3.5

    ---@type number 主角半透开始距离
    self._transparentStartScale = -3
    ---@type number 主角透明度0距离
    self._transparentZeroScale = -1

    ---@type number 建筑透明度参数 近点 远点
    self._buildTransparentNear = 1
    ---@type number
    self._buildTransparentFar = 5

    ---@type number 光灵透明度参数 近点 远点
    self._petTransparentNear = 0.5
    ---@type number
    self._petTransparentFar = 4

    ---@type number 初始fov 加载相机prefab后读取
    self._fovInit = 0
    ---@type number 近平面距离 加载后读取
    self._near = 0.3
    ---region 静态配置 end

    ---region 动态配置
    ---相机相对偏移下移控制参数:当相机拉近到一定距离后，偏移高度开始跟随降低
    ---@type number 偏移高度开始变化的距离
    self._offsetYReduceStartScale = -8
    ---@type number 偏移高度最低值
    self._offsetYMin = 1.1
    ---@type number 缩放范围
    self._offsetYScaleRange = self._maxScale - self._offsetYReduceStartScale

    ---相机fov控制参数：当相机拉近到一定距离后，fov开始跟随减小
    ---@type number fov开始变化的距离
    self._fovReduceStartScale = -8
    ---@type number fov最低值
    self._fovMin = 25
    ---@type number 缩放范围
    self._fovScaleRange = self._maxScale - self._fovReduceStartScale

    ---冲刺效果参数：冲刺时fov变大，相机距离拉远，然后在冲刺过程中线性回归
    ---@type number fov变大值
    self._dashFovIncrementBase = 0
    ---@type number 距离变大值，建议给负数
    self._zOffsetIncrementBase = 0
    ---region 动态配置 end

    ---region 运行时数据
    ---@type Vector3 相对角色偏移
    self._focusOffset = Vector3(0, self._OffsetYStart, 0)
    ---@type Vector3 当前锁定的位置
    self._focusPos = nil
    ---@type number 当前x轴转角
    self._xAngle = 0
    ---@type number 当前fov 不含冲刺导致的变化
    self._fov = 0
    ---@type number 当前相机距离 不含冲刺导致的变化
    self._zOffset = 0

    ---@type number 当前冲刺导致的fov变大值
    self._dashFovIncrement = 0
    ---@type number 当前冲刺导致的距离变大值
    self._zOffsetIncrement = 0

    ---@type table<FadeComponent, boolean> 在半透状态的组件列表 离开范围要还原状态
    self._fadeCmptDic = {}

    ---@type number 默认聚焦动画时长
    self._defaultFocusTime = 0.5
    ---@type boolean 是否聚焦状态
    self._focusState = false
    ---@type Vector3 聚焦前相机位置
    self._camPosBeforeFocus = nil
    ---@type Vector3 聚焦前相机旋转
    self._camRotBeforeFocus = nil
    ---@type Vector3 聚焦前相机角度
    self._camAnglesBeforeFocus = nil

    ---@type boolean 需要同步相机节点坐标
    self._needSyncCamPos = false

    ---@type boolean 是否是透明状态
    self._isTransparent = false
    ---region 运行时数据 end
end

---@param homelandClient HomelandClient
function HomelandFollowCameraController:Init(homelandClient)
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
    ---@type UnityEngine.Transform
    self._camActorLightDirTrans = self._camTrans:GetChild(0)
    ---@type UnityEngine.Transform
    self._camPosTrans = self._camAxisXTrans:GetChild(1)
    ---@type UnityEngine.Transform
    self._camNearPlanePos = self._camPosTrans:GetChild(0)
    ---@type UnityEngine.Transform
    self._camNearPlaneBottomPos = self._camNearPlanePos:GetChild(0)
    self._camPosTrans.localPosition = self._camTrans.localPosition

    local positionz=LocalDB.GetInt("homeland_follow_camera_position", -455)
    self._camPosTrans.localPosition = Vector3(0,0,positionz/100)
    self._zOffset = self._camPosTrans.localPosition.z
    self._vecNearCenter2Botton = self._camNearPlaneBottomPos.position - self._camNearPlanePos.position

    self._xAngle = self._camAxisXTrans.localEulerAngles.x
    self._ori_xAngle = self._xAngle

    self._char = homelandClient:CharacterManager():MainCharacterController()
    local mainCharTrans = self._char:Transform()
    self._focusPos = mainCharTrans.position
    self._camRootTrans.position = self._focusPos + self._focusOffset
    self._camRootTrans.rotation = mainCharTrans.rotation

    self._sceneManager = homelandClient:SceneManager(self._camActorLightDirTrans)
    self._sceneManager:SetCustomLightTransform(self._camActorLightDirTrans)
    local runtimeRootTrans = self._sceneManager:RuntimeRootTrans()
    self._camRootTrans:SetParent(runtimeRootTrans)
    self._camRootGO:SetActive(true)
    ---@type UnityEngine.Camera
    self._camera = self._camRootGO:GetComponentInChildren(typeof(UnityEngine.Camera))
    self._fovInit = self._camera.fieldOfView
    self._fov = self._fovInit
    self._near = self._camera.nearClipPlane
    self._camNearPlanePos.localPosition = Vector3(0, 0, self._near)

    self:SyncCamLocalPos(self._camPosTrans.localPosition)

    ---@type HomeBuildManager
    self._HomelandBuildManager = homelandClient:BuildManager()
end

function HomelandFollowCameraController:Dispose()
    self._resReq:Dispose()
    self._resReq = nil
    self._camRootGO = nil
    self._camRootTrans = nil
    self._camAxisXTrans = nil
end

function HomelandFollowCameraController:Update()
    self._sceneManager:UpdateH3DRenderSetting()

    if self._focusState then
        return
    end

    if self._needSyncCamPos then
        --- 相机位置和半透使用两个方向的raycast计算 先执行挤开相机处理 再执行半透处理
        local camFocusPos = self._camAxisXTrans.position --self._focusPos:Clone()
        --camFocusPos.y = camFocusPos.y + self._OffsetYStart

        local nearPlaneBottomPos = self._camNearPlaneBottomPos.position --self._camNearPlaneBottomPos.position:Clone()
        --nearPlaneBottomPos.y = nearPlaneBottomPos.y - (self._focusOffset.y - self._OffsetYStart)

        local cameraPos = camFocusPos + self._vecNearCenter2Botton
        local hitList = self:GetHitList(cameraPos, nearPlaneBottomPos)
        local reversHitList = self:GetHitList(nearPlaneBottomPos, cameraPos)

        --[[
        local hitListLog = "hitlist count:"..#hitList.." "
        for i = 1, #hitList do
            hitListLog = hitListLog..hitList[i].distance.." "
        end
        Log.fatal(hitListLog)

        hitListLog = "reverseHitlist count:"..#reversHitList.." "
        for i = 1, #reversHitList do
            hitListLog = hitListLog..reversHitList[i].distance.." "
        end
        Log.fatal(hitListLog)
        ]]
        local j = #reversHitList

        --根据距离排序，近的在前面
        local function CompareDistance(hitInfo1, hitInfo2)
            --这里不适用hit.point，那点不准，因为射线是分段发射的，起点都不一样。这里统一使用相机的坐标计算距离
            local dis1 = Vector3.Distance(hitInfo1.point, cameraPos)
            local dis2 = Vector3.Distance(hitInfo2.point, cameraPos)
            return dis1 < dis2
        end
        table.sort(hitList, CompareDistance)

        local pushed = false
        if #hitList > 0 then
            for i = 1, #hitList do
                if j > 0 and reversHitList[j].transform == hitList[i].transform then
                    j = j - 1
                elseif self:ProcessRaycastPushCamera(hitList[i], hitList, cameraPos) then
                    pushed = true
                    break
                end
            end

            if not pushed then
                self:SyncCamLocalPos(self._camPosTrans.localPosition)
            end
        else
            self:SyncCamLocalPos(self._camPosTrans.localPosition)
        end

        for fadeCmpt, _ in pairs(self._fadeCmptDic) do
            self._fadeCmptDic[fadeCmpt] = false
        end
        ---@type RaycastHit[]
        hitList =
            UnityEngine.Physics.RaycastAll(
            self._camPosTrans.position,
            camFocusPos - self._camPosTrans.position,
            -self._zOffset
        )
        if hitList.Length > 0 then
            for i = 0, hitList.Length - 1 do
                self:ProcessRaycastTransparent(hitList[i])
            end
        end

        for fadeCmpt, bValue in pairs(self._fadeCmptDic) do
            if not bValue then
                self._fadeCmptDic[fadeCmpt] = nil
                fadeCmpt.Alpha = 1
            end
        end
    end
end

function HomelandFollowCameraController:GetHitList(startPoint, endPoint)
    local hitList = {}
    local rayStart = startPoint:Clone()
    local direction = Vector3.Normalize(endPoint - startPoint)

    while true do
        local dist = Vector3.Distance(rayStart, endPoint)
        if dist < 0.01 then
            return hitList
        end
        local res, hit = UnityEngine.Physics.Raycast(rayStart, direction, nil, dist, self._navmeshLayer)
        if res then
            --Log.fatal("hit point:"..tostring(rayStart))
            hitList[#hitList + 1] = hit
            rayStart = hit.point + direction / 100
        else
            return hitList
        end
    end
end

---@param raycastHit RaycastHit
function HomelandFollowCameraController:ProcessRaycastTransparent(raycastHit)
    ---@type UnityEngine.GameObject
    local go = raycastHit.transform.gameObject
    local name = go.name
    --Log.fatal("ProcessRaycastTransparent hit:"..name.." distance:"..raycastHit.distance.." collider type:"..raycastHit.collider:ToString())
    --- 检测是角色或可摆放建筑
    if name == "Bip001" then
        local root = go.transform.parent
        while true do
            if root.gameObject.name == "Root" then
                break
            else
                root = root.parent
                if not root then
                    break
                end
            end
        end
        if root then
            ---@type FadeComponent
            local fadeCmpt = root.gameObject:GetComponent(typeof(FadeComponent))
            if not fadeCmpt then
                fadeCmpt = root.gameObject:AddComponent(typeof(FadeComponent))
            end

            if raycastHit.distance < self._petTransparentNear then
                fadeCmpt.Alpha = 0
            elseif raycastHit.distance > self._petTransparentFar then
                fadeCmpt.Alpha = 1
            else
                fadeCmpt.Alpha =
                    (raycastHit.distance - self._petTransparentNear) /
                    (self._petTransparentFar - self._petTransparentNear)
            end

            self._fadeCmptDic[fadeCmpt] = true
        end
    end
end

---@param raycastHit RaycastHit
function HomelandFollowCameraController:ProcessRaycastPushCamera(raycastHit, hitList, cameraPos)
    -----@type UnityEngine.GameObject
    --local go = raycastHit.transform.gameObject
    --local name = go.name
    --Log.fatal("go.name:"..name)
    --Log.fatal("ProcessRaycastPushCamera hit:"..name.." distance:"..raycastHit.distance.." collider type:"..raycastHit.collider:ToString())
    --- 是场景或不可摆放建筑

    --To Do: 对于多个障碍物穿插的情况计算还是不准确----

    local targetHit = nil
    for i = 1, #hitList do
        ---@type RaycastHit
        local hit = hitList[i]
        if hit ~= raycastHit then
            --如果相机的坐标在这个hit点打到的碰撞内
            local collider = hit.collider
            local closestPoint = collider:ClosestPoint(self._camTrans.position)
            local dir = Vector3.Distance(closestPoint, self._camTrans.position)
            --这里不适用hit.point，那点不准，因为射线是分段发射的，起点都不一样。这里统一使用相机的坐标计算距离
            local hitDis = Vector3.Distance(hit.point, cameraPos)
            local raycastHitDis = Vector3.Distance(raycastHit.point, cameraPos)
            --并且这个碰撞的距离比传进来的点要近
            if dir <= 0 and hitDis < raycastHitDis then
                targetHit = hit
                break
            end
        end
    end
    if targetHit then
        raycastHit = targetHit
    end

    self._camTrans.position = raycastHit.point - self._vecNearCenter2Botton
    self:SyncCamLocalPos(Vector3(0, 0, self._camTrans.localPosition.z + 0.01))
    return true

    --[[
    if go.layer == HomeBuildLayer.Building then
        local homeBuilding = self._HomelandBuildManager:GetBuildingByCollider(raycastHit.collider)
        if not homeBuilding:CanMove() then
            if raycastHit.collider:ClosestPoint(self._camPosTrans.position) == self._camPosTrans.position then
                self._camTrans.position = raycastHit.point
                self:SyncCamLocalPos(Vector3(0, 0, self._camTrans.localPosition.z + 0.01))
                return true
            end
        end
    elseif name ~= "Bip001" and name ~= "TerrainPlain" and name ~= "DragPlain" then
        self._camTrans.position = raycastHit.point
        self:SyncCamLocalPos(Vector3(0, 0, self._camTrans.localPosition.z + 0.01))
        return true
    end
    return false]]
end

function HomelandFollowCameraController:SyncCamLocalPos(pos)
    self._camTrans.localPosition = pos

    local z = pos.z
    ---主角半透处理
    if z > self._transparentStartScale then
        local alpha =
            (lmathext.clamp(z, self._transparentStartScale, self._transparentZeroScale) - self._transparentZeroScale) /
            (self._transparentStartScale - self._transparentZeroScale)

        self._char:SetAlpha(alpha)
        self._isTransparent = true
    elseif self._isTransparent then
        self._char:SetAlpha(1)
        self._isTransparent = false
    end

    ---相机下移
    local offsetY = lmathext.lerp(self._offsetYMin, self._OffsetYStart, (self._maxScale - z) / self._offsetYScaleRange)
    self._focusOffset.y = offsetY
    self:_UpdatePosInternal()

    ---相机fov
    local fov = lmathext.lerp(self._fovMin, self._fovInit, (self._maxScale - z) / self._fovScaleRange)
    self._fov = fov
    self:_UpdateFovInternal()

    self._needSyncCamPos = false
end

--修改相机点的偏移
function HomelandFollowCameraController:SetHandleOffset(offsetPos)
    self._camAxisXTrans.localPosition = offsetPos
end

---@param mx number 横向滑动
---@param my number 纵向滑动
function HomelandFollowCameraController:HandleRotate(mx, my)
    if self._focusState then
        return
    end

    if mx == 0.0 and my == 0.0 then
        return
    end

    if mx ~= 0 and self._camRootTrans then
        self._camRootTrans:Rotate(0, mx * self._rotateFacorX, 0)
    end

    if my ~= 0 and self._camRootTrans then
        local xAngle = self._xAngle - my * self._rotateFacorY
        if xAngle > self._maxXAngle then
            xAngle = self._maxXAngle
        elseif xAngle < self._minXAngle then
            xAngle = self._minXAngle
        end

        self._camAxisXTrans.localRotation = Quaternion.Euler(xAngle, 0, 0)
        self._xAngle = xAngle
    end

    self._needSyncCamPos = true
end
function HomelandFollowCameraController:SetXRotation(xAngle)
    if self._focusState then
        return
    end

    local _xAngle = xAngle
    if _xAngle > self._maxXAngle then
        _xAngle = self._maxXAngle
    elseif _xAngle < self._minXAngle then
        _xAngle = self._minXAngle
    end
    self._camAxisXTrans.localRotation = Quaternion.Euler(_xAngle, 0, 0)
    self._xAngle = _xAngle
end

---@param scale number
function HomelandFollowCameraController:HandleScale(scale)
    if self._stopScale or self._focusState then
        return
    end
    local newZ = self._zOffset + scale
    if newZ < self._minScale then
        newZ = self._minScale
    elseif newZ > self._maxScale then
        newZ = self._maxScale
    end
    self._zOffset = newZ
    LocalDB.SetInt( "homeland_follow_camera_position", newZ*100)
    self:_UpdateScaleInternal()
end
---@param scale number
function HomelandFollowCameraController:HandleScaleForStory(z)
    local newZ = z
    if newZ < self._minScale then
        newZ = self._minScale
    elseif newZ > self._maxScale then
        newZ = self._maxScale
    end
    self._zOffset = newZ
    self:_UpdateScaleInternal()
end

---@return Vector3
function HomelandFollowCameraController:CalcMovement(inputVec)
    return self._camRootTrans:TransformDirection(inputVec)
end

function HomelandFollowCameraController:GetFocusPos()
    return self._focusPos
end

---@param pos Vector3
function HomelandFollowCameraController:UpdatePos(pos)
    if self._focusState then
        return
    end
    self._focusPos = pos
    self:_UpdatePosInternal()
end

function HomelandFollowCameraController:_UpdatePosInternal()
    if self._focusPos then
        self._camRootTrans.position = self._focusPos + self._focusOffset
    end
    self._needSyncCamPos = true
end

function HomelandFollowCameraController:_UpdateFovInternal()
    self._camera.fieldOfView = self._fov + self._dashFovIncrement
end

function HomelandFollowCameraController:_UpdateScaleInternal()
    self._camPosTrans.localPosition = Vector3(0, 0, self._zOffset + self._zOffsetIncrement)
    self._needSyncCamPos = true
end

function HomelandFollowCameraController:SetActive(active)
    self._camRootGO:SetActive(active)

    if active then
        self._sceneManager:SetCustomLightTransform(self._camActorLightDirTrans)
    end
end

function HomelandFollowCameraController:Rotation()
    return self._camRootTrans.rotation
end
function HomelandFollowCameraController:Position()
    return self._camRootTrans.position
end
function HomelandFollowCameraController:CamPosition()
    return self._camTrans.position
end

function HomelandFollowCameraController:CameraCmp()
    return self._camera
end

--当前的z值
function HomelandFollowCameraController:CurrentScale()
    return self._zOffset
end
--不可以缩放
function HomelandFollowCameraController:StopCameraScale(hide)
    self._stopScale = hide
end
--还原垂直旋转
function HomelandFollowCameraController:OriXAngle()
    return self._ori_xAngle
end
function HomelandFollowCameraController:NowXAngle()
    return self._xAngle
end

function HomelandFollowCameraController:SetRotation(rot)
    self._camRootTrans.rotation = rot
end

function HomelandFollowCameraController:SetCamLocation(angleX, angelY, scale)
    local _xAngle = angleX
    if _xAngle > self._maxXAngle then
        _xAngle = self._maxXAngle
    elseif _xAngle < self._minXAngle then
        _xAngle = self._minXAngle
    end
    self._camAxisXTrans.localRotation = Quaternion.Euler(_xAngle, 0, 0)
    self._xAngle = _xAngle

    self._camRootTrans.localRotation = Quaternion.Euler(0, angelY, 0)

    local newZ = scale
    if newZ < self._minScale then
        newZ = self._minScale
    elseif newZ > self._maxScale then
        newZ = self._maxScale
    end
    self._zOffset = newZ

    self:_UpdateScaleInternal()
end

function HomelandFollowCameraController:UpdateDashProgress(progress)
    self._dashFovIncrement = lmathext.lerp(self._dashFovIncrementBase, 0, progress)
    self._zOffsetIncrement = lmathext.lerp(self._zOffsetIncrementBase, 0, progress)
    self:_UpdateFovInternal()
    self:_UpdateScaleInternal()
end

---@param transform UnityEngine.Transform
---@param time number
function HomelandFollowCameraController:Focus(transform, time, rotateCompleteCallback)
    if self._focusState then
        return
    end

    self._focusState = true
    self._camPosBeforeFocus = self._camTrans.transform.position
    self._camRotBeforeFocus = self._camTrans.transform.rotation

    local focusTime = time
    if not focusTime then
        focusTime = self._defaultFocusTime
    end

    if focusTime <= 0 then
        self._camTrans.transform.position = transform.position
        self._camTrans.transform.rotation = transform.rotation
        if rotateCompleteCallback then
            rotateCompleteCallback()
        end
        return
    end

    GameGlobal.UIStateManager():Lock("HomelandFollowCameraController:Focus")
    self._camTrans:DOMove(transform.position, focusTime, false)
    self._camTrans:DORotateQuaternion(transform.rotation, focusTime):OnComplete(
        function()
            GameGlobal.UIStateManager():UnLock("HomelandFollowCameraController:Focus")
            if rotateCompleteCallback then
                rotateCompleteCallback()
            end
        end
    )
end

---@param transform UnityEngine.Transform
---@param time number
function HomelandFollowCameraController:LeaveFocus(time, callback)
    if not self._focusState then
        return
    end

    local focusTime = time
    if not focusTime then
        focusTime = self._defaultFocusTime
    end

    if focusTime <= 0 then
        self._camTrans.transform.position = self._camPosBeforeFocus
        self._camTrans.transform.rotation = self._camRotBeforeFocus
        self._focusState = false
        if callback then
            callback()
        end
        return
    end

    GameGlobal.UIStateManager():Lock("HomelandFollowCameraController:LeaveFocus")
    self._camTrans:DOMove(self._camPosBeforeFocus, focusTime, false)
    self._camTrans:DORotateQuaternion(self._camRotBeforeFocus, focusTime):OnComplete(
        function()
            self._focusState = false
            if callback then
                callback()
            end
            GameGlobal.UIStateManager():UnLock("HomelandFollowCameraController:LeaveFocus")
        end
    )
end

function HomelandFollowCameraController:DoShake()
    self._camTrans:DOShakePosition(0.3, Vector3(0.1, 0.1, 0.1), 30, 45, false, true)
end

---@param transform UnityEngine.Transform
---@param time number
function HomelandFollowCameraController:FocusUseAngles(transform, time, rotateCompleteCallback)
    if self._focusState then
        return
    end

    self._focusState = true
    self._camPosBeforeFocus = self._camTrans.transform.position
    self._camRotBeforeFocus = self._camTrans.transform.rotation
    self._camAnglesBeforeFocus = self._camTrans.transform.eulerAngles

    local focusTime = time
    if not focusTime then
        focusTime = self._defaultFocusTime
    end

    if focusTime <= 0 then
        self._camTrans.transform.position = transform.position
        self._camTrans.transform.rotation = transform.rotation
        if rotateCompleteCallback then
            rotateCompleteCallback()
        end
        return
    end

    GameGlobal.UIStateManager():Lock("HomelandFollowCameraController:Focus")
    self._camTrans:DOMove(transform.position, focusTime, false)
    self._camTrans:DORotate(transform.eulerAngles, focusTime):OnComplete(
        function()
            GameGlobal.UIStateManager():UnLock("HomelandFollowCameraController:Focus")
            if rotateCompleteCallback then
                rotateCompleteCallback()
            end
        end
    )
end

---@param transform UnityEngine.Transform
---@param time number
function HomelandFollowCameraController:LeaveFocusUseAngles(time, callback)
    if not self._focusState then
        return
    end

    local focusTime = time
    if not focusTime then
        focusTime = self._defaultFocusTime
    end

    if focusTime <= 0 then
        self._camTrans.transform.position = self._camPosBeforeFocus
        self._camTrans.transform.rotation = self._camRotBeforeFocus
        self._focusState = false
        if callback then
            callback()
        end
        return
    end

    GameGlobal.UIStateManager():Lock("HomelandFollowCameraController:LeaveFocus")
    self._camTrans:DOMove(self._camPosBeforeFocus, focusTime, false)
    self._camTrans:DORotate(self._camAnglesBeforeFocus, focusTime):OnComplete(
        function()
            self._focusState = false
            if callback then
                callback()
            end
            GameGlobal.UIStateManager():UnLock("HomelandFollowCameraController:LeaveFocus")
        end
    )
end
