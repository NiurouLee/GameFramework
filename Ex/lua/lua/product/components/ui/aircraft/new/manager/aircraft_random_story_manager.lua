--[[
    风船随机事件控制器
]]
---@class AircraftRandomStoryManager:Object
_class("AircraftRandomStoryManager", Object)
AircraftRandomStoryManager = AircraftRandomStoryManager

function AircraftRandomStoryManager:Constructor(aircraftMain)
    ---@type AircraftMain
    self._main = aircraftMain

    --获得所有剧情
    ---@type number[]
    self._inStoryPets = {}
    --触发和未触发剧情
    ---@type number[]
    self._showStory = {}
    ---@type number[]
    self._hideStory = {}
    --从未触发剧情列表中移除剧情用
    ---@type number[]
    self._removeStoryIDs = {}

    --存放已触发的剧情相关信息
    ---@type table<number,AircraftRandomStoryItem>
    self._pet2action = {}
end

--获得剧情通过星灵id
function AircraftRandomStoryManager:GetStoryIDByPetID(petid)
    for key, value in pairs(self._pet2action) do
        if petid == value.petid then
            return key
        end
    end
end

function AircraftRandomStoryManager:Init()
    ---@type AircraftModule
    local AirModule = GameGlobal.GetModule(AircraftModule)
    ---@type QuestChatModule
    local questChatModule = GameGlobal.GetModule(QuestChatModule)
    self._inStoryPets = {}
    --解锁房间
    local roomStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.UnlockRoom)
    if roomStory and table.count(roomStory) > 0 then
        for key, value in pairs(roomStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    --判断终端是否已读
                    local cfg_story = Cfg.cfg_aircraft_pet_stroy_refresh[var]
                    if not cfg_story then
                        Log.error("cfg_aircraft_pet_stroy_refresh 表中没有这个 id --> ", var)
                    end
                    local cid = cfg_story.StoryEventChatID
                    if cid and cid ~= 0 then
                        local isEnd = questChatModule:UI_IsChatEnd(cid)
                        if isEnd then
                            table.insert(self._inStoryPets, var)
                        end
                    end
                end
            end
        end
    end
    --获得星灵剧情
    local addPetStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.AddPet)
    if addPetStory and table.count(addPetStory) > 0 then
        for key, value in pairs(addPetStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    --判断终端是否已读
                    local cfg_story = Cfg.cfg_aircraft_pet_stroy_refresh[var]
                    if not cfg_story then
                        Log.error("cfg_aircraft_pet_stroy_refresh 表中没有这个 id --> ", var)
                    end
                    local cid = cfg_story.StoryEventChatID
                    if cid and cid ~= 0 then
                        local isEnd = questChatModule:UI_IsChatEnd(cid)
                        if isEnd then
                            table.insert(self._inStoryPets, var)
                        end
                    end
                end
            end
        end
    end
    --登陆剧情
    local loginStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.LoginGame)
    if loginStory and table.count(loginStory) > 0 then
        for key, value in pairs(loginStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    --判断终端是否已读
                    local cfg_story = Cfg.cfg_aircraft_pet_stroy_refresh[var]
                    if not cfg_story then
                        Log.error("cfg_aircraft_pet_stroy_refresh 表中没有这个 id --> ", var)
                    end
                    local cid = cfg_story.StoryEventChatID
                    if cid and cid ~= 0 then
                        local isEnd = questChatModule:UI_IsChatEnd(cid)
                        if isEnd then
                            table.insert(self._inStoryPets, var)
                        end
                    end
                end
            end
        end
    end
    --总段剧情
    local MultPetsStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.EnterAircraftSection)
    if MultPetsStory and table.count(MultPetsStory) > 0 then
        for key, value in pairs(MultPetsStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    table.insert(self._inStoryPets, var)
                end
            end
        end
    end
    --完成主线剧情
    local missionStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.PassMission)
    if missionStory and table.count(missionStory) > 0 then
        for key, value in pairs(missionStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    table.insert(self._inStoryPets, var)
                end
            end
        end
    end
    --送礼
    local giftStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.GiveGift)
    if giftStory and table.count(giftStory) > 0 then
        for key, value in pairs(giftStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    table.insert(self._inStoryPets, var)
                end
            end
        end
    end
    --进入剧情
    local enterStory = AirModule:GetStoryEventDicByTriggerType(EStoryTriggerType.EnterAircraft)
    if enterStory and table.count(enterStory) > 0 then
        for key, value in pairs(enterStory) do
            for index, var in ipairs(value.story_event_id_list) do
                if var > 0 then
                    table.insert(self._inStoryPets, var)
                end
            end
        end
    end

    --触发
    if table.count(self._inStoryPets) > 0 then
        Log.debug("###random 有剧情，开启", table.count(self._inStoryPets), "个")
        self:StartStory()
    end

    AirLog("AircraftRandomStoryManager Init Done")
end

--当前触发的随机剧情数量
function AircraftRandomStoryManager:GetRandomStoryTriggerCount()
    return table.count(self._pet2action)
end

--检查星灵是否在触发剧情中
---@param pet AircraftPet
function AircraftRandomStoryManager:CheckPetInRandomStory(pet)
    local pid = pet:TemplateID()
    if self._pet2action[pid] then
        return true
    end
    return false
end

--触发一个剧情
function AircraftRandomStoryManager:TriggerRandomStory(storyid, gotReward, gotAffinity)
    --当前人物等待action改为触发action
    local petid = self._pet2action[storyid].petid
    local pet = self._main:GetPetByTmpID(petid)

    --关掉材质动画
    pet:StopMatAnim()
    local needpets = self._pet2action[storyid].needPets
    if needpets and table.count(needpets) > 0 then
        for i = 1, #needpets do
            local needpet = self._main:GetPetByTmpID(needpets[i])
            needpet:StopMatAnim()
        end
    end

    ---@type AirAction_RS_Look
    local action_rs_look = AirAction_RS_Look:New(pet, self._main, storyid, gotReward, gotAffinity)
    pet:StartMainAction(action_rs_look)
    action_rs_look:ReadyPlayStory()
    ---触发剧情
    pet:SetEffectCollider(nil) --气泡关闭 碰撞器置空 设置是在AirAction_RS_Wait中
end

--开始触发能触发的剧情
function AircraftRandomStoryManager:StartStory()
    for i = 1, #self._inStoryPets do
        local storyid = self._inStoryPets[i]
        self:StartOneRandomEvent(storyid)
    end
end

function AircraftRandomStoryManager:Update(deltaTimeMS)
end

--检查伴随剧情的星灵,检查sp星灵
function AircraftRandomStoryManager:CheckPetWithRandomStory(withPets)
    for i = 1, #withPets do
        for key, value in pairs(self._showStory) do
            if self._pet2action[value] then
                local storyItem = self._pet2action[value]
                local withs = {}
                local needPets = storyItem.needPets
                local petid = storyItem.petid
                table.insert(withs, petid)
                if needPets and table.count(needPets) > 0 then
                    for i = 1, #needPets do
                        local pid = needPets[i]
                        table.insert(withs, pid)
                    end
                end
                for k, v in pairs(withs) do
                    if v == withPets[i] then
                        return true
                    end
                end
                local inner = HelperProxy:GetInstance():CheckBinderID(withs, withPets[i])
                if inner then
                    Log.debug("###[AircraftRandomStoryManager] sp星灵已在剧情中,id", withPets[i])
                    return true
                end
            end
        end
    end
    return false
end

--开启一个剧情（nomove，是否移动到剧情点）
---@param pet AircraftPet
function AircraftRandomStoryManager:StartOneRandomEvent(storyid, noMove)
    Log.debug("###random 准备开启一个剧情-id-->", storyid)

    local cfg_aircraft_pet_stroy_refresh = Cfg.cfg_aircraft_pet_stroy_refresh[storyid]
    if not cfg_aircraft_pet_stroy_refresh then
        Log.error("###[RandomStory]cfg_aircraft_pet_stroy_refresh is nil ! id -- ", storyid)
        return
    end
    local triggerType = cfg_aircraft_pet_stroy_refresh.TriggerType
    local petid = cfg_aircraft_pet_stroy_refresh.PetID
    local needpetids = cfg_aircraft_pet_stroy_refresh.EnterTriggerNeedPetsArray
    local withPets = {}
    table.insert(withPets, petid)
    if needpetids and table.count(needpetids) > 0 then
        for i = 1, #needpetids do
            table.insert(withPets, needpetids[i])
        end
    end

    --先检查星灵存在不存在,服务器做了判断了

    --如果相关的星灵已经在剧情中
    if self:CheckPetWithRandomStory(withPets) then
        if not table.icontains(self._hideStory, storyid) then
            table.insert(self._hideStory, storyid)
        end
        return
    end

    --检查剧情触发点
    local storyParam, floor, pointid, randomPointHolder = self:GetRandomStoryPoint(storyid)
    if not noMove then
        if storyParam == nil then
            Log.debug("###[AircraftRandomStoryManager] storyid-->", storyid, "触发失败,原因没有点")
            return
        end
    end

    --获得剧情人物
    local pet = self._main:GetPetByTmpID(petid)
    local sp = false
    if not pet then
        pet, sp = self._main:AddPet(petid)
        if not pet then
            if sp then
                Log.debug("###[AircraftRandomStoryManager] sp星灵已存在,sp:", sp, ",petid:", petid)
            end
            return
        end
    end

    ---@type AirAction_RS_Wait
    local action_rs_wait =
        AirAction_RS_Wait:New(pet, self._main, storyid, storyParam, floor, pointid, randomPointHolder, noMove)
    pet:SetState(AirPetState.RandomEvent)
    --设置障碍
    pet:SetAsObstacle()
    pet:StartMainAction(action_rs_wait)
    ---开始剧情
    action_rs_wait:StartWaitBubble()

    --伴随剧情的人
    local needPetList = {}
    if needpetids and #needpetids > 0 then
        for i = 1, #needpetids do
            local tempid = needpetids[i]
            local otherPet = self._main:GetPetByTmpID(tempid)
            if not otherPet then
                otherPet, sp = self._main:AddPet(tempid)
                if not pet then
                    if sp then
                        Log.debug("###[AircraftRandomStoryManager] sp星灵已存在,sp:", sp, ",petid:", tempid)
                    end
                    return
                end
            end

            local storyParam, floor, pointid, randomPointHolder = self:GetRandomStoryPoint(storyid, true)

            ---@type AirAction_RS_Wait
            local action_rs_with =
                AirActionRandomStoryWith:New(
                    otherPet,
                    self._main,
                    storyid,
                    storyParam,
                    floor,
                    pointid,
                    randomPointHolder,
                    noMove
                )
            otherPet:SetState(AirPetState.RandomEventWith)
            --设置障碍
            otherPet:SetAsObstacle()
            otherPet:StartMainAction(action_rs_with)
        end
    end

    -------------------------------------------------------------------------------------------
    table.insert(self._removeStoryIDs, storyid)
    ---@type AircraftRandomStoryItem
    local storyItem = AircraftRandomStoryItem:New(storyid, petid, needpetids, triggerType)
    self._pet2action[storyid] = storyItem
    table.insert(self._showStory, storyid)
end

--获取剧情点，获取失败不触发
function AircraftRandomStoryManager:GetRandomStoryPoint(storyid, noRemoveFurniturePet)
    Log.debug("###[AircraftRandomStoryManager] 获取剧情触发数据 storyid --> ", storyid)
    local cfg = Cfg.cfg_aircraft_pet_stroy_refresh[storyid]
    if not cfg then
        Log.error("###[AircraftRandomStoryManager]cfg_aircraft_pet_stroy_refresh is nil ! id --> ", storyid)
        return
    end

    local randomStoryAreaType = cfg.RandomStoryAreaType
    local storyParam, floor, pointid, randomPointHolder
    if randomStoryAreaType == 1 then
        --点剧情
        local posids = cfg.RandomStoryPosIDs
        storyParam, floor, pointid, randomPointHolder = self:GetRandomStoryPos(storyid, posids)
    else
        --家具交互剧情
        local furnitureType = cfg.RandomStoryFurnitureType
        storyParam, floor = self:GetRandomStoryFurniture(furnitureType, noRemoveFurniturePet)
        if storyParam == nil then
            --么找到家具，普通触发
            local posids = cfg.RandomStoryPosIDs
            storyParam, floor, pointid, randomPointHolder = self:GetRandomStoryPos(storyid, posids)
        end
    end
    --如果点也没找到，触发失败
    if storyParam == nil then
        Log.debug("###[AircraftRandomStoryManager] 如果点也没找到，触发失败")
        return
    else
        Log.debug("###[AircraftRandomStoryManager] 触发")
        return storyParam, floor, pointid, randomPointHolder
    end
end

--点剧情
function AircraftRandomStoryManager:GetRandomStoryPos(storyid, RandomStoryPosIDs)
    local storyParam, floor, pointid, randomPointHolder
    --检查没有用到的剧情点
    local storyParams = RandomStoryPosIDs
    Log.debug("###[AircraftRandomStoryManager] 检查没用到的剧情点")

    for i = 1, #storyParams do
        local area = storyParams[i][1]
        pointid = storyParams[i][2]

        Log.debug("###[AircraftRandomStoryManager] 开始找点 area --> ", area, "| pointid --> ", pointid)

        ---@type AircraftStoryPointHolder
        if area == AirRestAreaType.Board3 or area == AirRestAreaType.Board4 then
            ---@type AircraftStoryPointHolder
            randomPointHolder = self._main:GetRandomStoryPointHolder(area)
        else
            local room = self._main:GetRoomByArea(area)
            if room == nil then
                Log.debug("###[AircraftRandomStoryManager] 找不到房间：", area, "|storyid-->", storyid)
            else
                ---@type AircraftStoryPointHolder
                randomPointHolder = room:GetRandomStoryPointHolder()
            end
        end

        if not randomPointHolder:CheckPointOccupy(pointid, storyid) then
            storyParam = randomPointHolder:GetPoint(pointid, storyid)
            floor = randomPointHolder:Floor(pointid)
            Log.debug("###[AircraftRandomStoryManager]找到一个点,id", pointid)
            Log.debug("###[AircraftRandomStoryManager]找到楼层，", floor)
            break
        end
    end
    if not storyParam or not floor then
        Log.debug("###[AircraftRandomStoryManager]检查完毕没找到")
        return
    end
    return storyParam, floor, pointid, randomPointHolder
end

--家具剧情
function AircraftRandomStoryManager:GetRandomStoryFurniture(furnitureType, noRemoveFurniturePet)
    local furniture = self._main:GetFurnitureByID(furnitureType)
    local storyParam, floor
    if furniture then
        if noRemoveFurniturePet then
            --不移除家具上的星灵
            Log.debug("###[AircraftRandomStoryManager] 伴随星灵 - 不移除家具上的星灵")
        else
            Log.debug("###[AircraftRandomStoryManager] 主星灵 - 移除家具上的星灵")

            --找到了家具，把家具上的星灵都干掉
            local pets = furniture:GetPets()
            for _, petid in pairs(pets) do
                local pet = self._main:GetPetByTmpID(petid)
                self._main:RandomActionForPet(pet)
            end
        end

        floor = furniture:Floor()
        storyParam = furnitureType

        Log.debug("###[AircraftRandomStoryManager]设置了家具的楼层 furnitureType-->", furnitureType, "|floor-->",
            floor)

        return storyParam, floor
    else
        --没找到家具,普通触发
        Log.debug("###[AircraftRandomStoryManager] 没找到家具,普通触发")
        return nil
    end
end

--结束随机剧情
---@param pet AircraftPet
function AircraftRandomStoryManager:RemoveOneRandomEvent(storyid)
    local storyPets = {}

    local petid = self._pet2action[storyid].petid
    local triggerType = self._pet2action[storyid].triggerType
    local storyID = self._pet2action[storyid].storyid

    AirLog("结束剧情，星灵：", petid)

    table.insert(storyPets, petid)
    local needPets = self._pet2action[storyid].needPets

    if needPets and table.count(needPets) > 0 then
        for _, p in pairs(needPets) do
            table.insert(storyPets, p)
        end
    end

    if self._pet2action[storyid] then
        self._pet2action[storyid] = nil
    end

    for i = 1, #storyPets do
        local itemPetid = storyPets[i]
        AirLog("随机行为，星灵：", petid)
        self._main:OnPetFinishStory(itemPetid, triggerType, storyID)
    end

    --导航栏接受事件
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshNavMenuData)
    --暂时先不开启剩余剧情--TODO--
    --self:CheckHideStory()
