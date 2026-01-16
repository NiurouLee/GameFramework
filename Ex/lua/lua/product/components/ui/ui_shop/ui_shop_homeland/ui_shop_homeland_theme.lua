---家园家具商店每期套组的主题颜色、文字描边、图片等配置。UIShopHomelandThemeKey 对应cfg_shop_furniture_goods_ext中的ShopId

---@class UIShopHomelandThemeKey
local UIShopHomelandThemeKey =
{
    Default = 1,
    N23 = 2,
    N25 = 5,
    N27 = 6,
    N29 = 7,
    N31 = 8,
}
_enum("UIShopHomelandThemeKey", UIShopHomelandThemeKey)

---@class UIShopHomelandTheme
local UIShopHomelandTheme =
{
    [UIShopHomelandThemeKey.Default] = 
    {
        ShowBtn = "base_shop_di07", --需要做左右的九宫格
        BigAwardTitleBg = "base_shop_di12", --需要做左右的九宫格
        GotBackground = "base_shop_di11",
        LockTextOutLine = Color(118 / 255, 186 / 255, 249 / 255),
        ItemPriceImg = "base_shop_btn01",
        ItemGotBackground = "base_shop_di11",
        ItemLockTextOutLine = Color(118 / 255, 186 / 255, 249 / 255),
    },
    [UIShopHomelandThemeKey.N23] = 
    {
        ShowBtn = "base_shop_di07",
        BigAwardTitleBg = "base_shop_di12",
        GotBackground = "base_shop_tiao_n23",
        LockTextOutLine = Color(128 / 255, 196 / 255, 48 / 255),
        ItemPriceImg = "base_shop_btn01",
        ItemGotBackground = "base_shop_tiao_n23",
        ItemLockTextOutLine = Color(128 / 255, 196 / 255, 48 / 255),
    },
    [UIShopHomelandThemeKey.N25] = 
    {
        ShowBtn = "base_shop_di26",
        BigAwardTitleBg = "base_shop_di27",
        GotBackground = "base_shop_tiao_n25",
        LockTextOutLine = Color(211 / 255, 38 / 255, 187 / 255),
        ItemPriceImg = "base_shop_btn02",
        ItemGotBackground = "base_shop_tiao_n25",
        ItemLockTextOutLine = Color(211 / 255, 38 / 255, 187 / 255),
    },
    [UIShopHomelandThemeKey.N27] = 
    {
        ShowBtn = "base_shop_di28",
        BigAwardTitleBg = "base_shop_di29",
        GotBackground = "base_shop_tiao_n27",
        LockTextOutLine = Color(245 / 255, 120 / 255, 179 / 255),
        ItemPriceImg = "base_shop_btn03",
        ItemGotBackground = "base_shop_tiao_n27",
        ItemLockTextOutLine = Color(245 / 255, 120 / 255, 179 / 255),
    },
    [UIShopHomelandThemeKey.N29] = 
    {
        ShowBtn = "base_shop_di30",
        BigAwardTitleBg = "base_shop_di31",
        GotBackground = "base_shop_tiao_n29",
        LockTextOutLine = Color(133 / 255, 56 / 255, 42 / 255),
        ItemPriceImg = "base_shop_btn04",
        ItemGotBackground = "base_shop_tiao_n29",
        ItemLockTextOutLine = Color(133 / 255, 56 / 255, 42 / 255),
    },
    [UIShopHomelandThemeKey.N31] = 
    {
        ShowBtn = "base_shop_di32",
        BigAwardTitleBg = "base_shop_di33",
        GotBackground = "base_shop_tiao_n31",
        LockTextOutLine = Color(60 / 255, 81 / 255, 114 / 255),
        ItemPriceImg = "base_shop_btn05",
        ItemGotBackground = "base_shop_tiao_n31",
        ItemLockTextOutLine = Color(60 / 255, 81 / 255, 114 / 255),
    }
}
_enum("UIShopHomelandTheme", UIShopHomelandTheme)

