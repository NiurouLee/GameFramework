_class("HomelandPetManager", Object)
---@class HomelandPetManager:Object
HomelandPetManager = HomelandPetManager

function HomelandPetManager:Constructor()
    ---@type table<number,HomelandPet>
    self._pets = {}
    self._petCount = 0
    self.petScale = Cfg.cfg_aircraft_camera["petScale"].Value
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)
    ---@type HomelandPetLoader
    self._petLoader = HomelandPetLoader:New()
    ---@type HomelandPetBehaviorFactory
    self._homelandPetBehaviorFactory = HomelandPetBehaviorFactory:New()
    ---@type HomelandPetComponentFactory
    self._homelandPetComponentFactory = HomelandPetComponentFactory:New()
    ---@type HomelandPetDebug
    self._debugPet = HomelandPetDebug:New(self, HomelandPetMode.Normal)
    self._followPets = {}
    self._followMax = 16 --跟随上限
    self._update_index = 0
    self._update_mod = 4
end

function HomelandPetManager:Init(homelandClient)
    ---@type HomelandClient
    self._homelandClient = homelandClient
    self._debugPet:Init(homelandClient)
    self._petLoader:Init()
    self:_InitDomitoryPets()

    self._petShader = GraphicUtli.FindFromBundle("H3D/Actor/Common")
    if self._petShader then
        self._petShader.maximumLOD = 200
    end

    if EDITOR then
        HelperProxy:GetInstance():SetRoleShaderLodLevel(200)
    end
end

function HomelandPetManager:Update(deltaTimeMS)
    local index = 0
    for _, pet in pairs(self._pets) do
        if index % self._update_mod == self._update_index then
            pet:Update(deltaTimeMS)
        end
        index = index+1
    end
    if self._tempPets  then 
        for _, pet in pairs(self._tempPets) do
            pet:Update(deltaTimeMS)
        end
    end 
    self._update_index = self._update_index+1
    if (self._update_index == self._update_mod) then
        self._update_index = 0
    end
    self._petLoader:Update()
    self._debugPet:Update()
end

--初始化宿舍中的光灵
function HomelandPetManager:_InitDomitoryPets()
    if self._homelandClient:IsVisit() then
        ---@type UIHomelandModule
        local uiModule = GameGlobal.GetUIModule(HomelandModule)
        ---@type role_help_pet_info[]
        local pets = uiModule:GetVisitInfo().pet_list
        for _, pet in ipairs(pets) do
            local tmpid = pet.pet_template_id
            local pstid = pet.pet_pst_id
            local level = pet.level
            local awake = pet.grade
            local skin = pet.skin_id
            local data = HomelandPetData:New(tmpid, pstid, level, awake, nil, skin)
            self:AddVisitPet(data)
        end
    else
        ---@type HomelandModule
        local homelandModule = GameGlobal.GetModule(HomelandModule)
        ---@type dormitoryInfo
        local domitoryData = homelandModule:GetHomelandInfo().dormitory_info
        for _, domitory in pairs(domitoryData.list) do
            if domitory.bBulid then
                for _, pstid in pairs(domitory.petList) do
                    if pstid > 0 then
                        local pet = self._petModule:GetPet(pstid)
                        if pet then
                            self:AddPet(pet:GetTemplateID())
                        end
                    end
                end
            end
        end
    end
end

---宿舍光灵的入住、入出、替换
---@param operation HomeSettleOperateType
---@param pstid uint64
---@param oldPstID uint64
---@param spPetPstID uint64
function HomelandPetManager:UpdateDomitoryPet(operation, pstid, oldPstID, spPetPstID)
    local pet = self._petModule:GetPet(pstid)
    if pet then
        if operation == HomeSettleOperateType.Add then
            self:AddPet(pet:GetTemplateID())
        elseif operation == HomeSettleOperateType.Remove then
            self:RemoveFollowList(pstid, spPetPstID)
            self:RemovePet(pet:GetTemplateID())
        elseif operation == HomeSettleOperateType.Replace then
            self:RemoveFollowList(oldPstID, spPetPstID)
            local oldPet = self._petModule:GetPet(oldPstID)
            if oldPet then
                self:RemovePet(oldPet:GetTemplateID())
            end
            self:AddPet(pet:GetTemplateID())
        end
        if spPetPstID then
            local spPet = self._petModule:GetPet(spPetPstID)
            if spPet then
                self:RemovePet(spPet:GetTemplateID())
            end
        end
    end
