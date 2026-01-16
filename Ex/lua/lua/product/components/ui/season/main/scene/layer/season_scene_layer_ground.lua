--地表块，处理战争迷雾
---@class SeasonSceneLayerGround:SeasonSceneLayerBase
_class("SeasonSceneLayerGround", SeasonSceneLayerBase)
SeasonSceneLayerGround = SeasonSceneLayerGround

function SeasonSceneLayerGround:Constructor(sceneRoot)
    self._time = 1
    self._mapTime = 3
    self._zoneMask = nil
    self._groundLayer = self._sceneRootTransform:Find(SeasonSceneLayer.Ground)
    self:_CacheGroundMap()
end

function SeasonSceneLayerGround:Dispose()
    SeasonSceneLayerGround.super.Dispose(self)
    if self._tweenTask then
        GameGlobal.TaskManager():KillTask(self._tweenTask)
        self._tweenTask = nil
    end
    if self._showTask then
        GameGlobal.TaskManager():KillTask(self._showTask)
        self._showTask = nil
    end
    table.clear(self._map)
end

function SeasonSceneLayerGround:UnLock(zoneMask, zoneID2Animation)
    local v4 = SeasonTool:GetInstance():GetV4ByZoneMask(zoneMask, zoneID2Animation)
    for _, renderer in pairs(self._renderers) do
        if renderer then
            if renderer.material then
                if renderer.material:HasProperty("_AreaUnlockMask") then
                    renderer.material:SetVector("_AreaUnlockMask", v4)
                end
                if renderer.material:HasProperty("_AreaUnlockMask1") then
                    renderer.material:SetVector("_AreaUnlockMask1", v4)
                end
            end
        end
    end
    self._zoneMask = zoneMask
    self:TweenV4()
end

function SeasonSceneLayerGround:ChangeMap(ids, openingID, closeID)
    local mapCount = table.count(self._map)
    if mapCount > 0 then
        for i = 1, mapCount do
            local show = table.icontains(ids, i)
            if openingID then
                if i == openingID then
                    self:OpenMapAlpha(self._map[openingID])
                else
                    self._map[i]:SetActive(show)
                end
            else
                self._map[i]:SetActive(show)
                if show then
                    local renderers = self._map[i].gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
                    if renderers.Length > 0 then
                        for i = 0, renderers.Length - 1 do
                            if renderers[i].material:HasProperty("_AlphaValue") then
                                renderers[i].material:SetFloat("_AlphaValue", 1)
                            end
                        end
                    end
                end
            end
        end
    end
end

---缓存地表层的MeshRender
function SeasonSceneLayerGround:_CacheGroundMap()
    if self._groundLayer then
        local mapCount = self._groundLayer.childCount
        if mapCount > 0 then
            for i = 1, self._maxMapCount do
                local map = self._groundLayer:Find(tostring(i))
                if map then
                    self._map[i] = map.gameObject
                    local pieceCount = map.childCount
                    if pieceCount > 0 then
                        for j = 0, pieceCount - 1 do
                            local piece = map:GetChild(j)
                            if piece then                                
                                local pieceRenderer = piece.gameObject:GetComponent(typeof(UnityEngine.Renderer))
                                if pieceRenderer then
                                    table.insert(self._renderers, pieceRenderer)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function SeasonSceneLayerGround:TweenV4()
    self._tweenTask = GameGlobal.TaskManager():StartTask(function (TT)
        YIELD(TT)
        local v4 = SeasonTool:GetInstance():GetV4ByZoneMask(self._zoneMask)
        for _, renderer in pairs(self._renderers) do
            if renderer then
                if renderer.material then
                    if renderer.material:HasProperty("_AreaUnlockMask") then
                        renderer.material:DOVector(v4, "_AreaUnlockMask", self._time)
                    end
                    if renderer.material:HasProperty("_AreaUnlockMask1") then
                        renderer.material:DOVector(v4, "_AreaUnlockMask1", self._time)
                    end
                end
            end
        end
    end)
end

---@param map UnityEngine.GameObject
function SeasonSceneLayerGround:OpenMapAlpha(map)
    self._showTask = GameGlobal.TaskManager():StartTask(function (TT)
        YIELD(TT, 500)
        map:SetActive(true)
        local renderers = map.gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
        if renderers.Length > 0 then
            local v4 = SeasonTool:GetInstance():GetV4ByZoneMask(self._zoneMask)
            for i = 0, renderers.Length - 1 do
                if renderers[i].material:HasProperty("_AreaUnlockMask1") then
                    renderers[i].material:SetVector("_AreaUnlockMask1", v4)
                end
                if renderers[i].material:HasProperty("_AlphaValue") then
                    renderers[i].material:SetFloat("_AlphaValue", 0)
                    renderers[i].material:DOFloat(1, "_AlphaValue", self._mapTime)
                end
            end
        end
    end)
end