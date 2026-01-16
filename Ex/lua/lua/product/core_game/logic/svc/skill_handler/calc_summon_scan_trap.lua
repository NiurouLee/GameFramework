_class("SkillEffectCalc_SummonScanTrap", SkillEffectCalc_Base)
---@class SkillEffectCalc_SummonScanTrap : SkillEffectCalc_Base
SkillEffectCalc_SummonScanTrap = SkillEffectCalc_SummonScanTrap

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonScanTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    local cLogicFeature = self._world:GetBoardEntity():LogicFeature()
    local trapID = cLogicFeature:GetScanTrapID()

    if (not trapID) or (trapID == 0) then
        return
    end

    ---@type CfgTrapScan
    local cfgTrapScan = Cfg.cfg_trap_scan[trapID]
    if not cfgTrapScan then
        Log.exception("SummonScanTrap: invalid trap id: ", tostring(trapID))
        return
    end

    local results = {}

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    for _, gridPos in ipairs(skillEffectCalcParam:GetSkillRange()) do
        if not trapServiceLogic:CanSummonTrapOnPos(gridPos, trapID, BlockFlag.None) then
            goto CONTINUE
        end

        local result = self:_DoSummonProcess(trapID, gridPos, skillEffectCalcParam)
        if result then
            table.insert(results, result)
        end

        ::CONTINUE::
    end

    return results
end

function SkillEffectCalc_SummonScanTrap:_DoSummonProcess(trapID, gridPos, skillEffectCalcParam)
    ---@type CfgTrapScan
    local cfgTrapScan = Cfg.cfg_trap_scan[trapID]

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local skillID = skillEffectCalcParam:GetSkillID()

    local tDestroyTrapInfo = {}
    local tAddBuffResults = {}

    --region 销毁超过数量上限的机关
    if cfgTrapScan.GlobalMaxCount and cfgTrapScan.GlobalMaxCount > 0 then
        tDestroyTrapInfo = self:DestroyTrapOutOfLimit(cfgTrapScan, casterEntity)
    end
    --endregion

    --region 创建机关
    local summonResult = SkillSummonTrapEffectResult:New(trapID, gridPos)
    local trapEntity = trapServiceLogic:CreateTrap(trapID, gridPos, Vector2(0, 1), true, nil, casterEntity)

    --[[
        MSG64467 CreateTrap可能失败并返回nil
        因阿克希娅的主动技本来就可能出现【可点选释放，但无法召唤】的状况
        协商确定预期为【正常播表现，不卡死即可】
    ]]
    if not trapEntity then
        return
    end


    if table.icontains(BattleConst.AkexiyaScanTrap_MeantimeLimitID, trapID) then
        ---@type BattleFlagsComponent
        local cBattleFlag = self._world:BattleFlags()
        local t = cBattleFlag:GetSummonMeantimeLimitEntityID(trapID)
        table.insert(t, trapEntity:GetID())
        cBattleFlag:SetSummonMeantimeLimitEntityID(trapID, t)
    end
    --endregion

    --特殊处理：娜丁(白铃)使用了独特的攻击力传递方式
    --讨论后的做法是，所有机关都找本主取数值，进行攻击力传递
    --local cfgTrapScan = Cfg.cfg_trap_scan[trapID]
    local petTemplateID = cfgTrapScan.PetID
    if petTemplateID then
        ---@type Entity
        local eLocalTeam = self._world:Player():GetLocalTeamEntity()
        local cTeam = eLocalTeam:Team()
        ---@type Entity[]
        local petEntities = cTeam:GetTeamPetEntities()
        for _, e in ipairs(petEntities) do
            local tid = e:PetPstID():GetTemplateID()
            if tid == petTemplateID then
                local attack = e:Attributes():GetAttack()
                trapEntity:BuffComponent():SetBuffValue("GuestAttack", attack)
            end
        end
    end

    -- 因为涉及添加buff的操作，这个计算器在计算当场就会直接execute
    --region 添加特殊buff
    if cfgTrapScan.Buff and (#cfgTrapScan.Buff > 0) then
        ---@type SkillEffectCalc_AddBuff
        local addBuffCalc = SkillEffectCalc_AddBuff:New(self._world)
        for _, buffID in ipairs(cfgTrapScan.Buff) do
            local addBuffParam = SkillAddBuffEffectParam:New({prob = 1, buffID = buffID,})
            local addBuffResult = addBuffCalc:DoSkillEffectCalculator(SkillEffectCalcParam:New(
                casterEntity:GetID(),
                {trapEntity:GetID()},
                addBuffParam,
                skillID,
                {gridPos},
                gridPos,
                gridPos
            ))
            if addBuffResult then
                table.appendArray(tAddBuffResults, addBuffResult)
            end
        end
    end
    --endregion

    --region 创建技能结果
    local result = SkillEffectResult_SummonScanTrap:New(trapEntity:GetID(), tDestroyTrapInfo, tAddBuffResults)
    --endregion

    return result
end

---@param cfgTrapScan CfgTrapScan
---@param casterEntity Entity
function SkillEffectCalc_SummonScanTrap:DestroyTrapOutOfLimit(cfgTrapScan, casterEntity, count)
    count = count or 1
    local trapID = cfgTrapScan.ID
    ---@type Entity[]
    local trapEntities = {}

    ---@type Entity[]
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _,e in ipairs(globalTrapEntities) do
        if (not e:HasDeadMark())  and (e:TrapID():GetTrapID() == trapID)then
            table.insert(trapEntities, e)
        end
    end

    -- 请求的数量没有超过时不予销毁
    if #trapEntities + count < cfgTrapScan.GlobalMaxCount then
        return {}
    end

    table.sort(trapEntities, function (a, b)
        return a:GetID() < b:GetID()
    end)

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    local r = {}
    for i = 1, count do
        if #trapEntities == 0 then
            break
        end

        local e = table.remove(trapEntities, 1)

        local info = {entityID = e:GetID()}

        --MSG70156
        ---@type TrapComponent
        local cTrap = e:Trap()
        local skillID = cTrap:GetDisappearSkillID()
        if skillID and skillID > 0 then
            skillLogicSvc:CalcSkillEffect(e, skillID)
            local skillResultContainer = e:SkillContext():GetResultContainer()
            info.replacingSkillContainer = skillResultContainer
            info.skillID = skillID
        end

        e:Attributes():Modify("HP", 0)
        trapServiceLogic:AddTrapDeadMark(e)

        table.insert(r, info)
    end

    return r
end
