--
---@class UIForgeOneKeyUnlock : UIController
_class("UIForgeOneKeyUnlock", UIController)
UIForgeOneKeyUnlock = UIForgeOneKeyUnlock
--初始化
function UIForgeOneKeyUnlock:OnShow(uiParams)
    self:InitWidget()

    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetForgeData()
    self._items = self.data:GetAllUnlockableItem()
    table.sort(
        self._items,
        function(a, b)
            local colora = Cfg.cfg_item[a.id].Color
            local colorb = Cfg.cfg_item[b.id].Color
            if colora ~= colorb then
                return colora > colorb
            end
            return a.id < b.id
        end
    )
    ---@type UIItemHomeland[]
    local widgets = self.content:SpawnObjects("UIItemHomeland", #self._items)
    for i = 1, #self._items do
        local asset = RoleAsset:New()
        asset.assetid = self._items[i].id
        asset.count = 1
        widgets[i]:Flush(asset)
    end

    UIHelper.RefreshLayout(self.contentRect)
    self.scroll.horizontalNormalizedPosition = 0
end
--获取ui组件
function UIForgeOneKeyUnlock:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    --generated end--
    self.contentRect = self:GetUIComponent("RectTransform", "Content")
    self.scroll = self:GetUIComponent("ScrollRect", "ScrollView")
end
--按钮点击
function UIForgeOneKeyUnlock:CancelBtnOnClick(go)
    self:CloseDialog()
end
--按钮点击
function UIForgeOneKeyUnlock:ConfirmBtnOnClick(go)
    self:StartTask(self._Req, self)
end
--按钮点击
function UIForgeOneKeyUnlock:CloseOnClick(go)
    self:CloseDialog()
end

function UIForgeOneKeyUnlock:_Req(TT)
    local ids = {}
    for _, item in ipairs(self._items) do
        ids[#ids + 1] = item.id
    end
    Log.notice("一键解锁:", table.concat(ids, ","))
    self:Lock(self:GetName())
    local res, _ = self.mHomeland:HandleOneClickUnlock(TT, ids)
    self:UnLock(self:GetName())
    if not res:GetSucc() then
        --不处理错误码
        return
    end
    local oldSort = self.data.tSort
    self.data:Init(self.mHomeland:GetHomelandInfo()) --重新初始化数据
    self.data.tSort = oldSort
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandForgeUpdateList)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshInteractUI) --刷新交互按钮红点
    self:CloseDialog()
    ToastManager.ShowHomeToast(StringTable.Get("str_homeland_forge_unlock_once_success"))
end
