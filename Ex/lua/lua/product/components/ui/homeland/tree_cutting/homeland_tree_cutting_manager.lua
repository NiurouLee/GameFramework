_class( "HomelandTreeCuttingManager", Object )
---@class HomelandTreeCuttingManager: Object
HomelandTreeCuttingManager = HomelandTreeCuttingManager

function HomelandTreeCuttingManager:Constructor()
    ---@type table<number, HomelandTree> 家园可砍伐的树木数据
    self._trees = {}

    ---@type number 树的交互配置统一用4
    self._interactCfgID = 4
    ---@type number 取出斧子时间
    self._takeOutAxePeriod = 1000
    ---@type number 砍树动作开始到击中的间隔
    self._beforeHitPeriod = 400
    ---@type number 砍树击中到掉落的间隔
    self._beforeDropPeriod = 260
    ---@type number 砍树掉落到动作完毕的间隔
    self._afterDropPeriod = 340
    ---@type number
    self._lastCutTreeID = nil
    ---@type number
    self._currentTaskID = nil
    ---@type H3DTimerEvent
    self._timerEvent = nil

    ---@type number 掉落需要的砍伐次数 需要走当前斧头的配置 0表示没有斧头
    self._dropNeedCutTimes = 0

    ---@type ResRequest 砍树特效
    self._hitEffect = nil
    ---@type ResRequest 掉落特效
    self._dropEffect = nil

    self._itemUpgradeCallback = GameHelper:GetInstance():CreateCallback(self.OnItemUpgrade, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnItemUpgrade, self._itemUpgradeCallback)

    self._itemChangeCallback = GameHelper:GetInstance():CreateCallback(self.OnItemChange, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.ItemCountChanged, self._itemChangeCallback)
end

---@param homelandClient HomelandClient
function HomelandTreeCuttingManager:Init(homelandClient)
    ---@type HomelandClient
    self._homelandClient = homelandClient
    ---@type InteractPointManager
    self._interactPointManager = self._homelandClient:InteractPointManager()
    ---@type HomelandMainCharacterController
    self._charCtrl = self._homelandClient:CharacterManager():MainCharacterController()

    ---@type HomelandFollowCameraController
    self._camCtrl = self._homelandClient:CameraManager():FollowCameraController()

    local sceneManager = homelandClient:SceneManager()
    local treesRoot = sceneManager:SceneRootTrans():Find("Trees")

    if treesRoot then
        for i = 0, treesRoot.childCount - 1 do
            local treeTrans = treesRoot:GetChild(i)
            local treeID = tonumber(treeTrans.name)
            if treeID then
                local treeCfg = Cfg.cfg_homeland_tree[treeID]
                if treeCfg then
                    local tree = HomelandTree:New(treeID, treeTrans.gameObject, treeCfg, self)
                    self._interactPointManager:AddBuildInteractPoint(tree, i, self._interactCfgID)
                    self._trees[treeID] = tree
                end
            end
        end
    end

    self:RefreshTreeDropInfo()
    self:ResetTimer()
    self:RefreshAxeInfo()
end

function HomelandTreeCuttingManager:Dispose()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnItemUpgrade, self._itemUpgradeCallback)
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.ItemCountChanged, self._itemChangeCallback)

    if self._hitEffect then
        self._hitEffect:Dispose()
    end

    if self._dropEffect then
        self._dropEffect:Dispose()
    end

    self._timerEvent:Cancel()
    self._timerEvent = nil
    self:StopCutTask()
    self._trees = nil
end

function HomelandTreeCuttingManager:RefreshTreeDropInfo()
    ---@type ClientHomelandInfo
    local homelandInfo = GameGlobal.GetModule(HomelandModule):GetHomelandInfo()

    local treeInfoList = homelandInfo.fell_info.infos
    local treeInfoDic = {}
    for i = 1, #treeInfoList do
        treeInfoDic[treeInfoList[i].tree_id] = treeInfoList[i]
    end

    for id, tree in pairs(self._trees) do
        local treeInfo = treeInfoDic[id]
        if treeInfo then
            tree:SetDropTimes(treeInfo.fell_times)
        else
            tree:SetDropTimes(0)
        end
    end
