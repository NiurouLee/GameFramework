--[[
    用来标记buff相关的逻辑功能开关，取值0-63
]]
BuffFlags = {
    SkipTurn = 0, --跳过行动回合
    ImmuneAttack = 1, --攻击免疫
    ImmuneControl = 2, --免控
    Silence = 3, --沉默
    Benumb = 4, --麻痹
    Invincible = 8, --无敌
    BreakInvincible = 16, --破除无敌
    SealedCurse = 32, -- 诅咒：无法上场
}
