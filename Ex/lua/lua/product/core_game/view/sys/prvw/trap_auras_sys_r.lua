--[[------------------------------------------------------------------------------------------
    TrapAurasSystem_Render : 机关绘制光环
]] --------------------------------------------------------------------------------------------
require("reactive_system")
---@class TrapAurasSystem_Render: ReactiveSystem
_class("TrapAurasSystem_Render", ReactiveSystem)
TrapAurasSystem_Render = TrapAurasSystem_Render

function TrapAurasSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function TrapAurasSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.TrapAurasOutline)
    local c = Collector:New({group}, {"AddedOrRemoved"})
    return c
end

---@param entity Entity
function TrapAurasSystem_Render:Filter(entity)
    return entity:HasTrapRender() and entity:TrapRender():HasAurasGroupID()
end

function TrapAurasSystem_Render:ExecuteEntities()
    ----@type  Entity[]
    local entities = self._world:GetGroupEntities(self._world.BW_WEMatchers.TrapAurasOutline)
    if not entities then
        return
    end
    local groupEntityList= {}
    for i, e in ipairs(entities) do
        ---@type TrapRenderComponent
        local trapRenderComponent = e:TrapRender()
        local groupID = trapRenderComponent:GetAurasGroupID()
        if not groupEntityList[groupID] then
            groupEntityList[groupID] = {}
        end
        table.insert(groupEntityList[groupID],e)
    end
    for groupID, entityList in pairs(groupEntityList) do
        self:PlayGroupAuras(entityList)
    end
