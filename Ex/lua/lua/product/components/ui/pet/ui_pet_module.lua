---@class UIPetModule:UIModule
_class("UIPetModule", UIModule)
UIPetModule = UIPetModule

function UIPetModule:Init()
    self._filterFirstConditionList = {}
    self._filterFirstTagConditionList = {}
    self._filterSecondTagConditionList = {}
    self._sortTypeInfos = {}
    self._curSelctSortItemInfo = nil
    self._curSelctPetInfo = nil
end
function UIPetModule:Dispose()
end
function UIPetModule:Constructor()
    self._filterFirstConditionList = {}
    self._filterFirstTagConditionList = {}
    self._filterSecondTagConditionList = {}
    self._sortTypeInfos = {}
    self._curSelctPetInfo = nil
    self._curSelctSortItemInfo = nil
    self:ResetSortInfos()
    self:InitFilterElementInfos()
    self:InitFilterTagInfos()
    ---@type PetModule
    self._petModule = self:GetModule(PetModule)

    --暂时关闭new的排序
    self._newSort = false
    self._gradeOrder = PetSortOrder.Descending
    --==============新的筛选排序

    self:ResetSortFilterParams()
end
--======================================
function UIPetModule:ResetSortFilterParams()
    --默认排序条件
    self._currentSortType = 2
    self:_CreateFilterParams()
    self:_CreateSortParamsNew()
end

--新的排序qa(列表用，风船的排序放在风船类里)
function UIPetModule:_CreateSortParamsNew()
    ---@type PetSortType
    self._sortTypeTab = {}
    self._sortParamGetTab = {}
    self._currentSortOrder = PetSortOrder.Descending

    table.insert(
        self._sortParamGetTab,
        function()
            return self:StarSortParam()
        end
    )
    table.insert(
        self._sortParamGetTab,
        function()
            return self:LevelSortParam()
        end
    )
    table.insert(
        self._sortParamGetTab,
        function()
            return self:ElementSortParam()
        end
    )
    table.insert(
        self._sortParamGetTab,
        function()
            return self:AttackSortParam()
        end
    )
    table.insert(
        self._sortParamGetTab,
        function()
            return self:DefenceSortParam()
        end
    )
    table.insert(
        self._sortParamGetTab,
        function()
            return self:HealthSortParam()
        end
    )
    table.insert(
        self._sortParamGetTab,
        function()
            return self:AffinitySortParam()
        end
    )

    self._sortTypeTab = self._sortParamGetTab[self._currentSortType]()
end

function UIPetModule:ChangeSortParamsNew(tp)
    if tp == self._currentSortType then
        if self._currentSortOrder == PetSortOrder.Ascending then
            self._currentSortOrder = PetSortOrder.Descending
        else
            self._currentSortOrder = PetSortOrder.Ascending
        end
    else
        self._currentSortOrder = PetSortOrder.Descending
        self._currentSortType = tp
    end
    if tp == PetSortType.Level then
        if self._currentSortOrder == PetSortOrder.Ascending then
            self._gradeOrder = PetSortOrder.Ascending
        else
            self._gradeOrder = PetSortOrder.Descending
        end
    end
    self._sortTypeTab = self._sortParamGetTab[self._currentSortType]()
end

function UIPetModule:GetCurrentSortType()
    return self._currentSortType, self._currentSortOrder
end

--等级排序
function UIPetModule:LevelSortParam()
    local paramTab = {}
    --觉醒
    local PetSortParam1 = PetSortParam:New(PetSortType.Grade, self._gradeOrder)
    table.insert(paramTab, PetSortParam1)
    --等级
    local PetSortParam2 = PetSortParam:New(PetSortType.Level, self._currentSortOrder)
    table.insert(paramTab, PetSortParam2)
    --星等
    local PetSortParam3 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --ID
    local PetSortParam4 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam4)

    return paramTab
end
--星级排序
function UIPetModule:StarSortParam()
    local paramTab = {}
    --星等
    local PetSortParam1 = PetSortParam:New(PetSortType.Star, self._currentSortOrder)
    table.insert(paramTab, PetSortParam1)
    --觉醒
    local PetSortParam2 = PetSortParam:New(PetSortType.Grade, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam2)
    --等级
    local PetSortParam3 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --ID
    local PetSortParam4 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam4)

    return paramTab
