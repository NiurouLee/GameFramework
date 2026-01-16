_class( "HomelandMiningManager", Object )
---@class HomelandMiningManager: Object
HomelandMiningManager = HomelandMiningManager

function HomelandMiningManager:Constructor()
    ---@type table<number, HomelandOre> 家园可砍伐的矿石木数据
    self._ores = {}

    ---@type number 矿石的交互配置14
    self._interactCfgID = 14
    ---@type number 挖矿开始到掉落的间隔
    self._beforeDropPeriod = 900
    ---@type number 挖矿掉落到动作完毕的间隔
    self._afterDropPeriod = 600
    ---@type number 挖矿动作前摇时间
    self._aniPeriod = 1300
    ---@type number 最近挖掘矿石Id
    self._lastCutOreID = nil
    ---@type number
    self._currentTaskID = nil
    ---@type H3DTimerEvent
    self._timerEvent = nil

    ---@type number 掉落需要的挖矿次数 需要走当前镐的配置 0表示没有镐
    self._dropNeedCutTimes = 0

    self._itemUpgradeCallback = GameHelper:GetInstance():CreateCallback(self.OnItemUpgrade, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnItemUpgrade, self._itemUpgradeCallback)

    self._itemChangeCallback = GameHelper:GetInstance():CreateCallback(self.OnItemChange, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.ItemCountChanged, self._itemChangeCallback)

    self._callOresRefresh = GameHelper:GetInstance():CreateCallback(self.CallOresRefresh, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.HomelandOreRefresh, self._callOresRefresh)

    self._refreshOreInfo = GameHelper:GetInstance():CreateCallback(self.RefreshOreInfo, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.HomelandRefreshOreInfo, self._refreshOreInfo)
end

---@param homelandClient HomelandClient
function HomelandMiningManager:Init(homelandClient)
    ---@type HomelandClient
    self._homelandClient = homelandClient
    ---@type InteractPointManager
    self._interactPointManager = self._homelandClient:InteractPointManager()
    ---@type HomelandMainCharacterController
    self._charCtrl = self._homelandClient:CharacterManager():MainCharacterController()
      ---@type InteractPointManager
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    local sceneManager = homelandClient:SceneManager()
    local oresRoot = sceneManager:SceneRootTrans():Find("Ores")

    if oresRoot then
        for i = 0, oresRoot.childCount - 1 do
            local oreTrans = oresRoot:GetChild(i)
            local oreID = tonumber(oreTrans.name)
            if oreID then
                local oreCfg = Cfg.cfg_homeland_mine[oreID]
                if oreCfg then
                    if not self._ores[oreID] then 
                        local ore = HomelandOre:New(oreID, oreTrans.gameObject, oreCfg, self)
                        self._interactPointManager:AddBuildInteractPoint(ore, i, self._interactCfgID)
                        self._ores[oreID] = ore
                    end 
                end
            end
        end
    end

    self:RefreshOreInfo()
    self:RefreshPickAxeInfo()
end

function HomelandMiningManager:Dispose()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnItemUpgrade, self._itemUpgradeCallback)
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.ItemCountChanged, self._itemChangeCallback)
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.HomelandOreRefresh, self._callOresRefresh)
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.HomelandRefreshOreInfo, self._refreshOreInfo)
  --  self._timerEvent:Cancel()
 --   self._timerEvent = nil
    self:StopDigTask()
    self._ores = nil
end

function HomelandMiningManager:RefreshOreInfo()
    ---@type ClientHomelandInfo
    local oreInfoList  = {}
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.UIStateManager():Lock("HomelandMiningManager:RefreshOreInfo")
            local res = self._homelandModule:HomelandGetMiningInfo(TT)
            if res:GetSucc() then
                local oreInfoDic = {}
                oreInfoList =  self._homelandModule.m_homeland_info.mining_info.infos 
                for i = 1, #oreInfoList do
                    oreInfoDic[oreInfoList[i].mine_id] = oreInfoList[i]
                end
            
                for id, ore in pairs(self._ores) do
                    local oreInfo = oreInfoDic[id]
                    if oreInfo then
                        ore:SetOreServerData(oreInfo)
                    end
                end
                self:CallOresRefresh()
            end 
            GameGlobal.UIStateManager():UnLock("HomelandMiningManager:RefreshOreInfo")    
        end,
        self
    )
