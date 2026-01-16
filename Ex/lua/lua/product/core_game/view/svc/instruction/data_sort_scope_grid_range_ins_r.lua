---@class GridRangeSortType
GridRangeSortType = {
    None = 0, --不排序，即按顺序一个个格子来
    NearToFar = 1,
    NearToFarFourDirections2x2 = 2, --从进到远 4方向 每4个格子是一个范围
    AbsDistance = 3, --根据绝对距离顺序
    Random = 4, --随机排序
    XSmallToLarge = 5, --从小到大排序（x从1到9）
    YSmallToLarge = 6, --从小到大排序（y从1到9）
    FixedPos = 7, --用于FixedPos范围类型的分组策略
    MultiRandomRange = 8, --用范围效果48的分组
    FarToNear = 9, --从远到近
    BoardCenterToFar = 10, --棋盘中心(5,5)向外扩散
    AbsDistanceForPickUp = 11, --从拾取点根据绝对距离顺序(只做了拾取一个点)
    JieweiZuo = 12, -- 戒卫座专用逻辑：范围内任选1位置，从其他位置中选择距离接近配置值的位置，连成序列后分组
    SpecialScopeResultIndex = 13, --技能范围计算中，根据专属规则进行的排序
    SectorAngle = 14, --艾露玛，扇形区域，按与主方向的夹角排序，每N度一组
    XYSmallToLargeSort = 15, --从左下到右上，x+y相同时，x大的在前
    AbsDistanceForPickUpFirstAndExcludePickUp = 16, --从第一个拾取点根据绝对距离顺序,排除掉所有拾取点
    YLargeToSmall = 17, --从大到小排序（y从9到1）
    NearToFarByPickUp = 18, --从拾取点根据距离顺序
    MAX = 99
}
_enum("GridRangeSortType", GridRangeSortType)

require("base_ins_r")
---@class DataSortScopeGridRangeInstruction: BaseInstruction
_class("DataSortScopeGridRangeInstruction", BaseInstruction)
DataSortScopeGridRangeInstruction = DataSortScopeGridRangeInstruction