end
--刷新跟随列表
function HomelandPetManager:RemoveFollowList(oldPet, spPet)
    if oldPet and oldPet ~= 0 then
        local pet = self:GetPetByPstID(oldPet)
        self:OnHomeInteractFollow(false, pet)
    end
    if spPet and spPet ~= 0 and spPet ~= oldPet then
        local pet = self:GetPetByPstID(spPet)
        self:OnHomeInteractFollow(false, pet)
    end
end
function HomelandPetManager:AddPet(templateID)
    if self._pets[templateID] then
        Log.fatal("HomelandPet Is Exist.", templateID)
        return
    end
    ---@type Pet
    local data = self._petModule:GetPetByTemplateId(templateID)
    if data == nil then
        Log.exception("HomelandPet Not In The Package.", templateID)
        return
    end
    local pstID = data:GetPstID()
    local level = data:GetPetLevel()
    local awake = data:GetPetGrade()
    local skinId = data:GetSkinId()
    local petData = HomelandPetData:New(templateID, pstID, level, awake, nil, skinId)
    local pet = self:_CreatePet(petData)
    self._pets[templateID] = pet
    self._petCount = self._petCount + 1
    self._petLoader:AsyncLoadPet(pet)
    self._debugPet:AddDebugPet(pet)
    Log.info("Add HomelandPet." .. templateID)
    return pet
end

--拜访时创建1个星灵
---@param petData HomelandPetData
function HomelandPetManager:AddVisitPet(petData)
    local pet = self:_CreatePet(petData)
    self._pets[petData:TmpID()] = pet
    self._petCount = self._petCount + 1
    self._petLoader:AsyncLoadPet(pet)
    self._debugPet:AddDebugPet(pet)
    Log.info("Add HomelandPet." .. petData:TmpID())
    return pet
end

function HomelandPetManager:RemovePet(templateID)
    local pet = self._pets[templateID]
    if not pet then
        Log.fatal("HomelandPet Have't Pet.", templateID)
        return false
    end
    pet:Dispose()
    self._pets[templateID] = nil
    self._petCount = self._petCount - 1
    self._debugPet:RemoveDebugPet(pet)
    Log.info("Remove HomelandPet." .. templateID)
    return true
end

---@return HomelandPet
function HomelandPetManager:GetPetByCollider(collider)
    for key, pet in pairs(self._pets) do
        if pet:Collider() == collider then
            return pet
        end
    end
    return nil
end

function HomelandPetManager:Dispose()
    for id, pet in pairs(self._pets) do
        pet:Dispose()
    end
    self._pets = {}
    self._petLoader:Dispose()
    self._debugPet:Dispose()

    if self._petShader then
        self._petShader.maximumLOD = 300
        self._petShader = nil
    end

    if EDITOR then
        HelperProxy:GetInstance():SetRoleShaderLodLevel(-1)
    end
end

---@return table<number, HomelandPet>
function HomelandPetManager:GetPets(filter)
    local pets = {}
    for _, pet in pairs(self._pets) do
        if filter then
            if filter(pet) then
                table.insert(pets, pet)
            end
        else
            table.insert(pets, pet)
        end
    end
    return pets
end

---@return HomelandPet
function HomelandPetManager:GetPet(templateID)
    return self._pets[templateID]
end

function HomelandPetManager:GetPetByPstID(pstid)
    local pet = self._petModule:GetPet(pstid)
    if pet then
        return self:GetPet(pet:GetTemplateID())
    end
end

---获取一个光灵，如果光灵还没有加载出来就同步加载,并打断它的异步加载
---@return HomelandPet
function HomelandPetManager:GetPetSync(templateID)
    local data = self._petModule:GetPetByTemplateId(templateID)
    if data == nil then
        Log.error("HomelandPet Not In The Package.", templateID)
        return nil
    end
    local pet = self._pets[templateID]
    if not pet then
        return nil
    end
    if pet:IsLoaded() then
        return pet
    else
        self._petLoader:InterruptAsyncLoad(pet)
        self._petLoader:SyncLoadePet(pet)
        return pet
    end
