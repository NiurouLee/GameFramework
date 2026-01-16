_class("BuffLogicDoHarmReductionByDistance", BuffLogicBase)
---@class BuffLogicDoHarmReductionByDistance : BuffLogicBase
BuffLogicDoHarmReductionByDistance = BuffLogicDoHarmReductionByDistance

function BuffLogicDoHarmReductionByDistance:Constructor(_buffIns, logicParam)
    self._reductionRates = logicParam.reductionRates
end

---@param notify NotifyAttackBase
function BuffLogicDoHarmReductionByDistance:DoLogic(notify)
    if type(notify.GetAttackerEntity) ~= "function" then
        Log.error(self._className, "incompatable notify. ")
        return
    end

    -- 以配置最大圈数+1作为单位的搜索范围
    local maxRing = #self._reductionRates

    ---@type Entity
    local e = notify:GetAttackerEntity()
    local v2AttackerGridPos = e:GetGridPosition()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)

    local v2SelfGridPos = self:GetEntity():GetGridPosition()
    local body = self:GetEntity():BodyArea():GetArea()
    local v2dir = self:GetEntity():GetGridDirection()

    local targetReductionRate
    for ring = 1, maxRing do
        if not self._reductionRates[ring] then
            Log.exception(self._className, "reductionRate得是从1开始的连续数组")
            return
        end

        -- 这块如果自己写还要重新考虑身形影响之类的，直接复用现有的范围逻辑
        local scopeResult = scopeCalc:ComputeScopeRange(
            SkillScopeType.AroundBodyArea,
            {1, ring},
            v2SelfGridPos,
            body,
            v2dir,
            SkillTargetType.Pet,
            v2SelfGridPos
        )

        if table.icontains(scopeResult:GetAttackRange(), v2AttackerGridPos) then
            targetReductionRate = self._reductionRates[ring]
            break
        end
    end

    if not targetReductionRate then 
        targetReductionRate = self._reductionRates[#self._reductionRates]
    end
    
    self._buffLogicService:ChangeFinalBeHitDamageParam(self._entity, self:GetBuffSeq(), targetReductionRate)
end

_class("BuffLogicRemoveHarmReductionByDistance", BuffLogicBase)
---@class BuffLogicRemoveHarmReductionByDistance : BuffLogicBase
BuffLogicRemoveHarmReductionByDistance = BuffLogicRemoveHarmReductionByDistance

function BuffLogicRemoveHarmReductionByDistance:DoLogic()
    self._buffLogicService:RemoveFinalBeHitDamageParam(self._entity, self:GetBuffSeq())
end
