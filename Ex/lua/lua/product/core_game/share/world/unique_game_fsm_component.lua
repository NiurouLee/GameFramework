--[[------------------------------------------------------------------------------------------
    GameFSMComponent : 
]] --------------------------------------------------------------------------------------------

require "game_fsm_config"

---@class GameFSMComponent: Object
_class("GameFSMComponent", Object)
GameFSMComponent = GameFSMComponent

---@param world MainWorld
function GameFSMComponent:Constructor(world)
    self.GameFSMGenInfo = GameFSMGenInfo:New()
    self.world = world
    self.fsm_id = world.BW_WorldInfo.fsm_id

    ---@type TimeService
    self._timeService = self.world:GetService("Time")
    ---是否能输入
    self._enableHandleInput = false
end

-- function GameFSMComponent:Dispose()
--     if self.fsmImp then
--         self.fsmImp:Destroy()
--         self.fsmImp = nil
--     end
-- end

function GameFSMComponent:Initialize()
    self.GameFSMGenInfo.CustomLogicConfigTable = GameFsmConfig

    self.GameFSMGenInfo.CustomLogicConfigID = self.fsm_id
    self.GameFSMGenInfo.World = self.world
    self.fsmImp = CustomLogicFactory.Static_CreateLogic(self.GameFSMGenInfo)
end

---@return GameStateID
function GameFSMComponent:CurStateID()
    ---@type FSMNode
    local fsmNode = self.fsmImp.nodes.elements[1]
    return fsmNode:CurrentStateID()
end

---@return GameFSMComponent
function GameFSMComponent:Update()
    local deltaTime = self._timeService:GetDeltaTimeMs()
    return self.fsmImp:Update(deltaTime)
end

function GameFSMComponent:EnableHandleInput(enable)
    self._enableHandleInput = enable
end

function GameFSMComponent:GetHandleInputEnable()
    return self._enableHandleInput
end

function GameFSMComponent:Dispose()
    CustomLogicFactory.Static_DestroyLogic(self.fsmImp)
    self.fsmImp = nil
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    MainWorld Extensions
]]
---@return GameFSMComponent
function MainWorld:GameFSM()
    if EDITOR and CHECK_RENDER_ACCESS_LOGIC then 
        local debugInfo = debug.getinfo(2,'S')
        local filePath = debugInfo.short_src
        local renderIndex = string.find(filePath,"_r.lua")
        if renderIndex ~= nil then 
            Log.exception("render file :",filePath," call GameFSM() ",Log.traceback())
            return nil
        end
    end    
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.GameFSM)
end

function MainWorld:HasGameFSM()
    return self:GetUniqueComponent(self.BW_UniqueComponentsEnum.GameFSM) ~= nil
end

function MainWorld:AddGameFSM()
    local index = self.BW_UniqueComponentsEnum.GameFSM
    local component = GameFSMComponent:New(self)
    component:Initialize()
    self:SetUniqueComponent(index, component)
end

function MainWorld:RemoveGameFSM()
    if self:HasGameFSM() then
        self:SetUniqueComponent(self.BW_UniqueComponentsEnum.GameFSM, nil)
    end
end
