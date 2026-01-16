_class("UIBuildComponentManager", Object)
---@class UIBuildComponentManager:Object
UIBuildComponentManager = UIBuildComponentManager

function UIBuildComponentManager:Constructor(buildComponent)
    ---@type CampaignBuildComponent
    self._buildComponent = buildComponent
    ---@type BuildComponentInfo
    self._buildComponentInfo = buildComponent:GetComponentInfo()

    local componentCfgId = self._buildComponent:GetComponentCfgId()
    ---@type UIBuildComponentBuildItemData
    self._buildItemData = UIBuildComponentBuildItemData:New(componentCfgId)

    ---@type UIBuildComponentPicnicData
    self._picnicItemData = UIBuildComponentPicnicData:New(componentCfgId)

    self._buildingList = self:_InitBuildingList()
end

function UIBuildComponentManager:_InitBuildingList()
    local tb_out = self._buildItemData:GetBuildItemIdList()
    table.sort(
        tb_out,
        function(a, b)
            local data_a = self:GetBuildCurStatusData(a)
            local data_b = self:GetBuildCurStatusData(b)
            local layer_a = self._buildItemData:GetLayer(data_a)
            local layer_b = self._buildItemData:GetLayer(data_b)
            if layer_a ~= layer_b then
                return layer_a < layer_b
            end
            return a < b
        end
    )
    return tb_out
end

--region status
--获取当前状态
function UIBuildComponentManager:GetBuildCurStatus(buildItemId)
    local buildItemInfos = self._buildComponentInfo.build_item_infos
    ---@type BuildItemInfo
    local buildingInfo = buildItemInfos[buildItemId]
    if buildingInfo then
        local statusList = self._buildItemData:GetBuildItemStatusList(buildItemId)
        for i = #statusList, 1, -1 do
            if (buildingInfo.mask & statusList[i]) > 0 then
                return statusList[i]
            end
        end
    end
    return 0
end

--获取当前状态数据
function UIBuildComponentManager:GetBuildCurStatusData(buildItemId)
    local status = self:GetBuildCurStatus(buildItemId)
    return self._buildItemData:GetBuildItemData(buildItemId, status)
end

--获取下一状态
function UIBuildComponentManager:GetBuildNextStatus(buildItemId, status)
    local statusList = self._buildItemData:GetBuildItemStatusList(buildItemId)
    local cur = table.ikey(statusList, status)
    if cur and cur + 1 <= #statusList then
        return statusList[cur + 1]
    end
end

--状态是否已经建造
function UIBuildComponentManager:CheckBuildStatusComplete(buildItemId, targetStatus)
    local status = self:GetBuildCurStatus(buildItemId)
    return status >= targetStatus
end

--下一状态是否已经建造
function UIBuildComponentManager:CheckNextStatusComplete(buildItemId, status)
    local nextStatus = self:GetBuildNextStatus(buildItemId, status)
    return not nextStatus or self:CheckBuildStatusComplete(buildItemId, nextStatus)
end
--endregion

--region build check
function UIBuildComponentManager:CheckBuildStatusUnlock(buildItemId, status)
    --判断前置建筑
    local id, st = self._buildItemData:GetNeedBuildItemIdAndStatus(buildItemId, status)
    if id == 0 then
        return true
    end
    if st ~= UIBuildComponentBuildStatus.Init then
        return self:CheckBuildStatusComplete(id, st)
    else
        return self:CheckBuildStatusUnlock(id, st)
    end

    -- todo:
    --具体重建区域解锁对应的关卡可配置。
    --关卡与重建玩法关联，通过指定关卡会解锁相应的重建区域。
    -- if self._needMissionList then
    --     local passMissionInfos = self._lineMissionCompInfo.m_pass_mission_info
    --     for i = 1, #self._needMissionList do
    --         if self._lineMissionComponet:IsPassCamMissionID(self._needMissionList[i]) == false then
    --             return false
    --         end
    --     end
    -- end
end

