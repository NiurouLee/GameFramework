--[[------------------------------------------------------------------------------------------
    SkillInfoComponent : 玩家身上的技能信息
]] --------------------------------------------------------------------------------------------

_class("ChainSkillIDSelector", Object)
---@class ChainSkillIDSelector
ChainSkillIDSelector = ChainSkillIDSelector
function ChainSkillIDSelector:Constructor()
    --chainCount skillID
    self._rules = {}
    self._current = "default"
end

function ChainSkillIDSelector:AddRule(name, value)
    self._rules[name] = value
    self._current = name
end

function ChainSkillIDSelector:RemoveRule(name)
    self._rules[name] = nil
    self._current = "default"
end

function ChainSkillIDSelector:GetRule(name)
    if not name then
        name = self._current
    end
    return self._rules[name]
end

_class("SkillInfoComponent", Object)
---@class SkillInfoComponent: Object
SkillInfoComponent = SkillInfoComponent

function SkillInfoComponent:Constructor(normal_skill_config_id, chain_skill_config_id, super_skill_config_id,extra_active_skill_id_list)
    self._normal_skill_config_id = normal_skill_config_id
    self._active_skill_config_id = super_skill_config_id
    self._extra_active_skill_config_id_list = extra_active_skill_id_list
    self._passive_skill_config_id = 0
    ---强化Buff列表
    self._intensify_buff_list = nil
    ---装备强化Buff数值
    self._equipIntensifyParam = nil
    --连锁技ID选择器
    self._chainSkillIDSelector = ChainSkillIDSelector:New()
    self._chainSkillIDSelector:AddRule("default", chain_skill_config_id)
    --buff修改连锁技释放条件为n，但只释放m阶连锁技 --{{Chian=新步数,OriChainSkillIndex=对应的现有技能阶段序号},...}
    self._buffOverlayChainSkillStepIndexTb = nil
    self._lockedChainSkillIndex = {}
    self._ignore_cd_update_extra_skill_index_list = {}--回合开始不更新cd的附加主动技（凯雅）_extra_active_skill_config_id_list的序号
    self._variantActiveSkillInfo = nil--主动技变体信息 key:技能id，value：变体技能id列表
end

function SkillInfoComponent:GetNormalSkillID()
    return self._normal_skill_config_id
end

function SkillInfoComponent:SetNormalSkillID(id)
    self._normal_skill_config_id = id
end

function SkillInfoComponent:GetActiveSkillID()
    return self._active_skill_config_id
end

--替换主动技
function SkillInfoComponent:SetActiveSkillID(activeSkillID)
    self._active_skill_config_id = activeSkillID
end
--附加主动技列表
function SkillInfoComponent:GetExtraActiveSkillIDList()
    return self._extra_active_skill_config_id_list
end
--附加主动技列表
function SkillInfoComponent:SetExtraActiveSkillIDList(extraActiveSkillIDList)
    self._extra_active_skill_config_id_list = extraActiveSkillIDList
end
--根据技能序号取技能ID 主动技序号1 附加技从2开始
function SkillInfoComponent:GetSkillIDByIndex(skillIndex)
    local skillID = 0
    if skillIndex then
        if skillIndex == 1 then
            skillID = self:GetActiveSkillID()
        else
            if self._extra_active_skill_config_id_list then
                local extraIndex = skillIndex - 1
                if extraIndex > 0 and extraIndex <= #self._extra_active_skill_config_id_list then
                    skillID = self._extra_active_skill_config_id_list[extraIndex]
                end
            end
        end
    else
        skillID = self:GetActiveSkillID()
    end
    return skillID
end
function SkillInfoComponent:GetChainSkillIDSelector()
    return self._chainSkillIDSelector
end

---@return number,number 根据连线数拿到配置里的连锁技id和索引
function SkillInfoComponent:GetChainSkillConfigID(chain, extraChains)
    --首先从buff替换的连锁数据里根据连线数拿到里的连锁技id和索引
    local buffOverlaySkillID,buffOverlaySkillIndex = self:_GetChainSkillConfigIDInBuffOverlay(chain)
    if buffOverlaySkillID and buffOverlaySkillID > 0 then
        return buffOverlaySkillID,buffOverlaySkillIndex
    end
    local rule = self._chainSkillIDSelector:GetRule()
    if rule then
        local len = #rule
        for i = len, 1, -1 do
            local v = rule[i]
            local requiredVal = v.Chain
            if extraChains and extraChains[v.Skill] then
                --关于这里做减法：ChangeExtraChainSkillReleaseFixForSkill为了保持参数意义一致
                --配置为正数时表示更容易释放连锁技能
                requiredVal = requiredVal - extraChains[v.Skill]
            end
            if (chain >= requiredVal) then
                if (not table.icontains(self._lockedChainSkillIndex, i)) then
                    return v.Skill, i
                else
                    Log.info("SkillInfoComponent: chain skill index [", i, "] is locked. ")
                end
            end
        end
    end
    return 0, 0
end
---@return number,number 首先从buff替换的连锁数据里根据连线数拿到里的连锁技id和索引
function SkillInfoComponent:_GetChainSkillConfigIDInBuffOverlay(chain)
    if self._buffOverlayChainSkillStepIndexTb then
        local overlayTb = self._buffOverlayChainSkillStepIndexTb
        if overlayTb then
            local len = #overlayTb
            for i = len, 1, -1 do
                ---{Chain=xxx,OriChainSkillIndex=xxx}
                local v = overlayTb[i]
                if (chain >= v.Chain) then
                    local useIndex = v.OriChainSkillIndex
                    local skillID = self:_GetOriChainSkillConfigInfoByIndex(useIndex)
                    if skillID and skillID > 0 then
                        return skillID, useIndex
                    end
                end
            end
        end
    end
    return 0,0 
