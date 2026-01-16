--[[
    风船星灵管理器
]]
_class("AircraftPetManager", Object)
---@class AircraftPetManager:Object
AircraftPetManager = AircraftPetManager

function AircraftPetManager:Constructor(main)
    ---@type AircraftMain
    self._main = main
    ---@type table<number,AircraftPet>
    self._pets = {}
    self._petCount = 0
    ---@type table<number,AircraftPet>
    self._visitPets = {}

    self.petScale = Cfg.cfg_aircraft_camera["petScale"].Value
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)

    ---@type AircraftPetLoader
    self._petLoader = AircraftPetLoader:New()

    --星灵显示上限
    local lodlevel = LODManager.Instance:GetLODLevel()
    if (lodlevel == 0) then
        self._petCeiling = Cfg.cfg_aircraft_const["aircraft_pet_ceiling_0"].IntValue
    elseif (lodlevel == 1) then
        self._petCeiling = Cfg.cfg_aircraft_const["aircraft_pet_ceiling_1"].IntValue
    else
        self._petCeiling = Cfg.cfg_aircraft_const["aircraft_pet_ceiling_2"].IntValue
    end

    --已经显示的星灵
    ---@type table<number,AircraftPet>
    self._shownPets = {}
    self._shownPetCount = 0

    ---@type SortedArray
    self._cacheArray =
        SortedArray:New(
            Algorithm.COMPARE_CUSTOM,
            function(p1, p2)
                ---@type AircraftPet
                local pet1 = p1
                ---@type AircraftPet
                local pet2 = p2

                -- local forceShow1 = self:forceShow(pet1)
                -- local forceShow2 = self:forceShow(pet2)
                -- if forceShow1 ~= forceShow2 then
                --     if forceShow1 then
                --         return 1
                --     else
                --         return -1
                --     end
                -- end

                local pos1 = pet1:WorldPosition():Clone()
                local pos2 = pet2:WorldPosition():Clone()
                pos1.z = 0
                pos2.z = 0

                local target = self._main:CameraFocusPoint()
                ---@type Vector3
                local d1 = (pos1 - target):SqrMagnitude()
                local d2 = (pos2 - target):SqrMagnitude()

                if d1 < d2 then
                    return 1
                elseif d1 > d2 then
                    return -1
                else
                    return 0
                end
            end
        )
    self._cacheArray:AllowDuplicate()

    if false then
        -- if EDITOR then
        self._testReq = ResourceManager:GetInstance():SyncLoadAsset("AircraftTestPanel.prefab", LoadType.GameObject)
        ---@type UIView
        local view = self._testReq.Obj:GetComponent(typeof(UIView))
        self._totalT = view:GetUIComponent("UILocalizationText", "value1")
        self._ceilingT = view:GetUIComponent("UILocalizationText", "value2")
        self._ceilingT:SetText(self._petCeiling)
        self._shownT = view:GetUIComponent("UILocalizationText", "value3")
        self._loadingT = view:GetUIComponent("UILocalizationText", "value4")
        self._testReq.Obj:SetActive(true)
        self._test = true
    end

    --每秒计算1次显示的星灵
    self._timer = 1000

    self._showPetDistance = Cfg.cfg_aircraft_const["aircraft_show_pet_distance"].FloatValue
end

--强制显示的星灵
---@param pet AircraftPet
function AircraftPetManager:forceShow(pet)
    return pet:GetState() == AirPetState.RandomEvent or pet:GetState() == AirPetState.RandomEventWith or
        pet:IsVisitPet() or
        pet:IsGiftPet()
end

function AircraftPetManager:Init()
    self.camera = self._main:GetMainCamera()
    self._cameraT = self.camera.transform

    self._petLoader:Init(
        function(count)
            self:onLoadingCountChanged(count)
        end
    )
    -- self:CalShowPet()
end

