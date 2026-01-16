---消灭星星Pet 主要是重写技能相关的获取接口
---消灭星星的光灵：无普攻、连锁、附加主动技、被动技，只有特殊主动技
---@class PopStarMatchPet:MatchPet
_class("PopStarMatchPet", MatchPet)
PopStarMatchPet = PopStarMatchPet

--普攻技能id
function PopStarMatchPet:GetNormalSkill()
    return nil
end

--主动技能id
function PopStarMatchPet:GetPetActiveSkill(grade, awakening)
    local tmpID = self:GetTemplateID()

    local petCfg = Cfg.cfg_popstar_pet_list[tmpID]
    if not petCfg then
        Log.error("PopStarPet cfg_popstar_pet_list err: pet template id = ", tmpID)
    end

    return petCfg.SkillId
end

--附加主动技能id列表
function PopStarMatchPet:GetPetExtraActiveSkill(grade, awakening)
    return nil
end

--被动技能id
function PopStarMatchPet:GetPetPassiveSkill(grade, awakening)
    return nil
end

--连锁技ID
function PopStarMatchPet:GetPetChainSkills(grade, awakening)
    return nil
end

--连锁技数据，给局内用
function PopStarMatchPet:GetChainSkillInfo(grade, awakening)
    return {}
end
