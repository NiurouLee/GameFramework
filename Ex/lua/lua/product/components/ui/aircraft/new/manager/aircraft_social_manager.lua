_class("AircraftSocialManager", Object)
---@class AircraftSocialManager:Object
AircraftSocialManager = AircraftSocialManager
local SOCIAL_DISPATCH = true -- 触发行为
local SOCIAL_OPEN = true -- 社交触发开关
local CHECK_TIME = 1000 * 60 * 5

---@param aircraftMain AircraftMain
function AircraftSocialManager:Constructor(aircraftMain)
    self.m_AirMain = aircraftMain
    self.m_Areas = {}
    ---@type table<number,AirGroupActionExecutor>
    self.m_Executors = {}
    self.m_SerializeIng = false -- 是否是序列化中
    self:InitFilter() -- 筛选
    self:InitMatcher() -- 组队
    self:AddListener()
    self:InitParams()
    ---统一的用来判断相机是否足够近
    self.m_SocialCamNearby = false
end

-- 初始化一些必要参数
function AircraftSocialManager:InitParams()
    local open = Cfg.cfg_aircraft_const["aircraft_social_open"]
    SOCIAL_OPEN = open and open.IntValue or 1
    if SOCIAL_OPEN == 1 then
        SOCIAL_OPEN = true
    else
        SOCIAL_OPEN = false
    end
    local time = Cfg.cfg_aircraft_const["aircraft_social_check_time"]
    CHECK_TIME = time and time.IntValue or 1000 * 60 * 5
    -- CHECK_TIME = 1000 * 10
end
function AircraftSocialManager:AddListener()
    self.cb = GameHelper:GetInstance():CreateCallback(self.ExecuteSocialAction, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.AirForceTriggerSocialAction, self.cb)
end

function AircraftSocialManager:RemoveListener()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.AirForceTriggerSocialAction, self.cb)
end

function AircraftSocialManager:Dispose()
    self:RemoveListener()
    self:DisposeExecutors(false)
    self:StopTimer()
end

function AircraftSocialManager:DisposeExecutors(needRandom)
    if self.m_Executors then
        for _, e in ipairs(self.m_Executors) do
            e:Dispose(needRandom, true)
        end
    end
    self.m_Executors = {}
end
--N分钟一触发
function AircraftSocialManager:StartTimer()
    self.timer = GameGlobal.Timer():AddEventTimes(CHECK_TIME, TimerTriggerCount.Infinite, self.CheckTrigger, self)
    self:CheckTrigger()
end

function AircraftSocialManager:CheckTrigger()
    ---TODO---
    if self.m_SerializeIng == true then
        return
    end
    -- if #self.m_Executors > 0 then
    --     return
    -- end
    -- 晒选基础条件
    local pets =
        self.m_AirMain:GetPets(
        function(_pet)
            ---@type AircraftPet
            local pet = _pet
            if pet:IsAlive() then
                local state = pet:GetState()
                if state ~= AirPetState.Wandering then
                    return false
                end
                local can = self:Filter(pet)
                return true
            end
        end,
        true
    )
    if pets and #pets > 1 then
        local areas = self:Match(pets)
        if areas and #areas > 0 then
            self:Dispatch(areas)
        end
    end
end
function AircraftSocialManager:StopTimer()
    if self.timer then
        GameGlobal.Timer():CancelEvent(self.timer)
        self.timer = nil
    end
end

function AircraftSocialManager:Init()
    if not SOCIAL_OPEN then
        return
    end
    self:StartTimer()
end
function AircraftSocialManager:Update(deltaTimeMS)
end

--- 初始化星灵过滤器
function AircraftSocialManager:InitFilter()
    -- 保证顺序
    self.filters = {
        SocialWeightFilter:New(), -- 社交参与权重
        AreaFilter:New() -- 是否在规定区域
    }
end

--- 初始化组团器
function AircraftSocialManager:InitMatcher()
    self.matchers = {
        InitAreaMatcher:New(), -- 初始化所有满足条件的区域
        RelationMatcher:New(),
        AddLibMatcher:New(), -- 添加人数对应的模板
        FilterLibMatcher:New(), -- N模板选1
        FilterLibPetMatcher:New(), --N人选m
        FilterAreaMatcher:New(), -- 筛选最多2个区域
        InitLibMakerMatcher:New() -- Init lib maker
    }
end

-- 过滤
function AircraftSocialManager:Filter(pet)
    local count = 0
    for _, filter in ipairs(self.filters) do
        local can = filter:Filter(pet)
        if can then
            count = count + 1
        end
    end
    return count == #self.filters
end

