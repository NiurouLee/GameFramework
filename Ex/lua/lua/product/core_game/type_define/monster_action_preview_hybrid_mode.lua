---@class MonsterActionHybridPreviewMode
---@field Carousel number 在AI技能配置中选择特定技能组轮播
---@field RoundBasedCarousel number
MonsterActionHybridPreviewMode = {
    Carousel = 1, ---在AI技能配置中选择特定技能组轮播
    RoundBasedCarousel = 2, ---从HybridSkillPreviewParam选择与回合数对应的组进行轮播
    AlphaFixedByRound = 3, ---按照与回合数对应的技能组，根据当前骑乘状态和技能范围，找到特定的技能ID，进行预览
    TotalRoundBasedCarousel = 4, ---从HybridSkillPreviewParam选择与回合数对应的组进行轮播,使用全局的回合数不使用AI内部的
}

_enum("MonsterActionHybridPreviewMode", MonsterActionHybridPreviewMode)
