require("pick_up_policy_base")

_class("PickUpPolicy_PetLingEn", PickUpPolicy_Base)
---@class PickUpPolicy_PetLingEn: PickUpPolicy_Base
PickUpPolicy_PetLingEn = PickUpPolicy_PetLingEn

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetLingEn:CalcAutoFightPickUpPolicy(calcParam)
    ---@type Entity
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    local layerType = policyParam.layerType
    local cfgLayerCount = policyParam.layerCountDamageOrBuff
    local cfgCanCastLayerCount = policyParam.layerCountDamage

    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local curLayerCount = svc:GetBuffLayer(petEntity, layerType)

    ---点自己，释放Buff
    if cfgLayerCount and curLayerCount < cfgLayerCount then
        pickPosList[1] = petEntity:GetGridPosition():Clone()
        attackPosList = pickPosList
        targetIdList[1] = petEntity:GetID()
        return pickPosList, attackPosList, targetIdList
    end

    if cfgCanCastLayerCount and curLayerCount < cfgCanCastLayerCount then
        ---沒达到配置层数，返回空，不释放
        return pickPosList, attackPosList, targetIdList
    end

    ---寻找伤害目标最多的方向
    local validPosIdxList, validPosList = self:_CalcPickUpValidGridList(petEntity, activeSkillID)
    local validResults = self:_CalcValidResultByPickUpType_PickUpPolicy(petEntity, activeSkillID, validPosList)
    if #validResults > 0 then
        table.sort(
            validResults,
            function(a, b)
                return #a[2] > #b[2]
            end
        )

        local t = validResults[1]
        if t then
            pickPosList[1] = t[1]
            table.appendArray(targetIdList, t[2])
            table.appendArray(attackPosList, t[3])
        end
    end
    return pickPosList, attackPosList, targetIdList
end
