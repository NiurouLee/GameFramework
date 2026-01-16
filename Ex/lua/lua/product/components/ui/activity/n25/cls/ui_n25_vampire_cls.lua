--region VampireTalentTier
---@class N25Data:CampaignDataBase
---@field pets VampirePet[] 精灵列表
---@field tiers VampireTalentTier[] 天赋技能层级列表
---@field skillIdToUnlock number 要播放解锁动效的技能id

--region Component ComponentInfo
function N25Data:GetComponentId()
    return ECampaignN25ComponentID.ECAMPAIGN_N25_BLOODSUCKER
end
function N25Data:GetComponentCfgId()
    local c = self:GetComponentVampire()
    return c:GetComponentCfgId()
end

---@return BloodsuckerComponent 吸血鬼组件
function N25Data:GetComponentVampire()
    local c = self.activityCampaign:GetComponent(self:GetComponentId())
    return c
end
---@return BloodsuckerComponentInfo 吸血鬼组件信息
function N25Data:GetComponentInfoVampire()
    local cInfo = self.activityCampaign:GetComponentInfo(self:GetComponentId())
    return cInfo
end
---@return TalentTreeInfo 获取BloodsuckerComponentInfo中的talent_info
function N25Data:GetTalentTreeInfo()
    local cInfo = self:GetComponentInfoVampire()
    return cInfo.talent_info
end
--endregion

--region Cfg
--cfg_component_bloodsucker_talent_skill
function N25Data:GetCfgComponentBloodsuckerTalentSkill()
    local cfgs = Cfg.cfg_component_bloodsucker_talent_skill {ComponentID = self:GetComponentCfgId()}
    return cfgs
end
--cfg_component_bloodsucker_talent_level
function N25Data:GetCfgComponentBloodsuckerTalentLevel()
    local cfgs = Cfg.cfg_component_bloodsucker_talent_level {ComponentID = self:GetComponentCfgId()}
    return cfgs
end
--endregion

---@param res AsyncRequestRes
function N25Data.CheckCode(res)
    local result = res:GetResult()
    if result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_SUCCESS then
        return true
    end
    ToastManager.ShowToast(StringTable.Get("str_activity_error_" .. result))
    if
        result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED or
            result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_NO_OPEN
     then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain) --活动结束，切到主界面
    elseif result == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_CLOSE then --吸血鬼结束，切到活动主界面
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIActivityN25MainController)
    end
    return false
end

function N25Data:InitVampire()
    self:InitVampirePets()
    self:InitVampireTiers()
end
function N25Data:InitVampirePets()
    self.pets = {}
    local petIds = UIN25VampireUtil.GetTryPetList(self:GetComponentCfgId()) or {}
    for index, petId in ipairs(petIds) do
        local pet = VampirePet:New(petId)
        table.insert(self.pets, pet)
    end
end
function N25Data:InitVampireTiers()
    self.tiers = {}
    local talentTreeInfo = self:GetTalentTreeInfo()
    local leftTalent = self:GetTalentLeft()
    local cfgs = self:GetCfgComponentBloodsuckerTalentSkill()
    local prevTier = nil
    for key, cfgv in pairs(cfgs) do
        local tier = VampireTalentTier:New()
        tier.id = cfgv.ID
        tier.row = cfgv.Row
        tier.unlockTalent = cfgv.NeedTalentPoint or 0

        --region VampireTalentSkill
        ---@type TalentTreeLayerInfo
        local info = talentTreeInfo.infos[cfgv.ID]
        tier.skills = {}
        for i, cfgvSkill in ipairs(cfgv.Skill) do
            local skill = VampireTalentSkill:New()
            skill.skillType = cfgvSkill[1] == 0 and VampireTalentSkillType.Talent or VampireTalentSkillType.Role
            local skillId = cfgvSkill[2]
            skill.skillId = skillId
            skill.index = i - 1
            if info then
                local skillNode = info.skill_nodes[skill.index]
                if skillNode then
                    skill.level = skillNode.level
                end
            end
            skill.maxLevel = cfgvSkill[3]
            tier.prev = prevTier
            prevTier = tier
            table.insert(tier.skills, skill)
        end
        --endregion

        if cfgv.RelicId then
            tier.relic = VampireTalentRelic:New(cfgv.RelicId)
        end
        table.insert(self.tiers, tier)
    end
end

---@return VampirePet
function N25Data:GetPetByTplId(tplId)
    for index, pet in ipairs(self.pets) do
        if pet:TplId() == tplId then
            return pet
        end
    end
end
---@return number 获取吸血鬼结束时间
function N25Data:GetVimpireEndTime()
    local cInfo = self:GetComponentInfoVampire()
    return cInfo.m_close_time