end

function HomelandTreeCuttingManager:ResetTimer()
    ---@type HomelandModule
    local homelandModule = GameGlobal.GetModule(HomelandModule)
    if not homelandModule then
        Log.fatal("HomelandModule is nil, may need login")
        return
    end

    local nextRefreshTime = homelandModule:GetHomelandInfo().fell_info.next_refresh_time * 1000
    local now = GameGlobal.GetModule(SvrTimeModule):GetServerTime()

    self._timerEvent = GameGlobal.Timer():AddEvent(nextRefreshTime - now, function()
        GameGlobal.TaskManager():StartTask(self.RefreshTreeInfoProcess, self)
    end)
end

function HomelandTreeCuttingManager:RefreshAxeInfo()
    local lastDropNeedCutTimes = self._dropNeedCutTimes

    local axeCfg = GameGlobal.GetUIModule(HomelandModule):GetCurrentToolCfg(ToolType.TT_AXE)
    if axeCfg then
        self._dropNeedCutTimes = axeCfg.param
    else
        self._dropNeedCutTimes = 0
    end

    if self._dropNeedCutTimes ~= lastDropNeedCutTimes then
        local tree = self._trees[self._lastCutTreeID]
        if tree then
            tree:ClearCutTimes()
        end
    end
end

function HomelandTreeCuttingManager:HaveAxe()
    return self._dropNeedCutTimes > 0
end

---@param tree HomelandTree
function HomelandTreeCuttingManager:CutTree(tree)
    if self._charCtrl:State() == HomelandActorStateType.Dash then
        return
    end

    self._currentTaskID = GameGlobal.TaskManager():StartTask(self.CutTreeProcess, self, tree)
end

function HomelandTreeCuttingManager:IsCutting()
    return self._currentTaskID ~= nil
end

---@param tree HomelandTree
function HomelandTreeCuttingManager:CutTreeProcess(TT, tree)
    local vec = tree:GetInteractPosition() - self._charCtrl:Position()
    local normal = vec:Normalize()
    local dis = vec:Magnitude()
    local radius = tree:GetCutRadius()
    
    if dis > radius + 0.1 then
        local target = normal * (dis - radius + 0.1) + self._charCtrl:Position()
        local success = self._charCtrl:NavigateToPos(TT, target)
        if not success then
            self._currentTaskID = nil
            return
        end
    end  

    --砍树期间禁止移动
    self._charCtrl:SetForbiddenMove(true, true)

    --朝向树
    local forward = tree:GetInteractPosition() - self._charCtrl:Position()
    forward.y = 0
    self._charCtrl:SetForward(forward)

    if self._charCtrl:State() ~= HomelandActorStateType.Axe then
        self._charCtrl:SetHoldAxe()
        YIELD(TT, self._takeOutAxePeriod)
    end

    --播砍树动作
    self._charCtrl:SetAnimatorTrigger("WaveAxe")

    --击中后播放击中特效
    YIELD(TT, self._beforeHitPeriod)
    self:PlayHitEff(tree:GetTreeRootTrans())    
    --tree:DoShake()
    self._camCtrl:DoShake()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioCutTree)

    --如果本次有掉落 播放掉落特效
    if self:CheckDrop(tree) then
        self:PlayDropEff(tree:GetTreeRootTrans())
    end

    --砍树动作开始到掉落过程
    YIELD(TT, self._beforeDropPeriod)

    --砍到树的时刻 切换lastcuttree 执行砍树逻辑 刷新数据
    local treeID = tree:ID()
    if self._lastCutTreeID ~= treeID then
        local tree = self._trees[self._lastCutTreeID]
        if tree then
            tree:ClearCutTimes()
        end
        self._lastCutTreeID = treeID
    end

    local cutTimes = tree:IncreaseCutTimes()
    Log.info("Felling tree  id:"..treeID.." total times:"..cutTimes)
    if cutTimes >= self._dropNeedCutTimes then
        ---@type HomelandModule
        local homelandModule = GameGlobal.GetModule(HomelandModule)
        local res, assetList = homelandModule:HomelandFell(TT, treeID, cutTimes)

        if res:GetSucc() then
            tree:ClearCutTimes()
            tree:IncreaseDropTimes()
            ---@type RoleAsset
            local asset = assetList[1]
            --根据获得的道具内容 播放获得木材/许愿币表现
            --tips
            local itemCfg = Cfg.cfg_item[asset.assetid]
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.HomeShowUIBubble, 
                StringTable.Get("str_homeland_collect_item", StringTable.Get(itemCfg.Name), asset.count),
                itemCfg.Icon
            )
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioJumpOutGift)
        elseif res:GetResult() ~= HomeLandErrorType.E_DROP_TIMES_LIMIT then
            Log.fatal("[Homeland] HomelandTreeCuttingManager:CutTreeProcess HomelandFell fail, res:"..res:GetResult())
        end
    else
        tree:ResetClearTimer()
    end

    --掉落到砍树动作结束过程
    YIELD(TT, self._afterDropPeriod)

    self._charCtrl:SetForbiddenMove(false)
    self._currentTaskID = nil
