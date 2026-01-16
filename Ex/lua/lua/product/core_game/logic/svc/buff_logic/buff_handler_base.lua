require("trigger_base")
require("trigger_owner")
--buff处理器
_class("BuffHandlerBase", ITriggerOwner)
---@class BuffHandlerBase:ITriggerOwner
BuffHandlerBase = BuffHandlerBase
function BuffHandlerBase:Constructor(buffInstance, triggerCfg, logicCfg)
    ---@type BuffInstance
    self._buffInstance = buffInstance
    local world = buffInstance:World()
    self._world = world
    ---@type TriggerService
    local triggerSvc = world:GetService("Trigger")
    ---@type BuffLogicService
    local bufflogicSvc = world:GetService("BuffLogic")

    ---@type CombinedTrigger
    self._trigger = triggerSvc:CreateTrigger(self, triggerCfg, world)
    ---@type BuffLogicBase
    self._logic = bufflogicSvc:CreateBuffLogic(buffInstance, logicCfg)

    self:Attach()
end

function BuffHandlerBase:Attach()
    ---@type TriggerService
    local svc = self._buffInstance:World():GetService("Trigger")
    svc:Attach(self._trigger)
end

function BuffHandlerBase:Detach()
    ---@type TriggerService
    local svc = self._buffInstance:World():GetService("Trigger")
    svc:Detach(self._trigger)
end

function BuffHandlerBase:SetActive(active)
    self._trigger:SetActive(active)
end

function BuffHandlerBase:DoOverlap(logicParam, context)
    if self._logic and logicParam then
        for i, logic in ipairs(self._logic) do
            self:PrintBuffHandlerLog("buff logic overlap ---- ", logic:GetLogicName())
            local logger = self._world:GetSyncLogger()
            logger:Trace(
                {
                    key = "buffOverlap",
                    buffID = self._buffInstance:BuffID(),
                    entityID = self:GetOwnerEntity():GetID(),
                    logic = logic:GetLogicName()
                }
            )
            local buffResult = logic:DoOverlap(logicParam[i], context)
            if buffResult then
                local res =
                    DataBuffLogicResult:New(
                    self:GetOwnerEntity():GetID(),
                    self._buffInstance:BuffSeq(),
                    logic:GetLogicName(),
                    NTBuffLoad:New(),
                    buffResult
                )
                res:SetBuffID(self._buffInstance:BuffID())
                res:SetLogicType("Overlap")
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end
end

function BuffHandlerBase:GetTrigger()
    return self._trigger
end

function BuffHandlerBase:GetTriggerType()
    return self._trigger:GetTriggerType()
end

function BuffHandlerBase:GetNotifyType()
    return self._trigger:GetNotifyType()
end

function BuffHandlerBase:GetOwnerEntity()
    return self._buffInstance:Entity()
end

function BuffHandlerBase:GetWorld()
    return self._buffInstance:World()
end

function BuffHandlerBase:PrintBuffHandlerLog(...)
    if self._world and self._world:IsDevelopEnv() then 
        Log.debug(...)
    end
end

--加载处理器
_class("BuffLoadHandler", BuffHandlerBase)
BuffLoadHandler = BuffLoadHandler
function BuffLoadHandler:Constructor()
end

function BuffLoadHandler:OnTrigger(notify, triggers)
    if self._logic then
        for index, logic in ipairs(self._logic) do
            self:PrintBuffHandlerLog("buff load trigger logic ---- ", logic:GetLogicName())
            local logger = self._world:GetSyncLogger()
            logger:Trace(
                {
                    key = "buffLoad",
                    buffID = self._buffInstance:BuffID(),
                    entityID = self:GetOwnerEntity():GetID(),
                    logic = logic:GetLogicName()
                }
            )
            local buffResult = logic:DoLogic(notify, triggers, index)
            if notify and buffResult then
                local res =
                    DataBuffLogicResult:New(
                    self:GetOwnerEntity():GetID(),
                    self._buffInstance:BuffSeq(),
                    logic:GetLogicName(),
                    notify,
                    buffResult,
                    triggers
                )
                res:SetBuffID(self._buffInstance:BuffID())
                res:SetLogicType("Load")
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end
end

--卸载处理器
_class("BuffUnloadHandler", BuffHandlerBase)
BuffUnloadHandler = BuffUnloadHandler
function BuffUnloadHandler:Constructor()
end

