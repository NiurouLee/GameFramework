--- @class UIN34DispatchType
local UIN34DispatchType =
{
    OpenDialogue = 1,
}
_enum("UIN34DispatchType", UIN34DispatchType)

--
---@class UIN34DispatchTerminalMainControlller : UIController
_class("UIN34DispatchTerminalMainControlller", UIController)
UIN34DispatchTerminalMainControlller = UIN34DispatchTerminalMainControlller

function UIN34DispatchTerminalMainControlller:Constructor()
    self._inDialogue = false
end

---@param res AsyncRequestRes
function UIN34DispatchTerminalMainControlller:LoadDataOnEnter(TT, res, uiParams)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type CCampaignN25
    self._localProcess = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N34)
    ---@type IdolMiniGameComponent
    self._dispatchComponent = self._localProcess:GetComponent(ECampaignN34ComponentID.ECAMPAIGN_N34_DISPATCH)
    self._dispatchComponentInfo  = self._dispatchComponent:GetComponentInfo()

    self._openType = uiParams[1]
    if self._openType == UIN34DispatchType.OpenDialogue then
        self._odArchId = uiParams[2]
    end
  
end
--初始化
function UIN34DispatchTerminalMainControlller:OnShow(uiParams)
    self:InitWidget()

    if self._openType == UIN34DispatchType.OpenDialogue then
        self:AutoOpenDialogue(self._odArchId)
    else
        self:LoadMainContent()
    end

end
--获取ui组件
function UIN34DispatchTerminalMainControlller:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.mainContent = self:GetUIComponent("UISelectObjectPath", "MainContent")
    ---@type UICustomWidgetPool
    self.logContent = self:GetUIComponent("UISelectObjectPath", "LogContent")
    ---@type UICustomWidgetPool
    self.dialogueLoader = self:GetUIComponent("UISelectObjectPath", "Dialogue")
    self.dialogueObj = self:GetGameObject("Dialogue")
    self.main = self:GetGameObject("Main")
    self.logAndDialogue = self:GetGameObject("LogAndDialogue")
    self.log = self:GetGameObject("Log")
    self.returnBtn = self:GetUIComponent("RectTransform", "ReturnBtn")

    self._logTitle = self:GetUIComponent("UILocalizationText", "LogTitle")
    self._toLogBtn = self:GetUIComponent("Image", "ToLogBtn")

    self._dialogueTitle = self:GetUIComponent("UILocalizationText", "DialogueTitle")
    self._toDialogueBtn = self:GetUIComponent("Image", "ToDialogueBtn")

    self._atlas = self:GetAsset("UIN34Dispatch.spriteatlas", LoadType.SpriteAtlas)
    --generated end--
end

