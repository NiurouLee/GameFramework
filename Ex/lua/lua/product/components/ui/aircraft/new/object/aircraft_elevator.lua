--[[
    风船电梯
]]
---@class AircraftElevator:Object
_class("AircraftElevator", Object)
AircraftElevator = AircraftElevator
function AircraftElevator:Constructor(main)
    ---@type AircraftMain
    self._main = main
    ---@type table<number,AircraftElevatorLine>
    self._lines = {
        AircraftElevatorLine:New(1, self._main),
        AircraftElevatorLine:New(2, self._main),
        AircraftElevatorLine:New(3, self._main),
        AircraftElevatorLine:New(4, self._main)
    }

    self._state = ElevatorState.Idle
    self._floor = 1 --默认在1层
    self._elevatorT = UnityEngine.GameObject.Find("Elevator").transform:Find("E")
    --当前正在运动的星灵
    self._curPet = nil

    --各种移动
    ---@type AircraftPetMover
    self._petMover = nil
    ---@type AircraftMover
    self._elevatorMover = nil
end
function AircraftElevator:Init()
end
function AircraftElevator:Update(deltaTimeMS)
    if self._state == ElevatorState.Idle then
        local target = 0
        local time = self._main:Time() --排队时间总时早于当前时间的
        for floor, line in ipairs(self._lines) do
            if line:HasWaitingPet() then
                local firstTime = line:FirstPetWaitTime()
                if firstTime < time then
                    time = firstTime
                    target = floor
                end
            end
        end
        if target > 0 then
            --找到可调度的楼层
            self._state = ElevatorState.Moving
            self._floor = target
            self._elevatorMover = nil
        end
    elseif self._state == ElevatorState.Moving then
        if self._elevatorMover == nil then
            if self._floor == nil then
                self._state = ElevatorState.Idle
                return
            end
            local line = self._lines[self._floor]
            local pos = line:Pos()
            self._elevatorMover = AircraftMover:New(self._elevatorT, pos, AircraftSpeed.Elevator)
            self._elevatorMover:Begin()
        end
        self._elevatorMover:Update(deltaTimeMS)
        if self._elevatorMover:IsArrive() then
            self._elevatorMover = nil
            --到达之后发现楼层为nil，则说明星灵被销毁
            if self._floor == nil then
                self._state = ElevatorState.Idle
            else
                self._state = ElevatorState.WaitEnter
            end
        end
    elseif self._state == ElevatorState.WaitEnter then
        if self._petMover == nil then
            if not self._floor or not self._lines[self._floor] or not self._lines[self._floor]:HasWaitingPet() then
                self._state = ElevatorState.Idle
                return
            end
            ---@type AircraftPet
            self._curPet = self._lines[self._floor]:PopPet()
            local line = self._lines[self._floor]
            local pos = line:Pos()
            self._petMover = AircraftPetMover:New(self._curPet, pos, AircraftSpeed.Pet)
            self._petMover:Begin()
        end
        if not self._curPet then
            self._state = ElevatorState.Idle
            return
        end
        self._petMover:Update(deltaTimeMS)
        if self._petMover:IsArrive() then
            self._petMover = nil
            self._state = ElevatorState.Delivering
            self._floor = self._curPet:GetTargetFloor()
            self._curPet:Anim_Stand()
            self._curPet:SetState(AirPetState.InElevator)
            self._curPet:SetEuler(Vector3(0, 180, 0))
        end
    elseif self._state == ElevatorState.Delivering then
        if self._elevatorMover == nil then
            if not self._curPet or not self._floor or not self._lines[self._floor] then
                self._state = ElevatorState.Idle
                return
            end
            local line = self._lines[self._floor]
            local pos = line:Pos()
            self._elevatorMover = AircraftMover:New(self._elevatorT, pos, AircraftSpeed.Elevator)
            self._elevatorMover:Begin()
        end
        self._elevatorMover:Update(deltaTimeMS)
        if self._curPet then
            self._curPet:SetPosition(self._elevatorT.position)
        end
        if self._elevatorMover:IsArrive() then
            self._elevatorMover = nil
            self._state = ElevatorState.WaitExit
        end
    elseif self._state == ElevatorState.WaitExit then
        if not self._curPet then
            self._state = ElevatorState.Idle
            return
        end
        if self._petMover == nil then
            local line = self._lines[self._floor]
            local pos = line:Exit()
            self._petMover = AircraftPetMover:New(self._curPet, pos, AircraftSpeed.Pet)
            self._petMover:Begin()
        end
        self._petMover:Update(deltaTimeMS)
        if self._petMover:IsArrive() then
            self._state = ElevatorState.Idle
            --星灵出电梯后继续Action
            ---@type AirActionMoveToDo
            local action = self._curPet:GetMoveToDoAction()
            action:ArriveFloor()
            self._petMover = nil
            self._curPet = nil
        end
    end

    for _, line in ipairs(self._lines) do
        line:Update(deltaTimeMS)
    end
end
function AircraftElevator:Dispose()
end

--获取某一层的排队点
function AircraftElevator:GetLineTarget(floor)
    if not self._lines[floor] then
        Log.exception("[AircraftElevator] 找不到电梯楼层：", floor)
    end
    return self._lines[floor]:Target()
end

--获取某一层的出电梯点
function AircraftElevator:GetLineExit(floor)
    if not self._lines[floor] then
        Log.exception("[AircraftElevator] 找不到电梯楼层：", floor)
    end
    return self._lines[floor]:Exit()
end

---@param pet AircraftPet
function AircraftElevator:ArriveLineTarget(pet, floor)
    AirLog("星灵到达楼梯点:", pet:TemplateID())
    self._lines[floor]:OnPetArriveTarget(pet)
end

function AircraftElevator:IsFull(floor)
    return self._lines[floor]:IsFull()
end

--处理星灵被移除
---@param pet AircraftPet
function AircraftElevator:TryRemovePet(pet)
    if not pet then
        return
    end
    if self._state == ElevatorState.Idle then
    elseif self._curPet and self._curPet:PstID() == pet:PstID() and self._state == ElevatorState.WaitEnter then
        AirLog("正在进入电梯的星灵被销毁：", pet:TemplateID())
        self._curPet = nil
        self._petMover = nil
        self._state = ElevatorState.Idle
    elseif self._curPet and self._curPet:PstID() == pet:PstID() and self._state == ElevatorState.WaitExit then
        AirLog("正在离开电梯的星灵被销毁：", pet:TemplateID())
        self._curPet = nil
        self._petMover = nil
        self._state = ElevatorState.Idle
    elseif self._state == ElevatorState.Moving then
        -- self._state = ElevatorState.Idle
        -- self._elevatorMover = nil
        --此时保证电梯继续移动到目标楼层，所以把_floor设置为空
        self._floor = nil
        AirLog("电梯正在移动向星灵，但是星灵被销毁", pet:TemplateID())
    elseif self._curPet and self._curPet:PstID() == pet:PstID() and self._state == ElevatorState.Delivering then
        -- self._elevatorMover = nil
        -- self._state = ElevatorState.Idle
        AirLog("正在运送中的星灵被销毁：", pet:TemplateID())
        self._curPet = nil
    end
    if self._state == ElevatorState.Idle then
    end

    for _, line in ipairs(self._lines) do
        line:OnPetRemove(pet)
    end
end