end

function HomelandPetManager:HasPet(id)
    return self._pets[id] ~= nil
end

---@return HomelandPet
---@param data HomelandPetData
function HomelandPetManager:_CreatePet(data)
    return HomelandPet:New(data, self._homelandClient)
end

---@return HomelandPetBehaviorFactory
function HomelandPetManager:GetBehaviorFactory()
    return self._homelandPetBehaviorFactory
end

---@return HomelandPetComponentFactory
function HomelandPetManager:GetComponentFactory()
    return self._homelandPetComponentFactory
end

---@param pet HomelandPet
function HomelandPetManager:OnHomeInteractFollow(follow, pet)
    ---@type HomelandPetBehavior
    local behavior = pet:GetPetBehavior()
    if follow then
        if not table.icontains(self._followPets, pet) then
            if behavior:CanChange(HomelandPetBehaviorType.Free) then
                table.insert(self._followPets, pet)
                behavior:ChangeBehavior(HomelandPetBehaviorType.Following)
            end
        end
    else
        if table.icontains(self._followPets, pet) then
            if behavior:CanChange(HomelandPetBehaviorType.Free) then
                table.removev(self._followPets, pet)
                behavior:ChangeBehavior(HomelandPetBehaviorType.Free)
            end
        end
    end
    for i = 1, #self._followPets do
        local pet = self._followPets[i]
        pet:RefreshFollow()
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnHomePetFollow)
end
function HomelandPetManager:RefreshFollowPets()
    if self._followPets and #self._followPets > 0 then
        for i = 1, #self._followPets do
            local pet = self._followPets[i]
            pet:RefreshFollow()
        end
    end
end
function HomelandPetManager:GetFollowPets()
    return self._followPets
end
function HomelandPetManager:FollowFull()
    return #self._followPets >= self._followMax
end
---@param mode HomelandMode
function HomelandPetManager:OnModeChanged(mode)
    self:SetPetsVisible(mode == HomelandMode.Normal)
    if self._homelandClient:LastMode() == HomelandMode.Build and mode == HomelandMode.Normal then
        for _, pet in pairs(self._pets) do
            pet:OnClientModeChange(self._homelandClient:LastMode(), mode)
        end
    end
end

---设置全部光灵的显示、隐藏
---@param visible boolean
function HomelandPetManager:SetPetsVisible(visible, pet_id)
    for _, pet in pairs(self._pets) do
        if pet_id == nil or pet:PstID() ~= pet_id then
            pet:SetVisible(visible)
        end
    end
end

---刷新指定tplid光灵显隐状态
---@param petTplID number
function HomelandPetManager:RefreshPetVisible(petTplID)
    for _, pet in pairs(self._pets) do
        local pet_a_sp = false
        local pet_b_sp = false
        local tmpid_a = pet:TemplateID()
        local cfg_pet_a = Cfg.cfg_pet[tmpid_a]
        if cfg_pet_a.BinderPetID then
            pet_a_sp = true
            tmpid_a = cfg_pet_a.BinderPetID
        end
        local tmpid_b = petTplID
        local cfg_pet_b = Cfg.cfg_pet[tmpid_b]
        if cfg_pet_b.BinderPetID then
            pet_b_sp = true
            tmpid_b = cfg_pet_b.BinderPetID
        end
        local refresh = false
        if pet_a_sp and pet_b_sp then
            if tmpid_a == tmpid_b then
                refresh = true
                Log.debug("###[sp] 2 两个都是sp，并且id相同,tmpid_a ", tmpid_a)
            end
        else
            if pet:TemplateID() == petTplID then
                refresh = true
                Log.debug("###[sp] 2 两个都不是sp，但是id相同,petTplID ", petTplID)
            end
        end
        if refresh then
            pet:RefreshVisible()
        end
    end
end