function UIN34DispatchTerminalMainControlller:LoadMainContent()

    local componentID = self._dispatchComponent:GetComponentCfgId()
    local ArchCfg = Cfg.cfg_component_dispatch_arch{ComponentID = componentID}
   
    local dispatchInfo = self._dispatchComponentInfo.dispatch_infos

    self._mainItems = self.mainContent:SpawnObjects("UIN34DispatchTerminalMainItem",#ArchCfg)

    for i, v in pairs(self._mainItems) do

        v:SetData(dispatchInfo[i],
                i,
                ArchCfg[i].DispatchLogName,
                function(id)
                    self:OnAwardClick(id)
                end,
                function(item)
                    self:OnItemSelect(item)
                end
                )
        if i == 1 then
            self:OnItemSelect(self._mainItems[i])
        end
    end
end


function UIN34DispatchTerminalMainControlller:OnAwardClick(id)
    local ArchCfg = Cfg.cfg_component_dispatch_arch[id]
    if not ArchCfg then
        return
    end
    local Award = ArchCfg.Rewards
    self:ShowDialog("UIN34DispatchAwardShowControlller",Award)
end

function UIN34DispatchTerminalMainControlller:OnItemSelect(item)
    local ID = item:GetDispatchID()
    local status = item:GetStatus()
    if self._lastID == ID then
        return
    end
    self._lastID = ID
    self._status = status

    if self.selectItem then
        self.selectItem:SetSelected(false)
    end
    self.selectItem = item
    self.selectItem:SetSelected(true)

end

function UIN34DispatchTerminalMainControlller:CheckLog(cfg, BuildingId)
    local log = {}

    local dispatchInfo = self._dispatchComponentInfo.dispatch_infos
    local Info =  dispatchInfo[BuildingId]
    if not Info then
        return log
    end
    local DispatchTime = Cfg.cfg_component_dispatch_arch[BuildingId].DispatchTime
    local startTime = Info.end_time - DispatchTime*1000
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = svrTimeModule:GetServerTime()

    for i, v in ipairs(cfg) do
        if startTime + v.DispatchTime*1000 < curTime then
            table.insert(log,cfg[i])
        end
    end
    return log
end

function UIN34DispatchTerminalMainControlller:ShowLog()

    local SelectBuildingID = self._lastID
    local cfg = Cfg.cfg_mission_dispatch_log{BuildingId = SelectBuildingID}

    local LogData = self:CheckLog(cfg, SelectBuildingID)

    self.main:SetActive(false)
    self.logAndDialogue:SetActive(true)
    self.logContent:SpawnObjects("UIN34DispatchTerminalLogItem", #LogData)
    self.logItems = self.logContent:GetAllSpawnList()
    for i, v in ipairs(self.logItems) do
        v:SetData(LogData[i])
    end
end

function UIN34DispatchTerminalMainControlller:BtnChange(ChangeLog)

    local SelectColor = Color(55/255, 42/255, 31/255, 255/255)
    local UnSelectColor = Color(119/255, 167/255, 188/255, 255/255)
    
    local SelectImageLog = self._atlas:GetSprite("n34_pqtc_btn03")
    local UnSelectImageLog = self._atlas:GetSprite("n34_pqtc_btn05")

    local SelectImageDialogue = self._atlas:GetSprite("n34_pqtc_btn06")
    local UnSelectImageDialogue = self._atlas:GetSprite("n34_pqtc_btn04")

    if ChangeLog then
        self._logTitle.color = SelectColor
        self._dialogueTitle.color = UnSelectColor

        self._toLogBtn.sprite = SelectImageLog
        self._toDialogueBtn.sprite = UnSelectImageDialogue
        self:ToLogBtn()
    else
        if self._status ~= N34TerminalItemStatus.End then
            ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
            return
        end

        self._logTitle.color = UnSelectColor
        self._dialogueTitle.color = SelectColor

        self._toLogBtn.sprite = UnSelectImageLog
        self._toDialogueBtn.sprite = SelectImageDialogue
        self:ToDialogueBtn()
    end
end


------------------------------------------------------------------
--按钮点击
function UIN34DispatchTerminalMainControlller:OpenBtnOnClick(go)
    if self._inDialogue then
        return
    end
    if self._status == N34TerminalItemStatus.NotStart then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    elseif self._status == N34TerminalItemStatus.Going then
        self:BtnChange(true)
        --self:ShowLog()
    elseif self._status == N34TerminalItemStatus.End then
        local SelectBuildingID = self._lastID
        if not SelectBuildingID then
            return
        end
        self:AutoOpenDialogue(SelectBuildingID)
    end
end

--按钮点击
function UIN34DispatchTerminalMainControlller:ReturnBtnOnClick(go)
    if self._inDialogue then
        return
    end
    self:InitWidget()
    self:LoadMainContent()
    self.main:SetActive(true)
    self.logAndDialogue:SetActive(false)
end
--按钮点击
function UIN34DispatchTerminalMainControlller:ToLogBtn(go)
    if self._inDialogue then
        return
    end

    self.log:SetActive(true)
    self:ShowLog()
    self.dialogueObj:SetActive(false)
end
--按钮点击
function UIN34DispatchTerminalMainControlller:ToDialogueBtn()
    if self._inDialogue then
        return
    end
    local SelectBuildingID = self._lastID
    if self._status ~= N34TerminalItemStatus.End then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    self:AutoOpenDialogue(SelectBuildingID)
end
--按钮点击
function UIN34DispatchTerminalMainControlller:BGOnClick(go)
    if self._inDialogue then
        return
    end

    self:CloseDialog()
end

--按钮点击
function UIN34DispatchTerminalMainControlller:ChangeBtnOnClick(go)
    
    if not self.changeLog then
        if self._status ~= N34TerminalItemStatus.End then
            ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
            return
        end
    end

    self:BtnChange(self.changeLog)

    if not self.changeLog then
        self.changeLog = true
    else
        self.changeLog = false
    end

end

function UIN34DispatchTerminalMainControlller:AutoOpenDialogue(archId)
    self.main:SetActive(false)
    self.logAndDialogue:SetActive(true)

    self.log:SetActive(false)
    self.dialogueObj:SetActive(true)

    self.dialogue = self.dialogueLoader:SpawnObject("UIN34DispatchDialogue")
    self.dialogue:Chat(archId, function(inDialogue)
        self._inDialogue = inDialogue
        self:OnInDialogueChanged()
    end)
end

function UIN34DispatchTerminalMainControlller:OnInDialogueChanged()
    self.returnBtn.gameObject:SetActive(not self._inDialogue)
end