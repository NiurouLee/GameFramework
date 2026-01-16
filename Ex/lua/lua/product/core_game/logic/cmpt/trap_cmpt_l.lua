--[[------------------------------------------------------------------------------------------
    TrapComponent : 机关组件
]] --------------------------------------------------------------------------------------------

require("trap_destroy_type") -- 下面用到了这个枚举

_class("TrapComponent", Object)
---@class TrapComponent: Object
TrapComponent = TrapComponent

function TrapComponent:Constructor()
    self._trapType = TrapType.None
    self._trapEffectType = TrapEffectType.None
    self._trapEffectParam = nil
    self._raceType = TrapRaceType.Player
    self._raceParams = nil

    self._destroyType = TrapDestroyType.DestroyByRound
    self._destroyParam = nil
    self._trapID = 0
    self._orgDir = Vector2(0, 1)

    self._trapLevel = 0
    self._replaceLevel = 0

    self._needDestory = false

    ---机关死亡有两种情况
    ---一种是血量变为0，例如碎石，守护BOSS等，另一种是无血量死亡，例如炸弹，地刺等
    ---有血量的，需要判断Attribute里的HP属性；没有血量的，判断这个标记
    self._isNoHPDead = false

    self._triggerSkillID = 0 --触发执行的技能id
    self._appearSkillID = 0 --出场技能id
    self._disappearSkillID = 0 --离场技能id
    self._dieSkillID = 0 --死亡技能id
    self._victorySkillID = 0 --胜利技能id
    self._activeSkillID = {} --主动技能id
    self._preChainSkillID = 0 --连锁前触发技能id
    self._triggerSkillByRaceType = {} --根据目标类型识别的触发技能
    self._warningSkillID = 0 --预警技能ID
    self._moveSkillID = 0 --移动技能ID

    ---下面这一坨用来判断对应技能的类型，暂时只有祭剑座连线的时候判断是不是伤害触发型机关
    self._triggerSkillType = TrapSkillType.Normal --触发执行的技能类型
    self._appearSkillType = 0 --出场技能类型
    self._disappearSkillType = 0 --离场技能类型
    self._dieSkillType = 0 --死亡技能类型
    self._victorySkillType = 0 --胜利技能类型

    self._blockByRaceType = {} --根据目标类型识别的阻挡信息

    self._groupId = 0 --组ID，针对成对机关，如弩车和弩车触发器组ID一致，0表示不是组队机关

    ---@type TrapTriggerException[]
    self._triggerException = {} --触发例外
    self._triggerMaxCount = -1
    self._scopeCenterGroupId = 0 --大于0的机关身上会挂ScopeCenter组件
    self._isExit = false --是否为出口机关
    self._isDimensionDoor = false --是否为任意门
    self._isSuperGrid = false --是否强化格子
    self._isPoorGrid = false --是否弱化格子 这强化叫super，我实在是词穷了
    self._isBrokenGrid = false --是否碎格子
    self._isLockedGrid = false --是否锁格子
    self._isPrismGrid = false --是否棱镜格子
    self._isAircraftCore = false --是否风船核心
    self._isBenumbTrigger = false --是否麻痹弩车触发器
    self._isCastSkillByRound = false --是否自动战斗中按照回合释放主动技
    self._isPetTrapCastSkill = false --光灵召唤的机关是否在自动战斗中于光灵释放主动技之后释放技能
    self._isSticker = false --是否贴纸
    self._currentTriggerCount = 0
    self._fallWithGrid = false
    ---高能警告：只有炸弹使用的数据
    self._ownerID = nil ---炸弹拥有人ID
    self._ownerRound = nil ---绑定时的回合数
    self._hasSelected = false ---此炸弹是否被选过，连锁技使用，后续连锁技重构会去掉这个标记

    ---执行了死亡技能
    self._hadCalcDead = false
    self._hadCalcSkill = {}

    --净化格子逻辑：是否会被净化
    self._canBePurified = false

    self._recordPieceType = PieceType.None --创建机关以前的格子颜色

    self._specialDestroy = false --只有机关生命周期/特殊的删除机关技能  这2种可以删除自己.
    ---@type Entity
    self._triggerWhileSpawnEntity = nil --机关生成过程中的触发者 MSG45699

    self._bornRound = nil --出生时的回合数

    self._isBlockSummon = false --是否阻挡召唤，需要召唤的技能效果里配置阻挡召唤的机关类型参数

    --光环类机关相关
    self._auraGroupID = nil
    ---@type Vector2[]
    self._auraRange = nil
