_class("TTRoundFirstActiveSkill", TriggerBase)
---@class TTRoundFirstActiveSkill : TriggerBase
TTRoundFirstActiveSkill = TTRoundFirstActiveSkill

---@param notify NTActiveSkillAttackStart
function TTRoundFirstActiveSkill:IsSatisfied(notify)
    ---@type  Entity
    local attacker = notify:GetAttackerEntity()
    local petPstID =attacker:PetPstID():GetPstID()
    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local curRound = battleStatComponent:GetLevelTotalRoundCount()
    local curRoundRecord = battleStatComponent:GetPetDoActiveSkillRecord(petPstID,curRound)
    ---这个数据在主动技释放前的通知发送前就保存了。
    if not curRoundRecord or #curRoundRecord ==1 then
        return true
    end
    return false
end


_class("TTPetSex", TriggerBase)
---@class TTPetSex : TriggerBase
TTPetSex = TTPetSex
function TTPetSex:IsSatisfied()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local petSexType = battleSvc:GetPetSexType(self._owner)
    return self._x ==petSexType
end

_class("TTPetSexUpAndDown", TriggerBase)
---@class TTPetSexUpAndDown : TriggerBase
TTPetSexUpAndDown = TTPetSexUpAndDown


function TTPetSexUpAndDown:IsSatisfied(notify)
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local ownerPetPstID =self._owner:PetPstID():GetPstID()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type TeamComponent
    local teamCmpt = teamEntity:Team()
    ---@type table<number,number>
    local teamOrder = teamCmpt:GetTeamOrder()
    ---队伍不到三个人，或者自己是队长或者自己是队尾
    if #teamOrder<3 or
    ownerPetPstID ==teamOrder[1] or ownerPetPstID== teamOrder[#teamOrder]
         then
        return false;
    end
    local ownerIndex = teamCmpt:GetTeamIndexByPetPstID(ownerPetPstID)
    ---@type Entity
    local upPet =teamCmpt:GetPetEntityByTeamIndex(ownerIndex-1)
    ---@type Entity
    local downPet =teamCmpt:GetPetEntityByTeamIndex(ownerIndex+1)
    return battleSvc:GetPetSexType(upPet) ==self._x and battleSvc:GetPetSexType(downPet) ==self._x
end

_class("TTAllMonsterHaveCampType", TriggerBase)
---@class TTAllMonsterHaveCampType : TriggerBase
TTAllMonsterHaveCampType = TTAllMonsterHaveCampType
function TTAllMonsterHaveCampType:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local onwerID = owner:GetID()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    ---@type Entity[]
    local MonsterEntityArray = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    local liveCount = 0
    for k, entity in ipairs(MonsterEntityArray) do
        if not entity:HasDeadMark() and entity:GetID()~= onwerID then
            if table.icontains(self._param,entity:MonsterID():GetCampType()) then
                return true
            end
        end
    end
    return false
end


_class("TTAllMonsterNotHaveCampType", TriggerBase)
---@class TTAllMonsterNotHaveCampType : TriggerBase
TTAllMonsterNotHaveCampType = TTAllMonsterNotHaveCampType
function TTAllMonsterNotHaveCampType:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local onwerID = owner:GetID()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    ---@type Entity[]
    local MonsterEntityArray = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    local liveCount = 0
    for k, entity in ipairs(MonsterEntityArray) do
        if not entity:HasDeadMark() and entity:GetID()~= onwerID then
            if table.icontains(self._param,entity:MonsterID():GetCampType()) then
                return false
            end
        end
    end
    return true
end


_class("TTCheckConvertGridSkillType", TriggerBase)
---@class TTCheckConvertGridSkillType : TriggerBase
TTCheckConvertGridSkillType = TTCheckConvertGridSkillType
---@param notify NTGridConvert
function TTCheckConvertGridSkillType:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.GridConvert then
        return false
    end
    if not notify:GetSkillType() or notify:GetSkillType()==nil  then
        return false
    end
    return table.icontains(self._param, notify:GetSkillType())
end


_class("TTCheckConvertGridHasGridType", TriggerBase)
---@class TTCheckConvertGridHasGridType : TriggerBase
TTCheckConvertGridHasGridType = TTCheckConvertGridHasGridType
---@param notify NTGridConvert
function TTCheckConvertGridHasGridType:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.GridConvert then
        return false
    end
    ---@type NTGridConvert_ConvertInfo[]
    local convertInfoList = notify:GetConvertInfoArray()
    ---@param v NTGridConvert_ConvertInfo
    for i, v in ipairs(convertInfoList) do
        local pieceType = v:GetAfterPieceType()
        if table.icontains(self._param, pieceType) then
            return true
        end
    end
    return false
end

--通知目标是自己
_class("TTNotifyMeOrSuperMe", TriggerBase)
---@class TTNotifyMeOrSuperMe:TriggerBase
TTNotifyMeOrSuperMe = TTNotifyMeOrSuperMe

---@param notify INotifyBase
function TTNotifyMeOrSuperMe:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    if entity:HasSuperEntity() then
        local super = entity:GetSuperEntity()
        return super:GetID() == owner:GetID()
    else
        return owner:GetID() == entity:GetID()
    end
end