function DataSortScopeGridRangeInstruction:Constructor(paramList)
    self._sortType = tonumber(paramList["sortType"])
    local metaParam = paramList["sortParam"]
    if metaParam then
        local arr = string.split(metaParam, "|")
        self._sortParam = arr
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSortScopeGridRangeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type ConfigService
    local sConfig = world:GetService("Config")
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    ---@type RandomServiceRender
    local randomSvc = world:GetService("RandomRender")
    local gridRange, maxRange = {}, 0
    local array = phaseContext._scopeGridList
    if self._sortType == GridRangeSortType.NearToFar then
        gridRange, maxRange = self:_SortGridNearToFar(array, casterEntity:GridLocation().Position)
    elseif self._sortType == GridRangeSortType.FarToNear then
        gridRange, maxRange = self:_SortGridFarToNear(array, casterEntity:GridLocation().Position)
    elseif self._sortType == GridRangeSortType.NearToFarFourDirections2x2 then
        gridRange, maxRange =
        self:_SortGridNearToFarFourDirections2x2(
                array,
                casterEntity:GridLocation().Position,
                casterEntity:BodyArea():GetArea()
        )
    elseif self._sortType == GridRangeSortType.AbsDistance then --根据绝对距离顺序
        gridRange, maxRange = self:_AbsDistanceSort(array, casterEntity:GridLocation().Position)
    elseif self._sortType == GridRangeSortType.Random then --随机排序
        gridRange, maxRange = self:_RandomSort(array, casterEntity:GridLocation().Position,randomSvc)
    elseif self._sortType == GridRangeSortType.XSmallToLarge then --从小到大排序（x从1到9）
        gridRange, maxRange = self:_XSmallToLargeSort(array)
    elseif self._sortType == GridRangeSortType.YSmallToLarge then --从小到大排序（x从1到9）
        gridRange, maxRange = self:_YSmallToLargeSort(array)
    elseif self._sortType == GridRangeSortType.FixedPos then
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        local skillId = skillEffectResultContainer:GetSkillID()
        gridRange, maxRange = self:_FixedPosSort(sConfig, array, skillId)
    elseif self._sortType == GridRangeSortType.MultiRandomRange then
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        local skillId = skillEffectResultContainer:GetSkillID()
        gridRange, maxRange = self:_MultiRandomRangeSort(sConfig, array, skillId)
    elseif self._sortType == GridRangeSortType.BoardCenterToFar then
        local boardCenterPos = utilDataSvc:GetCurBoardCenterPos()
        gridRange, maxRange = self:_SortBoardCenterToFar(array, boardCenterPos)
    elseif self._sortType == GridRangeSortType.AbsDistanceForPickUp then
        --从拾取点根据绝对距离顺序(只做了拾取一个点)
        ---@type RenderPickUpComponent
        local renderPickUpComponent = casterEntity:RenderPickUpComponent()
        ---@type Vector2[]
        local scopeGridList = renderPickUpComponent:GetAllValidPickUpGridPos()
        gridRange, maxRange = self:_AbsDistanceSort(array, scopeGridList[1])
    elseif self._sortType == GridRangeSortType.JieweiZuo then
        gridRange, maxRange = self:_JieweiZuoSort(array)
    elseif self._sortType == GridRangeSortType.SpecialScopeResultIndex then
        local specialScopeResultList = phaseContext:GetSpecialScopeResultList()
        gridRange, maxRange = self:_SpecialScopeIndexSort(specialScopeResultList)
    elseif self._sortType == GridRangeSortType.SectorAngle then
        local casterPos = casterEntity:GridLocation().Position
        ---@type RenderPickUpComponent
        local renderPickUpComponent = casterEntity:RenderPickUpComponent()
        ---@type Vector2[]
        local pickList = renderPickUpComponent:GetAllValidPickUpGridPos()
        gridRange, maxRange =
        self:_SortBySectorAngle(
                array,
                casterPos,
                pickList
        )
    elseif self._sortType == GridRangeSortType.XYSmallToLargeSort then
        gridRange, maxRange = self:_XYSmallToLargeSort(array)
    elseif self._sortType == GridRangeSortType.AbsDistanceForPickUpFirstAndExcludePickUp then
        ---@type RenderPickUpComponent
        local renderPickUpComponent = casterEntity:RenderPickUpComponent()
        ---@type Vector2[]
        local scopeGridList = renderPickUpComponent:GetAllValidPickUpGridPos()
        for i, pos in pairs(scopeGridList) do
            table.removev(array, pos)
        end
        gridRange, maxRange = self:_AbsDistanceSort(array, scopeGridList[1])
    elseif self._sortType == GridRangeSortType.YLargeToSmall then
        gridRange, maxRange = self:_YLargeToSmallSort(array)
    elseif self._sortType == GridRangeSortType.NearToFarByPickUp then
        ---@type RenderPickUpComponent
        local renderPickUpComponent = casterEntity:RenderPickUpComponent()
        ---@type Vector2[]
        local scopeGridList = renderPickUpComponent:GetAllValidPickUpGridPos()
        gridRange, maxRange = self:_SortGridNearToFar(array, scopeGridList[1])
    else
        gridRange, maxRange = self:_NoneSort(array)
    end
        phaseContext:SetScopeGridRange(gridRange, maxRange) --设置效果作用的范围
end

--region None
function DataSortScopeGridRangeInstruction:_NoneSort(gridList)
    if not gridList then
        return
    end
    return {{gridList}}, 1
end
--endregion

