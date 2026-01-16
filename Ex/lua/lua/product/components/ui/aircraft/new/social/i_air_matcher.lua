--[[
    @社交模板组队器 初始化数据
]]
_class("IAirMatcher", Object)
---@class IAirMatcher:Object
IAirMatcher = IAirMatcher

function IAirMatcher:Match(pets)
end

--region -----------------------------创建不同区域拥有的人--------------------------------

_class("InitAreaMatcher", IAirMatcher)
---@class InitAreaMatcher:IAirMatcher
InitAreaMatcher = InitAreaMatcher

function InitAreaMatcher:Match(pets, airMain)
    local areas = {}
    ---@type AircraftPet
    for _, pet in pairs(pets) do
        local area = AirHelper.GetArea(pet, areas, airMain)
        if area then
            area:AddPet(pet:TemplateID(), pet)
        end
    end

    return areas
end
--endregion

--region----------------------------判断关系配对 亲近/远离------------------------------

_class("RelationMatcher", IAirMatcher)
---@class RelationMatcher:IAirMatcher
RelationMatcher = RelationMatcher

function RelationMatcher:Match(areas)
    if not areas or #areas <= 0 then
        return {}
    end
    local newAreas = {}
    for index, area in ipairs(areas) do
        local pets = area:GetPets()
        local count = table.count(pets)
        -- 社交必须大于1个人
        if count > 1 then
            local match = true
            local closer, farAwayer = AirHelper.GetCloserAndFarAwayer(pets)
            if count == 2 then
                for petTempId, farPetTempIds in pairs(farAwayer) do
                    if #farPetTempIds > 0 then
                        match = false
                    end
                end
            elseif count >= 3 then
                --region 广度递归算法（图）--
                local graph = graph:New()
                graph:Clear()
                local petTempIds = {}
                for petTempId, value in pairs(pets) do
                    graph:AddVertex(petTempId)
                    table.insert(petTempIds, petTempId)
                end
                --  A            {B,C}
                for petTempId, closerPetTempIds in pairs(closer) do
                    for index, value in ipairs(closerPetTempIds) do
                        if not farAwayer[value] or not table.ikey(farAwayer[value], petTempId) then
                            graph:AddDirectedEdge(petTempId, value)
                        end
                    end
                end
                -- 最终匹配
                for i = 1, count do
                    local list = graph:BFSTraverse(i)
                    local finalCount = #list
                    -- 优先三人组cp
                    if finalCount == 3 then
                        break
                    elseif finalCount == 2 then -- 2人cp
                        for index, petTempId in ipairs(petTempIds) do
                            -- 在目标list
                            if not table.ikey(list, petTempId) then
                                area:RemovePet(petTempId)
                            end
                        end
                    elseif finalCount > 3 then -- 2人cp
                        local index = math.random(1, 2)
                        local middle = math.floor(finalCount * 0.5)
                        if index == 1 then
                            for j = middle, finalCount do
                                area:RemovePet(list[j])
                            end
                            break
                        elseif index == 2 then
                            for j = 1, middle do
                                area:RemovePet(list[j])
                            end
                            break
                        end
                    end
                end
            end
            if match then
                table.insert(newAreas, area)
            end
        end
    end
    return newAreas
end
--region -----------------------------匹配三种模板的人数----------------------------------

_class("AddLibMatcher", IAirMatcher)
---@class AddLibMatcher:IAirMatcher
AddLibMatcher = AddLibMatcher

-- 	两个人时，三种库都会触发
--	三个人时，只会触发聊天对话库、家具交互库
--  优先匹配家居库
function AddLibMatcher:Match(areas, main)
    if not areas or #areas <= 0 then
        return {}
    end
    local newAreas = {}
    for index, area in ipairs(areas) do
        local matchFurniture, pets = self:MatchFurniture(area, main)
        -- 优先匹配家居库
        if matchFurniture ~= nil then
            area:AddLib(AirSocialActionType.Furniture)
            -- 设置交互的家具
            area:SetFurniture(matchFurniture, pets)
            table.insert(newAreas, area)
        else
            local pets = area:GetPets()
            local count = table.count(pets)
            if count == 2 then
                area:AddLib(AirSocialActionType.Gather)
                area:AddLib(AirSocialActionType.WalkTalk)
                table.insert(newAreas, area)
            elseif count >= 3 then
                area:AddLib(AirSocialActionType.Gather)
                table.insert(newAreas, area)
            end
        end
    end
    return newAreas
end

