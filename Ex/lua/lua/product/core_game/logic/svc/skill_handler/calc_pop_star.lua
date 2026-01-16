--[[
    PopStar = 208, ---消灭星星玩法中的消除格子
]]
---@class SkillEffectCalc_PopStar: Object
_class("SkillEffectCalc_PopStar", Object)
SkillEffectCalc_PopStar = SkillEffectCalc_PopStar

function SkillEffectCalc_PopStar:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PopStar:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type SkillEffectPopStarParam
    local popStarParam = skillEffectCalcParam:GetSkillEffectParam()
    local skillRange = skillEffectCalcParam:GetSkillRange()

    ---获取消除的格子列表
    ---@type Vector2[]
    local pieceList = self:_GetPopPieceList(popStarParam, skillRange)
    if not pieceList or #pieceList == 0 then
        return
    end

    ---获取消除结果
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    ---@type DataPopStarResult
    local dataPopResult = popStarSvc:CalculatePopPieces(pieceList)

    local result = SkillEffectPopStarResult:New(dataPopResult)
    return { result }
end

---@param popStarParam SkillEffectPopStarParam
---@param skillRange Vector2[]
function SkillEffectCalc_PopStar:_GetPopPieceList(popStarParam, skillRange)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---获取对应对应属性的格子
    local pieceTypeList = popStarParam:GetPieceTypeList()
    local matchTypePosList = {}
    for _, pos in ipairs(skillRange) do
        local pieceType = utilDataSvc:GetPieceType(pos)
        if table.icontains(pieceTypeList, pieceType) and not table.icontains(matchTypePosList, pos) then
            matchTypePosList[#matchTypePosList + 1] = pos
        end
    end
    if #matchTypePosList == 0 then
        return
    end

    local popCount = popStarParam:GetPopCount()
    local countRandomTab = popStarParam:GetCountRandomTab()
    ---返回范围内属性匹配的所有格子
    if not popCount and not countRandomTab then
        return matchTypePosList
    end

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    if countRandomTab then
        ---随机格子数量
        local min = countRandomTab.min
        local max = countRandomTab.max
        popCount = randomSvc:LogicRand(min, max)
    end

    ---属性匹配的格子数小于所需数量
    if popCount >= #matchTypePosList then
        return matchTypePosList
    end

    ---随机或按顺序
    local posList = {}
    local needRandom = popStarParam:NeedRandom()
    if needRandom then
        while #posList < popCount do
            local index = randomSvc:LogicRand(1, #matchTypePosList)
            posList[#posList + 1] = matchTypePosList[index]
            table.remove(matchTypePosList, index)
        end
    else
        posList = table.sub(matchTypePosList, 1, popCount)
    end
    return posList
end
