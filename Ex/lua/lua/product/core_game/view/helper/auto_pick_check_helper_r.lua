--自动战斗 点选错误时的处理辅助
_class("AutoPickCheckHelperRender", Object)
---@class AutoPickCheckHelperRender : Object
AutoPickCheckHelperRender = AutoPickCheckHelperRender

---@return boolean
function AutoPickCheckHelperRender.IsAutoFightRunning()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type AutoFightService
    local autoSvc = mainWorld:GetService("AutoFight")
    if autoSvc and autoSvc:IsRunning() then 
        return true
    else
        return false
    end
end
---上报自动战斗点选异常
function AutoPickCheckHelperRender.ReportAutoFightPickError(errorStep,errorType,activeSkillID,curPickPos)
    local cmd = ClientExceptionReportCommand.CreateAutoFightPickErrorReport(activeSkillID,errorStep,errorType,nil,nil,curPickPos)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClientExceptionReport, cmd)
end
--光灵技能ready状态
function AutoPickCheckHelperRender.CheckPetSkillReady(petEntity,skillID)
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    ---@type UtilDataServiceShare
    local utilDataSvc = mainWorld:GetService("UtilData")
    if utilDataSvc then
        if petEntity then
            local ready = utilDataSvc:GetPetSkillReadyAttr(petEntity,skillID)
            if ready and (ready == 1) then
                return true
            else
                return false
            end
        end
    end
    return true --避免意外影响
end