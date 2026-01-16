--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    强制引导的时候没有复制一个要引导的按钮，放在UIGuideMessageBox里，
    是因为尝试复制的时候，有两大问题：
    1 UI里的图片等可能是动态加载进来的，复制的时刻，这些资源是否加载完不确定，表现出错。
    2 复制的UI元素上面可能有脚本，好比滚动列表里的元素都有UIDrag，UISelectItem脚本,这些脚本里有对父亲节点上其他UI元素的访问，这个时候父亲节点改成messageBox了，访问就会出错。
    所以最后强制引导时没有复制引导的元素，做了个中间镂空的遮罩来让引导的按钮可点击。
    这样做也有问题，比如滚动列表里的元素不禁止拖动的话，强制引导时还能拖拽，就会出问题。
    现在的解决办法时引导时静止了滚动列表的拖动。
    遇到其他问题时，需要考虑怎么解决。

    非强制引导时，引导UI贴着要引导的按钮，没上面这些问题。
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
--region新手引导UI，强制引导的时候使用
---@class UIGuideMessageBox:UIMessageBox
_class("UIGuideMessageBox", UIMessageBox)
UIGuideMessageBox = UIGuideMessageBox

function UIGuideMessageBox:Constructor()
    self.closeCallback = nil
    self.isShow = nil
end

function UIGuideMessageBox:OnShow()
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", "GuideLoader")
    local guideScript = pool:SpawnObject("UIGuide")
    ---@type UIGuide
    self.guideScript = guideScript
end

--region 重写
---@param params reward_icon reward_count callBack callbackParam
function UIGuideMessageBox:Alert(popup, params)
    Log.debug("UIGuideMessageBox:Alert")
    if self.isShow then
        GuideHelper.GuideLoadLock(false, "Button")
        return
    end
    self.isShow = true
    self.guideScript:Init(params[1])
    self.closeCallback = self:GetCallBack(popup)
end

function UIGuideMessageBox:ClearCallback()
    if self.isShow then
        self.isShow = false
        if self.closeCallback then
            self.closeCallback()
            self.closeCallback = nil
        end
        self.guideScript:RemoveClick()
    end
end
--endregion

function UIGuideMessageBox:CloseGuid()
    if self.closeCallback then
        self.closeCallback()
    end
end
function UIGuideMessageBox:GetCallBack(popup, btnCallback, param)
    return function()
        --Log.fatal("UIMessageBox:GetCallBack")
        if btnCallback then
            btnCallback(param)
        end
        self:SetShow(false)
        Log.debug("[UIPopup] UIMessageBox:GetCallBack request ClosePopup")
        GameGlobal.GuideMessageBoxMng():ClosePopup(popup)
    end
end
--endregion
