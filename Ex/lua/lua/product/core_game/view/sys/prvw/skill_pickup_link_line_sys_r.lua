--[[----------------------------------------------------------
    定制化的点选效果 针对 蒂娜 的技能效果 定制化处理逻辑
	连线选格子
]]
------------------------------------------------------------
---@class SkillPickUpLinkLineSystem_Render:ReactiveSystem
_class("SkillPickUpLinkLineSystem_Render", ReactiveSystem)
SkillPickUpLinkLineSystem_Render = SkillPickUpLinkLineSystem_Render

---@param world MainWorld
function SkillPickUpLinkLineSystem_Render:Constructor(world)
    self._world = world
    self._pickUpType = nil

    self._pickUpNum = 0
end

---@param world World
function SkillPickUpLinkLineSystem_Render:GetTrigger(world)
    local c = Collector:New(
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
function SkillPickUpLinkLineSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()

    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.LinkLine then
        return true
    end
    return false
end

function SkillPickUpLinkLineSystem_Render:ExecuteEntities(entities)
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    local isStartPreview = inputCmpt:IsPreviewActiveSkill()
    for i = 1, #entities do
        if isStartPreview then
            self:DoLinkLine(entities[i])
        else
            self:DoPickUp(entities[i])
        end
    end
end

function SkillPickUpLinkLineSystem_Render:DoLinkLine(entity)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    if not previewEntity then
        return
    end
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()

    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    self._pickUpType = pickUpTargetCmpt:GetPickUpTargetType()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petPstID = pickUpTargetCmpt:GetPetPstid()
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    local petEntity = self._world:GetEntityByID(petEntityId)
    if not petEntity then
        ---施法者并非光灵时
        local entityID = pickUpTargetCmpt:GetEntityID()
        petEntity = self._world:GetEntityByID(entityID)
    end

    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    ---可连线的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1]) or 0
    self._pickUpNum = pickUpNum
    local canLinkMonster = tonumber(skillConfigData._pickUpParam[3]) or 0

    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    previewPickUpComponent:ClearGridPos()
    previewPickUpComponent:AddGridPosList(chainPath)

    ---可连线至怪物脚下，则检查最后一个连线格子是否连到怪物
    local isLinkMonster = false
    if #chainPath > 1 then
        if canLinkMonster == 1 then
            local lastPos = chainPath[#chainPath]
            if utilDataSvc:GetMonsterAtPos(lastPos) then
                isLinkMonster = true
            end
        end
    end

    self:UpdateUI(previewPickUpComponent, isLinkMonster)
end

function SkillPickUpLinkLineSystem_Render:DoPickUp(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    self._pickUpType = pickUpTargetCmpt:GetPickUpTargetType()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petPstID = pickUpTargetCmpt:GetPetPstid()
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    local petEntity = self._world:GetEntityByID(petEntityId)
    if not petEntity then
        ---施法者并非光灵时
        local entityID = pickUpTargetCmpt:GetEntityID()
        petEntity = self._world:GetEntityByID(entityID)
    end

    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    ---可连线的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1]) or 0
    self._pickUpNum = pickUpNum

    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    previewPickUpComponent:ClearGridPos()
    --previewPickUpComponent:SetIgnorePickCheck(true)

    self:UpdateUI(previewPickUpComponent, false)

    local casterPos = petEntity:GetGridPosition()
    --点击的是光灵脚下
    if pickUpGridPos == casterPos then
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        utilScopeSvc:ChangeGameFSMState2PickUp()
        ---@type InputComponent
        local inputCmpt = self._world:Input()
        inputCmpt:SetPreviewActiveSkill(true)
    else
        --点击非光灵脚下
        ---@type PreviewActiveSkillService
        local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
        if previewActiveSkill then
            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
        end
    end
end

---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpLinkLineSystem_Render:UpdateUI(previewPickUpComponent, isLinkMonster)
    local gridCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
    --去除连线起点（玩家所在位置）
    gridCount = gridCount - 1

    local canCast = false

    --计算剩余连线格子
    local leftNum = self._pickUpNum
    if gridCount > 0 then
        canCast = true
        leftNum = leftNum - gridCount
    end

    --连线到怪
    if isLinkMonster then
        canCast = true
        leftNum = 0
    end

    if leftNum < 0 then
        leftNum = 0
    end

    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, leftNum)
    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, canCast)
end
