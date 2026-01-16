---@class UIActivityCommonComponentEnter:UICustomWidget
_class("UIActivityCommonComponentEnter", UICustomWidget)
UIActivityCommonComponentEnter = UIActivityCommonComponentEnter

---------------------------------------------------
--- 活动通用组件入口按钮逻辑
---
--- 支持 显示 SetNew() 和 SetRed()
--- 支持 显示道具图标和道具数量， SetIcon() 和 SetText()
---------------------------------------------------

function UIActivityCommonComponentEnter:OnShow(uiParams)
    self:_AttachEvents()
end

function UIActivityCommonComponentEnter:OnHide()
    self:_DetachEvents()
end

function UIActivityCommonComponentEnter:Destroy()
    if self._EMIMatResRequest then
        self._EMIMat = nil
        self._EMIMatResRequest:Dispose()
        self._EMIMatResRequest = nil
    end
end

--region set option
---------------------------------------------------
--- 可选项
--- 需要在 SetData 之前设置
---------------------------------------------------
function UIActivityCommonComponentEnter:SetNew(widgetName, checkNewFunc)
    widgetName = widgetName or "new"

    self._newObj = self:GetGameObject(widgetName)
    self._checkNewFunc = checkNewFunc
end

function UIActivityCommonComponentEnter:SetRed(widgetName, checkRedFunc)
    widgetName = widgetName or "red"

    self._redObj = self:GetGameObject(widgetName)
    self._checkRedFunc = checkRedFunc
end

function UIActivityCommonComponentEnter:SetNew_RedDotModule(widgetName, newdotType)
    widgetName = widgetName or "new"

    self._newObj = self:GetGameObject(widgetName)
    self._newdotType = newdotType
end

function UIActivityCommonComponentEnter:SetRed_RedDotModule(widgetName, reddotType)
    widgetName = widgetName or "red"

    self._redObj = self:GetGameObject(widgetName)
    self._reddotType = reddotType
end

function UIActivityCommonComponentEnter:SetIcon(widgetName, icon)
    widgetName = widgetName or "icon"

    ---@type UnityEngine.UI.RawImageLoader
    local obj = self:GetUIComponent("RawImageLoader", widgetName)
    obj:LoadImage(icon)
end

function UIActivityCommonComponentEnter:SetText(widgetName, str)
    widgetName = widgetName or "text"

    ---@type UILocalizationText
    local obj = self:GetUIComponent("UILocalizationText", widgetName)
    obj:SetText(str)
end

function UIActivityCommonComponentEnter:SetLocalizedTMPMaterial(widgetName, matName)
    self._localizedTMP = self:GetUIComponent("UILocalizedTMP", widgetName)

    -- self._localizedTMP.fontMaterial = UnityEngine.Material:New(self._localizedTMP.fontMaterial)

    self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset(matName, LoadType.Mat)
    self._EMIMat = self._EMIMatResRequest.Obj
    local mat = self._localizedTMP.fontMaterial
    self._localizedTMP.fontMaterial = self._EMIMat
    self._localizedTMP.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end
--endregion

---------------------------------------------------
function UIActivityCommonComponentEnter:SetData(campaign, uiCallback)
    ---@type UIActivityCampaign
    self._campaign = campaign
    self._uiCallback = uiCallback

    self:_CheckPoint()
end

function UIActivityCommonComponentEnter:BtnOnClick()
    if self._uiCallback then
        self._uiCallback()
    end
end

--region AttachEvent
function UIActivityCommonComponentEnter:_AttachEvents()
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:AttachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

function UIActivityCommonComponentEnter:_DetachEvents()
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:DetachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

function UIActivityCommonComponentEnter:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign and self._campaign._id == campaign_id then
        self:_CheckPoint()
    end
end

function UIActivityCommonComponentEnter:_OnQuestUpdate()
    self:_CheckPoint()
end

function UIActivityCommonComponentEnter:_CheckPoint()
    if self._newdotType or self._reddotType then
        self:_CheckPoint_RedDotModule()
        return
    end

    local new = self._checkNewFunc and self._checkNewFunc() or false
    local red = self._checkRedFunc and self._checkRedFunc() or false

    UIActivityHelper.SetWidgetNewAndRed(self._newObj, new, self._redObj, red)
end

function UIActivityCommonComponentEnter:_CheckPoint_RedDotModule()
    GameGlobal.TaskManager():StartTask(
        function(TT)
            local checkList = {}
            checkList[#checkList + 1] = self._newdotType
            checkList[#checkList + 1] = self._reddotType

            ---@type RedDotModule
            local redDotModule = GameGlobal.GetModule(RedDotModule)
            local results = redDotModule:RequestRedDotStatus(TT, checkList)

            local new = results[self._newdotType]
            local red = results[self._reddotType]
            UIActivityHelper.SetWidgetNewAndRed(self._newObj, new, self._redObj, red)
        end
    )
end
--endregion
