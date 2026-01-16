--游戏暂停
---@class UIBouncePause : UICustomWidget
_class("UIBouncePause", UICustomWidget)
UIBouncePause = UIBouncePause
--初始化
function UIBouncePause:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIBouncePause:InitWidget()
    --generated--
    --generated end--
end

--设置数据
function UIBouncePause:Init(exitCall, continueCall)
    self.exitCall = exitCall
    self.continueCall = continueCall
end

function UIBouncePause:Start()

end

--按钮点击
function UIBouncePause:ExitBtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
    if self.continueCall then
        self.continueCall()
    end
end

--按钮点击
function UIBouncePause:ContinueOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneInfo)
    if self.exitCall then
        self.exitCall()
    end
end