end

function HomelandMiningManager:ResetTimer()
    ---@type ClientHomelandInfo
    -- local res = GameGlobal.GetModule(HomelandModule):HomelandGetMiningInfo()
    -- if res:GetSucc() then 
    --     local nextRefreshTime = self._homelandModule.m_homeland_info.mining_info.infos 
    --     local now = GameGlobal.GetModule(SvrTimeModule):GetServerTime()
    --     self._timerEvent = GameGlobal.Timer():AddEvent(nextRefreshTime - now, function()
    --         GameGlobal.TaskManager():StartTask(self.RefreshOreInfoProcess, self)
    --     end)
    -- end 
end

function HomelandMiningManager:RefreshPickAxeInfo()
    local lastDropNeedCutTimes = self._dropNeedCutTimes

    local pickAxeCfg = GameGlobal.GetUIModule(HomelandModule):GetCurrentToolCfg(ToolType.TT_PICK)

    if pickAxeCfg then
        self._dropNeedCutTimes = pickAxeCfg.param
    else
        self._dropNeedCutTimes = 0
    end

    if self._dropNeedCutTimes ~= lastDropNeedCutTimes then
        local ore = self._ores[self._lastCutOreID]
        if ore then
            ore:ClearCutTimes()
        end
    end
end

function HomelandMiningManager:HavePickAxe()
    return self._dropNeedCutTimes > 0
end

---@param ore HomelandOre
function HomelandMiningManager:CutOre(ore)
    if not self._charCtrl then 
       return 
    end 
    if self._charCtrl:State() == HomelandActorStateType.Dash  then
        return
    end
    if not  ore:CheckCanCut() then
        Log.fatal("Mining ore  id:"..ore:ID().." total times max")
        return
    end
    self._currentTaskID = GameGlobal.TaskManager():StartTask(self.CutOreProcess, self, ore)
end

function HomelandMiningManager:IsCutting()
    return self._currentTaskID ~= nil
end

function HomelandMiningManager:_GetNearestPoint(points, check)
    if not self._charCtrl then  
        return 
    end
    local charPos = self._charCtrl:Position()
    local nearestDis = math.huge
    local nearestPoint = nil    

    for i = 1, #points do
        local point = points[i]
        local ore = point:GetBuild()
        local checkRet = not check or ore:CheckCanCut()
        if point:IsTrigger(charPos) and checkRet then 
            local dis = point:GetDistance(charPos)
            if dis > 0 and dis < nearestDis then
                nearestDis = dis
                nearestPoint = point
            end
        end
    end
    return nearestPoint
end

function HomelandMiningManager:GetNearestOreCanCut()

    local points = self._interactPointManager:GetPoints(InteractPointType.Mining)

    local point = self:_GetNearestPoint(points, true)
    if point then 
        return point:GetBuild()
    end
    -- 包括挖空的矿
    local point = self:_GetNearestPoint(points, false)
    if point then 
        return point:GetBuild()
    end
    return nil
end

