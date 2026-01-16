--[[--------------------------------------------
    ChainPreviewMonsterBehaviorSystem_Render  连线预览中显示一些怪物的特殊行为
--]] -------------------------------------------

---@class ChainPreviewMonsterBehaviorSystem_Render :Object
_class("ChainPreviewMonsterBehaviorSystem_Render", Object)
ChainPreviewMonsterBehaviorSystem_Render = ChainPreviewMonsterBehaviorSystem_Render

function ChainPreviewMonsterBehaviorSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    self._skillCalculater = SkillScopeCalculator:New(utilScopeSvc)

    ---@type RenderEntityService
    self._renderEntityService = world:GetService("RenderEntity")

    ---@type EntityPoolServiceRender
    self._entityPoolServiceRender = world:GetService("EntityPool")
end

function ChainPreviewMonsterBehaviorSystem_Render:Execute()
    local reBoard = self._world:GetRenderBoardEntity()
    if reBoard == nil then
        return
    end

    ---@type ChainPreviewMonsterBehaviorComponent
    local chainPreviewMonsterBehaviorCmpt = reBoard:ChainPreviewMonsterBehavior()
    if not chainPreviewMonsterBehaviorCmpt then
        return
    end

    local previewMonsterRange = chainPreviewMonsterBehaviorCmpt:GetPreviewMonsterRange()
    if table.count(previewMonsterRange) == 0 then
        return
    end

    local needRefresh = chainPreviewMonsterBehaviorCmpt:GetNeedRefresh()
    if not needRefresh then
        return
    end

    --0也要刷新成关
    local chainPath = chainPreviewMonsterBehaviorCmpt:GetChainPath()
    -- if not chainPath or table.count(chainPath) == 0 then
    --     return
    -- end

    --显示怪物预警范围
    for entityID, skillID in pairs(previewMonsterRange) do
        local entity = self._world:GetEntityByID(entityID)
        if entity then
            local posSelf = entity:GetGridPosition()
            local bodyArea = entity:BodyArea():GetArea()

            ---@type SkillConfigData
            local skillConfigData = self._configService:GetSkillConfigData(skillID)

            ---@type SkillScopeResult
            local skillResult = self._skillCalculater:CalcSkillScope(skillConfigData, posSelf, Vector2(0, 1), bodyArea)
            local posList = skillResult:GetAttackRange()
            -- local match = table.icontains(posList, curMovePos)

            local showArea = true
            if table.count(chainPath) == 0 then
                showArea = false
            end
            for _, grid in ipairs(chainPath) do
                if not table.intable(posList, grid) then
                    showArea = false
                    break
                end
            end

            local outlineEntityList = chainPreviewMonsterBehaviorCmpt:GetOutlineEntityList(entityID)

            if showArea then
                if not outlineEntityList then
                    outlineEntityList =
                        self._renderEntityService:CreateAreaOutlineEntity(posList, EntityConfigIDRender.WarningArea)
                    for i, outlineEntity in ipairs(outlineEntityList) do
                        outlineEntity:ReplaceDamageWarningAreaElement(entityID, EntityConfigIDRender.WarningArea)
                    end

                    chainPreviewMonsterBehaviorCmpt:SetOutlineEntityList(entityID, outlineEntityList)
                end
            else
                if outlineEntityList and table.count(outlineEntityList) > 0 then
                    for i, outlineEntity in ipairs(outlineEntityList) do
                        ---@type DamageWarningAreaElementComponent
                        local cmpt = outlineEntity:DamageWarningAreaElement()
                        cmpt:ClearOwnerEntityID()
                        self._entityPoolServiceRender:DestroyCacheEntity(
                            outlineEntity,
                            EntityConfigIDRender.WarningArea
                        )
                    end
                end

                chainPreviewMonsterBehaviorCmpt:SetOutlineEntityList(entityID, nil)
            end
        end
    end

    --刷新一次显示后 清理数据
    chainPreviewMonsterBehaviorCmpt:SetNeedRefresh(false)
end
