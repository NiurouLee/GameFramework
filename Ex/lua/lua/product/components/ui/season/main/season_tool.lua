
---@class SeasonTool:Singleton
_class("SeasonTool", Singleton)
SeasonTool = SeasonTool

function SeasonTool:Constructor()
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    self._loginModule = GameGlobal.GetModule(LoginModule)
    self._id_position = UnityEngine.Shader.PropertyToID("_PlaneShadowPosition")
    self._id_normal = UnityEngine.Shader.PropertyToID("_PlaneShadowNormal")
end

---根据zoneMask计算UnlockMap shader的遮罩参数
---@return Vector4
function SeasonTool:GetV4ByZoneMask(zoneMask, zoneID2Animation)
    if not zoneMask then
        return Vector4.zero
    end
    local v4 = Vector4((zoneMask >> 2) & 1, zoneMask & 1, (zoneMask >> 1) & 1, 0)
    if zoneID2Animation then
        if zoneID2Animation == SeasonZone.One then
            v4.y= 0
        elseif zoneID2Animation == SeasonZone.Two then
            v4.z = 0
        elseif zoneID2Animation == SeasonZone.Three then
            v4.x = 0
        end
    end
    return v4
end

---根据zoneMask计算当前解锁的区域
---@return table
function SeasonTool:GetZonesByZoneMask(zoneMask)
    local zone = {}
    if zoneMask & 1 == 1 then
        table.insert(zone, SeasonZone.One)
    end
    if (zoneMask >> 1) & 1 == 1 then
        table.insert(zone, SeasonZone.Two)
    end
    if (zoneMask >> 2) & 1 == 1 then
        table.insert(zone, SeasonZone.Three)
    end
    return zone
end

---@param shadowPlane UnityEngine.Transform
---@param renderers UnityEngine.Renderer[]
function SeasonTool:SetMaterialProperty(shadowPlane, renderers, materialPropertyBlock)
    if shadowPlane ~= nil and materialPropertyBlock then
        local v4_position = Vector4(shadowPlane.position.x, shadowPlane.position.y, shadowPlane.position.z, 0)
        local v4_normal = Vector4(shadowPlane.up.normalized.x, shadowPlane.up.normalized.y, shadowPlane.up.normalized.z, 0)
        if renderers.Length > 0 then
            for i = 0, renderers.Length - 1 do
                ---@type UnityEngine.Renderer
                local render = renderers[i]
                if render.materials.Length > 0 then
                    for j = 0, render.materials.Length - 1 do
                        materialPropertyBlock:Clear()
                        render:GetPropertyBlock(materialPropertyBlock, j)
                        materialPropertyBlock:SetVector(self._id_position, v4_position)
                        materialPropertyBlock:SetVector(self._id_normal, v4_normal)
                        render:SetPropertyBlock(materialPropertyBlock,j)
                    end
                end
            end
        end
    end
end

---@param gameObject UnityEngine.GameObject
function SeasonTool:DisenableMeshRender(gameObject)
    if gameObject then
        local shadowRenderers = gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
        if shadowRenderers.Length > 0 then
            for i = 0, shadowRenderers.Length - 1 do
                ---@type UnityEngine.Renderer
                local render = shadowRenderers[i]
                render.enabled = false
            end
        end
    end
end

--根据指定的表现类型获取第一个包含该表现的进度
---@param cfg cfg_season_map_eventpoint
---@param expressType SeasonExpressType
function SeasonTool:GetProgressByExpressType(cfg, expressType)
    local check = function (expresses)
        if expresses then
            for _, id in pairs(expresses) do
                local cfgExpress = Cfg.cfg_season_map_express[id]
                if cfgExpress and cfgExpress.ExpressType == expressType then
                    return true
                end
            end
        end
        return false
    end
    if check(cfg.Express1) then
        return SeasonEventPointProgress.SEPP_Show
    end
    if check(cfg.Express2) then
        return SeasonEventPointProgress.SEPP_Interaction
    end
    if check(cfg.Express3) then
        return SeasonEventPointProgress.SEPP_Finish
    end
    return nil
end

function SeasonTool:SetLocalDBFloat(key, value)
    LocalDB.SetFloat(self._loginModule:GetRoleShowID()..key, value)
end

function SeasonTool:GetLocalDBFloat(key, defaultValue)
    return LocalDB.GetFloat(self._loginModule:GetRoleShowID()..key, defaultValue)
end