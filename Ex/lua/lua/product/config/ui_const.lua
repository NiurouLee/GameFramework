---@class UIConst
local UIConst = {
    TurnTipsOutTick = 200, ---回合切换时，回合提示滑出时间
    TurnTipsInTick = 200, ----回合切换时，回合提示滑入时间
    TurnTipsStayTick = 500, ----回合切换时，回合提示显示时间
    UIDiscoveryUnlockShowTime = 2000, --UIDiscoveryUnlock解锁界面显示时长
    ConnectorString = "-",
    BranchMissionIndexPrefix = "S", --分支关卡索引前缀，S3-2-1
    IsShieldPay = false, --是否屏蔽充值直购
    End = 99999
}
_enum("UIConst", UIConst)

UIEnum = {}
UIEnum.ItemColorFrame = function(color)
    if not UIEnum._itemColorFrame then
        UIEnum._itemColorFrame = {
            [ItemColor.ItemColor_White] = "spirit_shengji_se1",
            [ItemColor.ItemColor_Green] = "spirit_shengji_se2",
            [ItemColor.ItemColor_Blue] = "spirit_shengji_se3",
            [ItemColor.ItemColor_Purple] = "spirit_shengji_se4",
            [ItemColor.ItemColor_Yellow] = "spirit_shengji_se5",
            [ItemColor.ItemColor_Golden] = "spirit_shengji_se6"
        }
    end
    return UIEnum._itemColorFrame[color] or ""
end

---@class UIItemRandomType
local UIItemRandomType = {
    Guding = 1, --- 固定掉落
    DaGaiLv = 2, ----大概率
    YiBanGaiLv = 3, ----一般概率
    XiaoGaiLv = 4, ----小概率
    JiXiaoGaiLv = 5, ----极小概率
    TeBieDiaoLuo = 6 --特别掉落
}
_enum("UIItemRandomType", UIItemRandomType)

UIEnum.ItemRandomStr = function(randomType)
    if not randomType then
        return ""
    end
    if not UIEnum._itemRandomTypeStr then
        UIEnum._itemRandomTypeStr = {
            [UIItemRandomType.Guding] = StringTable.Get("str_item_guding"),
            [UIItemRandomType.DaGaiLv] = StringTable.Get("str_item_dagailv"),
            [UIItemRandomType.YiBanGaiLv] = StringTable.Get("str_item_yibangailv"),
            [UIItemRandomType.XiaoGaiLv] = StringTable.Get("str_item_xiaogailv"),
            [UIItemRandomType.JiXiaoGaiLv] = StringTable.Get("str_item_jixiaogailv"),
            [UIItemRandomType.TeBieDiaoLuo] = StringTable.Get("str_battle_special_drop")
        }
    end
    return UIEnum._itemRandomTypeStr[randomType] or ""
end

PetAwakeSpriteName = {
    [1] = {
        [0] = "spirit_juexing1_big0",
        [1] = "spirit_juexing1_big1"
    }, --最大觉醒数为1
    [2] = {
        [0] = "spirit_juexing2_big0",
        [1] = "spirit_juexing2_big1",
        [2] = "spirit_juexing2_big2"
    }, --最大觉醒数为2
    [3] = {
        [0] = "spirit_juexing3_big0",
        [1] = "spirit_juexing3_big1",
        [2] = "spirit_juexing3_big2",
        [3] = "spirit_juexing3_big3"
    } --最大觉醒数为3
}

PetAwakeSpriteGlowName = {
    [2] = {
        [1] = "spirit_juexing_icon6",
        [2] = "spirit_juexing_icon7"
    }, --最大觉醒数为2
    [3] = {
        [1] = "spirit_juexing_icon6",
        [2] = "spirit_juexing_icon7",
        [3] = "spirit_juexing_icon8"
    } --最大觉醒数为3
}