end

function TrapComponent:SetTrapID(trapID)
    self._trapID = trapID
end

function TrapComponent:GetTrapID()
    return self._trapID
end

function TrapComponent:SetTrapType(trapType)
    self._trapType = trapType
end

--region TypeParam
function TrapComponent:SetTypeParam(typeParam)
    if not typeParam then
        return
    end
    self._triggerException = typeParam["triggerException"] or {}
    self._triggerMaxCount = typeParam.triggerMaxCount or -1
    self._scopeCenterGroupId = typeParam.ScopeCenter or 0
    self._isExit = typeParam.isExit or false
    self._isDimensionDoor = typeParam.isDimensionDoor or false
    self._isSuperGrid = typeParam.isSuperGrid or false
    self._isPoorGrid = typeParam.isPoorGrid or false
    self._isAircraftCore = typeParam.isAircraftCore or false
    self._isBenumbTrigger = typeParam.isBenumbTrigger or false
    self._isBrokenGrid = typeParam.isBrokenGrid or false
    self._isLockedGrid = typeParam.isLockGrid or false
    self._isPrismGrid = typeParam.isPrismGrid or false
    self._prismScopeType = typeParam.prismScopeType or nil
    self._prismScopeParam = typeParam.prismScopeParam or {}
    self._isSticker = typeParam.isSticker or false
    self._isCastSkillByRound = typeParam.isCastSkillByRound or false
    self._isPetTrapCastSkill = typeParam.isPetTrapCastSkill or false
    self._isBlockSummon = typeParam.isBlockSummon or false
    self._auraGroupID = typeParam.groupID
    self._deadNotPlayDisappear = typeParam.deadNotPlayDisappear
    self._canStayBoardSplice = typeParam.canStayBoardSplice
end

function TrapComponent:GetTriggerException()
    return self._triggerException
end

function TrapComponent:GetTriggerMaxCount()
    return self._triggerMaxCount
end

function TrapComponent:GetScopeCenterGroupId()
    return self._scopeCenterGroupId
end

--endregion
function TrapComponent:FallWithGrid()
    return self._fallWithGrid
end

function TrapComponent:SetFallWithGrid(flag)
    self._fallWithGrid = flag
end

function TrapComponent:GetCurrentTriggerCount()
    return self._currentTriggerCount
end

function TrapComponent:SetCurrentTriggerCount(count)
    self._currentTriggerCount = count
end

function TrapComponent:AddCurrentTriggerCount()
    self:SetCurrentTriggerCount(self._currentTriggerCount + 1)
end

---@return TrapType
function TrapComponent:GetTrapType()
    return self._trapType
end

function TrapComponent:SetNeedDestory(bdestory)
    self._needDestory = bdestory
end

function TrapComponent:GetNeedDestory()
    return self._needDestory
end

function TrapComponent:SetOrgDir(trapRotation)
    self._orgDir = trapRotation
end

function TrapComponent:GetOrgDir()
    return self._orgDir
end

function TrapComponent:SetTrapLevel(trapLevel)
    self._trapLevel = trapLevel
end

function TrapComponent:GetTrapLevel()
    return self._trapLevel
end

function TrapComponent:SetReplaceLevel(replaceLevel)
    self._replaceLevel = replaceLevel
end

function TrapComponent:GetReplaceLevel()
    return self._replaceLevel
end

function TrapComponent:SetTrapEffect(trapEffectType, trapEffectParam)
    self._trapEffectType = trapEffectType or TrapEffectType.None
    self._trapEffectParam = trapEffectParam
end

function TrapComponent:GetTrapEffectType()
    return self._trapEffectType
end

function TrapComponent:IsRuneChange()
    return self._trapEffectType == TrapEffectType.RuneChange
end

function TrapComponent:IsExit()
    return self._isExit
end

function TrapComponent:IsDimensionDoor()
    return self._isDimensionDoor
end

function TrapComponent:IsAircraftCore()
    return self._isAircraftCore
end

function TrapComponent:IsBenumbTrigger()
    return self._isBenumbTrigger
end

function TrapComponent:IsCastSkillByRound()
    return self._isCastSkillByRound
end

