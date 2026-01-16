--[[
    风船摄像机，手势与摇杆共同控制
]]
---@class AircraftCamera:Object
_class("AircraftCamera", Object)
AircraftCamera = AircraftCamera

function AircraftCamera:Constructor()
    --跟随参数
    self._lerpValue = Cfg.cfg_aircraft_camera["lerpParam"].Value
    --聚焦星灵时的z坐标
    self._clickPetPosZ = Cfg.cfg_aircraft_camera["clickPetPosZ"].Value
    --点击1次返回，返回的z坐标
    self._backPosZ = Cfg.cfg_aircraft_camera["backPosZ"].Value
    --视野顶部距离
    self._topDistance = Cfg.cfg_aircraft_camera["mainTopDistance"].Value
    --装扮全景视野能看到的顶部距离
    self._decorateTopDistance = Cfg.cfg_aircraft_camera["decorateTopDistance"].Value
    --相机能拉到的最近距离绝对值
    self._nearDistance = Cfg.cfg_aircraft_camera["mainNearDistance"].Value
    --最远时的拖拽系数
    self._dragParamFar = Cfg.cfg_aircraft_camera["mainDragParamFar"].Value
    --最近时的拖拽系数
    self._dragParamNear = Cfg.cfg_aircraft_camera["mainDragParamNear"].Value
    --缩放系数
    self._zoomParam = Cfg.cfg_aircraft_camera["mainZoomParam"].Value
    --相机抬起时的距离
    self._riseUpDistance = Cfg.cfg_aircraft_camera["riseUpDistance"].Value
    --相机抬起的最大高度
    self._riseUpMaxY = Cfg.cfg_aircraft_camera["riseUpMaxY"].Value
    --最小fov
    self._minFov = Cfg.cfg_aircraft_camera["minFov"].Value
    --最大fov
    self._maxFov = Cfg.cfg_aircraft_camera["maxFov"].Value
    --摇杆系数
    self._joyStickParam = Cfg.cfg_aircraft_camera["joyStickDragParam"].Value
    --摇杆拉动，相机水平最大角度（y轴）
    self._joyStickAngleVer = Cfg.cfg_aircraft_camera["joyStickAngleVertical"].Value
    --摇杆拉动，相机竖直最大角度（x轴）
    self._joyStickAngleHor = Cfg.cfg_aircraft_camera["joyStickAngleHorizontal"].Value
    --能点击到熔炼炉的位置
    self._clickSmeltPosZ = Cfg.cfg_aircraft_camera["uiHidePosX"].Value
    --能点击到书架的位置
    self._clickBookShelfPosZ = Cfg.cfg_aircraft_camera["clickBookShelfPosZ"].Value
    --能点击到派遣任务地图的位置
    self._clickDispatchTaskMapPosZ = Cfg.cfg_aircraft_camera["clickDispatchTaskMapPosZ"].Value
    --fov改变参数
    self._fovParam = Cfg.cfg_aircraft_camera["fovScaleParam"].Value
    --fov最小时相机拖拽参数
    self._minFovDragParam = Cfg.cfg_aircraft_camera["minFovDragParam"].Value
    --默认宽高比，16：9
    self._defaultAspect = BattleConst.CameraDefaultAspect
end

