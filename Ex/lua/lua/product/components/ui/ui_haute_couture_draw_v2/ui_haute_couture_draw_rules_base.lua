--高级时装规则基类
---@class UIHauteCoutureDrawRulesBase:UICustomWidget
---@field controller UIHauteCoutureDrawRulesV2Controller 控制器
_class("UIHauteCoutureDrawRulesBase", UICustomWidget)
UIHauteCoutureDrawRulesBase = UIHauteCoutureDrawRulesBase

function UIHauteCoutureDrawRulesBase:Constructor()
    self.controller = nil
    -- self._probablityTable = {}
end

function UIHauteCoutureDrawRulesBase:InitWidgetsBase()
    self.controller = self.uiOwner
    self.items = self:GetUIComponent("UISelectObjectPath", "items")
    self.pros = self:GetUIComponent("Transform", "Pros")
end

function UIHauteCoutureDrawRulesBase:_OnValue()
    self.items.dynamicInfoOfEngine:SetObjectName(self:GetRuleItemPrefab())
    self.items:SpawnObjects(self:GetRuleItemScript(), 10)
    ---@type table<number,UISeniorSKinProItems>
    local itemWidgets = self.items:GetAllSpawnList()

    local data = self.controller.CtxData
    local prizes = data:GetPrizeCfgs()
    local replacedIdx
    --这里是通用逻辑,需要考虑兼容活动复刻
    if data:IsReview() then
        --复刻的时候需要修改奖励内容文本
        replacedIdx =
            GameGlobal.GetModule(CampaignModule):GetSeniorSkinDuplicateRewardIndexs(
            prizes,
            data:GetSeniorSkinCmp():GetComponentInfo()
        )
        self:SetReviewRewardContenText()
    end

    for i = 1, 10 do
        local prizeCfg = prizes[i]
        local prize
        local normalPrize
        if table.icontains(replacedIdx, i) then
            normalPrize = {prizeCfg.ReplaceRewardID, prizeCfg.ReplaceRewardCount}
        else
            normalPrize = {prizeCfg.RewardID, prizeCfg.RewardCount}
        end
        if prizeCfg.AppendGlow and prizeCfg.AppendGlow > 0 then
            prize = {{RoleAssetID.RoleAssetGlow, prizeCfg.AppendGlow}, normalPrize}
        else
            prize = {normalPrize}
        end
        itemWidgets[i]:SetData(prize)
        self.pros:GetChild(i - 1):GetComponent(typeof(UILocalizationText)):SetText(prizeCfg.BaseProb)
    end
    -- for i = 1, 10 do
    --     itemWidgets[i]:SetData(Cfg.cfg_senior_skin_probablity[i].Items)
    -- end

    -- for i = 1, 10 do
    --     self.pros:GetChild(i - 1):GetComponent(typeof(UILocalizationText)):SetText(
    --         Cfg.cfg_senior_skin_probablity[i]["Time" .. i]
    --     )
    -- end
end

--子类调用
function UIHauteCoutureDrawRulesBase:GetRuleItemPrefab()
    Log.error("UIHauteCoutureDrawRulesBase:GetRuleItemPrefab should be inherited")
    return nil
end

--子类调用
function UIHauteCoutureDrawRulesBase:GetRuleItemScript()
    Log.error("UIHauteCoutureDrawRulesBase:GetRuleItemScript should be inherited")
    return nil
end

function UIHauteCoutureDrawRulesBase:SetReviewRewardContenText()
    Log.error("UIHauteCoutureDrawRulesBase:SetReviewRewardContenText should be inherited")
    -- self:GetUIComponent("UILocalizationText", "RewardContent"):SetText(StringTable.Get(""))
end

function UIHauteCoutureDrawRulesBase:MaskOnClick()
    self.controller:CloseDialog()
end
