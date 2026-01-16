--[[
    ConvertAndDamageByLinkLine = 198, N28光灵蒂娜：通过连线位移的方式进行转色及伤害，若造成伤害则瞬移至连线终点前的位置
]]
---@class SkillEffectCalc_ConvertAndDamageByLinkLine: Object
_class("SkillEffectCalc_ConvertAndDamageByLinkLine", Object)
SkillEffectCalc_ConvertAndDamageByLinkLine = SkillEffectCalc_ConvertAndDamageByLinkLine

function SkillEffectCalc_ConvertAndDamageByLinkLine:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ConvertAndDamageByLinkLine:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)

    ---@type ActiveSkillPickUpComponent
    local activeSkillPickUpCmpt = casterEntity:ActiveSkillPickUpComponent()
    if not activeSkillPickUpCmpt then
        return
    end
    local chainPath = activeSkillPickUpCmpt:GetAllValidPickUpGridPos()

    --连线数量不足
    local linkCount = #chainPath
    if linkCount <= 1 then
        return
    end

    ---@type SkillEffectConvertAndDamageByLinkLineParam
    local skillEffectParam = skillEffectCalcParam:GetSkillEffectParam()
    local convertCount = skillEffectParam:GetConvertCount()
    local canLinkMonster = skillEffectParam:IsCanLinkMonster()

    --最大可连线数量
    local maxLinkCount = convertCount + 1
    if canLinkMonster then
        maxLinkCount = maxLinkCount + 1
    end

    --连线数量超出技能配置的最大连线数量
    if linkCount > maxLinkCount then
        return
    end

    --检查最后连线是否连到怪物脚下
    local isLinkMonster = false
    local lastPos = chainPath[#chainPath]
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local monsterEntity = utilDataSvc:GetMonsterAtPos(lastPos)
    if monsterEntity then
        isLinkMonster = true
    end

    ---@type SkillEffectConvertAndDamageByLinkLineResult
    local effectResult = SkillEffectConvertAndDamageByLinkLineResult:New()

    --连线路径结果
    local linkPosList = table.cloneconf(chainPath)
    --连线转色格子列表
    local convertLinePosList = table.cloneconf(chainPath)
    --连线终点转色格子
    local convertEndPos = nil
    --攻击位置
    local attackPos = casterEntity:GetGridPosition()

    if isLinkMonster then
        --直接连线到怪物脚下，无行走路径，无转色
        if #chainPath == 2 then
            linkPosList = {}
            convertLinePosList = {}
            convertEndPos = nil
        else
            --连线路径去除怪脚下
            table.remove(linkPosList, #linkPosList)
            --连线转色格子，去除起点、怪脚下和连线终点
            table.remove(convertLinePosList, 1)
            table.remove(convertLinePosList, #convertLinePosList)
            table.remove(convertLinePosList, #convertLinePosList)
            --连线终点转灰格子（玩家最终位置）
            convertEndPos = chainPath[#chainPath - 1]
            --攻击位置
            attackPos = convertEndPos
            --计算瞬移结果
            local teleportRes = self:CalculateTeleportResult(skillEffectCalcParam, attackPos, monsterEntity)
            effectResult:SetTeleportResult(teleportRes)
        end
    else
        --连线转色格子去除第一个格子（玩家脚下）
        table.remove(convertLinePosList, 1)
    end

    --设置连线路径结果
    effectResult:SetChainPath(linkPosList)

    --转色
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    if #convertLinePosList > 0 then
        local skillRangePosList = {}
        local convertType = skillEffectParam:GetConvertType()
        for _, pos in pairs(convertLinePosList) do
            local canConverPos = boardServiceLogic:GetCanConvertGridElement(pos)
            local pieceType = boardServiceLogic:GetPieceType(pos)
            if canConverPos and pieceType ~= convertType then
                table.insert(skillRangePosList, pos)
            end
        end
        local convertResult = SkillConvertGridElementEffectResult:New(skillRangePosList, convertType)
        effectResult:SetConvertResult(convertResult)
    end

    --伤害
    if isLinkMonster then
        local damageResult = self:CalculateDamageResult(skillEffectCalcParam, attackPos, monsterEntity)
        effectResult:SetDamageResult(damageResult)
    end

    return { effectResult }
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param newPos Vector2
---@param defenderEntity Entity
---@return SkillEffectResult_Teleport
function SkillEffectCalc_ConvertAndDamageByLinkLine:CalculateTeleportResult(skillEffectCalcParam, newPos, defenderEntity)
    ---@type SkillEffectConvertAndDamageByLinkLineParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local pieceType = param:GetConvertType()

    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local casterPos = casterEntity:GetGridPosition():Clone()
    local defenderPos = defenderEntity:GetGridPosition()
    local dirNew = defenderPos - newPos

    local stageIndex = param:GetSkillEffectDamageStageIndex()

    ---@type SkillEffectResult_Teleport
    local result = SkillEffectResult_Teleport:New(
        casterEntityID,
        casterPos,
        pieceType,
        newPos,
        dirNew,
        stageIndex
    )

    return result
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param attackPos Vector2
---@param defenderEntity Entity
---@return SkillDamageEffectResult
function SkillEffectCalc_ConvertAndDamageByLinkLine:CalculateDamageResult(skillEffectCalcParam, attackPos, defenderEntity)
    ---@type SkillEffectConvertAndDamageByLinkLineParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local percentList = param:GetPercent()
    local curFormulaID = param:GetFormulaID()
    if curFormulaID == nil then
        curFormulaID = 5 --主动技伤害公式
    end

    --攻击者和被击者
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local defenderPos = defenderEntity:GetGridPosition()

    --伤害参数
    local skillDamageParam = SkillDamageEffectParam:New(
        {
            percent = percentList,
            formulaID = curFormulaID,
            damageStageIndex = 1
        }
    )

    --伤害计算
    local nTotalDamage, listDamageInfo = self._skillEffectService:ComputeSkillDamage(
        casterEntity,
        attackPos,
        defenderEntity,
        defenderPos,
        skillEffectCalcParam:GetSkillID(),
        skillDamageParam,
        SkillEffectType.ConvertAndDamageByLinkLine,
        1
    )

    local damageRes = self._skillEffectService:NewSkillDamageEffectResult(
        defenderPos,
        defenderEntity:GetID(),
        nTotalDamage,
        listDamageInfo
    )
    return damageRes
end
