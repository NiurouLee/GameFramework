--[[
    @资源本总览界面
]]
---@class UIResEntryController:UIController
_class("UIResEntryController", UIController)
UIResEntryController = UIResEntryController

function UIResEntryController:OnShow(uiParams)
    local openMainType = uiParams[1]
    local openSubType = uiParams[2]
    local dontShowAni = uiParams[3]
    local resDungeonModule = self:GetModule(ResDungeonModule)
    self.clientResInstance = resDungeonModule:GetClientResInstance()
    self.entryCmp = self:GetUIComponent("UISelectObjectPath", "entrys")
    local count = self.clientResInstance:GetEntryCount()
    self.entryCmp:SpawnObjects("UIResEntryCell", count)
    self.entrys = self.entryCmp:GetAllSpawnList()

    local returnHelpPool = self:GetUIComponent("UISelectObjectPath", "returnHelp")
    ---@type UICommonReturnHelp
    local returnHelp = returnHelpPool:SpawnObject("UICommonReturnHelp")
    returnHelp:SetData(true)

    local topButton = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            if not GameGlobal.UIStateManager():IsShow("UIDiscovery") then
                self:SwitchState(UIStateType.UIDiscovery)
            else
                self:CloseDialog()
            end
            GameGlobal.EventDispatcher():Dispatch(GameEventType.CloseResInstance)
        end
    )
    self.canvasGroup = self:GetGameObject().transform:GetComponent("CanvasGroup")
    self.animation = self:GetGameObject().transform:GetComponent("Animation")

    if GameGlobal.UIStateManager():IsShow("UIStage") then
        GameGlobal.UIStateManager():CloseDialog("UIStage")
    end
    self:Refresh(dontShowAni)
    if not dontShowAni then
        self.animation:Play()
    else
    end
    if openMainType then
        self.entrys[openMainType]:picOnClick(nil, openSubType)
    end
    -- self.canvasGroup.alpha = 1
end
function UIResEntryController:LoadDataOnEnter(TT, res, uiParams)
    local resDungeonModule = self:GetModule(ResDungeonModule)
    local result = resDungeonModule:GetOpenStatus(TT)
    if result and table.count(result) > 0 then
        res:SetSucc(true)
    else
        res:SetSucc(false)
    end
end

function UIResEntryController:Refresh(dontShowAni)
    local entryDatas = self.clientResInstance:GetEntryDatas()
    for index, entry in ipairs(self.entrys) do
        ---@type UIResEntryCell
        entry:Refresh(entryDatas[index], dontShowAni)
    end
    if EngineGameHelper.EnableAppleVerifyBulletin() then
        self:GetEntryCell(DungeonType.DungeonType_equip):SetActive(false)
    end
end
function UIResEntryController:OnUpdate(deltaTimeMS)
end

function UIResEntryController:OnHide()
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.CloseResInstance)
end

function UIResEntryController:GetEntryCell(mainType)
    for index, entry in ipairs(self.entrys) do
        if entry:GetMainType() == mainType then
            return entry:GetGameObject("pic")
        end
    end
end
