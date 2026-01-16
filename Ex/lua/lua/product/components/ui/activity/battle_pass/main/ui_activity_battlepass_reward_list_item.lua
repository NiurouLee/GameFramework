---@class UIActivityBattlePassRewardListItem:UICustomWidget
_class("UIActivityBattlePassRewardListItem", UICustomWidget)
UIActivityBattlePassRewardListItem = UIActivityBattlePassRewardListItem

function UIActivityBattlePassRewardListItem:SetData_Fixed(component)
    --- @type LVRewardComponent
    self._component = component
    --- @type LVRewardComponentInfo
    self._info = component:ComponentInfo()

    self:_SetLevel({lv = "", sp = false})
    self:_SetCell({adv = false, fix = true, sp = false})
    self:_SetCell({adv = true, fix = true, sp = false})
end

function UIActivityBattlePassRewardListItem:SetData(index, component, clickCallback, tipCallback, matRes)
    self._index = index
    --- @type LVRewardComponent
    self._component = component
    --- @type LVRewardComponentInfo
    self._info = component:ComponentInfo()
    self._clickCallback = clickCallback
    self._tipCallback = tipCallback
    self._EMIMat = matRes

    local isPreview = self._component:IsPreviewLvFromConfig(self._index)
    self:_SetLevel({lv = self._index, sp = isPreview})
    self:_SetCell({adv = false, fix = false, sp = isPreview})
    self:_SetCell({adv = true, fix = false, sp = isPreview})
end

function UIActivityBattlePassRewardListItem:OnShow(uiParams)
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIBattlePass.spriteatlas", LoadType.SpriteAtlas)
end

function UIActivityBattlePassRewardListItem:OnHide()
end

function UIActivityBattlePassRewardListItem:_GetLevelBgId(lv, sp)
    if lv == false and sp == false then
        return "pass_jiangli_di11"
    elseif lv == true and sp == false then
        return "pass_jiangli_di10"
    elseif lv == false and sp == true then
        return "pass_jiangli_di11-1"
    elseif lv == true and sp == true then
        return "pass_jiangli_di10-1"
    end
end

function UIActivityBattlePassRewardListItem:_SetLevel(args)
    local text = self:GetUIComponent("UILocalizationText", "levelText")
    text:SetText(tostring(args.lv))

    if self._info then
        local id = self:_GetLevelBgId(self._info.m_current_level == args.lv, args.sp)

        ---@type UnityEngine.UI.Image
        local lvbg = self:GetUIComponent("Image", "lvbg")
        lvbg.sprite = self._atlas:GetSprite(id)
    end
end

function UIActivityBattlePassRewardListItem:_SetCell(args)
    local id = args.adv and "deluxePool" or "standardPool"
    local sop = self:GetUIComponent("UISelectObjectPath", id)
    local obj = sop:SpawnObject("UIActivityBattlePassRewardCell")

    if not args.fix then
        obj:SetData(
            self._index,
            args.adv,
            args.sp,
            self._component,
            self._clickCallback,
            self._tipCallback,
            self._EMIMat
        )
    else
        obj:SetData_Fixed(args.adv, self._component)
    end
end
