_class("UIActivityNPlusSixBuildingCondition", Object)
---@class UIActivityNPlusSixBuildingCondition:Object
UIActivityNPlusSixBuildingCondition = UIActivityNPlusSixBuildingCondition

---@param localProcess CCampaingN6
function UIActivityNPlusSixBuildingCondition:Constructor(cfg, localProcess)
    ---@type CCampaingN6
    self._localProcess = localProcess
    --- 线性关卡组件
    ---@type LineMissionComponent        
    self._lineMissionComponet = self._localProcess:GetComponent(ECampaignN6ComponentID.ECAMPAIGN_N6_LINE_MISSION) 
    ---@type LineMissionComponentInfo
    self._lineMissionCompInfo = self._localProcess:GetComponentInfo(ECampaignN6ComponentID.ECAMPAIGN_N6_LINE_MISSION)

    self._preBuildingIdList = {}
    self._preBuildingStatusList = {}
    if not cfg then
        return
    end
    if cfg.NeedItemId > 0 then
        self._preBuildingIdList[#self._preBuildingIdList + 1] = cfg.NeedItemId
        self._preBuildingStatusList[#self._preBuildingStatusList + 1] = cfg.NeedItemStatus
    end
    self._needMissionList = cfg.NeedMissionList
end

---@param buildingDatas UIActivityNPlusSixBuildingDatas
function UIActivityNPlusSixBuildingCondition:IsUnLock(buildingDatas)
    --判断前置建筑
    for i = 1, #self._preBuildingIdList do
        ---@type UIActivityNPlusSixBuildingData
        local buildingData = buildingDatas:GetBuilding(self._preBuildingIdList[i])
        ---@type UIActivityNPlusSixBuildingStatus
        local statusType = self._preBuildingStatusList[i]
        if statusType >= 0 then
            if buildingData:IsUnLockStatus(self._preBuildingStatusList[i])  == false then
                return false
            end
        end
    end
    --具体重建区域解锁对应的关卡可配置。
    --关卡与重建玩法关联，通过指定关卡会解锁相应的重建区域。
    if self._needMissionList then
        local passMissionInfos = self._lineMissionCompInfo.m_pass_mission_info
        for i = 1, #self._needMissionList do
            if self._lineMissionComponet:IsPassCamMissionID(self._needMissionList[i]) == false then
                return false
            end
        end
    end
    
    return true
end