function TrapComponent:IsPetTrapCastSkill()
    return self._isPetTrapCastSkill
end

function TrapComponent:GetTrapEffectParam()
    return self._trapEffectParam
end

function TrapComponent:SetTrapRaceType(raceType, raceParam)
    self._raceType = raceType
    self._raceParams = raceParam
end

function TrapComponent:GetTrapRaceType()
    return self._raceType
end

function TrapComponent:GetTrapRaceParam()
    return self._raceParams
end

function TrapComponent:GetTrapDestroyType()
    return self._destroyType
end

function TrapComponent:GetTrapDestroyParam()
    return self._destroyParam
end

local destroyParamTypeList = {
    TrapDestroyType.DestroyByRound,
    TrapDestroyType.DestoryByWave, --typo as-is
    TrapDestroyType.DestroyAtRoundResult
}

function TrapComponent:SetTrapDestroy(trapDestroyType, trapDestroyParam)
    self._destroyType = trapDestroyType
    if table.icontains(destroyParamTypeList, self._destroyType) then
        local num = 0
        if trapDestroyParam then
            num = tonumber(trapDestroyParam[1])
        end
        self._destroyParam = TrapSelfDestroyParam:New(num)
    end
end

function TrapComponent:GetTriggerSkillID()
    return self._triggerSkillID
end

function TrapComponent:GetAppearSkillID()
    return self._appearSkillID
end

function TrapComponent:GetDisappearSkillID()
    return self._disappearSkillID
end

function TrapComponent:GetWarningSkillID()
    return self._warningSkillID
end

function TrapComponent:GetMoveSkillID()
    return self._moveSkillID
end

function TrapComponent:GetDieSkillID()
    return self._dieSkillID
end

function TrapComponent:GetActiveSkillID()
    return self._activeSkillID
end

function TrapComponent:SetActiveSkillID(activeSkillID)
    self._activeSkillID = activeSkillID
end

function TrapComponent:GetPreChainSkillID()
    return self._preChainSkillID
end

function TrapComponent:GetVictorySkillID()
    return self._victorySkillID
end

function TrapComponent:GetTriggerSkillByRaceType()
    return self._triggerSkillByRaceType
end

---@param skillID table
function TrapComponent:SetSkillID(skillID)
    if not skillID then
        return
    end
    self._triggerSkillID = skillID["Trigger"] or 0
    self._appearSkillID = skillID["Appear"] or 0
    self._disappearSkillID = skillID["Disappear"] or 0
    self._dieSkillID = skillID["Die"] or 0
    --self._activeSkillID = skillID["Active"] or {}
    self._activeSkillID = {}
    if type(skillID["Active"]) == "table" then
        table.appendArray(self._activeSkillID, skillID["Active"])
    end
    self._preChainSkillID = skillID["PreChain"] or 0
    self._victorySkillID = skillID["Victory"] or 0

    self._warningSkillID = skillID["Warning"] or 0
    self._moveSkillID = skillID["Move"] or 0
end

function TrapComponent:GetTriggerSkillType()
    return self._triggerSkillType
end

---@param skillID table
function TrapComponent:SetSkillType(skillID)
    if not skillID then
        return
    end
    self._triggerSkillType = skillID["Trigger"] or 0
    self._appearSkillType = skillID["Appear"] or 0
    self._disappearSkillType = skillID["Disappear"] or 0
    self._dieSkillType = skillID["Die"] or 0
    self._activeSkillType = skillID["Active"] or {}
    self._preChainSkillType = skillID["PreChain"] or 0
    self._victorySkillType = skillID["Victory"] or 0
end

function TrapComponent:SetTriggerByRace(triggerByRace)
    self._triggerSkillByRaceType = triggerByRace
end

function TrapComponent:GetBlockByRaceType()
    return self._blockByRaceType
end

function TrapComponent:SetBlockByRaceType(blockByRaceType)
    self._blockByRaceType = blockByRaceType
end

function TrapComponent:SetGroupID(groupId)
    self._groupId = groupId or 0
end

function TrapComponent:GetGroupID()
    return self._groupId
end

function TrapComponent:SetGroupTriggerTrapID(trapID)
    self._groupTriggerTrapID = trapID
end

function TrapComponent:GetGroupTriggerTrapID()
    return self._groupTriggerTrapID
end

---所有人ID
function TrapComponent:GetOwnerID()
    return self._ownerID
