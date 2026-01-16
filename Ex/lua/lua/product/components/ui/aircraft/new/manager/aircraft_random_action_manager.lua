--[[
    风船随机行为控制器
]]
_class("AircraftRandomActionManager", Object)
---@class AircraftRandomActionManager:Object
AircraftRandomActionManager = AircraftRandomActionManager

---@param aircraftMain AircraftMain
function AircraftRandomActionManager:Constructor(aircraftMain)
    ---@type AircraftMain
    self._main = aircraftMain
end
function AircraftRandomActionManager:Init()
    ---@type table<number,AircraftBoard>
    self._boards = self._main:GetAllBoards()
end
function AircraftRandomActionManager:Update(deltaTimeMS)
end
function AircraftRandomActionManager:Dispose()
end

---@param pet AircraftPet
function AircraftRandomActionManager:RandomActionForPet(pet)
    self:_randomForPet(pet, false)
end

---@param pet AircraftPet
function AircraftRandomActionManager:RandomInitActionForPet(pet)
    self:_randomForPet(pet, true)
end

function AircraftRandomActionManager:_randomForPet(pet, isInit)
    --[[
        为星灵随机行为：
        1.根据星灵状态，获取行为库id
        2.根据权重随机生成一个行为列表
        3.遍历列表，找到第一个可执行的行为
        4.实例化具体的行为类，开始执行
    ]]
    local lib = self:_1_getLib(pet)
    local list = self:_2_getActionList(pet, lib)
    local action = self:_3_getValidAction(pet, list, isInit)
    self:_4_startAction(pet, action, isInit)
end

---@param pet AircraftPet
function AircraftRandomActionManager:_1_getLib(pet)
    local petID = pet:TemplateID()
    local actionLibID = -1
    --送礼和拜访星灵，会走特殊的随即行为库
    if pet:IsGiftPet() or pet:IsVisitPet() then
        actionLibID = Cfg.cfg_aircraft_pet[petID].GiftLib
    else
        actionLibID = Cfg.cfg_aircraft_pet[petID].ActionLib
    end
    local cfg = Cfg.cfg_aircraft_random_actions[actionLibID]
    if cfg == nil then
        Log.exception("找不到行为，星灵id：", petID, "，配置：", actionLibID)
    end
    return cfg
end

function AircraftRandomActionManager:_2_getActionList(pet, cfgLib)
    ---@type table<number,PetCfgAction>
    local list = {}
    local totalWeight1 = cfgLib.WWeight + cfgLib.FWeight
    local wweight = cfgLib.WWeight / totalWeight1
    local fweight = cfgLib.FWeight / totalWeight1
    local totalWeightWander = 0
    for _, cfg in ipairs(cfgLib.WAreas) do
        totalWeightWander = totalWeightWander + cfg[3]
    end
    local totalWeightFurArea = 0
    for _, cfg in ipairs(cfgLib.FAreas) do
        totalWeightFurArea = totalWeightFurArea + cfg[2]
    end
    local totalWeightFur = 0
    for _, cfg in ipairs(cfgLib.FFurniture) do
        totalWeightFur = totalWeightFur + cfg[3]
    end

    local w = 0
    local idx = 1
    for _, cfg in ipairs(cfgLib.WAreas) do
        list[#list + 1] = {
            Index = idx,
            Type = AirRandomActionType.Wandering,
            Area = cfg[1],
            Duration = cfg[2],
            Weight = cfg[3] / totalWeightWander * wweight,
            Condition = cfg[4] --可空
        }
        idx = idx + 1
        w = w + cfg[3] / totalWeightWander * wweight
    end
    for _, cfg in ipairs(cfgLib.FAreas) do
        local aweight = cfg[2] / totalWeightFurArea
        for __, cfgF in ipairs(cfgLib.FFurniture) do
            list[#list + 1] = {
                Index = idx,
                Type = AirRandomActionType.Furniture,
                Area = cfg[1],
                Duration = cfgF[2],
                Weight = cfgF[3] / totalWeightFur * aweight * fweight,
                FurType = cfgF[1],
                Condition = cfgF[4] --可空
            }
            w = w + cfgF[3] / totalWeightFur * aweight * fweight
            idx = idx + 1
        end
    end

    --按权重随机排列算法
    local cur = 1
    local weight = 1.0
    while cur < #list do
        local r = math.random() * weight
        local temp = 0
        local target = cur
        for i = cur, #list - cur + 1 do
            temp = temp + list[i].Weight
            if temp >= r then
                target = i
                break
            end
        end
        weight = weight - list[target].Weight
        if cur ~= target then
            --交换
            local t = list[cur]
            list[cur] = list[target]
            list[target] = t
        end
        cur = cur + 1
    end
    return list
end

