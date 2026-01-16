---@class HomelandMedalWall:HomeBuilding
_class("HomelandMedalWall", HomeBuilding)
HomelandMedalWall = HomelandMedalWall

---@param architecture Architecture
function HomelandMedalWall:Constructor(insID, architecture, cfg)
    self._isInited = false
end

function HomelandMedalWall:InitMedalWall(architecture)
    if self._isInited then
        return
    end
    self._isInited = true

    ---@type UIHomelandModule
    self._uiModule = GameGlobal.GetUIModule(HomelandModule)
    --是否为拜访
    self._isVisit = self._uiModule:GetClient():IsVisit()

    self._pstid = architecture.pstid
    self._buildID = self:GetBuildId()
    self._buildPstID = self:GetBuildPstId()
    self._transform = self:Transform()

    --勋章挂点
    self._medalRoot = GameObjectHelper.FindChild(self._transform, "MedalRoot")
    --勋章墙
    self._meadalWall = GameObjectHelper.FindChild(self._transform, "hl_envmod_building_5256001")

    if self._isVisit then
        self:RefreshMedalWall()
    else
        self:_InitMedalWall()
    end

    -- self._refreshWithBuild = false

    -- self._timerHandler =
    -- GameGlobal.Timer():AddEventTimes(
    --     1,
    --     TimerTriggerCount.Infinite,
    --     function()
    --         if self._homelandClient:CurrentMode() == HomelandMode.Build then
    --             if self._medals and self._refreshWithBuild == false then
    --                 for k, v in pairs(self._medals) do
    --                     v:Destroy()
    --                 end
    --                 self._medals = {}
    --                 self._refreshWithBuild = true
    --             end
    --         else
    --             if self._refreshWithBuild == true then
    --                 self:RefreshMedalWall()
    --                 self._refreshWithBuild = false
    --             end
    --         end
    --     end
    -- )
end

function HomelandMedalWall:Dispose()
    HomelandMedalWall.super.Dispose(self)
    self:ClearMedals()

    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
end

function HomelandMedalWall:ClearMedals()
    if self._medals then
        for k, v in pairs(self._medals) do
            v:Destroy()
        end
    end

    self:RemoveEvents()
end

function HomelandMedalWall:RemoveEvents()
    if self._updateMedalCallback then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.BoardMedalUpdate, self._updateMedalCallback)
        self._updateMedalCallback = nil
    end
end

---初始化
function HomelandMedalWall:_InitMedalWall()
    if self._updateMedalCallback == nil then
        self._updateMedalCallback = GameHelper:GetInstance():CreateCallback(self.RefreshMedalWall, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.BoardMedalUpdate, self._updateMedalCallback)
    end

    self:RefreshMedalWall()
end

function HomelandMedalWall:RefreshMedalWall()
    --删除展示的勋章
    if self._medals then
        for k, v in pairs(self._medals) do
            v:Destroy()
        end
    end
    self._medals = {}

    --获取勋章摆放信息
    ---@type medal_placement_info
    local placeData = nil
    if self._isVisit then
        placeData = self._uiModule:GetVisitInfo().medal_placement
    else
        --从勋章系统中获取
        placeData = GameGlobal.GetModule(MedalModule):GetPlacementInfo()
    end

    --更换材质（勋章板）
    local boardCfg = Cfg.cfg_item_medal_board[placeData.board_back_id]
    if boardCfg then
        if self._meadalWall then
            local meadalWallMesh = self._meadalWall:GetComponent(typeof(UnityEngine.MeshRenderer))
            self._res = ResourceManager:GetInstance():SyncLoadAsset(boardCfg.BoardMat..".mat", LoadType.Mat)
            if self._res then 
                meadalWallMesh.material  = self._res.Obj
            else
                Log.fatal("该勋章板资源不存在")
            end 
        end
    end

    ---@type N22MedalEditData 勋章位置计算器
    local medalEditor = GameGlobal.GetModule(MedalModule):GetN22MedalEditData()
    ---@type BoardMedal[]
    local medalList = medalEditor:GetMappingBoardMedalList(MedalWallConfig.HomelandMedalWallWidth, placeData)

    --挂载勋章
    for _, boardMedal in pairs(medalList) do
        self._medals[#self._medals + 1] = HomelandMedal:New(self._medalRoot, boardMedal, self._buildID)
    end
end
