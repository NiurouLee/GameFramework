--大地图功能入口数据类，一般情况下一个入口对应一个功能模块，番外特殊
---@class UIDiscoveryEnterUnlockClsExtra:UIDiscoveryEnterUnlockClsBase
_class("UIDiscoveryEnterUnlockClsExtra", UIDiscoveryEnterUnlockClsBase)
UIDiscoveryEnterUnlockClsExtra = UIDiscoveryEnterUnlockClsExtra

function UIDiscoveryEnterUnlockClsExtra:Constructor(moduleID, go, tex, img)
end

--是否已解锁
function UIDiscoveryEnterUnlockClsExtra:IsUnlock()
    return self._roleModule:CheckModuleUnlock(GameModuleID.MD_ExtMission) or
        self._roleModule:CheckModuleUnlock(GameModuleID.MD_CAMPAIGNREVIEW)
end
