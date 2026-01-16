require("pick_up_policy_base")

_class("PickUpPolicy_PetANaTuoLi", PickUpPolicy_Base)
---@class PickUpPolicy_PetANaTuoLi: PickUpPolicy_Base
PickUpPolicy_PetANaTuoLi = PickUpPolicy_PetANaTuoLi

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetANaTuoLi:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    ---获取配置的点选的数量
    local pickUpNum = self:_GetPickUpNumByConfig(activeSkillID)

    local petColor = petEntity:Element():GetPrimaryType()
    local casterPos = petEntity:GridLocation().Position

    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ----@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---需要返回的三个数据
    local posList = {}
    local targetIdList = {} --攻击目标
    local attackPosList = {} --攻击范围
    local pickMonsterList = {}--不能重复

    local ringMax = boardService:GetCurBoardRingMax()
    local casterPosIndex = self:_Pos2Index(casterPos)
    local env = self:_GetPickUpPolicyEnv()

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            local isRepeatMonster = false
            local isValidTarget = true
            local entity =utilDataSvc:GetMonsterAtPos(pos)
            if entity then
                if entity and entity:HasBuff() and not buffLogicSvc:CheckCanBeMagicAttack(petEntity, entity) then
                    isValidTarget = false
                end
                if isValidTarget then
                    local entityID = entity:GetID()
                    if table.icontains(pickMonsterList,entityID) then
                        isRepeatMonster = true
                    else
                        table.insert(pickMonsterList,entityID)
                    end
                end
            end
            if isValidTarget and not isRepeatMonster then
                posList[#posList + 1] = pos
                if #posList >= pickUpNum then
                    break
                end
            end
        end
    end
    if #posList > 0 then
        attackPosList = {}
        targetIdList = pickMonsterList
        -- local result, targetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, posList)
        -- table.appendArray(attackPosList, result:GetAttackRange())
        -- table.appendArray(targetIdList, targetIds)
    end
    return posList, attackPosList, targetIdList
end