--初始化之后计算需要强制显示的星灵，同步加载
function AircraftPetManager:ForceShowPetAfterInit()
    for id, pet in pairs(self._pets) do
        if self:forceShow(pet) then
            self._petLoader:SyncLoadePet(pet)
            self._shownPets[pet:PstID()] = pet
            self._shownPetCount = self._shownPetCount + 1
        end
    end
    for id, pet in pairs(self._visitPets) do
        if self:forceShow(pet) then
            self._petLoader:SyncLoadePet(pet)
            self._shownPets[pet:PstID()] = pet
            self._shownPetCount = self._shownPetCount + 1
        end
    end
end

function AircraftPetManager:Update(deltaTimeMS)
    for id, pet in pairs(self._pets) do
        pet:Update(deltaTimeMS)
        --pet的update里更新行为可能导致星灵销毁，这里判定星灵先判定星灵是否存活
        if pet:IsAlive() and pet:IsMainActionOver() then
            self._main:RandomActionForPet(pet)
        end
    end

    for id, pet in pairs(self._visitPets) do
        pet:Update(deltaTimeMS)
        if pet:IsMainActionOver() then
            self._main:RandomActionForPet(pet)
        end
    end

    self._petLoader:Update()

    self._timer = self._timer - deltaTimeMS
    if self._timer < 0 then
        self:CalShowPet()
        self._timer = 1000
    end
end

function AircraftPetManager:AddPet(tmpID)
    if self._pets[tmpID] then
        Log.fatal("[AircraftPet] 星灵已经出现在风船中，ID：", tmpID)
        return
    end

    --sp
    if table.count(self._pets) > 0 then
        local pets = {}
        for key, value in pairs(self._pets) do
            table.insert(pets, key)
        end
        local inner, sp = HelperProxy:GetInstance():CheckBinderID(pets, tmpID)
        if inner then
            return nil, sp
        end
    end

    ---@type Pet
    local data = self._petModule:GetPetByTemplateId(tmpID)
    if data == nil then
        Log.exception("[AircraftPet] 严重错误，星灵不在背包中，不能进入娱乐区：", tmpID)
    end

    local pstID = data:GetPstID()
    local level = data:GetPetLevel()
    local awake = data:GetPetGrade()
    local skinId = data:GetSkinId()
    local pdata = AircraftPetData:New(tmpID, pstID, level, awake, nil, skinId)

    local pet = self:_createPet(pdata)
    if pet == nil then
        return
    end
    self._pets[tmpID] = pet
    self._petCount = self._petCount + 1
    self:onPetCountChanged()
    return pet
end

function AircraftPetManager:RemovePet(tmpID)
    local pet = self._pets[tmpID]
    if not pet then
        Log.fatal("[AircraftPet] 星灵不在风船内，ID：", tmpID)
        return false
    end
    local pstID = pet:PstID()
    if self._shownPets[pstID] then
        self._shownPetCount = self._shownPetCount - 1
        self:onShownPetCountChanged()
        self._shownPets[pstID] = nil
    end
    pet:Dispose()
    self._pets[tmpID] = nil
    Log.fatal("[AircraftPet] 星灵销毁：", tmpID)
    self._petCount = self._petCount - 1
    self:onPetCountChanged()
    return true
end

--计算1次当前需要显示的星灵列表
function AircraftPetManager:CalShowPet()
    if self._petCount <= self._shownPetCount then
        return
    end

    local pets = self:getShowPets()
    self._cacheArray:Clear()
    self._shownPetCount = 0
    for _, pet in pairs(self._shownPets) do
        local id = pet:PstID()
        if pets[id] then
            self._shownPetCount = self._shownPetCount + 1
            pets[id] = nil
        else
            pet:Hide()
            self._petLoader:TryDelPet(pet)
            self._shownPets[id] = nil
        end
    end

    for _, pet in pairs(pets) do
        self._petLoader:AsyncLoadPet(pet)
        self._shownPets[pet:PstID()] = pet
        self._shownPetCount = self._shownPetCount + 1
    end
end