--region NearToFar
function DataSortScopeGridRangeInstruction:_SortGridNearToFar(gridList, castPos)
    local leftUpList = {}
    local leftBottomList = {}
    local rightBottomList = {}
    local rightUpList = {}
    local upList = {}
    local bottomList = {}
    local rightList = {}
    local leftList = {}
    local maxGridCount = 0

    for i, pos in pairs(gridList) do
        local dis = pos - castPos
        if dis.x == 0 then --水平方向距离为0
            if dis.y > 0 then --正上方
                table.insert(upList, pos)
            else --正下方
                table.insert(bottomList, pos)
            end
        elseif dis.x > 0 then --在右侧
            if dis.y == 0 then
                table.insert(rightList, pos)
            elseif dis.y > 0 then
                if dis.x > dis.y then
                    table.insert(rightList, pos)
                elseif dis.x == dis.y then
                    table.insert(rightUpList, pos)
                elseif dis.x < dis.y then
                    table.insert(upList, pos)
                end
            elseif dis.y < 0 then
                if dis.x > math.abs(dis.y) then
                    table.insert(rightList, pos)
                elseif dis.x == math.abs(dis.y) then
                    table.insert(rightBottomList, pos)
                elseif dis.x < math.abs(dis.y) then
                    table.insert(bottomList, pos)
                end
            end
        elseif dis.x < 0 then --在左侧
            if dis.y == 0 then
                table.insert(leftList, pos)
            elseif dis.y > 0 then
                if math.abs(dis.x) > dis.y then
                    table.insert(leftList, pos)
                elseif math.abs(dis.x) == dis.y then
                    table.insert(leftUpList, pos)
                elseif math.abs(dis.x) < dis.y then
                    table.insert(upList, pos)
                end
            elseif dis.y < 0 then
                if math.abs(dis.x) > math.abs(dis.y) then
                    table.insert(leftList, pos)
                elseif math.abs(dis.x) == math.abs(dis.y) then
                    table.insert(leftBottomList, pos)
                elseif math.abs(dis.x) < math.abs(dis.y) then
                    table.insert(bottomList, pos)
                end
            end
        end
    end
    --排序
    local cmpNearToFar = function(pos1, pos2)
        local disX1 = math.abs(pos1.x - castPos.x)
        local disY1 = math.abs(pos1.y - castPos.y)
        local disX2 = math.abs(pos2.x - castPos.x)
        local disY2 = math.abs(pos2.y - castPos.y)
        local dis1 = disX1 + disY1
        local dis2 = disX2 + disY2
        return dis1 < dis2
    end
    table.sort(leftBottomList, cmpNearToFar)
    table.sort(rightBottomList, cmpNearToFar)
    table.sort(leftUpList, cmpNearToFar)
    table.sort(rightUpList, cmpNearToFar)

    local convertFunc = function(array)
        local list = {}
        for i = 1, #array do
            local t = {}
            t[1] = array[i]
            list[i] = t
        end
        return list
    end

    leftBottomList = convertFunc(leftBottomList)
    rightBottomList = convertFunc(rightBottomList)
    leftUpList = convertFunc(leftUpList)
    rightUpList = convertFunc(rightUpList)

    local reverseTbale = function(tab)
        local tmp = {}
        for i = 1, #tab do
            local key = #tab
            tmp[i] = table.remove(tab)
        end
        return tmp
    end

    local sortDic = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a < b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end

    --上
    local upDic = {}
    for _, p in pairs(upList) do
        local y = p.y
        if not upDic[y] then
            upDic[y] = {}
        end
        table.insert(upDic[y], p)
    end
    upList = sortDic(upDic)
    --下
    local bottomDic = {}
    for _, p in pairs(bottomList) do
        local y = p.y
        if not bottomDic[y] then
            bottomDic[y] = {}
        end
        table.insert(bottomDic[y], p)
    end
    bottomList = sortDic(bottomDic)
    bottomList = reverseTbale(bottomList)
    --左
    local leftDic = {}
    for _, p in pairs(leftList) do
        local x = p.x
        if not leftDic[x] then
            leftDic[x] = {}
        end
        table.insert(leftDic[x], p)
    end
    leftList = sortDic(leftDic)
    leftList = reverseTbale(leftList)
    --右
    local rightDic = {}
    for _, p in pairs(rightList) do
        local x = p.x
        if not rightDic[x] then
            rightDic[x] = {}
        end
        table.insert(rightDic[x], p)
    end
    rightList = sortDic(rightDic)

    --取最长的方向有多少个格子
    local GetMaxGridCount = function(table, maxGridCount)
        if #table > maxGridCount then
            maxGridCount = #table
        end
        return maxGridCount
    end
    maxGridCount = GetMaxGridCount(upList, maxGridCount)
    maxGridCount = GetMaxGridCount(bottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftBottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightBottomList, maxGridCount)

    local res = {}
    res[1] = leftList
    res[2] = rightList
    res[3] = upList
    res[4] = bottomList
    res[5] = leftUpList
    res[6] = rightUpList
    res[7] = leftBottomList
    res[8] = rightBottomList

    return res, maxGridCount
