--[[
    风船跳转到抽卡
]]
---@class AircraftToDrawcardLoading:LoadingHandler
_class("AircraftToDrawcardLoading", LoadingHandler)
AircraftToDrawcardLoading = AircraftToDrawcardLoading

function AircraftToDrawcardLoading:PreLoadBeforeLoadLevel(TT)
    --正常的风船析构逻辑，在销毁场景前
    ---@type AircraftModule
    local module = GameGlobal.GetModule(AircraftModule)
    ---@type AircraftMain
    local main = module:GetClientMain()
    main:Dispose()
    module:SetClientMain(nil)
    --通知服务器离开风船
    module:PushLeaveAircraft()

    AudioHelperController.RequestUISoundList(
        {
            CriAudioIDConst.DrawCard_tuijingtou,
            CriAudioIDConst.DrawCard_lagan_new,
            CriAudioIDConst.Drawcard_lagan_eft_3,
            CriAudioIDConst.Drawcard_lagan_eft_4,
            CriAudioIDConst.Drawcard_lagan_eft_5,
            CriAudioIDConst.Drawcard_lagan_eft_6,
            CriAudioIDConst.Drawcard_light_one,
            CriAudioIDConst.Drawcard_light_more,
            CriAudioIDConst.Drawcard_light_one,
            CriAudioIDConst.Drawcard_mul_show,
            CriAudioIDConst.Drawcard_lagan_once
        }
    )
end

function AircraftToDrawcardLoading:PreLoadAfterLoadLevel(TT, ...)
    LoadingHandler.PreLoadAfterLoadLevel(self, TT, ...)
end

function AircraftToDrawcardLoading:OnLoadingFinish(...)
    ---@type GambleModule
    local module = GameGlobal.GetModule(GambleModule)
    module:InitContext(self.sceneResReq)
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIDrawCard, ...)
end

function AircraftToDrawcardLoading:LoadingType()
    return LoadingType.STATICPIC
end