---@param ore HomelandOre
function HomelandMiningManager:CutOreProcess(TT, ore)
    local player =  self._charCtrl:Transform()
    if not player then 
        return 
    end 
    local vec = ore:GetInteractPosition() - self._charCtrl:Position()
    local normal = vec:Normalize()
    local dis = vec:Magnitude()
    local radius = ore:GetCutRadius()
    
    if dis > radius + 0.1 then
        local target = normal * (dis - radius + 0.1) + self._charCtrl:Position()
        local success = self._charCtrl:NavigateToPos(TT, target)
        if not success then
            self._currentTaskID = nil
            self:OnTaskOver()
            return
        end
    end
    
    --砍矿石期间禁止移动
    self._charCtrl:SetForbiddenMove(true, true)
    local forward =  ore:GetPlayerDirection(self._charCtrl)
    self._charCtrl:SetForward(forward)
    if self._charCtrl:State() ~= HomelandActorStateType.Pick then
        self._charCtrl:SetHoldPick()
        YIELD(TT, self._aniPeriod)
    end
  
    --播砍矿石动作
    --砍矿石动作开始到掉落过程
    self._charCtrl:SetAnimatorTrigger("WavePick")
    local trans = ore:GetOreEffectPos(self._charCtrl)
    self:PlayHitEff(trans)
    AudioHelperController.PlayUISoundAutoReleaseDelay(CriAudioIDConst.HomelandAudioMining,500)
    
    YIELD(TT, self._beforeDropPeriod)
    --砍到矿石的时刻 切换lastCutOre 执行砍矿石逻辑 刷新数据
    local oreID = ore:ID()
    if self._lastCutOreID ~= oreID then
        local ore = self._ores[self._lastCutOreID]
        if ore then
            ore:ClearCutTimes()
        end
        self._lastCutOreID = oreID
    end

    local cutTimes = ore:IncreaseCutTimes() -- Time++ 
    Log.fatal("Felling ore  id:"..oreID.." total times:"..cutTimes)
    if cutTimes >= self._dropNeedCutTimes then
        ---@type HomelandModule
        local homelandModule = GameGlobal.GetModule(HomelandModule)
        local res, assetList = homelandModule:HomelandMining(TT, oreID, cutTimes)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioJumpOutGift)
        if res:GetSucc() then
            ore:ClearCutTimes()
            ore:IncreaseDropTimes()
            local asset = assetList[1]
            if #assetList > 0 then 
                --根据获得的道具内容 播放获得石材/许愿币表现
                local itemCfg = Cfg.cfg_item[asset.assetid]
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.HomeShowUIBubble, 
                    StringTable.Get("str_homeland_collect_item", StringTable.Get(itemCfg.Name), asset.count),
                    itemCfg.Icon
            ) 
            end 
        else
            Log.fatal("[Homeland] HomelandMiningManager:CutOreProcess HomelandMining fail, res:"..res:GetResult())
        end
    else
        ore:ResetClearTimer()
    end

    --掉落到砍矿石动作结束过程
    YIELD(TT, self._afterDropPeriod)

    self._charCtrl:SetForbiddenMove(false)
    self:OnTaskOver()
    self._currentTaskID = nil
end

function HomelandMiningManager:OnTaskOver()
    if self._hitEffect then
        self._hitEffect:Dispose()
        self._hitEffect = nil
    end
end

function HomelandMiningManager:StopDigTask()
    if self._currentTaskID then
        GameGlobal.TaskManager():KillTask(self._currentTaskID)
        self._currentTaskID = nil
    end
end

function HomelandMiningManager:OnItemUpgrade(tplID)
    local pickAxeCfg = Cfg.cfg_item_tool_upgrade[tplID]
    if not pickAxeCfg then
        return
    end

    if pickAxeCfg.ToolType == ToolType.TT_PICK then
        self:RefreshPickAxeInfo()
    end
end

function HomelandMiningManager:OnItemChange()
    self:RefreshPickAxeInfo()
end

function HomelandMiningManager:CallOresRefresh()
    local oreInfoList  = {}
    TaskManager:GetInstance():StartTask(
        function(TT)
                local res = self._homelandModule:HomelandGetMiningInfo(TT)
                if res:GetSucc() then
                    local oreInfoDic = {}
                    oreInfoList =  self._homelandModule.m_homeland_info.mining_info.infos 
                    for i = 1, #oreInfoList do
                        oreInfoDic[oreInfoList[i].mine_id] = oreInfoList[i]
                    end
                
                    for id, ore in pairs(self._ores) do
                        local oreInfo = oreInfoDic[id]
                        if oreInfo then
                            ore:SetRefreshTime(oreInfo.next_refresh_time)
                        end
                    end
                end       
             end,
        self
    )
end
    
function HomelandMiningManager:PlayHitEff(root)
    if not self._hitEffect then
        self._hitEffect = ResourceManager:GetInstance():SyncLoadAsset("eff_jy_mine_axe_hit.prefab", LoadType.GameObject)
    end
    local player =  self._charCtrl:Transform()
    local effectTra =  player:Find(root)
    if effectTra and  self._hitEffect.Obj then 
        self._hitEffect.Obj:SetActive(false)
        self._hitEffect.Obj.transform:SetParent(effectTra , false)
        self._hitEffect.Obj:SetActive(true)
        self._hitEffect.Obj.transform.localPosition = Vector3(-0.2944,-0.044,0.474)
    end 
end
