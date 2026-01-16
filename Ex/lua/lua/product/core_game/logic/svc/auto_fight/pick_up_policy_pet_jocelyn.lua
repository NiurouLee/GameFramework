require("pick_up_policy_base")

_class("PickUpPolicy_PetJocelyn", PickUpPolicy_Base)
---@class PickUpPolicy_PetJocelyn: PickUpPolicy_Base
PickUpPolicy_PetJocelyn = PickUpPolicy_PetJocelyn

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetJocelyn:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local dirCount = calcParam.policyParam[1]
    local buffEffectID = calcParam.policyParam[2]
    local casterPos = petEntity:GetGridPosition()
    local offSets
    if dirCount == 4 then
        offSets = Offset4
    elseif dirCount == 8 then
        offSets = Offset8
    else
        Log.fatal("AutoFight Invalid dirCount,activeSkillID",activeSkillID)
    end
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    local maxLen= math.max(boardSvc:GetCurBoardMaxX(),boardSvc:GetCurBoardMaxY())
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    local maxBuffLayerCount = 0
    local pickUpPos
    local targetID
    for _, offset in ipairs(offSets) do
        local newPos = Vector2(casterPos.x + offset[1], casterPos.y + offset[2])
        for i = 1, maxLen do
            local monsterPos =Vector2(casterPos.x + offset[1]*i, casterPos.y + offset[2]*i)
            local monsterEntityIDList =battleSvc:FindMonsterEntityInPos(monsterPos)
            if #monsterEntityIDList>0 then
                local entity
                ---骑乘的情况
                if #monsterEntityIDList>1 then
                    entity = self._world:GetEntityByID(monsterEntityIDList[2])
                else
                    entity = self._world:GetEntityByID(monsterEntityIDList[1])
                end

                if entity then
                    local buffLayerCount = buffLogicSvc:GetBuffLayer(entity,buffEffectID)
                    if buffLayerCount >= maxBuffLayerCount then
                        maxBuffLayerCount = buffLayerCount
                        pickUpPos = newPos
                        targetID = monsterEntityIDList[1]
                    end
                end
            end
            if boardSvc:IsPosBlock(monsterPos,BlockFlag.LinkLine) then
                break
            end
        end
    end
    if not pickUpPos then
        return {},{},{}
    end
    return { pickUpPos },{pickUpPos},{targetID}
end
