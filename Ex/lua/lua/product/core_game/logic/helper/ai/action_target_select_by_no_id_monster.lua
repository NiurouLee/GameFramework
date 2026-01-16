--[[-------------------------------------
    ActionTargetSelectByNoIDMonster 选择离我最近非指定ID的怪物

--]] -------------------------------------
require "ai_node_new"
---@class ActionTargetSelectByNoIDMonster:AINewNode
_class("ActionTargetSelectByNoIDMonster", AINewNode)
ActionTargetSelectByNoIDMonster = ActionTargetSelectByNoIDMonster

--------------------------------
function ActionTargetSelectByNoIDMonster:Constructor()
end
function ActionTargetSelectByNoIDMonster:Reset()
	ActionTargetSelectByNoIDMonster.super.Reset(self)
end
--------------------------------
function ActionTargetSelectByNoIDMonster:OnBegin()
	---@type AIComponentNew
	local aiCmpt = self.m_entityOwn:AI()
	self:FindTarget()
	---@type Entity
	local targetEntity = aiCmpt:GetTargetEntity()
    local monsterIDList = self.m_configData
    self.monsterIDStr = ""
    for _, id in ipairs(monsterIDList) do
        self.monsterIDStr = self.monsterIDStr .. tostring(id).." "
    end
end
---@return AINewNodeStatus 每次Update返回状态
function ActionTargetSelectByNoIDMonster:OnUpdate()
	---@type AIComponentNew
	local aiCmpt = self.m_entityOwn:AI()
	---@type Entity
	local entityPlayer = aiCmpt:GetTargetDefault()
	---一定要在分配过Bomb后调用如下代码

	self:FindTarget()
	---@type Entity
	local entityTarget = aiCmpt:GetTargetEntity()

    self:PrintDebugLog("目标ID = ",entityTarget:GetID(),"玩家ID = ",entityPlayer:GetID(),"排除的怪物ID=",self.monsterIDStr)
	---找到了目标
	if entityPlayer:GetID() ~= entityTarget:GetID() then
		return AINewNodeStatus.Success
	end
	return AINewNodeStatus.Failure
end
function ActionTargetSelectByNoIDMonster:OnEnd()
end

function ActionTargetSelectByNoIDMonster:FindTarget()
    local monsterIDList = self.m_configData
	---@type Vector2
	local ownPos = 	self.m_entityOwn:GetGridPosition()
	---@type UtilScopeCalcServiceShare
	local utilScopeCalc = self._world:GetService("UtilScopeCalc")
	local monsterList = utilScopeCalc:SortMonstersByPos(ownPos)
	local targetEntityID = nil
	for i, element in ipairs(monsterList) do
		---@type Entity
		local monsterEntity = element.monster_e
		if not table.icontains(monsterIDList,monsterEntity:MonsterID():GetMonsterClassID())and
			not monsterEntity:HasDeadMark()	then
			targetEntityID = monsterEntity:GetID()
			break
		end
	end
	self:SetRuntimeData("Target",targetEntityID)
end