function BuffUnloadHandler:OnTrigger(notify, triggers)
    if self._logic then
        for _, logic in ipairs(self._logic) do
            self:PrintBuffHandlerLog("buff unload trigger logic ---- ", logic:GetLogicName())
            local logger = self._world:GetSyncLogger()
            logger:Trace(
                {
                    key = "buffUnload",
                    buffID = self._buffInstance:BuffID(),
                    entityID = self:GetOwnerEntity():GetID(),
                    logic = logic:GetLogicName()
                }
            )
            local buffResult = logic:DoLogic(notify, triggers)
            if notify and buffResult then
                local res =
                    DataBuffLogicResult:New(
                    self:GetOwnerEntity():GetID(),
                    self._buffInstance:BuffSeq(),
                    logic:GetLogicName(),
                    notify,
                    buffResult,
                    triggers
                )
                res:SetBuffID(self._buffInstance:BuffID())
                res:SetLogicType("Unload")
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end
    self._buffInstance:Unload(notify, true)
end

--激活处理器
_class("BuffActiveHandler", BuffHandlerBase)
BuffActiveHandler = BuffActiveHandler
function BuffActiveHandler:Constructor()
end

function BuffActiveHandler:OnTrigger(notify, triggers)
    self._buffInstance:SetActive(true)

    if self._logic then
        for _, logic in ipairs(self._logic) do
            self:PrintBuffHandlerLog("buff active trigger logic ---- ", logic:GetLogicName())
            local logger = self._world:GetSyncLogger()
            logger:Trace(
                {
                    key = "buffActive",
                    buffID = self._buffInstance:BuffID(),
                    entityID = self:GetOwnerEntity():GetID(),
                    logic = logic:GetLogicName()
                }
            )
            local buffResult = logic:DoLogic(notify, triggers)
            if notify and buffResult then
                local res =
                    DataBuffLogicResult:New(
                    self:GetOwnerEntity():GetID(),
                    self._buffInstance:BuffSeq(),
                    logic:GetLogicName(),
                    notify,
                    buffResult,
                    triggers
                )
                res:SetBuffID(self._buffInstance:BuffID())
                res:SetLogicType("Active")
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end
end

--失活处理器
_class("BuffDeactiveHandler", BuffHandlerBase)
BuffDeactiveHandler = BuffDeactiveHandler
function BuffDeactiveHandler:Constructor()
end

function BuffDeactiveHandler:OnTrigger(notify, triggers)
    self._buffInstance:SetActive(false)

    if self._logic then
        for _, logic in ipairs(self._logic) do
            self:PrintBuffHandlerLog("buff deactive trigger logic ---- ", logic:GetLogicName())
            local logger = self._world:GetSyncLogger()
            logger:Trace(
                {
                    key = "buffDeactive",
                    buffID = self._buffInstance:BuffID(),
                    entityID = self:GetOwnerEntity():GetID(),
                    logic = logic:GetLogicName()
                }
            )
            local buffResult = logic:DoLogic(notify, triggers)
            if notify and buffResult then
                local res =
                    DataBuffLogicResult:New(
                    self:GetOwnerEntity():GetID(),
                    self._buffInstance:BuffSeq(),
                    logic:GetLogicName(),
                    notify,
                    buffResult,
                    triggers
                )
                res:SetBuffID(self._buffInstance:BuffID())
                res:SetLogicType("Deactive")
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end
end

--执行处理器
_class("BuffExecuteHandler", BuffHandlerBase)
BuffExecuteHandler = BuffExecuteHandler

function BuffExecuteHandler:OnTrigger(notify, triggers)
    if self._logic then
        for _, logic in ipairs(self._logic) do
            self:PrintBuffHandlerLog("buff exec trigger logic ---- ", logic:GetLogicName())
            local logger = self._world:GetSyncLogger()
            logger:Trace(
                {
                    key = "buffExec",
                    buffID = self._buffInstance:BuffID(),
                    entityID = self:GetOwnerEntity():GetID(),
                    logic = logic:GetLogicName()
                }
            )
            local buffResult = logic:DoLogic(notify, triggers)
            if notify and buffResult then
                local res =
                    DataBuffLogicResult:New(
                    self:GetOwnerEntity():GetID(),
                    self._buffInstance:BuffSeq(),
                    logic:GetLogicName(),
                    notify,
                    buffResult,
                    triggers
                )
                res:SetBuffID(self._buffInstance:BuffID())
                res:SetLogicType("Exec")
                self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            end
        end
    end
end
