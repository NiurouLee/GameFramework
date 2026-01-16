
require "custom_nodes_lookup"
--测试配置
ConfigData_CustomLogicTest = {
    [101]={
        ID=101,
        Tips="Test1",
        Type=CustomLogic,
        Nodes={
            { Type=PrintLogBhv, LogStr="LogicTest1" },
        },
    },

    [10001]={
        ID=10001,
        Tips="TestProceedInSequence",
        Type=CustomLogic,
        Nodes={
            { Type=PrintLogBhv, LogStr="LogicTest1" },
            { Type=FTBhvSequence, Nodes={
                    { Type=DelayBhv, TimeLen=1.5 },
                    { Type=PrintLogBhv, LogStr="Action_1" },
                    { Type=DelayBhv, TimeLen=2.5 },
                    { Type=PrintLogBhv, LogStr="Action_2" },
                }
            },
        },
    },

    [10002]={
        ID=10002,
        Tips="Test2",
        Type=CustomLogic,
        Nodes={
            { Type=PrintLogBhv, LogStr="LogicTest2" },
            { Type=FTBhvSequence, Nodes={
                    { Type=DelayBhv, TimeLen=1.5 },
                    { Type=PrintLogBhv, LogStr="Action_1" },
                    { Type=DelayBhv, TimeLen=2.5 },
                    { Type=PrintLogBhv, LogStr="Action_2" },
                }
            },
        },
    },
}