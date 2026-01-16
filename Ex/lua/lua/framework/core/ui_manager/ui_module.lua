--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UIModule用于存放逻辑较复杂的UI长周期数据，常驻内存
    若是结构简单、通用的长周期数据，可以通过GameGlobal:GetInstance():SetData()设置简单的全局字典。但是这种需考虑多人协作时，写入名字相同的key，导致数据获取不正确的问题

    一般是一个逻辑module（GameModule），最多对应一个ui module
    注册时，挂在对应的逻辑module（GameModule）下
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
---@class UIModule
_class("UIModule", Object)
UIModule = UIModule

function UIModule:Constructor()
    self.autoBinder = AutoEventBinder:New(GameGlobal.EventDispatcher())
end
function UIModule:Dispose()
    self.autoBinder:Dispose()
end
function UIModule:AttachEvent(gameEventType, func)
    self.autoBinder:BindEvent(gameEventType, self, func)
end

function UIModule:DetachEvent(gameEventType)
    self.autoBinder:UnBindEvent(gameEventType)
end
function UIModule:DetachAllEvents()
    self.autoBinder:UnBindAllEvents()
end

---@generic T:GameModule
---@param type T
---@return T
function UIModule:GetModule(type)
    return GameGlobal.GetModule(type)
end
---@generic T:GameModule, K:UIModule
---@param gameModuleProto T
---@return K
function UIModule:GetUIModule(gameModuleProto)
    return GameGlobal.GetUIModule(gameModuleProto)
end

function UIModule:StartTask(func, ...)
    GameGlobal.TaskManager():StartTask(func, ...)
end
function UIModule:AttachEvent(gameEventType, func)
    self.autoBinder:BindEvent(gameEventType, self, func)
end

function UIModule:DetachEvent(gameEventType)
    self.autoBinder:UnBindEvent(gameEventType)
end
function UIModule:DetachAllEvents()
    self.autoBinder:UnBindAllEvents()
end