function AircraftPetManager:getShowPets()
    local pets = {}
    local count = 0

    --特殊星灵必显示
    for _, pet in pairs(self._pets) do
        if self:forceShow(pet) then
            pets[pet:PstID()] = pet
            count = count + 1
            if count >= self._petCeiling then
                return pets
            end
        end
    end
    for _, pet in pairs(self._visitPets) do
        --拜访星灵必定是特殊星灵
        pets[pet:PstID()] = pet
        count = count + 1
        if count >= self._petCeiling then
            return pets
        end
    end

    -- 相机远近使用不同策略
    if self._cameraT.position.z > self._showPetDistance then
        self._cacheArray:Clear()
        --拉近时只根据星灵距相机焦点的距离判定
        for _, pet in pairs(self._pets) do
            self._cacheArray:Insert(pet)
        end

        for _, pet in pairs(self._visitPets) do
            self._cacheArray:Insert(pet)
        end

        for i = 1, self._cacheArray:Size() do
            ---@type AircraftPet
            local pet = self._cacheArray:GetAt(i)
            if pets[pet:PstID()] == nil then
                pets[pet:PstID()] = pet
                count = count + 1
                if count >= self._petCeiling then
                    return pets
                end
            end
        end
        return pets
    else
        --拉远时保证星灵平均分布
        local workingPets = {}
        local restPets = {}

        local workingPetCount = 0
        local restPetCount = 0
        for _, pet in pairs(self._pets) do
            if pet:IsWorkingPet() then
                if pets[pet:PstID()] == nil then
                    local spaceID = pet:GetSpace()
                    if workingPets[spaceID] == nil then
                        workingPets[spaceID] = {}
                    end
                    table.insert(workingPets[spaceID], pet)
                    workingPetCount = workingPetCount + 1
                end
            else
                if pets[pet:PstID()] == nil then
                    table.insert(restPets, pet)
                    restPetCount = restPetCount + 1
                end
            end
        end

        if workingPetCount + restPetCount == 0 then
            return pets
        end

        local needCount = self._petCeiling - count
        local total = restPetCount + workingPetCount
        if needCount > total then
            total = needCount
        end
        local restCount = math.ceil(needCount * restPetCount / total)
        local workCount = needCount - restCount

        for i = 1, restCount do
            ---@type AircraftPet
            local pet = restPets[i]
            pets[pet:PstID()] = pet
            count = count + 1
        end

        while workingPetCount > 0 do
            for space, workingPets in pairs(workingPets) do
                if #workingPets > 0 then
                    ---@type AircraftPet
                    local pet = workingPets[1]
                    table.remove(workingPets, 1)
                    workingPetCount = workingPetCount - 1
                    pets[pet:PstID()] = pet
                    count = count + 1
                    if count >= self._petCeiling then
                        return pets
                    elseif workingPetCount <= 0 then
                        break
                    end
                end
            end
        end
        return pets
    end
end

--通过点击的碰撞器拿到AircraftPet
function AircraftPetManager:GetPetByCollider(collider)
    for key, pet in pairs(self._pets) do
        if pet:CheckCollider(collider) then
            return pet
        end
    end
    for key, pet in pairs(self._visitPets) do
        if pet:CheckCollider(collider) then
            return pet
        end
    end
    return nil
end

function AircraftPetManager:Dispose()
    for id, pet in pairs(self._pets) do
        pet:Dispose()
    end
    self._pets = {}

    for id, pet in pairs(self._visitPets) do
        pet:Dispose()
    end
    self._visitPets = {}

    self._petCount = 0
    self._petLoader:Dispose()
    if self._testReq then
        self._testReq:Dispose()
    end
end

---@return AircraftPet
function AircraftPetManager:GetPet(tmpID)
    return self._pets[tmpID]
end

function AircraftPetManager:HasPet(id)
    return self._pets[id] ~= nil
end

