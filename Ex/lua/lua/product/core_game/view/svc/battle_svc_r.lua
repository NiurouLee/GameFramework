--[[------------------------------------------------------------------------------------------
    RenderBattleService 战斗整体行为表现公共服务
]] --------------------------------------------------------------------------------------------
require("base_service")

require("battle_ui_active_skill_cannot_cast_reason")

ActiveSkillCannotCastReasonText = {
    [BattleUIActiveSkillCannotCastReason.NotReady] = "str_match_cannot_cast_skill_reason", ---
    [BattleUIActiveSkillCannotCastReason.SanValue] = "str_battle_skill_not_useable_4",---
    [BattleUIActiveSkillCannotCastReason.SanByScopeGridCounts] = "str_battle_skill_not_useable_5",---
    [BattleUIActiveSkillCannotCastReason.DecreaseHPPercentAsSan] = "str_battle_skill_not_useable_6",---
    [BattleUIActiveSkillCannotCastReason.HPValPercent] = "str_battle_skill_not_useable_7",---
    [BattleUIActiveSkillCannotCastReason.SanNotFull] = "str_battle_skill_not_useable_8",---
    [BattleUIActiveSkillCannotCastReason.CardNotFull] = "str_battle_skill_not_useable_9",---
    [BattleUIActiveSkillCannotCastReason.CardNotEnough] = "str_battle_skill_not_useable_10",---
    [BattleUIActiveSkillCannotCastReason.CardTarPetHasBuff] = "str_battle_skill_not_useable_11",---
    [BattleUIActiveSkillCannotCastReason.NotUnlockByBuffLayer] = "str_battle_skill_not_useable_12",---
    [BattleUIActiveSkillCannotCastReason.NotUnlockByAurora] = "str_battle_skill_not_useable_13",---
}
_enum("ActiveSkillCannotCastReasonText", ActiveSkillCannotCastReasonText)

_class("RenderBattleService", BaseService)
---@class RenderBattleService:BaseService
RenderBattleService = RenderBattleService

function RenderBattleService:Constructor(world)
    self._comboNum = 0 ---表现使用
    self._sendGameOver =false

    -- pasted from HPPosSystem
    ---@type table key=GameObject value={UnityEngine.SkinnedMeshRenderer, UnityEngine.Vector3}
    self._firstSkinedMeshRenders = {}
    ---@type table key=GameObject value=UnityEngine.MeshRenderer
    self._childMeshRenderers = {}
end

function RenderBattleService:HideUIPetInfo(TT)
    self:DisableTeamOrderChangeView()

    YIELD(TT, BattleConst.RefreshPetInfoTick)
    local delay = 0
    while delay <= 10 do
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowPetInfo, -0.1)
        delay = delay + 1
        YIELD(TT)
    end
    Log.debug("[refresh] HidePetInfo end ")
end

function RenderBattleService:ShowUIPetInfo(TT)
    YIELD(TT, BattleConst.RefreshPetInfoTick)
    local delay = 0
    while delay <= 10 do
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowPetInfo, 0.1)
        delay = delay + 1
        YIELD(TT)
    end
    self:EnableTeamOrderChangeView()
end

---@param entity Entity
---@param animList string[]
function RenderBattleService:PlayAnimation(entity, animList)
    if entity and entity:View() then
        ---@type UnityEngine.GameObject
        local gridGameObj = entity:View().ViewWrapper.GameObject

        ---@type UnityEngine.Animation 动画组件
        local u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
        if not u3dAnimCmpt then
            Log.fatal("Can not find animation component", "Trace:", Log.traceback())
            return
        end

        ---检查有没有挂动画
        local clipCount = u3dAnimCmpt:GetClipCount()
        if clipCount <= 0 then
            return
        end

        if animList == nil then
            return
        end

        if #animList <= 0 then
            return
        end
        --u3dAnimCmpt:Stop()
        if #animList > 1 then
            for _, v in ipairs(animList) do
                u3dAnimCmpt:PlayQueued(v, UnityEngine.QueueMode.CompleteOthers)
            end
        else
            ---有时候会发现PlayQueued会出现播放不完成的问题，还没找出是啥原因
            local curAnim = animList[1]
            u3dAnimCmpt:Play(curAnim)
        end
    end
end

