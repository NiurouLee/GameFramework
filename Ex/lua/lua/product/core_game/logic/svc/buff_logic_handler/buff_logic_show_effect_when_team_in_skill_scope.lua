--[[
    当队伍在技能范围内的时候显示特效
]]
_class("BuffLogicShowEffectWhenTeamInSkillScope", BuffLogicBase)
BuffLogicShowEffectWhenTeamInSkillScope = BuffLogicShowEffectWhenTeamInSkillScope

function BuffLogicShowEffectWhenTeamInSkillScope:Constructor(buffInstance, logicParam)
    self._effectID = logicParam.effectID
    self._skillID = logicParam.skillID
    self._buffID = logicParam.buffID
    self._buffEffect = logicParam.buffEffect
end

function BuffLogicShowEffectWhenTeamInSkillScope:DoLogic(notify)
    --不同notify传pos的方法都不一样
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posTeam = teamEntity:GridLocation().Position
    local curMovePos = posTeam
    if
        notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd
     then
        curMovePos = notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.Teleport then
        local entity = notify:GetNotifyEntity()
        if not entity:HasTeam() and not entity:HasPetPstID() then
            return
        end
        curMovePos = notify:GetPosNew()
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd then
        if notify:GetDefenderId() ~= teamEntity:GetID() then
            return
        end
        curMovePos = notify:GetPosEnd()
    elseif notify:GetNotifyType() == NotifyType.TransportEachMoveEnd then
        if notify:GetNotifyEntity():GetID() ~= teamEntity:GetID() then
            return
        end
        curMovePos = notify:GetPosNew()
    end

    --使用施法者机关的坐标计算技能范围
    local ownerEntity = self._buffInstance:Entity()
    local bodyArea = ownerEntity:BodyArea():GetArea()
    local posSelf = ownerEntity:GridLocation().Position
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(self._skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, posSelf, Vector2(0, 1), bodyArea)

    --判断范围是否包含notify的坐标
    local match = table.icontains(skillResult:GetAttackRange(), curMovePos)
    --将计算结果设置到result中
    local buffResult = BuffResultShowEffectWhenTeamInSkillScope:New(match, self._effectID)
    buffResult:SetMovePos(curMovePos)

    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")

    --添加删除buff
    if match then
        local buffInstance = buffSvc:AddBuff(self._buffID, teamEntity, {casterEntity = teamEntity})
        if buffInstance then
            buffResult:SetBuffSeq({buffInstance:BuffSeq()})
        end
    else
        ---@type BuffComponent
        local buffCmpt = teamEntity:BuffComponent()
        local tSeqID = buffCmpt:RemoveBuffByEffectType(self._buffEffect, NTBuffUnload:New())
        buffResult:SetBuffSeq(tSeqID)
    end

    buffResult:SetBuffID(self._buffID)

    return buffResult
end
