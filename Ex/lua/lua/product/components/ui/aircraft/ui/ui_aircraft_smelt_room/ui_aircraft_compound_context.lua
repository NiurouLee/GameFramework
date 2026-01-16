---@class UIAircraftCompoundContext:Object
_class("UIAircraftCompoundContext", Object)
UIAircraftCompoundContext = UIAircraftCompoundContext

function UIAircraftCompoundContext:Constructor()
    self.maxLimit = 999 --最大合成上限
    self.itemModule = GameGlobal.GetModule(ItemModule)
    self._roleModule = GameGlobal.GetModule(RoleModule)
end

function UIAircraftCompoundContext:Clear()
    self.maxComNum = 0 --最大合成数量
    self.curComNum = 1 --当前选中合成数量
    self.materialTypesNum = 1 --材料种类数量
    self.materialData = {} --材料数据
    self._cost = 0  --合成消耗
    self.comList = {} --合成列表
    self._atomDiscount = 1 --原子剂折扣
    self.materailNotEnough = false
    self.coinNotEntenough = false
end

function UIAircraftCompoundContext:InitIdMap(idMap)
    self.idMap = idMap
end

function UIAircraftCompoundContext:InitWithTargetItem(targetCfg, atomDiscount)
    self:Clear()
    self.targetCfg = targetCfg
    self._atomDiscount = atomDiscount
    self:_AddMaterialData(1, targetCfg.Input, targetCfg.SInput)
    self.materialTypesNum = #self.materialData

    local mid = math.ceil(self.maxLimit/2)
    local left = 1
    local right = self.maxLimit

    while true do
        if mid < left or mid > right then
            break
        end

        local nextIndex  = 0
        if self:CalcWithTargetNum(mid) then
            --满足条件,向右
            nextIndex = mid + math.ceil((right - mid )/2)
            left = mid + 1 
            self.maxComNum = mid
        else
            --不满足条件，向左
            nextIndex = mid - math.ceil((mid - left)/2)
            right = mid - 1
        end
        mid = nextIndex
    end
    Log.debug("UIAircraftCompoundContext , maxComNum", self.maxComNum)
end

function UIAircraftCompoundContext:_AddMaterialData(typeLevel, input, sInput)
    local inputCfg = {}
    self.materialData[typeLevel] = inputCfg
    for i, v in ipairs(input) do
        local mat = {}
        mat.ID = v[1]--goodsId
        mat.NeedNum = v[2]
        mat.SelectNum = 0 --选中数量
        mat.HaveNum = 0 --拥有数量
        
        inputCfg[mat.ID] = mat

        if i == 1 then
            local nextCfgId = self.idMap[mat.ID]
            if nextCfgId then
                local cfg_smelt = Cfg.cfg_item_smelt[nextCfgId]
                if cfg_smelt and cfg_smelt.Input then
                    self:_AddMaterialData(typeLevel + 1, cfg_smelt.Input, cfg_smelt.SInput)
                end
            end
            
        end
    end
end

---@return boolean --true/false 是否可以合成
function UIAircraftCompoundContext:CalcWithTargetNum(num, continueCalWhenCostNotEnough)
    self._continueCalWhenCostNotEnough  = continueCalWhenCostNotEnough --材料不足时是否继续计算
    self._cost = 0
    table.clear(self.comList)
    self.coinNotEntenough = false
    self.materailNotEnough = false

    --材料数量初始化
    for level, matList in ipairs(self.materialData) do
        for k, mat in pairs(matList) do
            mat.HaveNum = self.itemModule:GetItemCount(mat.ID)
            mat.SelectNum = 0
        end
    end

    return self:_CheckComTarget(self.targetCfg.ID, 1, num)
end

function UIAircraftCompoundContext:_CheckComTarget(targetCfgId, level, comNum)
    --合成目标
    local cfg_smelt = Cfg.cfg_item_smelt[targetCfgId]
    local targetCost = 0
    if cfg_smelt and #cfg_smelt.SInput > 0 then
        targetCost = cfg_smelt.SInput[1][2]
    end
    --材料列表
    local matList = self.materialData[level]
    --计算消耗
    self._cost = self._cost + math.ceil(comNum * targetCost* self._atomDiscount)

    for k, mat in pairs(matList) do
        if not self:_CheckMaterial(mat.ID, level, mat.NeedNum * comNum) then
            return false
        end
    end
    -- 检查消耗
    if(self._roleModule:GetAssetCount(RoleAssetID.RoleAssetAtom) < self._cost) then
        self.coinNotEntenough = true
        if not self._continueCalWhenCostNotEnough then
            return false --代币不足，继续计算，用来保证计算出稳定的消耗
        end
    end
    local hasComNum = self.comList[targetCfgId]
    if hasComNum then
        self.comList[targetCfgId] = hasComNum + comNum
    else
        self.comList[targetCfgId] = comNum
    end
    return true
end

function UIAircraftCompoundContext:_CheckMaterial(targetGoodsId, level, needNum)
    local matList = self.materialData[level]
    if not matList then
        return false
    end
    local targetCfgId = self.idMap[targetGoodsId]

    local mat = matList[targetGoodsId]
    local remainNum = mat.HaveNum - mat.SelectNum
    local needAppend = 0 --需要补充数量
    if remainNum >= needNum then
        mat.SelectNum = mat.SelectNum + needNum
        return true
    end
    needAppend = needNum - remainNum
    mat.SelectNum = mat.HaveNum --全部扣除

    --检查是否低级替代材料
    local nextLevel = level + 1
    local nextMatList = self.materialData[nextLevel]
    if not nextMatList then
        self.materailNotEnough = true
        return false --无低级替代材料
    end

    --刷新替代材料需求数量
    local cfg_smelt = Cfg.cfg_item_smelt[targetCfgId]
    for k, v in pairs(cfg_smelt.Input) do
        local mat = nextMatList[v[1]]
        mat.NeedNum = v[2]
    end

    --检查下一级材料
    return self:_CheckComTarget(targetCfgId, nextLevel, needAppend)
end

function UIAircraftCompoundContext:GetComListData()
    local id_num_list = {}
    for id, count in pairs(self.comList) do
        local asset = RoleAsset:New()
        asset.assetid = id
        asset.count = count

        table.insert(id_num_list,  asset)
    end
    return id_num_list
end

function UIAircraftCompoundContext:GetCost()
    return self._cost
end

function UIAircraftCompoundContext:IsCostEnough()
    return    not self.coinNotEntenough
end

function UIAircraftCompoundContext:IsMaterialEnough()
    return  not self.materailNotEnough
end

function UIAircraftCompoundContext:ReCalcOnlyUseBaseMaterial(count)
    for i, input in ipairs(self.materialData) do
        if i == 1 then
            for k, mat in pairs(input) do
                mat.SelectNum = mat.NeedNum * count
            end
        else
            for k, mat in pairs(input) do
                mat.SelectNum = 0
            end
        end
    end


    --重新计算代币是否足够--指计算基础材料
    local cfg_smelt = Cfg.cfg_item_smelt[self.targetCfg.ID]
    local targetCost = 0
    if cfg_smelt and #cfg_smelt.SInput > 0 then
        targetCost = cfg_smelt.SInput[1][2]
    end
    self._cost = math.ceil(count * targetCost* self._atomDiscount)
    if(self._roleModule:GetAssetCount(RoleAssetID.RoleAssetAtom) < self._cost) then
        self.coinNotEntenough = true
    end
end