end
--元素排序
function UIPetModule:ElementSortParam()
    local paramTab = {}
    --元素
    local PetSortParam1 = PetSortParam:New(PetSortType.Element, self._currentSortOrder)
    table.insert(paramTab, PetSortParam1)
    --觉醒
    local PetSortParam2 = PetSortParam:New(PetSortType.Grade, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam2)
    --等级
    local PetSortParam3 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --星等
    local PetSortParam4 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam4)
    --ID
    local PetSortParam5 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam5)

    return paramTab
end
--攻击排序
function UIPetModule:AttackSortParam()
    local paramTab = {}
    --攻击
    local PetSortParam1 = PetSortParam:New(PetSortType.Attack, self._currentSortOrder)
    table.insert(paramTab, PetSortParam1)
    --星等
    local PetSortParam2 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam2)
    --觉醒
    local PetSortParam3 = PetSortParam:New(PetSortType.Grade, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --等级
    local PetSortParam4 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam4)
    --ID
    local PetSortParam5 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam5)

    return paramTab
end
--防御排序
function UIPetModule:DefenceSortParam()
    local paramTab = {}
    --防御
    local PetSortParam1 = PetSortParam:New(PetSortType.Defence, self._currentSortOrder)
    table.insert(paramTab, PetSortParam1)
    --星等
    local PetSortParam2 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam2)
    --觉醒
    local PetSortParam3 = PetSortParam:New(PetSortType.Grade, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --等级
    local PetSortParam4 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam4)
    --ID
    local PetSortParam5 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam5)

    return paramTab
end
--生命排序
function UIPetModule:HealthSortParam()
    local paramTab = {}
    --生命
    local PetSortParam1 = PetSortParam:New(PetSortType.Health, self._currentSortOrder)
    table.insert(paramTab, PetSortParam1)
    --星等
    local PetSortParam2 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam2)
    --觉醒
    local PetSortParam3 = PetSortParam:New(PetSortType.Grade, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --等级
    local PetSortParam4 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam4)
    --ID
    local PetSortParam5 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam5)

    return paramTab
end
--亲密排序
function UIPetModule:AffinitySortParam()
    local paramTab = {}
    --亲密
    local PetSortParam1 = PetSortParam:New(PetSortType.Affinity, self._currentSortOrder)
    table.insert(paramTab, PetSortParam1)
    --星等
    local PetSortParam2 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam2)
    --觉醒
    local PetSortParam3 = PetSortParam:New(PetSortType.Grade, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam3)
    --等级
    local PetSortParam4 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    table.insert(paramTab, PetSortParam4)
    --ID
    local PetSortParam5 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(paramTab, PetSortParam5)

    return paramTab
end

--构建排序条件
function UIPetModule:_CreateSortParams()
    ---@type PetSortType
    self._sortTypeTab = {}

    --默认排序条件

    --[[

        --新旧
        local PetSortParam2 = PetSortParam:New(PetSortType.NewOrOld, PetSortOrder.Ascending)
        table.insert(self._sortTypeTab, PetSortParam2)
        ]]
    --PetSortType.Star
    --星等
    local defaultSortParam1 = Cfg.cfg_client_pet_sort[1].Type

    local PetSortParam1 = PetSortParam:New(defaultSortParam1, PetSortOrder.Descending)
    table.insert(self._sortTypeTab, PetSortParam1)

    --ID
    local PetSortParam3 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(self._sortTypeTab, PetSortParam3)
end
function UIPetModule:_CreateSortParamsWithoutNew()
    ---@type PetSortType
    self._sortTypeTab = {}

    --默认排序条件
    --PetSortType.Star
    --星等
    local defaultSortParam1 = Cfg.cfg_client_pet_sort[1].Type

    local PetSortParam1 = PetSortParam:New(defaultSortParam1, PetSortOrder.Descending)
    table.insert(self._sortTypeTab, PetSortParam1)

    --ID
    local PetSortParam3 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(self._sortTypeTab, PetSortParam3)
end
--构建筛选条件
function UIPetModule:_CreateFilterParams()
    self._filterParamTab = {}
end
--获得排序条件
function UIPetModule:GetSortParams()
    --只有第一个可修改
    if self._newSort then
        return self._sortTypeTab[2]
    else
        return self._sortTypeTab[1]
    end
end
--获得筛选条件
function UIPetModule:GetFilterParams()
    return self._filterParamTab