---@param camera UnityEngine.Camera
function AircraftCamera:Init(camera, input, clickCallback)
    ---@type UnityEngine.Camera
    self._camera = camera
    ---@type UnityEngine.Camera
    self._hudCamera = self._camera.transform:GetChild(0).gameObject:GetComponent(typeof(UnityEngine.Camera))
    ---@type AircraftInputManager
    self._input = input
    self._clickCB = clickCallback

    --手势操作--
    self._fovT = 1
    --end--

    --摇杆--
    --相机目标点
    self._cameraTarget = nil
    --相机距离
    self._distance = nil
    self._joyX = 0
    self._joyY = 0
    --end--

    --初始化一次位置
    self._currentPos = self._camera.transform.position
    self._currentRot = self._camera.transform.rotation

    self._active = true
    --相机动画
    ---@type AircraftCameraAnim
    self._anim = nil

    self._fov = self._maxFov
    camera.fieldOfView = self._fov
    self._hudCamera.fieldOfView = self._fov
    --当前设备宽高比
    self._aspect = camera.aspect

    --窄屏（4：3）时适配宽度
    if self._defaultAspect > self._aspect then
        --计算16：9时，可以看到的最大宽度
        local widthDistance = self._topDistance * self._defaultAspect
        --根据宽度适配，反算出当前设备最大高度
        self._topDistance = widthDistance / self._aspect
        self._decorateTopDistance = self._decorateTopDistance * self._defaultAspect / self._aspect
    end

    --正切
    self._tangent = math.tan(math.rad(self._fov / 2))
    --相机视野左边沿转动角度，与fov与宽高比有关
    self._horAngle = math.deg(math.atan(math.tan(math.rad(self._fov / 2) * self._aspect)))
    --相机最大视野
    self._field = Vector2(self._topDistance * self._aspect, self._topDistance)
    --相机最远距离绝对值
    self._farDistance = self._topDistance / self._tangent
    --装扮全景相机z轴距离
    self._decorateDistance = self._decorateTopDistance / self._tangent

    --目标点范围
    self._targetField = Vector2.zero
    local maxTargetY = self._topDistance - self._nearDistance * self._tangent
    --摄像机最近时，目标点的最大视野
    self._targetMaxField = Vector2(maxTargetY * self._aspect, maxTargetY)
    self:RefreshTarget()

    --正在改变fov聚焦
    self._focusing = false
end

--更新相机目标点
function AircraftCamera:RefreshTarget()
    local pos = self._currentPos
    local p1 = Vector3(pos.x, pos.y, 0)
    local dir = Vector3.forward * self._currentRot
    local nor = Vector3(0, 0, -1)
    local n =
        (nor.x * p1.x - nor.x * pos.x + nor.y * p1.y - nor.y * pos.y + nor.z * p1.z - nor.z * pos.z) /
        (nor.x * dir.x + nor.y * dir.y + nor.z * dir.z)
    self._cameraTarget = pos + dir * n
end

--根据一个摄像机的位置、朝向，计算视野是否超范围，超出视野返回true
function AircraftCamera:IsOutOfField(pos, dir)
    -- if pos.z > -self._nearDistance then
    --     return true
    -- end

    --旋转
    local rot = Quaternion.LookRotation(dir)
    local rightAxis = Vector3.right * rot
    local upAxis = Vector3.up * rot

    local left = self:GetRayPoint(pos, Quaternion.AngleAxis(-self._horAngle, upAxis) * dir)
    if not self:IsInEdge(left) then
        return true
    end
    local right = self:GetRayPoint(pos, Quaternion.AngleAxis(self._horAngle, upAxis) * dir)
    if not self:IsInEdge(right) then
        return true
    end
    local top = self:GetRayPoint(pos, Quaternion.AngleAxis(-self._fov / 2, rightAxis) * dir)
    if not self:IsInEdge(top) then
        return true
    end
    local bottom = self:GetRayPoint(pos, Quaternion.AngleAxis(self._fov / 2, rightAxis) * dir)
    if not self:IsInEdge(bottom) then
        return true
    end
    return false
end

function AircraftCamera:IsInEdge(p)
    if p.x > -self._field.x and p.x < self._field.x then
        if p.y > -self._field.y and p.y < self._field.y then
            return true
        end
    end
    return false
end

--射线与平面交点坐标
function AircraftCamera:GetRayPoint(pos, dir)
    local p1 = Vector3(pos.x, pos.y, 0)
    local nor = Vector3.back
    local n =
        (nor.x * p1.x - nor.x * pos.x + nor.y * p1.y - nor.y * pos.y + nor.z * p1.z - nor.z * pos.z) /
        (nor.x * dir.x + nor.y * dir.y + nor.z * dir.z)
    local p = pos + dir * n
    -- p.z = 0
    return p
end

