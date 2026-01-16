--[[
    根据距离改变主动技和连锁技伤害
]]
--设置技能伤害加成
---@class BuffLogicChangeSkillIncreaseByDistance:BuffLogicBase
_class("BuffLogicChangeSkillIncreaseByDistance", BuffLogicBase)
BuffLogicChangeSkillIncreaseByDistance = BuffLogicChangeSkillIncreaseByDistance

function BuffLogicChangeSkillIncreaseByDistance:Constructor(buffInstance, logicParam)
    self._ratesByDis = logicParam.ratesByDis or {}
    self._entity = buffInstance:Entity()
    self._disToPick = logicParam.disToPick
end

function BuffLogicChangeSkillIncreaseByDistance:DoLogic(notify)
    if notify == nil then
        return
    end
    local attacker = notify:GetNotifyEntity()
    if self._entity ~= attacker then
        return
    end
    local notifyType = notify:GetNotifyType()
    --攻击者的位置
    local attackerPos = self._entity:GridLocation().Position
    if self._disToPick then
        local pickIndex = tonumber(self._disToPick)
        ---@type ActiveSkillPickUpComponent
        local component = self._entity:ActiveSkillPickUpComponent()
        if component then
            local pickVec = component:GetAllValidPickUpGridPos()
            if #pickVec >= pickIndex then
                attackerPos = pickVec[pickIndex]
            end
        end
    end
    if notifyType == NotifyType.ChainSkillEachAttackStart then --连锁技开始
        ---@type Entity
        local teamEntity = self._entity:Pet():GetOwnerTeamEntity()
        ---@type LogicChainPathComponent
        local logicChainPathCmpt = teamEntity:LogicChainPath()

        local chainPath = logicChainPathCmpt:GetLogicChainPath()
        if chainPath and #chainPath >= 1 then
            attackerPos = chainPath[#chainPath]
        end
    end

    local dis = 100
    local skillID = notify:GetSkillID()
    local configsvc = self._world:GetService("Config")
    local skillConfig = configsvc:GetSkillConfigData(skillID)
    local filter = skillConfig:GetScopeFilterParam()
    local targetMode = filter:GetTargetSelectionMode()
    --被攻击的位置
    if targetMode == SkillTargetSelectionMode.Grid then
        local defenderPos = notify:GetTargetPos()
        --计算释放者和被攻击位置的距离
        local offsetX = math.abs(defenderPos.x - attackerPos.x)
        local offsetY = math.abs(defenderPos.y - attackerPos.y)
        dis = offsetX > offsetY and offsetX or offsetY
    elseif targetMode == SkillTargetSelectionMode.Entity then
        ---@type Entity
        local defender = notify:GetDefenderEntity()
        local defenderPos = defender:GridLocation().Position
        local defenderArea = defender:BodyArea():GetArea()

        for i, v in ipairs(defenderArea) do
            local pos = defenderPos + v
            --计算释放者和被攻击位置的距离
            local offsetX = math.abs(pos.x - attackerPos.x)
            local offsetY = math.abs(pos.y - attackerPos.y)
            local d = offsetX > offsetY and offsetX or offsetY
            dis = d < dis and d or dis
        end
    end
    --获取增加的数值
    local changeValue = self._ratesByDis[dis]
    if not changeValue then
        -- Log.warn("### get rate failed. dis=", dis)
        return
    end
    if notifyType == NotifyType.ChainSkillEachAttackStart then --连锁技开始
        self._buffLogicService:ChangeSkillIncrease(
            self._entity,
            self:GetBuffSeq(),
            ModifySkillIncreaseParamType.ChainSkill,
            changeValue
        )
    elseif notifyType == NotifyType.ActiveSkillEachAttackStart then --主动技开始
        self._buffLogicService:ChangeSkillIncrease(
            self._entity,
            self:GetBuffSeq(),
            ModifySkillIncreaseParamType.ActiveSkill,
            changeValue
        )
    elseif notifyType == NotifyType.MonsterEachAttackStart then --怪物攻击前
        self._buffLogicService:ChangeSkillIncrease(
            self._entity,
            self:GetBuffSeq(),
            ModifySkillIncreaseParamType.MonsterDamage,
            changeValue
        )
    end
end

---@class BuffLogicRemoveSkillIncreaseByDistance:BuffLogicBase
_class("BuffLogicRemoveSkillIncreaseByDistance", BuffLogicBase)
BuffLogicRemoveSkillIncreaseByDistance = BuffLogicRemoveSkillIncreaseByDistance

function BuffLogicRemoveSkillIncreaseByDistance:Constructor(buffInstance, logicParam)
    self._entity = buffInstance:Entity()
end

function BuffLogicRemoveSkillIncreaseByDistance:DoLogic(data)
    if data == nil then
        return
    end
    local attacker = data:GetNotifyEntity()
    if self._entity ~= attacker then
        return
    end
    local notifyType = data:GetNotifyType()
    if notifyType == NotifyType.ChainSkillEachAttackEnd then --连锁技结束
        self._buffLogicService:RemoveSkillIncrease(
            self._entity,
            self:GetBuffSeq(),
            ModifySkillIncreaseParamType.ChainSkill
        )
    elseif notifyType == NotifyType.ActiveSkillEachAttackEnd then --主动技结束
        self._buffLogicService:RemoveSkillIncrease(
            self._entity,
            self:GetBuffSeq(),
            ModifySkillIncreaseParamType.ActiveSkill
        )
    elseif notifyType == NotifyType.MonsterEachAttackEnd then --怪物攻击后
        self._buffLogicService:RemoveSkillIncrease(
            self._entity,
            self:GetBuffSeq(),
            ModifySkillIncreaseParamType.MonsterDamage
        )
    end
end
