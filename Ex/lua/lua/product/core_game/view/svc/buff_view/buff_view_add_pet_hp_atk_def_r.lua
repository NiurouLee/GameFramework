--[[
    播放造成伤害的buff
]]
_class("BuffViewAddPetHpAtkDef", BuffViewBase)
---@class BuffViewAddPetHpAtkDef:BuffViewBase
BuffViewAddPetHpAtkDef = BuffViewAddPetHpAtkDef

function BuffViewAddPetHpAtkDef:PlayView(TT)
    ---@type BuffResultAddPetHpAtkDef
    local result = self:GetBuffResult()
    local pstId = self._entity:PetPstID():GetPstID()
    local hpAdded = result:GetAddHP()
    local atkAdded = result:GetAddAtk()
    local defAdded = result:GetAddDef()
    local damageInfo = result:GetDamageInfo()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangePetAtkDefHp, pstId, atkAdded, defAdded, hpAdded)

    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    playDamageSvc:UpdateTargetHPBar(TT, self._entity, damageInfo)

    ---@type BuffViewInstance
    local buffViewInstance = self:BuffViewInstance()
    ---@type BuffConfigData
    local buffConfigData = buffViewInstance:BuffConfigData()
    local viewParams = buffConfigData:GetViewParams()
    local isPassiveSkill = (viewParams.passiveSkill == 1)

    if isPassiveSkill then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, pstId, true)
    else
        ---@type Entity
        local entity = self._entity
        local materialAnimationComponent = entity:MaterialAnimationComponent()
        if materialAnimationComponent then
            if atkAdded > 0 then
                materialAnimationComponent:PlayAtkup()
            end

            if defAdded > 0 then
                materialAnimationComponent:PlayDefup()
            end
        end
    end
end

-- _class("BuffViewAddPetHpAtkDefUndo", BuffViewBase)
-- ---@class BuffViewAddPetHpAtkDefUndo:BuffViewBase
-- BuffViewAddPetHpAtkDefUndo = BuffViewAddPetHpAtkDefUndo

-- function BuffViewAddPetHpAtkDefUndo:PlayView(TT)
--     local pstId = self._entity:PetPstID():GetPstID()

--     local result = self._buffResult
--     local hpAdded = result.hpAdded * (-1)
--     local atkAdded = result.atkAdded * (-1)
--     local defAdded = result.defAdded * (-1)
--     local totalHp = result.totalHp - hpAdded
--     GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangePetAtkDefHp, pstId, atkAdded, defAdded, hpAdded)

--     ---@type BuffViewInstance
--     local buffViewInstance = self:BuffViewInstance()
--     ---@type BuffConfigData
--     local buffConfigData = buffViewInstance:BuffConfigData()
--     local viewParams = buffConfigData:GetViewParams()
--     local isPassiveSkill = (viewParams.passiveSkill == 1)

--     if isPassiveSkill then
--         GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, pstId, false)
--     end

--     self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
-- end
