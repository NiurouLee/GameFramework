--高级时装类别
---@class HauteCoutureType
local HauteCoutureType = {
    HC_None = 0,
    HC_GL = 1, -- 贡露
    HC_KR = 2, -- 卡戎
    HC_BLH = 3, --伯利恒
    HC_PLM = 4, --普律玛
    --
    HC_KL_Re = 1001, --卡莲复刻
    HC_GL_Re = 1002, --贡露复刻
    HC_KR_Re = 1003, --卡戎复刻
    HC_BLH_Re = 1004, --伯利恒复刻
    END = 9999
}
_enum("HauteCoutureType", HauteCoutureType)

---@class HauteCouture:Singleton
---@field GetInstance HauteCouture
---@field HcType HauteCoutureType
_class("HauteCouture", Singleton)
HauteCouture = HauteCouture

function HauteCouture:Constructor()
    self.HcType = HauteCoutureType.HC_None

    --代币Id
    self.CostCoinId = 0
end
