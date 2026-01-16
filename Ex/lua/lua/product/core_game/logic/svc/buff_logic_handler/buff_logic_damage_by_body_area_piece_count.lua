--[[
    触发后对目标造成伤害，走伤害公式 根据目标身形下某些颜色格子的数量计算伤害比例
]]
_class("BuffLogicDamageByBodyAreaPieceCount", BuffLogicBase)
BuffLogicDamageByBodyAreaPieceCount = BuffLogicDamageByBodyAreaPieceCount

function BuffLogicDamageByBodyAreaPieceCount:Constructor(buffInstance, logicParam)
    self._damageParam = logicParam

    self._basePercent = logicParam.percent

    self._pieceType = logicParam.pieceType or {}
    self._excludeTrap = logicParam.excludeTrap or {}
end

function BuffLogicDamageByBodyAreaPieceCount:DoLogic(notify)
    local context = self._buffInstance:Context()
    if not context then
        return
    end
    local petEntity = context.casterEntity
    if not petEntity then
        return
    end
    local defender = self._entity

    ---重置第二属性标记，到这里有可能玩家还在使用第二属性
    ---@type ElementComponent
    local playerElementCmpt = petEntity:Element()
    if playerElementCmpt then
        playerElementCmpt:SetUseSecondaryType(false)
    end

    local pieceCount = 1
    local bodyAreaPosList = {}
    local bodyAreaList = defender:BodyArea():GetArea()
    local gridPos = defender:GridLocation():GetGridPos()
    for _, bodyArea in ipairs(bodyAreaList) do
        local workPos = gridPos + bodyArea
        table.insert(bodyAreaPosList,workPos)
    end
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local posList =
        boardServiceLogic:FindPieceElementByTypeCountAndCenterFromParam(
        gridPos,
        self._pieceType,
        #bodyAreaPosList,
        bodyAreaPosList
    )
    local pieceCount = table.count(posList)
    local newPercent = 0
    newPercent = self._basePercent * pieceCount
    if newPercent == 0 then
        return --没有伤害就不计算
    end

    --重新赋值伤害系数
    self._damageParam.percent = newPercent

    self._world:GetMatchLogger():BeginBuff(defender:GetID(), self._buffInstance:BuffID())

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), petEntity, defender, self._damageParam)

    self._world:GetMatchLogger():EndBuff(defender:GetID())

    local buffResult = BuffResultDamage:New(damageInfo)

    return buffResult
end
