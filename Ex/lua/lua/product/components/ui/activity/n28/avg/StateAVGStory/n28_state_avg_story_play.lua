---@class N28StateAVGStoryPlay : N28StateAVGStoryBase
_class("N28StateAVGStoryPlay", N28StateAVGStoryBase)
N28StateAVGStoryPlay = N28StateAVGStoryPlay

function N28StateAVGStoryPlay:OnEnter(TT, ...)
    --self.hideJumpBtn = table.unpack({...})
    self:ShowHideJumpBtn(true)
    self:Init()
end

function N28StateAVGStoryPlay:OnExit(TT)
end

function N28StateAVGStoryPlay:OnUpdate(deltaTimeMS)
    self:UpdateDriveByState(deltaTimeMS)
end
