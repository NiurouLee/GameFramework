---@class ActivePickSkillCheckErrorType
ActivePickSkillCheckErrorType = {
    None = 0,--
    NoActivePickCmpt = 1,--发送消息时 activeSkillPickUpComponent nil
    PickPosListEmpty = 2, --发送消息时 activeSkillPickUpComponent 点选格子列表为空
    AutoPickFail = 3, --自动战斗 点选过程中出错
    AutoPickFailEmpty = 4,--自动战斗点选结束后 activeSkillPickUpComponent 点选格子列表为空
    AutoPickCalcListEmpty = 5,--自动战斗 计算出的点选列表为空
    AutoPickInsInvalid = 6,--自动战斗 点选后是在非有效区域
    AutoPickInsRepeat = 7,--自动战斗 重复点选
    AutoPickStateError = 8,--自动战斗 点选后状态不对
    PetNotReady = 9,--发送消息时 光灵 不是ready状态
}
ActivePickSkillCheckErrorType = ActivePickSkillCheckErrorType
_enum("ActivePickSkillCheckErrorType", ActivePickSkillCheckErrorType)

---@class ActivePickSkillCheckErrorStep
ActivePickSkillCheckErrorStep = {
    SendBeforeDoIns = 1,--发送消息前 DoActiveSkillInstruction 之前
    SendBeforeAfterDoIns = 2, --发送消息前 DoActiveSkillInstruction 之后
    TrySend = 3, --EventListenerServiceRender:SendCastPickUpActiveSkillCommand 中
    AutoPickOnStateError = 4,--自动战斗 点选后状态不对
    AutoPickOnPickError = 5,--自动战斗 点选后 数量不对
    PickInsRepeat = 6,--自动战斗 PickInstruction 点选重复
    PickInsInvalid = 7,--自动战斗 PickInstruction 点选无效
    PickLineAndDirectionInsRepeat = 8,--自动战斗 PickLineAndDirectionInstruction 点选重复 --艾露玛
    PickLineAndDirectionInsInvalid = 9,--自动战斗 PickLineAndDirectionInstruction 点选无效 --艾露玛
    PickAndDirectionInsRepeat = 10,--自动战斗 PickAndDirectionInstruction 点选重复 --普律玛
    PickAndDirectionInsInvalid = 11,--自动战斗 PickAndDirectionInstruction 点选无效 --普律玛
    PickAndDirectionInsDirInvalid = 12,--自动战斗 PickAndDirectionInstruction 点选无效 --普律玛
    PickPosAndRotateInsInvalid = 13,--自动战斗 PickUpPosAndRotateInstruction 点选无效 --狗兄弟
    PickDirectionInsInvalid = 14,--自动战斗 PickDirectionInstruction 点选无效
    PickDiffPowerInsRepeat = 15,--自动战斗 PickDiffPowerInstruction 点选重复 --罗伊
    PickDiffPowerInsInvalid = 16,--自动战斗 PickDiffPowerInstruction 点选无效 --罗伊
    PickAndTelInsRepeat = 17,--自动战斗 PickAndTeleportInstruction 点选重复 --库斯库塔
    PickAndTelInsInvalid = 18,--自动战斗 PickAndTeleportInstruction 点选无效 --库斯库塔
    PickAndTelInsMonsterError = 19,--自动战斗 PickAndTeleportInstruction 点选无效 --库斯库塔
    PickAndTelInsCanNotTel = 20,--自动战斗 PickAndTeleportInstruction 点选无效 --库斯库塔
    PickYeliyaRepeat = 21,--自动战斗 PickYeliya 点选重复
    PickYeliyaInvalid = 22,--自动战斗 PickYeliya 点选无效
}
ActivePickSkillCheckErrorStep = ActivePickSkillCheckErrorStep
_enum("ActivePickSkillCheckErrorStep", ActivePickSkillCheckErrorStep)