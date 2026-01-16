---@class UIN19LineMissionConst:UIController
_class("UIN19LineMissionConst", UIController)
UIN19LineMissionConst = UIN19LineMissionConst

-- s关枚举id
function UIN19LineMissionConst.SLevel()
    return 999
end

--通关后文本和阴影颜色
function UIN19LineMissionConst.Passed()
    return 888
end

function UIN19LineMissionConst.NodeCfg()
    return {
        [DiscoveryStageType.FightNormal] = {
            [1] = {
                normal = "n19_xxg_btn1",
                press = "",
                lock = "",
                textColor = Color(10 / 255, 11 / 255, 12 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255),
                normalStar = "",
                passStar = "n19_xxg_star"
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        },
        [DiscoveryStageType.FightBoss] = {
            [1] = {
                normal = "n19_xxg_btn3",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(255 / 255, 255 / 255, 255 / 255),
                normalStar = "",
                passStar = "n19_xxg_star"
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(238 / 255, 0 / 255, 34 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        },
        [DiscoveryStageType.Plot] = {
            [1] = {
                normal = "n19_xxg_btn2",
                press = "",
                lock = "",
                textColor = Color(10 / 255, 11 / 255, 12 / 255),
                textShadow = Color(0 / 255, 0 / 255, 0 / 255)
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(249 / 255, 255 / 255, 97 / 255),
                textShadow = Color(191 / 255, 52 / 255, 25 / 255)
            } --高难样式
        },
        [UIN19LineMissionConst.SLevel()] = {
            [1] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "",
                passStar = ""
            }, --普通样式
            [2] = {
                normal = "",
                press = "",
                lock = "",
                textColor = Color(255 / 255, 255 / 255, 255 / 255),
                textShadow = Color(22 / 255, 42 / 255, 61 / 255),
                normalStar = "",
                passStar = ""
            } --高难样式
        }
    }
end
