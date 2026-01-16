--拍电影准备阶段主界面
---@class UIHomelandMovieActionController : UIController
_class("UIHomelandMovieActionController", UIController)
UIHomelandMovieActionController = UIHomelandMovieActionController

--构造
function UIHomelandMovieActionController:Constructor()

end

--初始化
function UIHomelandMovieActionController:OnShow(uiParams)
    self:InitWidget()

    self._ActionRoot = self:GetGameObject("ActionRoot")
end

function UIHomelandMovieActionController:OnHide()  
end

--获取ui组件
function UIHomelandMovieActionController:InitWidget()
    
end

--返回按钮点击
function UIHomelandMovieActionController:BackBtnOnClick(go)
    self:CloseDialog()
end
--返回按钮点击
function UIHomelandMovieActionController:ActionOnClick(go)
    --MovieDataManager:GetInstance():SendDataToServer()
    self:Lock("UIHomelandMovieActionController_ActionOnClick")
    self._ActionRoot.transform:DOScale(Vector3(0.8, 0.8, 0.8),0.1)
    GameGlobal.Timer():AddEvent(
        200,
        function()
            self._ActionRoot.transform:DOScale(Vector3(1, 1, 1), 0.1)
        end
    )
    GameGlobal.Timer():AddEvent(
        400,
        function()
            self:UnLock("UIHomelandMovieActionController_ActionOnClick")
            self:CloseDialog()
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1Click)
            GameGlobal.TaskManager():StartTask(function (TT)
                GameGlobal.GetModule(HomelandModule):GetUIModule():EnterMovieMaker(TT)
            end)
        end
    )
end


