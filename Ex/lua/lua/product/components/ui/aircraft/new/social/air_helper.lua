--[[
    @风船辅助类
]]
---@class AirHelper
_class("AirHelper", Object)
AirHelper = AirHelper

function AirHelper.GetArea(pet, areas, airMain, areaType)
    local areaType = areaType or pet:GetWanderingArea()
    -- local spaceId = pet:GetSpace()
    -- 工作区
    -- if spaceId then
    --     local targetArea = nil
    --     for _, area in ipairs(areas) do
    --         if spaceId == area:GetSpaceId() then
    --             targetArea = area
    --             break
    --         end
    --     end
    --     if targetArea then
    --         return targetArea
    --     else
    --         return AirHelper.CreateArea(pet, areas, airMain, areaType)
    --     end
    -- elseif areaType then -- 娱乐区
    if areaType then -- 娱乐区
        local targetArea = nil
        for _, area in ipairs(areas) do
            if areaType == area:GetRestAreaType() then
                targetArea = area
                break
            end
        end
        if targetArea then
            return targetArea
        else
            return AirHelper.CreateArea(pet, areas, airMain, areaType)
        end
    end
end
---@param pet AircraftPet
function AirHelper.CreateArea(pet, areas, airMain, areaType)
    local areaType = areaType or pet:GetWanderingArea()
    -- local spaceId = pet:GetSpace()
    local area
    -- 工作区
    -- if spaceId then
    --     area = AirSocialWorkArea:New(airMain)
    --     area:SetSpaceId(spaceId)
    -- elseif areaType then -- 娱乐区
    if areaType then -- 娱乐区
        area = AirSocialHappyArea:New(airMain)
        area:SetRestAreaType(areaType)
    end
    table.insert(areas, area)
    return area
end

-- 是否是播动画序列的家具
function AirHelper.IsActionSeqFurniture(furniture)
    if furniture then
        -- 家具类型
        local fType = furniture:Type()
        local cfgs = Cfg.cfg_aircraft_action_sequence {seqType = fType}
        if cfgs then
            -- seq类型 证明是特殊家具
            return table.count(cfgs) > 0
        else
            return false
        end
    else
        return false
    end
end

-- 通过势力类型获取所有的petTempIds
function AirHelper.GetPetTempIdsByShiLi(targetShiLi)
    local cfgs = Cfg.cfg_pet {}
    local tbl = {}
    for key, petCfg in pairs(cfgs) do
        local tags = petCfg.Tags
        if tags and tags[1] then
            local shili = tags[1]
            if shili == targetShiLi then
                table.insert(tbl, petCfg.ID)
            end
        end
    end
    return tbl
end

---@param pets table<number,AircraftPet>
function AirHelper.GetCloserAndFarAwayer(pets)
    ---@type  table<number,AircraftPet>
    local _pets = table.toArray(pets)
    local closer = {}
    local farAwayer = {}
    for index, pet in ipairs(_pets) do
        local clonePets = table.shallowcopy(_pets)
        -- 移出自身
        table.remove(clonePets, index)
        for _, pet2 in ipairs(clonePets) do
            local isCloser = pet:IsCloserToMe(pet2:TemplateID())
            if isCloser then
                if not closer[pet:TemplateID()] then
                    closer[pet:TemplateID()] = {}
                end
                table.insert(closer[pet:TemplateID()], pet2:TemplateID())
            end
            local isFaraway = pet:IsFarAwayFromMe(pet2:TemplateID())
            if isFaraway then
                if not farAwayer[pet:TemplateID()] then
                    farAwayer[pet:TemplateID()] = {}
                end
                table.insert(farAwayer[pet:TemplateID()], pet2:TemplateID())
            end
        end
    end
    return closer, farAwayer
end

function AirHelper.InSphere(targetPos, centerPos, radius)
    local value =
        math.pow(targetPos.x - centerPos.x, 2) + math.pow(targetPos.y - centerPos.y, 2) +
        math.pow(targetPos.z - centerPos.z, 2)
    return value <= radius * radius
end

