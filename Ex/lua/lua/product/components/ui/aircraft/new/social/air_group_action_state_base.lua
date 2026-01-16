--[[
    @风船组队状态
]]
require "fsm_state"

--region statebase

_class("AirGroupActionStateBase", FSMState)
---@class AirGroupActionStateBase:FSMState
AirGroupActionStateBase = AirGroupActionStateBase

function AirGroupActionStateBase:Constructor()
    self.actions = {}
    ---@type AirGroupActionExecutor
    self.owner = self.stateMachine:GetOwner()
    self.socialArea = self.owner:GetSocialArea()
    ---@type AircraftPet[]
    self.pets = self.owner:GetPets()
    self.petIds = table.keys(self.pets)
    ---@type AirLibMaker
    self.libMaker = self.owner:GetLibMaker()
    -- HFSM阉割版
    self.childMachines = {}
end
---@return AircraftMain
function AirGroupActionStateBase:GetAirMain()
    return self.owner:GetAirMain()
end

-- 补丁做法子状态机 分层状态机的思想 TODO 做个HFSM
function AirGroupActionStateBase:AddChild(stateTypes, callBack, sender)
    local m = AirGroupActionMachine:New(self.owner, stateTypes)
    m:SetProcessFinish(callBack, sender)
    -- owner 为父状态机
    table.insert(self.childMachines, m)
end

function AirGroupActionStateBase:OnDispose()
    for index, value in ipairs(self.childMachines) do
        value:Dispose()
    end
    self.childMachines = {}
end

function AirGroupActionStateBase:Excute()
    if self.pets then
        for key, pet in pairs(self.pets) do
            if not pet:IsAlive() then
                --这里容错，发现社交中的星灵销毁了，停止整个社交
                self:GetAirMain():StopSocialByPet(pet)
                return
            end
        end
    end

    local count = 0
    for index, action in ipairs(self.actions) do
        if action:IsOver() then
            count = count + 1
        end
    end
    if self.actions and count == #self.actions then
        self.stateMachine:ChangeNextState()
    end
end
function AirGroupActionStateBase:Exit()
    FSMState.Exit(self)
    self.actions = {}
end

--endregion
--region 空状态
---@class AirGroupActionNoneState:AirGroupActionStateBase
_class("AirGroupActionNoneState", AirGroupActionStateBase)
AirGroupActionNoneState = AirGroupActionNoneState
function AirGroupActionNoneState:Enter(machine)
end

function AirGroupActionNoneState:Exit()
    AirGroupActionStateBase.Exit(self)
end
--endregion

---@class AirGroupActionMoveState:AirGroupActionStateBase
_class("AirGroupActionMoveState", AirGroupActionStateBase)
AirGroupActionMoveState = AirGroupActionMoveState
function AirGroupActionMoveState:Enter()
    local pos = self.libMaker:PopPoint(table.count(self.pets))
    for _, pet in pairs(self.pets) do
        local floor = pet:GetFloor()
        local pos = self.libMaker:GetCurPos(pet:TemplateID())
        if pos then
            local action = AirActionMove:New(pet, pos, floor, self.owner:GetAirMain())
            self.owner:PlayAction(pet, action)
            table.insert(self.actions, action)
        end
    end
end

---@class AirGroupActionFollowState:AirGroupActionStateBase
_class("AirGroupActionFollowState", AirGroupActionStateBase)
AirGroupActionFollowState = AirGroupActionFollowState
function AirGroupActionFollowState:Enter()
    self.libMaker:PopPoint(table.count(self.pets))
    local pets = table.toArray(self.pets)
    local beFollowPet = pets[1]
    local beFollowAction
    if beFollowPet then
        local floor = beFollowPet:GetFloor()
        beFollowAction =
            AirActionMove:New(
            beFollowPet,
            self.libMaker:GetCurPos(beFollowPet:TemplateID()),
            floor,
            self.owner:GetAirMain()
        )
        self.owner:PlayAction(beFollowPet, beFollowAction)
        table.insert(self.actions, beFollowAction)
    end

    local followPet = pets[2]
    if followPet then
        local floor = followPet:GetFloor()
        local action =
            AirActionMove:New(
            followPet,
            self.libMaker:GetCurPos(followPet:TemplateID()),
            floor,
            self.owner:GetAirMain()
        )
        self.owner:PlayAction(followPet, action)
        table.insert(self.actions, action)
    end
    if table.count(self.pets) > 2 then
        for index, pet in ipairs(pets) do
            if index > 2 then
                self.owner:GetAirMain():RandomActionForPet(pet)
            end
        end
        Log.exception("并排走出现了三个人？")
    end