---@param pet AircraftPet
---@param list table<number,PetCfgAction>
function AircraftRandomActionManager:_3_getValidAction(pet, list, isInit)
    local currentIdx = pet:GetRandomActionCfgID()
    for _, action in ipairs(list) do
        --第1条件：不等于上次行为
        if action.Index ~= currentIdx then
            if action.Type == AirRandomActionType.Wandering then
                local area = action.Area
                --漫游只有1个条件，该区域漫游人数没到上限
                if self._main:CanWanderingInArea(area) then
                    return action
                end
            elseif action.Type == AirRandomActionType.Furniture then
                local area = action.Area
                local furType = action.FurType
                if isInit and furType == AirFurnitureType.RestEmpty then
                    --初始化时，不让星灵随到去空地，因为空地可能跟其他家具重叠，只要初始化不随上去，运行过程中星灵走不过去 靳策 2021.7.13
                    --MSG26291	【现网】【偶现】（测试_郭简宁）鳄鱼停留位置,进入装扮模式，放家具后，鳄鱼模型和后面家具交互光灵重合
                    AirLog("初始化时随到了星灵去空地, 不处理, 星灵:", pet:TemplateID(), ", 索引:", action.Index)
                else
                    ---@type table<number,AircraftFurniture> key是家具的InstanceID
                    local furs = self._main:GetFurnituresByArea(area)
                    for _, fur in pairs(furs) do
                        if fur:Type() == furType then
                            local condCfg = action.Condition
                            ---@type AircraftPetFurPointCondition
                            local cond = AircraftPetFurPointCondition:New(pet, fur, condCfg)
                            --前置条件检验
                            if cond:PreCheck() then
                                action.Fur = fur
                                action.PointCond = cond
                                return action
                            end
                        end
                    end
                end
            else
                Log.exception("星灵行为类型错误：", action.Type)
            end
        end
    end
end

---@param pet AircraftPet
---@param action PetCfgAction
---@param cond AircraftPetFurSpecialConditionBase
function AircraftRandomActionManager:_4_startAction(pet, action, isInit)
    if action == nil then
        Log.exception("星灵没有可执行行为：", pet:TemplateID())
        return
    end

    --如果之前在漫游，离开之前的漫游区域
    local area = pet:GetWanderingArea()
    if area then
        local room = self._main:GetRoomByArea(area)
        if room then
            room:PetLeaveWandering(pet:TemplateID())
        end
        pet:SetWanderingArea(nil)
    end

    --这里拿到的action认为是必定可以执行的，不再做任何条件判断
    if isInit then
        --初始化直接开始执行
        local petAction = nil
        if action.Type == AirRandomActionType.Wandering then
            local area = action.Area
            self._main:EnterAreaToWandering(pet, area)
            ---@type AircraftPointHolder
            local holder = self._main:GetPointHolder(area)
            pet:SetFloor(holder:Floor())
            pet:SetPosition(self._main:GetInitPos(holder))
            AirLog("初始化，星灵开始漫游:", pet:TemplateID(), "，区域：", area, "，楼层：", holder:Floor())
            petAction = AirActionWandering:New(pet, holder, action.Duration, "漫游-初始化", self._main)
        elseif action.Type == AirRandomActionType.Furniture then
            local area = action.Area
            ---@type AircraftFurniture  直接取家具
            local furn = action.Fur
            local cond = action.PointCond
            --家具行为开始前，按条件占据点
            local point = cond:TakePointOnStart()
            pet:SetFloor(furn:Floor())
            pet:SetState(AirPetState.OnFurniture)
            AirLog("初始化，星灵与家具交互:", pet:TemplateID(), "，家具：", furn:GetPstKey(), "，索引点：", point:Index())
            petAction = AirActionOnFurniture:New(pet, furn, point, cond, action.Duration, true)
        end
        self._main:StartInitAction(pet, petAction, action.Index)
        pet:SetRandomActionCfgID(action.Index)
    else
        --在TakePointOnStart之前，先停止主行为
        pet:StopMainAction()

        --运行中需要走过去执行
        local petAction = nil
        if action.Type == AirRandomActionType.Wandering then
            local area = action.Area
            self._main:EnterAreaToWandering(pet, area)
            ---@type AircraftPointHolder
            local holder = self._main:GetPointHolder(area)
            local point = holder:PopPoint()
            AirLog("运行时，星灵走向漫游点:", pet:TemplateID(), "，区域:", area, "，楼层:", holder:Floor())
            petAction = AirActionMoveToWandering:New(self._main, pet, holder, point, action.Duration)
        elseif action.Type == AirRandomActionType.Furniture then
            local area = action.Area
            ---@type AircraftFurniture  直接取家具
            local furn = action.Fur
            local cond = action.PointCond
            --家具行为开始前，提前按条件占据点
            local point = cond:TakePointOnStart()
            AirLog("运行时，星灵走向家具:", pet:TemplateID(), "，家具：", furn:CfgID(), "，索引点：", point:Index(), "，楼层：", furn:Floor())
            petAction = AirActionMoveToFurniture:New(self._main, pet, furn, point, cond, action.Duration)
        end
        pet:StartMainAction(petAction)
        --此次执行的行为id，下次不能再执行
        pet:SetRandomActionCfgID(action.Index)
    end
