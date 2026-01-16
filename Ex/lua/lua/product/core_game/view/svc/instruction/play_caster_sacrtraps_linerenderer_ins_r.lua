require("base_ins_r")
---@class PlayCasterSacrificeTrapsLineRendererInstruction: BaseInstruction
_class("PlayCasterSacrificeTrapsLineRendererInstruction", BaseInstruction)
PlayCasterSacrificeTrapsLineRendererInstruction = PlayCasterSacrificeTrapsLineRendererInstruction

function PlayCasterSacrificeTrapsLineRendererInstruction:Constructor(paramList)
    self._casterEffectID = tonumber(paramList["casterEffectID"])
    self._lineCasterBindPos = paramList["lineCasterBindPos"]
    self._lineEffectID = tonumber(paramList["lineEffectID"])
    self._lineEffectWaitTime = tonumber(paramList["lineEffectWaitTime"])
    self._gridBindPos =  paramList["gridBindPos"] or "spot"
    self._gridEffectID = tonumber(paramList["gridEffectID"])
    self._gridEffectWaitTime  = tonumber(paramList["gridEffectWaitTime"])
    self._lineDuration = paramList["lineDuration"]
end

function PlayCasterSacrificeTrapsLineRendererInstruction:GetCacheResource()
    local t = {}
    if self._casterEffectID and self._casterEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._casterEffectID].ResPath, 1 })
    end
    if self._lineEffectID and self._lineEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._lineEffectID].ResPath, 1 })
    end
    if self._gridEffectID and self._gridEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._gridEffectID].ResPath, 1 })
    end
    return t
end
---@param casterEntity Entity
function PlayCasterSacrificeTrapsLineRendererInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    self._casterEntity = casterEntity
    self._world = world
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type Entity
    local casterEffectEntity = effectService:CreateEffect(self._casterEffectID,casterEntity)
    --连线点 施法者特效身上的绑点
    local targetRoot = GameObjectHelper.FindChild(casterEffectEntity:View().ViewWrapper.GameObject.transform, self._lineCasterBindPos)

    if not targetRoot then
        return
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultSacrificeTraps[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SacrificeTraps)
    if not results then
        results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.PetSacrificeSuperGridTraps)--光灵米洛斯 表现复用
    end
    ---@type SkillEffectResultSacrificeTraps
    local result = results[1]
    if not result then
        Log.fatal("11111111111")
    end
    local trapIDs = result:GetTrapIDs()
    local taskIDList ={}
    local extraGrids = nil
    if result.GetExtraGrids then--光灵米洛斯 --点击的地方没有强化格子也要播表现
        extraGrids = result:GetExtraGrids()
    end
    local taskID = TaskManager:GetInstance():CoreGameStartTask(self.PlayGridEffectAtTraps,self,trapIDs,extraGrids)
    table.insert(taskIDList,taskID)
    taskID = TaskManager:GetInstance():CoreGameStartTask(self.PlayLineEffect,self,trapIDs,targetRoot,extraGrids)
    table.insert(taskIDList,taskID)
    while not TaskHelper:GetInstance():IsAllTaskFinished(self.taskIDList) do
        YIELD(TT)
    end
end

