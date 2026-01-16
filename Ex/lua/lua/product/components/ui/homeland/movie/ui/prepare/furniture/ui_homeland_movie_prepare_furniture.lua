--自由摆放阶段
---@class UIHomelandMoviePrepareFurniture : UIHomelandMoviePrepareBase
_class("UIHomelandMoviePrepareFurniture", UIHomelandMoviePrepareBase)
UIHomelandMoviePrepareFurniture = UIHomelandMoviePrepareFurniture

function UIHomelandMoviePrepareFurniture:OnShow()
    ---@type UICustomWidgetPool
    local freeStagePool = self:GetUIComponent("UISelectObjectPath", "editList")
    local camera = GameGlobal.UIStateManager():GetControllerCamera("UIHomelandMoviePrepareMainController")
    ---@type UIHomelandBuildEditList
    self.editList = freeStagePool:SpawnObject("UIHomelandBuildEditList")
    self.editList:Init(camera, BuildEditListType.BT_MakeMovie)

    self.fatherBuilding = MoviePrepareData:GetInstance():GetFatherBuild()
    self.mUIHomeland = GameGlobal.GetModule(HomelandModule):GetUIModule()
end

--进入
---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareFurniture:OnEnter(prepareType)
    self:Refresh(prepareType)
    self.mUIHomeland:ShowHightLightFreeArea(self.fatherBuilding, true)
end

--进入
---@param prepareType MoviePrepareType 
---@return boolean true：可以退出 fasle 不可推出
function UIHomelandMoviePrepareFurniture:OnExit(prepareType)
    self.mUIHomeland:ShowHightLightFreeArea(self.fatherBuilding, false)
    return true
end

--根据数据刷新
---@param prepareType MoviePrepareType 
function UIHomelandMoviePrepareFurniture:Refresh(prepareType)
    HomelandMoviePrepareManager:GetInstance():SetPhaseType( prepareType )
    self.editList:FlushArrange()
end

function UIHomelandMoviePrepareFurniture:SetUIWidgetHomelandBuildController(mobileControl)
    self.editList:SetUIWidgetHomelandBuildController(mobileControl)
end
