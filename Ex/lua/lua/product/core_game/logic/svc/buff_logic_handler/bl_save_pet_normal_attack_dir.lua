BuffLogicSaveNormalAttackDirEnum = {
    Up = 1, ---
    RightTop = 2, ---
    Right = 3, ---
    RightBottom = 4, ---
    Down = 5, ---
    LeftBottom = 6, ---
    Left = 7, ---
    LeftTop = 8, ---
}
_enum("BuffLogicSaveNormalAttackDirEnum", BuffLogicSaveNormalAttackDirEnum)

require('buff_logic_base')

_class("BuffLogicSaveNormalAttackDir", BuffLogicBase)
---@class BuffLogicSaveNormalAttackDir:BuffLogicBase
BuffLogicSaveNormalAttackDir = BuffLogicSaveNormalAttackDir

---@param notify NTNormalAttackChangeBefore
function BuffLogicSaveNormalAttackDir:DoLogic(notify)
    if not self._entity:HasPetPstID() then
        return
    end

    local cPetPstID = self._entity:PetPstID()

    local curRound = self._world:BattleStat():GetGameRoundCount()

    local attackPos = notify:GetAttackPos()
    local damagePos = notify:GetTargetPos()
    local dir = damagePos - attackPos
    local dirNum = 0
    if dir.x == 0 and dir.y > 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Up
    elseif dir.x > 0 and dir.y > 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.RightTop
    elseif dir.x > 0 and dir.y == 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Right
    elseif dir.x > 0 and dir.y < 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.RightBottom
    elseif dir.x == 0 and dir.y < 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Down
    elseif dir.x < 0 and dir.y < 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.LeftBottom
    elseif dir.x < 0 and dir.y == 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Left
    elseif dir.x < 0 and dir.y > 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.LeftTop
    end
    cPetPstID:SetRoundNormalAttackDir(curRound, dirNum)

    local dirTable = cPetPstID:GetRoundNormalAttackDirTable(curRound)
    local result = BuffResultSavePetNormalAttackDir:New(dirTable, dir, dirNum)
    result.__notify_entity = notify:GetNotifyEntity()
    result.__notify_attackPos = notify:GetAttackPos()
    result.__notify_beAttackPos = notify:GetTargetPos()
    return result
end

_class("BuffLogicClearPetNormalAttackDirInCurrentRound", BuffLogicBase)
---@class BuffLogicClearPetNormalAttackDirInCurrentRound:BuffLogicBase
BuffLogicClearPetNormalAttackDirInCurrentRound = BuffLogicClearPetNormalAttackDirInCurrentRound

---@param notify NTNormalAttackChangeBefore
function BuffLogicClearPetNormalAttackDirInCurrentRound:DoLogic(notify)
    if not self._entity:HasPetPstID() then
        return
    end

    local cPetPstID = self._entity:PetPstID()

    local curRound = self._world:BattleStat():GetGameRoundCount()
    cPetPstID:ClearRoundNormalAttackDir(curRound)

    --local dirTable = cPetPstID:GetRoundNormalAttackDirTable(curRound)
    return BuffResultClearPetNormalAttackDir:New()
end