--[[
    风船工作星灵控制器
]]
---@class AircraftWorkingManager:Object
_class("AircraftWorkingManager", Object)
AircraftWorkingManager = AircraftWorkingManager

---@param aircraftMain AircraftMain
function AircraftWorkingManager:Constructor(aircraftMain)
    ---@type AircraftMain
    self._main = aircraftMain
    ---@type AircraftModule
    self._module = GameGlobal.GetModule(AircraftModule)
end
function AircraftWorkingManager:Init()
    local spaces = Cfg.cfg_aircraft_space {}

    for i = 1, #spaces do
        ---@type AircraftRoomBase
        local roomData = self._module:GetRoom(i)
        if roomData then
            ---@type table<number,Pet>
            local pets = roomData:GetPets()
            if pets and #pets > 0 then
                for _, pet in ipairs(pets) do
                    local tmpID = pet:GetTemplateID()
                    if self._main:IsRandomStoryPet(tmpID) or self._main:IsGiftPet(tmpID) then
                        --工作中心灵产生了随机事件，需要设置基本信息，不需要设置行为
                        local apet = self._main:GetPetByTmpID(tmpID)
                        apet:SetAsWorkingPet()
                        apet:SetSpace(i)
                        AirLog("工作中星灵产生了剧情或送礼事件，不工作：", tmpID)
                    else
                        local apet, sp = self._main:AddPet(tmpID)
                        if apet then
                            apet:SetState(AirPetState.Working)
                            apet:SetAsWorkingPet()
                            apet:SetSpace(i)
                            ---@type AircraftRoom
                            local room = self._main:GetRoomBySpaceID(i)
                            local holder = room:GetPointHolder()
                            local pos = self._main:GetInitPos(holder)
                            apet:SetPosition(pos)
                            apet:SetFloor(holder:Floor())
                            local action = AirActionWandering:New(apet, holder, nil, "漫游-工作中", self._main)
                            self._main:StartInitAction(apet, action, nil)
                            AirLog("星灵开始工作：", tmpID)
                        else
                            if sp then
                                AirLog("已经有sp星灵存在，：", sp, ",tmpID:", tmpID)
                            end
                        end
                    end
                end
            end
        end
    end

    AirLog("AircraftWorkingManager Init Done")
end

---@param pet AircraftPet
function AircraftWorkingManager:StartWorking(pet)
    if not pet:IsWorkingPet() then
        Log.fatal("[AircraftWorking] 该星灵不是工作星灵：", pet:TemplateID())
        return
    end
    local spaceID = pet:GetSpace()
    ---@type AircraftRoom
    local room = self._main:GetRoomBySpaceID(spaceID)
    local holder = room:GetPointHolder()
    local action = AirActionWandering:New(pet, holder, nil, "漫游-工作中", self._main)
    pet:SetState(AirPetState.Working)
    pet:StartMainAction(action)
end

function AircraftWorkingManager:PetEnterSpaceToWork(petID, spaceID)
    ---@type AircraftPet
    local pet = self._main:GetPetByTmpID(petID)
    local sp = false
    if pet == nil then
        pet, sp = self._main:AddPet(petID)
    end
    if not pet then
        if sp then
            Log.debug("###[AircraftWorkingManager] 已存在sp星灵，sp:", sp, ",petid:", petID)
        end
        return
    end
    pet:SetAsWorkingPet()
    pet:SetSpace(spaceID)
    if self._main:IsRandomStoryPet(petID) then
        --触发了随机剧情的星灵入住房间
        return
    end
    pet:SetState(AirPetState.Working)
    ---@type AircraftRoom
    local room = self._main:GetRoomBySpaceID(spaceID)
    local holder = room:GetPointHolder()
    local point = holder:PopPoint()
    local pos = point:Pos()
    holder:ReleasePoint(point)
    pet:SetFloor(holder:Floor())
    local action = AirActionWandering:New(pet, holder, nil, "漫游-工作中", self._main)
    pet:StartMainAction(action)
    --最后设置位置，因为在家具上的星灵在OnFurniture行为Stop时会强行设置为家具的target点，所以在设置过之后再设置一次
    pet:SetPosition(pos)
end

function AircraftWorkingManager:OnSpacePetChanged(spaceID)
    local pets =
        self._main:GetPets(
        function(p)
            ---@type AircraftPet
            local pet = p
            if pet:IsWorkingPet() and pet:GetSpace() == spaceID then
                return true
            end
            return false
        end
    )
    local roomData = self._module:GetRoom(spaceID)
    ---@type table<number,Pet>
    local roomPets
    if roomData then
        roomPets = roomData:GetPets()
    else
        AirLog("找不到房间，可能是房间被拆除了:", spaceID)
        roomPets = {}
    end

    local remove = {} --需要移除的
    local add = {} --新增星灵需要判断是否是sp星灵
    for _, roomPet in ipairs(roomPets) do
        local found = false
        for __, pet in ipairs(pets) do
            if pet:TemplateID() == roomPet:GetTemplateID() then
                found = true
                break
            end
        end
        if not found then
            local petID = roomPet:GetTemplateID()
            add[#add + 1] = petID
            local replacePetID = self:_CheckSpPet(roomPet)
            if replacePetID then
                --sp星灵替换
                local pModule = GameGlobal.GetModule(PetModule)
                local pet1Name = StringTable.Get(pModule:GetPetByTemplateId(petID):GetPetName())
                local pet2Name = StringTable.Get(pModule:GetPetByTemplateId(replacePetID):GetPetName())
                local tips = StringTable.Get("str_aircraft_sp_enter_tips", pet1Name, pet2Name)
                ToastManager.ShowToast(tips)
                remove[replacePetID] = true
            end
        end
    end

    for _, pet in ipairs(pets) do
        local found = false
        for __, roomPet in ipairs(roomPets) do
            if roomPet:GetTemplateID() == pet:TemplateID() then
                found = true
                break
            end
        end
        if not found then
            remove[pet:TemplateID()] = true
        end
    end

    for id, _ in pairs(remove) do
        self._main:PetStopWork(id)
    end
    for _, id in ipairs(add) do
        self._main:PetStartWork(id, spaceID)
    end

    -- if self._currentSpPet then

    -- end
end

function AircraftWorkingManager:Update(deltaTimeMS)
end
function AircraftWorkingManager:Dispose()
end

---@param pet MatchPet
---@return number 需要移除的星灵id
---@return number 需要移除的星灵所在的房间
function AircraftWorkingManager:_CheckSpPet(pet)
    local pModule = GameGlobal.GetModule(PetModule)
    local bindPet = pModule:GetBindPet(pet:GetTemplateID())
    if bindPet then
        local spID = bindPet:GetTemplateID()
        local spAirPet = self._main:GetPetByTmpID(spID)
        if spAirPet then
            --sp星灵出现在了风船里
            if
                (not self._main:IsGiftPet(spID) and not self._main:IsRandomStoryPet(spID) and spAirPet:IsWorkingPet()) or
                    self._main:IsRestPet(spID)
             then
                --需要被顶替
                return spID
            end
        end
    end
end