---@param stick UIAircraftJoyStick
function AircraftCamera:SetStick(stick, onStart, focus, onEnd)
    ---@type UIAircraftJoyStick
    self._stick = stick
    stick.onBegin = function()
        self:RefreshTarget()
        self._joyX = self._camera.transform.eulerAngles.y
        self._joyY = -self._camera.transform.eulerAngles.x
        self._distance = Vector3.Distance(self._currentPos, self._cameraTarget)
        --发生了摇杆拖拽
        self._stickOffset = true
    end
    stick.onEnd = function()
        --返回拖拽结束是否显示归正按钮
        return not self:IsCamareAtFarPoint()
    end
    stick.onReset = function()
        self._stickOffset = false
        self._currentRot = Quaternion.identity
        local distance = Vector3.Distance(self._currentPos, self._cameraTarget)
        self._currentPos =
            self:_CalPos(Vector3(self._cameraTarget.x, self._cameraTarget.y, -distance), self._currentRot)
    end

    self._onFocusStart = onStart
    self._onFocusEnd = onEnd
    self._onFocuse = focus
end

function AircraftCamera:Dispose()
end

function AircraftCamera:SetActive(active)
    self._active = active
end

function AircraftCamera:Update(deltaTimeMS)
    if not self._active then
        return
    end

    if self._anim then
        self._anim:Update(deltaTimeMS)
        if self._anim:IsComplete() then
            self._anim = nil
            self:RefreshTarget()
        end
    else
        self._stick:Update(deltaTimeMS)

        local down, downPos = self._input:GetMouseDown()
        if down then
            local layers = 0
            if self._currentPos.z > self._clickSmeltPosZ then
                layers = layers | (1 << AircraftLayer.Smelt)
            end
            if self._currentPos.z > self._clickDispatchTaskMapPosZ then
                layers = layers | (1 << AircraftLayer.DispatchTaskMap)
            end
            if layers > 0 then
                local downRay = self._camera:ScreenPointToRay(downPos)
                local castRes, hitInfo = UnityEngine.Physics.Raycast(downRay, nil, 1000, layers)
                if castRes then
                    --统一处理鼠标按下描边效果
                    ---@type UIView
                    local view = hitInfo.transform.gameObject:GetComponent(typeof(UIView))
                    if view then
                        local outline = view:GetUIComponent("Animation", "outline")
                        if outline then
                            outline:Play("eff_fengchuan_outline_show")
                            self._outlineAnim = outline
                        end
                    end
                end
            end
        end

        local up, upPos = self._input:GetMouseUp()
        if up then
            if self._outlineAnim then
                self._outlineAnim:Play("eff_fengchuan_outline_fade")
                self._outlineAnim = nil
            end
        end

        --点击
        local clicked, clickPos = self._input:GetClick()
        --缩放
        local scaling, scaleLength, scaleCenterPos = self._input:GetScale()
        --拖拽
        local dragging, dragStartPos, dragEndPos = self._input:GetDrag()
        --摇杆
        local sticking, offset = self._stick:GetDrag()

        if clicked then
            local clickRay = self._camera:ScreenPointToRay(clickPos)
            -- 风船系统QA_领取材料逻辑修改
            --local layers = AircraftLayer.Default | (1 << AircraftLayer.Award)
            local layers = AircraftLayer.Default

            if self._currentPos.z > self._clickPetPosZ then
                --超过配置才能点击到星灵
                layers = layers | (1 << AircraftLayer.Pet)
            end
            if self._currentPos.z > self._clickSmeltPosZ then
                layers = layers | (1 << AircraftLayer.Smelt)
                layers = layers | (1 << AircraftLayer.Tactic) --与熔炼炉使用相同的距离配置
            end
            if self._currentPos.z > self._clickBookShelfPosZ then
                layers = layers | (1 << AircraftLayer.BookShelf)
            end
            if self._currentPos.z > self._clickDispatchTaskMapPosZ then
                layers = layers | (1 << AircraftLayer.DispatchTaskMap)
                -- 风船系统QA_领取材料逻辑修改
                layers = layers | (1 << AircraftLayer.Award)
            end

            local results = UnityEngine.Physics.RaycastAll(clickRay, 1000, layers)
            if results and results.Length > 0 then
                local t = {}
                for i = 1, results.Length do
                    t[i] = results[i - 1]
                end
                table.sort(
                    t,
                    function(a, b)
                        return a.distance < b.distance
                    end
                )
                self._clickCB(t)
                return
            end
        end

        if scaling then
            if self._focusing then
                --正在聚焦
                local delta = scaleLength * self._fovParam
                self:SetFovT(self._fovT - delta)
                self._onFocuse(self._fovT)
                if delta < 0 and self._fovT >= 1 then
                    self._focusing = false
                    self._onFocusEnd()
                end
            else
                --缩放
                local forward = Vector3.forward * self._currentRot
                local oz = self._currentPos.z
                local delta = forward * (scaleLength * self._zoomParam)
                local target = self._currentPos + delta

                if target.z > -self._nearDistance then
                    --拉到最近面
                    target.z = -self._nearDistance
                    self._currentPos = target
                else
                    --本次缩放超出边界
                    if self:IsOutOfField(target, forward) then
                        if delta.z < 0 then
                            if target.z <= -self._farDistance then
                                self._currentPos = Vector3(0, 0, -self._farDistance)
                                self._currentRot = Quaternion.identity
                            else
                                target.z = Mathf.Clamp(target.z, -self._farDistance, -self._nearDistance)

                                --超出边界，并且摄像机在拉远
                                local deltaZ = math.abs(target.z - oz)
                                local z = math.abs(oz)
                                local t = deltaZ / (self._farDistance - z)

                                --拉远归正
                                self._currentRot = Quaternion.Lerp(self._currentRot, Quaternion.identity, t)
                                self._currentPos = self:_CalPos(target, self._currentRot)
                            end
                        end
                        self:RefreshTarget()
                    else
                        self._currentPos = target
                    end
                end
                if self._currentPos.z > -self._nearDistance - 0.1 then
                    --开始聚焦
                    self._focusing = true
                    self._onFocusStart()
                end
            end
        elseif dragging then
            --拖拽
            local forward = Vector3.forward * self._currentRot
            local _dragParam = self:_CalDragParam(self._currentPos.z)
            local delta = (dragStartPos - dragEndPos) * _dragParam
            local target = self._currentPos + delta
            if self:IsOutOfField(target, forward) then
            else
                self._currentPos = target
                --更新相机目标点
                --拖拽会改变相机中心点
                self:RefreshTarget()
            end
        elseif sticking and not self:IsCamareAtFarPoint() then
            --摇杆
            local euler = self._currentRot.eulerAngles:Clone()
            local x = self._joyX + offset.x * self._joyStickParam
            local y = self._joyY + offset.y * self._joyStickParam
            -- --映射到-180~180，限制角度
            if x < -180 then
                x = x + 360
            elseif x > 180 then
                x = x - 360
            end
            if y < -180 then
                y = y + 360
            elseif y > 180 then
                y = y - 360
            end
            x = Mathf.Clamp(x, -self._joyStickAngleHor, self._joyStickAngleHor)
            y = Mathf.Clamp(y, -self._joyStickAngleVer, self._joyStickAngleVer)

            local rot = Quaternion.Euler(-y, x, 0)
            local target = rot * Vector3(0, 0, -self._distance) + self._cameraTarget
            local forward = Vector3.forward * rot
            if self:IsOutOfField(target, forward) then
            else
                self._currentPos = target
                self._currentRot = rot
                self._joyX = x
                self._joyY = y
            end
        end
    end

    local cur = self._camera.transform.position
    cur = Vector3.Lerp(cur, self._currentPos, self._lerpValue)
    self._camera.transform.position = cur

    if cur.z > -self._nearDistance - 0.1 and not self._showFocus then
        self._onFocusStart()
        self._showFocus = true
    elseif cur.z < -self._nearDistance - 0.1 and self._showFocus then
        self._onFocusEnd()
        self._showFocus = false
    end

    local curRot = self._camera.transform.rotation
    curRot = Quaternion.Lerp(curRot, self._currentRot, self._lerpValue)
    self._camera.transform.rotation = curRot
