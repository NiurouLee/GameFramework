--region dc define
require "message_def"

local rankMessageDef ={
    --region rank
    CLSID_CEventRankDatum = 30000,
    CLSID_CEventRankDatumLevel = 30001,
    CLSID_CEventRankDatumActive = 30002,
    CLSID_CEventRankDatumConsume = 30003,
    CLSID_CEventRankDatumTest = 30004,
    CLSID_CEventRankRequestEvent = 30005,
    CLSID_CEventRankReplyEvent = 30006,
    CLSID_CEventRankRoleRequestPage = 30007,
    CLSID_CEventRankRoleReplyPage = 30008,
    CLSID_CEventRankRoleRequestTotal = 30009,
    CLSID_CEventRankRoleReplyTotal = 30010,
    CLSID_CEventRankRoleRequestUpdate = 30011,
    CLSID_CEventRankRoleReplyUpdate = 30012,
    CLSID_CEventRankRoleRequestDelete = 30013,
    CLSID_CEventRankRoleReplyDelete = 30014,
    --endregion
}
table.append(MessageDef, rankMessageDef)

-- rank接口处理返回码
--- @class RankRoleProcRet
local RankRoleProcRet = {
    RP_SUCCESS = 0,
    RP_NOT_IN_USE = 1, -- 榜单不可用
    RP_ARGS_ERR = 2, -- 参数错误
    RP_CANT_IN_RANK = 3, -- 玩家积分不可上榜
    RP_NOT_ENOUGH = 4, -- 无法满足拉取的数量
    RP_NOT_IN_RANK = 5, -- 玩家不在榜单
    RP_PROC_FAIL = 6, -- 榜单操作执行失败
    RP_UP_SAME = 7, -- 榜单更新的值无变化
    RP_TYPE_ERR = 8, -- 榜单类型错误
}
_enum("RankRoleProcRet", RankRoleProcRet)

-- 客户端通信

-- 榜单c/s通信数据包基类
--region CEventRankRequestEvent define
---@class CEventRankRequestEvent:CCallRequestEvent
_class("CEventRankRequestEvent",CCallRequestEvent)
CEventRankRequestEvent = CEventRankRequestEvent

 function CEventRankRequestEvent:Constructor()
    self.m_rank_type = RANK_TYPE.RANK_TYPE_INVALID -- 榜单类型, 具体业务类必须填充
end
---@private
CEventRankRequestEvent._proto = {
    [1] = {"m_rank_type", "int"},
}
--endregion

--region CEventRankReplyEvent define
---@class CEventRankReplyEvent:CCallReplyEvent
_class("CEventRankReplyEvent",CCallReplyEvent)
CEventRankReplyEvent = CEventRankReplyEvent

 function CEventRankReplyEvent:Constructor()
    self.m_ret = RANK_SER_RET_NO.TR_RANK_TYPE_ERR -- 返回码
end
---@private
CEventRankReplyEvent._proto = {
    [1] = {"m_ret", "int"},
}
--endregion

-- 分页拉取
--region CEventRankRoleRequestPage define
---@class CEventRankRoleRequestPage:CEventRankRequestEvent
_class("CEventRankRoleRequestPage",CEventRankRequestEvent)
CEventRankRoleRequestPage = CEventRankRoleRequestPage

 function CEventRankRoleRequestPage:Constructor()
    self.m_index = 0 -- 榜单位置索引,从0开始
    self.m_count = 0 -- 拉取的数量
end
---@private
CEventRankRoleRequestPage._proto = {
    [1] = {"m_index", "int"},
    [2] = {"m_count", "int"},
}
--endregion

--region CEventRankRoleReplyPage define
---@class CEventRankRoleReplyPage:CEventRankReplyEvent
_class("CEventRankRoleReplyPage",CEventRankReplyEvent)
CEventRankRoleReplyPage = CEventRankRoleReplyPage

 function CEventRankRoleReplyPage:Constructor()
    self.m_index = 0 -- 从榜单位置第几个拉
    self.m_count = 0 -- 拉取的数量
    self.m_rank_data = {} -- 返回的榜单数据 
end
---@private
CEventRankRoleReplyPage._proto = {
    [1] = {"m_index", "int"},
    [2] = {"m_count", "int"},
    [3] = {"m_rank_data", "list<buffer>"},
}
--endregion

-- 请求全部榜单
--region CEventRankRoleRequestTotal define
---@class CEventRankRoleRequestTotal:CEventRankRequestEvent
_class("CEventRankRoleRequestTotal",CEventRankRequestEvent)
CEventRankRoleRequestTotal = CEventRankRoleRequestTotal

 function CEventRankRoleRequestTotal:Constructor()
end
---@private
CEventRankRoleRequestTotal._proto = {
}
--endregion

--region CEventRankRoleReplyTotal define
---@class CEventRankRoleReplyTotal:CEventRankReplyEvent
_class("CEventRankRoleReplyTotal",CEventRankReplyEvent)
CEventRankRoleReplyTotal = CEventRankRoleReplyTotal

 function CEventRankRoleReplyTotal:Constructor()
    self.m_rank_data = {} -- 返回的榜单数据 
end
---@private
CEventRankRoleReplyTotal._proto = {
    [1] = {"m_rank_data", "list<buffer>"},
}
--endregion

-- 更新榜单中元素, 默认实现修改值
--region CEventRankRoleRequestUpdate define
---@class CEventRankRoleRequestUpdate:CEventRankRequestEvent
_class("CEventRankRoleRequestUpdate",CEventRankRequestEvent)
CEventRankRoleRequestUpdate = CEventRankRoleRequestUpdate

 function CEventRankRoleRequestUpdate:Constructor()
    self.m_pstid = 0 -- 玩家pstid
    self.m_value = 0 -- 要更新的值
end
---@private
CEventRankRoleRequestUpdate._proto = {
    [1] = {"m_pstid", "int64"},
    [2] = {"m_value", "int64"},
}
--endregion

--region CEventRankRoleReplyUpdate define
---@class CEventRankRoleReplyUpdate:CEventRankReplyEvent
_class("CEventRankRoleReplyUpdate",CEventRankReplyEvent)
CEventRankRoleReplyUpdate = CEventRankRoleReplyUpdate

 function CEventRankRoleReplyUpdate:Constructor()
    self.m_pstid = 0 -- 玩家pstid
    self.m_value = 0 -- 要更新的值
end
---@private
CEventRankRoleReplyUpdate._proto = {
    [1] = {"m_pstid", "int64"},
    [2] = {"m_value", "int64"},
}
--endregion

-- 从榜单中删除某玩家
--region CEventRankRoleRequestDelete define
---@class CEventRankRoleRequestDelete:CEventRankRequestEvent
_class("CEventRankRoleRequestDelete",CEventRankRequestEvent)
CEventRankRoleRequestDelete = CEventRankRoleRequestDelete

 function CEventRankRoleRequestDelete:Constructor()
    self.m_pstid = 0 -- 玩家pstid
end
---@private
CEventRankRoleRequestDelete._proto = {
    [1] = {"m_pstid", "int64"},
}
--endregion

--region CEventRankRoleReplyDelete define
---@class CEventRankRoleReplyDelete:CEventRankReplyEvent
_class("CEventRankRoleReplyDelete",CEventRankReplyEvent)
CEventRankRoleReplyDelete = CEventRankRoleReplyDelete

 function CEventRankRoleReplyDelete:Constructor()
    self.m_pstid = 0 -- 玩家pstid
end
---@private
CEventRankRoleReplyDelete._proto = {
    [1] = {"m_pstid", "int64"},
}
--endregion

--endregion dc define
