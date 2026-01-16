---@class SeasonSceneEnvironment:Object
_class("SeasonSceneEnvironment", Object)
SeasonSceneEnvironment = SeasonSceneEnvironment

function SeasonSceneEnvironment:Constructor(sceenRoot)
    ---@type UnityEngine.GameObject
    self._sceenRoot = sceenRoot
    ---@type SeasonSceneEnvironmentBase[]
    self._animals = {}
    self._animals[1] = SeasonSceneGiantLizard:New(sceenRoot)
    self._animals[2] = SeasonSceneSmallLizard:New(sceenRoot, 1)
    self._animals[3] = SeasonSceneSmallLizard:New(sceenRoot, 2)
end

function SeasonSceneEnvironment:Update(deltaTime)
    for _, animal in pairs(self._animals) do
        animal:Update(deltaTime)
    end
end

function SeasonSceneEnvironment:Dispose()
    for _, animal in pairs(self._animals) do
        animal:Dispose()
    end
end

--解锁某个区的时候场景上的表现
---@param zoneMask number
---@param zoneID2Animation number
function SeasonSceneEnvironment:UnLockZone(zoneMask, zoneID2Animation)
    local unlockZoneIDs = SeasonTool:GetInstance():GetZonesByZoneMask(zoneMask)
    if table.icontains(unlockZoneIDs, SeasonZone.Two)  then
        self._animals[1]:UnLock(true)
    end
end