--是否解锁
function UIBuildComponentManager:IsNextStatusUnlock(buildItemId)
    --检测下个状态的need状态是否完成
    local status = self:GetBuildCurStatus(buildItemId)
    local nextStatus = self:GetBuildNextStatus(buildItemId, status)
    if not nextStatus then
        Log.debug("UIBuildComponentManager:IsNextStatusUnlock() nextStatus = nil")
        return nil
    end
    return self:CheckBuildStatusUnlock(buildItemId, nextStatus)
end

--是否有可以建造的建筑
function UIBuildComponentManager:HaveCanBuilding(itemCount)
    for _, v in pairs(self._buildingList) do
        local data = self:GetBuildCurStatus(v)
        if not self:IsAllStatusComplete(v) and self:IsNextStatusUnlock(v) then
            local cost = self:GetCostCount(data) or 0
            if itemCount >= cost then
                return true
            end
        end
    end
    return false
end

--该建筑所有状态是否已完成建造
function UIBuildComponentManager:IsAllStatusComplete(buildItemId)
    local status = self:GetBuildCurStatus(buildItemId)
    local list = self._buildItemData:GetBuildItemStatusList(buildItemId)
    return status == list[#list]
end

--是否所有建筑都建造完毕
function UIBuildComponentManager:IsAllBuildingComplete()
    for _, v in ipairs(self._buildingList) do
        if not self:IsAllStatusComplete(v) then
            return false
        end
    end
    return true
end
--endregion

--region build help
function UIBuildComponentManager:GetBuildRewardList()
    local tb_in = self._buildItemData:GetBuildItemDataMap()

    local tb_out = {}
    for buildItemId, statusMap in pairs(tb_in) do
        for status, cfg in pairs(statusMap) do
            local reward = self:GetBuildReward(buildItemId, status)
            if reward and #reward > 0 then
                table.insert(
                    tb_out,
                    {
                        ["buildItemId"] = buildItemId,
                        ["status"] = status,
                        ["name"] = self:GetName(buildItemId),
                        ["state"] = self:CheckBuildStatusComplete(buildItemId, status) and 2 or 1,
                        ["reward"] = reward
                    }
                )
            end
        end
    end

    table.sort(
        tb_out,
        function(a, b)
            if a.state == b.state then
                return a.buildItemId == b.buildItemId and a.status < b.status or a.buildItemId < b.buildItemId
            else
                return a.state < b.state
            end
        end
    )
    return tb_out
end

-- 计算距离解锁还需几步
function UIBuildComponentManager:CalcBuildUnlockStep(buildItemId, status)
    local status = self:GetBuildNextStatus(buildItemId, status)

    local step = 1
    while not self:CheckBuildStatusUnlock(buildItemId, status) do
        if status ~= UIBuildComponentBuildStatus.Init then
            step = step + 1
        end
        buildItemId, status = self._buildItemData:GetNeedBuildItemIdAndStatus(buildItemId, status)
    end
    return step
end

function UIBuildComponentManager:CalcBuildUnlockProgress()
    local tb_in = self._buildItemData:GetBuildItemDataMap()

    local all = 0
    local unlock = 0
    for buildItemId, statusMap in pairs(tb_in) do
        for status, cfg in pairs(statusMap) do
            if status ~= UIBuildComponentBuildStatus.Init then
                all = all + 1
                if self:CheckBuildStatusComplete(buildItemId, status) then
                    unlock = unlock + 1
                end
            end
        end
    end
    return unlock, all
end
--endregion

--region Picnic
function UIBuildComponentManager:CheckCanPicnic(buildItemId)
    local complete = self:CheckPicnicStatusComplete(buildItemId)
    local noStory = not self:CheckPicnicHaveStory()
    local lockTime = self:CheckPicnicLockTime(buildItemId)
    local nextCfg = self:CheckPicnicHaveNextCfg()

    return complete and noStory and lockTime and nextCfg
end

function UIBuildComponentManager:CheckPicnicStatusComplete(buildItemId)
    return self:CheckBuildStatusComplete(buildItemId, UIBuildComponentBuildStatus.Picnic)
end

function UIBuildComponentManager:CheckPicnicStoryUnlock(seq)
    local cur = self:GetPicnicCurSeq()
    return seq <= cur
end

function UIBuildComponentManager:CheckPicnicHaveStory()
    return self._buildComponentInfo.m_picnic_info.m_have_story
end

function UIBuildComponentManager:CheckPicnicLockTime(buildItemId)
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    local nextFood = self._buildComponentInfo.m_picnic_info.m_next_food[buildItemId] or 0
    return nextFood <= curTime
end

function UIBuildComponentManager:CheckPicnicHaveNextCfg()
    local seq = self:GetPicnicCurSeq() + 1
    local cfg = self:GetPicnicData(seq)
    return cfg ~= nil
end

function UIBuildComponentManager:GetPicnicCurSeq()
    return self._buildComponentInfo.m_picnic_info.m_times
end
--endregion

--region StoryList
function UIBuildComponentManager:GetUnPlayStoryList()
    local tb_out = {}
    for buildItemId, buildingInfo in pairs(self._buildComponentInfo.build_item_infos) do
        local maskList = self._buildItemData:GetBuildItemStatusList(buildItemId)
        for i = 2, #maskList do
            local v1, v2 = maskList[i], maskList[i - 1]
            local mask = buildingInfo.mask
            local storyMask = buildingInfo.story_mask
            if (mask & v1) > 0 and (storyMask & v1) == 0 then
                local data = self._buildItemData:GetBuildItemData(buildItemId, v2)
                local storyType = self._buildItemData:GetStoryType(data)
                local storyId = self._buildItemData:GetStoryId(data)
                if storyId and storyId > 0 then
                    table.insert(tb_out, {storyType, storyId, v2, buildItemId})
                end
            end
        end
    end
    return tb_out
end

function UIBuildComponentManager:GetCanReviewStory()
    local tb_out = {}
    for _, buildItemId in pairs(self._buildingList) do
        local status = self:GetBuildCurStatus(buildItemId)
        local maskList = self._buildItemData:GetBuildItemStatusList(buildItemId)
        for _, v in ipairs(maskList) do
            if v == status then
                break
            end
            local data = self._buildItemData:GetBuildItemData(buildItemId, v)
            local id = self._buildItemData:GetStoryReviewId(data)
            if id and id > 0 then
                table.insert(tb_out, id)
            end
        end
    end
    table.sort(
        tb_out,
        function(a, b)
            return a < b
        end
    )
    return tb_out
end

function UIBuildComponentManager:GetBuildDataStoryReviewIdMap()
    return self._buildItemData:GetBuildDataStoryReviewIdMap()
end

function UIBuildComponentManager:GetPicnicDataStoryReviewIdMap()
    return self._picnicItemData:GetPicnicDataStoryReviewIdMap()
end
--endregion

--region LocalDB
function UIBuildComponentManager:IsFirstEnterBuilding()
    local key = self:GetFirstEnterBuildingKey()
    local value = UnityEngine.PlayerPrefs.GetInt(key, 0)
    return value == 0
end

function UIBuildComponentManager:EnterBuilding()
    local key = self:GetFirstEnterBuildingKey()
    UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UIBuildComponentManager:GetFirstEnterBuildingKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local componentCfgId = self._buildComponent:GetComponentCfgId()
    local key = "UIBuildComponentManager_GetFirstEnterBuildingKey_" .. componentCfgId .. "_" .. pstId
    return key
end
--endregion

--region UIBuildComponentBuildItemData
function UIBuildComponentManager:GetBuildItemIdList()
    return self._buildingList
end

function UIBuildComponentManager:GetBuildItemIdList_Picnic()
    return self._buildItemData:GetBuildItemIdList_Picnic()
end

--建筑名称
function UIBuildComponentManager:GetName(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return self._buildItemData:GetName(data)
end

--状态名称
function UIBuildComponentManager:GetStatusName(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return self._buildItemData:GetStatusName(data)
end

--状态图标
function UIBuildComponentManager:GetIcon(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return self._buildItemData:GetIcon(data)
end

--状态Spine
function UIBuildComponentManager:GetSpine(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return self._buildItemData:GetSpine(data)
end

--状态描述
function UIBuildComponentManager:GetDes(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return self._buildItemData:GetDes(data)
end

--建造花费
function UIBuildComponentManager:GetCostItemId()
    return self._buildItemData:GetBuildDataItemId()
end

function UIBuildComponentManager:GetCostCount(buildItemId)
    local status = self:GetBuildCurStatus(buildItemId)
    local nextStatus = self:GetBuildNextStatus(buildItemId, status)
    local data = self._buildItemData:GetBuildItemData(buildItemId, nextStatus)
    return data and self._buildItemData:GetCostCount(data)
end

--重建奖励
function UIBuildComponentManager:GetBuildReward(buildItemId, status)
    local data = self._buildItemData:GetBuildItemData(buildItemId, status)
    return data and self._buildItemData:GetBuildReward(data)
end

function UIBuildComponentManager:GetBuildStoryId(buildItemId, status)
    local data = self._buildItemData:GetBuildItemData(buildItemId, status)
    return data and self._buildItemData:GetStoryId(data)
end

--剧情Id
function UIBuildComponentManager:GetCompleteStoryId(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetStoryId(data) or 0
end

--剧情类型
function UIBuildComponentManager:GetCompleteStoryType(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetStoryType(data) or 0
end

--获取控件描述位置
function UIBuildComponentManager:GetWidgetDesPos(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetWidgetDesPos(data) or Vector2(0, 0)
end

--获取控件位置
function UIBuildComponentManager:GetWidgetPos(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetWidgetPos(data) or Vector2(0, 0)
end

--获取图标位置
function UIBuildComponentManager:GetIconPos(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetIconPos(data) or Vector2(0, 0)
end

--获取图标宽度
function UIBuildComponentManager:GetIconWidth(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetIconWidth(data) or 0
end

--获取图标高度
function UIBuildComponentManager:GetIconHeight(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetIconHeight(data) or 0
end

--获取图标旋转
function UIBuildComponentManager:GetIconRotate(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetIconRotate(data) or 0
end

--获取触发区域位置
function UIBuildComponentManager:GetTriggerPos(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetTriggerPos(data) or Vector2(0, 0)
end

--获取触发区域宽度
function UIBuildComponentManager:GetTriggerWidth(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetTriggerWidth(data) or 0
end

--获取触发区域高度
function UIBuildComponentManager:GetTriggerHeight(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetTriggerHeight(data) or 0
end

--获取触发区域旋转
function UIBuildComponentManager:GetTriggerRotate(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetTriggerRotate(data) or 0
end

--获取特效区域位置
function UIBuildComponentManager:GetEffectAreaPos(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetEffectAreaPos(data) or Vector2(0, 0)
end

--获取特效区域大小
function UIBuildComponentManager:GetEffectAreaScale(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetEffectAreaScale(data) or 1
end

--获取层级
function UIBuildComponentManager:GetLayer(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:GetLayer(data) or 0
end

--是否显示
function UIBuildComponentManager:IsShow(buildItemId)
    local data = self:GetBuildCurStatusData(buildItemId)
    return data and self._buildItemData:IsShow(data) or false
end
--endregion

--region UIBuildComponentPicnicData
function UIBuildComponentManager:GetPicnicData(seq)
    return self._picnicItemData:GetPicnicData(seq)
end

function UIBuildComponentManager:GetPicnicFixedPetIdList(seq, count)
    return self._picnicItemData:GetPicnicFixedPetIdList(seq, count)
end

function UIBuildComponentManager:GetPicnicPet(seq)
    return self._picnicItemData:GetPicnicPet(seq)
end

function UIBuildComponentManager:GetPicnicRewardList(seq)
    return self._picnicItemData:GetPicnicRewardList(seq)
end

function UIBuildComponentManager:GetPicnicStory(seq)
    return self._picnicItemData:GetPicnicStory(seq)
end
--endregion
