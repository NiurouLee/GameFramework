--[[------------------------------------------------------------------------------------------
    逻辑表现共享组件
]] --------------------------------------------------------------------------------------------

SharedComponentsRegister =
    ComponentsLookup:New(
    {
        "SharedStartIndex",
        ---不会更改的数据
        "EntityType",
        "Element",
        "MonsterID",
        "PetPstID",
        "Pet",
        "TrapID",
        "Boss",
        "BodyArea",
        "BlockFlag",
        "MatchPet",
        "AttackArea",
        "SuperEntity",
        "Alignment",
        "GameTurn",

        "Summoner",
        "DeadMark",
        "PetDeadMark",
        "TeamDeadMark",
        ---动态改变的数据
        "ActiveSkillPickUp",
        
        "Team",
        "GridLocation",
        "SkillInfo",
        "AIRecorder",
        "DropAsset",
        "AppearTriggerTrap",
        "Ride",
        "ChessPet",
        --多面棋盘
        "OutsideRegion",
        "TrapExtendSkillScope",
        --离场 记录MonsterID
        "OffBoardMonster",
        "Mirage",
        --Count
        "TotalSharedCount",
    }
)

SharedUniqueComponentsRegister =
    ComponentsLookup:New(
    {
        "SharedUniqueStartIndex",
        "Player",
        --Count
        "TotalSharedUniqueComponents"
    }
)
