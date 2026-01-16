_class("ResPetSkill", Object)
ResPetSkill = ResPetSkill

function ResPetSkill:Constructor()
    self._SkillRes = {} -- cfg_pet_skill 资源整合

    self:Init()
end

--重载cfg_pet_skill.lua表格资源
--优化引用
function ResPetSkill:Init()
    self._SkillRes = {}
    local cfg = Cfg.cfg_pet_skill {}
    for k, v in pairs(cfg) do
        if self._SkillRes[v.PetID] == nil then
            self._SkillRes[v.PetID] = {}
        end
        if self._SkillRes[v.PetID][v.Grade] == nil then
            self._SkillRes[v.PetID][v.Grade] = {}
        end
        --[[if self._SkillRes[v.PetID][v.Grade][v.Awakening] == nil then
            self._SkillRes[v.PetID][v.Grade][v.Awakening] = {};
        end--]]
        self._SkillRes[v.PetID][v.Grade][v.Awakening] = v
    end
end

--获取cfg_pet_skill行级数据
---@return cfg_pet_skill某一行
function ResPetSkill:GetSKill(petId, grade, awakening)
    if petId == nil or grade == nil or awakening == nil then
        return nil
    end

    if self._SkillRes[petId] == nil then
        Log.error("ResPetSkill:GetSKill petId error ", petId)
        return nil
    end

    if self._SkillRes[petId][grade] == nil then
        Log.error("ResPetSkill:GetSKill petId grade error ", petId, ", ", grade)
        return nil
    end

    local skill = self._SkillRes[petId][grade][awakening]
    if skill == nil then
        Log.error("ResPetSkill:GetSKill petId grade awakening error ", petId, ", ", grade, ", ", awakening)
        return nil
    end
    return skill
end

--获取pet的普通技能
---@return value或者nil
function ResPetSkill:GetNormalSKill(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    return ns.NormalSkill
end

--获取pet的普通技能
---@return value或者nil
function ResPetSkill:GetActiveSkill(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    return ns.ActiveSkill
end

--获取pet的附加主动技能
---@return value或者nil
function ResPetSkill:GetExtraActiveSkill(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    return ns.ExtraActiveSkill
end

--获取pet的被动技能
---@return value或者nil
function ResPetSkill:GetPassiveSkill(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    return ns.PassiveSkill
end

--获取pet的强化Buff
---@return value或者nil
function ResPetSkill:GetIntensifyBuffList(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    return ns.IntensifyBuff
end

--获取pet的连锁技能
---@return table或者nil
function ResPetSkill:GetChainSkill(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    -- WARN: 200001, 200002, nil, 200004 <-这是第四连锁而不是第三，但这么写就会变成第三连锁技，前面有nil同理
    local ss = {ns.ChainSkill1, ns.ChainSkill2, ns.ChainSkill3, ns.ChainSkill4}

    return ss
end

--获取pet的生活技能
---@return table或者nil
function ResPetSkill:GetWorkSkill(petId, grade, awakening)
    local ns = self:GetSKill(petId, grade, awakening)
    if ns == nil then
        return nil
    end

    local ss = {ns.WorkSkill1, ns.WorkSkill2, ns.WorkSkill3}
    return ss
end
