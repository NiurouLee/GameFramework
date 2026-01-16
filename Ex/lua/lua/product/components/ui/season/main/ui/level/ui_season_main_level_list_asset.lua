--
---@class UISeasonMainLevelListAsset : UICustomWidget
_class("UISeasonMainLevelListAsset", UICustomWidget)
UISeasonMainLevelListAsset = UISeasonMainLevelListAsset
--初始化
function UISeasonMainLevelListAsset:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonMainLevelListAsset:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.icon = self:GetUIComponent("Image", "icon")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "count")
    --generated end--
end

--设置数据
function UISeasonMainLevelListAsset:SetData(id, count)
    local zeros
    if count > 99999 then
        -- string.format("%.1f", count / 1000)
        Log.exception("奖励数量不可超过5位:", count)
    elseif count < 10000 and count > 999 then
        zeros = "0"
    elseif count < 1000 and count > 99 then
        zeros = "00"
    elseif count < 100 and count > 9 then
        zeros = "000"
    elseif count < 10 and count > 0 then
        zeros = "0000"
    end
    if string.isnullorempty(zeros) then
        self.count:SetText(count)
    else
        self.count:SetText("<color=#51504e>" .. zeros .. "</color>" .. count)
    end

    local cfg = Cfg.cfg_top_tips[id]
    local atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self.icon.sprite = atlas:GetSprite(cfg.Icon)
end
