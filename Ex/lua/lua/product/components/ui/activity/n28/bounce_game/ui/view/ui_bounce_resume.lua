--游戏恢复倒计时
---@class UIBounceResume : UICustomWidget
_class("UIBounceResume", UICustomWidget)
UIBounceResume = UIBounceResume
--初始化
function UIBounceResume:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIBounceResume:InitWidget()
    --generated--
    self._atlas = self:GetAsset("UIN28MinigameIn.spriteatlas", LoadType.SpriteAtlas) 
    self._txt = self:GetUIComponent("Image", "txt")
    --generated end--
end

--设置数据
---@param finishCall function 倒计时完成回调 
function UIBounceResume:Init(finishCall)
    self._finishCall = finishCall
end

function UIBounceResume:Start()
    self:StartTask(self.StartAni,self)
end

function UIBounceResume:StartAni(TT)
    self:Lock("UIBounceResume:StartAni")
    for i = 3, 1, -1 do 
        self._txt.sprite = self._atlas:GetSprite("N28_yrj_jngq_countdown0"..i)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneCounter)
        YIELD(TT,1000)
    end 
    YIELD(TT,500)
    self:UnLock("UIBounceResume:StartAni")
    if self._finishCall then 
        self._finishCall()
    end 
end

--取消倒计时，不回调
function UIBounceResume:Cancel()
    
end
