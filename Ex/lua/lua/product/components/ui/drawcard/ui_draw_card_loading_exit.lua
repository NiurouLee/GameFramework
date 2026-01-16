---@class UIDrawCardLoadingExit:LoadingHandler
_class("UIDrawCardLoadingExit", LoadingHandler)
UIDrawCardLoadingExit = UIDrawCardLoadingExit

function UIDrawCardLoadingExit:PreLoadAfterLoadLevel(TT, ...)
    --释放音效
    ---@type AudioManager
    --local audio = AudioManager.Instance

    -- AudioHelperController.ReleaseUISoundList(
    --     {
    --         CriAudioIDConst.DrawCard_chendi,
    --         CriAudioIDConst.DrawCard_chengse,
    --         CriAudioIDConst.DrawCard_danka,
    --         CriAudioIDConst.DrawCard_daodi,
    --         CriAudioIDConst.DrawCard_lagan,
    --         CriAudioIDConst.DrawCard_lanse,
    --         CriAudioIDConst.DrawCard_shilian,
    --         CriAudioIDConst.DrawCard_tanhui,
    --         CriAudioIDConst.DrawCard_zise,
    --         CriAudioIDConst.DrawCard_tuijingtou,
    --         CriAudioIDConst.DrawCard_guangqiu,
    --         CriAudioIDConst.DrawCard_preshilian
    --     }
    -- )

    AudioHelperController.ReleaseUISoundList(
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

function UIDrawCardLoadingExit:OnLoadingFinish(...)
    ---@type GambleModule
    local module = GameGlobal.GetModule(GambleModule)
    module:ClearContext()
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
end

function UIDrawCardLoadingExit:LoadingType()
    return LoadingType.BOTTOM
end
