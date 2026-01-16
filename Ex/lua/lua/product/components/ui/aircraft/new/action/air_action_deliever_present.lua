--[[
    星靈送出禮物，禮包爆開，聊天，展示物品
]]
---@class DelieverStatus
local DelieverStatus = {
    None = 0,
    Starting = 1,
    Talking = 2,
    Bursting = 3,
    ShowAsset = 4,
    End = 5
}
_enum("DelieverStatus", DelieverStatus)

---@class AirActionDelieverPresent:AirActionBase
_class("AirActionDelieverPresent", AirActionBase)
AirActionDelieverPresent = AirActionDelieverPresent

---@param pet AircraftPet
function AirActionDelieverPresent:Constructor(pet, assetList, main)
    self._pet = pet
    self.delieverStatus_ = DelieverStatus.None
    self.assetList_ = assetList
    ---@type AircraftMain
    self.main_ = main
end
function AirActionDelieverPresent:Start()
    self.delieverStatus_ = DelieverStatus.Starting
    self._running = true
    self._pet:SetState(AirPetState.SendingGift)
    self._timer = 0
    self._waitTime = 2000
    --锁屏
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "AircraftSendGift")
end
function AirActionDelieverPresent:IsOver()
    return not self._running
end
function AirActionDelieverPresent:Update(deltaTimeMS)
    if self.delieverStatus_ == DelieverStatus.Starting then
        local pet_cfg = Cfg.cfg_aircraft_pet[self._pet:TemplateID()]
        local group = pet_cfg.ClickActionLib

        local giftTag
        if self._pet:IsGiftPet() then
            giftTag = AircraftPetGiftTag.Gift
        elseif self._pet:IsVisitPet() then
            giftTag = AircraftPetGiftTag.Visit
        else
            Log.exception("送礼星灵状态错误:", self._pet:TemplateID())
        end
        local cfgs = Cfg.cfg_aircraft_click_action_lib {Group = group, GiftTag = giftTag}
        if cfgs == nil or #cfgs == 0 then
            Log.exception("找不到送礼文本气泡，group:", group, "，Tag:", giftTag)
        end
        local sentence = cfgs[1].Sentence
        if not sentence then
            Log.exception("送礼文本气泡配置错误，group:", group, "，Tag:", giftTag)
        end

        local skinList = cfgs[1].SkinID
        local currSkinID = self._pet:ClothSkinID()
        local _playIdx = 0
        if skinList then
            for i = 1, #skinList do
                local skinid = skinList[i]
                if skinid == currSkinID then
                    _playIdx = i
                    break
                end
            end
        end
        local playIdx = _playIdx + 1
        local sentenceTex = sentence[playIdx]

        --根据策划口头协定，星灵送礼只有文字气泡，不会有语音 2021.4.7 靳策
        ---@type AirActionSentence
        local DelieverPresentSentenceAction = AirActionSentence:New(self._pet, sentenceTex, self.main_, nil)
        self._pet:StartSentenceAction(DelieverPresentSentenceAction)
        --开始冒文字气泡，播语音
        self.delieverStatus_ = DelieverStatus.Talking
        return
    end

    if self.delieverStatus_ == DelieverStatus.Talking then
        self._timer = self._timer + deltaTimeMS
        if self._timer > self._waitTime then
            --播完气泡，礼包爆开
            self.delieverStatus_ = DelieverStatus.Bursting
            self:DoBurstAnimation()
            return
        end
    end
    if self.delieverStatus_ == DelieverStatus.Bursting then
        if not self:DoingBurstAnimation() then
            --在这里解锁屏幕，因为获得物品弹窗需要点击空白关闭
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "AircraftSendGift")
            self.delieverStatus_ = DelieverStatus.ShowAsset
            if self.assetList_ and table.count(self.assetList_) > 0 then
                GameGlobal.UIStateManager():ShowDialog(
                    "UIGetItemController",
                    self.assetList_,
                    function()
                        self.delieverStatus_ = DelieverStatus.End
                        self:Stop()
                    end
                )
            end
        end
    end
end
function AirActionDelieverPresent:Stop()
    self._running = false
    self._pet:StopSpecialAction(AircraftSpecialActionType.PresentBag)
    if self._pet:IsGiftPet() then
        --送礼星灵送完礼之后清除标记
        self._pet:SetGiftFlag(nil)
    elseif self._pet:HasVisitGift() then
        self._pet:SetVisitGift(nil)
    end
    --工作星灵执行1个行为，非工作星灵不需要执行，行为结束后会自动随机1个
    if self._pet:IsWorkingPet() then
        --走回工作室
        AirLog("送礼星灵走回工作房间：", self._pet:TemplateID(), "，空间id：", self._pet:GetSpace())
        local action = AirActionMoveToWork:New(self.main_, self._pet)
        self._pet:StartMainAction(action)
    end
    --刷新导航栏星灵数量
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshNavMenuData)
end
function AirActionDelieverPresent:Dispose()
    self._pet = nil
    self.delieverStatus_ = DelieverStatus.End
    self.assetList_ = nil
end

function AirActionDelieverPresent:DoBurstAnimation()
    local obj = self._pet:GetPresentObject()
    local lizi = obj.transform:Find("lizi").gameObject
    lizi:SetActive(true)
    self.animation_ = obj:GetComponent("Animation")
    self.animation_:Play("eff_meme_baokai")
end

function AirActionDelieverPresent:DoingBurstAnimation()
    return self.animation_:IsPlaying("eff_meme_baokai")
end
