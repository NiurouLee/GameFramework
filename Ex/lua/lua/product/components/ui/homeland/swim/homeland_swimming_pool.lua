---泳池，负责通知玩家/光灵进入游泳范围。
---筛选符合条件
---管理交互中的光灵
---@class HomelandSwimmingPool:HomeBuildingFather
_class("HomelandSwimmingPool", HomeBuildingFather)
HomelandSwimmingPool = HomelandSwimmingPool

---@param architecture Architecture
function HomelandSwimmingPool:Constructor(insID, architecture, cfg)
    self._isInited = false
end

function HomelandSwimmingPool:InitSwimmingPool(architecture)
    if self._isInited then
        return --地块的数据只初始化一次
    end

    ---@type UIHomelandModule
    self._uiModule = GameGlobal.GetUIModule(HomelandModule)
    self._isVisit = self._uiModule:GetClient():IsVisit() --是否为拜访

    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)

    self._pstid = architecture.pstid
    self._buildID = self:GetBuildId()
    self._transform = self:Transform()

    local cfgSwimmingPool = Cfg.cfg_homeland_swimming_pool[self._buildID]
    --水池的水面高度
    self._waterHeight = self._transform.position.y + cfgSwimmingPool.WaterHeight

    --获取泳池的通道
    local pathRoot = GameObjectHelper.FindChild(self._transform, "Path")

    --光灵用-碰撞围的可游泳范围
    local swimAreaRoot = GameObjectHelper.FindChild(self._transform, "PetSwimArea")
    if not swimAreaRoot then
        return
    end
    self._swimAreaCollider = swimAreaRoot:GetComponent(typeof(UnityEngine.BoxCollider))

    --主角用-碰撞围的可游泳范围
    local roleSwimAreaRoot = GameObjectHelper.FindChild(self._transform, "RoleSwimArea")
    if not roleSwimAreaRoot then
        return
    end
    self._roleSwimAreaCollider = roleSwimAreaRoot:GetComponent(typeof(UnityEngine.BoxCollider))

    --光灵用-碰撞围的建筑范围
    local poolAreaRoot = GameObjectHelper.FindChild(self._transform, "RolePoolArea")
    if not poolAreaRoot then
        return
    end
    self._poolAreaCollider = poolAreaRoot:GetComponent(typeof(UnityEngine.CapsuleCollider))


    self._pathList = {}
    for i = 0, pathRoot.childCount - 1 do
        local childTransform = pathRoot:GetChild(i)
        self._pathList[#self._pathList + 1] = childTransform
    end

    --正在来的路上的光灵
    self._commingPetList = {}

    --正在游泳中的光灵
    self._swimmingPetList = {}
    --光灵上限
    self._swimmingPetCountMax = cfgSwimmingPool.PetCountMax

    --检查光灵位置
    self:OnReCheckPetSwimState()

    --用于判断玩家穿着非泳装进入泳池范围
    self._timerHandler =
        GameGlobal.Timer():AddEventTimes(
        1,
        TimerTriggerCount.Infinite,
        function()
            self:CheckRoleSwimsuit()
        end
    )

    self._roleInSwimArea = false

    if self._saveBuildingCallback == nil then
        self._saveBuildingCallback = GameHelper:GetInstance():CreateCallback(self.OnSaveBuilding, self)
        GameGlobal.EventDispatcher():AddCallbackListener(
            GameEventType.HomelandBuildOnSaveBuilding,
            self._saveBuildingCallback
        )
    end
end

function HomelandSwimmingPool:GetInteractingPetCountMax()
    return self._swimmingPetCountMax
end

function HomelandSwimmingPool:Dispose()
    HomelandSwimmingPool.super.Dispose(self)

    if self._saveBuildingCallback then
        GameGlobal.EventDispatcher():RemoveCallbackListener(
            GameEventType.HomelandBuildOnSaveBuilding,
            self._saveBuildingCallback
        )
        self._saveBuildingCallback = nil
    end

    --建筑销毁的时候，交互中的光灵终止游泳行为
    self:OnRemoveAllSwimmingPet()

    --交互中的主角
    --如果是泳装
    if self._characterController and self._characterController:IsWearingSwimsuit() and self._characterController._charGO then
        self._characterController:OnChangeSwimsuit()
    end

    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
end

---@param updateBuildings table<number,HomeBuilding>
---@param deleteBuildings table<number,HomeBuilding>
function HomelandSwimmingPool:OnSaveBuilding(updateBuildings, deleteBuildings)
    for _, building in ipairs(updateBuildings) do
        if self._pstid == building._pstid then
            --如果游泳池有更新，需要重新计算光灵的游泳状态
            self:OnReCheckPetSwimState()

            --移除交互点
            self:ResetInteractPoint()
            --刷新交互点
            self:RefreshInteractPoint()
            return
        end
    end
end

function HomelandSwimmingPool:OnReCheckPetSwimState()
    self:OnDissolveHomeInteractFollow()

    --正在交互中的光灵
    local tmpList = {}
    for _, pet in pairs(self._swimmingPetList) do
        if pet:IsAlive() then
            table.insert(tmpList, pet)
        end
    end

    --被移动后的位置包围进来的光灵  都挤出去。
    self._petManager = self._homelandClient:PetManager()
    local allPet = self._petManager:GetAllPets()
    for key, pet in pairs(allPet) do
        local closestPoint = self._roleSwimAreaCollider:ClosestPoint(pet:GetPosition())
        local dir = Vector3.Distance(closestPoint, pet:GetPosition())
        local inRange = false
        if dir <= 0 then
            inRange = true
        end

        if table.icontains(tmpList, pet) then
            --正在交互的光灵 如果不在范围内，结束当前行为，重新随机行为
            if not inRange then
                ---@type HomelandPetBehavior
                local behavior = pet:GetPetBehavior()
                ---@type HomelandPetBehaviorSwimmingPool
                local behaviorSwimmingPool = behavior:GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
                if behaviorSwimmingPool then
                    behaviorSwimmingPool:OnChangeSwimStage(HomelandPetSwimStage.Finish)
                end
            end
        else
            --不在交互的光灵 被放到了泳池范围内，随机一个随表仍出去
            if inRange then
                pet:_RandomBornPosition()
            end
        end
    end
end

function HomelandSwimmingPool:OnRemoveAllSwimmingPet()
    self:OnDissolveHomeInteractFollow()

    --因为光灵在随机下一个行为的时候，回退掉泳池中交互的位置，需要在新建list
    local tmpList = {}
    for _, pet in pairs(self._swimmingPetList) do
        if pet:IsAlive() then
            table.insert(tmpList, pet)
        end
    end
    for _, pet in pairs(tmpList) do
        ---@type HomelandPetBehavior
        local behavior = pet:GetPetBehavior()
        ---@type HomelandPetBehaviorSwimmingPool
        local behaviorSwimmingPool = behavior:GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
        if behaviorSwimmingPool then
            behaviorSwimmingPool:OnChangeSwimStage(HomelandPetSwimStage.Finish)
        end
    end
    self._swimmingPetList = {}
end

---解散跟随中的队伍（收纳泳池/位移泳池）
function HomelandSwimmingPool:OnDissolveHomeInteractFollow()
    local homeModule = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    local uiHomeModule = homeModule:GetUIModule()
    local homeClient = uiHomeModule:GetClient()
    local followList = homeClient:PetManager():GetFollowPets()
    if followList and table.count(followList) > 0 then
        local tmpList = {}
        for _, pet in pairs(followList) do
            table.insert(tmpList, pet)
        end
        --解散队伍在随机行为的地方就做了  这里是需要刷新UI
        for _, pet in pairs(tmpList) do
            --发事件不管用，因为监听的界面在建造模式下都关闭了。
            -- GameGlobal.EventDispatcher():Dispatch(GameEventType.OnHomeInteractFollow, false, pet)
            -- 无法解决
            -- self._homelandClient:PetManager():OnHomeInteractFollow(false, pet)

            if table.icontains(self._swimmingPetList, pet) then
                table.removev(self._homelandClient:PetManager()._followPets, pet)
            end
        end
    end
end

---判断泳池的游泳功能是否解锁
function HomelandSwimmingPool:IsSwimmable()
    --目前只有5271001这个组合建筑支持游泳功能 未来泳池可能不是组合建筑 可能无需解锁条件或解锁条件有变化 需要看情况扩展并配置化
    if self:GetBuildId() == 5271001 then
        return self:IsAreaCleaned(52710011)
    end

    return false
end

function HomelandSwimmingPool:OnHangPointCleaned(hangPointID)
    --目前只有5271001这个组合建筑支持游泳功能 未来泳池可能不是组合建筑 可能无需解锁条件或解锁条件有变化 需要看情况扩展并配置化
    if self:GetBuildId() == 5271001 and self:IsAreaCleaned(52710011) then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomeBuildingSwimmingUnlock, self:GetBuildId())
    end
