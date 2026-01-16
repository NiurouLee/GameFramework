_class("HomelandTree", Object)
---@class HomelandTree: Object
HomelandTree = HomelandTree

function HomelandTree:Constructor(treeID, treeGO, treeCfg, treeCuttingManager)
    ---@type number
    self._treeID = treeID
    ---@type UnityEngine.GameObject
    self._treeGO = treeGO
    ---@type table<string, number>
    self._treeCfg = treeCfg
    ---@type HomelandTreeCuttingManager
    self._treeCuttingManager = treeCuttingManager

    ---@type number
    self._dropTimes = 0
    ---@type number
    self._cutTimes = 0
    ---@type H3DTimerEvent
    self._timerEvent = nil
    ---@type UnityEngine.GameObject
    self._forbiddenIcon = nil

    ---@type number 清空砍伐次数的持续未砍伐时间(ms)
    self._clearCutTimesTime = 1000 * 60 * 30
    ---@type string
    self._forbidderIconName = "CutForbidden.prefab"
    ---@type Vector3
    self._forbiddenIconOffset = Vector3(0, 0, 0)
end

function HomelandTree:Dispose()
    if self._timerEvent then
        self._timerEvent:Cancel()
    end

    if self._forbiddenIcon then
        UIHelper.DestroyGameObject(self._forbiddenIcon)
        self._forbiddenIcon = nil
    end
end

function HomelandTree:ID()
    return self._treeID
end

function HomelandTree:GetInteractRedStatus()
    return false
end

function HomelandTree:EnterInteractScope()
    self:RefreshForbiddenIcon()
end

function HomelandTree:LeaveInteractScope()
    if self._forbiddenIcon then
        UIHelper.DestroyGameObject(self._forbiddenIcon)
        self._forbiddenIcon = nil
    end
end

function HomelandTree:RefreshForbiddenIcon()
    if self._dropTimes >= self._treeCfg.DropLimit and not self._forbiddenIcon then
        self._forbiddenIcon = UIHelper.GetGameObject(self._forbidderIconName)
        self._forbiddenIcon.transform:SetParent(self._treeGO.transform)
        self._forbiddenIcon.transform.localPosition = self._forbiddenIconOffset
    elseif self._dropTimes < self._treeCfg.DropLimit and self._forbiddenIcon then
        UIHelper.DestroyGameObject(self._forbiddenIcon)
        self._forbiddenIcon = nil
    end
end

function HomelandTree:SetDropTimes(dropTimes)
    self._dropTimes = dropTimes
    if self._forbiddenIcon then
        self:RefreshForbiddenIcon()
    end
end

function HomelandTree:IncreaseDropTimes()
    self._dropTimes = self._dropTimes + 1
    self:RefreshForbiddenIcon()
end

function HomelandTree:ResetClearTimer()
    if self._timerEvent then
        self._timerEvent:Cancel()
        self._timerEvent = nil
    end
    self._timerEvent =
        GameGlobal.Timer():AddEvent(
        self._clearCutTimesTime,
        function()
            self._cutTimes = 0
        end
    )
end

function HomelandTree:ClearCutTimes()
    self._cutTimes = 0
    if self._timerEvent then
        self._timerEvent:Cancel()
        self._timerEvent = nil
    end
end

function HomelandTree:IncreaseCutTimes()
    if self._forbiddenIcon then
        return 0
    end

    self._cutTimes = self._cutTimes + 1
    return self._cutTimes
end

function HomelandTree:GetInteractPosition(index)
    if self._interactpos == nil then
        self._interactpos = self._treeGO.transform.position
    end
    return self._interactpos
end

function HomelandTree:GetTreeRootTrans()
    return self._treeGO.transform
end

function HomelandTree:GetCutTimes()
    return self._cutTimes
end

function HomelandTree:GetCutRadius()
    return self._treeCfg.CutRadius
end

function HomelandTree:ForbiddenCut()
    return self._forbiddenIcon ~= nil
end

function HomelandTree:DoShake()
    self._treeGO.transform:DOShakePosition(0.3, Vector3(0.04, 0, 0.04), 30, 45, false, true)
end
