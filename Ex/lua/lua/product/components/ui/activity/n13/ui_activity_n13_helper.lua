--[[
    活动辅助类
]]

EnumN13Review = {
    A = 1,--老活动
    B = 2,--活动回顾
}
_enum("EnumN13Review", EnumN13Review)
---@class UIActivityN13Helper
_class("UIActivityN13Helper", Object)
UIActivityN13Helper = UIActivityN13Helper

function UIActivityN13Helper:Constructor()
end

--region Coin
function UIActivityN13Helper.GetCoinItemId(type)
    local itemId = 3000238 -- 老活动代币
    if type == EnumN13Review.B then
        itemId = 3000323--活动回顾新增代币
    end

    return itemId
end

function UIActivityN13Helper.GetCoinItemIconName(type)
    local itemId = UIActivityN13Helper.GetCoinItemId(type)
    local cfg = Cfg.cfg_item[itemId]
    if not cfg then
        return nil
    end
    return cfg.Icon
end

function UIActivityN13Helper.GetCoinItemCount(type)
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    local itemCount = itemModule:GetItemCount(UIActivityN13Helper.GetCoinItemId(type))
    return itemCount
end

--endregion

--region PlayStory
function UIActivityN13Helper.PlayStory_Build(component, storyInfo, callback)
    local storyType = storyInfo[1]
    local storyId = storyInfo[2]
    local curStatus = storyInfo[3]
    local buildingId = storyInfo[4]

    -- 1:纯局外立绘对话 2:通用的剧情形式 3:终端对话
    if storyType == 1 or storyType == 3 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIStoryBanner",
            storyId,
            StoryBannerShowType.HalfPortrait,
            function()
                component:Start_HandleStory(buildingId, curStatus, callback)
            end
        )
    elseif storyType == 2 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIStoryController",
            storyId,
            function()
                component:Start_HandleStory(buildingId, curStatus, callback)
            end
        )
    end
end

function UIActivityN13Helper.PlayStory_Picnic(component, storyInfo, callback)
    local storyType = storyInfo[1]
    local storyId = storyInfo[2]
    local curStatus = storyInfo[3] -- no use
    local buildingId = storyInfo[4] -- no use

    -- 1:纯局外立绘对话 2:通用的剧情形式 3:终端对话
    if storyType == 1 or storyType == 3 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIStoryBanner",
            storyId,
            StoryBannerShowType.HalfPortrait,
            function()
                component:Start_HandlePicnicStory(callback)
            end
        )
    elseif storyType == 2 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIStoryController",
            storyId,
            function()
                component:Start_HandlePicnicStory(callback)
            end
        )
    end
end
--endregion

--region Status
function UIActivityN13Helper.GetStrByStatus_Operator(status, name)
    local tb = {
        [UIBuildComponentBuildStatus.Init] = "str_n13_build_tips_cleanup_operator_name",
        [UIBuildComponentBuildStatus.CleanUpComplete] = "str_n13_build_tips_decorate_operator_name",
        [UIBuildComponentBuildStatus.RepairComplete] = "",
        [UIBuildComponentBuildStatus.DecorateComplete] = "",
        [UIBuildComponentBuildStatus.Picnic] = ""
    }
    local strId = tb[status]
    if not string.isnullorempty(strId) then
        return StringTable.Get(strId, name)
    end
    return ""
end

function UIActivityN13Helper.GetStrByStatus_Title(status)
    local tb = {
        [UIBuildComponentBuildStatus.Init] = "str_n13_build_tips_cleanup_btn_name",
        [UIBuildComponentBuildStatus.CleanUpComplete] = "str_n13_build_tips_decorate_btn_name",
        [UIBuildComponentBuildStatus.RepairComplete] = "",
        [UIBuildComponentBuildStatus.DecorateComplete] = "",
        [UIBuildComponentBuildStatus.Picnic] = ""
    }
    local strId = tb[status]
    if not string.isnullorempty(strId) then
        return StringTable.Get(strId)
    end
    return ""
end

function UIActivityN13Helper.GetStrByStatus_Picnic(name)
    local strId = "str_n13_build_tips_picnic_operator_name"
    return StringTable.Get(strId, name)
end
--endregion
