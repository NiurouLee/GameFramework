--[[------------------------------------------------------------------------------------------
    DataMonsterCreationResult : 单个怪物创建的结果，用于逻辑传递给表现使用
]] --------------------------------------------------------------------------------------------

_class("DataMonsterCreationResult", Object)
---@class DataMonsterCreationResult: Object
DataMonsterCreationResult = DataMonsterCreationResult

function DataMonsterCreationResult:Constructor()
    self._templateID = -1 ---怪物配置的模板ID
    self._resPath = nil ---资源路径

    self._curHp = -1 ---当前血量
    self._maxHp = -1 ---最大血量
    self._hpOffset = nil ---血条偏移
    self._isBoss = false ---是不是BOSS
    self._elementType = ElementType.ElementType_None ---元素类型

    self._lockHpList = nil ---锁血需要

    self._isChangeModelWithPetIndex = false

    self._appearSkillID = -1

    ---@type GridLocationResult
    self._gridLocRes = nil
end
----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterTemplateID()
    return self._templateID
end

function DataMonsterCreationResult:SetMonsterTemplateID(id)
    self._templateID = id
end
----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterResPath()
    return self._resPath
end

function DataMonsterCreationResult:SetMonsterResPath(path)
    self._resPath = path
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterHP()
    return self._curHp
end

function DataMonsterCreationResult:SetMonsterHP(hp)
    self._curHp = hp
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterMaxHP()
    return self._maxHp
end

function DataMonsterCreationResult:SetMonsterMaxHP(hp)
    self._maxHp = hp
end
----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterHPOffset()
    return self._hpOffset
end

function DataMonsterCreationResult:SetMonsterHPOffset(offset)
    self._hpOffset = offset
end
----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterIsBoss()
    return self._isBoss
end

function DataMonsterCreationResult:SetMonsterIsBoss(isBoss)
    self._isBoss = isBoss
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterElement()
    return self._elementType
end

function DataMonsterCreationResult:SetMonsterElement(element)
    self._elementType = element
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterLockHPList()
    return self._lockHpList
end

function DataMonsterCreationResult:SetMonsterLockHPList(list)
    self._lockHpList = list
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterChangeModelWithPetIndex()
    return self._isChangeModelWithPetIndex
end

function DataMonsterCreationResult:SetMonsterChangeModelWithPetIndex(index)
    self._isChangeModelWithPetIndex = index
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterAppearSkillID()
    return self._appearSkillID
end

function DataMonsterCreationResult:SetMonsterAppearSkillID(skillID)
    self._appearSkillID = skillID
end

----------------------------------------------------------------
function DataMonsterCreationResult:GetMonsterGridLocResult()
    return self._gridLocRes
end

function DataMonsterCreationResult:SetMonsterGridLocResult(res)
    self._gridLocRes = res
end