end
--endregion

function DataSortScopeGridRangeInstruction:_SortGridFarToNear(gridList, castPos)
    local gridRange, maxRange = self:_AbsDistanceSort(gridList, castPos)
    local resultGridRange = self:_ReverseTable(gridRange)

    return resultGridRange, maxRange
end

function DataSortScopeGridRangeInstruction:_ReverseTable(gridRange)
    local tmp = {}
    local tab = gridRange[1]
    for i = 1, #tab do
        local key = #tab
        tmp[i] = table.remove(tab)
    end
    gridRange[1] = tmp
    return gridRange
end

--region NearToFarFourDirections2x2
function DataSortScopeGridRangeInstruction:_SortGridNearToFarFourDirections2x2(gridList, castPos, bodyArea)
    local xTbl = {}
    local yTbl = {}
    for index, vec2 in ipairs(bodyArea) do
        local x = castPos.x + vec2.x
        local y = castPos.y + vec2.y
        table.insert(xTbl, x)
        table.insert(yTbl, y)
    end
    --bodyArea的边界
    local minX = table.min(xTbl)
    local minY = table.min(yTbl)
    local maxX = table.max(xTbl)
    local maxY = table.max(yTbl)

    local upList = {}
    local bottomList = {}
    local rightList = {}
    local leftList = {}
    local maxGridCount = 0

    for i, pos in pairs(gridList) do
        local dis = pos

        local includeX = minX - 1 <= pos.x and pos.x <= maxX + 1
        local includeY = minY - 1 <= pos.y and pos.y <= maxY + 1

        if pos.y > maxY and includeX then
            --上
            table.insert(upList, pos)
        elseif pos.y < minY and includeX then
            --下
            table.insert(bottomList, pos)
        elseif pos.x < minX and includeY then
            --左
            table.insert(leftList, pos)
        elseif pos.x > maxX and includeY then
            --右
            table.insert(rightList, pos)
        end
    end

    --排序
    local bottomStartPosList = {}
    table.insert(bottomStartPosList, Vector2(minX - 0.5, minY - 1.5))
    table.insert(bottomStartPosList, Vector2(maxX + 0.5, minY - 1.5))
    local bottomCenterList = self:_GetBodyAreaCenter(bottomList, bottomStartPosList, Vector2(0, -2))

    local upStartPosList = {}
    table.insert(upStartPosList, Vector2(minX - 0.5, maxY + 1.5))
    table.insert(upStartPosList, Vector2(maxX + 0.5, maxY + 1.5))
    local upCenterList = self:_GetBodyAreaCenter(upList, upStartPosList, Vector2(0, 2))

    local leftStartPosList = {}
    table.insert(leftStartPosList, Vector2(minX - 1.5, minY - 0.5))
    table.insert(leftStartPosList, Vector2(minX - 1.5, maxY + 0.5))
    local leftCenterList = self:_GetBodyAreaCenter(leftList, leftStartPosList, Vector2(-2, 0))

    local rightStartPosList = {}
    table.insert(rightStartPosList, Vector2(maxX + 1.5, minY - 0.5))
    table.insert(rightStartPosList, Vector2(maxX + 1.5, maxY + 0.5))
    local rightCenterList = self:_GetBodyAreaCenter(rightList, rightStartPosList, Vector2(2, 0))

    --取最长的方向有多少个格子
    local GetMaxGridCount = function(table, maxGridCount)
        if #table > maxGridCount then
            maxGridCount = #table
        end
        return maxGridCount
    end
    maxGridCount = GetMaxGridCount(bottomCenterList, maxGridCount)
    maxGridCount = GetMaxGridCount(upCenterList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftCenterList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightCenterList, maxGridCount)

    local res = {}

    res[1] = bottomCenterList
    res[2] = upCenterList
    res[3] = leftCenterList
    res[4] = rightCenterList

    return res, maxGridCount