end

---判断泳池是否满了
function HomelandSwimmingPool:GetSwimmingPoolIsFull()
    return table.count(self._swimmingPetList) >= self._swimmingPetCountMax
end
function HomelandSwimmingPool:AddSwimmingPet(pet)
    table.insert(self._swimmingPetList, pet)
end
function HomelandSwimmingPool:RemovSwimmingPet(pet)
    table.removev(self._swimmingPetList, pet)
end
function HomelandSwimmingPool:PetIsInSwimmingPool(pet)
    return table.icontains(self._swimmingPetList, pet)
end

---获得游泳池的水面高度
function HomelandSwimmingPool:GetSwimmingPoolWaterHeight()
    return self._waterHeight
end

---获取进出泳池的路径
function HomelandSwimmingPool:GetPathPos()
    local freePath = self:GetFreePath()
    if not freePath then
        return nil, nil, nil
    end

    local insidePos = GameObjectHelper.FindChild(freePath, "inside").position
    local outsidePos = GameObjectHelper.FindChild(freePath, "outside").position
    return freePath, insidePos, outsidePos
end

---获取一条可以用的进出路径
function HomelandSwimmingPool:GetFreePath()
    if not self._pathList or table.count(self._pathList) == 0 then
        return
    end
    local index = math.random(1, #self._pathList)
    local freePath = self._pathList[index]
    table.removev(self._pathList, freePath)
    return freePath
end
---归还
function HomelandSwimmingPool:GiveBackPath(pathTransform)
    self._pathList[#self._pathList + 1] = pathTransform
end

---获得一个可以游泳的随机点
function HomelandSwimmingPool:GetSwimRandomPos()
    if not self._swimAreaCollider then
        return
    end
    local boxcollider = self._swimAreaCollider
    local posX = boxcollider.center.x + UnityEngine.Random.Range(-boxcollider.size.x, boxcollider.size.x) * 0.5
    local posZ = boxcollider.center.z + UnityEngine.Random.Range(-boxcollider.size.z, boxcollider.size.z) * 0.5
    local pos = Vector3(posX, 0, posZ)
    pos = boxcollider.transform:TransformPoint(pos)
    return pos
end

function HomelandSwimmingPool:GetRoleSwimAreaCollider()
    return self._roleSwimAreaCollider
end

function HomelandSwimmingPool:GetPoolAreaCollider()
    return self._poolAreaCollider
end

function HomelandSwimmingPool:Interactable()
    return self:IsSwimmable()
end

---检查主角是否穿了泳装
function HomelandSwimmingPool:CheckRoleSwimsuit()
    --摆放模式的移动
    if self._homelandClient:CurrentMode() == HomelandMode.Build then
        return
    end

    if not self._roleSwimAreaCollider then
        return
    end

    local curRoleInSwimArea = self:OnCheckRoleInSwimmingArea()

    --进入范围 没有穿泳装
    if self._roleInSwimArea == false and curRoleInSwimArea and self._characterController:IsNotWearingSwimsuit() then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_invite_role_cannot_swim"))
    end

    --进范围
    if self._roleInSwimArea == false and curRoleInSwimArea == true and self._characterController:IsWearingSwimsuit() then
        --关闭冲刺按钮
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnChangeUIHomelandButtonSprintShow, false)
    end
    --出范围
    if self._roleInSwimArea == true and curRoleInSwimArea == false and self._characterController:IsWearingSwimsuit() then
        --打开冲刺按钮
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnChangeUIHomelandButtonSprintShow, true)
    end

    --进出范围 穿的泳装 解散队伍
    if self._roleInSwimArea ~= curRoleInSwimArea and self._characterController:IsWearingSwimsuit() then
        local homeModule = GameGlobal.GetModule(HomelandModule)
        ---@type UIHomelandModule
        local uiHomeModule = homeModule:GetUIModule()
        local homeClient = uiHomeModule:GetClient()
        local followList = homeClient:PetManager():GetFollowPets()
        if followList and table.count(followList) > 0 then
            local tmpList = {}
            --解散队伍
            for _, pet in pairs(followList) do
                table.insert(tmpList, pet)
            end

            for _, pet in pairs(tmpList) do
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnHomeInteractFollow, false, pet)

                --如果是出泳池，泳池中的跟随队伍重新回去游泳
                if curRoleInSwimArea == false then
                    ---@type HomelandPetBehavior
                    local behavior = pet:GetPetBehavior()
                    behavior:ChangeBehavior(HomelandPetBehaviorType.SwimmingPool)

                    --如果是在水中改变行为后，游泳行为的Enter里会包含修改状态。
                    --这里需要考虑把光灵带到梯子边的状态，再设置一下行为中的状态。
                    ---@type HomelandPetBehaviorSwimmingPool
                    local behaviorSwimmingPool = behavior:GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
                    if behaviorSwimmingPool then
                        behaviorSwimmingPool:OnChangeSwimStage(HomelandPetSwimStage.Swimming)
                    end
                end
            end
        end
    end

    self._roleInSwimArea = curRoleInSwimArea
end

---检查主角是否在泳池的可游范围内
function HomelandSwimmingPool:OnCheckRoleInSwimmingArea()
    if not self._characterController then
        ---@type HomelandCharacterManager
        local characterManager = self._homelandClient:CharacterManager()
        ---@type HomelandMainCharacterController
        self._characterController = characterManager:MainCharacterController()
    end
    if not self._characterController._charTrans then
        return false
    end

    if not self._swimmingPoolArea then
        ---@type HomeBuildingFatherArea
        local homeBuildingFatherArea = self._areaList[#self._areaList]
        ---@type HomeBuildArea
        self._swimmingPoolArea = homeBuildingFatherArea:GetHomeArea()
    end

    -- local posOffset = self._characterController._charTrans.position - self._swimmingPoolArea._trans.position
    local posOffset = self._characterController._charTrans.position
    local posWork = Vector2(posOffset.x, posOffset.z)
    if self._swimmingPoolArea:OnOutSide(posWork) then
        return false
    end

    local rolePos = self._characterController:Position()
    local inRange = false
    local closestPoint = self._roleSwimAreaCollider:ClosestPoint(rolePos)
    local dir = Vector3.Distance(closestPoint, rolePos)
    if dir <= 0 then
        inRange = true
    end

    return inRange
end