end
--修改排序条件
function UIPetModule:SetSortParams(params)
    --修改的第二条排序条件
    if self._newSort then
        -- body
        self._sortTypeTab[2]._sort_order = params._sort_order
        self._sortTypeTab[2]._sort_type = params._sort_type
    else
        self._sortTypeTab[1]._sort_order = params._sort_order
        self._sortTypeTab[1]._sort_type = params._sort_type
    end
end

--修改筛选条件
function UIPetModule:SetFilterParams(type, tag)
    for i = 1, #self._filterParamTab do
        if self._filterParamTab[i]._filter_type == type then
            table.remove(self._filterParamTab, i)
            return
        end
    end
    local filterParam
    if tag then
        filterParam = PetFilterParam:New(type, tag)
    else
        filterParam = PetFilterParam:New(type)
    end
    table.insert(self._filterParamTab, filterParam)
end

--排序
function UIPetModule:_SortPets()
    --排序筛选list
    local pets = self._petModule:GetPets()
    self._petSortedList = self._petModule:_SortPets(pets, self._filterParamTab, self._sortTypeTab)
end

--修改排序条件（new不参与排序）
function UIPetModule:RemoveNewSortParam()
    self._newSort = false
    self:_CreateSortParamsWithoutNew()
end
function UIPetModule:AddNewSortParam()
    --暂时关闭new的排序
    --[[
        old
        self._newSort = true
        ]]
    self._newSort = false

    self:_CreateSortParams()
end

--编队进来需要用固定星灵
function UIPetModule:SetTeamPets(pstids)
    self._teamPets = {}
    if pstids then
        if table.count(pstids) > 0 then
            for i = 1, #pstids do
                local pstid = pstids[i]
                local pet = self._petModule:GetPet(pstid)
                table.insert(self._teamPets, pet)
            end
            self._fromTeam = true
            return
        end
    end
    self._fromTeam = false
end

function UIPetModule:SetTeamCustomPets(customPetDatas)
    self._teamPets = {}
    if customPetDatas then
        if table.count(customPetDatas) > 0 then
            for i = 1, #customPetDatas do
                ---@type UICustomPetData
                local customPetData = customPetDatas[i]
                local tmp =  _G.pet_data
                local tempData = tmp:New()
                tempData.template_id = customPetData:GetPetId()
                tempData.current_skin = 0-- current_skin不在pet_data中 用于非本地星灵
                local pet = Pet:New(tempData)
                -- 不要改变顺序
                tempData.grade = customPetData:GetGrade()
                tempData.level = pet:GetMaxLevel()
                tempData.awakening = customPetData:GetAwakening() --觉醒
                tempData.equip_lv = customPetData:GetEquip()
                tempData.affinity_level = pet:GetPetAffinityMaxLevel()
                pet:SetData(tempData)
                table.insert(self._teamPets, pet)
            end
            self._fromTeam = true
            return
        end
    end
    self._fromTeam = false
end

--获得
function UIPetModule:GetSortedPets()
    if self._fromTeam then
        if self._teamPets then
            if table.count(self._teamPets) > 0 then
                return self._teamPets
            end
        end
    end
    self:_SortPets()
    return self._petSortedList
end
--======================================

function UIPetModule:ResetSortInfos()
    self._sortTypeInfos = {}
    local sortConfig = Cfg.pet_sort_config {}
    for key, value in pairs(sortConfig) do
        local pet_sort_data = pet_sort_data:New(value.SortType, value.Name, value.SortState)
        table.insert(self._sortTypeInfos, pet_sort_data)
        if value.SortState > 0 then
            self._curSelctSortItemInfo = pet_sort_data
        end
    end
end

function UIPetModule:ChangeSortDataState()
    local sortTypeInfos = self._sortTypeInfos
    if sortTypeInfos == nil then
        return
    end
    local curSortInfo = self._curSelctSortItemInfo
    for index, value in pairs(sortTypeInfos) do
        if value.sortType ~= curSortInfo.sortType then
            value.sortState = 0
        else
            value = curSortInfo
        end
    end
end
function UIPetModule:SetSorDataState(sortData)
    if sortData == nil then
        return
    end
    if sortData.sortState == SortState.None then
        sortData.sortState = tonumber(SortState.Up)
    elseif sortData.sortState == SortState.Up then
        sortData.sortState = tonumber(SortState.Down)
    elseif sortData.sortState == SortState.Down then
        sortData.sortState = tonumber(SortState.Up)
    end
