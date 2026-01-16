require("sp_base_inst")
_class("SkillPreviewYeliyaRefreshPickGhostInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewYeliyaRefreshPickGhostInstruction: SkillPreviewBaseInstruction
SkillPreviewYeliyaRefreshPickGhostInstruction = SkillPreviewYeliyaRefreshPickGhostInstruction

function SkillPreviewYeliyaRefreshPickGhostInstruction:Constructor(params)
    self._ghostAnim = params["GhostAnim"] or "AtkUltPreview"
    self._lineEffectID = tonumber(params["LineEffectID"])
    self._bindPos = params["BindPos"] or "Root"
    self._pickPosEffectID = tonumber(params["PickPosEffectID"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewYeliyaRefreshPickGhostInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type RenderEntityService
    local renderEntitySvc = world:GetService("RenderEntity")
    renderEntitySvc:DestroyGhost()
    YIELD(TT)
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    local pickupPosArray = previewPickUpComponent and previewPickUpComponent:GetAllValidPickUpGridPos() or {}
    if #pickupPosArray > 0 then
        local lastPos = casterEntity:GetPosition()
        local lastEntity = casterEntity
        for index, pickPos in ipairs(pickupPosArray) do
            local ghostEntity = entitySvc:CreateGhost(pickPos, casterEntity, self._ghostAnim)
            if ghostEntity then
                ghostEntity:SetDirection(pickPos - lastPos)
                ghostEntity:SetViewVisible(true)
                if self._pickPosEffectID then
                    effectService:CreateEffect(self._pickPosEffectID, ghostEntity)
                end
                GameGlobal.TaskManager():CoreGameStartTask(self._CreateIndexNumHeadShow, self, world,ghostEntity,index)
                --连线，从后向前连，清理ghost时特效也会删
                self:_PlayLineEffect(TT,world,ghostEntity,lastEntity)
                lastEntity = ghostEntity
            end
            lastPos = pickPos
        end
    end
end
function SkillPreviewYeliyaRefreshPickGhostInstruction:_PlayLineEffect(TT,world,fromEntity,toEntity)
    if not self._lineEffectID then
        return
    end
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type EffectLineRendererComponent
    local effectLineRenderer = fromEntity:EffectLineRenderer()
    if not effectLineRenderer then
        fromEntity:AddEffectLineRenderer()
        effectLineRenderer = fromEntity:EffectLineRenderer()
    end
    ---@type EffectHolderComponent
    local effectHolderCmpt = fromEntity:EffectHolder()
    if not effectHolderCmpt then
        fromEntity:AddEffectHolder()
        effectHolderCmpt = fromEntity:EffectHolder()
    end
    local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[self._lineEffectID]
    local effect
    if effectEntityIdList then
        effect = world:GetEntityByID(effectEntityIdList[1])
    end
    if not effect then
        --需要创建连线特效
        effect = effectService:CreateEffect(self._lineEffectID, fromEntity)
        effectHolderCmpt:AttachPermanentEffect(effect:GetID())
    end

    --等待一帧才有View()
    -- YIELD(TT)

    --获取特效GetGameObject上面的LineRenderer组件
    local go = effect:View():GetGameObject()
    local renderers
    renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)

    local fromEntityViewRoot = fromEntity:View().ViewWrapper.GameObject.transform
    local fromEntityRoot = GameObjectHelper.FindChild(fromEntityViewRoot, self._bindPos)

    local toEntityViewRoot = toEntity:View().ViewWrapper.GameObject.transform
    local toEntityRoot = GameObjectHelper.FindChild(toEntityViewRoot, self._bindPos)
    local fromEntityID = fromEntity:GetID()
    local toEntityID = toEntity:GetID()
    effectLineRenderer:InitEffectLineRenderer(
        fromEntityID,
        fromEntityRoot,
        toEntityRoot,
        fromEntityViewRoot,
        renderers,
        effect:GetID()
    )
    effectLineRenderer:SetEffectLineRendererShow(fromEntityID, true)
    effectLineRenderer:SetTargetEntityID(toEntityID)
    effectLineRenderer:SetTargetRootOff(Vector3(0,0.001,0))
end
---机关头顶上的UI显示 （炮台 炸弹）
---@param entity Entity
function SkillPreviewYeliyaRefreshPickGhostInstruction:_CreateIndexNumHeadShow(TT,world,entity,index)
    ---@type RenderEntityService
    local entityService = world:GetService("RenderEntity")

    local roundInfoEntity = entityService:CreateRenderEntity(EntityConfigIDRender.HeadTrapRoundInfo)
    roundInfoEntity:ReplaceAsset(NativeUnityPrefabAsset:New("hud_yeliya_ghost_index_info.prefab"))
    roundInfoEntity:AddHUD()
    --临时
    local tmpType = TrapHeadShowType.HeadShowLevel
    local tmpParam = {levelTrapNum=1,x=0,y=0,z=0}
    entity:ReplaceTrapRoundInfoRender(roundInfoEntity:GetID(), tmpType, tmpParam)
    YIELD(TT)
    ---@type TrapRoundInfoRenderComponent
    local roundRender = entity:TrapRoundInfoRender()
    if roundRender then
        local round_entity_id = roundRender:GetRoundInfoEntityID()
        local round_entity = world:GetEntityByID(round_entity_id)
        if round_entity then
            local num = index
            local go = round_entity:View().ViewWrapper.GameObject
            local uiview = go:GetComponent("UIView")

            if uiview and num then
                local numText = uiview:GetUIComponent("UILocalizationText", "LevelNumText")
                if numText then
                    numText:SetText(num)
                end
            end
            roundRender:SetIsShow(true)
            round_entity:SetViewVisible(true)
            --强制刷新一次
            ---@type RenderEntityService
            local renderEntityService = world:GetService("RenderEntity")
            renderEntityService:SetHudPosition(entity, round_entity, roundRender:GetOffset())
        end
    end
end