--[[
    风船序列化器
]]
---@class AircraftSerializer:Object
_class("AircraftSerializer", Object)
AircraftSerializer = AircraftSerializer
function AircraftSerializer:Constructor(main)
    ---@type AircraftMain
    self._main = main
    self._playerID = GameGlobal.GetModule(RoleModule):GetPstId()
    self.AIRCRAFTKEY = "AircraftActionKey"
    self.FLUSHTIME = 1200000 --重置时间间隔，20分钟
    self.saveTimeDelta = 10000
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
end
function AircraftSerializer:Init()
    AirLog("AircraftSerializer Init Start")
    if UnityEngine.PlayerPrefs.HasKey(self.AIRCRAFTKEY) then
        --小于重置事件，恢复上一次状态
        local s = UnityEngine.PlayerPrefs.GetString(self.AIRCRAFTKEY)
        ---@type AircraftSaveData
        local tt = string.totable(s)[1]
        if tt.playerID ~= self._playerID then
            --账号改变
            self._main:ResetPet()
        else
            local time = tt.time
            local deltaTime = self:now() - time
            if deltaTime > self.FLUSHTIME then
                --大于重置时间
                self._main:ResetPet()
            else
                local have = {}
                -----------------------------------------
                --恢复排队队列
                local queue = AircraftQueue:New()
                for _, id in ipairs(tt.queue) do
                    if self._main:IsRestPet(id) then
                        --检查sp星灵
                        local pets = {}
                        for petid, value in pairs(have) do
                            table.insert(pets,petid)
                        end
                        local sp = HelperProxy:GetInstance():CheckBinderID(pets,id)
                        if not sp then
                            queue:Enqueue(id)
                            have[id] = true
                        end
                    end
                end
                -----------------------------------------

                --------------------------------------------------------------
                ----单个星灵恢复行为
                -- 社交状态优先反序列化（需要占据PointHolder）
                for _, t in ipairs(tt.pets) do
                    if t.data and t.data.state == AirPetState.Social then
                        --检查sp星灵
                        local pets = {}
                        for petid, value in pairs(have) do
                            table.insert(pets,petid)
                        end
                        local sp = HelperProxy:GetInstance():CheckBinderID(pets,t.pet)
                        if not sp then
                            local success = self:Decode(t, deltaTime)
                            have[t.pet] = true
                            if not success then
                                if not sp then
                                    queue:Enqueue(t.pet)
                                end
                            end
                        end
                    end
                end
                -- 其他状态反序列化
                for _, t in ipairs(tt.pets) do
                    if t.data and t.data.state ~= AirPetState.Social then
                        --检查sp星灵
                        local pets = {}
                        for petid, value in pairs(have) do
                            table.insert(pets,petid)
                        end
                        local sp = HelperProxy:GetInstance():CheckBinderID(pets,t.pet)
                        if not sp then
                            local success = self:Decode(t, deltaTime)
                            have[t.pet] = true
                            if not success then
                                if not sp then
                                    queue:Enqueue(t.pet)
                                end
                            end
                        end
                    end
                end
                --------------------------------------------------------------
                --所有可以出现在风船中的星灵
                local airPetCfg = Cfg.cfg_aircraft_pet {}
                local airPet = {}
                for _, cfg in pairs(airPetCfg) do
                    local id = cfg.ID
                    airPet[id] = true
                end

                ------------------------------
                --查找背包中新获得的星灵
                ---@type PetModule
                local petModule = GameGlobal.GetModule(PetModule)
                ---@type MatchPet
                local bagPets = petModule:GetPetTabs()
                for id, pet in pairs(bagPets) do
                    if not have[id] and airPet[id] == true and self._main:IsRestPet(id) then
                        --检查sp星灵
                        local pets = {}
                        for petid, value in pairs(have) do
                            table.insert(pets,petid)
                        end
                        local sp = HelperProxy:GetInstance():CheckBinderID(pets,id)
                        if not sp then
                             --序列化数据中没有，并且能出现在风船中，则加入队列排队
                            queue:Enqueue(id)
                            have[id] = true
                        end
                    end
                end
                ------------------------------

                --恢复排队队列
                self._main:SetQueueAndInit(queue)
                --恢复社交行为
                self._main:NoticeSocialDecodeFinish()
            end
        end
    else
        self._main:ResetPet()
    end
    self._saveTime = self:now() + self.saveTimeDelta

    AirLog("AircraftSerializer Init Done")
end

function AircraftSerializer:Decode(t, deltaTime, queue)
    local id = t.pet
    if self._main:IsRestPet(id) then
        local time = t.data.remainTime - deltaTime
        --上次退出时间与本次进入的时间差超过了该行为的剩余时长，行为不能恢复则加入到排队queue
        if time <= 0 then
            return false
        else
            --没超过时长，恢复行为
            local pet = self._main:AddPet(id)
            if not pet then
                return false
            end
            local success = pet:Decode(t.data, time, self._main)
            if not success then
                self._main:DestroyPet(pet)
                return false
            end
        end
    end
    return true
end
function AircraftSerializer:GetSerializedTime()
    return UnityEngine.PlayerPrefs.GetFloat(self.TIMEKEY)
end

function AircraftSerializer:Update(deltaTimeMS)
    if self:now() > self._saveTime then
        self._saveTime = self._saveTime + self.saveTimeDelta
        self:SaveOnce()
    end
end

function AircraftSerializer:Reset()
    self._saveTime = self:now() + self.saveTimeDelta
end

--触发一次序列化
function AircraftSerializer:SaveOnce()
    AirLog("风船开始序列化")
    local pets =
        self._main:GetPets(
        function(p)
            ---@type AircraftPet
            local pet = p
            local state = pet:GetState()
            if
                not pet:IsWorkingPet() and
                    (state == AirPetState.OnFurniture or state == AirPetState.Social or state == AirPetState.Wandering or
                        state == AirPetState.Transiting or
                        state == AirPetState.InElevator or
                        state == AirPetState.Selected or
                        state == AirPetState.WaitingElevator)
             then
                return true
            else
                return false
            end
        end
    )
    local p = {}
    for _, pet in ipairs(pets) do
        local e = pet:Encode()
        if e then
            ---@type AircraftSavePet
            local t = {}
            t.pet = pet:TemplateID()
            t.data = e
            p[#p + 1] = t
        end
    end
    local q = self._main:GetScheduleQueue()
    ---@type AircraftSaveData
    local tt = {}
    tt.pets = p
    tt.queue = q
    tt.playerID = self._playerID
    tt.time = self:now()
    local s = table.tostring(tt)
    UnityEngine.PlayerPrefs.SetString(self.AIRCRAFTKEY, s)
    AirLog("风船序列化完成")
end

function AircraftSerializer:Dispose()
    self:SaveOnce()
    self._timeModule = nil
end

function AircraftSerializer:now()
    return self._main:Time()
end