end
---@return number, number , number 天赋等级，当前天赋经验，升级所需天赋经验
function N25Data:GetTalentLevelExp()
    local talentTreeInfo = self:GetTalentTreeInfo()
    local talent_level = talentTreeInfo.talent_level
    local upgradeExp = 0
    local cfg = self:GetCfgComponentBloodsuckerTalentLevel()
    if cfg then
        for key, cfgv in pairs(cfg) do
            if cfgv.Level == talent_level then
                upgradeExp = cfgv.Exp
                break
            end
        end
    end
    return talent_level, talentTreeInfo.cur_exp, upgradeExp
end
---@return VampireTalentTier 根据层id返回层
function N25Data:GetTierById(id)
    for index, tier in ipairs(self.tiers) do
        if tier.id == id then
            return tier
        end
    end
end
---@return VampireTalentTier 根据技能id获取该技能所在层
function N25Data:GetTierBySkillId(skillId)
    for _, tier in ipairs(self.tiers) do
        for _, skill in ipairs(tier.skills) do
            if skill.skillId == skillId then
                return tier
            end
        end
    end
end
---@return VampireTalentTier 根据层行数返回层
function N25Data:GetTierByRow(row)
    for index, tier in ipairs(self.tiers) do
        if tier.row == row then
            return tier
        end
    end
end
---@return VampireTalentSkill 根据技能id获取技能
function N25Data:GetSkillBySkillId(skillId)
    for index, tier in ipairs(self.tiers) do
        for index, skill in ipairs(tier.skills) do
            if skill.skillId == skillId then
                return skill
            end
        end
    end
end
---@return VampireTalentSkill[] 空裔技能列表
function N25Data:GetRoleSkills()
    local t = {}
    for index, tier in ipairs(self.tiers) do
        for index, skill in ipairs(tier.skills) do
            if skill.skillType == VampireTalentSkillType.Role then
                table.insert(t, skill)
            end
        end
    end
    return t
end
---@return VampireTalentSkill 获取第1个空裔技能
function N25Data:GetFstRoleSkill()
    for index, tier in ipairs(self.tiers) do
        for index, skill in ipairs(tier.skills) do
            if skill.skillType == VampireTalentSkillType.Role then
                return skill
            end
        end
    end
end
---@return VampireTalentSkill 获取当前装备的空裔技能
function N25Data:GetCurRoleSkill()
    local talentTreeInfo = self:GetTalentTreeInfo()
    local row = talentTreeInfo.select_row
    local index = talentTreeInfo.select_index
    for _, tier in ipairs(self.tiers) do
        if row == tier.row then
            for _, skill in ipairs(tier.skills) do
                if index == skill.index then
                    return skill
                end
            end
        end
    end
end
---@return boolean 当前是否有激活的空裔技能
function N25Data:IsRoleSkillActive()
    for index, tier in ipairs(self.tiers) do
        if tier:IsLock() then
            break
        else
            for index, skill in ipairs(tier.skills) do
                if skill.skillType == VampireTalentSkillType.Role and skill.level > 0 then
                    return true
                end
            end
        end
    end
    return false
end

---@return number, number 根据技能id获取技能所在行列
function N25Data:GetSkillRowIndexBySkillId(skillId)
    for _, tier in ipairs(self.tiers) do
        for _, skill in ipairs(tier.skills) do
            if skill.skillId == skillId then
                return tier.row, skill.index
            end
        end
    end
end
---@return number 已用天赋点
function N25Data:GetTalentUsed()
    local used = 0
    for _, tier in ipairs(self.tiers) do
        for _, skill in ipairs(tier.skills) do
            used = used + skill.level
        end
    end
    return used
end
---@return number 剩余天赋点
function N25Data:GetTalentLeft()
    local talentTreeInfo = self:GetTalentTreeInfo()
    return talentTreeInfo.cur_talent_point
end

--region Red
function N25Data:CheckRedTalentTree()
    local talent = self:GetTalentLeft()
    return talent > 0
end
-- function N25Data:CheckRedChallengeTask()
--     return false
-- end
--endregion

--endregion

--region VampireTalentTier
---@class VampireTalentTier:Object
---@field id number ID
---@field row number 行号
---@field unlockTalent number 解锁所需天赋点数
---@field skills VampireTalentSkill[] 天赋技能列表
---@field relic VampireTalentRelic 圣物
---@field prev VampireTalentTier 前一行
_class("VampireTalentTier", Object)
VampireTalentTier = VampireTalentTier

function VampireTalentTier:Constructor()
    local mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = mCampaign:GetN25Data()