end

function UIPetModule:RefreshSortDataState(sortInfo)
    if sortInfo == nil then
        return
    end
    self:SetSorDataState(sortInfo)
    self:SetCurSortInfo(sortInfo)
    self:ChangeSortDataState()
end

function UIPetModule:GetPetDatasBySortType(sortInfo)
    self:RefreshSortDataState(sortInfo)
    return self:RequestPetDatas()
end
function UIPetModule:SetCurSelctPet(petInfo)
    self._curSelctPetInfo = petInfo
end

function UIPetModule:GetCurSelctPet()
    return self._curSelctPetInfo
end

function UIPetModule:InitFilterElementInfos()
    self._filterElementInfos = {}
    for index = 1, 4 do
        local cfg = Cfg.pet_filter_element_config[index]
        if cfg then
            local info = {}
            info.attributeID = cfg.attributeID
            info.Name = cfg.Name
            table.insert(self._filterElementInfos, info)
        end
    end
end

function UIPetModule:GetFilterElementInfoByIndex(index)
    if self._filterElementInfos[index] == nil then
        return
    end
    return self._filterElementInfos[index]
end

function UIPetModule:GetFilterElementInfos()
    return self._filterElementInfos
end

function UIPetModule:InitFilterTagInfos()
    self._filterFirstTagInfos = {}
    self._filterSecondTagInfos = {}
    local configData = Cfg.cfg_pet_tags {}
    for configId, cfg in pairs(configData) do
        if cfg then
            local info = {}
            info.tagID = cfg.ID
            info.Name = cfg.Name
            info.tagType = cfg.tagType
            if cfg.tagType == 1 then
                table.insert(self._filterFirstTagInfos, info)
            elseif cfg.tagType == 2 then
                table.insert(self._filterSecondTagInfos, info)
            end
        end
    end
end

function UIPetModule:GetFilterTagInfoByIndex(index)
    if self._filterFirstTagInfos[index] == nil then
        return
    end
    return self._filterFirstTagInfos[index]
end

function UIPetModule:GetFilterTagInfos()
    return self._filterFirstTagInfos
end

function UIPetModule:GetFilterSecondTagInfoByIndex(index)
    if self._filterSecondTagInfos[index] == nil then
        return
    end
    return self._filterSecondTagInfos[index]
end

function UIPetModule:GetFilterrSecondTagInfos()
    return self._filterSecondTagInfos
end

function UIPetModule:RequestPetDatas()
    local tRequestPetDatas = {}
    local _curSortInfo = self._curSelctSortItemInfo
    local _filterFirstConditionList = self._filterFirstConditionList --元素筛选条件
    local _filterFirstTagConditionList = self._filterFirstTagConditionList --标签筛选条件
    local _filterSecondTagConditionList = self._filterSecondTagConditionList --标签筛选条件
    local requestHandleInfo = {}
    requestHandleInfo.sort_type = _curSortInfo.sortType
    requestHandleInfo.sort_order = _curSortInfo.sortState
    requestHandleInfo.element_list = _filterFirstConditionList
    requestHandleInfo.tag_list = _filterFirstTagConditionList
    requestHandleInfo.secondeTag_list = _filterSecondTagConditionList
    tRequestPetDatas = self._petModule:SortPets(requestHandleInfo)
    return self:GetAllPetPstID(tRequestPetDatas)
end

function UIPetModule:RequestPetDatasAndReturnPets()
    local sortConfig = Cfg.pet_sort_config {}

    local sortInfo = {}
    for key, value in pairs(sortConfig) do
        local pet_sort_data = pet_sort_data:New(value.SortType, value.Name, value.SortState)
        if value.SortState > 0 then
            sortInfo = pet_sort_data
        end
    end

    local tRequestPetDatas = {}
    local _curSortInfo = sortInfo
    local _filterFirstConditionList = self._filterFirstConditionList --元素筛选条件
    local _filterFirstTagConditionList = self._filterFirstTagConditionList --标签筛选条件
    local _filterSecondTagConditionList = self._filterSecondTagConditionList --标签筛选条件
    local requestHandleInfo = {}
    requestHandleInfo.sort_type = _curSortInfo.sortType
    requestHandleInfo.sort_order = _curSortInfo.sortState

    requestHandleInfo.element_list = _filterFirstConditionList
    requestHandleInfo.tag_list = _filterFirstTagConditionList
    requestHandleInfo.secondeTag_list = _filterSecondTagConditionList

    tRequestPetDatas = self._petModule:SortPets(requestHandleInfo)

    return self:GetAllPetPstID(tRequestPetDatas)
