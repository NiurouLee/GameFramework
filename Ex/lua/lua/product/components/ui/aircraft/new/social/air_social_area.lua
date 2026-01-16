--[[
    @社交区域数据
]]
_class("AirSocialArea", Object)
---@class AirSocialArea:Object
AirSocialArea = AirSocialArea

local SOCIAL_TIME = 5 * 60 * 1000
local GATHER_ROUND = 20
local WALKTALK_ROUND = 20
local PER_TIME = 5000
function AirSocialArea:Constructor(aircraftMain)
    ---@type AircraftMain
    self.m_AirMain = aircraftMain
    ---@type table<number,AircraftPet>
    self.m_Pets = {}
    self.m_LibTypes = {}
    self.m_LibMaker = nil
    self.m_Furniture = nil
    self.m_SocialRound = 0
    self.m_RemainTime = 0
    self.log = ""
end

function AirSocialArea:Dispose(needRandom, isLeave)
    self:RandomAllPet(needRandom)
    self.m_LibTypes = {}
    if self.m_LibMaker then
        self.m_LibMaker:Dispose()
    end
    self.m_LibMaker = nil
    if not isLeave then
        -- 重置序列化信息
        for key, pet in pairs(self.m_Pets) do
            pet:ResetSocialParam()
        end
    end
    table.clear(self.m_Pets)
end

-- 为所有星灵随机行为
function AirSocialArea:RandomAllPet(needRandom)
    if self.m_Pets then
        for key, _pet in pairs(self.m_Pets) do
            ---@type AircraftPet
            local pet = _pet
            if needRandom and pet:IsAlive() then
                self.m_AirMain:RandomActionForPet(pet)
            else
                -- pet:SetState(AirPetState.Wandering)
            end
        end
    end
end

function AirSocialArea:StartAllPetAction()
    if self.m_Pets then
        for key, _pet in pairs(self.m_Pets) do
            ---@type AircraftPet
            local pet = _pet
            pet:StartIdleAction()
        end
    end
end

-- 设置所有星灵的社交状态
function AirSocialArea:SetAllPetSocialState()
    if self.m_Pets then
        for key, _pet in pairs(self.m_Pets) do
            ---@type AircraftPet
            local pet = _pet
            AirLog("星灵开始社交:", pet:TemplateID())
            pet:SetState(AirPetState.Social)
        end
    end
end
---virtual
function AirSocialArea:GetAreaType()
end

---@return table<number,AircraftPet>
function AirSocialArea:GetPets()
    return self.m_Pets
end

-- 添加星灵
function AirSocialArea:AddPet(petId, pet)
    self.m_Pets[petId] = pet
end

-- 移除星灵
function AirSocialArea:RemovePet(petId)
    self.m_Pets[petId] = nil
end

-- 添加社交行为
function AirSocialArea:AddLib(libType)
    self.m_LibTypes[libType] = true
end

-- 获取社交行为组
function AirSocialArea:GetLibs()
    return self.m_LibTypes
end

-- 移出社交行为
function AirSocialArea:RemoveLib(libType)
    self.m_LibTypes[libType] = nil
end

--获取房间 AircraftRoom
function AirSocialArea:GetRoom()
    Log.error("AirSocialArea:GetRoom() need override")
    return nil
end

-- 设置交互的家具
function AirSocialArea:SetFurniture(f, pets)
    ---@type AircraftFurniture
    self.m_Furniture = f --家具
    if not pets then
    else
        -- 顺便设置家具交互的人 ，TODO
        table.clear(self.m_Pets)
        -- real pet count
        self.m_Pets = {}
        local allCount = self.m_Furniture:AvailableCount()
        local index = 0
        for _, pet in pairs(pets) do
            index = index + 1
            if index <= allCount then
                self:AddPet(pet:TemplateID(), pet)
            end
        end
        for key, pet in pairs(self.m_Pets) do
            pet:SetSocialFurnitureKey(self.m_Furniture:GetPstKey())
        end
    end
end

function AirSocialArea:GetFurniture()
    return self.m_Furniture
end

