---@class HomelandAquariumFishModel:Object
_class("HomelandAquariumFishModel", Object)
HomelandAquariumFishModel = HomelandAquariumFishModel

function HomelandAquariumFishModel:Constructor(buildTran, id, instanceId, buildID, buildAquarium)
    self._id = id
    self._instaceId = instanceId
    local fishCfg = Cfg.cfg_item_homeland_fish[id]
    local prefabName = fishCfg.Model .. ".prefab"
    self._req = ResourceManager:GetInstance():SyncLoadAsset(prefabName, LoadType.GameObject)
    if not self._req then
        BuildError("找不到鱼模型:" .. prefabName)
        return
    end

    ---@type HomelandAquarium
    self._buildAquarium = buildAquarium

    --可以游动的区域高度
    local activityArea = Cfg.cfg_item_aquarium_area[buildID].ActivityArea
    self._activityArea = {activityArea[3], activityArea[4]}

    local birthPos = Cfg.cfg_item_aquarium_area[buildID].BirthPos
    self._birthPos = Vector3(birthPos[1], birthPos[2], birthPos[3])

    self._fishingAreaPointList = self:GetFishingAreaPolygon(buildTran)

    self._go = self._req.Obj
    self._go:SetActive(true)
    self._transform = self._req.Obj.transform

    local root = GameObjectHelper.FindChild(buildTran, "FishRoot")
    self._transform:SetParent(root)
    self._transform.localPosition = self:CalcInitPos(buildTran)
    self._transform.localRotation = Quaternion.identity
    local scale = fishCfg.Scaling[1]
    self._transform.localScale = Vector3(scale, scale, scale)

    self._dir = self:CalcInitDir()

    self._moveSpeed = fishCfg.AquariumMoveSpeed / 1000
    self._idleSpeed = fishCfg.AquariumMoveSpeed / 5000
    self._speed = self._moveSpeed

    self._buildCenter = root.position

    self._lastChangeDirTime = GameGlobal:GetInstance():GetCurrentTime()

    ---目标转向
    self._targetDir = Vector3.zero
    ---正在转向中
    self._changingDir = false

    ---转向需要的时间
    self._changeDirLen = 300
    self._changeDirStartTime = nil

    self._fishState = 1 ---鱼的状态，1移动，2待机

    --连续碰撞的次数
    self._crashCount = 0

    self._lastCrashCollider = nil

    ----------------------------------------------移动参数-----------------------------------------------------------------------------
    self._moveStartTime = GameGlobal:GetInstance():GetCurrentTime() ---启动时间

    self._moveTimeRange = {10000, 20000} ---移动时长范围
    self._moveLen = Mathf.Random(self._moveTimeRange[1], self._moveTimeRange[2]) ---移动的时长

    self._moveChangeDirInternalRange = {10000, 20000} ---移动过程中转向的间隔范围
    local moveChangeDirInternal = Mathf.Random(self._moveChangeDirInternalRange[1], self._moveChangeDirInternalRange[2]) ---移动过程中的转向的间隔

    self._moveChangeDirLenRange = {300, 500} ---移动过程中的转向需要的时间范围
    local moveChangeDirLen = Mathf.Random(self._moveChangeDirLenRange[1], self._moveChangeDirLenRange[2])

    self._moveChangeDirRange = {-50, 50, -10, 10, -50, 50}

    self._moveRefreshFrameCount = 2 --检测碰撞频率
    ----------------------------------------------待机参数-----------------------------------------------------------------------------
    self._idleStartTime = 0

    self._idleTimeRange = {10000, 20000} ---待机时长范围
    self._idleLen = Mathf.Random(self._idleTimeRange[1], self._idleTimeRange[2]) ---待机时长

    self._idleChangeDirInternalRange = {10000, 20000} ---待机过程中的转向间隔范围
    local idleChangeDirInternal = Mathf.Random(self._idleChangeDirInternalRange[1], self._idleChangeDirInternalRange[2]) ---待机过程中的转向间隔

    self._idleChangeDirLenRange = {500, 1000} ---待机过程中的转向需要的时间范围
    local idleChangeDirLen = Mathf.Random(self._idleChangeDirLenRange[1], self._idleChangeDirLenRange[2])

    self._idleChangeDirRange = {-50, 50, -10, 10, -50, 50}

    self._idleRefreshFrameCount = 5
    ---------------------------------------------------------------------------------------------------------------------------

    self._changeDirLen = moveChangeDirLen ---当前的转向时长，默认取移动过程的数值
    self._changeDirInternal = moveChangeDirInternal ---当前转向间隔
    self._changeDirRange = self._moveChangeDirRange --当前转向角度的范围

    --转身后关闭碰撞的时间
    self._colseColliderTime = 1500
    self._lastColseColliderTime = 0
    self._turnRoundTimeRange = {400, 600} ---转身时长范围

    self._frameCount = 0
    self._targetRefreshFrameCount = self._moveRefreshFrameCount

    self._timerHandler =
        GameGlobal.Timer():AddEventTimes(
        1,
        TimerTriggerCount.Infinite,
        function()
            self:UpdateFish()
        end
    )