end

------------------------------------------------------------------------------------------------
---@class PetCfgAction:Object 注释用
local PetCfgAction = {
    Index = nil,
    Type = nil,
    Area = nil,
    Duration = nil,
    FurType = nil,
    Weight = nil,
    Condition = nil,
    --
    Fur = nil,
    PointCond = nil
}

------------------------------------------------------------------------------------------------
--[[
    按条件获取家具点，随机取、取特定名称点、取特定名称后占据其他点
]]
---@class AircraftPetFurPointCondition:Object
_class("AircraftPetFurPointCondition", Object)
AircraftPetFurPointCondition = AircraftPetFurPointCondition
function AircraftPetFurPointCondition:Constructor(pet, fur, cfgID, point)
    --家具社交行为反序列化后，直接占据点，这里为了逻辑上的统一暂存点并释放点
    if point then
        self._point = point
        self._social = true
    else
        if cfgID then
            self._cfg = Cfg.cfg_aircraft_special_action[cfgID]
            if self._cfg == nil then
                Log.exception("找不到特殊行为配置：", cfgID)
            end
        end
    end
    ---@type AircraftFurniture
    self._furniture = fur
    ---@type AircraftPet
    self._pet = pet
end
function AircraftPetFurPointCondition:PreCheck()
    if self._social then
        Log.exception("社交反序列化行为不需要调用PreCheck", debug.traceback())
    end

    self._available = false
    if self._cfg == nil then
        --无条件时，家具有可用点
        self._available = self._furniture:AvailableCount() > 0
    elseif self._cfg.Type == AircraftPetFurSpacialActionType.WithGivenPoint then
        local pointNames = self._cfg.Params[1].points
        for _, name in ipairs(pointNames) do
            if self._furniture:HasAvailablePoint(name) then
                self._availablePointName = name
                self._available = true
                break
            end
        end
    elseif self._cfg.Type == AircraftPetFurSpacialActionType.OccupyFurniture then
        --取特定名字的点，且所有点都没有被占据
        if self._furniture:IsEmpty() then
            local pointNames = self._cfg.Params[1].points
            for _, name in ipairs(pointNames) do
                if self._furniture:HasAvailablePoint(name) then
                    self._availablePointName = name
                    self._available = true
                    break
                end
            end
        end
    end
    return self._available
end
function AircraftPetFurPointCondition:TakePointOnStart()
    if not self._available then
        Log.exception("当前条件不可用，不可调用TakePointOnStart")
        return
    end

    if self._social then
        Log.exception("社交反序列化行为不需要调用TakePointOnStart.", debug.traceback())
    end
    if not self._cfg then
        --随机取1个空闲点
        self._point = self._furniture:PopPoint()
        if self._point == nil then
            Log.exception("Sit取不到家具点：", self._furniture:GetPstKey(), "，星灵:", self._pet:TemplateID())
        end
    elseif self._cfg.Type == AircraftPetFurSpacialActionType.WithGivenPoint then
        --取并占据
        self._point = self._furniture:PopPointByName(self._availablePointName)
        if self._point == nil then
            Log.exception("找不到家具点，类型1：", self._availablePointName, "，家具：", self._furniture:CfgID())
        end
    elseif self._cfg.Type == AircraftPetFurSpacialActionType.OccupyFurniture then
        --取并占据全部
        self._point = self._furniture:GetPointByName(self._availablePointName)
        if self._point == nil then
            Log.exception("找不到家具点，类型2：", self._availablePointName, "，家具：", self._furniture:CfgID())
        end
        self._furniture:OccupyAllPoint(true)
    end
    --点被占据之后，设置星灵占据的家具实例id，家具销毁时会通过这个id找到星灵，并为星灵随机行为
    self._pet:SetOccupyFurniture(self._furniture:InstanceID())

    if self._point == nil then
        Log.exception("取不到家具点：", self._furniture:GetPstKey(), "，星灵:", self._pet:TemplateID())
    end

    return self._point
end
function AircraftPetFurPointCondition:ReleasePointOnStop()
    if self._social then
        AirLog("社交反序列化行为释放家具点")
    else
        if not self._available then
            Log.exception("当前条件不可用，不可调用ReleasePointOnStop.", debug.traceback())
            return
        end
    end
    if not self._cfg then
        self._furniture:ReleasePoint(self._point)
    elseif self._cfg.Type == AircraftPetFurSpacialActionType.WithGivenPoint then
        self._furniture:ReleasePoint(self._point)
    elseif self._cfg.Type == AircraftPetFurSpacialActionType.OccupyFurniture then
        self._furniture:OccupyAllPoint(false)
    end
    self._pet:SetOccupyFurniture(nil)
end
