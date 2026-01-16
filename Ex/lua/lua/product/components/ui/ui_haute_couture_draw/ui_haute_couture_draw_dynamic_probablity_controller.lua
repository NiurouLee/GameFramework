---@class UIHauteCoutureDrawDynamicProbablityController:UIController
_class("UIHauteCoutureDrawDynamicProbablityController", UIController)
UIHauteCoutureDrawDynamicProbablityController = UIHauteCoutureDrawDynamicProbablityController

function UIHauteCoutureDrawDynamicProbablityController:Constructor()
end

function UIHauteCoutureDrawDynamicProbablityController:OnShow(uiParams)
    self._prizes = uiParams[1]
    ---@type SeniorSkinComponentInfo
    self._cmpInfo = uiParams[2]
    self._cmpID = uiParams[3]
    self._replaceIdxs = uiParams[4] or {} --重复抽取需要替换的奖励
    self._drawTimes = self._cmpInfo.shake_num --已抽取次数
    self._gotPrizeIds = self._cmpInfo.shake_win_ids --已经得到的id
    self._title = self:GetUIComponent("UILocalizationText", "title")
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self._text2 = self:GetUIComponent("RectTransform", "text2")
    self:OnValue()
end

function UIHauteCoutureDrawDynamicProbablityController:OnValue()
    ---@type table<number,UIHauteCoutureDrawProbabilityItem>
    local items = self._content:SpawnObjects("UIHauteCoutureDrawProbabilityItem", #self._prizes)
    local allRate = 0
    local allRateTab = {}
    --[[
        处理动态概率的浮点数误差问题，按优先级：
        1.概率保留两位小数，舍弃小数两位之后
        2.所有概率相加必须等于100%
        3.所有概率保留两位小数后，相加不等于100%时，差值加到概率最高的最后一条上
    ]]
    for idx, v in ipairs(self._prizes) do
        if not table.icontains(self._gotPrizeIds, v.ID) and self:FilterDrawTimes(v) then
            local rate = 0
            rate = self:CalculateProbablity(v.ID)
            rate = math.floor(rate * 100) / 100 --截断小数点两位之后
            allRate = allRate + rate
            allRateTab[v.ID] = rate
        end
    end

    local deltaRate = 0 --因为浮点数误差问题，总概率可能不为100，
    deltaRate = allRate - 100 --插值一定是0.01的整数倍
    if deltaRate ~= 0 then
        local max = 0
        local theOne = -1
        for i = 1, #self._prizes do
            local id = self._prizes[i].ID
            if allRateTab[id] then
                local rate = allRateTab[id]
                if rate >= max then
                    theOne = id
                    max = rate
                end
            end
        end
        allRateTab[theOne] = allRateTab[theOne] - deltaRate
    end
    for k, v in ipairs(self._prizes) do
        items[k]:SetData(
            v,
            self._drawTimes,
            table.icontains(self._gotPrizeIds, v.ID),
            allRateTab[v.ID],
            table.icontains(self._replaceIdxs, k)
        )
    end

    self._text2:SetAsLastSibling()
end

function UIHauteCoutureDrawDynamicProbablityController:maskOnClick()
    self:CloseDialog()
end

function UIHauteCoutureDrawDynamicProbablityController:CalculateProbablity(id)
    local totalWeight = 0
    local cfgs = Cfg.cfg_component_senior_skin_weight {ComponentID = self._cmpID}
    for _, cfg in pairs(cfgs) do
        if not table.icontains(self._gotPrizeIds, cfg.ID) and self:FilterDrawTimes(cfg) then
            totalWeight = totalWeight + cfg.Weight
        end
    end
    return (Cfg.cfg_component_senior_skin_weight[id].Weight / totalWeight) * 100
end
function UIHauteCoutureDrawDynamicProbablityController:FilterDrawTimes(v)
    if v.RareLevel and self._drawTimes < v.RareLevel - 1 then
        return false
    end
    return true
end
function UIHauteCoutureDrawDynamicProbablityController:closeOnClick()
    self:CloseDialog()
end