end
function DataSortScopeGridRangeInstruction:_GetBodyAreaCenter(gridList, startPosList, interval)
    local centerList = {}

    local bodyAreaFix = {}
    table.insert(bodyAreaFix, Vector2(0.5, 0.5))
    table.insert(bodyAreaFix, Vector2(0.5, -0.5))
    table.insert(bodyAreaFix, Vector2(-0.5, 0.5))
    table.insert(bodyAreaFix, Vector2(-0.5, -0.5))

    for i = 1, 5 do
        local centerFix = interval * (i - 1)
        --并行的起点
        for _, pos in pairs(startPosList) do
            --算上每一个间隔后的中点
            local wordCenterPos = pos + centerFix
            --4格子范围都要计算 有一个格子也要添加中心
            for _, bodyArea in pairs(bodyAreaFix) do
                local workPos = pos + bodyArea + centerFix

                if table.intable(gridList, workPos) then
                    if not centerList[i] then
                        centerList[i] = {}
                    end
                    if not table.intable(centerList[i], wordCenterPos) then
                        table.insert(centerList[i], wordCenterPos)
                    end
                end
            end
        end
    end

    return centerList
end
--endregion

--region AbsDistance
function DataSortScopeGridRangeInstruction:_AbsDistanceSort(gridList, castPos)
    local posDic = {}
    for _, pos in pairs(gridList) do
        local dis = Vector2.Distance(castPos, pos)
        if not posDic[dis] then
            posDic[dis] = {}
        end
        table.insert(posDic[dis], pos)
    end

    local sortDicFunc = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a < b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end
    posDic = sortDicFunc(posDic)
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
--endregion

--region Random
---@param randomSvc RandomServiceRender
function DataSortScopeGridRangeInstruction:_RandomSort(gridList, castPos,randomSvc)
    local posDic = {}
    local bShuffle = nil
    if self._sortParam then
        bShuffle = tonumber(self._sortParam[1])
    end
    if bShuffle and bShuffle == 1 then
        local randGrids = {}
        for _, pos in pairs(gridList) do--不确定是不是连续 转一下
            table.insert(randGrids, pos)
        end
        gridList = randomSvc:Shuffle(randGrids)
    end
    for _, pos in pairs(gridList) do
        local t = {}
        table.insert(t, pos)
        table.insert(posDic, t)
    end
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
--endregion

--region SmallToLarge
function DataSortScopeGridRangeInstruction:_XSmallToLargeSort(gridList)
    local posDic = {}
    for _, pos in pairs(gridList) do
        local dis = pos.x
        if not posDic[dis] then
            posDic[dis] = {}
        end
        table.insert(posDic[dis], pos)
    end

    posDic = self:_SmallToLargeSort(posDic)
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
function DataSortScopeGridRangeInstruction:_YSmallToLargeSort(gridList)
    local posDic = {}
    for _, pos in pairs(gridList) do
        local dis = pos.y
        if not posDic[dis] then
            posDic[dis] = {}
        end
        table.insert(posDic[dis], pos)
    end

    posDic = self:_SmallToLargeSort(posDic)
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
---从小到大的排序
function DataSortScopeGridRangeInstruction:_SmallToLargeSort(posDic)
    local sortDicFunc = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a < b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end
    posDic = sortDicFunc(posDic)
    return posDic
end
--endregion

--region LargeToSmall
function DataSortScopeGridRangeInstruction:_YLargeToSmallSort(gridList)
    local posDic = {}
    for _, pos in pairs(gridList) do
        local dis = pos.y
        if not posDic[dis] then
            posDic[dis] = {}
        end
        table.insert(posDic[dis], pos)
    end

    posDic = self:_LargeToSmallSort(posDic)
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
function DataSortScopeGridRangeInstruction:_LargeToSmallSort(posDic)
    local sortDicFunc = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a > b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end
    posDic = sortDicFunc(posDic)
    return posDic
