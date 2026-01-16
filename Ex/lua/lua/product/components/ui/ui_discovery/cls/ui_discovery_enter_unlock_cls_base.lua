--大地图功能入口数据类，一般情况下一个入口对应一个功能模块，番外特殊
---@class UIDiscoveryEnterUnlockClsBase:Object
_class("UIDiscoveryEnterUnlockClsBase", Object)
UIDiscoveryEnterUnlockClsBase = UIDiscoveryEnterUnlockClsBase

function UIDiscoveryEnterUnlockClsBase:Constructor(moduleID, go, tex, img)
    self._moduleId = moduleID
    self._roleModule = GameGlobal.GetModule(RoleModule)
    self._go = go
    self._tex = tex
    self._img = img
end

--是否已解锁
function UIDiscoveryEnterUnlockClsBase:IsUnlock()
    return self._roleModule:CheckModuleUnlock(self._moduleId)
end

function UIDiscoveryEnterUnlockClsBase:GameObject()
    return self._go
end

function UIDiscoveryEnterUnlockClsBase:Text()
    return self._tex
end

function UIDiscoveryEnterUnlockClsBase:Image()
    return self._img
end