end
---@param groupEntityList Entity[]
function TrapAurasSystem_Render:PlayGroupAuras(groupEntityList)
    local totalRange = {}
    local entity2RangeList = {}
    local groupEffect,birthAnim,deadAnim,birthDelay,deadDelay,loopAnim
    local radius
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local birthEntityList ={}
    local deadEntityList ={}
    local destroyEntityList={}
    for _, entity in ipairs(groupEntityList) do
        ---@type TrapRenderComponent
        local trapRenderComponent = entity:TrapRender()
        local effect = trapRenderComponent:GetAurasEffect()
        if not groupEffect then
            groupEffect = effect
        end
        local myRadius = trapRenderComponent:GetAurasRadius()
        if not radius then
            radius = myRadius
        end
        if trapRenderComponent:GetAurasStatus() == TrapAurasState.Close
        then
            local dead = trapRenderComponent:GetAurasDeathAnim()
            local delay = trapRenderComponent:GetAurasBirthDelay()
            if not deadAnim then
                deadAnim = dead
            end
            if not deadDelay then
                deadDelay = delay
            end
            if groupEffect~= effect  or deadAnim~=dead or deadDelay ~= delay then
                Log.exception("Trap Auras Effect Invalid")
            end
            local aurasEntityList = trapRenderComponent:GetAllAurasEntity()
            for i, id in ipairs(aurasEntityList) do
                local aurasEntity = self._world:GetEntityByID(id)
                --entityPoolService:DestroyCacheEntity(aurasEntity,EntityConfigIDRender.TrapAurasArea)
                if not trapRenderComponent:IsAurasFinish() then
                    table.insert(deadEntityList,aurasEntity)
                end
            end
        elseif trapRenderComponent:GetAurasStatus() == TrapAurasState.Open then
            local birth = trapRenderComponent:GetAurasBirthAnim()
            local loop = trapRenderComponent:GetAurasLoopAnim()
            local delay = trapRenderComponent:GetAurasBirthDelay()
            if not birthAnim then
                birthAnim = birth
            end
            if not birthDelay then
                birthDelay = delay
            end
            if not loopAnim then
                loopAnim = loop
            end
            if groupEffect~= effect or birthAnim~=birth or birthDelay ~= delay
                    or loopAnim ~= loop then
                Log.exception("Trap Auras Effect Invalid")
            end
            local skillID = trapRenderComponent:GetAurasRangeSkillID()
            ---@type SkillConfigData 主动技配置数据
            local skillConfigData = configService:GetSkillConfigData(skillID)
            local casterPos = entity:GetGridPosition()
            local scapeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, entity)
            local range  =scapeResult:GetAttackRange()
            for i, pos in ipairs(range) do
                if not table.Vector2Include(totalRange,pos) then
                    table.insert(totalRange,pos)
                end
            end
            entity2RangeList[entity:GetID()] = range
            local aurasEntityList = trapRenderComponent:GetAllAurasEntity()
            for i, id in ipairs(aurasEntityList) do
                local aurasEntity = self._world:GetEntityByID(id)
                --entityPoolService:DestroyCacheEntity(aurasEntity,EntityConfigIDRender.TrapAurasArea)
                table.insert(destroyEntityList,aurasEntity)
            end
        end
        trapRenderComponent:ClearAurasEntity()
    end
    GameGlobal.TaskManager():StartTask(self.PlayDead,self,deadEntityList,deadAnim,deadDelay)
    ---@type RenderEntityService
    local renderEntitySvcR = self._world:GetService("RenderEntity")
    ---@type Entity[]
    local outlineEntityList =renderEntitySvcR:CreateAreaOutlineEntity(totalRange,EntityConfigIDRender.TrapAurasArea,groupEffect,nil,nil,radius)
    for i, aurasEntity in ipairs(destroyEntityList) do
        entityPoolService:DestroyCacheEntity(aurasEntity,EntityConfigIDRender.TrapAurasArea)
    end
    for i, outlineEntity in ipairs(outlineEntityList) do
        local sourcePos = renderEntitySvcR:GetOutlineSourcePos(outlineEntity,radius)
        for entityID, range in pairs(entity2RangeList) do
            if table.Vector2Include(range,sourcePos) then
                ---@type Entity
                local entity = self._world:GetEntityByID(entityID)
                ---@type TrapRenderComponent
                local trapRenderComponent = entity:TrapRender()
                trapRenderComponent:AddMyAurasEntity(outlineEntity:GetID())
                if trapRenderComponent:GetAurasStatus() == TrapAurasState.Open and not trapRenderComponent:IsAurasFinish() then
                    table.insert(birthEntityList,outlineEntity)
                end
                goto Continue
            end
        end
        ::Continue::
    end
    ---这里设置全部播放完毕
    for _, entity in ipairs(groupEntityList) do
        ---@type TrapRenderComponent
        local trapRenderComponent = entity:TrapRender()
        trapRenderComponent:SetAurasFinish()
    end
    GameGlobal.TaskManager():StartTask(self.PlayBirth,self,birthEntityList,birthAnim,birthDelay,loopAnim)

end

---@param entityList Entity[]
function TrapAurasSystem_Render:PlayBirth(TT, entityList, birthAnim, delay, loopAnim)
    if not entityList or  #entityList ==0 or not birthAnim then
        return
    end
    ---@type RenderBattleService
    local renderBattle = self._world:GetService("RenderBattle")
    for i, entity in ipairs(entityList) do
        renderBattle:PlayAnimation(entity, { birthAnim })
    end
    YIELD(TT, delay)
    for i, entity in ipairs(entityList) do
        renderBattle:PlayAnimation(entity, { loopAnim })
    end
end

---@param entityList Entity[]
function TrapAurasSystem_Render:PlayDead(TT, entityList, deadAnim, deadDelay)
    if not entityList or  #entityList ==0 then
        return
    end
    ---@type RenderBattleService
    local renderBattle = self._world:GetService("RenderBattle")
    if  deadAnim then
        for i, entity in ipairs(entityList) do
            renderBattle:PlayAnimation(entity, { deadAnim })
        end
    end
    if deadDelay then
        YIELD(TT, deadDelay)
    end
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    for i, entity in ipairs(entityList) do
        entityPoolService:DestroyCacheEntity(entity,EntityConfigIDRender.TrapAurasArea)
    end
end
