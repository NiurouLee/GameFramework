--region dc define

-- 榜单唯一类型
--- @class RANK_TYPE
local RANK_TYPE = {
    RANK_TYPE_INVALID = 0,
    RANK_TYPE_LEVEL = 1, -- 玩家等级榜
    RANK_TYPE_CONSUME = 2, -- 玩家消费榜
    RANK_TYPE_ACTIVE = 3, -- 玩家活跃榜
    RANK_TYPE_WITH_TEST = 4, -- 测试类型
    RANK_TYPE_END = 5,
}
_enum("RANK_TYPE", RANK_TYPE)

-- 调用rank服接口返回码
--- @class RANK_SER_RET_NO
local RANK_SER_RET_NO = {
    TR_SUCCESS = 0,
    TR_RANK_TYPE_ERR = 1,
    TR_PROC_ERR = 2,
    TR_RANK_NOT_INIT = 3,
}
_enum("RANK_SER_RET_NO", RANK_SER_RET_NO)

-- 榜单数据包装,以序列化方式透传数据
--region RankWrapBuff define
---@class RankWrapBuff:Object
_class("RankWrapBuff",Object)
RankWrapBuff = RankWrapBuff

 function RankWrapBuff:Constructor()
    self.m_buff = ""
end
---@private
RankWrapBuff._proto = {
    [1] = {"m_buff", "buffer"},
}
--endregion

-- 以下会在db中存储,使用表命名规则
--region rank_role_info define
---@class rank_role_info:Object
_class("rank_role_info",Object)
rank_role_info = rank_role_info

 function rank_role_info:Constructor()
end
--region dc custom rank_role_info
--endregion dc custom rank_role_info
---@private
rank_role_info._proto = {
}
--endregion

-- 业务rank

-- 等级榜
--region rank_level define
---@class rank_level:rank_role_info
_class("rank_level",rank_role_info)
rank_level = rank_level

 function rank_level:Constructor()
    self.pstid = 0 --玩家pstid
    self.value = 0 --值
    self.enter_time = 0 --上榜时间
end
--region dc custom rank_level
--endregion dc custom rank_level
---@private
rank_level._proto = {
    [1] = {"pstid", "int64"},
    [2] = {"value", "int64"},
    [3] = {"enter_time", "time"},
}
--endregion

-- 榜单元素全部数据,包含榜单数据和附加数据
--region rank_level_whole define
---@class rank_level_whole:Object
_class("rank_level_whole",Object)
rank_level_whole = rank_level_whole

 function rank_level_whole:Constructor()
    self.rank_base = rank_level:New() -- 榜单基础数据
    self.icon_head = "" -- 头像
end
---@private
rank_level_whole._proto = {
    [1] = {"rank_base", "rank_level"},
    [2] = {"icon_head", "string"},
}
--endregion

-- 活跃榜
--region rank_active define
---@class rank_active:rank_role_info
_class("rank_active",rank_role_info)
rank_active = rank_active

 function rank_active:Constructor()
    self.pstid = 0
    self.value = 0
    self.enter_time = 0
end
--region dc custom rank_active
--endregion dc custom rank_active
---@private
rank_active._proto = {
    [1] = {"pstid", "int64"},
    [2] = {"value", "int64"},
    [3] = {"enter_time", "time"},
}
--endregion

--region rank_active_whole define
---@class rank_active_whole:Object
_class("rank_active_whole",Object)
rank_active_whole = rank_active_whole

 function rank_active_whole:Constructor()
    self.rank_base = rank_active:New() -- 榜单基础数据
    self.icon_head = "" -- 头像
end
---@private
rank_active_whole._proto = {
    [1] = {"rank_base", "rank_active"},
    [2] = {"icon_head", "string"},
}
--endregion

-- 消费榜单
--region rank_consume define
---@class rank_consume:rank_role_info
_class("rank_consume",rank_role_info)
rank_consume = rank_consume

 function rank_consume:Constructor()
    self.pstid = 0
    self.value = 0
    self.enter_time = 0
    self.consume_type = 0
end
--region dc custom rank_consume
--endregion dc custom rank_consume
---@private
rank_consume._proto = {
    [1] = {"pstid", "int64"},
    [2] = {"value", "int64"},
    [3] = {"enter_time", "time"},
    [4] = {"consume_type", "int"},
}
--endregion

--region rank_consume_whole define
---@class rank_consume_whole:Object
_class("rank_consume_whole",Object)
rank_consume_whole = rank_consume_whole

 function rank_consume_whole:Constructor()
    self.rank_base = rank_consume:New() -- 榜单基础数据
    self.icon_head = "" -- 头像
end
---@private
rank_consume_whole._proto = {
    [1] = {"rank_base", "rank_consume"},
    [2] = {"icon_head", "string"},
}
--endregion

-- 测试数据
--region rank_test_data define
---@class rank_test_data:rank_role_info
_class("rank_test_data",rank_role_info)
rank_test_data = rank_test_data

 function rank_test_data:Constructor()
    self.pstid = 0
    self.value = 0
    self.enter_time = 0
    -- 填充
    self.fill_data = "abcdefghigklmnabcdefghigklmnabcdefghigklmnabcdefghigklmnabcdefghigklmnabcdefghigklmnabcdefghigk"
end
--region dc custom rank_test_data
--endregion dc custom rank_test_data
---@private
rank_test_data._proto = {
    [1] = {"pstid", "int64"},
    [2] = {"value", "int64"},
    [3] = {"enter_time", "time"},
    [4] = {"fill_data", "string"},
}
--endregion

--region rank_test_whole define
---@class rank_test_whole:Object
_class("rank_test_whole",Object)
rank_test_whole = rank_test_whole

 function rank_test_whole:Constructor()
    self.rank_base = rank_test_data:New() -- 榜单基础数据
    self.icon_head = "" -- 头像
end
---@private
rank_test_whole._proto = {
    [1] = {"rank_base", "rank_test_data"},
}
--endregion

--endregion dc define
