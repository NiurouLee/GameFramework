--[[----------------------------------------------------------
    SkillPickUpChainInstructionSystem_Render 指令化的PickUPSystem
]] ------------------------------------------------------------
---@class SkillPickUpChainInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpChainInstructionSystem_Render", ReactiveSystem)
SkillPickUpChainInstructionSystem_Render = SkillPickUpChainInstructionSystem_Render

---@param world World
function SkillPickUpChainInstructionSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function SkillPickUpChainInstructionSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PickUpTarget)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function SkillPickUpChainInstructionSystem_Render:Filter(entity)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    if not previewEntity then 
        return false
    end
    ---@type PreviewChainSkillComponent
    local prvwCmpt = previewEntity:PreviewChainSkill()
    local enablePickUp = prvwCmpt:GetPickUpTargetEnalbe()
    if not enablePickUp then 
        return false
    end

    local cPickUpTarget = entity:PickUpTarget()
    local skillHandleType = cPickUpTarget:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.ChainInstruction then
        return true
    end
    return false
end

function SkillPickUpChainInstructionSystem_Render:ExecuteEntities(entities)
    ---@type PreviewActiveSkillService
    local sPreviewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewActiveSkillService
    local sPreviewSkill = self._world:GetService("PreviewActiveSkill")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local posPickUpSafe = pickUpTargetCmpt:GetCurPickUpGridSafePos()
    if posPickUpSafe then
        local isValid, isGuide = self._world:GetService("Guide"):IsValidGuidePiecePos(posPickUpSafe.x, posPickUpSafe.y)
        if not isValid then
            posPickUpSafe = nil
        else
            if isGuide then
                self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
            end
        end
    end
    if posPickUpSafe then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveUIPreviewChainBtnOK, true)
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveUIPreviewChainBtnOK, false)
        return
    end
    --队长虚影
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    local casterEntity = teamEntity:GetTeamLeaderPetEntity()
    GameGlobal.TaskManager():CoreGameStartTask(self.PlayLeaderPreview, self, casterEntity, posPickUpSafe)
    --连锁轮播
    local petIds, skillIds = sPreviewSkill:GetChianAttackPetIds()
    if petIds and table.count(petIds) > 0 then
        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        previewEntity:ReplacePreviewChainSkill(petIds, skillIds, posPickUpSafe,true)
    end
end

function SkillPickUpChainInstructionSystem_Render:PlayLeaderPreview(TT, casterEntity, posPickUpSafe)
    ---@type PreviewActiveSkillService
    local sPreviewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewActiveSkillService
    local sPreviewSkill = self._world:GetService("PreviewActiveSkill")
    sPreviewSkill:StopPreviewChainSkill(TT)
    local skillPreviewParamInstruction = SkillPreviewParamInstruction:New({})
    local instructionSet =
        skillPreviewParamInstruction:_ParseInstructionSet(BattleConst.DimensionPreviewInstructionSetId)
    if instructionSet then
	    ---@type SkillPreviewContext
        local previewContext = SkillPreviewContext:New(self._world, casterEntity)
        previewContext:SetPickUpPos(posPickUpSafe)
        sPreviewActiveSkill:DoPreviewInstruction(TT, instructionSet, casterEntity, previewContext)
    end
end
