--[[------------------------------------------------------------------------------------------
    WaveResultAwardSystem：波次奖励（小秘境）
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class WaveResultAwardSystem:MainStateSystem
_class("WaveResultAwardSystem", MainStateSystem)
WaveResultAwardSystem = WaveResultAwardSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function WaveResultAwardSystem:_GetMainStateID()
    return GameStateID.WaveResultAward
end

---@param TT token 协程识别码，服务端是nil
function WaveResultAwardSystem:_OnMainStateEnter(TT)
    local choosePartnerFun = nil
    local choosePartners = nil
    local choseRelics = nil

    --TODO_KZY
    --临时处理，关闭时回调进行顺序显示保证，需修改为关闭后发消息

    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    local openingChoose = talentSvc:NeedChooseOpeningRelic()
    if openingChoose then
        local groupID, count = talentSvc:GetChooseRelicParam()
        choseRelics = self:_DoLogicRandomRelic(groupID, count)
    else
        choosePartners = self:_DoLogicCalcChoosePartner()
        choseRelics = self:_DoLogicRandomRelic()
    end

    if choosePartners then
        choosePartnerFun = function(choosenRelicID) self:_DoRenderShowChoosePartner(TT, choosePartners, choosenRelicID) end
    end

    if choseRelics then
        self:_DoRenderShowChooseRelic(TT, choseRelics, choosePartnerFun, openingChoose)
    elseif choosePartnerFun then
        choosePartnerFun(0)
    else
    end
    --ChooseMiniMazeWaveAwardCommandHandler 中切状态
end

function WaveResultAwardSystem:_DoLogicCalcChoosePartner()
    ---@type PartnerServiceLogic
    local partnerService = self._world:GetService("PartnerLogic")
    return partnerService:_CalcChoosePartner()
end

function WaveResultAwardSystem:_DoLogicRandomRelic(groupID, count)
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    return battleSvc:CalcRandomRelic(groupID, count)
end

------------------------------------------------------------------------------------------

function WaveResultAwardSystem:_DoRenderShowChoosePartner(TT, choosePartners, choosenRelicID)
end

function WaveResultAwardSystem:_DoRenderShowChooseRelic(TT, chooseRelics, openingChoose)
end