function RenderBattleService:StopAnimation(entity)
    if entity and entity:View() then
        ---@type UnityEngine.GameObject
        local gridGameObj = entity:View().ViewWrapper.GameObject

        ---@type UnityEngine.Animation 动画组件
        local u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
        if not u3dAnimCmpt then
            Log.fatal("Can not find animation component", "Trace:", Log.traceback())
            return
        end

        ---检查有没有挂动画
        local clipCount = u3dAnimCmpt:GetClipCount()
        if clipCount <= 0 then
            return
        end
        u3dAnimCmpt:Stop()
    end
end

function RenderBattleService:ClearChainSkillPreviewRenderData()
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type PreviewChainSkillRangeComponent
    local previewChainSkillRangeCmpt = reBoard:PreviewChainSkillRange()
    ---@type ChainSkillRangeOutlineEntityDic
    local chainSkillRangeDic = previewChainSkillRangeCmpt:GetChainSkillRangeOutlineDic()
    local chainSkillOutLineEntityDic = chainSkillRangeDic:GetChainSkillOutlineEntityDic()
    if not chainSkillOutLineEntityDic then
        return
    end
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    for _, lineEntityList in pairs(chainSkillOutLineEntityDic) do
        if lineEntityList then
            for _, entityId in pairs(lineEntityList) do
                local entity = self._world:GetEntityByID(entityId)
                entityPoolService:DestroyCacheEntity(entity, EntityConfigIDRender.SkillRangeOutline)
            end
        end
    end

    local previewChainSkillGroup = self._world:GetGroup(self._world.BW_WEMatchers.PreviewChainSkillRange)
    for _, entity in ipairs(previewChainSkillGroup:GetEntities()) do
        local previewChainSkillRangeCmpt = entity:PreviewChainSkillRange()
        local chainSkillRangeDic = previewChainSkillRangeCmpt:GetChainSkillRangeOutlineDic()
        chainSkillRangeDic:ClearChainSkillOutlineEntityDic()
    end

    ---连锁技是治疗效果的
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    teamLeaderEntity:StopCurePreAnim()

    ---连锁技是单体的
    local effectList = previewChainSkillRangeCmpt:GetSnipeEffectList()
    for k, effectEntity in pairs(effectList) do
        self._world:DestroyEntity(effectEntity)
    end
    previewChainSkillRangeCmpt:ClearPreviewChainSkill()
end

function RenderBattleService:SetComboNum(comboNum)
    self._comboNum = comboNum
end

function RenderBattleService:GetComboNum()
    return self._comboNum
end

function RenderBattleService:ChangeTeamLeaderRender(TT, teamEntity)
end

---格子相对坐标转换成Hud世界坐标
---格子相对坐标的意思是（1,1），（2,5）这样的棋盘坐标
---@param gridPos Vector2
---@return Vector3
function RenderBattleService:GridPos2HudWorldPos(gridPos)
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    local gridRenderPos = boardRenderSvc:GridPos2RenderPos(gridPos)
    return self:GridRenderPos2HudWorldPos(gridRenderPos)
end

--格子渲染世界坐标转成Hud世界坐标
--格子渲染坐标是格子在对应场景里的真实坐标
function RenderBattleService:GridRenderPos2HudWorldPos(gridRenderPos)
    local camera = self._world:MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(gridRenderPos)

    local hudCamera = self._world:MainCamera():HUDCamera()
    local hudWorldPos = hudCamera:ScreenToWorldPoint(screenPos)

    return hudWorldPos
end

function RenderBattleService:RenderChangeTeamLeader(newPetPstID, oldPetPstID)
    local petEntity = self._world:Player():GetPetEntityByPetPstID(newPetPstID)
    local teamLeaderEntity = self._world:Player():GetPetEntityByPetPstID(oldPetPstID)
    petEntity:SetViewVisible(true)
    teamLeaderEntity:SetViewVisible(false)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:SetTeamLeaderRender(petEntity, true)
end

----@param battleResult MatchResult
function RenderBattleService:NotifyUIBattleGameOver(battleResult)
    if self._sendGameOver then
        return
    end
    self._sendGameOver = true
    --数值日志策划不用，暂时注释掉
    ---@type MatchModule
    -- local matchMD = GameGlobal.GetModule(MatchModule)
    -- local battleLog = self._world:GetDataLogger():GetLog()
    -- matchMD:SendBattleLog(battleLog)
    self._world:EventDispatcher():Dispatch(GameEventType.OnGameOver, battleResult)