end

--计算1个抬起高度
function AircraftCamera:_CalRiseUp(z)
    --抬起
    local delta = z + self._riseUpDistance
    local riseUp = 0
    if delta < 0 then
    else
        local dis = -(z + self._nearDistance)
        riseUp = (1 - dis / (self._riseUpDistance - self._nearDistance)) * self._riseUpMaxY
    end
    return riseUp
end

--根据z坐标返回拖拽系数
function AircraftCamera:_CalDragParam(z)
    if self._fovT < 1 then
        return self._fovT * (self._dragParamNear - self._minFovDragParam) + self._minFovDragParam
    else
        local rate = (self._dragParamFar - self._dragParamNear) / (self._farDistance - self._nearDistance)
        return (math.abs(z) - self._nearDistance) * rate + self._dragParamNear
    end
end

--根据位置和旋转，计算出1个位置，使在保持旋转的情况下，相机被被限制到最大视野内
function AircraftCamera:_CalPos(pos, rot)
    local dir = Vector3.forward * rot
    local right = Vector3.right * rot
    local up = Vector3.up * rot

    local left = self:GetRayPoint(pos, Quaternion.AngleAxis(-self._horAngle, up) * dir)
    local top = self:GetRayPoint(pos, Quaternion.AngleAxis(-self._fov / 2, right) * dir)

    local x, y = 0
    if left.x < -self._field.x then
        x = -left.x - self._field.x
    else
        local right = self:GetRayPoint(pos, Quaternion.AngleAxis(self._horAngle, up) * dir)
        if right.x > self._field.x then
            x = self._field.x - right.x
        else
        end
    end

    if top.y > self._field.y then
        y = self._field.y - top.y
    else
        local bottom = self:GetRayPoint(pos, Quaternion.AngleAxis(self._fov / 2, right) * dir)
        if bottom.y < -self._field.y then
            y = -bottom.y - self._field.y
        else
        end
    end
    return Vector3(x, y, 0) + pos
