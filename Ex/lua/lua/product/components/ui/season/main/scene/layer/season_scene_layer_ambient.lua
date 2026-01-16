require "season_scene_layer_base"

--氛围特效层: 未解锁隐藏，解锁显示，显示过程AlphaValue从0到1过渡
---@class SeasonSceneLayerAmbient:SeasonSceneLayerBase
_class("SeasonSceneLayerAmbient", SeasonSceneLayerBase)
SeasonSceneLayerAmbient = SeasonSceneLayerAmbient

function SeasonSceneLayerAmbient:Constructor(sceneRoot)
    self._time = 1
    self._ambientLayer = self._sceneRootTransform:Find(SeasonSceneLayer.Ambient)
    ---@type table<number, UnityEngine.GameObject[]>
    self._ambientEffects = {} --氛围特效
    self:_CacheAmbientRenderer()
end

function SeasonSceneLayerAmbient:Dispose()
    SeasonSceneLayerAmbient.super.Dispose(self)
    table.clear(self._ambientEffects)
end

function SeasonSceneLayerAmbient:UnLock(zoneMask, zoneID2Animation)
    local unlockZoneIDs = SeasonTool:GetInstance():GetZonesByZoneMask(zoneMask)
    for zoneid, effects in pairs(self._ambientEffects) do
        for key, effect in pairs(effects) do
            effect:SetActive(table.icontains(unlockZoneIDs, zoneid))
        end
    end
    for zoneid, zoneRenderers in pairs(self._renderers) do
        local alpha = 0
        if table.icontains(unlockZoneIDs, zoneid) then
            alpha = 1
        end
        for key, renderer in pairs(zoneRenderers) do
            if zoneid == zoneID2Animation then
                if renderer.material then
                    renderer.material:DOFloat(alpha, "AlphaValue", self._time)
                end
            else
                if renderer.material then
                    renderer.material:SetFloat("AlphaValue", alpha)
                end
            end
        end
    end
end

function SeasonSceneLayerAmbient:_CacheAmbientRenderer()
    if self._ambientLayer then
        local zoneCount = self._ambientLayer.childCount
        if zoneCount > 0 then
            for i = 0, zoneCount - 1 do
                local zone = self._ambientLayer:GetChild(i)
                if zone then
                    local zoneid = i + 1
                    local childCount = zone.childCount
                    for j = 0, childCount - 1 do
                        local ambient = zone:GetChild(j)
                        if not self._ambientEffects[zoneid] then
                            self._ambientEffects[zoneid] = {}
                        end
                        table.insert(self._ambientEffects[zoneid], ambient.gameObject)
                        local renderers = ambient.gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
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