require("pick_up_policy_base")

_class("PickUpPolicy_PetSaiKa", PickUpPolicy_Base)
---@class PickUpPolicy_PetSaiKa: PickUpPolicy_Base
PickUpPolicy_PetSaiKa = PickUpPolicy_PetSaiKa

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetSaiKa:CalcAutoFightPickUpPolicy(calcParam)
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
    
    local maxPos = nil
    local maxHP = 0
    for _, v in ipairs(validResults) do
        for _, id in ipairs(v[2]) do
            local e = self._world:GetEntityByID(id)
            local hp = e:Attributes():GetCurrentHP()
            if hp > maxHP then
                maxHP = hp
                maxPos = v[1]
                targetIdList = v[2]
                attackPosList = v[3]
            end
        end
    end
    return { maxPos }, attackPosList, targetIdList
end