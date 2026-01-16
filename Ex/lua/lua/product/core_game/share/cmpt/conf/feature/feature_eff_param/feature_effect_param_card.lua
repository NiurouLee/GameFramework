---选牌模块参数
---@class FeatureEffectParamCard: FeatureEffectParamBase
_class("FeatureEffectParamCard", FeatureEffectParamBase)
FeatureEffectParamCard = FeatureEffectParamCard
---构造
function FeatureEffectParamCard:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamCard:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.SkillDic then
        self._skillDic = t.SkillDic--技能id
    end
    if t.CardMax then
        self._cardMax = t.CardMax--卡牌上限
    end
    if t.InitCardNum then
        self._initCardNum = t.InitCardNum--初始附带几张
    end
    if t.InitCardList then
        self._initCardList = t.InitCardList--初始指定的卡牌列表 用于引导关
    end
    if t.DrawCardFixedList then
        self._drawCardFixedList = t.DrawCardFixedList--固定顺序的抽卡牌列表 用于引导关
    end
    if t.DefaultWeightNum then
        self._defaultWeightNum = t.DefaultWeightNum--抽牌 初始权重
    end
    if t.WeightIncreaseNum then
        self._weightIncreaseNum = t.WeightIncreaseNum--抽牌 每次未抽中 权重增加值
    end
    if t.UiType then
        self._uiType = t.UiType--皮肤改ui
    end
end
---模块类型
function FeatureEffectParamCard:GetFeatureType()
    return FeatureType.Card
end
---复制用
---@param param FeatureEffectParamCard
function FeatureEffectParamCard:CopyFrom(param)
    if param then
        for k,v in pairs(param) do
            self[k] = v
        end
    end
end
---复制
---@return FeatureEffectParamCard
function FeatureEffectParamCard:CloneSelf()
    local param = FeatureEffectParamCard:New()
    param:CopyFrom(self)
    return param
end
---替换部分参数
function FeatureEffectParamCard:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end
---技能id
function FeatureEffectParamCard:GetCardSkillDic()
    return self._skillDic
end
---卡牌上限
function FeatureEffectParamCard:GetCardMax()
    return self._cardMax
end
---初始卡牌数
function FeatureEffectParamCard:GetInitCardNum()
    return self._initCardNum
end
--指定初始牌
function FeatureEffectParamCard:GetInitCardList()
    return self._initCardList
end
--指定抽牌列表
function FeatureEffectParamCard:GetDrawCardFixedList()
    return self._drawCardFixedList
end
--根据次数取固定卡牌
function FeatureEffectParamCard:GetFixedDrawCard(times)
    local card = nil
    if self._drawCardFixedList then
        card = self._drawCardFixedList[times]
    end
    return card
end
--抽牌 默认权重
function FeatureEffectParamCard:GetDefaultWeightNum()
    return self._defaultWeightNum or 5
end
--抽牌 权重增加值
function FeatureEffectParamCard:GetWeightIncreaseNum()
    return self._weightIncreaseNum or 1
end
function FeatureEffectParamCard:GetUiType()
    return self._uiType or FeatureCardUiType.Default
end