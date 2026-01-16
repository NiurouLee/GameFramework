--
---@class UIHomeVisitSpeedup : UIController
_class("UIHomeVisitSpeedup", UIController)
UIHomeVisitSpeedup = UIHomeVisitSpeedup

function UIHomeVisitSpeedup:LoadDataOnEnter(TT, res, uiParams)
    ---@type HomelandModule
    self._module = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self._uiModule = GameGlobal.GetUIModule(HomelandModule)

    local speedup =
        table.icontains(self._module:GetHomelandInfo().visit_info.forge_list, self._uiModule:GetVisitInfo().pstid)
    if speedup then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_visit_has_speedup"))
        res:SetSucc(false)
        return
    end
    res:SetSucc(true)
end

--初始化
function UIHomeVisitSpeedup:OnShow(uiParams)
    self:InitWidget()
    local atlas = self:GetAsset("UIHomelandVisit.spriteatlas", LoadType.SpriteAtlas)
    self._btn =
        UIHomeStateWidget:New(
        {
            {
                UI = self._btnImage,
                Type = UIHomeStateWidgetType.SpriteSwap,
                States = {
                    [1] = atlas:GetSprite("n17_homie_btn5"),
                    [2] = atlas:GetSprite("n17_homie_btn7"),
                    [3] = atlas:GetSprite("n17_homie_btn7")
                }
            },
            {
                UI = self._btnText,
                Type = UIHomeStateWidgetType.TextSwap,
                States = {
                    [1] = StringTable.Get("str_homeland_visit_put_gift"),
                    [2] = StringTable.Get("str_homeland_visit_put_gift_already"),
                    [3] = StringTable.Get("str_homeland_visit_put_gift")
                }
            }
        }
    )
    self:_RefreshList(false)
end
--获取ui组件
function UIHomeVisitSpeedup:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.topBtn = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    --generated end--
    self._empty = self:GetGameObject("empty")
    self._btnImage = self:GetUIComponent("Image", "Speedup")
    self._btnText = self:GetUIComponent("UILocalizationText", "BtnText")
end
function UIHomeVisitSpeedup:_RefreshList(afterSpeedup, finishedInfos)
    local visitInfo = self._uiModule:GetVisitInfo()
    ---@type table<number, ForgeItemInfo>
    local items
    if afterSpeedup then
        items = {}
        local isFinished = {}
        ---@type table< number,VisitHelpTimeInfo>
        local timeInfos = visitInfo.forge_time
        local now = GetSvrTimeNow()
        ---@type table<number, ForgeItemInfo>
        local datas = visitInfo.forge_info.forge_list
        for _, value in ipairs(datas) do
            local time = value.end_time - now
            local info = timeInfos[value.index]
            if info then
                time = time - info.offline_help_time
            end
            --过滤掉已完成但未领取的队列
            if time > 0 then
                table.insert(items, value)
            end
        end

        ---@type table< number,VisitHelpTimeInfo>
        local timeInfos = visitInfo.forge_time
        ---@type table<number, UIHomeVisitSpeedupItem>
        local widgets = self.content:SpawnObjects("UIHomeVisitSpeedupItem", #items)
        local now = GetSvrTimeNow()
        for i = 1, #items do
            local data = items[i]
            local isFinish = false
            for _, value in pairs(finishedInfos) do
                if value == data.index then
                    local time = data.end_time - now
                    local info = timeInfos[data.index]
                    if info then
                        time = time - info.offline_help_time
                    end
                    if time <= 0 then
                        isFinish = true
                    end
                    break
                end
            end
            widgets[i]:SetData(data, timeInfos[data.index], true, isFinish)
        end
        self._btn:ChangeState(2)
    else
        items = {}
        ---@type table< number,VisitHelpTimeInfo>
        local timeInfos = visitInfo.forge_time
        local now = GetSvrTimeNow()
        ---@type table<number, ForgeItemInfo>
        local datas = visitInfo.forge_info.forge_list
        for _, value in ipairs(datas) do
            local time = value.end_time - now
            local info = timeInfos[value.index]
            if info then
                time = time - info.offline_help_time
            end
            --过滤掉已完成但未领取的队列
            if time > 0 then
                table.insert(items, value)
            end
        end
        ---@type table<number, UIHomeVisitSpeedupItem>
        local widgets = self.content:SpawnObjects("UIHomeVisitSpeedupItem", #items)
        for i = 1, #items do
            local data = items[i]
            widgets[i]:SetData(data, timeInfos[data.index], false)
        end
        self._btn:ChangeState(1)
    end

    self._isEmpty = #items == 0
    self._empty:SetActive(self._isEmpty)
    if self._isEmpty then
        self._btn:ChangeState(3)
    end
end
--按钮点击
function UIHomeVisitSpeedup:SpeedupOnClick(go)
    if self._isEmpty then
        return
    end
    self:StartTask(self._Speedup, self)
end
--按钮点击
function UIHomeVisitSpeedup:CloseOnClick(go)
    self:CloseDialog()
end
function UIHomeVisitSpeedup:_Speedup(TT)
    self:Lock(self:GetName())
    local res
    ---@type CEventHomelandAccForgeReply
    local reply
    res, reply = self._module:HomelandAccForgeReq(TT, self._uiModule:GetVisitInfo().pstid)
    self:UnLock(self:GetName())
    if not res:GetSucc() then
        ToastManager.ShowHomeToast(self._module:GetVisitErrorMsg(res:GetResult()))
        return
    end
    ToastManager.ShowHomeToast(StringTable.Get("str_homeland_visit_speedup_success"))
    self._uiModule:GetVisitInfo().forge_info = reply.newInfo
    self._uiModule:GetVisitInfo().forge_time = reply.forge_time
    self:_RefreshList(true, reply.help_list)
end