end

---判断是否弹有所属 nOwnerID暂时没有使用
function TrapComponent:IsTrapHaveOwner(nOwnerRound)
    if nil == self._ownerRound or self._ownerRound < nOwnerRound then
        return false
    end
    return self._ownerID
end

function TrapComponent:SetOwner(nOwnerID, nOwnerRound)
    self._ownerID = nOwnerID
    self._ownerRound = nOwnerRound
end

function TrapComponent:SetBombSelected(selected)
    self._hasSelected = selected
end

function TrapComponent:IsBombSelected()
    return self._hasSelected
end

function TrapComponent:SetReplaceTrap(replaceTrap)
    self._replaceTrap = replaceTrap
end

function TrapComponent:GetReplaceTrap()
    return self._replaceTrap
end

---@return boolean
function TrapComponent:IsHadCalcDead()
    return self._hadCalcDead
end

function TrapComponent:SetHadCalcDead()
    self._hadCalcDead = true
end

function TrapComponent:IsSuperGrid()
    return self._isSuperGrid
end

function TrapComponent:IsPoorGrid()
    return self._isPoorGrid
end

function TrapComponent:IsBrokenGrid()
    return self._isBrokenGrid
end

function TrapComponent:IsLockedGrid()
    return self._isLockedGrid
end

function TrapComponent:IsPrismGrid()
    return self._isPrismGrid
end

function TrapComponent:GetCustomPrismGridScopeType()
    return self._prismScopeType
end

function TrapComponent:GetCustomPrismGridScopeParam()
    return self._prismScopeParam
end

function TrapComponent:IsSticker()
    return self._isSticker
end

function TrapComponent:SetHadCalcSkill(skillID)
    table.insert(self._hadCalcSkill, skillID)
end

function TrapComponent:IsSkillHadCalc(skillID)
    if not skillID then
        return false
    end
    return table.icontains(self._hadCalcSkill, skillID)
end

function TrapComponent:SetCanBePurified(b)
    self._canBePurified = b
end

function TrapComponent:CanBePurified()
    return self._canBePurified
end

function TrapComponent:SetRecordPieceType(pieceType)
    self._recordPieceType = pieceType
end

function TrapComponent:GetRecordPieceType()
    return self._recordPieceType
end

function TrapComponent:SetSpecialDestroy(specialestroy)
    self._specialDestroy = specialestroy
end

---只有机关生命周期/特殊的删除机关技能  这2种可以删除自己.
function TrapComponent:GetSpecialDestroy()
    return self._specialDestroy
end

---@param e Entity
function TrapComponent:SetTriggerWhileSpawnEntity(e)
    self._triggerWhileSpawnEntity = e
end

function TrapComponent:GetTriggerWhileSpawnEntity()
    return self._triggerWhileSpawnEntity
end

function TrapComponent:SetTrapBornRound(round)
    self._bornRound = round
end

function TrapComponent:GetTrapBornRound()
    return self._bornRound
end

function TrapComponent:IsBlockSummon()
    return self._isBlockSummon
end

function TrapComponent:GetAuraGroupID()
    return self._auraGroupID
end

function TrapComponent:GetDeadNotPlayDisappear()
    return self._deadNotPlayDisappear
end

function TrapComponent:GetCanStayBoardSplice()
    return self._canStayBoardSplice
end

---@param auraRange Vector2[]
function TrapComponent:SetAuraRange(auraRange)
    self._auraRange = auraRange
end

---@return Vector2[]
function TrapComponent:GetAuraRange()
    return self._auraRange
end

function TrapComponent:SetCantAutoSkill(cantAutoSkill)
    self._cantAutoSkill = cantAutoSkill
end

function TrapComponent:GetCantAutoSkill()
    return self._cantAutoSkill
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return TrapComponent
function Entity:Trap()
    return self:GetComponent(self.WEComponentsEnum.Trap)
end

function Entity:HasTrap()
    return self:HasComponent(self.WEComponentsEnum.Trap)
end

function Entity:AddTrap()
    local index = self.WEComponentsEnum.Trap
    local component = TrapComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceTrap()
    local index = self.WEComponentsEnum.Trap
    local component = TrapComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveTrap()
    if self:HasTrap() then
        self:RemoveComponent(self.WEComponentsEnum.Trap)
    end
end
