---@class UIPetEquipLvIcon:UICustomWidget
_class("UIPetEquipLvIcon", UICustomWidget)
UIPetEquipLvIcon = UIPetEquipLvIcon

---@param pet MatchPet
---@param showLv boolean [true] = 显示等级数字 [false] = 不显示等级数字
---@param txtLvExtra string 等级的附加文字，可为 nil
---@param posLv Vector3 设置等级文字位置，可为 nil
function UIPetEquipLvIcon:SetData(pet, showLv, txtLvExtra, posLv)
    if not pet then
        return
    end

    -- 解锁状态
    local unlock = (pet:GetPetGrade() > 0)
    self:_SetLockState(unlock)

    -- 图标等级
    local state = self:_GetIconState(pet)
    self:_SetIconState(state)

    -- 装备等级
    if showLv then
        txtLvExtra = txtLvExtra or ""
        local lv = txtLvExtra .. pet:GetEquipLv()
        self:_SetText(state, lv, posLv)
    end
end

function UIPetEquipLvIcon:_SetLockState(unlock)
    self:GetGameObject("_unlock"):SetActive(unlock) 
    self:GetGameObject("_locked"):SetActive(not unlock) 
end

function UIPetEquipLvIcon:_GetIconState(pet)
    local grade = -1 -- [-1] = 没有精炼, [0-3] = 精炼 0-3 级

    if UIPetEquipHelper.HasRefine( pet:GetTemplateID()) then
        grade = pet:GetEquipRefineLv()
    end
    --------------------------------------------------------------------------------
    -- hack: 国服还未开放精炼，相关代码还没合并

    -- local cfgs = Cfg.cfg_pet_equip_refine { PetID = pet:GetTemplateID() }
    -- local isRefine = cfgs and table.count(cfgs) ~= 0 -- 是否有精炼
    -- if isRefine then
    --     local refineLv = pet._data.equip_refine_lv  -- 精炼等级，应该使用获取精炼等级的接口
    --     grade = refineLv
    -- end
    --------------------------------------------------------------------------------
    
    return grade
end

function UIPetEquipLvIcon:_SetIconState(state)
    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, 
        {
            [-1] = {"_icon_a", "_locked_a"},
            [0] = {"_icon_b0", "_locked_b"},
            [1] = {"_icon_b1", "_locked_b"},
            [2] = {"_icon_b2", "_locked_b"},
            [3] = {"_icon_b3", "_locked_b"}
        }
    )
    UIWidgetHelper.SetObjGroupShow(objs, state)
end

function UIPetEquipLvIcon:_SetText(state, lv, pos)
    local tb = {"_txtLv_a", "_txtLv_b"}
    for i, v in ipairs(tb) do
        self:GetGameObject(v):SetActive(false)
    end

    local widgetName = (state == -1) and tb[1] or tb[2]
    UIWidgetHelper.SetLocalizationText(self, widgetName, lv)
    self:GetGameObject(widgetName):SetActive(true)

    if pos then
        local trans = self:GetUIComponent("RectTransform", widgetName)
        trans.anchoredPosition = pos
    end
end
