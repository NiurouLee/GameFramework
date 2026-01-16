require("pick_up_policy_base")

_class("PickUpPolicy_MovePathEndPos", PickUpPolicy_Base)
---@class PickUpPolicy_MovePathEndPos: PickUpPolicy_Base
PickUpPolicy_MovePathEndPos = PickUpPolicy_MovePathEndPos

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_MovePathEndPos:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    
    ---需要返回的三个数据
    local posList = {}
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    local env = self:_GetPickUpPolicyEnv()
    ---@type AutoFightService
    local autoFightSvc = self._world:GetService("AutoFight")
    local chainPath, pieceType, evalue = autoFightSvc:GetAutoChainPath(calcParam.TT, env.TeamEntity)
    local pos = chainPath[#chainPath]
    
    --MSG31563
    local isBlockedSummonTrap = boardService:IsPosBlock(pos, BlockFlag.MonsterLand)
    local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
    if #chainPath == 1 or isBlockedSummonTrap or isBlockedLinkLine then
        return {}, {}, {}
    end

    table.insert(posList,pos)
    local result, targetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pos)
    attackPosList = result:GetAttackRange()

    return posList, attackPosList, targetIds
end