local AirRestAreaTypeName = {
    [AirRestAreaType.RestRoom] = "休息室",
    [AirRestAreaType.CoffeeHouse] = "咖啡厅",
    [AirRestAreaType.Bar] = "酒吧",
    [AirRestAreaType.EntertainmentRoom] = "娱乐室",
    [AirRestAreaType.Board3] = "3层甲板",
    [AirRestAreaType.Board4] = "4层甲板",
    [AirRestAreaType.CenterRoom] = "主控室"
}
-- 组团
function AircraftSocialManager:Match(pets)
    ---@type table<number,AirSocialHappyArea>
    local areas = self.matchers[1]:Match(pets, self.m_AirMain)
    Log.error("社交匹配@@@第1阶段：初始化所有区域和人")
    Log.error("社交匹配@@@1.当前区域个数", #areas)
    for index, area in ipairs(areas) do
        self.log1 = ""
        self.log1 = self.log1 .. "社交匹配@@@1.区域类型:" .. AirRestAreaTypeName[area:GetRestAreaType()] .. "  "
        for index, pet in pairs(area:GetPets()) do
            self.log1 = self.log1 .. pet:PetName() .. ","
        end
        Log.error(self.log1)
    end

    for index = 2, #self.matchers do
        areas = self.matchers[index]:Match(areas, self.m_AirMain)
        Log.error("社交匹配@@@第", index, "阶段：", self.matchers[index]._className)
        Log.error("社交匹配@@@", index, ".当前区域个数", #areas)
        for _, area in ipairs(areas) do
            self.log2 = ""
            self.log2 = self.log2 .. "社交匹配@@@", index, ".区域类型:" .. AirRestAreaTypeName[area:GetRestAreaType()] .. "  "
            for _, pet in pairs(area:GetPets()) do
                self.log2 = self.log2 .. pet:PetName() .. ","
            end
            Log.error(self.log2)
        end
    end

    return areas
end

-- 发送(已经是最终人选)
function AircraftSocialManager:Dispatch(areas)
    if not SOCIAL_DISPATCH then
        return
    end
    for key, area in pairs(areas) do
        -- 设置所有人社交状态
        area:SetAllPetSocialState()
        local executor =
            AirGroupActionExecutor:New(
            self.m_AirMain,
            area,
            function(executor)
                if executor then
                    executor:Dispose(true)
                    table.removev(self.m_Executors, executor)
                end
            end
        )
        table.insert(self.m_Executors, executor)
    end
end
function AircraftSocialManager:DecodeFinish()
    self.m_SerializeIng = false
    local removeIndex = {}
    for index, area in ipairs(self.m_Areas) do
        local remove = area:InitLibMaker(true)
        if remove then
            table.insert(removeIndex, index)
        end
    end
    if #removeIndex > 0 then
        for i = #removeIndex, 1, -1 do
            table.remove(self.m_Areas, removeIndex[i])
        end
    end
    self:Dispatch(self.m_Areas)
end

-- 用于序列化 强行触发社交行为
function AircraftSocialManager:ExecuteSocialAction(_pet)
    self.m_SerializeIng = true
    ---@type AircraftPet
    local pet = _pet
    if not pet then
        return
    end
    local airSocialActionType = pet:GetSocialActionType()
    local round = pet:GetSocialRound()
    local pointHolderIndex = pet:GetSocialPointHolderIndex()
    local furnitureKey = pet:GetSocialFurnitureKey()
    local restType = pet:GetSocialAreaType()
    local allPetCount = pet:GetSocialPetCount()
    ---@type AirSocialArea
    local area = AirHelper.GetArea(pet, self.m_Areas, self.m_AirMain, restType)
    area:AddPet(pet:TemplateID(), pet)
    area:AddLib(airSocialActionType)
    if furnitureKey then
        if not area:GetFurniture() then
            local furniture = self.m_AirMain:GetFurnitureByKey(furnitureKey)
            -- 设置指定家具
            area:SetFurniture(furniture)
        end
    end
    area:SetSocialRound(round)
    area:SetSocialPointHolderIndex(pointHolderIndex)
    area:SetSocialPetCount(allPetCount)
end

-- 停止社交行为
function AircraftSocialManager:StopSocialByPet(targetPet)
    if targetPet and targetPet:GetState() == AirPetState.Social then
        local targetExecutor = false
        for index, group in ipairs(self.m_Executors) do
            local pets = group:GetPets()
            for key, pet in pairs(pets) do
                if pet == targetPet then
                    targetExecutor = group
                    break
                end
            end
        end
        if targetExecutor then
            local log = ""
            --除了目标外的所有人随机一个行为
            local pets = targetExecutor:GetPets()
            for index, pet in pairs(pets) do
                if pet ~= targetPet then
                    self.m_AirMain:RandomActionForPet(pet)
                    log = log .. pet:TemplateID() .. "，"
                end
            end
            targetExecutor:Dispose(false)
            table.removev(self.m_Executors, targetExecutor)
            AirLog("1个星灵打断社交行为:", targetPet:TemplateID(), "，其余星灵：", log)
        end
    end
end

---通过家具停止社交
function AircraftSocialManager:StopSocialByFurniture(furID)
    ---@type table<number,AirGroupActionExecutor>
    local needRemove = {}
    for index, group in ipairs(self.m_Executors) do
        local targetFur = group:GetAreaFurniture()
        if targetFur and targetFur:InstanceID() == furID then
            needRemove[#needRemove + 1] = group
        end
    end

    for _, group in ipairs(needRemove) do
        for index, pet in pairs(group:GetPets()) do
            self.m_AirMain:RandomActionForPet(pet)
        end
        group:Dispose(false)
        table.removev(self.m_Executors, group)
    end
end

function AircraftSocialManager:SetCamNearbyState(state)
    self.m_SocialCamNearby = state
end

function AircraftSocialManager:GetCamNearbyState()
    return self.m_SocialCamNearby
end

function AircraftSocialManager:OnPetDestroy(pet)
    self:StopSocialByPet(pet)
end

---@param pet AircraftPet
function AircraftSocialManager:GetSocialGroupPets(pet)
    if pet and pet:GetState() == AirPetState.Social then
        local targetExecutor = nil
        for index, group in ipairs(self.m_Executors) do
            ---@type table<number,AircraftPet>
            local pets = group:GetPets()
            for key, p in pairs(pets) do
                if p:TemplateID() == pet:TemplateID() then
                    return pets
                end
            end
        end
    end
end

--------------------------------------------------------------------家具上社交相关
---@param pet AircraftPet
---@param action AirActionOnFurniture
function AircraftSocialManager:OnFurnitureActionStart(pet, fur, action)
end

function AircraftSocialManager:OnFurnitureActionStop()
end
---------------------------------------------------------------------
