--检查自己是不是附身状态
require "ai_node_new"
---@class ActionCheckAttachStatus:AINewNode
_class("ActionCheckAttachStatus", AINewNode)
ActionCheckAttachStatus = ActionCheckAttachStatus

function ActionCheckAttachStatus:Constructor()
end


function ActionCheckAttachStatus:OnUpdate()
	---@type AIComponentNew
	local aiCmpt = self.m_entityOwn:AI()
	if aiCmpt:GetRuntimeData("AttachMonsterID") then
		return AINewNodeStatus.Success
	else
		if aiCmpt:GetRuntimeData("DetachBeginRunRound")  then
			if aiCmpt:GetRuntimeData("DetachBeginRunRound") <= self:GetGameRountNow() then
				aiCmpt:SetRuntimeData("DetachBeginRunRound",nil)
				return AINewNodeStatus.Failure
			else
				return AINewNodeStatus.Success
			end
		else
			return AINewNodeStatus.Failure
		end
	end
end