end

---統一處理播放狙击特效
function RenderBattleService:PlaySnipeEffectAnimation(entity, element)
    if not  self._snipeEffectList then
        self._snipeEffectList = {}
        self._snipeEffectList[PieceType.Blue] = "eff_ingame_locking_1"
        self._snipeEffectList[PieceType.Red] = "eff_ingame_locking_2"
        self._snipeEffectList[PieceType.Green] = "eff_ingame_locking_3"
        self._snipeEffectList[PieceType.Yellow] = "eff_ingame_locking_4"
    end

    self:PlayAnimation(entity,{self._snipeEffectList[element]})
end


---@param go UnityEngine.GameObject
---@param animList string[]
function RenderBattleService:PlayAnimationByGameObject(go, animList)
    ---@type UnityEngine.Animation 动画组件
    local u3dAnimCmpt = go:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not u3dAnimCmpt then
        Log.fatal("Can not find animation component", "Trace:", Log.traceback())
        return
    end

    ---检查有没有挂动画
    local clipCount = u3dAnimCmpt:GetClipCount()
    if clipCount <= 0 then
        return
    end

    if animList == nil then
        return
    end

    if #animList <= 0 then
        return
    end
    --u3dAnimCmpt:Stop()
    if #animList > 1 then
        for _, v in ipairs(animList) do
            u3dAnimCmpt:PlayQueued(v, UnityEngine.QueueMode.CompleteOthers)
        end
    else
        ---有时候会发现PlayQueued会出现播放不完成的问题，还没找出是啥原因
        local curAnim = animList[1]
        u3dAnimCmpt:Play(curAnim)
    end
end

--region 光灵出战顺序修改队列
function RenderBattleService:DisableTeamOrderChangeView()
    self._world:RenderBattleStat():SetChangeTeamOrderViewDisabled(true)
end

function RenderBattleService:EnableTeamOrderChangeView()
    Log.info("[RenderBattleService] enabling change team order view")

    ---@type RenderBattleStatComponent
    local renderStat = self._world:RenderBattleStat()
    renderStat:SetChangeTeamOrderViewDisabled(false)

    local viewQueue = renderStat:GetChangeTeamOrderViewQueue()

    if #viewQueue == 0 then
        Log.info("[RenderBattleService] change team order view queue is empty. ")
        return
    end

    local currentRequest = renderStat:GetCurrentTeamOrderRequest()
    if currentRequest then
        --容错分支，执行到这里时，上一个请求没有结束，这里不再继续。（表现是否结束是由UI决定的）
        return
    end

    -- 如果待播放队列不是空的，则将队列内的数据与当前的最终结果合并成一个新的request
    local firstRequest = viewQueue[1]
    if not firstRequest then
        return
    end

    local currentTeamOrder = BattleStatHelper.GetLogicCurrentLocalTeamOrder()

    local mergedReq = BattleTeamOrderViewRequest:New(
            firstRequest:GetOldTeamOrder(),
            currentTeamOrder,
            BattleTeamOrderViewType.ShuffleTeamOrder
    )

    -- 丢弃请求信息打印
    for _, req in ipairs(viewQueue) do
        Log.info("[RenderBattleService] change team order view merged, dropping request seq ", req:GetRequestSequenceNo())
    end

    renderStat:ClearChangeTeamOrderViewQueue()
    renderStat:AddChangeTeamOrderViewRequest(mergedReq)

    self:TryPopNextChangeTeamOrderView()
end

function RenderBattleService:TryPopNextChangeTeamOrderView()
    ---@type RenderBattleStatComponent
    local renderStat = self._world:RenderBattleStat()

    if renderStat:IsChangeTeamOrderViewDisabled() then
        Log.info("[InnerGameHelperRender] change team order view disabled, skip popping next request. ")
        return
    end

    if renderStat:GetCurrentTeamOrderRequest() then
        Log.info("[InnerGameHelperRender] there is already a presenting request. ")
        return
    end

    local current = renderStat:PopFirstTeamOrderRequestAsCurrent()
    if current then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CallUIChangeTeamOrderView, current)
    end
end

function RenderBattleService:GetCurrentChangeTeamOrderViewRequest()
    ---@type RenderBattleStatComponent
    local renderStat = self._world:RenderBattleStat()
    return renderStat:GetCurrentTeamOrderRequest()
