--[[------------------------------------------------------------------------------------------
    EntityPoolServiceRender 在有些情况下，创建Entity也很耗，需要缓存Entity
]] --------------------------------------------------------------------------------------------
require("base_service")

_class("EntityPoolServiceRender", BaseService)
---@class EntityPoolServiceRender:BaseService
EntityPoolServiceRender = EntityPoolServiceRender

function EntityPoolServiceRender:Constructor(world)
    self._world = world
    ---entity缓存配置，key是EntityConfigIDConst，value是缓存数量
    self._entityCacheConfig = {}
    self._entityCacheConfig[EntityConfigIDRender.SkillRangeOutline] = 10
    self._entityCacheConfig[EntityConfigIDRender.MonsterAreaOutLine] = 10
    self._entityCacheConfig[EntityConfigIDRender.LinkNum_Any] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkNum_Red] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkNum_Green] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkNum_Blue] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkNum_Yellow] = 5

    self._entityCacheConfig[EntityConfigIDRender.LinkGridDot_Any] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkGridDot_Red] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkGridDot_Green] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkGridDot_Blue] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkGridDot_Yellow] = 5

    self._entityCacheConfig[EntityConfigIDRender.LinkLine_Any] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkLine_Red] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkLine_Green] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkLine_Blue] = 5
    self._entityCacheConfig[EntityConfigIDRender.LinkLine_Yellow] = 5

    self._entityCacheConfig[EntityConfigIDRender.MoveRange] = 5
    self._entityCacheConfig[EntityConfigIDRender.MoveRangePro] = 5
    self._entityCacheConfig[EntityConfigIDRender.MoveRangeArrow] = 5
    self._entityCacheConfig[EntityConfigIDRender.MoveRangeGrid] = 5
    self._entityCacheConfig[EntityConfigIDRender.WarningArea] = 5
    self._entityCacheConfig[EntityConfigIDRender.DeathArea] = 5
    self._entityCacheConfig[EntityConfigIDRender.WaringDeathArea] = 1
    self._entityCacheConfig[EntityConfigIDRender.TrapAurasArea] = 1

    self._entityCacheConfig[EntityConfigIDRender.TrapAreaOutline] = 10
    ---包含LineRender组件的要设置点
    self._lineRenderEntityList = {
        EntityConfigIDRender.LinkLine_Any,
        EntityConfigIDRender.LinkLine_Yellow,
        EntityConfigIDRender.LinkLine_Blue,
        EntityConfigIDRender.LinkLine_Green,
        EntityConfigIDRender.LinkLine_Red
    }

    ---entity缓存池，key是EntityConfigIDConst，value是一个Array，元素是Entity
    self._entityCacheTable = {}
end

---按照配置缓存Entity
function EntityPoolServiceRender:CacheEntities()
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    for cacheID, cahceNum in pairs(self._entityCacheConfig) do
            for cacheIndex = 1, cahceNum do
                local cacheEntity = self:_CreateCahceEntity(cacheID)
                local cacheList = self._entityCacheTable[cacheID]
                if cacheList == nil then
                    cacheList = {}
                    self._entityCacheTable[cacheID] = cacheList
                end
                if table.icontains(self._lineRenderEntityList, cacheID) then
                    linkageRenderService:ResetLinkLineEntity(cacheEntity)
                end
                cacheList[#cacheList + 1] = cacheEntity
            end

    end
end

function EntityPoolServiceRender:HideCacheEntities()
    for _, entityList in pairs(self._entityCacheTable) do
        for _, entity in pairs(entityList) do
            ---@type ViewComponent
            local viewCmpt = entity:View()
            if viewCmpt ~= nil then
                --viewCmpt:GetGameObject():SetActive(true)
                viewCmpt:GetGameObject().transform.position = Vector3(0, BattleConst.CacheHeight, 0)
            --entity:SetLocationHeight((BattleConst.CacheHeight))
            end
        end
    end
end

---@param cacheID EntityConfigIDConst
function EntityPoolServiceRender:_CreateCahceEntity(cacheID)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    local cacheEntity = sEntity:CreateRenderEntity(cacheID)
    cacheEntity:SetViewVisible(true)
    return cacheEntity
end

function EntityPoolServiceRender:GetCacheEntityCountByID(cacheID)
    local entityList = self._entityCacheTable[cacheID]
    if entityList == nil then
        Log.notice("has not cache entity,which config id is:", cacheID)
        return nil
    end
    local curCount = #entityList
    --Log.notice("CacheCount:",curCount,"CacheID:",cacheID)
    return curCount
end

---@param cacheID EntityConfigIDConst
---@return Entity 缓存的Entity对象
function EntityPoolServiceRender:GetCacheEntityByConfigID(cacheID)
    local entityList = self._entityCacheTable[cacheID]
    if entityList == nil then
        Log.fatal("has not cache entity,which config id is:", cacheID)
        return nil
    end

    local curCount = #entityList
    if curCount <= 0 then
        ---如果缓存的entity数量小于0，需要创建一个，并返回
        local cacheEntity = self:_CreateCahceEntity(cacheID)
        return cacheEntity
    end

    ---总是取队列中的第一个Entity
    local cacheIndex = 1
    local curEntity = entityList[cacheIndex]
    table.remove(entityList, cacheIndex)

    return curEntity
end

---删除缓存的Entity
---@param cacheEntity Entity 待删除的缓存Entity
---@param entityConfigID EntityConfigIDConst entity模板的类型
function EntityPoolServiceRender:DestroyCacheEntity(cacheEntity, entityConfigID)
    local entityList = self._entityCacheTable[entityConfigID]
    if entityList == nil then
        Log.fatal("DestroyCacheEntity,has not cache entity,which config id is:", entityConfigID)
        return nil
    end

    self:_HideCacheEntity(cacheEntity)

    entityList[#entityList + 1] = cacheEntity
end

---这里只是挪了下位置
---@param cacheEntity Entity
function EntityPoolServiceRender:_HideCacheEntity(cacheEntity)
    ---@type ViewComponent
    local viewCmpt = cacheEntity:View()
    if viewCmpt == nil then
        Log.fatal("cache entity has no view")
        return
    end

    local gameObj = viewCmpt:GetGameObject()
    local curPos = gameObj.transform.position

    gameObj.transform.position = Vector3(curPos.x, BattleConst.CacheHeight, curPos.z)
    cacheEntity:SetLocationHeight((BattleConst.CacheHeight))
    local lineRender = gameObj:GetComponent("LineRenderer")
    if lineRender == nil then
        lineRender = gameObj:GetComponentInChildren(typeof(UnityEngine.LineRenderer))
        if lineRender then
            lineRender.positionCount = 2
            local pos = Vector3(0, 1000, 0)
            lineRender:SetPosition(0, pos)
            lineRender:SetPosition(1, pos)
        end
    end
    --Log.fatal("HideEntity:",cacheEntity:GetID(),"Pos", tostring(cacheEntity:GetRenderGridPosition()))
end
