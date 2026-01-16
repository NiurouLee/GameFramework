--[[------------------------------------------------------------------------------------------
    ResPetEquipRefineRefine：装备精炼辅助类，方便根据光灵ID和等级查询数据
]] --------------------------------------------------------------------------------------------

_class("ResPetEquipRefine", Object)
---@class ResPetEquipRefine:Object
ResPetEquipRefine = ResPetEquipRefine

function ResPetEquipRefine:Constructor()
    self._Res = {} -- 实际转存的数据表
    self._MaxLv = {}

    self:InitResPetEquipRefine()
end

function ResPetEquipRefine:InitResPetEquipRefine()
    self._Res = {}
    local cfg = Cfg.cfg_pet_equip_refine {}
    for k, v in pairs(cfg) do
        if self._Res[v.PetID] == nil then
            self._Res[v.PetID] = {}
        end
        
        if self._MaxLv[v.PetID] == nil or self._MaxLv[v.PetID] < v.Level then
            self._MaxLv[v.PetID] = v.Level
        end
        
        self._Res[v.PetID][v.Level] = v
    end
end

--获取cfg_pet_equip_refine表里的单行数据
---@return cfg_pet_equip_refine 某一行
function ResPetEquipRefine:GetRes(petId, level)
    if petId == nil or level == nil then
        return nil
    end

    if self._Res[petId] == nil then
        ---不是所有光灵都有装备精炼，故去掉此处报错
        --Log.error("ResPetEquipRefine:GetRes petId error ", petId)
        return nil
    end

    local res = self._Res[petId][level]
    if res == nil then
        Log.error("ResPetEquipRefine:GetRes petId level error ", petId, ", ", level)
        return nil
    end
    return res
end

--获取pet的最大装备精炼等级
---@return value或者nil
function ResPetEquipRefine:GetMaxLv(petId)
    local ns = self._MaxLv[petId]
    if ns == nil then
        Log.error("ResPetEquipRefine:GetMaxLv petId error ", petId)
        return nil
    end

    return ns
end