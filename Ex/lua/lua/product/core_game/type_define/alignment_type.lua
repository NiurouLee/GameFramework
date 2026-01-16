--阵营类型
AlignmentType = {
    LocalPlayer = 1, --玩家，我方队伍、星灵、守护机关、我方机关，和阵营2互为敌方
    Monster = 2, --怪物，pvp队伍、pvp星灵、怪、敌方机关，和阵营1互为敌方
    Goodness = 3, --善良，不可以被攻击，不可以攻击别人的单位，和所有阵营的单位互为友方
    Wickedness = 4, -- 邪恶，和所有阵营(不含3)的单位互为敌方
    Punishment = 5, --天罚，不可以被攻击，可以攻击别人的单位，作为攻击者和所有阵营(不含3)互为敌方，作为被击者和所有阵营互为友方
}

--阵营目标类型
AlignmentTargetType = {
    Friend = 1, --朋友
    Enemy = 2, --敌人
}


--根据施法者和目标的阵营类型判断阵营目标类型
function MatchAlignmentType(casterAlignmentType, targetAlignmentType)
    if casterAlignmentType == targetAlignmentType then
        return AlignmentTargetType.Friend
    end
    
    if casterAlignmentType == AlignmentType.Goodness or targetAlignmentType == AlignmentType.Goodness then
        return AlignmentTargetType.Friend
    end

    if casterAlignmentType == AlignmentType.Punishment then
        return AlignmentTargetType.Enemy
    end

    if targetAlignmentType == AlignmentType.Punishment then
        return AlignmentTargetType.Friend
    end

    if casterAlignmentType == AlignmentType.Wickedness or targetAlignmentType == AlignmentType.Wickedness then
        return AlignmentTargetType.Enemy
    end

    if casterAlignmentType == AlignmentType.LocalPlayer and targetAlignmentType == AlignmentType.Monster then
        return AlignmentTargetType.Enemy
    end
    
    if casterAlignmentType == AlignmentType.Monster and targetAlignmentType == AlignmentType.LocalPlayer then
        return AlignmentTargetType.Enemy
    end

    return AlignmentTargetType.Enemy
end