end

function UIPetModule:GetAllPetPstID(tRequestPetDatas)
    if tRequestPetDatas == nil then
        return
    end
    local petPstIdList = {}
    for key, petInfo in pairs(tRequestPetDatas) do
        local pstID = petInfo:GetPstID()
        table.insert(petPstIdList, pstID)
    end
    return petPstIdList
end

function UIPetModule:ReleaseConditionLData()
    self._filterFirstConditionList = {}
    self._filterFirstTagConditionList = {}
    self._filterSecondTagConditionList = {}
end

function UIPetModule:GetCombatSKill(petInfo)
    local batSkillsID = {}
    local activeSkillID = petInfo:GetPetActiveSkill()
    local activeSkillinfo = {}
    activeSkillinfo.skillList = {activeSkillID}

    local extraSkillID_tmp = petInfo:GetPetExtraActiveSkill()
    local extraSkillID
    if extraSkillID_tmp then
        extraSkillID = extraSkillID_tmp[1]
    end
    local extraSkillinfo = {}
    extraSkillinfo.skillList = {extraSkillID}

    local chainSkills = petInfo:GetPetChainSkills()
    local chainInfo = nil
    if chainSkills ~= nil and table.count(chainSkills) > 0 then
        chainInfo = {}
        chainInfo.skillList = chainSkills
    end

    local captainID = petInfo:GetPetPassiveSkill()
    local captaInfo = {}
    captaInfo.skillList = {captainID}

    if activeSkillID and activeSkillID ~= 0 then
        table.insert(batSkillsID, activeSkillinfo)
    end

    if extraSkillID and extraSkillID ~= 0 then
        table.insert(batSkillsID, extraSkillinfo)
    end

    if chainSkills and table.count(chainSkills) > 0 then
        table.insert(batSkillsID, chainInfo)
    end

    if captainID and captainID ~= 0 then
        table.insert(batSkillsID, captaInfo)
    end

    return batSkillsID
end

function UIPetModule:GetWorkSKillInfo(petInfo)
    return petInfo:GetPetWorkSkills()
end

function UIPetModule:GetSkillDetailInfoBySkillType(petInfo)
    return self:GetCombatSKill(petInfo)
end
---@param petInfo MatchPet
function UIPetModule:GetSkillDetailInfoBySkillTypeHideExtra(petInfo)
    local skillInfos = self:GetSkillDetailInfoBySkillType(petInfo)
    local petAwake = petInfo:GetPetAwakening()
    local petGrade = petInfo:GetPetGrade()
    local petId = petInfo:GetTemplateID()

    local skillInfos_ret = {}
    for i = 1, #skillInfos do
        local skill_info = skillInfos[i]
        local skill_list = skill_info.skillList
        local inner = true
        for j = 1, #skill_list do
            local skill_id = skill_list[j]
            local cfgs = Cfg.cfg_pet_skill{PetID=petId,Grade=petGrade,Awakening=petAwake}
            if cfgs and table.count(cfgs)>0 then
                local tmp_cfg = cfgs[1]
                local extraids = tmp_cfg.ExtraActiveSkill
                if extraids and #extraids>0 then
                    local extraid = extraids[1]
                    if extraid == skill_id then
                        local HideExtra = tmp_cfg.HideExtraSkillInPanel
                        if HideExtra then
                            inner = false
                            break
                        end 
                    end
                else
                    break
                end
            end
        end
        if inner then
            table.insert(skillInfos_ret,skill_info)
        end
    end
    
    return skillInfos_ret
end
--属性注册
function UIPetModule:RegisteredAttributeFilterType(attFilterType)
    local isHave, index = self:ContainAttributeFilterType(attFilterType)
    if isHave == true then
        table.remove(self._filterFirstConditionList, index)
    else
        table.insert(self._filterFirstConditionList, attFilterType)
    end
end
function UIPetModule:ContainAttributeFilterType(attFilterType)
    if self._filterFirstConditionList == nil then
        return false, -1
    end
    for index, conditionType in ipairs(self._filterFirstConditionList) do
        if conditionType == attFilterType then
            return true, index
        end
    end
    return false, -1
end

function UIPetModule:GetAttributeFilterFirstConditionList()
    return self._filterFirstConditionList
