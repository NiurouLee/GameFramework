_class("MovieFatherSon", Object)
---@class MovieFatherSon : Object
MovieFatherSon = MovieFatherSon

function MovieFatherSon:Constructor()
end

function MovieFatherSon:Dispose()
    self.testID = 1
    self.homeBuildManager = nil
end

function MovieFatherSon:GetBuildManager()
    if self.homeBuildManager == nil then
        ---@type HomelandModule
        self.mHomeland = GameGlobal.GetModule(HomelandModule)
        ---@type UIHomelandModule
        self.mUIHomeland = self.mHomeland:GetUIModule()
        ---@type HomelandClient
        self.homelandClient = self.mUIHomeland:GetClient()
        ---@type HomeBuildManager
        self.homeBuildManager = self.homelandClient:BuildManager()
    end

    return self.homeBuildManager
end

function MovieFatherSon:TestFn()
    local buildMgr = self:GetBuildManager()
    local fatherBuilding = buildMgr:FindBuildingByCfgID(5271001)

    if self.testID == nil then
        self.testID = 1
    end

    if self.testID == 1 then
        self.dataList = self:OnSavePlayback(fatherBuilding)
    elseif self.testID == 2 then
        self:OnClearFreeArea(fatherBuilding)
        self:OnClearMovie(fatherBuilding)
    elseif self.testID == 3 then
        -- self:OnEnterPlayback(fatherBuilding, self.dataList)
        self:OnRestoreHomeBuilding(fatherBuilding)
    end

    self.testID = self.testID + 1
end

-- 临时清空背景墙、地板、中央空地、运镜空地上的所有家具
-- 清理，不删除
-- 提炼保存列表
function MovieFatherSon:OnEnterMovie(fatherBuilding)
    local restoreList = {}

    local children = fatherBuilding:GetAllChildren()
    for k, v in pairs(children) do
        if fatherBuilding:GetFreeChild(k) == nil then
            restoreList[k] = v

            v:ShowBuilding(false)
            fatherBuilding:RemoveChild(v)
        end
    end

    -- 拍电影其他编辑限制功能

    return restoreList
end

-- 离开拍电影，还原空背景墙、地板、中央空地、运镜空地上的所有家具
function MovieFatherSon:OnExitMovie(fatherBuilding, restoreList)
    local clearList = {}

    local children = fatherBuilding:GetAllChildren()
    for k, v in pairs(children) do
        if fatherBuilding:GetFreeChild(k) == nil then
            clearList[k] = v
        end
    end

    local buildMgr = self:GetBuildManager()

    for k, v in pairs(clearList) do
        -- buildMgr:DestroyBuilding(v)
    end

    for k, v in pairs(restoreList) do
        v:ShowBuilding(true)
        fatherBuilding:AddChild(v)
    end
end

---拍电影添加背景墙 与 地板
function MovieFatherSon:AddFixedBuilding(fatherBuilding, id)
    local childBuildingCfg = Cfg.cfg_item_son_architecture[id]
    local fatherSlot = childBuildingCfg.FatherSlot
    local cfg_fixed_position = Cfg.cfg_homeland_building_fixed_position{}[fatherSlot]
    if cfg_fixed_position == nil then
        BuildError("拍电影找不到固定家具位置cfg_homeland_building_fixed_position ：" .. fatherSlot)
        return
    end

    local theNearestFather = fatherBuilding

    -- 坐标与旋转
    local fixedTransform = nil
    local fatherTransform = theNearestFather:Transform()
    local fatherPosition = fatherTransform.position
    if cfg_fixed_position.FixedPosition ~= nil then
        fixedTransform = theNearestFather:FindRecursively(cfg_fixed_position.FixedPosition)
    end

    if fixedTransform == nil then
        fixedTransform = fatherTransform
    end

    local relationPosition = fixedTransform.position - fatherPosition
    local fatherYaw = fatherTransform.eulerAngles.y
    local relationYaw = fixedTransform.eulerAngles.y - fatherYaw


    -- 固定位置
    local replacedBuilding = theNearestFather:GetFixedChild(fatherSlot)
    if replacedBuilding ~= nil then
        replacedBuilding:Delete()
    end


    -- 创建建筑
    local worldPosition = fatherPosition + relationPosition
    local worldYaw = fatherYaw + relationYaw

    local data = Architecture:New()
    data.asset_id = id
    data.parent = theNearestFather:GetBuildId()
    --服务器只存整数,舍弃小数点5位之后
    data.pos_x = BuildHelper.ToInt(worldPosition.x)
    data.pos_y = BuildHelper.ToInt(worldPosition.y)
    data.pos_z = BuildHelper.ToInt(worldPosition.z)
    data.rot = math.floor(worldYaw)
    data.pstid = 0 --保证不与服务器算出来的id相等

    local buildMgr = self:GetBuildManager()
    local building = buildMgr:_CreateBuilding(data)

    return building
