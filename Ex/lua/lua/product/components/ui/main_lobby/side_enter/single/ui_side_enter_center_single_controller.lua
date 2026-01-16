---@class UISideEnterCenterSingleController : UIController
_class("UISideEnterCenterSingleController", UIController)
UISideEnterCenterSingleController = UISideEnterCenterSingleController

--- 用来为 Side Enter Center 活动中心中加载的活动内容Content 独立显示的窗口
function UISideEnterCenterSingleController:LoadDataOnEnter(TT, res, uiParams)
    local id = uiParams and uiParams[1] or 0
    Log.info("UISideEnterCenterSingleController:LoadDataOnEnter() id = ", id)

    local class, prefab = UISideEnterConst.GetCfg_SideEnterContent_Info(id, ESideEnterContentType.Single) -- Single 模式

    if string.isnullorempty(class) or string.isnullorempty(prefab) then
        res:SetSucc(false)
        return
    end

    local obj = UIWidgetHelper.SpawnObject(self, '_pool', class, prefab)
    obj:OnInit(ESideEnterContentType.Single,  -- 设置成 Single 模式
        function()
            self:CloseDialog()
        end
    )

    -- 响应通用的活动关闭事件
    self._campaign = obj._campaign
end

function UISideEnterCenterSingleController:OnShow(uiParams)
    self:AddListener()
end

function UISideEnterCenterSingleController:OnHide()
    self:DetachListener()
end

function UISideEnterCenterSingleController:AddListener()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
end

function UISideEnterCenterSingleController:DetachListener()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
end

function UISideEnterCenterSingleController:OnActivityCloseEvent(id)
    if self._campaign and self._campaign._id == id then
       self:CloseDialog()
    end
end
