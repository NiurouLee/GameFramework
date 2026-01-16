--[[
    风船行为，随机剧情伴随行为
]]
---@class AirActionRandomStoryWithWith:AirActionBase
_class("AirActionRandomStoryWith", AirActionBase)
AirActionRandomStoryWith = AirActionRandomStoryWith

--伴随剧情不需要接受pointid和holder，因为主星灵结束的时候会释放这个holder
function AirActionRandomStoryWith:Constructor(pet, main, storyid, storyParam, floor, pointid, randomPointHolder, noMove)
    ---@type AircraftPet
    self._pet = pet

    ---@type AircraftMain
    self._main = main

    self._storyid = storyid

    local cfg = Cfg.cfg_aircraft_pet_stroy_refresh[self._storyid]
    if not cfg then
        Log.error("###[AirAction_RS_Wait_with]cfg_aircraft_pet_stroy_refresh is nil ! id --> ", self._storyid)
        return
    end

    --秒
    self._lastTime = cfg.CancelWaitTime
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
    if not noMove then
        self._pet:SetFloor(self._floor)
    end

    --是否移动位置
    self._noMove = noMove
end

function AirActionRandomStoryWith:Start()
    self._running = true
    self._isWaiting = true

    --位置/交互/副行为
    if not self._noMove then
        --把星灵放到某个点
        if self._randomStoryAreaType == 1 then
            self._pet:Anim_Stand()
            local pos = self._storyParams.position
            local rot = self._storyParams.localRotation
            self._pet:NaviObstacle().enabled = false
            --需要在update第一帧设置导航位置
            self._setNavPos = pos
            self._pet:SetPosition(pos)
            self._pet:SetRotation(rot)
        else
            if self._storyParams then
                Log.exception("星灵不能在家具上触发跟随剧情", self._pet:TemplateID())
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

--如果规定时间内没被点击，取消随机事件
function AirActionRandomStoryWith:Update(deltaTimeMS)
    if self._running then
        if self._setNavPos then
            --延迟一帧设置星灵被家具挤开之后的位置
            local found, hit = UnityEngine.AI.NavMesh.SamplePosition(self._setNavPos, nil, 10, 1 << (self._floor + 2))
            if found then
                self._pet:SetPosition(hit.position)
            end
            self._pet:NaviObstacle().enabled = true
            self._setNavPos = nil
        end
    end
end

function AirActionRandomStoryWith:IsOver()
    return not self._running
end
function AirActionRandomStoryWith:Stop()
    self._running = false
end

function AirActionRandomStoryWith:GetPointAndFloor(storyType, RandomStoryPosIDs, RandomStoryFurnitureType)
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
            Log.debug("###[AirAction_RS_Wait_with]设置了家具的楼层")
            return storyParam, floor
        else
            Log.debug("###[AirAction_RS_Wait_with]没有该家具，去甲板触发")
            storyType = 1

            return self:GetPointAndFloor_NoFurniture(RandomStoryPosIDs)
        end
    end
end

function AirActionRandomStoryWith:GetPointAndFloor_NoFurniture(RandomStoryPosIDs)
    local storyParam, floor
    --检查没有用到的剧情点
    local storyParams = RandomStoryPosIDs
    for i = 1, #storyParams do
        local area = storyParams[i][1]
        local pointid = storyParams[i][2]

        ---@type AircraftStoryPointHolder
        local randomPointHolder
        if area == AirRestAreaType.Board3 or area == AirRestAreaType.Board4 then
            randomPointHolder = self._main:GetRandomStoryPointHolder(area)
        else
            local room = self._main:GetRoomByArea(area)
            randomPointHolder = room:GetRandomStoryPointHolder()
        end
        if not randomPointHolder:CheckPointOccupy(pointid, self._storyid) then
            storyParam = randomPointHolder:GetPoint(pointid, self._storyid)
            floor = randomPointHolder:Floor(pointid)
            Log.debug("###[AirAction_RS_Wait_with]找到一个点,id", pointid)
            Log.debug("###[AirAction_RS_Wait_with]找到楼层，", floor)
            break
        end
    end
    if not storyParam or not floor then
        Log.debug("###rrrrr检查完毕没找到")
        return
    end
    return storyParam, floor
end
function AirActionRandomStoryWith:GetPointAndFloor_ByFurniture(RandomStoryFurnitureType)
    -- body
end
