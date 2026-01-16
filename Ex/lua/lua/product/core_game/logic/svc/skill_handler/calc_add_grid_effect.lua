--[[
    AddGridEffect = 6, --给格子增加特殊效果(棱镜)
]]
---@class SkillEffectCalc_AddGridEffect: Object
_class("SkillEffectCalc_AddGridEffect", Object)
SkillEffectCalc_AddGridEffect = SkillEffectCalc_AddGridEffect

function SkillEffectCalc_AddGridEffect:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddGridEffect:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillAddGridEffectParam
    local skillGridEffectParam = skillEffectCalcParam.skillEffectParam
    local gridEffectType = skillGridEffectParam:GetTargetGridEffectType()
    local gridConvertType = skillGridEffectParam:GetGridConvertType()
    local summonTrap = skillGridEffectParam:GetSummonTrap()
    ---若添加棱镜效果的格子为禁止转色的万色格子，则忽略转色
    local ignoreConvertForAny = skillGridEffectParam:GetIgnoreConvertForAny()

    local gridList = skillEffectCalcParam.skillRange
    local casterEntityID = skillEffectCalcParam.casterEntityID
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    ---@type BoardServiceLogic
    local boardServiceL = self._world:GetService("BoardLogic")
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local tConvertInfo = {}

    local posList = table.cloneconf(gridList)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for _, pos in ipairs(posList) do
        local samePosTraps = utilData:GetTrapsAtPos(pos)
        if #samePosTraps > 0 then
            for _, e in ipairs(samePosTraps) do
                ---@type TrapComponent
                local trapCmpt = e:Trap()
                if trapCmpt:GetTrapType() == TrapType.GapTileTrap then
                    table.removev(gridList, pos)
                end
            end
        end
    end
    if #gridList == 0 then
        return
    end

    if gridConvertType then
        for _, pos in ipairs(gridList) do
            local nOldColor = utilData:FindPieceElement(pos)
            if ignoreConvertForAny and self:IsForbidConvertAndTypeAny(pos) then
                -- body
            else
                local convertInfo = NTGridConvert_ConvertInfo:New(pos, nOldColor, gridConvertType)
                table.insert(tConvertInfo, convertInfo)
            end
        end
    end

    local traps = {}
    local gridConvertTypes = {}
    for i = 1, #gridList do
        local gridPos = gridList[i]
        local pt = board:GetPieceType(gridPos)
        if gridConvertType and gridConvertType ~= pt then
            if ignoreConvertForAny and self:IsForbidConvertAndTypeAny(gridPos) then
                -- body
            else
                boardServiceL:SetPieceTypeLogic(gridConvertType, gridPos)
                gridConvertTypes[Vector2.Pos2Index(gridPos)] = gridConvertType
            end
        end

        if summonTrap and summonTrap ~= 0 then
            --棱镜出场技会修改逻辑数据
            local eTrap = trapServiceLogic:CreateTrap(summonTrap, gridPos, Vector2(0, 1), false, nil, casterEntity)
            if eTrap then
                traps[Vector2.Pos2Index(gridPos)] = eTrap:GetID()
            end
        end
    end
    ---@type NTGridConvert
    local nt = NTGridConvert:New(casterEntity, tConvertInfo)
    nt:SetConvertEffectType(SkillEffectType.AddGridEffect)
    nt:SetSkillType(skillGridEffectParam:GetSkillType())
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(nt)

    local skillConvertEffectResult = SkillAddGridEffectResult:New(gridList, gridConvertTypes, traps)
    return skillConvertEffectResult
end

function SkillEffectCalc_AddGridEffect:IsForbidConvertAndTypeAny(gridPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local isAnyPiece = utilDataSvc:GetPieceType(gridPos) == PieceType.Any
    local isBlock = utilDataSvc:IsPosBlock(gridPos, BlockFlag.ChangeElement)

    return isAnyPiece and isBlock
end
