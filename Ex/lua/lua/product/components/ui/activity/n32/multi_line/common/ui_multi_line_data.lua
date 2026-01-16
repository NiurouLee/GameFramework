---@class UIMultiLineData : Object
_class("UIMultiLineData", Object)
UIMultiLineData = UIMultiLineData

---@param res AsyncRequestRes
function UIMultiLineData:LoadData(TT, res, eCampaignType, eCampaignComponentID, forceUpdate)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign =  UIActivityCampaign.New()
    
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        eCampaignType,
        eCampaignComponentID
    )

    -- 错误处理
    if res and not res:GetSucc() then
        return
    end

    if not self._campaign then
        return
    end

    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    if forceUpdate then
        self._campaign:ReLoadCampaignInfo_Force(TT, res)
    end

    --获取组件
    ---@type MultiLineMissionComponent
    self._multiLineComponent = self._localProcess:GetComponent(eCampaignComponentID)
    ---@type MultiLineComponentInfo
    self._multiLineComponentInfo = self._localProcess:GetComponentInfo(eCampaignComponentID)

    self._componentId  = self._multiLineComponentInfo.m_campaign_id * 100000 + self._multiLineComponentInfo.m_component_type * 100 + self._multiLineComponentInfo.m_component_id

    return true
end

function UIMultiLineData:GetCampaignId()
    return self._campaign._id
end


function UIMultiLineData:GetComponent()
    return self._multiLineComponent, self._multiLineComponentInfo
end

function UIMultiLineData:GetComponentID()
    return self._componentId
end

--活动组件结束
function UIMultiLineData:IsComponentTimeEnd()
    local closeTime = self._multiLineComponentInfo.m_close_time
    local now = GameGlobal.GetModule(SvrTimeModule):GetServerTime() / 1000
    return now >= closeTime
end


function UIMultiLineData:GetMultiLineFolderCfgs()
    local componentId = self._componentId
    local cfgs = Cfg.cfg_component_multiline_mission_main{ComponentID = componentId}
    return cfgs
end

function UIMultiLineData:GetMultiLineFolderCfgByIndex(index)
    local cfgs = self:GetMultiLineFolderCfgs()
    return cfgs[index]
end

--目录是否解锁
function UIMultiLineData:IsMultiLineFolderUnlock(cfg)
    local missionId = cfg.NeedMissionId
    if missionId and missionId > 0 then
        return self:GetPassMissionInfo(missionId) ~= nil
    else
        return true
    end
end

--获得通关信息，nil 未通关
---@return cam_mission_info
function UIMultiLineData:GetPassMissionInfo(missionId)
    return self._multiLineComponentInfo.m_pass_mission_info[missionId]
end

--进入地图之前，保存周目状态，以便再次进入时判断是否解锁了新周目
function UIMultiLineData:SnapFolderContexBeforeEnterMap(lastPassFolerNum)
    UIMultiLineData.lastPassFolderNum = lastPassFolerNum
end

--进入战斗保存战斗关卡快照
function UIMultiLineData:SnapMultilineContextBeforeFight(folderId,levelId)
    UIMultiLineData.LastFightLevelId = levelId
    UIMultiLineData.LastFightForderIndex = folderId
    UIMultiLineData.LastFightLevelIsPass = nil
    local cfgLevel = Cfg.cfg_component_multiline_mission[levelId]

    local passInfo = self:GetPassMissionInfo(cfgLevel.MissionID)
    UIMultiLineData.LastFightLevelIsPass = passInfo ~= nil
end


--检查指定周目状态
---@param index number 周目索引
---@return  unPassNumM(主线未通关数量),unPssNumB(支线未通关数量),unLockAllB(支线是否全部解锁),unLockZeroB(支线是否一个都未通关)
function UIMultiLineData:CheckFolderState(index)
    local unPassNumM = 0
    local unPssNumB = 0
    local unLockAllB = true
    local unLockZeroB = true

    local cfg = self:GetMultiLineFolderCfgByIndex(index)
    if not cfg then
        return unPassNumM, unPssNumB, unLockAllB, unLockZeroB
    end
    

    local mainLevels = cfg.MainMission
    for k, levelId in pairs(mainLevels) do
        local cfg = Cfg.cfg_component_multiline_mission[levelId]
        local passInfo = self:GetPassMissionInfo(cfg.MissionID)
        if not passInfo then
            unPassNumM = unPassNumM + 1
        end
    end

    local branchLevels = cfg.BranchMission
    for k, levelId in pairs(branchLevels) do
        local cfg = Cfg.cfg_component_multiline_mission[levelId]
        local passInfo = self:GetPassMissionInfo(cfg.MissionID)
        if not passInfo then
            unPssNumB = unPssNumB + 1
        end
        if unLockAllB then
            --检查是否解锁
            local needMissionId = cfg.NeedMissionId
            if needMissionId and needMissionId > 0 then
                local needPassInfo = self:GetPassMissionInfo(needMissionId)
                if not needPassInfo then
                    unLockAllB = false
                else
                    unLockZeroB = false
                end
            else
                unLockZeroB = false
            end
        end
    end
    return unPassNumM, unPssNumB, unLockAllB, unLockZeroB
