---@class UIN22EntrustEventTransfer : UIN22EntrustEventBase
_class("UIN22EntrustEventTransfer", UIN22EntrustEventBase)
UIN22EntrustEventTransfer = UIN22EntrustEventTransfer

-- 虚函数
function UIN22EntrustEventTransfer:Refresh()
    self:_SetRoot(false)

    local cfg = self:GetCfgCampaignEntrustEvent()
    local params = cfg.Params[1]
    local desc = params.Desc
    self._targetId = cfg.TargetID
    
    local pass = self._component:IsEventPass(self._levelId, self._eventId)
    if pass then
        -- 完成之后，点击即移动
        self:SetPlayer(self._targetId)
        self:CloseDialog()
        return
    end

    -- 如果没有 target ，则直接完成
    if not self._targetId then
        self:RequestEvent()
        return
    end

    -- 打开窗口
    self:_SetRoot(true)
    self:_SetMainDesc(StringTable.Get(desc))

    -- 确定按钮
    local txtConfirm = StringTable.Get("str_n22_entrust_event_transfer_desc_confirm")
    self:_SetConfirmBtn(true, txtConfirm, function()
        self:RequestEvent()
    end)

    -- 退出按钮
    local txtExit = StringTable.Get("str_n22_entrust_event_exits_leave")
    self:_SetExitBtn(txtExit, function()
        self:CloseDialog()
    end)
end

-- 虚函数
function UIN22EntrustEventTransfer:OnEventFinish(rewards)
    Log.info("UIN22EntrustEventTransfer:OnEventFinish()")

    if self._targetId then
        -- 完成之后，自动移动 Player 到 Target
        self:SetPlayer(self._targetId)

        local targetPass = self._component:IsEventPass(self._levelId, self._targetId)
        if not targetPass then
            local targetType = self._component:GetEventType(self._targetId)
            if targetType == EntrustEventType.EntrustEventType_Transfer then
                local targetCfg = self:GetCfgCampaignEntrustEvent(self._targetId)
                if not targetCfg.TargetID or targetCfg.TargetID == self._eventId then
                     -- 双向传送，自动完成
                     -- 单向传送，自动完成
                     -- 传向其他位置，不自动完成
                    self:RequestEvent(self._targetId)
                    return -- 不在这里 CloseDialog ，要在请求成功后关闭
                end
            end
        end
    end
    self:CloseDialog()
end