end

--检查hideStory里有没有可以触发的
function AircraftRandomStoryManager:CheckHideStory()
    for key, value in pairs(self._hideStory) do
        self:StartOneRandomEvent(value)
    end
    for i = 1, #self._removeStoryIDs do
        local id = self._removeStoryIDs[i]
        for j = 1, #self._hideStory do
            if self._hideStory[j] == self._removeStoryIDs[i] then
                table.remove(self._hideStory, j)
                break
            end
        end
    end
    table.clear(self._removeStoryIDs)
end

function AircraftRandomStoryManager:Dispose()
    if self._pet2action then
        table.clear(self._pet2action)
        self._pet2action = nil
    end
    if self._inStoryPets then
        table.clear(self._inStoryPets)
        self._inStoryPets = nil
    end
    self._main = nil
end

function AircraftRandomStoryManager:GetRandomStoryPets()
    local pets = {}
    if table.count(self._pet2action) then
        for key, value in pairs(self._pet2action) do
            pets[#pets + 1] = value
        end
    end
    return pets
end

--通过伴随剧情的人获取剧情星灵
---@param needpet AircraftPet
function AircraftRandomStoryManager:GetStoryPetByNeedPet(needpet)
    local needpetid = needpet:TemplateID()
    for key, value in pairs(self._pet2action) do
        local item = value
        local needPets = item.needPets
        local inner = false
        if needPets and table.count(needPets) > 0 then
            for key, value in pairs(needPets) do
                if value == needpetid then
                    inner = true
                    break
                end
            end
        end
        if inner then
            local petid = item.petid
            return petid
        end
    end
end

--通过剧情的人获取剧情相关星灵
---@param pet AircraftPet
function AircraftRandomStoryManager:GetNeedPetByStoryPet(pet)
    ---@type AirPetState
    local petState = pet:GetState()
    local _petid = pet:TemplateID()
    local pets
    local storyid
    if petState == AirPetState.RandomEvent then
        pets = {}
        for key, value in pairs(self._pet2action) do
            if value.petid == _petid then
                storyid = key
                break
            end
        end

        local data = self._pet2action[storyid]
        table.insert(pets, data.petid)
        if data.needPets and table.count(data.needPets) > 0 then
            for i = 1, #data.needPets do
                local needPet = data.needPets[i]
                table.insert(pets, needPet)
            end
        end
    elseif petState == AirPetState.RandomEventWith then
        pets = {}
        for key, value in pairs(self._pet2action) do
            local _needPets = value.needPets
            if _needPets then
                for i = 1, #_needPets do
                    local _needPet = _needPets[i]
                    if _needPet == _petid then
                        storyid = key
                        break
                    end
                end
            end
            if storyid then
                break
            end
        end

        local data = self._pet2action[storyid]
        table.insert(pets, data.petid)
        if data.needPets and table.count(data.needPets) > 0 then
            for i = 1, #data.needPets do
                local needPet = data.needPets[i]
                table.insert(pets, needPet)
            end
        end
    end
    return pets
end

--[[
    风船随机剧情对象
]]
---@class AircraftRandomStoryItem:Object
_class("AircraftRandomStoryItem", Object)
AircraftRandomStoryItem = AircraftRandomStoryItem

function AircraftRandomStoryItem:Constructor(storyid, petid, needPets, triggerType)
    self.storyid = storyid
    self.petid = petid
    self.needPets = needPets
    self.triggerType = triggerType
end
