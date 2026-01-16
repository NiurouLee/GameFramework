--[[
    时装ui数据结构
]]
-- 时装标签类型
--- @class PetSkinFlag
local PetSkinFlag = {
    PSF_NORMAL = 1, -- 普通
    PSF_COLLECTION = 2 -- 典藏
}
_enum("PetSkinFlag", PetSkinFlag)

-- 详情界面打开类型
--- @class PetSkinUiOpenType
local PetSkinUiOpenType = {
    PSUOT_SHOW_LIST = 1, -- 详情 时装列表
    PSUT_SHOP_DETAIL = 2, -- 商城详情
    PSUOT_TIPS = 3 -- 详情 不能购买
}
_enum("PetSkinUiOpenType", PetSkinUiOpenType)

-- 时装 界面 状态 类型
--- @class PetSkinStateType
local PetSkinStateType = {
    PSST_CUR_SKIN = 1,
    --当前时装
    PSST_CAN_USE = 2, -- 可使用
    PSST_NOT_OBTAIN = 3, -- 未获得
    PSST_SHOP_BUY = 4, -- 商城 购买
    PSST_SHOP_OBTAINED = 5 -- 商城 已获得
}
_enum("PetSkinStateType", PetSkinStateType)

-- 时装解锁类型
--- @class PetSkinUnlockType
local PetSkinUnlockType = {
    PSUT_BASE = 1,
    --基础时装
    PSUT_GRADE = 2, -- 觉醒时装
    PSUT_SHOP = 3, -- 购买
    PSUT_HauteCouture = 4, --高级时装
    PSUT_BattlePass = 5, --战斗通行证
    PSUT_Dream = 6 --梦境活动
}
_enum("PetSkinUnlockType", PetSkinUnlockType)

---@class DPetSkinDetailCard
_class("DPetSkinDetailCard", Object)
---@class DPetSkinDetailCard:Object
DPetSkinDetailCard = DPetSkinDetailCard

function DPetSkinDetailCard:Constructor(cfg)
    self.cfg = cfg
    self.unlock_CG = 0
    --是否解锁CG
    self.is_onbody = false --是否当前穿戴时装
    self.obtained = false --是否已拥有
    self.is_shop_detail = false --是否是商城购买详情界面中
    self.is_tips_detail = false -- 是否 tips 详情
end
---@public
---时装id
function DPetSkinDetailCard:GetSkinId()
    if self.cfg then
        return self.cfg.id
    end
    return 0
end
---@public
---设置是否是tips详情界面中
function DPetSkinDetailCard:SetIsTipsDetail(inShop)
    self.is_tips_detail = inShop
end
---@public
---是否是否是tips详情界面中
function DPetSkinDetailCard:IsTipsDetail()
    return self.is_tips_detail
end
---@public
---设置是否是商城购买详情界面中
function DPetSkinDetailCard:SetIsShopDetail(inShop)
    self.is_shop_detail = inShop
end
---@public
---是否是否是商城购买详情界面中
function DPetSkinDetailCard:IsShopDetail()
    return self.is_shop_detail
end
---@public
---设置是否已拥有
function DPetSkinDetailCard:SetObtained(obtained)
    self.obtained = obtained
end
---@public
---是否已拥有
function DPetSkinDetailCard:IsObtained()
    return self.obtained
end

---@public
---设置是否是当前时装
function DPetSkinDetailCard:SetIsCurrentSkin(isCurrent)
    self.is_onbody = isCurrent
end
---@public
---是否是当前时装
function DPetSkinDetailCard:IsCurrentSkin()
    return self.is_onbody
end
---@public
---设置是否解锁CG
function DPetSkinDetailCard:SetUnlockCg(unlockCg)
    self.unlock_CG = unlockCg
end
---@public
---是否解锁CG
function DPetSkinDetailCard:IsUnlockCg()
    return (self.unlock_CG == 1)
end