end

function MovieFatherSon:RemoveBuilding(fatherBuilding, building)
    if fatherBuilding == nil then
        return
    end

    if building == nil then
        return
    end

    local buildMgr = self:GetBuildManager()
    fatherBuilding:RemoveChild(building)
    buildMgr:RemoveBuilding(building)
    building:Dispose()
end

---拍电影 始终高亮整个自由摆放区
function MovieFatherSon:OnShowFreeArea(fatherBuilding, isShow)
    local allFreeArea = fatherBuilding:GetAllFreeArea()
    local areaID = -1
    for k, v in pairs(allFreeArea) do
        areaID = v
        break
    end

    fatherBuilding:ShowBuildingArea(areaID, isShow, true)
end

-- 清空按钮 -> 清空自由摆放区的所有家具
function MovieFatherSon:OnClearFreeArea(fatherBuilding)
    local restoreList = {}
    local children = fatherBuilding:GetAllFreeChildren()
    for k, v in pairs(children) do
        restoreList[k] = v
    end

    local buildMgr = self:GetBuildManager()
    for k, v in pairs(restoreList) do
        fatherBuilding:RemoveChild(v)
        buildMgr:RemoveBuilding(v)
        v:Dispose()
    end
end

-- 清空按钮 -> 清空背景墙与地面
function MovieFatherSon:OnClearMovie(fatherBuilding)
    local restoreList = {}
    local children = fatherBuilding:GetAllChildren()
    for k, v in pairs(children) do
        if fatherBuilding:GetFreeChild(k) == nil then
            restoreList[k] = v
        end
    end

    local buildMgr = self:GetBuildManager()
    for k, v in pairs(restoreList) do
        fatherBuilding:RemoveChild(v)
        buildMgr:RemoveBuilding(v)
        v:Dispose()
    end
end

---拍电影恢复家园所有子建筑
function MovieFatherSon:OnRestoreHomeBuilding(fatherBuilding)
    local buildMgr = self:GetBuildManager()
    buildMgr:refreshBuilding()
end

function MovieFatherSon:GetArchitecture(building)
    local archServer = building:GetArchitecture()
    local arch = Architecture:New()
    for k, v in pairs(archServer) do
        arch[k] = v
    end

    local buildingPos = building:Pos()
    local buildingYaw = building:RotY()
    arch.pos_x = BuildHelper.ToInt(buildingPos.x)
    arch.pos_y = BuildHelper.ToInt(buildingPos.y)
    arch.pos_z = BuildHelper.ToInt(buildingPos.z)
    arch.rot = buildingYaw
    arch.parent = building:GetParentAssetID()

    return arch
end

---拍电影自由摆放区域子建筑 保存录像
---相对位置
---@return table<number, Architecture>
function MovieFatherSon:OnSavePlayback(fatherBuilding)
    local dataList = {}
    local father = self:GetArchitecture(fatherBuilding)
    local children = fatherBuilding:GetAllChildren()
    for k, v in pairs(children) do
        if not v:IsDelete() then
            local child = self:GetArchitecture(v)
            local data = Architecture:New()

            data.asset_id = child.asset_id
            data.skin = child.skin
            data.pos_x = child.pos_x - father.pos_x
            data.pos_y = child.pos_y - father.pos_y
            data.pos_z = child.pos_z - father.pos_z
            data.rot = child.rot - father.rot
            data.pstid = child.pstid
            data.status = child.status
            data.parent = child.parent

            table.insert(dataList, data)
        end
    end

    table.insert(dataList, father)

    return dataList
end

---拍电影 回放设置电影保存的建筑
---相对位置
function MovieFatherSon:OnEnterPlayback(fatherBuilding, dataList)
    local buildMgr = self:GetBuildManager()
    local father = self:GetArchitecture(fatherBuilding)

    for k, v in pairs(dataList) do
        if v.asset_id == fatherBuilding:GetBuildId() then
            -- _CreateBuilding(fatherBuilding)
        else
            local child = v
            local data = Architecture:New()
            data.asset_id = child.asset_id
            data.skin = child.skin
            data.pos_x = child.pos_x + father.pos_x
            data.pos_y = child.pos_y + father.pos_y
            data.pos_z = child.pos_z + father.pos_z
            data.rot = child.rot + father.rot
            data.pstid = child.pstid
            data.status = child.status
            data.parent = child.parent

            local building = buildMgr:_CreateBuilding(data)
        end
    end
end

function MovieFatherSon:OnExitPlayback(fatherBuilding)

end




