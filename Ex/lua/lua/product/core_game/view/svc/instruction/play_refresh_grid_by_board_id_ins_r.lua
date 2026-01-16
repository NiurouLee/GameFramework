require("base_ins_r")

---@class PlayRefreshGridByBoardIDInstruction: BaseInstruction
_class("PlayRefreshGridByBoardIDInstruction", BaseInstruction)
PlayRefreshGridByBoardIDInstruction = PlayRefreshGridByBoardIDInstruction

function PlayRefreshGridByBoardIDInstruction:Constructor(paramList)
    ---场景特效
    local str = paramList["sceneEffectIDs"]
    local strIDs = string.split(str, "|")
    self._sceneEffectIDs = {}
    for _, v in ipairs(strIDs) do
        self._sceneEffectIDs[#self._sceneEffectIDs + 1] = tonumber(v)
    end
    ---场景特效位置
    self._sceneEffPos = Vector2(tonumber(paramList["gridPosX"]), tonumber(paramList["gridPosY"]))

    ---场景转换特效
    str = paramList["sceneChangeEffectIDs"]
    strIDs = string.split(str, "|")
    self._sceneChangeEffectIDs = {}
    for _, v in ipairs(strIDs) do
        self._sceneChangeEffectIDs[#self._sceneChangeEffectIDs + 1] = tonumber(v)
    end

    ---場景切换延迟时间
    self._changeDelayTime = tonumber(paramList["changeDelayTime"]) or 0

    ---格子背景亮度
    self._backIntensity = tonumber(paramList["backIntensity"])
end

function PlayRefreshGridByBoardIDInstruction:GetCacheResource()
    local t = {}
    for _, value in ipairs(self._sceneEffectIDs) do
        if value and value > 0 then
            table.insert(t, { Cfg.cfg_effect[value].ResPath, 1 })
        end
    end

    for _, value in ipairs(self._sceneChangeEffectIDs) do
        if value and value > 0 then
            table.insert(t, { Cfg.cfg_effect[value].ResPath, 1 })
        end
    end

    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayRefreshGridByBoardIDInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectRefreshGridByBoardIDResult
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.RefreshGridByBoardID)
    if result == nil then
        return
    end

    ---获取本次应该播放的特效
    local changeTimes = result:GetSceneChangeTimes()
    local index = 0
    index = math.fmod(changeTimes, #self._sceneEffectIDs)
    if index == 0 then
        index = #self._sceneEffectIDs
    end
    local curSceneEffectID = self._sceneEffectIDs[index]
    local curSceneChangeEffectID = self._sceneChangeEffectIDs[index]

    ---播放场景切换特效
    ---@type EffectService
    local effectSvc = world:GetService("Effect")
    ---@type Entity
    effectSvc:CreateEffect(curSceneChangeEffectID, casterEntity)

    ---延迟
    if self._changeDelayTime > 0 then
        YIELD(TT, self._changeDelayTime)
    end

    ---死亡的机关表现 不播放死亡技能
    ---@type TrapServiceRender
    local trapSvc = world:GetService("TrapRender")
    local destroyTrapEntityIDList = result:GetDestroyTrapEntityIDList()
    local trapEntityList = {}
    for _, entityID in ipairs(destroyTrapEntityIDList) do
        local entity = world:GetEntityByID(entityID)
        table.insert(trapEntityList, entity)
    end
    trapSvc:PlayTrapDieSkill(TT, trapEntityList, true)

    ---刷新格子
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type BoardServiceRender
    local boardSvc = world:GetService("BoardRender")
    for pos, pieceType in pairs(result:GetGridPieceData()) do
        local currentPiece = renderBoardCmpt:GetGridRenderEntity(pos)
        if currentPiece then
            if currentPiece:Piece() and currentPiece:Piece():GetPieceType() ~= pieceType then
                ---格子颜色不一致 则重建
                local gridEntity = boardSvc:ChangeGridEntity(pieceType, pos)
                pieceSvc:SetPieceEntityAnimNormal(gridEntity)
            end
        else
            ---没有 则新建
            boardSvc:CreateGridEntity(pieceType, pos)
        end
    end

    ---停止原场景特效
    local effectID = renderBoardCmpt:GetSceneEffectEntityID()
    effectSvc:DestroyEffectByID(effectID)

    ---播放新的场景特效
    ---@type Entity
    local sceneEffEntity = effectSvc:CreateWorldPositionEffect(curSceneEffectID, self._sceneEffPos)
    renderBoardCmpt:SetSceneEffectEntityID(sceneEffEntity:GetID())

    ---设置H3DRenderSetting
    local goRenderSetting = UnityEngine.GameObject.Find("[H3DRenderSetting]")
    local csRenderSetting = goRenderSetting:GetComponent("H3DRenderSetting")
    if csRenderSetting.BackIntensity then
        csRenderSetting.BackIntensity = self._backIntensity
    end
end