function PlayCasterSacrificeTrapsLineRendererInstruction:PlayLineEffect(TT,trapIDs,targetRoot,extraGrids)
    YIELD(TT,self._lineEffectWaitTime)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    local tarPosList = {}
    for i, id in ipairs(trapIDs) do
        ---@type Entity
        local trapEntity = self._world:GetEntityByID(id)
        ---@type Vector2
        local trapPos = trapEntity:GetRenderGridPosition()
        table.insert(tarPosList,trapPos)
    end
    if extraGrids then
        for index, pos in ipairs(extraGrids) do
            table.insert(tarPosList,pos)
        end
    end
    for i, gridPos in ipairs(tarPosList) do
        ---@type Vector2
        local trapPos = gridPos
        ---@type Entity
        local pieceEntity = pieceSvc:FindPieceEntity(trapPos)
        local linkLineEntity =self._gridEffectEntityList[i]
        ---@type EffectLineRendererComponent
        local effectLineRenderer = linkLineEntity:EffectLineRenderer()
        ---@type UnityEngine.Transform
        local entityViewRoot = linkLineEntity:View().ViewWrapper.GameObject.transform
        local curRoot = GameObjectHelper.FindChild(entityViewRoot, self._gridBindPos)

        if not curRoot and EDITOR then
            Log.exception("Pos:", tostring(trapPos), " Grid no  :", self._gridBindPos)
        end

        --找的到目标点菜添加组件
        if curRoot then
            --添加EffectLineRenderer组件
            if not effectLineRenderer then
                linkLineEntity:AddEffectLineRenderer()
                effectLineRenderer = linkLineEntity:EffectLineRenderer()
            end

            ---@type EffectHolderComponent
            local effectHolderCmpt = linkLineEntity:EffectHolder()
            if not effectHolderCmpt then
                linkLineEntity:AddEffectHolder()
                effectHolderCmpt = linkLineEntity:EffectHolder()
            end

            local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[self._lineEffectID]
            local effect
            if effectEntityIdList then
                effect = self._world:GetEntityByID(effectEntityIdList[1])
            end

            if not effect then
                --需要创建连线特效
                effect = effectService:CreateEffect(self._lineEffectID, linkLineEntity)
                effectHolderCmpt:AttachPermanentEffect(effect:GetID())
            end



            --获取特效GetGameObject上面的LineRenderer组件
            ---@type UnityEngine.GameObject
            local go = effect:View():GetGameObject()
            local renderers
            renderers = go.transform:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)
            for i = 0, renderers.Length - 1 do
                local line = renderers[i]
                if line then
                    line.gameObject:SetActive(true)
                end
            end

            effectLineRenderer:InitEffectLineRenderer(
                    self._casterEntity:GetID(),
                    curRoot,
                    targetRoot,
                    entityViewRoot,
                    renderers,
                    effect:GetID()
            )
            effectLineRenderer:SetEffectLineRendererShow(self._casterEntity:GetID(), true)
            --TaskManager:GetInstance():CoreGameStartTask(self._CloseLineRender,self,renderers,effectLineRenderer)
        end
    end
end

--function PlayCasterSacrificeTrapsLineRendererInstruction:_CloseLineRender(TT,renderers,effectLineRenderer)
--    YIELD(TT,self._lineDuration)
--    if effectLineRenderer then
--        effectLineRenderer:SetEffectLineRendererShow(self._casterEntity:GetID(), false)
--    end
--    if renderers and renderers.Length then
--        for i = 0, renderers.Length - 1 do
--            local line = renderers[i]
--            if line and line.gameObject then
--                line.gameObject:SetActive(false)
--            end
--        end
--    end
--end

function PlayCasterSacrificeTrapsLineRendererInstruction:PlayGridEffectAtTraps(TT,trapIDs,extraGrids)
    YIELD(TT,self._gridEffectWaitTime)
    self._gridEffectEntityList ={}
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    for i, id in ipairs(trapIDs) do
        ---@type Entity
        local trapEntity = self._world:GetEntityByID(id)
        ---@type EffectLineRendererComponent
        local effectLineRenderer = trapEntity:EffectLineRenderer()
        ---@type Vector2
        local trapPos = trapEntity:GetRenderGridPosition()
        if trapPos then
            local entity =  effectService:CreateCommonGridEffect(self._gridEffectID,trapPos)
            entity:SetViewVisible(true)
            table.insert(self._gridEffectEntityList,entity)
        end
    end
    if extraGrids then
        for index, pos in ipairs(extraGrids) do
            local entity =  effectService:CreateCommonGridEffect(self._gridEffectID,pos)
            entity:SetViewVisible(true)
            table.insert(self._gridEffectEntityList,entity)
        end
    end
end