-- 是否为家具交互
function AirSocialArea:IsFurnitureInteract()
    return self.m_Furniture ~= nil
end
----------------------------------------------------------------
--最终的社交行为
function AirSocialArea:GetMainLibType()
    if not self.m_FinalLibType then
        self.m_FinalLibType = table.keys(self.m_LibTypes)[1]
    end
    return self.m_FinalLibType
end

function AirSocialArea:InitLibMaker(isSerialize)
    if isSerialize then
        local curCount = table.count(self.m_Pets)
        local expectCount = self.m_SocialPetCount
        if expectCount ~= curCount then
            return true -- 期望数量和当前数量不相等 需要移除
        end
    end
    ---@type AirLibMaker
    self.m_LibMaker = AirLibMaker:New(self, self.m_AirMain)
    self:CalRemainTimeByRound()
    for key, pet in pairs(self.m_Pets) do
        pet:SetSocialActionType(self:GetMainLibType())
    end
    self:SetSocialPetCount(table.count(self.m_Pets), true) -- 检查由于特殊原因 扥走的
    self:InitMaxRound() -- 总回合
    --娱乐区设置type
    local type = self:GetAreaType()
    if type == AirSocialAreaType.Happy then
        local type = self:GetRestAreaType()
        for key, pet in pairs(self.m_Pets) do
            pet:SetSocialAreaType(type)
        end
    end
    --debug--
    math.randomseed(os.clock() * 1000000)
    local teamId = math.random(1, 99999)
    for key, value in pairs(self.m_Pets) do
        value.a = self:GetMainLibType() .. "  " .. teamId
    end
    --debug--
end

-- local AircraftSocialTag = {
--     Hot = 1, -- 热情
--     Normal = 2, -- 正常
--     Lone = 3 -- 孤僻
-- }
function AirSocialArea:InitMaxRound()
    self.m_MaxRound = 0
    for key, pet in pairs(self.m_Pets) do
        local id = pet:TemplateID()
        local cfg = Cfg.cfg_aircraft_pet[id]
        if cfg and cfg.SocialTag then
            local tag = cfg.SocialTag
            local key
            if tag == AircraftSocialTag.Hot then
                key = "aircraft_social_reqing_time"
            elseif tag == AircraftSocialTag.Normal then
                key = "aircraft_social_zhengchang_time"
            elseif tag == AircraftSocialTag.Lone then
                key = "aircraft_social_lengmo_time"
            end
            -- body
            local value = Cfg.cfg_aircraft_const[key].IntValue
            self.m_MaxRound = self.m_MaxRound + value
        end
    end
    if self.m_MaxRound == 0 then
        self.m_MaxRound = 20
    end
end
function AirSocialArea:GetLibMaker()
    return self.m_LibMaker
end

------------------------------------------序列化相关-------------------------------------
---开始状态
function AirSocialArea:GetStateTypes()
    local index = 1
    local mainType = self:GetMainLibType()
    if mainType == AirSocialActionType.Gather then
        if self.m_SocialRound > 0 then -- 0 / 2
            -- 定位->朝向->对话
            return {
                AirGroupActionStateType.Located,
                AirGroupActionStateType.LookAt,
                AirGroupActionStateType.Talk
            }
        else
            -- 移动->朝向->对话
            return {
                AirGroupActionStateType.Move,
                AirGroupActionStateType.LookAt,
                AirGroupActionStateType.Talk
            }
        end
    elseif mainType == AirSocialActionType.WalkTalk then
        if self.m_SocialRound > 0 then
            return {AirGroupActionStateType.Located, AirGroupActionStateType.MoveTalk}
        else
            return {AirGroupActionStateType.Move, AirGroupActionStateType.MoveTalk}
        end
    elseif mainType == AirSocialActionType.Furniture then
        if self.m_SocialRound > 0 then -- 8 / 10
            return {AirGroupActionStateType.Located, AirGroupActionStateType.FurnitureTalk}
        else
            return {AirGroupActionStateType.Move, AirGroupActionStateType.FurnitureTalk}
        end
    end
end