end


--周目支线未读取完提示，是否已提示
function UIMultiLineData:IsForlderBranchUnReadHasTipsed(index)
    local key = self:GetForlderBranchUnReadTipsKey(index)
    return UIMultiLineData.HasPrefs(key)
    
end

function UIMultiLineData:SetFolderBranchUnReadTips(index)
    local key = self:GetForlderBranchUnReadTipsKey(index)
    UIMultiLineData.SetPrefsKey(key)
end

function UIMultiLineData:GetForlderBranchUnReadTipsKey(index)
    local key = "multi_forlder_branch_tips_".. self._componentId.."_"..index
    key = UIMultiLineData.GetPrefsKey(key)
    return key
end

--周目目录是否已读
function UIMultiLineData:IsForlderHasRead(folrderId)
    return self._multiLineComponent:GetMark(folrderId)
end

function UIMultiLineData:SetFoolderAsRead(TT, folrderId)
    local asyncRes =  AsyncRequestRes:New()
    return self._multiLineComponent:ECCH_HandleMultiLineSetMark(TT, asyncRes,  folrderId)
end



function UIMultiLineData.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end

function UIMultiLineData.GetPrefsKey(str)
    local playerPrefsKey = UIMultiLineData.GetPstId() .. str
    return playerPrefsKey
end

function UIMultiLineData.HasPrefs(key)
    return UnityEngine.PlayerPrefs.HasKey(key)
end

function UIMultiLineData.SetPrefsKey(key)
    UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UIMultiLineData:MultiLinePetFilesCfg(componentID,Id)
    return  Cfg.cfg_component_multiline_mission_petfiles{ComponentID = componentID, ID = Id }
end

function UIMultiLineData:MultiLinePetCfg(componentID,petId)
    if not petId then 
        return  Cfg.cfg_component_multiline_mission_pet{ComponentID = componentID}
    end 
    return  Cfg.cfg_component_multiline_mission_pet{ComponentID = componentID,PetID = petId }
end

function UIMultiLineData:GetPetFiles()
    return  self._multiLineComponentInfo.m_pet_files
end

function UIMultiLineData:CheckPetFileReceived(fileId)
    if not self._multiLineComponentInfo.m_pet_files then 
       return  false 
    end 
    for key, value in pairs(self._multiLineComponentInfo.m_pet_files) do
        if value == fileId then 
           return true 
        end 
    end
    return  false 
end

function UIMultiLineData:CheckPetRewardReceived(petId)
    if not self._multiLineComponentInfo.m_files_received then 
       return  false 
    end 
    for key, value in pairs(self._multiLineComponentInfo.m_files_received) do
        if value == petId then 
           return true 
        end 
    end
    return  false 
end

function UIMultiLineData:CheckMultilineMissionPassed(componentId,fileId)
    local cfg =  Cfg.cfg_component_multiline_mission{ComponentID = componentId, FilesId = fileId}
    if not cfg then
        Log.debug("UIMultiLineData:CheckMultilineMissionPassed".. fileId.."no cfg")
       return false 
    end 
    return self:GetPassMissionInfo(cfg[1].NeedMissionId) ~= nil
end

function UIMultiLineData:GetPetFileReaded(fileId)
    local key = self:GettPetFileKey(fileId)
    return UIMultiLineData.HasPrefs(key)
end

function UIMultiLineData:SetPetFileReaded(fileId)
    local key = self:GettPetFileKey(fileId)
    UIMultiLineData.SetPrefsKey(key)
end

function UIMultiLineData:GettPetFileKey(fileId)
    local key = "multi_petfile_read_".. self._componentId.."_"..fileId
    key = UIMultiLineData.GetPrefsKey(key)
    return key
end

function UIMultiLineData:CheckDocRedPoint()
    self._petInfos =  self:MultiLinePetCfg(self:GetComponentID())
    for i, v in ipairs(self._petInfos) do
        if self:CheckBtnRedPoint(v) then
             return true 
        end 
    end
    return false 
end

function UIMultiLineData:CheckBtnRedPoint(petInfo)
    if not petInfo then 
        return false 
    end 
    for index, value in ipairs(petInfo.FilesID) do
        if  self:CheckPetFileReceived(value) then
            local readed =  self:GetPetFileReaded(value)
            if not readed then 
                return true 
            end 
        end 
    end
    return false 
end



