--[[------------------------------------------------------------------------------------------
    2019-12-12 韩玉信添加
    SkillEffectResult_ShowWarningArea : 显示特定技能的预警范围
]] --------------------------------------------------------------------------------------------

---@class SkillEffectResult_ShowWarningArea: SkillEffectResultBase
_class("SkillEffectResult_ShowWarningArea", SkillEffectResultBase)
SkillEffectResult_ShowWarningArea = SkillEffectResult_ShowWarningArea

function SkillEffectResult_ShowWarningArea:Constructor()
    self.m_listPosWarning = {} --预警范围
end

function SkillEffectResult_ShowWarningArea:GetEffectType()
    return SkillEffectType.ShowWarningArea
end

function SkillEffectResult_ShowWarningArea:GetWarningPosList()
    return self.m_listPosWarning
end

function SkillEffectResult_ShowWarningArea:GetCenterList()
    return self.m_Centerlist
end

---@param effectParam SkillEffectParam_ShowWarningArea
function SkillEffectResult_ShowWarningArea:ComputeWarningArea(world, casterEntity, effectParam)
    local centerType = effectParam:GetWarningCenterType()
    local posCaster = casterEntity:GridLocation().Position
    local casterArea = {}
    self.m_Centerlist = {}
    if centerType == ShowWarningCenterType.CanUseCenterArray then
        local centerArray = effectParam:GetCanUseCenterArray()
        local area = casterEntity:BodyArea():GetArea()
        local location = casterEntity:GridLocation().Position
        -- --寻找第一个可以使用的位置
        for i = 1, #centerArray do
            local pos = centerArray[i]
            local canUse = true
            for i, p in ipairs(area) do
                if location.x + p.x == pos.x and location.y + p.y == pos.y then
                    canUse = false
                    break
                end
            end
            if canUse then
                ---@type Vector2
                posCaster = Vector2(pos.x, pos.y)
                break
            end
        end
        for i, p in ipairs(area) do
            casterArea[#casterArea + 1] = Vector2(posCaster.x + p.x, posCaster.y + p.y)
        end
        self.m_Centerlist[#self.m_Centerlist + 1] = posCaster
    elseif centerType == ShowWarningCenterType.Self then
        posCaster = casterEntity:GridLocation().Position
    end

    local warningSkillID = effectParam:GetWarningSkillID()

    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(warningSkillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    local scapeResult = utilScopeSvc:CalcSkillScope(skillConfigData, posCaster, casterEntity)
    if effectParam:GetValidArea() then
        self.m_listPosWarning = scapeResult:GetAttackRange()
    else
        self.m_listPosWarning = scapeResult:GetWholeGridRange()
    end

    ---目前仅支持最多2个技能的预警区显示 如果需要更多可以将技能ID的参数类型改为table
    warningSkillID = effectParam:GetWarningSkillID2()
    if warningSkillID then
        local scapeResult = utilScopeSvc:CalcSkillScope(skillConfigData, posCaster, casterEntity)
        local additionalArea = {}
        if effectParam:GetValidArea() then
            additionalArea = scapeResult:GetAttackRange()
        else
            additionalArea = scapeResult:GetWholeGridRange()
        end
        for i = 1, #additionalArea do
            table.insert(self.m_listPosWarning, additionalArea[i])
        end
    end

    local isContainCasterArea = effectParam:IsContainCasterArea()
    if isContainCasterArea then
        for _, pos in ipairs(casterArea) do
            table.insert(self.m_listPosWarning, pos)
        end
    end

    local isValidPiecePosList = {}
    --删除棋盘外的格子
    ---@type BoardServiceLogic
    local boardServiceLogic = world:GetService("BoardLogic")
    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    for _, pos in ipairs(self.m_listPosWarning) do
        if
            utilData:IsValidPiecePos(pos) and
                not boardServiceLogic:IsPosBlock(pos, BlockFlag.Skill | BlockFlag.SkillSkip)
         then
            table.insert(isValidPiecePosList, pos)
        end
    end

    self.m_listPosWarning = isValidPiecePosList
end
