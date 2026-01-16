--[[
    风船行为，随机剧情开启
]]
---@class AirAction_RS_Wait:AirActionBase
_class("AirAction_RS_Wait", AirActionBase)
AirAction_RS_Wait = AirAction_RS_Wait

function AirAction_RS_Wait:Constructor(pet, main, storyid, storyParam, floor, pointid, randomPointHolder, noMove)
    ---@type AircraftPet
    self._pet = pet

    Log.debug("###[AirAction_RS_Wait] 开启一个随机剧情-id-->", self._pet:TemplateID())

    ---@type AircraftMain
    self._main = main

    self._storyid = storyid

    local cfg = Cfg.cfg_aircraft_pet_stroy_refresh[self._storyid]
    if not cfg then
        Log.error("###[AirAction_RS_Wait]cfg_aircraft_pet_stroy_refresh is nil ! id --> ", self._storyid)
        return
    end

    --秒
    self._lastTime = cfg.CancelWaitTime * 1000
    --等待气泡
    self._waitBubble = cfg.HeadBubbleID
    --站位类型，1-位置(area，pos)，2-家具(type)
    self._randomStoryAreaType = cfg.RandomStoryAreaType

    --[[
        old
        --楼层和位置
        local storyParam, floor =
        self:GetPointAndFloor(self._randomStoryAreaType, cfg.RandomStoryPosIDs, cfg.RandomStoryFurnitureType)
        ]]
    self._storyParams = storyParam

    self._floor = floor

    self._pointID = pointid

    self._randomPointHolder = randomPointHolder

    if not noMove then
        self._pet:SetFloor(self._floor)
    end

    self._startTime = 0

    --等待中
    self._waiting = true

    --是否移动位置
    self._noMove = noMove

    self._setNavPos = false
end

function AirAction_RS_Wait:Update(deltaTimeMS)
    if not self._noMove and not self._setNavPos then
        --延迟一帧设置星灵被家具挤开之后的位置
        local found, hit = UnityEngine.AI.NavMesh.SamplePosition(self._position, nil, 10, 1 << (self._floor + 2))
        if found then
            self._pet:SetPosition(hit.position)
        end
        self._pet:NaviObstacle().enabled = true
        self._setNavPos = true
    end

    if self._running then
        self._startTime = self._startTime + deltaTimeMS
        if self._waiting then
            if self._startTime > self._lastTime then
                self._waiting = false
                self._startTime = 0
                self:ReadyStop()
            end
        end
    end
end

function AirAction_RS_Wait:ReadyStop()
    local action_rs_cancel = AirAction_RS_Cancel:New(self._pet, self._main, self._storyid)
    self._pet:StartViceAction(action_rs_cancel)
end

function AirAction_RS_Wait:Start()
    self._running = true
    self._isWaiting = true

    --位置/交互/副行为
    if not self._noMove then
        --把星灵放到某个点
        if self._randomStoryAreaType == 1 then
            local pos = self._storyParams.position
            local rot = self._storyParams.localRotation
            self._pet:NaviObstacle().enabled = false
            self._pet:SetPosition(pos)
            self._pet:SetRotation(rot)
            self._position = pos
            self._pet:Anim_Stand()
        else
            if self._storyParams then
                Log.exception("星灵不能在家具上触发剧情", self._pet:TemplateID())

                ---@type AircraftFurniture
                -- local furniture = self._main:GetFurnitureByID(self._storyParams)
                -- local point = furniture:PopPoint()
                -- local duration = self._lastTime * 1000
                -- local action = AirActionOnFurniture:New(self._pet, furniture, point, duration)
                -- self._pet:StartViceAction(action)
            end
        end
    end
end

function AirAction_RS_Wait:StartWaitBubble()
    --先在那杵着冒气泡，等待点击
    if self._waitBubble then
        local waitAction = AirActionFace:New(self._pet, self._waitBubble, nil, self._lastTime)
        self._pet:StartViceAction(waitAction)
        --这里的气泡只可能是2001或者1001 这两种气泡都有碰撞器
        local bubble = waitAction:GetBubbleGameObject()
        if bubble then
            local collider = bubble:GetComponentInChildren(typeof(UnityEngine.BoxCollider))
            if collider then
                --特效的碰撞器设置给星灵 点击特效等同于点击星灵
                self._pet:SetEffectCollider(collider)
            else
                AirError("剧情特效无法获取碰撞器:", self._waitBubble)
            end
        end
    end
end

function AirAction_RS_Wait:IsOver()
    return not self._running
end

function AirAction_RS_Wait:Stop()
    self._running = false
    if self._randomPointHolder and self._pointID then
        self._randomPointHolder:ReleasePoint(self._pointID)
        self._randomPointHolder = nil
        self._pointID = nil
    end
end

function AirAction_RS_Wait:GetPointAndFloor(storyType, RandomStoryPosIDs, RandomStoryFurnitureType)
    --如果是位置
    if storyType == 1 then
        return self:GetPointAndFloor_NoFurniture(RandomStoryPosIDs)
    else
        local storyParam, floor
        --家具，看家具在哪层
        storyParam = RandomStoryFurnitureType
        local furniture = self._main:GetFurnitureByID(storyParam)
        if furniture then
            --找到了家具，把家具上的星灵都干掉
            local pets = furniture:GetPets()
            for _, petid in pairs(pets) do
                local pet = self._main:GetPetByTmpID(petid)
                self._main:RandomActionForPet(pet)
            end
            floor = furniture:Floor()
            Log.debug("###[AirAction_RS_Wait]设置了家具的楼层")
            return storyParam, floor
        else
            Log.debug("###[AirAction_RS_Wait]没有该家具，去甲板触发")
            storyType = 1

            return self:GetPointAndFloor_NoFurniture(RandomStoryPosIDs)
        end
    end
end

function AirAction_RS_Wait:GetPointAndFloor_NoFurniture(RandomStoryPosIDs)
    local storyParam, floor
    --检查没有用到的剧情点
    local storyParams = RandomStoryPosIDs
    Log.debug("###[AirAction_RS_Wait]检查没用到的剧情点")
    for i = 1, #storyParams do
        local area = storyParams[i][1]
        local pointid = storyParams[i][2]
        ---@type AircraftStoryPointHolder
        local randomPointHolder
        if area == AirRestAreaType.Board3 or area == AirRestAreaType.Board4 then
            randomPointHolder = self._main:GetRandomStoryPointHolder(area)
        else
            local room = self._main:GetRoomByArea(area)
            if room == nil then
                Log.exception("找不到房间：", area)
            end
            randomPointHolder = room:GetRandomStoryPointHolder()
        end
        self._pointID = pointid
        self._randomPointHolder = randomPointHolder

        if not randomPointHolder:CheckPointOccupy(pointid, self._storyid) then
            storyParam = randomPointHolder:GetPoint(pointid, self._storyid)
            floor = randomPointHolder:Floor(pointid)
            Log.debug("###[AirAction_RS_Wait]找到一个点,id", pointid)
            Log.debug("###[AirAction_RS_Wait]找到楼层，", floor)
            break
        end
    end
    if not storyParam or not floor then
        Log.debug("###[AirAction_RS_Wait]检查完毕没找到")
        return
    end
    return storyParam, floor
end

function AirAction_RS_Wait:GetPointAndFloor_ByFurniture(RandomStoryFurnitureType)
    -- body
end
