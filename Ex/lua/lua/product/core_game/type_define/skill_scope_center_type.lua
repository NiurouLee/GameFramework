--技能范围的中心点类型
SkillScopeCenterType = {
    SkillScopeCenterTypeStart = 1,
    CasterPos = 1, --自己为中心
    Component = 2, --以挂了ScopeCenterComponent组件的实体为中心
    PickUpGridPos = 3, --以点选的格子为中心（有效可到达的格子） 等于最后一个有效点选位置
    PickUpMultiGridPos = 4, --分别以点选的多个格子为中心 要求点选的是有效的格子
    SelectNeareat2Pet = 5, --从 ScopeParam.ScopeCenterParam 中取一个离玩家最近的
    ChainSkillPickUpGridPos = 6, ---任意门专用
    PickUpSelectMonsterGridPos =7, ---库斯库塔主动技,点选怪物使用
    FirstPickUpGridPos = 8, ---第一个有效点选位置
    CastBombPos = 9, --直线扔手雷被阻挡的落点
    RoundBeginPlayerPos = 10, ---回合开始时玩家位置
    PlayerPos = 11, ---玩家位置
    NearestPetChessPos = 12, ---距离怪物最近的我方棋子位置
    NearestPosToCasterInPickMonster = 13, ---光灵哈提，点选位置上的怪的bodyarea中离施法者最近的点
    PickUpMonsterPos = 14,  --阿纳托利 返回点选的怪物中心点列表
    PickUpMonsterPosAndCasterPos = 15,--阿纳托利 返回点选的怪物中心点列表，如果只有一个，则光灵位置作为第一个点
    SkillScopeCenterTypeEnd = 999
}