---判断是否有光灵、主角在指定范围内
---@param center Vector3
---@param range number
---@param excludePet HomelandPet
function HomelandPetManager:PetInRange(center, range, excludePet)
    if self._pets then
        for _, pet in pairs(self._pets) do
            if pet:FinalVisible() and (not excludePet or (pet ~= excludePet)) then
                if Vector3.Distance(pet:GetPosition(), center) <= range then
                    return true
                end
            end
        end
    end
    if self._homelandClient and self._homelandClient:CharacterManager() and self._homelandClient:CharacterManager():MainCharacterController() then
        local mainCharacterController = self._homelandClient:CharacterManager():MainCharacterController()
        local playerPosition = mainCharacterController:Position()
        if Vector3.Distance(playerPosition, center) <= range then
            return true
        end
    end
    return false
end

---主角是否再和这个家具交互中
---@param pBuilding HomeBuilding
---@param pTransform UnityEngine.Transform
function HomelandPetManager:MainCharacterInteracting(pBuilding, pTransform)
    if self._homelandClient and self._homelandClient:CharacterManager() and self._homelandClient:CharacterManager():MainCharacterController() then
        local mainCharacterController = self._homelandClient:CharacterManager():MainCharacterController()
        local state = mainCharacterController:State()
        if state == HomelandActorStateType.Interact then
            local mBuilding = mainCharacterController:GetCurInteractBuilding()
            if mBuilding and mBuilding == pBuilding then
                local mTransform = mainCharacterController:GetCurInteractTargetTransform()
                if mTransform and pTransform then
                    local mIndex = mTransform:GetSiblingIndex()
                    local pIndex = pTransform:GetSiblingIndex()
                    if mIndex - pIndex == 1 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function HomelandPetManager:GetAllPets()
    return self._pets
end

---光灵换皮肤，如果光灵还没有加载出来就同步加载,并打断它的异步加载
---@param homelandPet HomelandPet
function HomelandPetManager:ChangePetSkin(homelandPet, newSkinID, newClothSkinID)
    local newSkinPrefabName = newSkinID .. ".prefab"
    homelandPet:SetSkinID(newSkinID)
    homelandPet:SetClothSkinID(newClothSkinID)
    homelandPet:SetPrefabName(newSkinPrefabName)
    self._petLoader:SyncLoadePetSkinModle(homelandPet)
end

---主角和光灵被泳池隔开
function HomelandPetManager:RoleAndPetSeparatedBySwimPool(homelandPet)
    ---@type HomelandCharacterManager
    local characterManager = self._homelandClient:CharacterManager()
    ---@type HomelandMainCharacterController
    local characterController = characterManager:MainCharacterController()

    --主角是游泳状态，光灵不是
    local roleIsSwimming = characterController:IsSwimming()
    if roleIsSwimming and homelandPet:GetMotionType() == HomelandPetMotionType.None then
        return true
    end

    --主角没有进入泳池/不在泳池范围内，光灵是游泳行为
    if not roleIsSwimming and homelandPet:GetMotionType() == HomelandPetMotionType.Swim then
        return true
    end

    return false
end

-- 添加临时光灵
function HomelandPetManager:GetTempPet(templateID)
    if not self._tempPets then 
        self._tempPets = {}
    end 
    local pet
    local isTemp = false 
    pet = self:GetPet(templateID)
    if pet then
        return pet,isTemp
    else 
        local petId = templateID
        local roompet = GameGlobal.GetModule(PetModule):GetPetByTemplateId(templateID)
        local skinId = nil 
        local skinIds = Cfg.cfg_pet_skin{PetId = petId}
        if roompet then
            skinId =  roompet:GetSkinId()
        else 
            skinId =  skinIds[1].id
        end 
        local petData = HomelandPetData:New(templateID, 999999999, 0, 0, nil, skinId)
        pet = self:_CreatePet(petData)
        isTemp = true 
    end
    self._tempPets[templateID] = pet
    self._petLoader:SyncLoadePet(pet)
    self._debugPet:AddDebugPet(pet)
    Log.info(" GetTempPet." .. templateID)
    return pet,isTemp
end

-- 删除临时光灵
function HomelandPetManager:DeleteTempPet(templateID)
    if not self._tempPets then 
        return 
    end 
    if not self._tempPets[templateID] then 
       return 
    end 
    self._tempPets[templateID]:Dispose()
    self._tempPets[templateID] = nil 
end

