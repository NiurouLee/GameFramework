--[[
    根据层数修改防御力
]]
--设置技能伤害加成
_class("BuffLogicChangeDefenceByLayer", BuffLogicBase)
---@class BuffLogicChangeDefenceByLayer:BuffLogicBase
BuffLogicChangeDefenceByLayer = BuffLogicChangeDefenceByLayer

function BuffLogicChangeDefenceByLayer:Constructor(buffInstance, logicParam)
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._maxValueNeedCheck = logicParam.maxValueNeedCheck --计算多个buff的效果合
    self._oneLayerAddMulValue = logicParam.oneLayerAddMulValue or 0
    self._oneLayerAddValue = logicParam.oneLayerAddValue or 0
    self._maxAddMulValue = logicParam.maxAddMulValue --添加最大值
    self._costHPGrowUp = logicParam.costHPGrowUp or 0
    self._costHpGrowUpMax = logicParam.costHpGrowUpMax or 1
    self._useTeamLayer = logicParam.useTeamLayer or 0 --从队伍身上取layer
    self._overrideModifierIDByLayerType = logicParam.overrideModifierIDByLayerType
end

function BuffLogicChangeDefenceByLayer:DoLogic()
    local modifierID = self._overrideModifierIDByLayerType and self._layerType or self:GetBuffSeq()

    local layerEntity = self._entity
    if self._useTeamLayer == 1 then
        if self._entity:HasPet() then
            layerEntity = self._entity:Pet():GetOwnerTeamEntity()
        end
    end
    local curMarkLayer = self._buffLogicService:GetBuffLayer(layerEntity, self._layerType)

    if curMarkLayer then --不能判断>0 层数清空的时候要修改防御
        if self._oneLayerAddMulValue ~= 0 then
            local change = self._oneLayerAddMulValue * curMarkLayer
            if self._maxAddMulValue then
                if change > self._maxAddMulValue then
                    change = self._maxAddMulValue
                end
            end
            if self._costHPGrowUp ~= 0 then
                ---@type BattleService
                local battleService = self._world:GetService("Battle")
                local hp, maxHP = battleService:GetCasterHP(self._entity)
                local hpPercent = hp / maxHP
                change = change * (1 + (1 - hpPercent) * self._costHpGrowUpMax)
            end

            if self._maxValueNeedCheck then
                ---@type BuffComponent
                local buffCmpt = layerEntity:BuffComponent()
                --其他的buff 添加的值
                local otherBuffAddValue = 0

                for _, layerType in ipairs(self._maxValueNeedCheck) do
                    if self._layerType ~= layerType then
                        local targetBuff = buffCmpt:GetSingleBuffByBuffEffect(layerType)
                        if targetBuff then
                            local targetBuffSeq = targetBuff:BuffSeq()

                            local targetVaue =
                                self._buffLogicService:GetBaseDefence(
                                self._entity,
                                targetBuffSeq,
                                ModifyBaseDefenceType.DefencePercentage
                            )

                            otherBuffAddValue = otherBuffAddValue + targetVaue
                        end
                    end
                end
                if change + otherBuffAddValue > self._maxAddMulValue then
                    change = self._maxAddMulValue - otherBuffAddValue
                end
            end

            self._buffLogicService:ChangeBaseDefence(
                self._entity,
                modifierID,
                ModifyBaseDefenceType.DefencePercentage,
                change
            )
        end
        if self._oneLayerAddValue ~= 0 then
            local change = math.floor(self._oneLayerAddValue * curMarkLayer)
            if self._maxAddMulValue then
                if change > self._maxAddMulValue then
                    change = self._maxAddMulValue
                end
            end
            self._buffLogicService:ChangeBaseDefence(
                self._entity,
                modifierID,
                ModifyBaseDefenceType.DefenceConstantFix,
                change
            )
        end
        if self._entity:HasPetPstID() then
            local teamEntity = self._entity:Pet():GetOwnerTeamEntity()
            self:UpdateTeamDefenceLogic(teamEntity)
        end
        return true
    end
end

function BuffLogicChangeDefenceByLayer:DoOverlap()
    return self:DoLogic()
end

_class("BuffLogicRemoveChangeDefenceByLayer", BuffLogicBase)
---@class BuffLogicRemoveChangeDefenceByLayer:BuffLogicBase
BuffLogicRemoveChangeDefenceByLayer = BuffLogicRemoveChangeDefenceByLayer

function BuffLogicRemoveChangeDefenceByLayer:Constructor(buffInstance, logicParam)
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._overrideModifierIDByLayerType = logicParam.overrideModifierIDByLayerType
end

function BuffLogicRemoveChangeDefenceByLayer:DoLogic()
    local modifierID = self._overrideModifierIDByLayerType and self._layerType or self:GetBuffSeq()

    self._buffLogicService:RemoveBaseDefence(self._entity, modifierID, ModifyBaseDefenceType.DefencePercentage)
    self._buffLogicService:RemoveBaseDefence(self._entity, modifierID, ModifyBaseDefenceType.DefenceConstantFix)
    if self._entity:HasPetPstID() then
        local teamEntity = self._entity:Pet():GetOwnerTeamEntity()
        self:UpdateTeamDefenceLogic(teamEntity)
    end
    return true
end

function BuffLogicRemoveChangeDefenceByLayer:DoOverlap()
end