end

---@param request BattleTeamOrderViewRequest
function RenderBattleService:RequestUIChangeTeamOrderView(request)
    ---@type RenderBattleStatComponent
    local renderStat = self._world:RenderBattleStat()
    renderStat:AddChangeTeamOrderViewRequest(request)
    if renderStat:GetCurrentTeamOrderRequest() then
        return
    end
    self:TryPopNextChangeTeamOrderView()
end
--endregion
function RenderBattleService:CalcHPBarPos(viewWrapper, hp_offset)
    local hpPosTransform = viewWrapper:FindChild("HPPos")--特殊情况 如果模型里有HPPos节点，则以该节点计算血条位置，否则是原逻辑
    if hpPosTransform then
        local hpPosObj = hpPosTransform.gameObject
        local owner_entity_render_pos = hpPosObj.transform.position
        local hpPosition = owner_entity_render_pos + hp_offset
        owner_entity_render_pos = self:CalcGridHUDWorldPos(hpPosition)
        return owner_entity_render_pos
    else
        return self:CalcSkinnedMeshPos(viewWrapper,hp_offset)
    end
end
--region SkinnedMeshPos calculation: pasted from HPPosSystem_Render
---@param viewWrapper UnityViewWrapper
function RenderBattleService:CalcSkinnedMeshPos(viewWrapper, hp_offset)
    local ownerObj = viewWrapper.GameObject
    local rootObj = nil
    local rootTransform = viewWrapper:FindChild("Root")
    if rootTransform then
        rootObj = rootTransform.gameObject
    else
        rootObj = viewWrapper.GameObject
    end

    local owner_entity_render_pos = rootObj.transform.position
    local skinnedMeshRender, meshExtents = self:FindFirstSkinedMeshRender(rootObj)
    if skinnedMeshRender ~= nil then
        local skinnedMeshPosition = skinnedMeshRender.transform.position + hp_offset
        local convertExtents = Vector3(0, meshExtents.x * 2, 0)
        local targetPos = skinnedMeshPosition + convertExtents
        --Log.fatal("ownObj",ownerObj.name," pos",skinnedMeshPosition.x,skinnedMeshPosition.y,skinnedMeshPosition.z," meshExtents ",meshExtents.x," ",meshExtents.y," ",meshExtents.z)

        owner_entity_render_pos = self:CalcGridHUDWorldPos(targetPos)
    else
        local meshRenderer = self:GetMeshRendererInChildren(ownerObj)
        if meshRenderer then
            local meshPosition = owner_entity_render_pos + hp_offset
            owner_entity_render_pos = self:CalcGridHUDWorldPos(meshPosition)
        else
            Log.fatal("ownerObj", ownerObj.name, "has no skinned mesh and mesh")
        end
    end

    return owner_entity_render_pos
end

---@param go UnityEngine.GameObject
---@return table UnityEngine.SkinnedMeshRenderer, UnityEngine.Vector3
function RenderBattleService:FindFirstSkinedMeshRender(go)
    if not self._firstSkinedMeshRenders[go] then
        local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(go)
        local meshExtents = GameObjectHelper.FindFirstSkinedMeshRenderBoundsExtent(go)
        self._firstSkinedMeshRenders[go] = {skinnedMeshRender, meshExtents}
    end
    local v = self._firstSkinedMeshRenders[go]
    return v[1], v[2]
end

function RenderBattleService:CalcGridHUDWorldPos(gridRenderPos)
    local camera = self._world:MainCamera():Camera()
    local hudCamera = self._world:MainCamera():HUDCamera()
    local hudWorldPos = GameObjectHelper.CalcGridHUDWorldPos(
        camera,
        hudCamera,
        gridRenderPos,
        BattleConst.HUDEdgeLeft,
        BattleConst.HUDEdgeRight,
        BattleConst.HUDEdgeDown,
        BattleConst.HUDEdgeUpper
    )
    return hudWorldPos
end

---@param go UnityEngine.GameObject
---@return UnityEngine.MeshRenderer
function RenderBattleService:GetMeshRendererInChildren(go)
    if not self._childMeshRenderers[go] then
        self._childMeshRenderers[go] = go:GetComponentInChildren(typeof(UnityEngine.MeshRenderer))
    end
    local v = self._childMeshRenderers[go]
    return v
end
--endregion