end
---@return boolean 该层是否锁定
--[[
该层解锁条件
若 前一层有天赋技能 则
    之前层消耗点数之和≥当前层 and 前一层至少有1个激活
否则
    之前层消耗点数之和≥当前层
]]
function VampireTalentTier:IsLock()
    if self.row == 1 then --第1层默认解锁
        return false
    end
    local isUnlock = false

    local tiers = self.data.tiers
    local prevCost = 0 --之前所有行消耗之和
    for i, tier in ipairs(tiers) do
        if tier.row >= self.row then
            break
        end
        local tierCostPoint = tier:GetTotalSkillLevel()
        prevCost = prevCost + tierCostPoint
    end

    local costGECur = prevCost >= self.unlockTalent
    if self:IsPrevTierExistSkills(self.row) then
        if costGECur and self:GetPrevTierCost(self.row) > 0 then
            isUnlock = true
        end
    else
        if costGECur then
            isUnlock = true
        end
    end
    return not isUnlock
end
---@return number 获取本层升级技能消耗的天赋点
function VampireTalentTier:GetTotalSkillLevel()
    local level = 0
    for index, skill in ipairs(self.skills) do
        level = level + skill.level
    end
    return level
end
---@return VampireTalentTier 获取前一行
function VampireTalentTier:GetPrevTier(row)
    if row <= 1 then
        return nil
    end
    local tier = self.data:GetTierByRow(row - 1)
    return tier
end
---@return boolean 行row的前一行是否存在天赋技能
function VampireTalentTier:IsPrevTierExistSkills(row)
    local tier = self:GetPrevTier(row)
    if tier then
        if tier.skills and table.count(tier.skills) > 0 then
            return true
        end
    end
    return false
end
---@return number 行row的前一行消耗点数
function VampireTalentTier:GetPrevTierCost(row)
    local tier = self:GetPrevTier(row)
    if tier then
        return tier:GetTotalSkillLevel()
    end
    return 0
end
--endregion

--region VampireTalentSkill
---@class VampireTalentSkill:Object
---@field skillType VampireTalentSkillType 技能类型
---@field skillId number 技能Id
---@field index number 技能索引，基于0
---@field level number 技能当前等级
---@field maxLevel number 技能最高等级
_class("VampireTalentSkill", Object)
VampireTalentSkill = VampireTalentSkill

function VampireTalentSkill:Constructor()
    self.level = 0
end

---@return string, string, string 技能icon，技能名，技能描述
function VampireTalentSkill:IconNameDesc()
    local cfgv = Cfg.cfg_mini_maze_talent[self.skillId]
    if not cfgv then
        Log.fatal("### no data in cfg_mini_maze_talent.", self.skillId)
        return
    end
    return cfgv.Icon, StringTable.Get(cfgv.Name), StringTable.Get(cfgv.Desc)
end
---@return number, number 技能当前等级，技能最高等级
function VampireTalentSkill:CurMaxLevel()
    return self.level, self.maxLevel
end
---@return boolean 是否激活
function VampireTalentSkill:IsActive()
    return self.level > 0
end
---@return boolean 等级已满
function VampireTalentSkill:IsLevelMax()
    return self.level >= self.maxLevel
end

---@class VampireTalentSkillType
---@field Talent number 天赋技能
---@field Role number 空裔技能
_enum(
    "VampireTalentSkillType",
    {
        Talent = 0,
        Role = 1
    }
)
VampireTalentSkillType = VampireTalentSkillType
--endregion

--region VampireTalentRelic
---@class VampireTalentRelic:Object
---@field itemId number 道具id
_class("VampireTalentRelic", Object)
VampireTalentRelic = VampireTalentRelic

function VampireTalentRelic:Constructor(itemId)
    self.itemId = itemId
end
function VampireTalentRelic:GetItemCfg()
    local cfgv = Cfg.cfg_item[self.itemId]
    if not cfgv then
        Log.fatal("### no data in cfg_item", self.itemId)
        return
    end
    return cfgv
end
function VampireTalentRelic:IconNameDesc()
    local cfg = self:GetItemCfg()
    if cfg then
        return cfg.Icon, StringTable.Get(cfg.Name), StringTable.Get(cfg.Intro) --RpIntro
    end
end
--endregion

--region VampirePet
---@class VampirePet:Object
---@field tplId number 模板id
_class("VampirePet", Object)
VampirePet = VampirePet

function VampirePet:Constructor(tplId)
    self.tplId = tplId
end
function VampirePet:TplId()
    return self.tplId
end
function VampirePet:CfgPet()
    local cfgv = Cfg.cfg_pet[self.tplId]
    if not cfgv then
        Log.fatal("### no data in cfg_pet", self.tplId)
    end
    return cfgv
end
function VampirePet:Icon()
    local cfgv = self:CfgPet()
    local icon = HelperProxy:GetInstance():GetPetTeamBody(self:TplId())
    return icon
end
--endregion
