---@class UIN25IdolBreakLoad:UIController
_class("UIN25IdolBreakLoad", UIController)
UIN25IdolBreakLoad = UIN25IdolBreakLoad

function UIN25IdolBreakLoad:Constructor()

end

function UIN25IdolBreakLoad:LoadDataOnEnter(TT, res, uiParams)
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type CCampaignN25
    self._localProcess = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N25)
    ---@type IdolMiniGameComponent
    self._idolComponent = self._localProcess:GetComponent(ECampaignN25ComponentID.ECAMPAIGN_N25_IDOL)
end

function UIN25IdolBreakLoad:OnShow(uiParams)
    self._archivePreviewPath = self:GetUIComponent("UISelectObjectPath", "archivePreview")
    self._archivePreview = self._archivePreviewPath:SpawnObject("UIN25IdolArchiveBreak")
    self._animation = self:GetUIComponent("Animation", "animation")

    local idolInfo = self._idolComponent:GetComponentInfo()
    --- @type IdolProgressInfo
    local breakInfo = idolInfo.break_info
    self._archivePreview:Flush(breakInfo)
end

function UIN25IdolBreakLoad:OnHide()
end

-- 关闭
function UIN25IdolBreakLoad:BtnCloseOnClick(go)
    local lockName = "UIN25IdolBreakLoad:_backAnim"
    self:StartTask(function(TT)
        self:Lock(lockName)
        self._animation:Play("uieff_UIN25IdolBreakLoad_out")
        YIELD(TT, 333)
        self:UnLock(lockName)

        self:CloseDialog()
    end)
end

-- 开启新游戏
function UIN25IdolBreakLoad:BtnNewGameOnClick(go)
    ---@param uiMsgBoxName string
    ---@param priority PopupPriority
    ---@param PopupMsgBoxType PopupMsgBoxType
    ---@param title string
    ---@param text string
    ---@param fnOk function
    ---@param fnOkParam
    ---@param fnCancel function
    ---@param fnCancelParam
    PopupManager.Alert("UIN25IdolMessageBox",
            PopupPriority.Normal, PopupMsgBoxType.OkCancel,
            "", StringTable.Get("str_n25_idol_y_break_new_game_second_confirm"),
            function(param)
                self:DispatchEvent(GameEventType.N25IdolStartPlayGame, IdolStartType.IdolStartType_New)
            end, nil,
            function(param)
                -- self:CloseDialog()
            end, nil
    )
end

-- 继续游戏
function UIN25IdolBreakLoad:BtnContinueGameOnClick(go)
    self:DispatchEvent(GameEventType.N25IdolStartPlayGame, IdolStartType.IdolStartType_Break)
end

