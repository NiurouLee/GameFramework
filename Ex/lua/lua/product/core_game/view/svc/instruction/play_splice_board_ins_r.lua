require("base_ins_r")

---@class PlaySpliceBoardInstruction: BaseInstruction
_class("PlaySpliceBoardInstruction", BaseInstruction)
PlaySpliceBoardInstruction = PlaySpliceBoardInstruction

function PlaySpliceBoardInstruction:Constructor(paramList)
    self._moveRootName = "BoardCenter"
    self._moveTime = tonumber(paramList["moveTime"]) or 1000

    self._startWaitTime = tonumber(paramList["startWaitTime"]) or 0

    self._startEffectID = tonumber(paramList["startEffectID"]) --切面特效，要放到旋转
    self._rotateEffectID = tonumber(paramList["rotateEffectID"]) --旋转的烟雾特效，要放到旋转节点下
    self._completeEffectID = tonumber(paramList["completeEffectID"])

    self._glowEffectID1 = tonumber(paramList["glowEffectID1"]) --跟着棋盘转的发光特效，1是小的
    self._glowEffectID2 = tonumber(paramList["glowEffectID2"])

    --机关
    local trapIDList = paramList["trapIDList"]
    self._trapIDList = {}
    if trapIDList then
        local arr = string.split(trapIDList, "|")
        for k, idStr in ipairs(arr) do
            local trapID = tonumber(idStr)
            table.insert(self._trapIDList, trapID)
        end
    end

    local playDieSkillTrapIDList = paramList["playDieSkillTrapIDList"]
    self._playDieSkillTrapIDList = {}
    if playDieSkillTrapIDList then
        local arr = string.split(playDieSkillTrapIDList, "|")
        for k, idStr in ipairs(arr) do
            local trapID = tonumber(idStr)
            table.insert(self._playDieSkillTrapIDList, trapID)
        end
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySpliceBoardInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultSpliceBoard[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SpliceBoard)
    if resultArray == nil then
        Log.fatal("PlaySpliceBoardInstruction, result is nil.")
        return
    end
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")

    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")

    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")

    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardComponent = renderBoardEntity:RenderBoard()
    ---@type RenderBoardSpliceComponent
    local renderBoardSpliceComponent = renderBoardEntity:RenderBoardSplice()

    ---@type PreviewEnvComponent
    local previewEnvComponent = world:GetPreviewEntity():PreviewEnv()

    local moveRoot = UnityEngine.GameObject.Find(self._moveRootName)
    if not moveRoot then
        moveRoot = UnityEngine.GameObject:New(self._moveRootName)
    end
    -- moveRoot.transform.position = Vector3.zero
    -- moveRoot.transform.localEulerAngles = Vector3.zero

    for _, resultSpliceBoard in ipairs(resultArray) do
        ---@type SkillEffectResultSpliceBoard
        local result = resultSpliceBoard
        local distance, direction = result:GetMoveParam()
        local entityResult = result:GetMoveEntities()
        local prismResult = result:GetSpliceBoardPrisms()
        local convertResult = result:GetConvertColors()
        local spliceResult = result:GetSpliceBoardGrid()
        local spliceOnlyPlayDarkResult = result:GetSpliceBoardOnlyPlayDark()

        local notifyStartTrapEntityID = result:GetNotifyStartTrapEntityID()
        local notifyStartTrapEntity = world:GetEntityByID(notifyStartTrapEntityID)
        local notifyEndTrapEntityID = result:GetNotifyEndTrapEntityID()
        local notifyEndTrapEntity = world:GetEntityByID(notifyEndTrapEntityID)

        --位移完成后 删除脱离的外环上的机关
        --改成位移前 就删除机关
        local destroyTrapList = result:GetDestroyTrapList()
        local isDieSkillDisabled = true --不执行死亡技能
        for _, entityID in ipairs(destroyTrapList) do
            local tarpEntity = world:GetEntityByID(entityID)

            isDieSkillDisabled = false
            -- ---@type TrapRenderComponent
            -- local trapRenderComponent = tarpEntity:TrapRender()
            -- if trapRenderComponent:GetTrapType() == TrapType.BadGrid then
            --     isDieSkillDisabled = false
            -- end
            trapServiceRender:PlayTrapDieSkill(TT, {tarpEntity}, false)

            local trapID = tarpEntity:TrapID():GetTrapID()
            if table.icontains(self._playDieSkillTrapIDList, trapID) then
                -- ---@type EntityPoolServiceRender
                -- local entityPoolService = world:GetService("EntityPool")
                ---@type TrapRenderComponent
                local trapRenderComponent = tarpEntity:TrapRender()
                local aurasEntityList = trapRenderComponent:GetAllAurasEntity()
                if aurasEntityList then
                    for i, id in ipairs(aurasEntityList) do
                        local aurasEntity = world:GetEntityByID(id)
                        -- if not trapRenderComponent:IsAurasFinish() then
                        -- entityPoolService:DestroyCacheEntity(aurasEntity, EntityConfigIDRender.TrapAurasArea)
                        -- end
                        world:DestroyEntity(aurasEntity)
                    end
                end

                ----@type  Entity[]
                local entities = world:GetGroupEntities(world.BW_WEMatchers.TrapAurasOutline)
                if entities then
                    for i, e in ipairs(entities) do
                        if not e:HasDeadMark() and not e:HasDeadFlag() then
                            e:ReplaceTrapAurasOutline()
                        end
                    end
                end
            end
        end

        if distance > 0 then
            --实体分类
            local arrPiece = {}
            local allEntity = {}

            for i, r in ipairs(convertResult) do
                local oldPos, newPos, pieceType, isAddGrid, isRemoveGrid = r[1], r[2], r[3], r[4], r[5]

                local pieceEntity = pieceService:FindPieceEntity(oldPos)
                if pieceEntity then
                    local t = {pieceEntity, oldPos, newPos}
                    allEntity[#allEntity + 1] = t
                end
            end

            for i, r in ipairs(entityResult) do
                local eid, oldPos, newPos = table.unpack(r)
                local e = world:GetEntityByID(eid)
                if e then
                    local t = {e, oldPos, newPos}
                    allEntity[#allEntity + 1] = t
                end
            end

            --移动实体
            for i, v in ipairs(allEntity) do
                ---@type Entity
                local e = v[1]
                local oldPos = v[2]
                local newPos = v[3]

                --设置旋转父级
                if e:HasView() then
                    local entityTransform = e:View():GetGameObject().transform
                    entityTransform.parent = moveRoot.transform
                end

                if e:HasMonsterID() then
                    --删除红线
                    renderEntityService:DestroyMonsterAreaOutLineEntity(e)
                elseif e:HasTrapID() then
                    if e:HasTrapRoundInfoRender() then
                        local eid = e:TrapRoundInfoRender():GetRoundInfoEntityID()
                        if eid then
                            local eff = world:GetEntityByID(eid)
                            -- eff:RemoveGridMove()
                            -- eff:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                            local entityTransform = eff:View():GetGameObject().transform
                            entityTransform.parent = moveRoot.transform
                        end
                    end
                    local cEffectHolder = e:EffectHolder()
                    if cEffectHolder then
                        --处理散布在格子外的待机特效（凛音结界）
                        local effectList = cEffectHolder:GetIdleEffect()
                        if table.count(effectList) > 0 then
                            for i, eff in ipairs(effectList) do
                                local effectEntity = world:GetEntityByID(eff)
                                if effectEntity and effectEntity:HasView() then
                                    local curGridPos = boardServiceRender:GetRealEntityGridPos(effectEntity)
                                    local newGridPos = curGridPos + direction
                                    -- effectEntity:RemoveGridMove()
                                    -- effectEntity:AddGridMove(BattleConst.ConveySpeed, newGridPos, curGridPos)
                                    local entityTransform = effectEntity:View():GetGameObject().transform
                                    entityTransform.parent = moveRoot.transform
                                end
                            end
                        end
                    end

                    ---@type TrapRenderComponent
                    local trapRenderComponent = e:TrapRender()
                    if trapRenderComponent then
                        local aurasEntityList = trapRenderComponent:GetAllAurasEntity()
                        if aurasEntityList then
                            for i, id in ipairs(aurasEntityList) do
                                local aurasEntity = world:GetEntityByID(id)
                                local entityTransform = aurasEntity:View():GetGameObject().transform
                                entityTransform.parent = moveRoot.transform
                            end
                        end
                    end
                end

                --移动前 把压暗的全部抬起

                --血条
                if e:HasMonsterID() or e:HasTeam() then
                    self:_ShowMonsterHPBar(e, false)
                end
            end

            local targetMovePos =
                moveRoot.transform.position + Vector3(direction.x * distance, 0, direction.y * distance)
            moveRoot.transform:DOMove(targetMovePos, self._moveTime / 1000)

            if notifyStartTrapEntity then
                local ntSpliceBoard = NTSpliceBoardBegin:New(notifyStartTrapEntity)
                playBuffService:PlayBuffView(TT, ntSpliceBoard)
            end

            local cameraPos = nil
            local boardCenter = nil

            --移动相机
            if direction == Vector2(1, 0) then
                cameraPos = Vector3(27, 28, -21)
                boardCenter = Vector3(2.5, 0, 3.5)
            elseif direction == Vector2(0, -1) then
                cameraPos = Vector3(25, 25.2, -21)
                boardCenter = Vector3(2.5, 0, 0.5)
            elseif direction == Vector2(-1, 0) then
                cameraPos = Vector3(22, 25, -21)
                boardCenter = Vector3(-0.5, 0, 0.5)
            elseif direction == Vector2(0, 1) then
                cameraPos = Vector3(23, 27, -20)
                boardCenter = Vector3(-0.5, 0, 3.5)
            end
            ---@type MainCameraComponent
            local mainCameraCmpt = world:MainCamera()
            local mainCamera = mainCameraCmpt:Camera()
            local cameraTran = mainCamera.transform
            cameraTran:DOMove(cameraPos, self._moveTime / 1000.0, false)

            YIELD(TT, self._moveTime)

            ---@type MainCameraComponent
            local mainCameraCmpt = world:MainCamera()
            mainCameraCmpt:SetCameraPos(cameraPos)

            ---@type BattleRenderConfigComponent
            local battleRenderCmpt = world:BattleRenderConfig()
            battleRenderCmpt:SetCurWaveBoardCenter(boardCenter)

            local monsterGroup = world:GetGroup(world.BW_WEMatchers.HP)
            for _, e in ipairs(monsterGroup:GetEntities()) do
                ---@type HPComponent
                local hpComponent = e:HP()
                if e:IsViewVisible() and hpComponent then
                    hpComponent:SetHPPosDirty(true)
                end
            end

            for i, r in ipairs(entityResult) do
                local eid, oldPos, newPos = table.unpack(r)
                local e = world:GetEntityByID(eid)
                if e then
                    if e:HasView() then
                        local entityTransform = e:View():GetGameObject().transform
                        entityTransform.parent = nil
                    end

                    e:SetPosition(newPos)

                    if e:HasMonsterID() then
                        renderEntityService:CreateMonsterAreaOutlineEntity(e)
                    end

                    if e:HasMonsterID() or e:HasTeam() then
                        self:_ShowMonsterHPBar(e, true)
                    end

                    if e:HasTeam() then
                        local petList = e:Team():GetTeamPetEntities()
                        for k, pet in pairs(petList) do
                            pet:SetPosition(newPos)
                        end
                    end
                end
            end

            --转色但是不刷新棱镜
            local notRefreshPrism = true
            for i, r in ipairs(convertResult) do
                local oldPos, newPos, pieceType, isAddGrid, isRemoveGrid = r[1], r[2], r[3], r[4], r[5]

                local pieceEntity = renderBoardComponent:GetGridRenderEntity(oldPos)
                if pieceEntity then
                    if pieceEntity:HasView() then
                        local entityTransform = pieceEntity:View():GetGameObject().transform
                        entityTransform.parent = nil
                    end
                    pieceEntity:SetPosition(newPos)
                    renderBoardComponent:SetGridRenderEntityData(newPos, pieceEntity)
                end

                if isAddGrid then
                end

                if isRemoveGrid then
                end

                ---@type Entity
                local newGridEntity =
                    boardServiceRender:ReCreateGridEntity(pieceType, newPos, false, false, false, notRefreshPrism)

                -- pieceService:InitializeGridU3DCmpt(newGridEntity)
                -- renderBoardComponent:SetGridRenderEntityData(newPos, newGridEntity)
                previewEnvComponent:SetPieceType(newPos, pieceType)
            end

            --统一刷一遍，为了创建_pieceAnim和_pieceEffect
            pieceService:InitPieceAnim()

            --棱镜
            for _, r in pairs(prismResult) do
                local oldPos, newPos = r[1], r[2]
                pieceService:SetPieceRenderEffect(oldPos, PieceEffectType.Normal)
                pieceService:SetPieceRenderEffect(newPos, PieceEffectType.Prism)
            end

            self:PlaySpliceResult(spliceResult, world)
        else
            self:PlaySpliceResult(spliceResult, world)

            --出场变暗
            for _, pos in ipairs(spliceOnlyPlayDarkResult) do
                ---@type Entity
                local newGridFakeEntity = pieceService:FindPieceFakeEntity(pos)
                if newGridFakeEntity then
                    pieceService:_PlayPieceU3DAnimation({"gezi_dark"}, newGridFakeEntity)
                end
                -- renderBoardComponent:SetGridRenderEntityData(pos, nil)
                -- previewEnvComponent:SetPieceType(pos, nil)
            end
        end

        if notifyEndTrapEntity then
            local ntSpliceBoard = NTSpliceBoardEnd:New(notifyEndTrapEntity)
            playBuffService:PlayBuffView(TT, ntSpliceBoard)
        end

        --统一刷一遍，为了创建_pieceAnim和_pieceEffect
        pieceService:InitPieceAnim()

        --机关

        YIELD(TT)
    end

    YIELD(TT)
end

function PlaySpliceBoardInstruction:_ShowMonsterHPBar(monsterEntity, isShow)
    ---@type HPComponent
    local cHP = monsterEntity:HP()
    if not cHP then
        return
    end

    cHP:SetShowHPSliderState(isShow)

    monsterEntity:ReplaceHPComponent()
end

function PlaySpliceBoardInstruction:PlaySpliceResult(spliceResult, world)
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardComponent = renderBoardEntity:RenderBoard()
    ---@type RenderBoardSpliceComponent
    local renderBoardSpliceComponent = renderBoardEntity:RenderBoardSplice()
    ---@type PreviewEnvComponent
    local previewEnvComponent = world:GetPreviewEntity():PreviewEnv()

    for i, r in ipairs(spliceResult) do
        local pos, isAddGrid, isRemoveGrid, pieceType, isPrism = r[1], r[2], r[3], r[4], r[5]

        ---@type Entity
        local pieceEntity = pieceService:FindPieceEntity(pos)
        ---@type Entity
        local pieceFakeEntity = pieceService:FindPieceFakeEntity(pos)

        if isAddGrid == true then
            --创建piece
            ---没有格子，新建一个pieceEntity
            local newGridEntity
            if not pieceEntity then
                newGridEntity = boardServiceRender:CreateGridEntity(pieceType, pos, false)
            else
                --第二次进来的时候是有pieceEntity，区别在于Re需要先在该位置find，再拿find的结果去re
                newGridEntity = boardServiceRender:ReCreateGridEntity(pieceType, pos, false)
            end
            --ReCreateGridEntity 的时候第6个参数不配  自动刷新prism。CreateGridEntity的时候没有，需要手动调用
            if isPrism then
                --会因为PieceEffectType相同return了
                -- pieceService:SetPieceRenderEffect(pos, PieceEffectType.Prism)

                pieceService:SetPieceEntityAnimNormal(newGridEntity)
            end

            pieceService:InitializeGridU3DCmpt(newGridEntity)

            renderBoardComponent:SetGridRenderEntityData(pos, newGridEntity)
            previewEnvComponent:SetPieceType(pos, pieceType)

            if pieceFakeEntity then
                world:DestroyEntity(pieceFakeEntity)
            end
        end

        --isRemoveGrid=true是删除    isRemoveGrid=nil是出场
        if isRemoveGrid == true then
            -- ---@type Entity
            -- local newGridFakeEntity = boardServiceRender:CreateGridFakeEntity(pieceType, pos, false)

            -- ---@type Entity
            -- local newGridFakeEntity = pieceService:FindPieceFakeEntity(pos)
            -- if not newGridFakeEntity then
            --     newGridFakeEntity = boardServiceRender:CreateGridFakeEntity(pieceType, pos, false)
            -- end

            ---@type Entity
            local newGridFakeEntity = boardServiceRender:CreateGridFakeEntity(pieceType, pos, false)

            --只播放dark就行了 不用播放棱镜

            -- --假格子播放材质动画
            -- if isPrism then
            --     ---@type TrapServiceRender
            --     local trapServiceRender = world:GetService("TrapRender")
            --     local prismEffectTrap = trapServiceRender:GetPrismEffectTrap(pos)
            --     --是格子动画棱镜
            --     if not prismEffectTrap then
            --         --因为是删除的格子 不占人 所以只有Normal动画
            --         -- pieceService:_PlayGridAnimation(newGridFakeEntity, "Normal")

            --         pieceService:_PlayPieceU3DAnimation({"gezi_prism,gezi_dark"}, newGridFakeEntity)
            --     end
            -- end

            pieceService:_PlayPieceU3DAnimation({"gezi_dark"}, newGridFakeEntity)

            renderBoardComponent:SetGridRenderEntityData(pos, nil)
            previewEnvComponent:SetPieceType(pos, nil)

            if pieceEntity then
                world:DestroyEntity(pieceEntity)
            end
        end
    end
end