end
function UIPetModule:SetAttributeFilterFirstConditionList(filterFirstConditionList)
    self._filterFirstConditionList = filterFirstConditionList
end
--第一标签注册
function UIPetModule:RegisteredTagFilterType(tagType)
    local isHave, index = self:ContainTagFilterType(tagType)
    if isHave == true then
        table.remove(self._filterFirstTagConditionList, index)
    else
        table.insert(self._filterFirstTagConditionList, tagType)
    end
end
function UIPetModule:ContainTagFilterType(tagType)
    if self._filterFirstTagConditionList == nil then
        return false, -1
    end
    for index, conditionType in ipairs(self._filterFirstTagConditionList) do
        if conditionType == tagType then
            return true, index
        end
    end
    return false, -1
end

function UIPetModule:GetTagFilterFirstConditionList()
    return self._filterFirstTagConditionList
end
function UIPetModule:SetTagFilterFirstConditionList(filterSecondConditionList)
    self._filterFirstTagConditionList = filterSecondConditionList
end
--第二标签注册
function UIPetModule:RegisteredSecondTagFilterType(tagType)
    local isHave, index = self:ContainSecondTagFilterType(tagType)
    if isHave == true then
        table.remove(self._filterSecondTagConditionList, index)
    else
        table.insert(self._filterSecondTagConditionList, tagType)
    end
end
function UIPetModule:ContainSecondTagFilterType(tagType)
    if self._filterSecondTagConditionList == nil then
        return false, -1
    end
    for index, conditionType in ipairs(self._filterSecondTagConditionList) do
        if conditionType == tagType then
            return true, index
        end
    end
    return false, -1
end

function UIPetModule:GetTagFilterSecondConditionList()
    return self._filterSecondTagConditionList
end
function UIPetModule:SetTagFilterSecondConditionList(filterSecondConditionList)
    self._filterSecondTagConditionList = filterSecondConditionList
end

function UIPetModule:GetAllSortInfos()
    return self._sortTypeInfos
end

function UIPetModule:SetAllSortInfos(sortInfos)
    self._sortTypeInfos = sortInfos
end

function UIPetModule:GetSortInfoByIndex(index)
    if self._sortTypeInfos == nil then
        return nil
    end
    if self._sortTypeInfos[index] == nil then
        return nil
    end
    return self._sortTypeInfos[index]
end
function UIPetModule:GetCurSortInfo()
    return self._curSelctSortItemInfo
end
function UIPetModule:SetCurSortInfo(sortInfo)
    self._curSelctSortItemInfo = sortInfo
end

--获取不同觉醒的信息对比
---@param petInfo MatchPet
---@param hasBody boolean
---@return UIFightSkillChangeData,UIFightSkillChangeData[]
function UIPetModule:GetDiffWithGrade(petInfo, hasBody)
    local change_data = {
        active = {},
        extra = {},
        chain = {},
        work = {},
        passive = {},
        body = {}
    }
    ---@type UIFightSkillChangeData
    local diff = petInfo:GetUpgradeChangeWithSkillIDNew()

    if diff == nil then
        return
    end

    local body = diff.body

    local tab = {}
    --active
    if diff.active.changeType ~= PetSkillChangeState.NoChange then
        table.insert(tab, diff.active)
    end

    --extra
    if diff.extra.changeType ~= PetSkillChangeState.NoChange then
        table.insert(tab, diff.extra)
    end

    if diff.chain.changeType ~= PetSkillChangeState.NoChange then
        table.insert(tab, diff.chain)
    end

    --equip
    if diff.passive.changeType ~= PetSkillChangeState.NoChange then
        table.insert(tab, diff.passive)
    end

    if diff.work.changeType ~= PetSkillChangeState.NoChange then
        table.insert(tab, diff.work)
    end

    if hasBody then
        return body, tab
    else
        return tab
    end
end

