require("base_ins_r")

---@class PlayHideSceneAndPlaySceneEffInstruction: BaseInstruction
_class("PlayHideSceneAndPlaySceneEffInstruction", BaseInstruction)
PlayHideSceneAndPlaySceneEffInstruction = PlayHideSceneAndPlaySceneEffInstruction

function PlayHideSceneAndPlaySceneEffInstruction:Constructor(paramList)
    ---场景出现特效
    self._sceneOpenEffectID = tonumber(paramList["sceneOpenEffectID"])

    ---延迟时间
    self._openDelayTime = tonumber(paramList["openDelayTime"]) or 0

    ---场景特效
    self._sceneEffectID = tonumber(paramList["sceneEffectID"])

    ---场景特效位置
    self._sceneEffPos = Vector2(tonumber(paramList["gridPosX"]), tonumber(paramList["gridPosY"]))

    ---格子背景亮度
    self._backIntensity = tonumber(paramList["backIntensity"])
end

function PlayHideSceneAndPlaySceneEffInstruction:GetCacheResource()
    local t = {}
    if self._sceneOpenEffectID and self._sceneOpenEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._sceneOpenEffectID].ResPath, 1 })
    end

    if self._sceneEffectID and self._sceneEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._sceneEffectID].ResPath, 1 })
    end

    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayHideSceneAndPlaySceneEffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---播放开场特效
    ---@type EffectService
    local effectSvc = world:GetService("Effect")
    ---@type Entity
    effectSvc:CreateWorldPositionEffect(self._sceneOpenEffectID, self._sceneEffPos)

    ---延迟
    if self._openDelayTime > 0 then
        YIELD(TT, self._openDelayTime)
    end

    ---关闭场景GameObject
    ---@type Entity
    local boardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = boardEntity:RenderBoard()
    local goScene = renderBoardCmpt:GetSceneGO("SceneRoot")
    if goScene then
        goScene:SetActive(false)
    end

    ---播放场景特效
    ---@type Entity
    local sceneEffEntity = effectSvc:CreateWorldPositionEffect(self._sceneEffectID, self._sceneEffPos)
    renderBoardCmpt:SetSceneEffectEntityID(sceneEffEntity:GetID())

    ---设置H3DRenderSetting
    local goRenderSetting = UnityEngine.GameObject.Find("[H3DRenderSetting]")
    local csRenderSetting = goRenderSetting:GetComponent("H3DRenderSetting")
    if csRenderSetting.BackIntensity then
        csRenderSetting.BackIntensity = self._backIntensity
    end
end