---@return table<number, AircraftPet>
function AircraftPetManager:GetPets(filter, includeVisitPet)
    if filter == nil then
        Log.fatal("[AircraftPet] filter is nil")
        return nil
    end
    local pets = {}
    for _, pet in pairs(self._pets) do
        if filter(pet) then
            pets[#pets + 1] = pet
        end
    end
    if includeVisitPet then
        for _, pet in pairs(self._visitPets) do
            if filter(pet) then
                pets[#pets + 1] = pet
            end
        end
    end
    return pets
end

---@return AircraftPet
function AircraftPetManager:GetVisitPet(tmpID)
    return self._visitPets[tmpID]
end

---@return AircraftPet
---@param _data AircraftPetData
function AircraftPetManager:_createPet(_data)
    -- local petPrefabResName = _data:Prefab()
    -- local go, reqs = HelperProxy:GetInstance():LoadPet(petPrefabResName, false)
    -- if go == nil then
    --     return
    -- end
    -- go:SetActive(true)
    -- go.transform.localScale = Vector3.one * self.petScale

    -- local root = go.transform:Find("Root")
    -- --默认隐藏武器
    -- for i = 0, root.childCount - 1 do
    --     local child = root:GetChild(i)
    --     local contains = string.find(child.name, "weapon")
    --     if contains then
    --         child.gameObject:SetActive(false)
    --     end
    -- end
    -- local pet = AircraftPet:New(reqs, go, _data)
    local pet = AircraftPet:New(_data, self._main)
    return pet
end

---@param pet aircraft_visit_pet
function AircraftPetManager:AddVisitPet(pet)
    local tmpid = pet.pet_info.pet_template_id
    if self._visitPets[tmpid] then
        Log.exception("[AircraftPet] 拜访星灵已经出现在风船中:", tmpid)
        return
    end
    local pstid = pet.pet_info.pet_pst_id
    local level = pet.pet_info.level
    local awake = pet.pet_info.grade
    local skin = pet.pet_info.skin_id

    local data = AircraftPetData:New(tmpid, pstid, level, awake, nil, skin)
    local airPet = self:_createPet(data)
    if airPet == nil then
        return
    end
    self._visitPets[tmpid] = airPet
    airPet:SetAsVisitPet()
    self._petCount = self._petCount + 1
    self:onPetCountChanged()
    return airPet
end

function AircraftPetManager:RemoveVisitPet(tmpID)
    local pet = self._visitPets[tmpID]
    if not pet then
        Log.fatal("[AircraftPet] 拜访星灵不在风船内，ID：", tmpID)
        return false
    end
    local pstID = pet:PstID()
    if self._shownPets[pstID] then
        self._shownPetCount = self._shownPetCount - 1
        self:onShownPetCountChanged()
        self._shownPets[pstID] = nil
    end
    pet:Dispose()
    self._visitPets[tmpID] = nil
    AirLog("拜访星灵销毁：", tmpID)
    self._petCount = self._petCount - 1
    self:onPetCountChanged()
    return true
end

function AircraftPetManager:onPetCountChanged()
    if self._test then
        self._totalT:SetText(self._petCount)
    end
end

function AircraftPetManager:onLoadingCountChanged(count)
    if self._test then
        self._loadingT:SetText(count)
        self._shownT:SetText(self._shownPetCount - count)
    end
end

function AircraftPetManager:onShownPetCountChanged()
    self:onLoadingCountChanged(self._petLoader:LoadingCount())
end

---在拜访星灵初始化完成后，可以通过这个接口获取到某个星灵是否为拜访星灵
function AircraftPetManager:IsVisitPet()
end

----------------------------------------------------------------
--[[
    风船星灵数据，统一背包中星灵和来拜访的星灵
]]
---@class AircraftPetData:Object
_class("AircraftPetData", Object)
AircraftPetData = AircraftPetData

function AircraftPetData:Constructor(tmpID, pstID, level, awake, breakL, skin)
    self._tmpID = tmpID
    self._pstID = pstID
    self._awake = awake
    self._level = level
    self._break = breakL
    self._skin = skin

    --获取prefab名称
    self._prefab = HelperProxy:GetInstance():GetPetPrefab(tmpID, awake, skin, PetSkinEffectPath.MODEL_AIRCRAFT)
    -- if awake == 0 then
    --     self._prefab = Cfg.cfg_pet[tmpID].Prefab
    -- else
    --     self._prefab = Cfg.cfg_pet_grade {PetID = tmpID, Grade = awake}[1].Prefab
    -- end
end

function AircraftPetData:TmpID()
    return self._tmpID
end

function AircraftPetData:PstID()
    return self._pstID
end

function AircraftPetData:Awake()
    return self._awake
end

function AircraftPetData:SkinID()
    return self._skin
end

function AircraftPetData:Prefab()
    return self._prefab
end
