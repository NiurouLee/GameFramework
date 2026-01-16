--[[
    邮件 ui helper
]]
---@class UiMailHelper: Object
_class("UiMailHelper", Object)
UiMailHelper = UiMailHelper
--region ShowUIGetRewards
-- 通用奖励弹窗
-- 根据奖励类型分来，先显示 pet ，再显示 pet skin ，最后显示 item
function UiMailHelper.ShowUIGetRewards(rewards, callback, doNotSort)
    -- 分类
    local itemList = {}
    local petList = {}
    local petSkinList = {}

    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    for _, v in pairs(rewards) do
        if petModule:IsPetID(v.assetid) then
            table.insert(petList, v)
        elseif petModule:IsPetSkinID(v.assetid) then
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = petModule:GetSkinIDFromItemID(v.assetid)
            roleAsset.count = v.count
            table.insert(petSkinList, roleAsset)
        else
            -- table.insert(itemList, v)
        end
        table.insert(itemList, v)
    end

    UiMailHelper.ShowUIGetRewards_Pet(petList, petSkinList, itemList, callback,doNotSort)
end

function UiMailHelper.ShowUIGetRewards_Pet(petList, petSkinList, itemList, callback,doNotSort)
    if table.count(petList) <= 0 then
        UiMailHelper.ShowUIGetRewards_PetSkin(petSkinList, itemList, callback,doNotSort)
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIPetObtain",
        petList,
        function()
            GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
            UiMailHelper.ShowUIGetRewards_PetSkin(petSkinList, itemList, callback,doNotSort)
        end
    )
    return
end

function UiMailHelper.ShowUIGetRewards_PetSkin(petSkinList, itemList, callback,doNotSort)
    if table.count(petSkinList) <= 0 then
        UiMailHelper.ShowUIGetRewards_Item(itemList, callback,doNotSort)
        return
    end

    local index = 0
    local showNextFunc = function()
        index = index + 1
        if index <= #petSkinList then
            return petSkinList[index]
        end
        return nil
    end
    local callBackFunc
    callBackFunc = function()
        GameGlobal.UIStateManager():CloseDialog("UIPetSkinObtainController")
        local nextAsset = showNextFunc()
        if nextAsset then
            UiMailHelper.ShowUIGetRewards_PetSkin_Single(nextAsset, callBackFunc)
        else
            UiMailHelper.ShowUIGetRewards_Item(itemList,callback, doNotSort)
        end
    end

    UiMailHelper.ShowUIGetRewards_PetSkin_Single(showNextFunc(), callBackFunc)
end

function UiMailHelper.ShowUIGetRewards_PetSkin_Single(roleAsset, callBackFunc)
    if not roleAsset then
        if callBackFunc then
            callBackFunc()
        end
        return
    end
    GameGlobal.UIStateManager():ShowDialog("UIPetSkinObtainController", roleAsset, callBackFunc)
end

function UiMailHelper.ShowUIGetRewards_Item(itemList, callback,doNotSort)
    if table.count(itemList) <= 0 then
        if callback then
            callback()
        end
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIGetItemController",
        itemList,
        function()
            if callback then
                callback()
            end
        end,
        doNotSort
    )
end
--endregion