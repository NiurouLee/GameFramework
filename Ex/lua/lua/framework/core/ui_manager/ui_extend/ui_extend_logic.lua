--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UI扩展逻辑，独立于UI窗口管理(如UIController)，由项目自己继承扩展
**********************************************************************************************
]]--------------------------------------------------------------------------------------------

---@class UIExtendLogic : UIBase
_class( "UIExtendLogic", UIBase )
UIExtendLogic = UIExtendLogic

--region 初始化/销毁
function UIExtendLogic:Constructor()
    Log.debug("[UIExtend] UIExtendLogic:Constructor")
end

---不可以被子类重写
---@private
function UIExtendLogic:Dispose()
    self:OnDestroy()--卸载子类
    Log.debug("[UIExtend] UIExtendLogic:Dispose")
    UIExtendLogic.super.Hide(self)--清除listener
    UIExtendLogic.super.UnLoad(self)--清除UIBase所有逻辑
    UIExtendLogic.super.Dispose(self)--Dispose UIBase
end
--endregion

--region 子类可以重写的方法
---@protected
function UIExtendLogic:OnCreate()
end

---@protected
function UIExtendLogic:OnDestroy()
end
--endregion