end
--endregion

--region FixedPos
---@param sConfig ConfigService
---@return Vector2[][][], number
function DataSortScopeGridRangeInstruction:_FixedPosSort(sConfig, gridList, skillId)
    --根据技能id拿技能范围参数
    local cfg = sConfig:GetSkillConfigData(skillId)
    local param = cfg:GetSkillScopeParam()
    local count = table.count(param.pos) --特效数
    local cellCount = table.count(gridList) / count
    --构造三维数组
    local posDic = {}
    for i, pos in ipairs(gridList) do
        local mod = (i - 1) // cellCount + 1
        if not posDic[mod] then
            posDic[mod] = {}
        end
        table.insert(posDic[mod], pos)
    end
    local res = {}
    res[1] = posDic
    return res, count
end
--endregion

--region FixedPos
---@param sConfig ConfigService
---@return Vector2[][][], number
function DataSortScopeGridRangeInstruction:_MultiRandomRangeSort(sConfig, gridList, skillId)
    --根据技能id拿技能范围参数
    local cfg = sConfig:GetSkillConfigData(skillId)
    local param = cfg:GetSkillScopeParam()
    local count = param.multiCount --特效数
    local cellCount = table.count(gridList) / count
    --构造三维数组
    local posDic = {}
    for i, pos in ipairs(gridList) do
        local mod = (i - 1) // cellCount + 1
        if not posDic[mod] then
            posDic[mod] = {}
        end
        table.insert(posDic[mod], pos)
    end
    local res = {}
    res[1] = posDic
    return res, count
end
--endregion

