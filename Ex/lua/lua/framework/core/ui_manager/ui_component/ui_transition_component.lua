---@class UITransitionComponent:UIComponent
_class( "UITransitionComponent", UIComponent )


function UITransitionComponent:Constructor()
    ---@type SortedArray
    self.enterAnims = nil
    ---@type SortedArray
    self.leaveAnims = nil
end

function UITransitionComponent:AfterShow(TT)
    self:PlayEnterAnim(TT)
end
function UITransitionComponent:BeforeHide(TT)
    if not self.uiController.SkipTransitionAmin then
        self:PlayLeaveAnim(TT)
    end
end

---@private
function UITransitionComponent:PlayEnterAnim(TT)
    if not self.enterAnims then
        self.enterAnims = SortedArray:New(Algorithm.COMPARE_CUSTOM, function(anim1, anim2)
            if anim1.EnterTime > anim2.EnterTime then
                return -1
            elseif anim1.EnterTime == anim2.EnterTime then
                return 0
            else
                return 1
            end
        end)

        local resCmps = UIHelper.GetAllTransitionComponents(self.uiController:GetGameObject())
        if resCmps then
            for i = 1, resCmps.Length do
                self.enterAnims:Insert(resCmps[i - 1])
            end
        end
    end

    for i = 1, self.enterAnims:Size() do
        self.enterAnims:GetAt(i):PlayEnterAnimation(true)
    end

    local enterTime = 0
    if self.enterAnims:Size() > 0 then
        enterTime = self.enterAnims:GetAt(1).EnterTime
    end
    YIELD(TT, enterTime)
end
---@private
function UITransitionComponent:PlayLeaveAnim(TT)
    if not self.leaveAnims then
        self.leaveAnims = SortedArray:New(Algorithm.COMPARE_CUSTOM, function(anim1, anim2)
            if anim1.RestTime > anim2.RestTime then
                return -1
            elseif anim1.RestTime == anim2.RestTime then
                return 0
            else
                return 1
            end
        end)

        local resCmps = UIHelper.GetAllTransitionComponents(self.uiController:GetGameObject())
        if resCmps then
            for i = 1, resCmps.Length do
                self.leaveAnims:Insert(resCmps[i - 1])
            end
        end
    end

    for i = 1, self.leaveAnims:Size() do
        self.leaveAnims:GetAt(i):PlayLeaveAnimation(true)
    end

    local restTime = 0
    if self.leaveAnims:Size() > 0 then
        restTime = self.leaveAnims:GetAt(1).RestTime
    end

    for i = 1, self.leaveAnims:Size() do
        ---@type UnityEngine.Animation
        local anim = self.leaveAnims:GetAt(i).gameObject:GetComponent("Animation")
        anim.enabled = true
        anim:get_Item(anim.clip.name).time = self.leaveAnims:GetAt(i).EnterTime/1000--self.curTime--(30/ anim.clip.frameRate)--self.leaveAnims:GetAt(i).m_EndFrameOfAnimIn
    end

    YIELD(TT, restTime)

    --[[
    C#代码等一帧，才开始播放离开动画
    //这两个变量是为了绕开unity的一个bug：当激活一个失效的animation和play该animation在同一帧时，对animation的设置是失效的
    bool m_IsPlayingAnimOut = false;
    bool m_HadPlayedAnimOut = false;
    if (!m_IsPlayingAnimOut)
    {//等一帧
        m_IsPlayingAnimOut = true;
        return;
    }
    ]]--
    if restTime > 0 then
        YIELD(TT)
    end
end