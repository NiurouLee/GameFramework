--[[
    根据目标脚下格子的颜色匹配数量增加技能伤害
]]
---@class BuffLogicChangeSkillIncreaseByTargetPieceMatchCount:BuffLogicBase
_class("BuffLogicChangeSkillIncreaseByTargetPieceMatchCount", BuffLogicBase)
BuffLogicChangeSkillIncreaseByTargetPieceMatchCount = BuffLogicChangeSkillIncreaseByTargetPieceMatchCount

function BuffLogicChangeSkillIncreaseByTargetPieceMatchCount:Constructor(buffInstance, logicParam)
    self._buffInstance._effectList = logicParam.effectList
    self._changeValue = logicParam.changeValue or 0
    self._pieceTypeList = logicParam.pieceTypeList or {}
end

function BuffLogicChangeSkillIncreaseByTargetPieceMatchCount:DoLogic(notify)
    if not notify.GetDefenderEntity then
        return
    end

    ---@type Entity
    local defenderEntity = notify:GetDefenderEntity()
    local defenderPos = defenderEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = defenderEntity:BodyArea()
    if not bodyAreaCmpt then
        return
    end
    local bodyArea = bodyAreaCmpt:GetArea()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local count = 0
    for _, posOffset in ipairs(bodyArea) do
        local newPos = defenderPos + posOffset
        local pieceType = utilDataSvc:GetPieceType(newPos)
        if table.icontains(self._pieceTypeList, pieceType) then
            count = count + 1
        end
    end

    --增加的数值
    local changeValue = self._changeValue * count

    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:ChangeSkillIncrease(self._entity, self:GetBuffSeq(), paramType, changeValue)
    end
end

---@class BuffLogicRemoveSkillIncreaseByTargetPieceMatchCount:BuffLogicBase
_class("BuffLogicRemoveSkillIncreaseByTargetPieceMatchCount", BuffLogicBase)
BuffLogicRemoveSkillIncreaseByTargetPieceMatchCount = BuffLogicRemoveSkillIncreaseByTargetPieceMatchCount

function BuffLogicRemoveSkillIncreaseByTargetPieceMatchCount:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSkillIncreaseByTargetPieceMatchCount:DoLogic()
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(self._entity, self:GetBuffSeq(), paramType)
    end
end
