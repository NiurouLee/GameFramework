--[[

]]
require("calc_base")

---@class SkillEffectCalc_PickUpGridTogether: SkillEffectCalc_Base
_class("SkillEffectCalc_PickUpGridTogether", SkillEffectCalc_Base)
SkillEffectCalc_PickUpGridTogether = SkillEffectCalc_PickUpGridTogether

function SkillEffectCalc_PickUpGridTogether:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PickUpGridTogether:DoSkillEffectCalculator(skillEffectCalcParam)

    ---@type SkillEffectParam_PickUpGridTogether
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    local skillRange = skillEffectCalcParam.skillRange
    local rangeCount = #skillRange
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type ActiveSkillPickUpComponent
    local component = casterEntity:ActiveSkillPickUpComponent()
    local pickVec = component:GetAllValidPickUpGridPos()
    local pickupPos = pickVec[1]
    local pickupIndex = self:FindPickIndex(skillRange, pickupPos)

    local pieceType = skillEffectParam:GetGridType()
    ---@type PickUpGridTogetherData[]
    local gridDataList = self:BuildData(skillRange)
    local replaceIndex = pickupIndex
    ---从下往上交换
    for i = pickupIndex , rangeCount do
        ---@type PickUpGridTogetherData
        local gridData = gridDataList[i]
        --找到一个可以聚拢的格子
        if pieceType == gridData:GetGridType() and
                gridData:IsCanConvert() and
                i ~= replaceIndex then
            local tmpData = gridData
            Log.info("ReplaceIndex:",replaceIndex,"Type:",gridData:GetGridType()," GridPos:",gridData:GetGridPos())
            local j =replaceIndex
            while j<=i do
                local tmpR = self:FindCanTogetherGrid(gridDataList, j, i,1)
                if tmpR then
                    Log.info("DownToUp Index:",tmpR,"Pos:",skillRange[tmpR]," NewType:",tmpData:GetGridType())
                    local tempGridData = gridDataList[tmpR]
                    gridDataList[tmpR] = tmpData
                    tmpData = tempGridData
                    j =tmpR
                end
                j = j + 1
            end
            replaceIndex = replaceIndex+1
        end
    end
    ---从下往上交换
    replaceIndex = pickupIndex
    for i = pickupIndex , 1,-1 do
        ---@type PickUpGridTogetherData
        local gridData = gridDataList[i]
        --找到一个可以聚拢的格子
        if pieceType == gridData:GetGridType() and
                gridData:IsCanConvert() and
                i ~= replaceIndex then
            Log.info("ReplaceIndex:",replaceIndex,"GridPos:",gridData:GetGridPos())
            local tmpData = gridData
            local j = replaceIndex
            while j>=i do
                local tmpR = self:FindCanTogetherGrid(gridDataList,j,i, -1)
                if tmpR then
                    Log.info("UpToDown Index:",tmpR,"Pos:",skillRange[tmpR]," NewType:",tmpData:GetGridType())
                    local tempGridData = gridDataList[tmpR]
                    gridDataList[tmpR] = tmpData
                    tmpData = tempGridData
                    j =tmpR
                end
                j = j - 1
            end
            replaceIndex = replaceIndex -1
        end
    end
    for i, pos in ipairs(skillRange) do
        gridDataList[i]:SetGridPos(pos)
    end
    ---@type SkillEffectResult_PickUpGridTogether
    local results = SkillEffectResult_PickUpGridTogether:New(gridDataList)
    return results
end

---@param gridDataList PickUpGridTogetherData[]
---@param beginIndex number
---@param endIndex number
---@param step number
function SkillEffectCalc_PickUpGridTogether:FindCanTogetherGrid(gridDataList, beginIndex, endIndex,step)
    for i = beginIndex, endIndex,step do
        local gridData = gridDataList[i]
        if gridData:IsCanConvert() then
            return i
        end
    end
end
---@param range Vector2[]
---@param pickPos Vector2
function SkillEffectCalc_PickUpGridTogether:FindPickIndex(range, pickPos)
    for i, v in ipairs(range) do
        if v.x == pickPos.x and v.y == pickPos.y then
            return i
        end
    end
end
---@param skillRange Vector2[]
---@return PickUpGridTogetherData[]
function SkillEffectCalc_PickUpGridTogether:BuildData(skillRange)
    ---@type PickUpGridTogetherData[]
    local ret = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    for i, pos in ipairs(skillRange) do
        local pieceType = utilDataSvc:GetPieceType(pos)
        local canConvert = utilDataSvc:IsPosCanConvertGridElement(pos)
        if pieceType == PieceType.None then
            canConvert = false
        end

        ---@type PickUpGridTogetherData
        local data = PickUpGridTogetherData:New(pieceType, pos, canConvert)
        table.insert(ret, data)

    end
    return ret
end