end

function HomelandTreeCuttingManager:PlayHitEff(root)
    if not self._hitEffect then
        self._hitEffect = ResourceManager:GetInstance():SyncLoadAsset("eff_jy_log_axe_hit.prefab", LoadType.GameObject)
    end

    self._hitEffect.Obj:SetActive(false)
    self._hitEffect.Obj.transform:SetParent(root, false)
    self._hitEffect.Obj:SetActive(true)
end

function HomelandTreeCuttingManager:PlayDropEff(root)
    if not self._dropEffect then
        self._dropEffect = ResourceManager:GetInstance():SyncLoadAsset("eff_jy_log_axe_leaf.prefab", LoadType.GameObject)
    end

    self._dropEffect.Obj:SetActive(false)
    self._dropEffect.Obj.transform:SetParent(root, false)
    self._dropEffect.Obj:SetActive(true)
end

---@param tree HomelandTree
function HomelandTreeCuttingManager:CheckDrop(tree)
    if tree:ForbiddenCut() then
        return false
    end

    local treeID = tree:ID()
    local cutTimes = 0
    if self._lastCutTreeID == treeID then
        cutTimes = tree:GetCutTimes()
    end

    return cutTimes + 1 >= self._dropNeedCutTimes
end

function HomelandTreeCuttingManager:StopCutTask()
    if self._currentTaskID then
        GameGlobal.TaskManager():KillTask(self._currentTaskID)
        self._currentTaskID = nil
    end
end

function HomelandTreeCuttingManager:OnItemUpgrade(tplID)
    local axeCfg = Cfg.cfg_item_tool_upgrade[tplID]
    if not axeCfg then
        return
    end

    if axeCfg.ToolType == ToolType.TT_AXE then
        self:RefreshAxeInfo()
    end
end

function HomelandTreeCuttingManager:OnItemChange()
    self:RefreshAxeInfo()
end

function HomelandTreeCuttingManager:RefreshTreeInfoProcess(TT)
    ---@type HomelandModule
    local homelandModule = GameGlobal.GetModule(HomelandModule)
    if not homelandModule then
        Log.fatal("HomelandModule is nil, may need login")
        return
    end

    local res = homelandModule:HomelandGetFellInfo(TT)

    --可能此时退出了家园
    if self._timerEvent == nil or self._timerEvent:IsCancel() then
        return
    end
    
    if res:GetSucc() then
        self:RefreshTreeDropInfo()
    else
        Log.fatal("[Homeland] HomelandTreeCuttingManager:RefreshTreeInfoProcess get fell info fail, res:"..res:GetResult())
    end

    self:ResetTimer()
end