-- 优先家具匹配库
---@param main AircraftMain
---@param area AirSocialArea
function AddLibMatcher:MatchFurniture(area, main)
    local f2Pet = {}
    local pets = area:GetPets()
    for key, pet in pairs(pets) do
        local fs = pet:GetInteractFurnitures()
        for index, data in ipairs(fs) do
            local furnitureType = data[1]
            -- local duration = data[2]
            if not f2Pet[furnitureType] then
                f2Pet[furnitureType] = {}
            end
            -- 找到可以可家具交互的所有宝宝
            table.insert(f2Pet[furnitureType], pet)
        end
    end
    ---@type AircraftRoom
    local room = area:GetRoom()
    if not room then
        Log.error("AddLibMatcher:MatchFurniture why no room!!!!!!!!!!!!!")
        return nil
    end
    -- 一个房间内所有的家具
    -- local fs = room:GetFurnitures()
    local fs = main:GetFurnituresBySpace(room:SpaceID())
    local newFurnitureTypes = {}
    -- 如果该房间内某个家具的可交互人数>2
    for furnitureType, value in pairs(fs) do
        if f2Pet[furnitureType] and #f2Pet[furnitureType] >= 2 then
            table.insert(newFurnitureTypes, furnitureType)
        end
    end
    -- 筛选可交互的家具（交互点>0）
    local filterFurnitures = {}
    for index, furnitureType in ipairs(newFurnitureTypes) do
        -- local furniture, index = room:GetFurniture(furnitureType)
        local furniture = main:GetFurniture(furnitureType)
        if furniture then
            if furniture:AvailableCount() >= 2 then
                table.insert(filterFurnitures, furniture)
            end
        end
    end
    --2021.1.26不根据家具索引确定优先级，家具删除索引字段 靳策修改
    -- table.sort(
    --     filterFurnitures,
    --     function(a, b)
    --         return a:GetIndex() < b:GetIndex()
    --     end
    -- )
    local count = table.count(filterFurnitures)
    if count >= 1 then
        local r = math.random(1, count)
        local betterFurniture = filterFurnitures[r]
        -- local betterFurniture = nil
        -- local r = nil
        -- for index, value in ipairs(filterFurnitures) do
        --     if value:Type() == 1004 then
        --         betterFurniture = value
        --         r = filterFurnituresIndex[index]
        --         break
        --     end
        -- end
        return betterFurniture, betterFurniture and f2Pet[betterFurniture:Type()] or nil
    else
        return nil, nil, nil
    end
end

--endregion 匹配三种模板的人数

--region ---------------------------------满足模板--------------------------------------
--如果一个区域满足多个社交模板，按社交模板的权重随机选择1个。

_class("FilterLibMatcher", IAirMatcher)
---@class FilterLibMatcher:IAirMatcher
FilterLibMatcher = FilterLibMatcher

function FilterLibMatcher:Match(areas)
    if not areas or #areas <= 0 then
        return {}
    end
    for _, area in ipairs(areas) do
        local libs = area:GetLibs()
        local count = table.count(libs)
        if count > 1 then
            local r = math.random(1, count)
            local keys = table.keys(libs)
            for index = 1, count do
                if index ~= r then
                    area:RemoveLib(keys[index])
                end
            end
        end
    end
    return areas
end

--endregion 满足模板

--region ------------------------------人数匹配最终模板------------------------------------
--	如果有多个人满足选中的社交模板，随机选择人员。

_class("FilterLibPetMatcher", IAirMatcher)
---@class FilterLibPetMatcher:IAirMatcher
FilterLibPetMatcher = FilterLibPetMatcher

function FilterLibPetMatcher:Match(areas)
    if not areas or #areas <= 0 then
        return {}
    end
    for _, area in ipairs(areas) do
        if area:GetFurniture() then
        else
            local pets = area:GetPets()
            local count = table.count(pets)
            -- 宝宝只有俩人则用俩
            if count <= 2 then
            else
                local targetNum = math.random(2, 3)
                local randomTime = count - targetNum
                if randomTime > 0 then
                    local r = {}
                    while (true) do
                        local d = math.random(1, count)
                        if not table.icontains(r, d) then
                            table.insert(r, d)
                        end
                        if #r == randomTime then
                            break
                        end
                    end
                    local keys = table.keys(pets)
                    for index = 1, count do
                        if table.icontains(r, index) then
                            area:RemovePet(keys[index])
                        end
                    end
                end
            end
        end
    end
    return areas
end
--endregion 人数匹配最终模板

--region--------------------------------- 满足区域----------------------------------
-- 如果没有满足模板条件的区域，则结束本轮逻辑。如果只有1个，
--则直接选择这个区域。如果有2个以上满足条件的区域，随机选择2个。

_class("FilterAreaMatcher", IAirMatcher)
---@class FilterAreaMatcher:IAirMatcher
FilterAreaMatcher = FilterAreaMatcher

function FilterAreaMatcher:Match(areas)
    ---@type AirSocialAreaData
    local filterAreas = {}
    if not areas or #areas == 0 then
        return filterAreas
    end

    local count = #areas
    if count > 2 then
        local _idx1 = math.random(1, count)
        local _idx2 = -1
        while true do
            local r = math.random(1, count)
            if r ~= _idx1 then
                _idx2 = r
                break
            end
        end
        table.insert(filterAreas, areas[_idx1])
        table.insert(filterAreas, areas[_idx2])
        return filterAreas
    else
        filterAreas = areas
    end
    return filterAreas
end
--endregion 满足模板条件的区域

--region ------------------------------初始化libMaker -----------------------------------

_class("InitLibMakerMatcher", IAirMatcher)
---@class InitLibMakerMatcher:IAirMatcher
InitLibMakerMatcher = InitLibMakerMatcher

function InitLibMakerMatcher:Match(areas)
    if not areas or #areas <= 0 then
        return {}
    end
    for index, _area in ipairs(areas) do
        ---@type AirSocialArea
        local area = _area
        area:InitLibMaker()
    end
    return areas
end
--endregion 人数匹配最终模板