end

---@class AirGroupActionLookAtState:AirGroupActionStateBase
_class("AirGroupActionLookAtState", AirGroupActionStateBase)
AirGroupActionLookAtState = AirGroupActionLookAtState

function AirGroupActionLookAtState:Enter()
    local pos = self.libMaker:GetTargetPos()
    for index, pet in pairs(self.pets) do
        local action = AirActionRotate:New(pet, pos, 100)
        self.owner:PlayAction(pet, action)
        table.insert(self.actions, action)
    end
end

_class("AirGroupActionTalkState", AirGroupActionStateBase)
---@class AirGroupActionTalkState:AirGroupActionStateBase
AirGroupActionTalkState = AirGroupActionTalkState

function AirGroupActionTalkState:Constructor()
    self.curPetIndex = 1
    self.maxRound = 0
    self.curAction = nil
    self.takeState = AircraftSocialTalkType.Normal
    self.petInCam = false
end

function AirGroupActionTalkState:Enter(maxRound)
    self.curPetIndex = 1
    self.curRound = self.socialArea:GetSocialRound()
    self.maxRound = maxRound or self.socialArea:GetMaxRound()
    self:Talk()
end

function AirGroupActionTalkState:GetAirCamera3D()
    return self:GetAirMain():GetMainCamera()
end

function AirGroupActionTalkState:CheckPetInCam()
    if not self.petInCam then
        ---@type UnityEngine.Camera
        local camera3d = self:GetAirCamera3D()
        for id, pet in pairs(self.pets) do
            local tr = pet:Transform()
            local petPos = tr.position
            local screenPos = camera3d:WorldToScreenPoint(petPos)
            ---在屏幕内
            if
                (screenPos.x <= UnityEngine.Screen.width and screenPos.x > 0 and
                    screenPos.y <= UnityEngine.Screen.height and
                    screenPos.y > 0)
             then
                self.petInCam = true
                break
            end
        end
    end
    return self.petInCam
end

function AirGroupActionTalkState:CanRealTalk()
    ---@type AircraftMain
    local airMain = self:GetAirMain()
    local nearByState = airMain:GetCamNearbyState()
    local petInCam = self:CheckPetInCam()
    return nearByState and petInCam
end

function AirGroupActionTalkState:Talk()
    local talkCfg = nil
    if self.takeState == AircraftSocialTalkType.Normal and self:CanRealTalk() then
        talkCfg = AirHelper.GetGroupTalk(self.pets, nil)
        if talkCfg then
            self.takeState = AircraftSocialTalkType.RealTalk
        else
            self.canRealTalk = false
        end
    end

    if self.takeState == AircraftSocialTalkType.Normal then
        local pet = self.pets[self.petIds[self.curPetIndex]]
        if pet then
            local action = AirActionFace:New(pet, pet:GetRandomFace())
            self.owner:PlayAction(pet, action)
            self.curAction = action
        end
    elseif self.takeState == AircraftSocialTalkType.RealTalk then
        ---@type AirActionGroupTalk
        local action = AirActionGroupTalk:New(self.pets, talkCfg, self:GetAirMain())
        self.curAction = action
        for k, pet in pairs(self.pets) do
            pet:SetSocialGroupTalk(action)
        end
        action:Start()
    end
end

function AirGroupActionTalkState:Exit()
    AirGroupActionStateBase.Exit(self)
    self.curPetIndex = 1
    self.curRound = 0
    self.maxRound = 0
    self.curAction = nil
end

