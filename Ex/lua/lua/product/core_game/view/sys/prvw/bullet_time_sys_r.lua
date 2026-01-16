--[[------------------------------------------------------------------------------------------
    BulletTimeSystem : 用于处理划线时的子弹时间
]] --------------------------------------------------------------------------------------------
require("reactive_system")
---@class BulletTimeSystem: ReactiveSystem
_class("BulletTimeSystem", ReactiveSystem)
BulletTimeSystem = BulletTimeSystem

function BulletTimeSystem:Constructor(world)
    self._world = world
end

function BulletTimeSystem:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.BulletTime)
    local c = Collector:New({group}, {"Added"})
    return c
end

---@param entity Entity
function BulletTimeSystem:Filter(entity)
    return entity:HasBulletTime()
end

function BulletTimeSystem:ExecuteEntities(entities)
    for i = 1, #entities do
        local e = entities[i]
        self:HandleEntity(e)
    end
end

---@param e Entity
function BulletTimeSystem:HandleEntity(e)
    ---@type BulletTimeComponent
    local bulletTimeCmpt = e:BulletTime()
    local enableBulletTime = bulletTimeCmpt:IsEnableBullteTime()
    if enableBulletTime then
        self:_EnalbeEntityBulletTime(e)
    else
        self:_DisableEntityBulletTime(e)
    end
end

---@param e Entity
function BulletTimeSystem:_EnalbeEntityBulletTime(e)
    ---@type BulletTimeComponent
    local bulletTimeCmpt = e:BulletTime()

    self._world:MainCamera():EnableSceneTiltShift(true)

    ---修改怪物的特效速度
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, entity in ipairs(monsterGroup:GetEntities()) do
        bulletTimeCmpt:AddBulletTimeEntityID(entity:GetID())
        self:_ModifyEntityFadeSpeed(entity, BattleConst.BulletTimeSpeed)
    end

    ---修改机关的特效速度
    ---@type TrapServiceRender
    local trapRenderSvc = self._world:GetService("TrapRender")
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for _, entity in ipairs(trapGroup:GetEntities()) do
        if not trapRenderSvc:IsRuneTrap(entity) then
            bulletTimeCmpt:AddBulletTimeEntityID(entity:GetID())
            self:_ModifyEntityFadeSpeed(entity, BattleConst.BulletTimeSpeed)
        end
    end

    ---修改主角的子弹时间
    local teamGroup = self._world:GetGroup(self._world.BW_WEMatchers.Team)
    for _, entity in ipairs(teamGroup:GetEntities()) do
        bulletTimeCmpt:AddBulletTimeEntityID(entity:GetID())
        self:_ModifyEntityFadeSpeed(entity, BattleConst.BulletTimeSpeed)
    end
end

---@param entity Entity
function BulletTimeSystem:_ModifyEntityFadeSpeed(entity, speed)
    ---@type ViewComponent
    local viewCmpt = entity:View()
    if not viewCmpt then
        return
    end

    ---@type UnityEngine.GameObject
    local u3dObj = viewCmpt:GetGameObject()
    if not u3dObj then
        return
    end

    ---@type FadeComponent
    local fadeCmpt = u3dObj:GetComponent(typeof(FadeComponent))
    if not fadeCmpt then
        return
    end

    fadeCmpt.Speed = speed
end

---@param e Entity
function BulletTimeSystem:_DisableEntityBulletTime(e)
    local normalSpeed = 1
    ---@type BulletTimeComponent
    local bulletTimeCmpt = e:BulletTime()
    local idList = bulletTimeCmpt:GetBulletTimeEntityIDList()
    for _, id in ipairs(idList) do
        ---@type Entity
        local entity = self._world:GetEntityByID(id)
        self:_ModifyEntityFadeSpeed(entity, normalSpeed)
    end

    bulletTimeCmpt:ResetBulletTimeData()

    self._world:MainCamera():EnableSceneTiltShift(false)
end
