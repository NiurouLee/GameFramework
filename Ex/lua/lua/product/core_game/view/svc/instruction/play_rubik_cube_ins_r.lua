require("base_ins_r")

---@class PlayRubikCubeInstruction: BaseInstruction
_class("PlayRubikCubeInstruction", BaseInstruction)
PlayRubikCubeInstruction = PlayRubikCubeInstruction

function PlayRubikCubeInstruction:Constructor(paramList)
    self._rotateRootName = "RubikCubeRotateRoot"
    self._rotateRootPos = Vector3(-1, -3.5, 0)
    self._rotateTime = tonumber(paramList["rotateTime"]) or 3000
    self._startWaitTime = tonumber(paramList["startWaitTime"]) or 0

    self._startEffectID = tonumber(paramList["startEffectID"]) --切面特效，要放到旋转
    self._rotateEffectID = tonumber(paramList["rotateEffectID"]) --旋转的烟雾特效，要放到旋转节点下
    self._completeEffectID = tonumber(paramList["completeEffectID"])

    self._glowEffectID1 = tonumber(paramList["glowEffectID1"]) --跟着棋盘转的发光特效，1是小的
    self._glowEffectID2 = tonumber(paramList["glowEffectID2"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayRubikCubeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultRubikCube[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.RubikCube)
    if resultArray == nil then
        Log.fatal("PlayRubikCubeInstruction, result is nil.")
        return
    end
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")

    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type PieceMultiServiceRender
    local PieceMultiService = world:GetService("PieceMulti")

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type BoardMultiServiceRender
    local boardMultiServiceRender = world:GetService("BoardMultiRender")

    ---@type TrapServiceRender
    local trapSvc = world:GetService("TrapRender")
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    ---@type EffectService
    local effectService = world:GetService("Effect")

    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardComponent = renderBoardEntity:RenderBoard()
    ---@type RenderMultiBoardComponent
    local renderMultiBoardComponent = renderBoardEntity:RenderMultiBoard()

    -------------------------------

    local rotateRoot = UnityEngine.GameObject.Find(self._rotateRootName)
    if not rotateRoot then
        rotateRoot = UnityEngine.GameObject:New(self._rotateRootName)
    end
    rotateRoot.transform.position = self._rotateRootPos
    rotateRoot.transform.localEulerAngles = Vector3.zero

    local rubikModle = UnityEngine.GameObject.Find("mfro_pfb_magiccube")
    local rubikRotateModle = UnityEngine.GameObject.Find("mfro_mod_magiccube_01")
    -------------------------------

    local sceneEffectScale = Vector3(0.998, 0.998, 0.998)

    ---@param v SkillEffectResultRubikCube
    for moveIndex, v in ipairs(resultArray) do
        local targetAngle = v:GetRubikCubeTargetAngle()

        --实体分类
        local arrPiece = {}
        local allEntity = {}

        --移动一步
        local entityResult = v:GetRubikCubeEntities()
        -- local pieceResult = v:GetRubikCubePieceResult()

        local prismResult = v:GetRubikCubePrisms()
        local convertResult = v:GetConvertColors()
        local trapDestoryList = v:GetTrapDestroyList()

        for i, r in ipairs(convertResult) do
            local oldPos, newPos, oldPieceType, newPieceType, fromBoard, toBoard = r[1], r[2], r[3], r[4], r[5], r[6]
            local pieceEntity = nil
            if fromBoard == 1 then
                pieceEntity = pieceService:FindPieceEntity(oldPos)
            else
                pieceEntity = PieceMultiService:FindPieceEntity(fromBoard, oldPos)
            end
            if pieceEntity then
                local t = {pieceEntity, oldPos, newPos, fromBoard, toBoard}
                allEntity[#allEntity + 1] = t
            end
        end

        for i, r in ipairs(entityResult) do
            local eid, oldPos, newPos, fromBoard, toBoard = table.unpack(r)
            local e = world:GetEntityByID(eid)
            if e then
                local t = {e, oldPos, newPos, fromBoard, toBoard}
                allEntity[#allEntity + 1] = t
            end
        end

        --移动实体
        for i, v in ipairs(allEntity) do
            ---@type Entity
            local e = v[1]
            local oldPos = v[2]
            local newPos = v[3]
            local fromBoard = v[4]
            local toBoard = v[5]

            --设置旋转父级
            if e:HasView() then
                local entityTransform = e:View():GetGameObject().transform
                entityTransform.parent = rotateRoot.transform
            end            

            --只有在主棋盘面才有的显示和操作
            if e:MonsterID() then
                self:_ShowMonsterHPBar(e, false)

                if fromBoard == 1 then
                    --删除红线
                    renderEntityService:DestroyMonsterAreaOutLineEntity(e)

                    --移动前 把压暗的全部抬起
                    local pos = e:GridLocation():GetGridOffset()
                    local bodyArea = e:BodyArea():GetArea()
                    for _, area in ipairs(bodyArea) do
                        local workPos = area + pos
                        local curPieceAnim = pieceService:GetPieceAnimation(workPos)
                        if curPieceAnim == "Down" then
                            pieceService:SetPieceAnimUp(workPos)
                        end
                    end
                end
            end
        end

        local cutPos = Vector3(0, 0, 0)
        local cutAngle = Vector3(0, 0, 0)
        local cutAngle = Vector3(0, 0, 0)
        local glowAngle = Vector3(0, 0, 0)

        --设置旋转动画中的地板模型
        local aloneBoardID = v:GetAloneBoard()
        if aloneBoardID == 6 then
            rubikModle.transform.localEulerAngles = Vector3(0, 0, 0)
            cutPos = Vector3(-1, -3.5, 0.5)
            cutAngle = Vector3(0, 90, 0)
            glowAngle = Vector3(0, 270, 0)
        elseif aloneBoardID == 5 then
            rubikModle.transform.localEulerAngles = Vector3(0, 180, 0)
            cutPos = Vector3(-1, -3.5, -0.5)
            cutAngle = Vector3(0, 90, 0)
            glowAngle = Vector3(0, 90, 0)
        elseif aloneBoardID == 2 then
            rubikModle.transform.localEulerAngles = Vector3(0, 90, 0)
            cutPos = Vector3(-0.5, -3.5, 0)
            cutAngle = Vector3(0, 0, 0)
            glowAngle = Vector3(0, 0, 0)
        elseif aloneBoardID == 4 then
            rubikModle.transform.localEulerAngles = Vector3(0, 270, 0)
            cutPos = Vector3(-1.5, -3.5, 0)
            cutAngle = Vector3(0, 0, 0)
            glowAngle = Vector3(0, 180, 0)
        end

        local startEffect = effectService:CreateWorldPositionEffect(self._startEffectID, cutPos)
        local startEffectObj = startEffect:View():GetGameObject()
        startEffectObj.transform.localEulerAngles = cutAngle
        startEffectObj.transform.localScale = sceneEffectScale
        YIELD(TT, self._startWaitTime)

        local glowEffect1 = effectService:CreateWorldPositionEffect(self._glowEffectID1, self._rotateRootPos)
        local glowEffectObj1 = glowEffect1:View():GetGameObject()
        local glowEffect2 = effectService:CreateWorldPositionEffect(self._glowEffectID2, self._rotateRootPos)
        local glowEffectObj2 = glowEffect2:View():GetGameObject()
        glowEffectObj2.transform.parent = rotateRoot.transform
        glowEffectObj1.transform.localEulerAngles = glowAngle
        glowEffectObj1.transform.localScale = sceneEffectScale
        glowEffectObj2.transform.localEulerAngles = glowAngle
        glowEffectObj2.transform.localScale = sceneEffectScale

        local rotateEffect = effectService:CreateWorldPositionEffect(self._rotateEffectID, cutPos)
        local rotateEffectObj = rotateEffect:View():GetGameObject()
        rotateEffectObj.transform.parent = rotateRoot.transform
        rotateEffectObj.transform.localEulerAngles = cutAngle
        rotateEffectObj.transform.localScale = sceneEffectScale

        rubikRotateModle.transform.parent = rotateRoot.transform

        --旋转
        rotateRoot.transform:DORotate(targetAngle, self._rotateTime / 1000)

        local completeEffect = effectService:CreateWorldPositionEffect(self._completeEffectID, cutPos)
        local completeEffectObj = completeEffect:View():GetGameObject()
        completeEffectObj.transform.localEulerAngles = cutAngle
        completeEffectObj.transform.localScale = sceneEffectScale

        YIELD(TT, self._rotateTime)

        rubikRotateModle.transform.parent = rubikModle.transform
        rubikRotateModle.transform.localEulerAngles = Vector3(0, 0, 0)
        rubikRotateModle.transform.localPosition = Vector3(0, 0, 0)
        rubikModle.transform.localEulerAngles = Vector3(0, 0, 0)

        --怪物在旋转后 需要设置新的父级
        for i, r in ipairs(entityResult) do
            local eid, oldPos, newPos, fromBoard, toBoard = table.unpack(r)
            local e = world:GetEntityByID(eid)
            if e then
                if e:HasView() then
                    local entityTransform = e:View():GetGameObject().transform
                    if toBoard == 1 then
                        entityTransform.parent = nil
                    else
                        local boardRoot = renderMultiBoardComponent:GetMultiBoardRootGameObject(toBoard)
                        entityTransform.parent = boardRoot.transform
                    end
                end
                
                --只有在主棋盘面才有的显示和操作
                if e:MonsterID() and toBoard == 1 then
                    --显示血条血条
                    self:_ShowMonsterHPBar(e, true)
                end

                ---@type LocationComponent
                local locationComponent = e:Location()
                if locationComponent then
                    e:SetPosition(newPos)
                end
            end
        end

        --棋盘在旋转后 需要设置回旧的父级
        for i, r in ipairs(convertResult) do
            local oldPos, newPos, oldPieceType, newPieceType, fromBoard, toBoard = r[1], r[2], r[3], r[4], r[5], r[6]
            local pieceEntity = nil
            if fromBoard == 1 then
                pieceEntity = pieceService:FindPieceEntity(oldPos)
            else
                pieceEntity = PieceMultiService:FindPieceEntity(fromBoard, oldPos)
            end
            if pieceEntity then
                if pieceEntity:HasView() then
                    local entityTransform = pieceEntity:View():GetGameObject().transform
                    if fromBoard == 1 then
                        entityTransform.parent = nil
                    else
                        local boardRoot = renderMultiBoardComponent:GetMultiBoardRootGameObject(fromBoard)
                        entityTransform.parent = boardRoot.transform
                    end
                end                

                ---@type LocationComponent
                local locationComponent = pieceEntity:Location()
                if locationComponent then
                    pieceEntity:SetPosition(oldPos)
                end
            end
        end

        --转色
        --转色但是不刷新棱镜
        local notRefreshPrism = true
        for _, r in ipairs(convertResult) do
            local oldPos, newPos, oldPieceType, newPieceType, fromBoard, toBoard = r[1], r[2], r[3], r[4], r[5], r[6]

            -- playSkillInstructionService:GridConvert(TT, casterEntity, pos, 0, elementType, notRefreshPrism)

            --------------- 这种在转色的时候直接刷新棱镜的每次成功是1/2
            -- ---@type Entity
            -- local newGridEntity = nil
            -- if toBoard == 1 then
            --     newGridEntity = boardServiceRender:ReCreateGridEntity(newPieceType, newPos)
            -- else
            --     newGridEntity = boardMultiServiceRender:ReCreateGridEntity(toBoard, newPieceType, newPos)
            -- end
            ---------------

            ---@type Entity
            local newGridEntity = nil
            if toBoard == 1 then
                newGridEntity =
                    boardServiceRender:ReCreateGridEntity(newPieceType, newPos, false, false, false, notRefreshPrism)
            else
                newGridEntity =
                    boardMultiServiceRender:ReCreateGridEntity(
                    toBoard,
                    newPieceType,
                    newPos,
                    false,
                    false,
                    false,
                    notRefreshPrism
                )

                --压暗动画，必须先抬起再压暗，重复的值会return。在Recreate的时候会把动画刷成normal 但是值不会变
                PieceMultiService:SetPieceAnimUp(toBoard, newPos)
                PieceMultiService:SetPieceAnimDown(toBoard, newPos)
            end

            --会导致一个面有棱镜  其他面也会一起刷棱镜
            -- if newGridEntity then
            --     pieceService:SetPieceEntityAnimNormal(newGridEntity)
            -- end
            -------------------
        end

        -- YIELD(TT)

        for i, r in ipairs(convertResult) do
            local oldPos, newPos, oldPieceType, newPieceType, fromBoard, toBoard = r[1], r[2], r[3], r[4], r[5], r[6]
            local pieceEntity = nil
            if fromBoard == 1 then
                pieceEntity = pieceService:FindPieceEntity(oldPos)
            else
                pieceEntity = PieceMultiService:FindPieceEntity(fromBoard, oldPos)
            end
            if pieceEntity and pieceEntity:HasView() then
                local entityTransform = pieceEntity:View():GetGameObject().transform
                if fromBoard == 1 then
                    if entityTransform.parent ~= nil then
                        entityTransform.parent = nil
                    end
                else
                    local boardRoot = renderMultiBoardComponent:GetMultiBoardRootGameObject(fromBoard)
                    if entityTransform.parent ~= boardRoot.transform then
                        entityTransform.parent = boardRoot.transform
                    end
                end

                ---@type LocationComponent
                local locationComponent = pieceEntity:Location()
                if locationComponent then
                    pieceEntity:SetPosition(oldPos)
                end

                local go = pieceEntity:View():GetGameObject()
                go.transform.localEulerAngles = Vector3(0, 0, 0)
            end
        end

        --棱镜
        for _, r in pairs(prismResult) do
            local oldPos, newPos, fromBoard, toBoard = r[1], r[2], r[3], r[4]
            if fromBoard == 1 then
                pieceService:SetPieceRenderEffect(oldPos, PieceEffectType.Normal)
            else
                PieceMultiService:SetPieceRenderEffect(fromBoard, oldPos, PieceEffectType.Normal)
            end
            if toBoard == 1 then
                pieceService:SetPieceRenderEffect(newPos, PieceEffectType.Prism)
            else
                PieceMultiService:SetPieceRenderEffect(toBoard, newPos, PieceEffectType.Prism)
            end
        end

        --死亡的机关表现
        --不播放死亡技能
        local donotPlayDie = true
        for _, entityID in ipairs(trapDestoryList) do
            local entity = world:GetEntityByID(entityID)
            trapSvc:PlayTrapDieSkill(TT, {entity}, donotPlayDie)
        end
    end

    YIELD(TT)

    --设置怪物脚底暗色  刷新红线
    pieceService:RefreshPieceAnim()
    pieceService:RefreshMonsterAreaOutLine(TT)
end

function PlayRubikCubeInstruction:_ShowMonsterHPBar(monsterEntity, isShow)
    ---@type HPComponent
    local cHP = monsterEntity:HP()
    if not cHP then
        return
    end

    cHP:SetShowHPSliderState(isShow)

    monsterEntity:ReplaceHPComponent()
end
