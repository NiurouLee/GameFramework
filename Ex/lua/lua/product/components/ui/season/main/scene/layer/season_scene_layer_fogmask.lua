--迷雾遮罩层:未解锁显示，解锁之后AlphaValue从1到0消失
---@class SeasonSceneLayerFogMask:SeasonSceneLayerBase
_class("SeasonSceneLayerFogMask", SeasonSceneLayerBase)
SeasonSceneLayerFogMask = SeasonSceneLayerFogMask

function SeasonSceneLayerFogMask:Constructor(sceneRoot)
    ---@type UnityEngine.Transform
    self._fogMaskLayer = self._sceneRootTransform:Find(SeasonSceneLayer.FogMask)
    self._time = 1
    ---@type table<number, UnityEngine.GameObject[]>
    self._fogEffects = {} --迷雾效果
    self:_CacheHighBuildingRenderer()
end

function SeasonSceneLayerFogMask:Dispose()
    SeasonSceneLayerFogMask.super.Dispose(self)
    if self._hideTask then
        GameGlobal.TaskManager():KillTask(self._hideTask)
        self._hideTask = nil
    end
    table.clear(self._fogEffects)
end

function SeasonSceneLayerFogMask:UnLock(zoneMask, zoneID2Animation)
    local unlockZoneIDs = SeasonTool:GetInstance():GetZonesByZoneMask(zoneMask)
    for zoneid, effects in pairs(self._fogEffects) do
        if zoneid ~= zoneID2Animation then
            for key, effect in pairs(effects) do
                effect:SetActive(not table.icontains(unlockZoneIDs, zoneid))
            end
        end
    end
    for zoneid, zoneRenderers in pairs(self._renderers) do
        local alpha = 1
        if table.icontains(unlockZoneIDs, zoneid) then
            alpha = 0
        end
        for key, renderer in pairs(zoneRenderers) do
            if zoneid == zoneID2Animation then
                if renderer.material then
                    renderer.material:DOFloat(alpha, "AlphaValue", self._time)
                end
                self:HideEffect(zoneid)
            else
                if renderer.material then
                    renderer.material:SetFloat("AlphaValue", alpha)
                end
            end
        end
    end
end

---缓存迷雾遮罩的MeshRender
function SeasonSceneLayerFogMask:_CacheHighBuildingRenderer()
    if self._fogMaskLayer then
        local zoneCount = self._fogMaskLayer.childCount
        if zoneCount > 0 then
            for i = 0, zoneCount - 1 do
                local zone = self._fogMaskLayer:GetChild(i)
                if zone then
                    local zoneid = i + 1
                    local childCount = zone.childCount
                    for j = 0, childCount - 1 do
                        local fogMask = zone:GetChild(j)
                        if not self._fogEffects[zoneid] then
                            self._fogEffects[zoneid] = {}
                        end
                        table.insert(self._fogEffects[zoneid], fogMask.gameObject)
                        local renderers = fogMask.gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
                        if renderers.Length > 0 then
                            for k = 0, renderers.Length - 1 do
                                self:InsertMeshRender(zoneid, renderers[k])
                            end
                        end
                    end
                end
            end
        end
    end
end

function SeasonSceneLayerFogMask:HideEffect(zoneid)
    self._hideTask = GameGlobal.TaskManager():StartTask(function (TT)
        YIELD(TT, self._time * 1000)
        local effects = self._fogEffects[zoneid]
        if effects then
            for _, effect in pairs(effects) do
                effect:SetActive(false)
            end
        end
    end)
end