function AirGroupActionTalkState:Excute()
    if self.pets then
        for key, pet in pairs(self.pets) do
            if not pet:IsAlive() then
                --这里容错，发现社交中的星灵销毁了，停止整个社交
                self:GetAirMain():StopSocialByPet(pet)
                return
            end
        end
    end

    if self.curAction and self.curAction:IsOver() then
        if self.takeState == AircraftSocialTalkType.RealTalk then
            self.stateMachine:ChangeNextState()
        elseif self.takeState == AircraftSocialTalkType.Normal then
            if self.curPetIndex < #self.petIds then
                self.curPetIndex = self.curPetIndex + 1
            else
                self.curPetIndex = 1
            end
            self.curRound = self.curRound + 1
            self.socialArea:SetSocialRound(self.curRound, true)
            if self.curRound > self.maxRound then
                self.stateMachine:ChangeNextState()
            else
                self:Talk()
            end
        end
    end
end

---@class AirGroupActionFurnitureState:AirGroupActionStateBase
_class("AirGroupActionFurnitureState", AirGroupActionStateBase)
AirGroupActionFurnitureState = AirGroupActionFurnitureState

function AirGroupActionFurnitureState:Enter()
    local seqMaker = self.libMaker:GetSeqMaker()
    self.isActionSeq = seqMaker ~= nil
    if seqMaker then
        ---@type AircraftFurniture
        local furn = self.libMaker:GetFurniture()
        if furn then
            local index = 1
            for petTempId, pet in pairs(self.pets) do
                local point = self.libMaker:GetFurniturePoint(petTempId)
                local pos, rot = point:InteractionPoint()
                local endPos = point:MovePoint()
                local furnAction =
                    AirActionSequence:New(
                    pet,
                    pos,
                    rot,
                    endPos,
                    seqMaker,
                    index,
                    self.socialArea:GetSocialRound(),
                    function()
                        pet:SetFurnitureType(furn:Type())
                    end,
                    function(round, index)
                        self.socialArea:SetSocialRound(round, true, index)
                    end,
                    function()
                        furn:ReleasePoint(point)
                        pet:SetFurnitureType(0)
                    end
                )
                self.owner:PlayAction(pet, furnAction)
                table.insert(self.actions, furnAction)
                index = index + 1
            end
        else
            Log.error("没找到家具直接进入下回合")
            self.stateMachine:ChangeNextState()
        end
    else
        ---@type AircraftFurniture
        local furn = self.libMaker:GetFurniture()
        if furn then
            for petTempId, pet in pairs(self.pets) do
                local point = self.libMaker:GetFurniturePoint(petTempId)
                local duration = pet:GetSocialRemainTime()
                local cond = AircraftPetFurPointCondition:New(pet, furn, nil, point)
                local furnAction = AirActionOnFurniture:New(pet, furn, point, cond, duration)
                self.owner:PlayAction(pet, furnAction)
                table.insert(self.actions, furnAction)
            end
        else
            Log.error("没找到家具直接进入下回合")
            self.stateMachine:ChangeNextState()
        end
    end
end

function AirGroupActionFurnitureState:Excute()
    AirGroupActionStateBase.Excute(self)
    if not self.isActionSeq then
        for _, action in pairs(self.actions) do
            local time = action:CurrentTime()
            local duration = action:Duration()
            local remainTime = math.floor(duration - time)
            local pet = action:GetPets()[1]
            if pet then
                pet:SetSocialRemainTime(remainTime)
            end
        end
    end
end

---@class AirGroupActionStandState:AirGroupActionStateBase
_class("AirGroupActionStandState", AirGroupActionStateBase)
AirGroupActionStandState = AirGroupActionStandState
function AirGroupActionStandState:Enter()
    for _, pet in pairs(self.pets) do
        local action = AirActionStand:New(pet, 5000, 7000)
        self.owner:PlayAction(pet, action)
        table.insert(self.actions, action)
    end
end

-----------------------------靠近---------------------------------------
------@class AirGroupActionCloserState:AirGroupActionStateBase
_class("AirGroupActionCloserState", AirGroupActionStateBase)
AirGroupActionCloserState = AirGroupActionCloserState
function AirGroupActionCloserState:Enter()
    for _, pet in pairs(self.pets) do
        local floor = pet:GetFloor()
        local pos = self.libMaker:GetCloserPos()
        if pos then
            local action = AirActionMove:New(pet, pos, floor, self.owner:GetAirMain())
            self.owner:PlayAction(pet, action)
            table.insert(self.actions, action)
        end
    end
