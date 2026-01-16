require("pick_up_policy_base")

_class("PickUpPolicy_PetSaiKaReverse", PickUpPolicy_Base)
---@class PickUpPolicy_PetSaiKaReverse: PickUpPolicy_Base
PickUpPolicy_PetSaiKaReverse = PickUpPolicy_PetSaiKaReverse

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetSaiKaReverse:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position
    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    
    local validResults = self:_CalcValidResultByPickUpType_PickUpPolicy(petEntity, activeSkillID, validPosList)
    
    local minPos = nil
    local minHP = -1
    for _, v in ipairs(validResults) do
        for _, id in ipairs(v[2]) do
            local e = self._world:GetEntityByID(id)
            local hp = e:Attributes():GetCurrentHP()
            if hp > 0 then
                if minHP < 0 or hp < minHP then
                    minHP = hp
                    minPos = v[1]
                    targetIdList = v[2]
                    attackPosList = v[3]
                end
            end
        end
    end
    return { minPos }, attackPosList, targetIdList
end