function UIPetModule:RemoveNotShowSkill(petid, grade, awaken, skillVaryInfo)
    local _petid = petid
    local _grade = grade
    local _awaken = awaken
    local skillinfo = skillVaryInfo
    local returnSkillInfo = {}
    local removeTab
    local cfg_pet_skill = Cfg.cfg_pet_skill {PetID = _petid, Grade = _grade, Awakening = _awaken}
    if cfg_pet_skill and table.count(cfg_pet_skill) > 0 then
        if cfg_pet_skill[1].NoShowSkillInfo then
            removeTab = cfg_pet_skill[1].NoShowSkillInfo
            if removeTab and #removeTab > 0 then
                for i = 1, #skillinfo do
                    local s = skillinfo[i]
                    if s.type == "passive" then
                        local removeState = removeTab[1]
                        if removeState ~= 0 then
                            table.insert(returnSkillInfo, s)
                        end
                    elseif s.type == "active" then
                        local removeState = removeTab[2]
                        if removeState ~= 0 then
                            table.insert(returnSkillInfo, s)
                        end
                    elseif s.type == "chain" then
                        local removeState = removeTab[3]
                        if removeState ~= 0 then
                            table.insert(returnSkillInfo, s)
                        end
                    elseif s.type == "extra" then
                        local removeState = removeTab[4]
                        local inser = true
                        if removeState and removeState == 1 then
                            table.insert(returnSkillInfo, s)
                        end
                    end
                end
            else
                returnSkillInfo = skillinfo
            end
        else
            returnSkillInfo = skillinfo
        end
    else
        returnSkillInfo = skillinfo
    end

    return returnSkillInfo
end
function UIPetModule:GetModule(type)
    return GameGlobal.GetModule(type)
end
---@generic T:GameModule, K:UIModule
---@param gameModuleProto T
---@return K
function UIPetModule:GetUIModule(gameModuleProto)
    return GameGlobal.GetUIModule(gameModuleProto)
end

function UIPetModule:StartTask(func, ...)
    GameGlobal.TaskManager():StartTask(func, ...)
end

function UIPetModule:GetAttributeIconData(pstID)
    local petInfo = self._petModule:GetPet(pstID)
    if petInfo == nil then
        return nil
    end
    local attrIconData = nil
    local cfgKey = ""
    local firstElement = petInfo:GetPetFirstElement()
    local secondElement = petInfo:GetPetSecondElement()
    local grade = petInfo:GetPetGrade()
    --找策划确定什么时候有第二属性
    if secondElement == nil then
        secondElement = 0
    end
    cfgKey = firstElement .. "_" .. secondElement
    local cfg = Cfg.pet_attr_config[cfgKey]
    if cfg then
        attrIconData = {}
        local colorValue = string.split(cfg.attColor, "|")
        attrIconData.icon = cfg.icon
        attrIconData.attrIcon = cfg.attrIcon
        attrIconData.arrayColor = {}
        for key, value in pairs(colorValue) do
            table.insert(attrIconData.arrayColor, value)
        end
    end
    return attrIconData
end

PetSkillMainType = {
    fight = 0,
    work = 1
}

_enum("PetSkillMainType", PetSkillMainType)
SkillSubType = {
    major = 1,
    chain = 2,
    captain = 3
}
_enum("SkillSubType", SkillSubType)

--region GetAwakeSpriteName
---@param petId number 宝宝模板id
---@param awake number 觉醒等级
function UIPetModule.GetAwakeSpriteName(petId, awake)
    local cfgs = Cfg.cfg_pet_grade {PetID = petId}
    if not cfgs or #cfgs <= 0 then
        Log.error("###[UIPetModule] cfg_pet_grade is nil ! id --> ",petId)
        return PetAwakeSpriteName[2][0]
    end
    local max = 0
    for _, value in pairs(cfgs) do
        if value.Grade == -1 then
        else
            max = max + 1
        end
    end
    return PetAwakeSpriteName[max][awake]
end
function UIPetModule.GetAwakeSpriteNameByParam(max, awake)
    return PetAwakeSpriteName[max][awake]
end

function UIPetModule.GetAwakeSpriteGlowName(petId, awake)
    local cfgs = Cfg.cfg_pet_grade {PetID = petId}
    if not cfgs or #cfgs <= 0 then
        return PetAwakeSpriteGlowName[2][0]
    end
    local hasAwake3 = true
    for _, value in pairs(cfgs) do
        if value.Grade == -1 then
            hasAwake3 = false
            break
        end
    end
    if hasAwake3 then
        return PetAwakeSpriteGlowName[3][awake]
    end
    return PetAwakeSpriteGlowName[2][awake]
end
--endregion

