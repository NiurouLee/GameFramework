require("sp_base_inst")

---专门为脚下格子做的转色预览指令

_class("SkillPreviewPlayCasterPosConvertInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterPosConvertInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterPosConvertInstruction = SkillPreviewPlayCasterPosConvertInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterPosConvertInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService =  self._world:GetService("PreviewCalcEffect")
    local effectList = previewContext:GetEffect(SkillEffectType.ConvertGridElement)
    local effectParam =previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.ConvertGridElement,effectList)
    local result = previewEffectCalcService:CalcConvertGridElement(casterEntity,scopeGridList,effectParam)

    local gridPos = casterEntity:GetGridPosition()

    local attackRange = previewContext:GetScopeResult()

    if not table.icontains(attackRange, gridPos) then
        return
    end

    local env = self._world:GetPreviewEntity():PreviewEnv()
    if env:GetConvertPlayerPosGridEffectEntityID() then
        local oldEntityID = env:GetConvertPlayerPosGridEffectEntityID()
        local e = self._world:GetEntityByID(oldEntityID)
        if e then
            self._world:DestroyEntity(e)
        end
        env:SetConvertPlayerPosGridEffectEntityID(nil)
    end

    local pieceType = result:GetTargetElementType()

    ---@type BoardServiceRender
    local rsvcBoard = self._world:GetService("BoardRender")
    local gridPrefabPath = rsvcBoard:_GetGridPrefabPath(pieceType)

    ---@type EffectService
    local fxsvc = self._world:GetService("Effect")
    local e = fxsvc:CreateEffectEntity()
    e:ReplaceAsset(NativeUnityPrefabAsset:New(gridPrefabPath))
    e:SetGridPosition(gridPos)
    e:SetPosition(gridPos)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    e:AddReplaceMaterialComponent(gridMatPath)

    ---Bug：MSG64189 卡莲预览(点格子、取消、发动)反复快速点，特效遗留
    ---删除此特效对象的ID是在YIELD之后设置的，以上操作可能造成ID还未设置，就已经执行了取消
    ---导致取消时无法获取到此特效对象实体
    env:SetConvertPlayerPosGridEffectEntityID(e:GetID())

    YIELD(TT)

    local effView = e:View()
    if not effView then
        return
    end

    local effectObj = effView:GetGameObject()
    if (not effectObj) or (tostring(effectObj) == "null") then
        return
    end
    
    local pieceAnimData = PieceAnimationData:New()
    local name = pieceAnimData:GetAnimationName("Color")

    local gridGameObj = e:View().ViewWrapper.GameObject
    local csAnimation = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
    csAnimation:Play(name)

    --env:SetConvertPlayerPosGridEffectEntityID(e:GetID())
end

_class("SkillPreviewRemoveCasterPosConvertInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewRemoveCasterPosConvertInstruction: SkillPreviewBaseInstruction
SkillPreviewRemoveCasterPosConvertInstruction = SkillPreviewRemoveCasterPosConvertInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewRemoveCasterPosConvertInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()

    local env = self._world:GetPreviewEntity():PreviewEnv()
    local eid = env:GetConvertPlayerPosGridEffectEntityID()
    if not eid then
        return
    end

    local e = self._world:GetEntityByID(eid)
    if not e then
        return
    end

    self._world:DestroyEntity(e)
end