--region NearToFar
function DataSortScopeGridRangeInstruction:_SortBoardCenterToFar(gridList, castPos)
    local leftUpList = {}
    local leftBottomList = {}
    local rightBottomList = {}
    local rightUpList = {}
    local upList = {}
    local bottomList = {}
    local rightList = {}
    local leftList = {}
    local centerList = {}
    local maxGridCount = 0

    table.insert(centerList, castPos)

    for i, pos in pairs(gridList) do
        local dis = pos - castPos
        if dis.x == 0 then --水平方向距离为0
            if dis.y > 0 then --正上方
                table.insert(upList, pos)
            elseif dis.y < 0 then --正下方
                table.insert(bottomList, pos)
            end
        elseif dis.x > 0 then --在右侧
            if dis.y == 0 then
                table.insert(rightList, pos)
            elseif dis.y > 0 then
                if dis.x > dis.y then
                    table.insert(rightList, pos)
                elseif dis.x == dis.y then
                    table.insert(rightUpList, pos)
                elseif dis.x < dis.y then
                    table.insert(upList, pos)
                end
            elseif dis.y < 0 then
                if dis.x > math.abs(dis.y) then
                    table.insert(rightList, pos)
                elseif dis.x == math.abs(dis.y) then
                    table.insert(rightBottomList, pos)
                elseif dis.x < math.abs(dis.y) then
                    table.insert(bottomList, pos)
                end
            end
        elseif dis.x < 0 then --在左侧
            if dis.y == 0 then
                table.insert(leftList, pos)
            elseif dis.y > 0 then
                if math.abs(dis.x) > dis.y then
                    table.insert(leftList, pos)
                elseif math.abs(dis.x) == dis.y then
                    table.insert(leftUpList, pos)
                elseif math.abs(dis.x) < dis.y then
                    table.insert(upList, pos)
                end
            elseif dis.y < 0 then
                if math.abs(dis.x) > math.abs(dis.y) then
                    table.insert(leftList, pos)
                elseif math.abs(dis.x) == math.abs(dis.y) then
                    table.insert(leftBottomList, pos)
                elseif math.abs(dis.x) < math.abs(dis.y) then
                    table.insert(bottomList, pos)
                end
            end
        end
    end
    --排序
    local cmpNearToFar = function(pos1, pos2)
        local disX1 = math.abs(pos1.x - castPos.x)
        local disY1 = math.abs(pos1.y - castPos.y)
        local disX2 = math.abs(pos2.x - castPos.x)
        local disY2 = math.abs(pos2.y - castPos.y)
        local dis1 = disX1 + disY1
        local dis2 = disX2 + disY2
        return dis1 < dis2
    end
    table.sort(leftBottomList, cmpNearToFar)
    table.sort(rightBottomList, cmpNearToFar)
    table.sort(leftUpList, cmpNearToFar)
    table.sort(rightUpList, cmpNearToFar)

    local convertFunc = function(array)
        local list = {}
        for i = 1, #array do
            local t = {}
            t[1] = array[i]
            list[i] = t
        end
        return list
    end

    leftBottomList = convertFunc(leftBottomList)
    rightBottomList = convertFunc(rightBottomList)
    leftUpList = convertFunc(leftUpList)
    rightUpList = convertFunc(rightUpList)
    centerList = convertFunc(centerList)

    local reverseTbale = function(tab)
        local tmp = {}
        for i = 1, #tab do
            local key = #tab
            tmp[i] = table.remove(tab)
        end
        return tmp
    end

    local sortDic = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a < b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end

    --上
    local upDic = {}
    for _, p in pairs(upList) do
        local y = p.y
        if not upDic[y] then
            upDic[y] = {}
        end
        table.insert(upDic[y], p)
    end
    upList = sortDic(upDic)
    --下
    local bottomDic = {}
    for _, p in pairs(bottomList) do
        local y = p.y
        if not bottomDic[y] then
            bottomDic[y] = {}
        end
        table.insert(bottomDic[y], p)
    end
    bottomList = sortDic(bottomDic)
    bottomList = reverseTbale(bottomList)
    --左
    local leftDic = {}
    for _, p in pairs(leftList) do
        local x = p.x
        if not leftDic[x] then
            leftDic[x] = {}
        end
        table.insert(leftDic[x], p)
    end
    leftList = sortDic(leftDic)
    leftList = reverseTbale(leftList)
    --右
    local rightDic = {}
    for _, p in pairs(rightList) do
        local x = p.x
        if not rightDic[x] then
            rightDic[x] = {}
        end
        table.insert(rightDic[x], p)
    end
    rightList = sortDic(rightDic)

    --取最长的方向有多少个格子
    local GetMaxGridCount = function(table, maxGridCount)
        if #table > maxGridCount then
            maxGridCount = #table
        end
        return maxGridCount
    end
    maxGridCount = GetMaxGridCount(upList, maxGridCount)
    maxGridCount = GetMaxGridCount(bottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftBottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightBottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(centerList, maxGridCount)

    local res = {}
    res[1] = leftList
    res[2] = rightList
    res[3] = upList
    res[4] = bottomList
    res[5] = leftUpList
    res[6] = rightUpList
    res[7] = leftBottomList
    res[8] = rightBottomList
    res[9] = centerList

    return res, maxGridCount
end
--endregion

local function GetDistanceInfo(center, pool)
    local dic = {}
    local array = {}
    local indexer = {}

    for index, v2 in ipairs(pool) do
        local distance = Vector2.Distance(center, v2)
        if not dic[distance] then
            dic[distance] = {
                distance = distance,
                elements = {}
            }
            table.insert(array, dic[distance])
        end
        local container = dic[distance].elements
        table.insert(container, v2)

        indexer[v2:Pos2Index()] = index
    end

    return array, indexer
end

function DataSortScopeGridRangeInstruction:_JieweiZuoSort(array)
    local pool = {}
    for _, v2 in ipairs(array) do
        table.insert(pool, v2)
    end

    local bestDistance = tonumber(self._sortParam[1])
    local maxGroup = tonumber(self._sortParam[2])

    local v2LastSelected = table.remove(pool, math.random(1, #pool))
    local sequence = {v2LastSelected}

    while (#pool > 0) do
        local array, indexer = GetDistanceInfo(v2LastSelected, pool)
        -- 这个排序有成立条件：每个元素的distance值是不一样的
        table.sort(
            array,
            function(a, b)
                -- 最佳距离的组永远是最优先的
                if a.distance == bestDistance then
                    return true
                end

                if b.distance == bestDistance then
                    return false
                end

                local absDisA = math.abs(a.distance)
                local absDisB = math.abs(b.distance)

                if absDisA == absDisB then
                    return a.distance > b.distance
                end

                return absDisA < absDisB
            end
        )

        local firstGroup = array[1].elements
        local selectedIndex = math.random(1, #firstGroup)
        local v2Selected = firstGroup[selectedIndex]
        local indexInPool = indexer[v2Selected:Pos2Index()]
        table.remove(pool, indexInPool)
        table.insert(sequence, v2Selected)
    end

    local bestGroupElementCount = #sequence // maxGroup

    local final = {}
    local currentGroupIndex = 1
    for i = 1, #sequence do
        if
            (final[currentGroupIndex]) and (currentGroupIndex ~= maxGroup) and
                (#final[currentGroupIndex] >= bestGroupElementCount)
         then
            currentGroupIndex = currentGroupIndex + 1
        end
        if not final[currentGroupIndex] then
            final[currentGroupIndex] = {}
        end
        table.insert(final[currentGroupIndex], sequence[i])
    end

    return {final}, maxGroup
end

function DataSortScopeGridRangeInstruction:_SpecialScopeIndexSort(specialScopeResultList)
    local posDic = {}
    for _, skillScopeGrid in pairs(specialScopeResultList) do
        local index = skillScopeGrid:GetIndex()
        local pos = skillScopeGrid:GetGridPos()
        if not posDic[index] then
            posDic[index] = {}
        end
        table.insert(posDic[index], pos)
    end

    local sortDicFunc = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a < b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end
    posDic = sortDicFunc(posDic)
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
--region SectorAngle
function DataSortScopeGridRangeInstruction:_SortBySectorAngle(gridList, castPos,pickList)
    local mainPick
    local expandPick
    if pickList and #pickList >= 2 then
        mainPick = pickList[1]
        expandPick = pickList[2]
    else
        return
    end
    local mainDir = mainPick - castPos
    --按该角度进行分组
    local groupAngle = tonumber(self._sortParam[1])
    groupAngle = groupAngle or 15
    groupAngle = groupAngle > 0 and groupAngle or 15
    local maxAngle = tonumber(self._sortParam[2])
    maxAngle = maxAngle or 45
    maxAngle = maxAngle > 0 and maxAngle or 45
    local posDic = {}
    local totalGroup = math.ceil(maxAngle/groupAngle)
    for i = 1, totalGroup do
        posDic[i] = {}
    end
    for _, pos in pairs(gridList) do
        local targetDir = pos - castPos
        local diffAngle = Vector2.Angle(mainDir,targetDir)
        diffAngle = math.floor(diffAngle + 0.5) --四舍五入取整 精度问题
        local index = math.ceil(diffAngle/groupAngle)
        if index == 0 then
            index = 1
        end
        if not posDic[index] then
            posDic[index] = {}
        end
        table.insert(posDic[index],pos)
    end
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end

function DataSortScopeGridRangeInstruction:_XYSmallToLargeSort(gridList)
    local posDic = {}
    local posList = {}
    for _, pos in pairs(gridList) do
        table.insert(posList,pos)
        -- local t = {}
        -- table.insert(t, pos)
        -- table.insert(posDic, t)
    end

    local sortDicFunc = function(a,b)
        local disA = a.x + a.y
        local disB = b.x + b.y
        if disA == disB then
            return a.x > b.x
        else
            return disA < disB
        end
    end
    table.sort(posList,sortDicFunc)
    posDic[1] = {}
    for _, pos in ipairs(posList) do
        table.insert(posDic[1], pos)
    end
    local maxGridCount = table.count(posDic)
    local res = {}
    res[1] = posDic
    return res, maxGridCount
end
--endregion