---跳转到光灵详情下的指定强化界面,跳转后的UI栈:主界面|光灵列表|光灵详情|指定的强化界面
---@param pstid number 光灵pstid
---@param uiname string 
function UIPetModule:JumpToPetUI(pstid, uiName)
    --支持列表
    local list = {
        ["UIBreakController"] = true,
        ["UIPetEquipUpLevelController"] = true,
        ["UIGradeInterfaceController"] = true
    }
    if not list[uiName] then
        Log.fatal("UIPetModule:JumpToPetUI() 暂不支持前往 ", uiName, " 界面的跳转")
        return
    end

    ---@type Pet
    local pet = self._petModule:GetPet(pstid)
    if not pet then
        Log.fatal("UIPetModule:JumpToPetUI() 找不到对应pet pstid:", pstid)
        return
    end

    --数据组织
    local openDialogListInfo = OpenDialogListInfo:New()
    openDialogListInfo:AddUIInfo("UIHeartSpiritController")
    openDialogListInfo:AddUIInfo("UISpiritDetailGroupController", pet:GetTemplateID())
    if uiName == "UIBreakController" then
        openDialogListInfo:AddUIInfo(uiName, pet:GetTemplateID())
    elseif uiName == "UIPetEquipUpLevelController" then
        openDialogListInfo:AddUIInfo("UIPetEquipController", pet)
        openDialogListInfo:AddUIInfo(uiName, pet)
    elseif uiName == "UIGradeInterfaceController" then
        openDialogListInfo:AddUIInfo(uiName, pet:GetTemplateID())
    end

    --UI跳转
    GameGlobal.UIStateManager():SwitchStateWithDialogList(UIStateType.UIMain, openDialogListInfo, true)
end


--某些模式下 低于指定值的光灵会被提升
function UIPetModule.ProcessSinglePetEnhance(oriPet)
    local outIsEnhanced = false
    if not oriPet then
        return oriPet,outIsEnhanced
    end
    local outPet = oriPet
    local module = GameGlobal.GetModule(MissionModule)
    local ctx = module:TeamCtx()
    if ctx.teamOpenerType == TeamOpenerType.Campaign then--sjs_todo 赛季 和 活动
        local param = ctx:GetParam()
        if param then
            local missionId = param[1]
            local missionComponentId = nil
            if param[3] then
                local keyMap = param[3]
                missionComponentId = keyMap[ECampaignMissionParamKey.ECampaignMissionParamKey_ComCfgId]
            end
            
            if missionComponentId then
                local campaignModule = GameGlobal.GetModule(CampaignModule)
                local usePet,isEnhanced = campaignModule:ProcressPetEnhance(oriPet,missionComponentId)
                if isEnhanced then
                    outPet = usePet
                    outIsEnhanced = true
                end
            end
        end
        return outPet,outIsEnhanced
    elseif ctx.teamOpenerType == TeamOpenerType.Camp_Diff then
        local param = ctx:GetParam()
        if param then
            ---@type DifficultyMissionComponent
            local diffCpt = param[5]
            if diffCpt then
                local missionComponentId = diffCpt:GetComponentCfgId()
                if missionComponentId then
                    local campaignModule = GameGlobal.GetModule(CampaignModule)
                    local usePet,isEnhanced = campaignModule:ProcressPetEnhance(oriPet,missionComponentId)
                    if isEnhanced then
                        outPet = usePet
                        outIsEnhanced = true
                    end
                end
            end
        end
        return outPet,outIsEnhanced
    elseif ctx.teamOpenerType == TeamOpenerType.Season then
        local ctxParam = ctx.param
        if ctxParam then
            local missionId = ctxParam[1]
            local seasonModule = GameGlobal.GetModule(SeasonModule)
            local usePet,isEnhanced = seasonModule:ProcressPetEnhance(oriPet,missionId)
            if isEnhanced then
                outPet = usePet
                outIsEnhanced = true
            end
        end
        return outPet,outIsEnhanced
    else
        return oriPet,outIsEnhanced
    end
end

UIPetModule.prof2TexKey = {
    [2001] = "str_pet_tag_job_name_color_change",
    [2002] = "str_pet_tag_job_name_return_blood",
    [2003] = "str_pet_tag_job_name_attack",
    [2004] = "str_pet_tag_job_name_function"
}

function UIPetModule.GetPetProfTxtKey(pet)
    local prof = pet:GetProf()
    return UIPetModule.GetPetProfTxtKeyByProf(prof)
end

function UIPetModule.GetPetProfTxtKeyByProf(prof)
    return UIPetModule.prof2TexKey[prof]
end