end

function HomelandAquariumFishModel:NotifyFishs(fishs)
    self._allFishs = fishs
end

function HomelandAquariumFishModel:CalcInitPos(buildTran)
    local fishingAreaObj = GameObjectHelper.FindChild(buildTran, "BirthRoot")
    local pointPosList = {}
    for i = 0, fishingAreaObj.childCount - 1 do
        local childTransform = fishingAreaObj:GetChild(i)
        pointPosList[#pointPosList + 1] = childTransform.localPosition
    end
    local count = #pointPosList
    local randomIndex = Mathf.Random(1, count)
    local pointPos = pointPosList[randomIndex]
    return pointPos
end

function HomelandAquariumFishModel:CalcInitDir()
    local targetDir = Vector3(Mathf.Random(-50, 50) / 10, 0, Mathf.Random(-50, 50) / 10).normalized
    local dirX = targetDir.x
    local dirZ = targetDir.z

    local randomDelta = Mathf.Random(-10, 10)

    local xOrz = Mathf.Random(0, 1)
    if xOrz > 0 then
        dirX = dirX + randomDelta
    else
        dirZ = dirZ + randomDelta
    end

    return Vector3(dirX, 0, dirZ).normalized
end

function HomelandAquariumFishModel:UpdateFish()
    --转向中
    if self._tweener then
        return
    end

    --如果水族箱不在相机范围内或者距离太远就不刷新
    local aquariumIsActive = self._buildAquarium:AquariumIsActive()
    if not aquariumIsActive then
        return
    end

    --不再每帧都刷新，刷新频率内就不再刷新
    if self._frameCount < self._targetRefreshFrameCount then
        self._frameCount = self._frameCount + 1
        --跳过碰撞检测 跳到游动部分
        self:OnMove()
        return
    end
    self._frameCount = 0

    --第一次跳过 等待动作开始播放 再添加碰撞
    if not self._collider and self._go and self._needInitBoxCollider then
        local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(self._go)
        --碰撞
        ---@type UnityEngine.BoxCollider
        self._collider = skinnedMeshRender.gameObject:AddComponent(typeof(UnityEngine.BoxCollider))
        self._collider.isTrigger = true
    end

    local isTriggerCollider = false
    self._crashActivityArea = {false, false}

    local currentTime = GameGlobal:GetInstance():GetCurrentTime()
    local curDelta = currentTime - self._lastColseColliderTime

    ---优先的朝向，在与假山静态碰撞后，会有这个值
    self._priorityDir = nil

    if curDelta > self._colseColliderTime then
        if self._collider then
            local onlyCalcFront = true
            local curGetBoxPoints = self:GetBoxPoints(self._collider, onlyCalcFront)

            local crashStone = false
            local crashFish = false

            -- for _, pos in ipairs(curGetBoxPoints) do
            --     if pos.y < self._activityArea[1] then
            --         self._crashActivityArea[1] = true
            --         isTriggerCollider = true
            --         break
            --     end
            --     if pos.y > self._activityArea[2] then
            --         self._crashActivityArea[2] = true
            --         isTriggerCollider = true
            --         break
            --     end
            -- end

            local curGetBoxPointsAll = self:GetBoxPoints(self._collider)
            for _, pos in ipairs(curGetBoxPointsAll) do
                if pos.y < self._activityArea[1] then
                    self._crashActivityArea[1] = true
                    isTriggerCollider = true
                    break
                end
                if pos.y > self._activityArea[2] then
                    self._crashActivityArea[2] = true
                    isTriggerCollider = true
                    break
                end
            end

            --检测所有装饰
            if not isTriggerCollider then
                for i, boxCollider in ipairs(self._staticColliderList) do
                    for _, pos in ipairs(curGetBoxPoints) do
                        -- local inRange, boxColliderName = self:CheckContains(boxCollider, pos, boxCollider.transform.name)

                        local inRange = false
                        local closestPoint = boxCollider:ClosestPoint(pos)
                        local dir = Vector3.Distance(closestPoint, pos)
                        if dir <= 0 then
                            inRange = true
                        end

                        if not inRange then
                            local curStaticBoxPoints = self._staticColliderVertexList[i]
                            for _, boxPos in ipairs(curStaticBoxPoints) do
                                closestPoint = self._collider:ClosestPoint(boxPos)
                                dir = Vector3.Distance(closestPoint, boxPos)
                                if dir <= 0 then
                                    inRange = true
                                    break
                                end
                            end
                        end

                        if inRange and self._lastCrashCollider ~= boxCollider then
                            self._priorityDir = self._transform.position - closestPoint
                            self._priorityDir.y = self._priorityDir.y + 0.1

                            isTriggerCollider = true
                            crashStone = true
                            -- Log.error("鱼: " .. self._transform.name .. "  碰撞 " .. boxCollider.transform.name)
                            self._lastCrashCollider = boxCollider
                            break
                        end
                    end

                    if isTriggerCollider then
                        break
                    end
                end
            end

            --检测所有鱼
            if self._allFishs and not isTriggerCollider then
                for i, fish in ipairs(self._allFishs) do
                    if fish ~= self and fish._collider then
                        for _, pos in ipairs(curGetBoxPoints) do
                            -- local inRange, boxColliderName = self:CheckContains(fish._collider, pos)
                            -- local points = self:GetBoxPoints(fish._collider)
                            -- local inRange = self:IsInRange(points, pos)

                            local inRange = false
                            local closestPoint = fish._collider:ClosestPoint(pos)
                            local dir = Vector3.Distance(closestPoint, pos)
                            if dir <= 0 then
                                inRange = true
                            end

                            if inRange and self._lastCrashCollider ~= fish._collider then
                                local boxColliderName = fish._collider.transform.name
                                isTriggerCollider = true
                                crashFish = true
                                -- Log.error("鱼: " .. self._transform.name .. "  碰撞 " .. boxColliderName)
                                self._lastCrashCollider = fish._collider

                                -- self._priorityDir = self._transform.position - closestPoint
                                break
                            end
                        end
                    end

                    if isTriggerCollider then
                        break
                    end
                end
            end
        end
    end

    self._isTriggerCollider = isTriggerCollider
    --这里如果连续几次转弯后都有碰撞 设置角度朝向上
    if not isTriggerCollider then
        self._lastCrashCollider = nil
        self._crashCount = 0
    else
        self._crashCount = self._crashCount + 1
    end

    self:OnMove()
end

function HomelandAquariumFishModel:OnMove()
    if self._fishState == 1 then
        self:CheckMoveToIdle()
    elseif self._fishState == 2 then
        self:CheckIdleToMove()
    end

    self:Move()

    self._needInitBoxCollider = true
end

function HomelandAquariumFishModel:CheckMoveToIdle()
    local currentTime = GameGlobal:GetInstance():GetCurrentTime()
    local curDelta = currentTime - self._moveStartTime
    if curDelta > self._moveLen then
        self._fishState = 2 ---切换到Idle
        self._speed = self._idleSpeed

        self._idleLen = Mathf.Random(self._idleTimeRange[1], self._idleTimeRange[2]) ---待机时长
        self._idleStartTime = currentTime

        local idleChangeDirLen = Mathf.Random(self._idleChangeDirLenRange[1], self._idleChangeDirLenRange[2])
        local idleChangeDirInternal =
            Mathf.Random(self._idleChangeDirInternalRange[1], self._idleChangeDirInternalRange[2])
        self._changeDirLen = idleChangeDirLen ---当前的转向时长，默认取移动过程的数值
        self._changeDirInternal = idleChangeDirInternal ---当前转向间隔

        self._changeDirRange = self._idleChangeDirRange

        self._targetRefreshFrameCount = self._moveRefreshFrameCount
    end
end

function HomelandAquariumFishModel:CheckIdleToMove()
    local currentTime = GameGlobal:GetInstance():GetCurrentTime()
    local curDelta = currentTime - self._idleStartTime
    if curDelta > self._idleLen then
        self._fishState = 1 ---切换到Move
        self._speed = self._moveSpeed

        self._moveLen = Mathf.Random(self._moveTimeRange[1], self._moveTimeRange[2])
        self._moveStartTime = currentTime

        local moveChangeDirLen = Mathf.Random(self._moveChangeDirLenRange[1], self._moveChangeDirLenRange[2])
        local moveChangeDirInternal =
            Mathf.Random(self._moveChangeDirInternalRange[1], self._moveChangeDirInternalRange[2])
        self._changeDirLen = moveChangeDirLen ---当前的转向时长，默认取移动过程的数值
        self._changeDirInternal = moveChangeDirInternal ---当前转向间隔

        self._changeDirRange = self._moveChangeDirRange

        self._targetRefreshFrameCount = self._idleRefreshFrameCount
    end
end

function HomelandAquariumFishModel:Move()
    --转向中
    if self._tweener then
        return
    end

    --掉头转向中
    if self._isTriggerCollider then
        self:DoTurnRound()
    end

    if self._tweener then
        return
    end

    if self._changingDir then
        --转向中
        self:DoChangeDir()
    else
        --随机小转向
        self:RandomMoveDir()
    end

    -- local nextPos = self._transform.position + self._dir.normalized * self._speed * UnityEngine.Time.deltaTime
    local nextPos = self._transform.position + self._dir * self._speed * UnityEngine.Time.deltaTime

    local inFishingArea = self:IsFishInArea(nextPos, self._fishingAreaPointList)
    if inFishingArea and self._collider then
        local onlyCalcFront = true
        local curGetBoxPoints = self:GetBoxPoints(self._collider, onlyCalcFront)
        for _, pos in ipairs(curGetBoxPoints) do
            inFishingArea = self:IsFishInArea(pos, self._fishingAreaPointList)
            if not inFishingArea then
                break
            end
        end
    end

    if not inFishingArea then
        local currentTime = GameGlobal:GetInstance():GetCurrentTime()
        local curDelta = currentTime - self._lastColseColliderTime
        if curDelta > self._turnRoundTimeRange[1] then
            self._dir = (self._buildCenter - self._transform.position).normalized

            local dirX = self._dir.x
            local dirZ = self._dir.z
            local dirY = self._dir.y

            local randomDelta = Mathf.Random(-10, 10)
            local delta = randomDelta / 10

            local xOrz = Mathf.Random(0, 1)
            if xOrz > 0 then
                dirX = dirX + delta
            else
                dirZ = dirZ + delta
            end

            self._dir = Vector3(dirX, 0, dirZ).normalized
            self._changingDir = false
            local turnRoundTime = Mathf.Random(self._turnRoundTimeRange[1], self._turnRoundTimeRange[2]) / 1000
            if self._tweener then
                self._tweener:Kill()
            end
            self._tweener = nil
            self._tweener =
                self._transform:DORotate(Quaternion.LookRotation(self._dir).eulerAngles, turnRoundTime):OnComplete(
                function()
                    self._tweener = nil
                    -- self._dir = self._transform.forward
                    -- self._dir = Quaternion.LookRotation(self._transform.rotation)
                    -- self._dir = self._transform.rotation.eulerAngles
                    -- self._dir = self._transform.forward
                    -- self._dir = self._transform.rotation.eulerAngles.normalized
                    self._dir = self._transform.forward.normalized

                    self._lastChangeDirTime = GameGlobal:GetInstance():GetCurrentTime()
                    --转身后设置一个不可碰撞的时间
                    self._lastColseColliderTime = GameGlobal:GetInstance():GetCurrentTime()
                end
            )
        else
            if self._dir and self._dir ~= self._transform.forward.normalized then
                if self._dir ~= Vector3.zero then
                    self._transform.rotation = Quaternion.LookRotation(self._dir)
                end
            -- self._transform.eulerAngles = self._dir
            end
            self._transform.position = nextPos
        end
    else
        if self._dir and self._dir ~= self._transform.forward.normalized then
            if self._dir ~= Vector3.zero then
                self._transform.rotation = Quaternion.LookRotation(self._dir)
            end
        -- self._transform.eulerAngles = self._dir
        end
        self._transform.position = nextPos
    end

    --位移之后如果超出活动范围
    if self._collider then
        local isTriggerCollider = false
        local curGetBoxPointsAll = self:GetBoxPoints(self._collider)
        for _, pos in ipairs(curGetBoxPointsAll) do
            if pos.y < self._activityArea[1] then
                self._crashActivityArea[1] = true
                isTriggerCollider = true
                break
            end
            if pos.y > self._activityArea[2] then
                self._crashActivityArea[2] = true
                isTriggerCollider = true
                break
            end
        end

        if isTriggerCollider then
            -- if self._tweener then
            --     self._tweener:Kill()
            -- end
            -- self._tweener = nil
            -- self._priorityDir = nil
            local onlyX = true
            self:DoTurnRound(onlyX)
        end
    end
end

---定时随机一次方向
function HomelandAquariumFishModel:RandomMoveDir()
    local currentTime = GameGlobal:GetInstance():GetCurrentTime()
    local curDelta = currentTime - self._lastChangeDirTime
    if curDelta > self._changeDirInternal then
        self._lastChangeDirTime = currentTime
        local dirX = self._dir.x
        local dirZ = self._dir.z
        local dirY = self._dir.y

        local delataValueX = Mathf.Random(self._changeDirRange[1], self._changeDirRange[2]) / 10
        local delataValueY = Mathf.Random(self._changeDirRange[3], self._changeDirRange[4]) / 10
        local delataValueZ = Mathf.Random(self._changeDirRange[5], self._changeDirRange[6]) / 10

        dirX = dirX + delataValueX
        dirY = dirY + delataValueY
        dirZ = dirZ + delataValueZ

        self._targetDir = Vector3(dirX, dirY, dirZ).normalized
        self._changingDir = true
        self._changeDirStartTime = currentTime
    end
end

function HomelandAquariumFishModel:DoTurnRound(onlyX)
    if self._tweener then
        return
    end
    self._changingDir = false

    local newTargetAngles = Vector3(-self._dir.x, 0, -self._dir.z)
    if self._priorityDir then
        newTargetAngles = (self._priorityDir).normalized
        newTargetAngles = Quaternion.LookRotation(newTargetAngles).eulerAngles
    else
        local newTargetAnglesX = Mathf.Random(-50, 50) / 10
        --新角度是当前加上随机变化值
        newTargetAnglesX = self._transform.localEulerAngles.x + newTargetAnglesX

        --这3种情况强制设置角度  不在本来值上累加
        if self._crashCount >= 3 then
            newTargetAnglesX = Mathf.Random(-150, -50) / 10
        end
        if self._crashActivityArea[1] then
            --触底 抬头
            newTargetAnglesX = Mathf.Random(-150, -50) / 10
        elseif self._crashActivityArea[2] then
            --水面 低头
            newTargetAnglesX = Mathf.Random(50, 150) / 10
        end

        if newTargetAnglesX >= 20 then
            newTargetAnglesX = 20
        end
        if newTargetAnglesX <= -20 then
            newTargetAnglesX = -20
        end

        -- local newTargetAnglesY = self._transform.localEulerAngles.y + Mathf.Random(90, 270)
        -- if newTargetAnglesY > 360 then
        --     newTargetAnglesY = newTargetAnglesY - 360
        -- end
        local newTargetAnglesY = self._transform.localEulerAngles.y
        newTargetAngles = Vector3(newTargetAnglesX, newTargetAnglesY, self._transform.localEulerAngles.z)

        if self._crashCount >= 3 and self._lastCrashCollider then
            local dir = (self._lastCrashCollider.transform.position - self._transform.position).normalized
            newTargetAngles = Quaternion.LookRotation(dir).eulerAngles
        end
    end

    --给触底用的
    if onlyX then
        newTargetAngles =
            Vector3(newTargetAngles.x, self._transform.localEulerAngles.y, self._transform.localEulerAngles.z)
    end

    --所有用2个坐标的向量的normalized 求的的角度  都需要用Quaternion.LookRotation(dir).eulerAngles处理

    local turnRoundTime = Mathf.Random(self._turnRoundTimeRange[1], self._turnRoundTimeRange[2]) / 1000
    if self._tweener then
        self._tweener:Kill()
    end
    self._tweener = nil
    self._tweener =
        self._transform:DORotate(newTargetAngles, turnRoundTime):OnComplete(
        function()
            self._tweener = nil
            -- self._dir = self._transform.forward
            -- self._dir = Quaternion.LookRotation(self._transform.rotation)
            -- self._dir = self._transform.rotation.eulerAngles
            -- self._dir = self._transform.rotation.eulerAngles.normalized
            self._dir = self._transform.forward.normalized

            self._lastChangeDirTime = GameGlobal:GetInstance():GetCurrentTime()
            --转身后设置一个不可碰撞的时间
            self._lastColseColliderTime = GameGlobal:GetInstance():GetCurrentTime()
        end
    )
end

function HomelandAquariumFishModel:DoChangeDir()
    local dotVal = Vector3.Angle(self._dir, self._targetDir)
    if dotVal < 0.01 then
        self._changingDir = false
        return
    end

    local currentTime = GameGlobal:GetInstance():GetCurrentTime()
    local curDelta = currentTime - self._changeDirStartTime
    local dirRes = Vector3.Slerp(self._dir, self._targetDir, curDelta / self._changeDirLen)
    self._dir = dirRes
end

function HomelandAquariumFishModel:Destroy()
    if self._tweener then
        self._tweener:Kill()
        self._tweener = nil
    end
    self._go = nil
    self._transform = nil
    if self._req then
        self._req:Dispose()
    end
    self._req = nil
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._buildAquarium = nil
end

function HomelandAquariumFishModel:GetFishingAreaPolygon(buildTran)
    local fishingAreaObj = GameObjectHelper.FindChild(buildTran.transform, "AreaRoot")
    local areaNode = {}
    for i = 0, fishingAreaObj.childCount - 1 do
        local childTransform = fishingAreaObj:GetChild(i)
        areaNode[#areaNode + 1] = childTransform.position
    end

    local colliderRoot = GameObjectHelper.FindChild(buildTran.transform, "navmesh")
    self._staticColliderList = {}
    self._staticColliderVertexList = {}

    for i = 0, colliderRoot.childCount - 1 do
        local childTransform = colliderRoot:GetChild(i)
        local collider = childTransform:GetComponent(typeof(UnityEngine.BoxCollider))
        if collider then
            table.insert(self._staticColliderList, collider)

            local curGetBoxPoints = self:GetBoxPoints(collider)
            table.insert(self._staticColliderVertexList, curGetBoxPoints)
        end
    end

    return areaNode
end

---使用经典的ray crossing算法
function HomelandAquariumFishModel:IsFishInArea(fishPos, areaPointList)
    if not areaPointList then
        return
    end

    local crossNum = 0
    local areaPointCount = #areaPointList

    for i = 1, areaPointCount do
        local v1 = areaPointList[i]
        local nextIndex = i + 1
        if nextIndex > areaPointCount then
            nextIndex = 1
        end

        local v2 = areaPointList[nextIndex]
        if v2 == nil then
            Log.fatal("next index :", nextIndex, " i:", i)
        end

        local underZ = ((v1.z <= fishPos.z) and (v2.z > fishPos.z)) or ((v1.z > fishPos.z) and (v2.z <= fishPos.z))

        if underZ then
            ---根据tan关系算出交叉点
            local intersectX = v1.x + (fishPos.z - v1.z) / (v2.z - v1.z) * (v2.x - v1.x)
            if fishPos.x < intersectX then
                crossNum = crossNum + 1
            end
        end
    end

    if crossNum % 2 == 0 then
        return false
    else
        return true
    end
end

function HomelandAquariumFishModel:GetBoxPoints(collider, front)
    local vertices = {}
    --前 上
    vertices[1] =
        collider.transform:TransformPoint(
        collider.center + Vector3(collider.size.x, -collider.size.y, collider.size.z) * 0.5
    )
    vertices[2] =
        collider.transform:TransformPoint(
        collider.center + Vector3(-collider.size.x, -collider.size.y, collider.size.z) * 0.5
    )
    --前 下
    vertices[3] =
        collider.transform:TransformPoint(
        collider.center + Vector3(-collider.size.x, -collider.size.y, -collider.size.z) * 0.5
    )
    vertices[4] =
        collider.transform:TransformPoint(
        collider.center + Vector3(collider.size.x, -collider.size.y, -collider.size.z) * 0.5
    )
    if not front then
        --后 上
        vertices[5] =
            collider.transform:TransformPoint(
            collider.center + Vector3(collider.size.x, collider.size.y, collider.size.z) * 0.5
        )
        vertices[6] =
            collider.transform:TransformPoint(
            collider.center + Vector3(-collider.size.x, collider.size.y, collider.size.z) * 0.5
        )
        --后下
        vertices[7] =
            collider.transform:TransformPoint(
            collider.center + Vector3(-collider.size.x, collider.size.y, -collider.size.z) * 0.5
        )
        vertices[8] =
            collider.transform:TransformPoint(
            collider.center + Vector3(collider.size.x, collider.size.y, -collider.size.z) * 0.5
        )
    end

    return vertices
end
