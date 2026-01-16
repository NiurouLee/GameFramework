require("sp_base_inst")

_class("SkillPreviewInitArrowByScopeInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewInitArrowByScopeInstruction: SkillPreviewBaseInstruction
SkillPreviewInitArrowByScopeInstruction = SkillPreviewInitArrowByScopeInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewInitArrowByScopeInstruction:DoInstruction(TT,casterEntity,previewContext)
	local world = previewContext:GetWorld()

    ---@type UtilScopeCalcServiceShare
	local utilScopeSvc = world:GetService("UtilScopeCalc")
    	---@type Entity
	local renderBoardEntity = world:GetRenderBoardEntity()
	---@type PickUpTargetComponent
	local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    	---@type ConfigService
	local configService = world:GetService("Config")
    	---@type SkillConfigData
	local skillConfigData = configService:GetSkillConfigData(activeSkillID, casterEntity)

    ---@type Vector2[]
	local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, casterEntity)
	---@type Vector2[]
	local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, casterEntity)

    local finalGridList = {}
    for _, v2 in ipairs(validGridList) do
        if not table.icontains(invalidGridList, v2) then
            table.insert(finalGridList, v2)
        end
    end

    local v2Center = previewContext:GetCasterPos()

	---@type PreviewActiveSkillService
	local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    local tmpDirMap = {}

    for _, v2 in ipairs(finalGridList) do
        local v2Relative = v2 - v2Center
        local relativeX = v2Relative.x
        local relativeY = v2Relative.y
        if relativeX > 0 then
            if relativeY > 0 then
                tmpDirMap[2] = 2
            elseif relativeY < 0 then
                tmpDirMap[4] = 4
            else
                tmpDirMap[3] = 3
            end
        elseif relativeX < 0 then
            if relativeY > 0 then
                tmpDirMap[8] = 8
            elseif relativeY < 0 then
                tmpDirMap[6] = 6
            else
                tmpDirMap[7] = 7
            end
        else
            if relativeY > 0 then
                tmpDirMap[1] = 1
            elseif relativeY < 0 then
                tmpDirMap[5] = 5
            end
        end
    end

    local tDirection = {}
    -- 顺序无关
    for _, directionIndex in pairs(tmpDirMap) do
        table.insert(tDirection, directionIndex)
    end

    previewActiveSkillService:ShowPickUpArrow(tDirection,nil,casterEntity:GetGridPosition())
end
