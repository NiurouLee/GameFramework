---@class SkillPickUpType
---每种拾取类型，都有自己特殊的表现效果
---以下的命名有些不够明确，比如1只能是棱镜效果专用
---这块的配置后边需要重构一次，从本质上说，pickup就是scope的一种类型
---因此需要pickup编到scope里，拾取类型，拾取数量作为scope param
SkillPickUpType = {
    None = 0, --指令化处理的拾取类型system
    ColorInstruction = 1, --点选颜色型指令处理类型
    PickAndTeleportInst = 2, --点选怪物并移动怪物
    PickAndDirectionInstruction = 3, --点选第一个点为基础，点选第二个方向
    PickOnePosAndRotate = 4, --连续点击同一个点多次以旋转方向
    LineAndDirectionInstruction = 5, --点选第一个点为主方向，点选第二个方向
    PickSwitchInstruction = 6, --重复点击一个点以切换技能效果，未点击是也可以释放技能（露比主动技）
    PickDiffPowerInstruction = 7, --根据点选格子不同（有没有指定机关），技能消耗能量不同(罗伊主动技)
    Instruction = 9, --点击型指令化处理的拾取类型system
    DirectionInstruction = 10, ---方向型指令化处理表现的拾取类型system
    ChainInstruction = 11, ---连锁技轮播
    PickAndDirectionInstruction2 = 12, --点选第一个点为基础，点选第二个方向,与3大体相同，只是点选方向时可以点选任意位置不需要点选有效格子
    Akexiya = 13, --阿克希亚专属，功能难以形容，请直接看需求
    Yeliya = 14, --耶利亚 点到指定机关时可以继续点 每次重算范围
    PickDirOrSelf = 15, --零恩 点选十字四方向或自己
    LinkLine = 16, --蒂娜 连线形式的拾取格子
    Hati = 17, --哈提 在9的基础上，点选有效格子时如果点位位置的怪周围一圈没有可站立位置，则抛弃本次点选，弹提示
    PickUpGridTogether = 18, --希南主动技,点相同格子是列行切换，换格子默认就是列
}
_enum("SkillPickUpType", SkillPickUpType)

---@class SkillPickUpTextStateType
local SkillPickUpTextStateType = {
    Normal = 1, ---正常版本显示
    Tel = 2, ---显示还能移动位置
    Direction = 3, --显示还能选择方向
    Rotate = 4, --显示再次点击还能旋转
    Target = 5, --显示还能点击目标
    Switch = 6, --显示再次点选脚下切换效果
    ChooseDir = 7, --显示点击选择方向
    ColOrRow = 8, --显示再次点击切换行活列
}
_enum("SkillPickUpTextStateType", SkillPickUpTextStateType)

---@class ShowArrowType
local ShowArrowType = {
    UpAndDown = 1, ---显示上下箭头
    LeftAndRight = 2, ---显示左右箭头
    Four = 3, ---显示四方向箭头
}
_enum("ShowArrowType", ShowArrowType)