--round 第几回合
--index 第几个人
--calRemainTime 是否
function AirSocialArea:SetSocialRound(round, syn)
    self.m_SocialRound = round
    if syn then
        for key, pet in pairs(self.m_Pets) do
            pet:SetSocialRound(self.m_SocialRound)
        end
        self:CalRemainTimeByRound()
    end
end

function AirSocialArea:GetSocialRound()
    return self.m_SocialRound
end

function AirSocialArea:_SetRemainTime(time)
    self.m_RemainTime = time
    for key, pet in pairs(self.m_Pets) do
        pet:SetSocialRemainTime(self.m_RemainTime)
    end
end

function AirSocialArea:GetMaxRound()
    local finalType = self:GetMainLibType()
    if finalType == AirSocialActionType.Gather then
        return self.m_MaxRound
    elseif finalType == AirSocialActionType.WalkTalk then
        return self.m_MaxRound
    end
    return 0
end
---
function AirSocialArea:CalRemainTimeByRound()
    local remainTime = 0
    local finalType = self:GetMainLibType()
    if finalType == AirSocialActionType.Gather then
        if self.m_SocialRound > 0 then
            remainTime = (GATHER_ROUND - self.m_SocialRound) * PER_TIME
        else
            remainTime = SOCIAL_TIME
        end
    elseif finalType == AirSocialActionType.WalkTalk then
        if self.m_SocialRound > 0 then
            remainTime = (WALKTALK_ROUND - self.m_SocialRound) * PER_TIME
        else
            remainTime = SOCIAL_TIME
        end
    elseif finalType == AirSocialActionType.Furniture then
        if AirHelper.IsActionSeqFurniture(self.m_Furniture) then
            remainTime = self.m_LibMaker:GetSeqMaker():GetRemainTime(self.m_SocialRound, 1)
        else
            remainTime = SOCIAL_TIME
        end
    end
    self:_SetRemainTime(remainTime)
end

function AirSocialArea:GetRemainTime()
    return self.m_RemainTime
end

function AirSocialArea:SetSocialPointHolderIndex(pointHolderIndex, syn)
    self.m_SocialPointHolderIndex = pointHolderIndex
    if syn then
        for key, pet in pairs(self.m_Pets) do
            pet:SetSocialPointHolderIndex(self.m_SocialPointHolderIndex)
        end
    end
end

function AirSocialArea:GetSocialPointHolderIndex()
    return self.m_SocialPointHolderIndex
end

function AirSocialArea:SetSocialPetCount(count, syn)
    self.m_SocialPetCount = count
    if syn then
        for key, pet in pairs(self.m_Pets) do
            pet:SetSocialPetCount(self.m_SocialPetCount)
        end
    end
end

function AirSocialArea:GetSocialPetCount()
    return self.m_SocialPetCount
end
--]]
-------------------------------------------------------------------------------------------
--region 工作区数据
---@class AirSocialWorkArea:AirSocialArea
_class("AirSocialWorkArea", AirSocialArea)
AirSocialWorkArea = AirSocialWorkArea

function AirSocialWorkArea:GetAreaType()
    return AirSocialAreaType.Work
end
function AirSocialWorkArea:SetSpaceId(spaceId)
    self.m_SpaceId = spaceId
end

function AirSocialWorkArea:GetSpaceId()
    return self.m_SpaceId
end

function AirSocialWorkArea:GetRoom()
    return self.m_AirMain:GetRoomBySpaceID(self.m_SpaceId)
end

--endregion 工作区数据

--region 娱乐区数据
---@class AirSocialHappyArea:AirSocialArea
_class("AirSocialHappyArea", AirSocialArea)
AirSocialHappyArea = AirSocialHappyArea

function AirSocialHappyArea:GetAreaType()
    return AirSocialAreaType.Happy
end

---@type AirRestAreaType
function AirSocialHappyArea:SetRestAreaType(type)
    self.m_RestAreaType = type
end

---@type AirRestAreaType
function AirSocialHappyArea:GetRestAreaType()
    return self.m_RestAreaType
end

function AirSocialHappyArea:GetRoom()
    return self.m_AirMain:GetRoomByArea(self.m_RestAreaType)
end

--endregion 娱乐区数据
