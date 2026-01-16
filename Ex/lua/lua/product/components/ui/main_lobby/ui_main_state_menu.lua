--[[
    @通用状态信息栏
]]
---@class UIMainStateMenu:UICustomWidget
_class("UIMainStateMenu", UICustomWidget)
UIMainStateMenu = UIMainStateMenu

function UIMainStateMenu:OnShow(uiParams)
    ---@type UICurrencyMenu
    local sop = self:GetUIComponent("UISelectObjectPath", "currencymenu")
    self.currencyMenu = sop:SpawnObject("UICurrencyMenu")
    self.currencyMenu:SetData({RoleAssetID.RoleAssetDoubleRes, RoleAssetID.RoleAssetPhyPoint})
    self.doubleItem = self.currencyMenu:GetItemByTypeId(RoleAssetID.RoleAssetDoubleRes)
    self.doubleItem:SetSwitchCallBack(
        function()
            if not self._enable then
                return
            end
            if self._open == false then
                self:Send(true)
            else
                self:Send(false)
            end
        end
    )
    self._resModule = self:GetModule(ResDungeonModule)
    self._aircraftModule = self:GetModule(AircraftModule)
    self._open = self._resModule:IsOpenDoubleRes()
    self._enable = true

    self._power = self:GetUIComponent("Transform", "power")
    self._powerPool = self:GetUIComponent("UISelectObjectPath", "powerpool")
    --self._areaBg = self:GetUIComponent("RectTransform", "areaBg")
    --体力
    local powerPool = self._powerPool:SpawnObject("UIPowerInfo")
    powerPool:SetData(self._power, self.currencyMenu:GetItemByTypeId(RoleAssetID.RoleAssetPhyPoint))

    self:Refresh()
end

function UIMainStateMenu:SetOpen()
    local room = self._aircraftModule:GetResRoom()
    if room then
        self.doubleItem:Enable(true)
        self.doubleItem:ShowSwitch(true)
        self.doubleItem:ShowOpen(self._open)
        local guideModule = self:GetModule(GuideModule)
        if guideModule:GuideInProgress() then
            return
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideShowResDouble)
    else
        self.doubleItem:Enable(false)
    end
end

function UIMainStateMenu:OpenAndClose(msg)
    self:StartTask(
        function(TT)
            ToastManager.ShowToast(StringTable.Get(msg)) --"双倍资源券不足")
            if self.doubleItem then
                self.doubleItem:ShowOpen(true)
            end
            self._enable = false
            YIELD(TT, 100)
            self._enable = true
            if self.doubleItem then
                self.doubleItem:ShowOpen(false)
            end
        end
    )
end

function UIMainStateMenu:Send(open)
    self:StartTask(
        function(TT)
            local a = self._resModule:SetDoubleResSwitch(TT, open)
            if a == RES_DUNGEON_CODE.RES_DUNGEON_SUCCEED then
                self._open = open
                self:SetOpen()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeResDouble, self._open)
            else
                if a == RES_DUNGEON_CODE.RES_DUNGEON_DOUBLE_RES_NOT_ENOUGH then --（）
                    self:OpenAndClose("str_res_instance_detail_double_no_enough") --("卷不足")
                elseif a == RES_DUNGEON_CODE.RES_DUNGEON_DOUBLE_RES_INVALID then
                    self:OpenAndClose("str_res_instance_detail_double_switch_error") --("状态切换失败")
                elseif a == RES_DUNGEON_CODE.RES_DUNGEON_AIRCRAFT_RESOURCE_ROOM_UNOPEN then
                    self:OpenAndClose("str_res_instance_detail_double_no_air") --("资源室没开放")
                end
            end
        end
    )
end

function UIMainStateMenu:Refresh()
    local doubleCount = self._resModule:GetDoubleResNum()
    if doubleCount <= 0 then
        self:Send(false)
    end
    self:SetOpen()
end
