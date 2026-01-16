--[[------------------------------------------------------------------------------------------
    GridAddViewSystem_Render : 监听格子表现变化
]] --------------------------------------------------------------------------------------------

---@class GridAddViewSystem_Render:ReactiveSystem
_class("GridAddViewSystem_Render", ReactiveSystem)
GridAddViewSystem_Render = GridAddViewSystem_Render

function GridAddViewSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

function GridAddViewSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.View)
    local c = Collector:New({group}, {"Added"})
    return c
end

function GridAddViewSystem_Render:Filter(entity)
    return entity:HasPiece() or entity:HasPieceFake()
end

function GridAddViewSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:OnGridViewAdded(entities[i])
    end
end

function GridAddViewSystem_Render:OnGridViewAdded(gridEntity)
    --[[
    local gridPos = gridEntity:GridLocation().Position
    if gridPos.x == 4 and gridPos.y == 1 then 
        local gridGameObj = gridEntity:View().ViewWrapper.GameObject
        local gameObjName = gridGameObj.name
        local frameCount = UnityEngine.Time.frameCount
        Log.fatal("OnGridViewAdded:",gameObjName,";gridPos:",gridPos,";frameCount:",frameCount,Log.traceback())
    end
    --]]
    ---格子坐标
    local gridPos = gridEntity:GridLocation().Position
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:InitializeGridU3DCmpt(gridEntity)
    pieceService:ResetPieceAnimatorState(gridPos)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local gameFsmStateID = utilDataSvc:GetCurMainStateID()
    if gameFsmStateID == GameStateID.PickUpActiveSkillTarget then
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
        if pickUpTargetCmpt == nil then
            Log.fatal("pick up target is nil")
            return
        end

        local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
        ---@type ConfigService
        local configService = self._configService
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(activeSkillID)
        ---@type SkillPickUpType
        local pickUpType = skillConfigData:GetSkillPickType()

        if pickUpType ~= SkillPickUpType.DirectionInstruction and pickUpType ~= SkillPickUpType.Instruction then
            self:_ChangeGridMaterial(gridEntity, gridPos)
        end
    elseif gameFsmStateID == GameStateID.ActiveSkill or gameFsmStateID == GameStateID.PersonaSkill then
        --主动技中 不处理
    else
        local isMonsterArea = self:_ChangeGridMaterial(gridEntity, gridPos)
        if not isMonsterArea then
        --临时解决格子动画不能正确播放的问题
        --pieceService:SetPieceEntityAnimNormal(gridEntity)
        end
    end
    if gridEntity:HasReplaceMaterialComponent() then
        ---@type ReplaceMaterialComponent
        local component = gridEntity:ReplaceMaterialComponent()

        if gridEntity:Piece() or gridEntity:HasPieceFake() then
            pieceService:ReplaceGridMaterial(gridEntity, component:GetMaterialAssetName())
        end
        gridEntity:RemoveReplaceMaterialComponent()
    end
end

---将怪物脚底下的格子材质设置为变暗效果
function GridAddViewSystem_Render:_ChangeGridMaterial(gridEntity, gridPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curSt = utilDataSvc:GetCurMainStateID()

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local monsterGridPos = e:GridLocation().Position
        if e:HasBodyArea() then
            ---@type BodyAreaComponent
            local bodyAreaCmpt = e:BodyArea()
            local areaArray = bodyAreaCmpt:GetArea()
            for i = 1, #areaArray do
                local curAreaPos = areaArray[i]
                --Log.fatal("monsterPos:",monsterGridPos.x," ",monsterGridPos.y," area",curAreaPos.x," ",curAreaPos.y)
                local monsterAreaPos = monsterGridPos + curAreaPos
                if monsterAreaPos == gridPos then
                    if curSt ~= GameStateID.Loading then
                        pieceSvc:SetPieceAnimDown(gridPos)
                    end
                    return true
                end
            end
        else
            local monsterAreaPos = monsterGridPos
            if monsterAreaPos == gridPos then
                if curSt ~= GameStateID.Loading then
                    pieceSvc:SetPieceAnimDown(gridPos)
                end
                return true
            end
        end
    end
    return false
end

---@param gridEntity Entity
function GridAddViewSystem_Render:_InitializeGridU3DCmpt(gridEntity)
    ---@type UnityEngine.GameObject
    local gridGameObj = gridEntity:View().ViewWrapper.GameObject

    ---@type UnityEngine.Animation 动画组件
    local u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not u3dAnimCmpt then
        Log.fatal("Can not find animation component")
        return
    end

    ---@type LegacyAnimationComponent
    local legacyAnimCmpt = gridEntity:LegacyAnimation()
    legacyAnimCmpt:SetU3DAnimationCmpt(u3dAnimCmpt)
end
