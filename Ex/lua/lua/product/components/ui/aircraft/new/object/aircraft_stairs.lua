--[[
    风船楼梯管理器
]]
---@class AircraftStairs:Object
_class("AircraftStairs", Object)
AircraftStairs = AircraftStairs

function AircraftStairs:Constructor(main)
    ---@type AircraftMain
    self._main = main
    local parent = UnityEngine.GameObject.Find("Stairs").transform
    --1、2层
    self._enters = {
        parent:GetChild(0):Find("enter").position,
        parent:GetChild(1):Find("enter").position
    }

    self._exits = {
        parent:GetChild(0):Find("exit").position,
        parent:GetChild(1):Find("exit").position
    }
    -- self._enterQueue = AircraftQueue:New()
    -- self._exitQueue = AircraftQueue:New()

    --
    local root = UnityEngine.GameObject.Find("LogicRoot").transform
    ---@type AircraftDoorOpener
    local door1 = AircraftDoorOpener:New(root:Find("door_up/door_up_left"), root:Find("door_up/door_up_right"))
    door1:Init()
    ---@type AircraftDoorOpener
    local door2 = AircraftDoorOpener:New(root:Find("door_down/door_down_left"), root:Find("door_down/door_down_right"))
    door2:Init()

    ---@type table<number,AircraftDoorOpener>
    self._doors = {door1, door2}

    ---@type ArrayList
    self._moverList = ArrayList:New()
end

function AircraftStairs:Init()
end

function AircraftStairs:Update(deltaTimeMS)
    if self._moverList:Size() > 0 then
        self._moverList:ForEach(
            function(m)
                ---@type AircraftStairMover
                local mover = m
                mover:Update(deltaTimeMS)
            end
        )
        ---@type AircraftStairMover
        local first = self._moverList:Front()
        if first:IsFinish() then
            self._moverList:RemoveAt(1)
        end
    end

    for _, door in ipairs(self._doors) do
        door:Update(deltaTimeMS)
    end

    -- if self._enterQueue:Count() > 0 then
    --     self._enterQueue:ForEach(
    --         function(m)
    --             ---@type AircraftPetMover
    --             local mover = m
    --             mover:Update(deltaTimeMS)
    --         end
    --     )

    --     ---@type AircraftPetMover
    --     local first = self._enterQueue:Peek()
    --     if first:IsArrive() then
    --         self._enterQueue:Dequeue()
    --         local pet = first:Pet()
    --         pet:SetEuler(Vector3(0, 180, 0))
    --         local floor = pet:GetTargetFloor()
    --         local target = self._exits[floor]
    --         pet:SetPosition(target)

    --         local mover = AircraftPetMover:New(pet, target + Vector3(0, 0, -1), 0.9)
    --         mover:Begin()
    --         self._exitQueue:Enqueue(mover)
    --     end
    -- end

    -- if self._exitQueue:Count() > 0 then
    --     self._exitQueue:ForEach(
    --         function(m)
    --             ---@type AircraftPetMover
    --             local mover = m
    --             mover:Update(deltaTimeMS)
    --         end
    --     )

    --     ---@type AircraftPetMover
    --     local first = self._exitQueue:Peek()
    --     if first:IsArrive() then
    --         self._exitQueue:Dequeue()
    --         local pet = first:Pet()
    --         local action = pet:GetFloorTargetAction()
    --         pet:SetFloorTargetAction(nil)
    --         pet:SetFloor(pet:GetTargetFloor())
    --         pet:SetTargetFloor(nil)
    --         pet:StartMainAction(action)
    --     end
    -- end
end

function AircraftStairs:Dispose()
end

function AircraftStairs:GetMoveTarget(floor)
    local pos = self._enters[floor]

    if pos == nil then
        Log.exception("严重错误，找不到楼梯点，", "楼层:", floor, "，总数:", table.count(self._enters), "，", debug.traceback())
    end

    return pos
end

function AircraftStairs:GetStairExit(floor)
    return self._exits[floor]
end

--星灵到达楼梯点，开始走进
---@param pet AircraftPet
function AircraftStairs:OnPetArrive(pet)
    -- pet:StartIdleAction()
    -- local mover = AircraftPetMover:New(pet, pet:Transform().position + Vector3(0, 0, 1), 0.9)
    -- mover:Begin()
    -- self._enterQueue:Enqueue(mover)
    local mover = AircraftStairMover:New(pet, self._exits[pet:GetTargetFloor()], self._doors)
    self._moverList:PushBack(mover)
end

---@param pet AircraftPet
function AircraftStairs:TryRemovePet(pet)
    if not pet then
        return
    end
    local target = nil
    for i = 1, self._moverList:Size() do
        ---@type AircraftStairMover
        local mover = self._moverList:GetAt(i)
        if mover:Pet():TemplateID() == pet:TemplateID() then
            target = i
            break
        end
    end
    if target then
        AirLog("楼梯中的星灵被销毁：", pet:TemplateID())
        self._moverList:RemoveAt(target)
    end
end

-------------------------------------------------------------------------
--[[
    
]]
---@class AircraftStairMover:Object
_class("AircraftStairMover", Object)
AircraftStairMover = AircraftStairMover
function AircraftStairMover:Constructor(pet, exitPos, doors)
    ---@type AircraftPet
    self._pet = pet
    self._exitPos = exitPos
    ---@type table<number,AircraftDoorOpener>
    self._doors = doors
    self._enterMover = AircraftPetMover:New(pet, pet:Transform().position + Vector3(0, 0, 2), 0.9)
    self._exitMover = AircraftPetMover:New(pet, self._exitPos, 0.9)
    self._enterMover:Begin()
    pet:SetState(AirPetState.Upstairs)
    --开门
    self._doors[pet:GetFloor()]:Open()
    self._state = AirPetStairState.Enter
    self._timer = 0
end
function AircraftStairMover:Update(deltaTimeMS)
    if self._state == AirPetStairState.Enter then
        self._enterMover:Update(deltaTimeMS)
        if self._enterMover:IsArrive() then
            self._pet:GameObject():SetActive(false)
            self._timer = 700
            self._state = AirPetStairState.Hide
        end
    elseif self._state == AirPetStairState.Hide then
        self._timer = self._timer - deltaTimeMS
        if self._timer < 0 then
            self._pet:SetEuler(Vector3(0, 180, 0))
            self._pet:SetPosition(self._exitPos + Vector3(0, 0, 2))
            self._pet:GameObject():SetActive(true)
            self._timer = 200
            --开目标层的门
            self._doors[self._pet:GetTargetFloor()]:Open()
            self._state = AirPetStairState.Wait
        end
    elseif self._state == AirPetStairState.Wait then
        self._timer = self._timer - deltaTimeMS
        if self._timer < 0 then
            self._exitMover:Begin()
            self._state = AirPetStairState.Exit
        end
    elseif self._state == AirPetStairState.Exit then
        self._exitMover:Update(deltaTimeMS)
        if self._exitMover:IsArrive() then
            local pet = self._pet
            ---@type AirActionMoveToDo
            local action = pet:GetMoveToDoAction()
            action:ArriveFloor()
            self._state = AirPetStairState.Finish
        end
    elseif self._state == AirPetStairState.Finish then
    end
end
function AircraftStairMover:IsFinish()
    return self._state == AirPetStairState.Finish
end

function AircraftStairMover:Pet()
    return self._pet
end