end
--按阶取连锁技id
---@return number,number 根据连线数拿到配置里的连锁技id和步数需求
function SkillInfoComponent:_GetOriChainSkillConfigInfoByIndex(index)
    local rule = self._chainSkillIDSelector:GetRule()
    if rule then
        local len = #rule
        for i = 1, len do
            local v = rule[i]
            if i == index then
                return v.Skill,v.Chain
            end
        end
    end
    return 0, 0
end
function SkillInfoComponent:GetChainSkillLevel(skillId)
    local rule = self._chainSkillIDSelector:GetRule()
    if rule then
        local len = #rule
        for i = len, 1, -1 do
            local v = rule[i]
            if v.Skill == skillId then
                return i
            end
        end
    end
    return 0
end

function SkillInfoComponent:SetPassiveSkillID(id)
    self._passive_skill_config_id = id
end

function SkillInfoComponent:GetPassiveSkillID()
    return self._passive_skill_config_id
end

function SkillInfoComponent:SetIntensifyBuffList(buffList)
    self._intensify_buff_list = buffList
end

function SkillInfoComponent:GetIntensifyBuffList()
    return self._intensify_buff_list
end

function SkillInfoComponent:SetEquipIntensifyParam(equipIntensifyParam)
    self._equipIntensifyParam = equipIntensifyParam
end

function SkillInfoComponent:GetEquipIntensifyParam()
    return self._equipIntensifyParam
end

function SkillInfoComponent:LockChainSkillIndex(index)
    if not table.icontains(self._lockedChainSkillIndex, index) then
        table.insert(self._lockedChainSkillIndex, index)
    end
end

function SkillInfoComponent:UnlockChainSkillIndex(index)
    table.removev(self._lockedChainSkillIndex, index)
end

function SkillInfoComponent:UnlockAllChainSkill()
    self._lockedChainSkillIndex = {}
end

function SkillInfoComponent:SetExtraSkillIgnoreCdUpdate(extraSkillIndex,bIgnore)
    if bIgnore then
        if not table.icontains(self._ignore_cd_update_extra_skill_index_list, extraSkillIndex) then
            table.insert(self._ignore_cd_update_extra_skill_index_list, extraSkillIndex)
        end
    else
        table.removev(self._ignore_cd_update_extra_skill_index_list, extraSkillIndex)
    end
end
function SkillInfoComponent:IsExtraSkillIgnoreCdUpdate(extraSkillIndex)
    if table.icontains(self._ignore_cd_update_extra_skill_index_list,extraSkillIndex) then
        return true
    end
    return false
end
--buff修改连锁技释放条件为n，但只释放m阶连锁技
function SkillInfoComponent:BuffOverlayChainSkillByStepAndOriIndexSkill(overlayInfo)
    ---overlayInfo {{Chain=1,OriSkillIndex=1},...}
    ---Chain 释放步数
    ---OriSkillIndex  取现有技能用的阶数
    if overlayInfo then
        self._buffOverlayChainSkillStepIndexTb = overlayInfo
    end
end
function SkillInfoComponent:ClearBuffOverlayChainSkillInfo()
    self._buffOverlayChainSkillStepIndexTb = nil
end


--主动技变体信息
function SkillInfoComponent:GetVariantActiveSkillInfo()
    return self._variantActiveSkillInfo
end
--主动技变体信息
function SkillInfoComponent:SetVariantActiveSkillInfo(info)
    self._variantActiveSkillInfo = info
end

function SkillInfoComponent:SetPassiveCountBuffIDArray(t)
    self._passiveCountBuffIDArray = t
end

function SkillInfoComponent:GetPassiveCountBuffIDArray()
    return self._passiveCountBuffIDArray or {}
end

function SkillInfoComponent:IsBuffIDPassiveCount(id)
    return table.icontains(self._passiveCountBuffIDArray, id)
end

function SkillInfoComponent:SetCountActiveSkillEnergy(b)
    self._countActiveSkillEnergy = b
end

function SkillInfoComponent:IsActiveSkillEnergyCount()
    return self._countActiveSkillEnergy
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return SkillInfoComponent
function Entity:SkillInfo()
    return self:GetComponent(self.WEComponentsEnum.SkillInfo)
end

function Entity:HasSkillInfo()
    return self:HasComponent(self.WEComponentsEnum.SkillInfo)
end

function Entity:AddSkillInfo(normal_skill_config_id, chain_skill_config_id, super_skill_config_id,extra_active_skill_id_list)
    local index = self.WEComponentsEnum.SkillInfo
    local component = SkillInfoComponent:New(normal_skill_config_id, chain_skill_config_id, super_skill_config_id,extra_active_skill_id_list)
    self:AddComponent(index, component)
end

function Entity:ReplaceSkillInfo(normal_skill_config_id, chain_skill_config_id, super_skill_config_id,extra_active_skill_id_list)
    local index = self.WEComponentsEnum.SkillInfo
    local component = SkillInfoComponent:New(normal_skill_config_id, chain_skill_config_id, super_skill_config_id,extra_active_skill_id_list)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveSkillInfo()
    if self:HasSkillInfo() then
        self:RemoveComponent(self.WEComponentsEnum.SkillInfo)
    end
end