end

function AircraftCamera:IsCamareAtFarPoint()
    return self._currentPos.z <= -self._farDistance
end

function AircraftCamera:IsFocusing()
    return self._focusing
end

--相机动画之前，设置状态，返回动画目标点位置和旋转
function AircraftCamera:OnAnimate(target)
    local riseUp = self:_CalRiseUp(target.z)
    local pos = target:Clone()
    pos.y = target.y + riseUp
    local rot = Quaternion.LookRotation(Vector3(0, -riseUp, -pos.z))
    pos = self:_CalPos(pos, rot)
    return pos, rot
end

function AircraftCamera:MoveAnim(target, callback, time)
    if self._anim then
        Log.exception("重复的相机动画:", debug.traceback())
    else
        AirLog("相机动画", debug.traceback())
    end

    local originPos = self._currentPos:Clone()
    local originRot = self._currentRot:Clone()
    local pos, rot = self:OnAnimate(target)
    if time then
        self._anim = AircraftCameraAnim:New(self, originPos, originRot, pos, rot, time, callback)
    else
        self._anim = AircraftCameraAnim:New(self, originPos, originRot, pos, rot, 700, callback)
    end
end

function AircraftCamera:SetCameraToNavMenuPos(pos)
    self._camera.transform.position = pos
    self._camera.transform.rotation = Quaternion.identity
end

--摄像机拉近时返回
function AircraftCamera:MoveBack(z)
    AirLog("相机动画，返回")
    local originPos = self._currentPos:Clone()
    local originRot = self._currentRot:Clone()
    self._currentRot = Quaternion.identity
    local target = Vector3(0, 0, z) --x、y都居中
    local pos, rot = self:OnAnimate(target)

    self._anim = AircraftCameraAnim:New(self, originPos, originRot, pos, rot, 700)
end

--摄像机返回最远处
function AircraftCamera:MoveToFar(callback)
    AirLog("相机动画，移向最远处")
    local originPos = self._currentPos:Clone()
    local originRot = self._currentRot:Clone()
    local pos = Vector3(0, 0, -self._farDistance)
    local rot = Quaternion.identity
    self._currentPos = pos
    self._currentRot = rot
    self._anim = AircraftCameraAnim:New(self, originPos, originRot, pos, rot, 700, callback)
end

--相机移动到某个点不固定时间
function AircraftCamera:MoveToPosNotTime(tpos, callback)
    AirLog("相机动画，移向某处,notTime")
    local originPos = self._currentPos:Clone()
    local originRot = self._currentRot:Clone()
    local pos = tpos
    local rot = Quaternion.identity
    self._currentPos = pos
    self._currentRot = rot
    self._anim = AircraftCameraAnimNotTime:New(self, originPos, originRot, pos, rot, 700, callback)
end

