require("sp_base_inst")
---播放全部配置格子转色预览效果，不支持后一个转色依靠前一个转色结果的情况
_class("SkillPreviewPlayAllScopeConvertGridInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayAllScopeConvertGridInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayAllScopeConvertGridInstruction = SkillPreviewPlayAllScopeConvertGridInstruction

function SkillPreviewPlayAllScopeConvertGridInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayAllScopeConvertGridInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService =  self._world:GetService("PreviewCalcEffect")
    ---@type SkillConvertGridElementEffectParam[]
    local effectList = previewContext:GetEffectsByType(SkillEffectType.ConvertGridElement)
    local totalBlockPosList = {}
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type PreviewConvertElementComponent
    local previewConvertElementCmpt = casterEntity:PreviewConvertElement()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---TODO 把这个组件干掉
    if not previewConvertElementCmpt then
        casterEntity:AddPreviewConvertElement()
        previewConvertElementCmpt = casterEntity:PreviewConvertElement()
    end
    local needRecreateList = {}
    for i, v in ipairs(effectList) do
        local effectParam =previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.ConvertGridElement,v)
        local result = previewEffectCalcService:CalcConvertGridElement(casterEntity,scopeGridList,effectParam)
        local gridList = result:GetTargetGridArray()
        for _, gridPos in ipairs(gridList) do
            local originalElementType = utilData:FindPieceElement(gridPos)
            previewConvertElementCmpt:AddTempConvertElement(gridPos, originalElementType)
            local entity = previewActiveSkillService:_ReplaceGridRes(result:GetTargetElementType(), gridPos)
            env:SetPieceType(gridPos,result:GetTargetElementType())
            table.insert(needRecreateList, { entity = entity, pos = gridPos })
        end
        table.Vector2Append(totalBlockPosList,result:GetBlockGridArray(),totalBlockPosList)
    end
    local oldPreviewIndex = previewActiveSkillService:GetPreviewIndex()
    -- 等待一帧是为了让转色Color的Ani加载完成，避免卡莲转色Ani播放不完整
    YIELD(TT)
    local newPreviewIndex = previewActiveSkillService:GetPreviewIndex()
    if oldPreviewIndex ~= newPreviewIndex then
        -- 由于已经切换预览，需要回滚上面的操作
        for _, v in ipairs(needRecreateList) do
            self._world:DestroyEntity(v.entity)
        end

        Log.fatal("preview active skill failed ")
        return
    end
    for i, v in ipairs(needRecreateList) do
        local sourceEntity = pieceService:FindPieceEntity(v.pos)
        self._world:DestroyEntity(sourceEntity)
        v.entity:SetLocationHeight(0)
        renderBoardCmpt:SetGridRenderEntityData(v.pos, v.entity)
        pieceService:SetPieceAnimColor(v.pos)

        --处理十字棱镜特效
        trapServiceRender:OnClosePreviewPrismEffectTrap(v.pos)
    end

    --锁格子动画
    if totalBlockPosList then
        for _, gridPos in ipairs(totalBlockPosList) do
            local es = env:GetEntitiesAtPos(
                    gridPos,
                    function(e)
                        return e:TrapRender() and e:TrapRender():GetTrapRender_IsLockedGrid()
                    end
            )
            local lockGridTrap = es[1]
            if lockGridTrap then
                local go = lockGridTrap:View():GetGameObject()
                local u3dAnimCmpt = go:GetComponent(typeof(UnityEngine.Animation))
                if lockGridTrap:TrapID():GetTrapID() == BattleConst.LockGridTrapID then
                    u3dAnimCmpt:Play("eff_2000521_lock_red01")
                else
                    u3dAnimCmpt:Play("eff_2000521_lock_red")
                end
            end
        end
    end
end