end

-----------------------------靠近---------------------------------------

-----------------------------定位--------------------------------------
------@class AirGroupActionLocatedState:AirGroupActionStateBase
_class("AirGroupActionLocatedState", AirGroupActionStateBase)
AirGroupActionLocatedState = AirGroupActionLocatedState
function AirGroupActionLocatedState:Enter()
    local pos = self.libMaker:PopPoint(table.count(self.pets))
    for _, pet in pairs(self.pets) do
        local floor = pet:GetFloor()
        local pos = self.libMaker:GetCurPos(pet:TemplateID())
        if pos then
            local action = AirActionLocated:New(pet, pos, floor)
            self.owner:PlayAction(pet, action)
            table.insert(self.actions, action)
        end
    end
end
-----------------------------定位--------------------------------------

--region 边走边聊
---@class AirGroupActionMoveTalkState:AirGroupActionStateBase
_class("AirGroupActionMoveTalkState", AirGroupActionStateBase)
AirGroupActionMoveTalkState = AirGroupActionMoveTalkState

function AirGroupActionMoveTalkState:Enter()
    local subStates = AirSocialSubLibType[self:GetStateType()]
    self:AddChild(
        subStates,
        function()
            -- 循环执行
            self.childMachines[1]:StartState()
            self.libMaker:ReleasePoint()
        end
    )
    self:AddChild(
        {AirGroupActionStateType.Talk},
        function()
            -- 总聊天结束才结束整个状态流程
            self.owner:OnProcessFinish()
        end
    )
    self.childMachines[1]:StartState()

    -- 子状态机同时开启聊天状态
    self.childMachines[2]:ChangeState(AirGroupActionStateType.Talk)
end

function AirGroupActionMoveTalkState:Excute()
end

--endregion 边走边聊

---------------------------------校正位置---------------------------------
---@class AirGroupActionCorrectState:AirGroupActionStateBase
_class("AirGroupActionCorrectState", AirGroupActionStateBase)
AirGroupActionCorrectState = AirGroupActionCorrectState
function AirGroupActionCorrectState:Enter()
    local pets = table.toArray(self.pets)
    local beFollowPet = pets[1]
    local beFollowAction
    if beFollowPet then
        local action = AirActionRotate:New(beFollowPet, beFollowPet:WorldPosition() + Vector3(0, 0, -1.5), 100)
        self.owner:PlayAction(beFollowPet, action)
        table.insert(self.actions, action)
    end
    local followPet = pets[2]
    if followPet then
        local floor = followPet:GetFloor()
        local action =
            AirActionMove:New(
            followPet,
            beFollowPet:WorldPosition() + Vector3(0, 0, -1.5),
            floor,
            self.owner:GetAirMain()
        )
        self.owner:PlayAction(followPet, action)
        table.insert(self.actions, action)
    end
    if table.count(self.pets) > 2 then
        for index, pet in ipairs(pets) do
            if index > 2 then
                self.owner:GetAirMain():RandomActionForPet(pet)
            end
        end
        Log.exception("并排走出现了三个人？")
    end
end

--------------------------------------边家具边聊
-----region 边走边聊
---@class AirGroupActionFurnitureTalkState:AirGroupActionStateBase
_class("AirGroupActionFurnitureTalkState", AirGroupActionStateBase)
AirGroupActionFurnitureTalkState = AirGroupActionFurnitureTalkState

function AirGroupActionFurnitureTalkState:Enter()
    self:AddChild(
        {AirGroupActionStateType.Furniture},
        function()
            --结束整个状态流程
            self.owner:OnProcessFinish()
        end
    )
    self:AddChild(
        {AirGroupActionStateType.Talk},
        function()
            -- 总聊天结束才结束整个状态流程
            -- self.owner:OnProcessFinish()
        end
    )
    self.childMachines[1]:StartState()
    -- 子状态机同时开启聊天状态
    self.childMachines[2]:ChangeState(AirGroupActionStateType.Talk, 99999999)
end

function AirGroupActionFurnitureTalkState:Excute()
end

--endregion 边走边聊