-- 因亲近远离随机行为
---@param main AircraftMain
---@param mainPet AircraftPet
function AirHelper.RandomRelationPet(main, mainPet)
    local random = false
    if main then
        local pets =
            main:GetPets(
            function(_pet)
                if _pet:PstID() == mainPet:PstID() then
                    return false
                end
                local state = _pet:GetState()
                if state == AirPetState.Wandering or state == AirPetState.OnFurniture then
                    if AirHelper.InSphere(_pet:WorldPosition(), mainPet:WorldPosition(), 0.5) then -- 在圆内
                        return true
                    else
                        return false
                    end
                end
                return false
            end
        )
        --自己离开
        for index, pet in ipairs(pets) do
            local far = mainPet:IsFarAwayFromMe(pet)
            mainPet.yuanli = false
            -- 我远离他
            if far then
                pet.yuanli = true
                pet.yuanlilog = mainPet:PetName() .. "远离" .. pet:PetName()
                Log.error(pet.yuanlilog)
                random = true
                break
            end
        end
        -- 别人离开
        for index, pet in ipairs(pets) do
            local far = pet:IsFarAwayFromMe(mainPet)
            pet.yuanli = false
            -- 我远离他
            if far then
                pet.yuanli = true
                pet.yuanlilog = pet:PetName() .. "远离" .. mainPet:PetName()
                Log.error(pet.yuanlilog)
                main:RandomActionForPet(pet)
            end
        end
    end

    return random
end

function AirHelper.CalcPetList(petTempIDs)
    if table.count(petTempIDs) > 1 then
        local ret = petTempIDs[1]
        if table.count(petTempIDs) >= 2 then
            for i = 2, #petTempIDs do
                ret = ret ~ petTempIDs[i]
            end
        end
        return ret
    end
end
---@param petList AircraftPet[]
function AirHelper.CheckSocialGroupTalk(petList, type, param)
    return true
end

function AirHelper.GetSocialTalkIsTalkList()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()

    local groupTalk1 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk1")
    local groupTalk2 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk2")
    local groupTalk3 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk3")
    local groupTalk4 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk4")
    local groupTalk5 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk5")
    local ret = {}
    table.insert(ret, groupTalk1)
    table.insert(ret, groupTalk2)
    table.insert(ret, groupTalk3)
    table.insert(ret, groupTalk4)
    table.insert(ret, groupTalk5)
    return ret
end
--TODO 优化一下写法
function AirHelper.SetSocialTalkIsTalk(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()

    local groupTalk1 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk1")
    local groupTalk2 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk2")
    local groupTalk3 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk3")
    local groupTalk4 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk4")
    local groupTalk5 = UnityEngine.PlayerPrefs.GetInt(pstId .. "LastSocialTalk5")
    if not groupTalk1 then
        UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk1", id)
        return
    end
    if not groupTalk2 then
        UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk2", id)
        return
    end
    if not groupTalk3 then
        UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk3", id)
        return
    end
    if not groupTalk4 then
        UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk4", id)
        return
    end
    if not groupTalk5 then
        UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk5", id)
        return
    end
    UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk5", id)
    UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk4", groupTalk5)
    UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk3", groupTalk4)
    UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk2", groupTalk3)
    UnityEngine.PlayerPrefs.SetInt(pstId .. "LastSocialTalk1", groupTalk2)
end

---@param petList AircraftPet[]
function AirHelper.GetGroupTalk(petList)
    local paramPetTemplIDs = {}
    for i, pet in pairs(petList) do
        table.insert(paramPetTemplIDs, pet:TemplateID())
    end
    local lastTalkIDList = AirHelper.GetSocialTalkIsTalkList()
    local param = AirHelper.CalcPetList(paramPetTemplIDs)
    local cfgTable = Cfg.cfg_aircraft_group_talk()
    local validCfgIDList = {}
    for id, cfg in ipairs(cfgTable) do
        local petIDList = cfg.GroupMember
        local num = AirHelper.CalcPetList(petIDList)
        ---TODO是否符合条件判断,需求没具体的例子暂时没写  写就是根据type在这里判断就好了
        if
            num == param and not table.icontains(lastTalkIDList, id) and
                AirHelper.CheckSocialGroupTalk(petList, cfg.ConditionType, cfg.ConditionParam)
         then
            table.insert(validCfgIDList, id)
        end
    end
    local cfg = nil
    local id
    if #validCfgIDList == 1 then
        id = validCfgIDList[1]
        cfg = cfgTable[id]
    elseif #validCfgIDList > 2 then
        local idIndex = math.random(1, #validCfgIDList)
        id = validCfgIDList[idIndex]
        cfg = cfgTable[id]
    end
    if id then
        AirHelper.SetSocialTalkIsTalk(id)
    end
    return cfg
end
