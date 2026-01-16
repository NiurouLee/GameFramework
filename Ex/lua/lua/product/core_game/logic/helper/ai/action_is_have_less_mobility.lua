--[[---------------------------------------------------------------
    2020-07-08 韩玉信
    ActionIs_HaveLessMobility 检测目标是否有特定的行动力
--]] ---------------------------------------------------------------
require "action_is_base"
---------------------------------------------------------------
_class("ActionIs_HaveLessMobility", ActionIsBase)
---@class ActionIs_HaveLessMobility:ActionIsBase
ActionIs_HaveLessMobility = ActionIs_HaveLessMobility

function ActionIs_HaveLessMobility:Constructor()
end

function ActionIs_HaveLessMobility:OnUpdate()
    ---从Config获取需要检测的行动点数
    local nConfigMobility = self:GetLogicData(-1)
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local nMobilityValid = aiCmpt:GetMobilityValid()
    local totalMobility = aiCmpt:GetMobilityConfig()

    local nReturn = AINewNodeStatus.Failure
    if nMobilityValid <= nConfigMobility then
        nReturn = AINewNodeStatus.Success
    end
    
    self:PrintLog("检测剩余行动力 nMobilityValid = " ,nMobilityValid,"TotalMobility =",totalMobility )
    self:PrintDebugLog("检测剩余行动力 nMobilityValid = " ,nMobilityValid,"TotalMobility =",totalMobility )
    return nReturn
end
---------------------------------------------------------------
