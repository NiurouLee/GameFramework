_class("ResourceHelper", Singleton)
ResourceHelper = ResourceHelper

function ResourceHelper:Constructor()
    self._PetSKill = nil;-- cfg_pet_skill 资源整合
    self._StoryAffinity = nil;
    self._PetEquip = nil;
end

--获取 ResPetSkill 数据
function ResourceHelper:GetPetSKill()
    if not self._PetSKill then
        self._PetSKill = ResPetSkill:New();
    end

    return self._PetSKill;     
end

--获取 ResStoryAffinity 数据
function ResourceHelper:GetStoryAffinity()
    if not self._StoryAffinity then
        self._StoryAffinity = ResStoryAffinity:New();
    end

    return self._StoryAffinity;     
end

--获取 ResPetEquip 数据
function ResourceHelper:GetPetEquip()
    if not self._PetEquip then
        self._PetEquip = ResPetEquip:New();
    end

    return self._PetEquip;     
end

--获取 装备精炼 数据
function ResourceHelper:GetPetEquipRefine()
    if not self._PetEquipRefine then
        self._PetEquipRefine = ResPetEquipRefine:New();
    end

    return self._PetEquipRefine;     
end