--取消聚焦动画
function AircraftCamera:CloseFocus(callback)
    AirLog("相机动画，关闭聚焦")
    if self._onFocusEnd then
        self._onFocusEnd()
    end
    self._focusing = false
    self._anim = AircraftCameraFovAnim:New(self, 1, callback)
end

--相机fov百分比
function AircraftCamera:SetFovT(t)
    self._fovT = Mathf.Clamp01(t)
    local fov = Mathf.Lerp(self._minFov, self._maxFov, self._fovT)
    self._fov = fov
    self._camera.fieldOfView = fov
    self._hudCamera.fieldOfView = fov
end

function AircraftCamera:SetHudCameraActive(active)
    self._hudCamera.gameObject:SetActive(active)
end

function AircraftCamera:SetPos(pos)
    self._currentPos = pos
end
function AircraftCamera:SetRot(rot)
    self._currentRot = rot
end

function AircraftCamera:Camera()
    return self._camera
end

function AircraftCamera:CameraFovPercent()
    return self._fovT
end

--最远点
function AircraftCamera:FarPoint()
    return Vector3(0, 0, -self._farDistance)
end

--装扮全景相机位置点
function AircraftCamera:DecorateViewPoint()
    return Vector3(0, 0, -self._decorateDistance)
end

function AircraftCamera:Reset()
    self._currentPos = self._camera.transform.position
    self._currentRot = self._camera.transform.rotation
end

function AircraftCamera:ResetFov()
    self:SetFovT(1)
end

function AircraftCamera:FocusPoint()
    return self._cameraTarget
end

-------------------------------------------------------------------
--[[
    相机控制器动画
]]
---@class AircraftCameraAnim:Object
_class("AircraftCameraAnim", Object)
AircraftCameraAnim = AircraftCameraAnim
---@param mainCam AircraftCamera
function AircraftCameraAnim:Constructor(camera, originPos, originRot, targetPos, targetRot, duration, onFinish)
    --所有摄像机动画加锁
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "AircraftCameraAnim")

    ---@type AircraftCamera
    self._cameraManager = camera
    self._transform = self._cameraManager:Camera().transform
    self._fromPos = originPos
    self._fromRot = originRot
    self._targetPos = targetPos
    self._targetRot = targetRot

    self._duration = duration
    self._onfinish = onFinish
    self._timer = 0
    self._completed = false

    self._pos = nil
    self._rot = nil
end
function AircraftCameraAnim:Update(deltaTimeMS)
    if self._completed then
        return
    end
    if self._timer < self._duration then
        local t = self._timer / self._duration
        self._timer = self._timer + deltaTimeMS

        self._cameraManager:SetPos(Vector3.Lerp(self._fromPos, self._targetPos, t))
        self._cameraManager:SetRot(Quaternion.Lerp(self._fromRot, self._targetRot, t))
    else
        self._cameraManager:SetPos(self._targetPos)
        self._cameraManager:SetRot(self._targetRot)
        self._completed = true
        --动画结束，解锁
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "AircraftCameraAnim")
        if self._onfinish then
            self._onfinish()
        end
    end
end
function AircraftCameraAnim:IsComplete()
    return self._completed
end

-------------------------------------------------------------------------------------------------
---@class AircraftCameraFovAnim:Object
_class("AircraftCameraFovAnim", Object)
AircraftCameraFovAnim = AircraftCameraFovAnim

function AircraftCameraFovAnim:Constructor(camera, speed, onFinish)
    ---@type AircraftCamera
    self._cameraManager = camera
    self._targetFov = 1 --固定从小到大变为1
    self._originFov = self._cameraManager:CameraFovPercent()
    self._speed = speed / 1000 --换算成毫秒
    self._onFinish = onFinish

    self._completed = false
    self._current = self._originFov
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "AircraftCameraFovAnim")
end
function AircraftCameraFovAnim:Update(deltaTimeMS)
    if self._completed then
        return
    end
    self._current = self._current + deltaTimeMS * self._speed
    if self._current < self._targetFov then
        self._cameraManager:SetFovT(self._current)
    else
        self._cameraManager:SetFovT(self._targetFov)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "AircraftCameraFovAnim")
        self._completed = true
        if self._onFinish then
            self._onFinish()
        end
    end
end

function AircraftCameraFovAnim:IsComplete()
    return self._completed
end
