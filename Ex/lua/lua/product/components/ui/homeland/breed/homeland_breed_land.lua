---@class HomelandBreedLand:HomeBuilding
_class("HomelandBreedLand", HomeBuilding)
HomelandBreedLand = HomelandBreedLand

---@param architecture Architecture
function HomelandBreedLand:Constructor(insID, architecture, cfg)
    -- HomelandBreedLand.super.Constructor(self, insID, architecture, cfg, posY, parent) --不需要，默认父类先构造
    self._isInited = false
end

function HomelandBreedLand:InitBreedLand(architecture)
    if self._isInited then
        return --地块的数据只初始化一次
    end
    ---@type UIHomelandModule
    self._uiModule = GameGlobal.GetUIModule(HomelandModule)
    self._isVisit = self._uiModule:GetClient():IsVisit() --是否为拜访
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    self._pstid = architecture.pstid
    self._breedTask = nil
    self._curPhases = 0
    self._finalPhases = 3
    self._phasesArray = nil
    self._endTime = 0
    self._totalTime = 0
    ---@type UnityEngine.GameObject
    self._tree = nil
    self._breedCfg = Cfg.cfg_homeland_breed_const[1]
    self._landEffectReqs = {}
    self._landEffectObjs = {}
    self:_InitLandEffect()
    ---@type HomelandBreedLandSprite
    self._sprite = HomelandBreedLandSprite:New(self:Transform(), self._breedCfg)
    self:_InitTree()
    self:_InitVisitEft()
    self._isInited = true
    if not self._friendSpeedCallBack then
        self._friendSpeedCallBack = GameHelper:GetInstance():CreateCallback(self._OnFriendSpeed, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.HomelandFriendSpeed, self._friendSpeedCallBack)
    end
end

function HomelandBreedLand:Dispose()
    HomelandBreedLand.super.Dispose(self)
    self._curPhases = 0
    self._finalPhases = 3
    self._phasesArray = nil
    self._endTime = 0
    self._totalTime = 0
    self:_DestroyTree()
    if self._phasesCheckTimer then
        GameGlobal.Timer():CancelEvent(self._phasesCheckTimer)
        self._phasesCheckTimer = nil
    end
    if self._sprite then
        self._sprite:Dispose()
        self._sprite = nil
    end
    for _, req in pairs(self._landEffectReqs) do
        req:Dispose()
    end
    self._landEffectReqs = nil
    for _, obj in pairs(self._landEffectObjs) do
        obj:Destroy()
    end
    self._landEffectObjs = nil
    if self._breedTask then
        GameGlobal.TaskManager():KillTask(self._breedTask)
        self._breedTask = nil
    end
    if self._waterEffReq then
        self._waterEft = nil
        self._waterEffReq:Dispose()
        self._waterEffReq = nil
    end
    if self._friendSpeedCallBack then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.HomelandFriendSpeed, self._friendSpeedCallBack)
        self._friendSpeedCallBack = nil
    end
end

--种植
function HomelandBreedLand:PlantTree()
    self._curPhases = 0
    self._finalPhases = 3
    self._phasesArray = nil
    self._endTime = 0
    self._totalTime = 0
    self:_DestroyTree()
    if self._breedTask then
        GameGlobal.TaskManager():KillTask(self._breedTask)
        self._breedTask = nil
    end
    self._breedTask = GameGlobal.TaskManager():StartTask(
        function(TT)
            ---@type CultivationInfo
            self._cultivationInfo = nil
            if self._isVisit then
                self._cultivationInfo = self._uiModule:GetVisitInfo().cultivation_info
            else
                self._cultivationInfo = self._homelandModule:GetHomelandInfo().cultivation_info
            end
            ---@type LandCultivationInfo
            self._landCultivationInfo = self._cultivationInfo.land_cultivation_infos[self._pstid]
            if self._landCultivationInfo then
                local seedId = nil
                local treeId = nil
                if #self._landCultivationInfo.client_info.mutation_cultivation > 0 then
                    seedId = self._landCultivationInfo.client_info.mutation_cultivation[1].main_seed_id
                elseif #self._landCultivationInfo.client_info.directional_cultivation > 0 then
                    seedId = self._landCultivationInfo.client_info.directional_cultivation[1].seed_id
                elseif #self._landCultivationInfo.client_info.state_change_cultivation > 0 then
                    treeId = self._landCultivationInfo.client_info.state_change_cultivation[1].tree_id
                end

                if seedId or treeId then
                    ---@type RoleAsset
                    local roleAsset = self._landCultivationInfo.cultivation_result
                    if #roleAsset > 0 then
                        self._cfgResultTree = Cfg.cfg_item_tree_attribute[roleAsset[1].assetid]
                    end
                end

                if seedId then
                    local cfg_seed = Cfg.cfg_item_tree_seed[seedId]
                    self._cfgSeedTree = Cfg.cfg_item_tree_attribute[cfg_seed.TreeId]
                    self._finalPhases = #self._cfgResultTree.PhasesModel
                    local phases, nextTime = self:_CalcPhases()
                    self._curPhases = phases
                    self:OnPhaseChange(TT, self._curPhases, self._cfgResultTree.PhasesModel[self._curPhases])
                    local startLoopTime =
                        self._breedCfg.LoopInterval +
                        math.random(self._breedCfg.RandomValue[1], self._breedCfg.RandomValue[2])
                    YIELD(TT, startLoopTime)
                    self:_AutoLoop()
                    if nextTime > 0 then
                        self._phasesCheckTimer = GameGlobal.Timer():AddEvent(nextTime * 1000, self._PhasesCheck, self)
                    end
                end

                if treeId and self._cfgResultTree then
                    --态变培育，模拟种树
                    self:SimulateTreeStateChg(TT)
                end
            end
        end
    )
end

--使用了加速道具
function HomelandBreedLand:RefreshPhases()
    ---@type CultivationInfo
    self._cultivationInfo = nil
    if self._isVisit then
        self._cultivationInfo = self._uiModule:GetVisitInfo().cultivation_info
    else
        self._cultivationInfo = self._homelandModule:GetHomelandInfo().cultivation_info
    end
    ---@type LandCultivationInfo
    self._landCultivationInfo = self._cultivationInfo.land_cultivation_infos[self._pstid]
    self._endTime = self._homelandModule:GetLandEndTime(self._landCultivationInfo)
    self:_PhasesCheck()
end

--收获、结束培育
function HomelandBreedLand:Clear()
    if self._waterEffReq then
        self._waterEft = nil
        self._waterEffReq:Dispose()
        self._waterEffReq = nil
    end
    for key, _ in pairs(HomelandBreedLandEffect) do
        self._landEffectObjs[key]:SetActive(false)
    end
    if self._breedTask then
        GameGlobal.TaskManager():KillTask(self._breedTask)
        self._breedTask = nil
    end
    if self._loopTask then
        GameGlobal.TaskManager():KillTask(self._loopTask)
        self._loopTask = nil
    end
    self._sprite:ShowSprite(false)
    self:_DestroyTree()
    self._cfgSeedTree = nil
    self._cfgResultTree = nil
    self._curPhases = 0
    self._landCultivationInfo = nil
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandBreedPhasesChange)
end

function HomelandBreedLand:_InitTree()
    ---@type CultivationInfo
    self._cultivationInfo = nil
    if self._isVisit then
        self._cultivationInfo = self._uiModule:GetVisitInfo().cultivation_info
    else
        self._cultivationInfo = self._homelandModule:GetHomelandInfo().cultivation_info
    end
    ---@type LandCultivationInfo
    self._landCultivationInfo = self._cultivationInfo.land_cultivation_infos[self._pstid]
    if self._landCultivationInfo then
        local seedId = nil
        local treeId = nil
        if #self._landCultivationInfo.client_info.mutation_cultivation > 0 then
            seedId = self._landCultivationInfo.client_info.mutation_cultivation[1].main_seed_id
        elseif #self._landCultivationInfo.client_info.directional_cultivation > 0 then
            seedId = self._landCultivationInfo.client_info.directional_cultivation[1].seed_id
        elseif #self._landCultivationInfo.client_info.state_change_cultivation > 0 then
            treeId = self._landCultivationInfo.client_info.state_change_cultivation[1].tree_id
        end

        if seedId or treeId then
            ---@type RoleAsset
            local roleAsset = self._landCultivationInfo.cultivation_result
            if #roleAsset > 0 then
                self._cfgResultTree = Cfg.cfg_item_tree_attribute[roleAsset[1].assetid]
            end
        end

        if seedId then
            local cfg_seed = Cfg.cfg_item_tree_seed[seedId]
            self._cfgSeedTree = Cfg.cfg_item_tree_attribute[cfg_seed.TreeId]
            self._finalPhases = #self._cfgResultTree.PhasesModel
            local phases, nextTime = self:_CalcPhases()
            self._curPhases = phases
            self:_LoadTree(self._cfgResultTree.PhasesModel[self._curPhases])
            self:_AutoLoop()
            if nextTime > 0 then
                self._phasesCheckTimer = GameGlobal.Timer():AddEvent(nextTime * 1000, self._PhasesCheck, self)
            end
        end

        if treeId then
            if self._cfgResultTree then
                self._finalPhases = #self._cfgResultTree.PhasesModel
                self._curPhases = self._finalPhases
                self:_LoadTree(self._cfgResultTree.PhasesModel[self._finalPhases])
            else
                Log.error("stateChange cultiviation error, result is nil")
            end
        end
    end
end

---@param name string
function HomelandBreedLand:_LoadTree(name)
    if not name then
        Log.error("HomelandBreedLand Error. CurPhases "..self._curPhases)
        return
    end
    self._treeReq = ResourceManager:GetInstance():SyncLoadAsset(name .. ".prefab", LoadType.GameObject)
    if self._treeReq and self._treeReq.Obj then
        self._tree = self._treeReq.Obj
        self._tree:SetActive(true)
        self._tree.transform:SetParent(self:Transform())
        self._tree.transform.localPosition = Vector3.zero
        self._tree.transform.localRotation = Quaternion.Euler(0, 0, 0)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandBreedPhasesChange)
end

function HomelandBreedLand:_DestroyTree()
    if self._tree then
        self._tree:Destroy()
        self._tree = nil
    end
    if self._treeReq then
        self._treeReq:Dispose()
        self._treeReq = nil
    end
    if self._phasesCheckTimer then
        GameGlobal.Timer():CancelEvent(self._phasesCheckTimer)
        self._phasesCheckTimer = nil
    end
end

function HomelandBreedLand:_CalcPhases()
    local curPhases = self._curPhases
    local nextTime = 0
    local curTime = self._svrTimeModule:GetServerTime() * 0.001
    if not self._phasesArray then
        local cfg = Cfg.cfg_homeland_rarity {Species = self._cfgSeedTree.Species, Rarity = self._cfgSeedTree.Rarity}
        self._phasesArray = {}
        local n = 0
        for key, _phases in pairs(cfg[1].Phases) do
            self._phasesArray[key] = {n, _phases}
            n = _phases
        end
        self._endTime = self._homelandModule:GetLandEndTime(self._landCultivationInfo)
        self._totalTime = 0
        if #self._landCultivationInfo.client_info.mutation_cultivation > 0 then
            self._totalTime = cfg[1].MutationTime
        end
        if #self._landCultivationInfo.client_info.directional_cultivation > 0 then
            self._totalTime = cfg[1].DirectionalTime
        end
    end
    local remainTime = self._endTime - curTime
    if remainTime >= 0 then
        local percent = math.abs(1 - remainTime / self._totalTime) * 100
        if percent > 100 then
            percent = 100
        end
        for _phases, value in pairs(self._phasesArray) do
            if percent > value[1] and percent <= value[2] then
                curPhases = _phases
            end
        end
        if curPhases < #self._phasesArray then
            local p = curPhases + 1
            local time = (self._phasesArray[p][1] * 0.01) * self._totalTime
            nextTime = time - percent * 0.01 * self._totalTime
        end
    else
        curPhases = self._finalPhases
    end
    Log.info("HomelandBreedLand CalcPhases "..curPhases..", "..nextTime)
    return curPhases, nextTime
end

function HomelandBreedLand:_PhasesCheck()
    if self._curPhases >= self._finalPhases then
        return
    end
    local phases, nextTime = self:_CalcPhases()
    if phases ~= self._curPhases then
        self._curPhases = phases
        if self._breedTask then
            GameGlobal.TaskManager():KillTask(self._breedTask)
            self._breedTask = nil
        end
        self._breedTask = GameGlobal.TaskManager():StartTask(
            function(TT)
                self:OnPhaseChange(TT, self._curPhases, self._cfgResultTree.PhasesModel[self._curPhases])
                if nextTime > 0 then
                    self._phasesCheckTimer = GameGlobal.Timer():AddEvent(nextTime * 1000, self._PhasesCheck, self)
                end
            end
        )
    else
        if self._phasesCheckTimer and nextTime > 0 then
            GameGlobal.Timer():CancelEvent(self._phasesCheckTimer)
            self._phasesCheckTimer = GameGlobal.Timer():AddEvent(nextTime * 1000, self._PhasesCheck, self)
        end
    end
end

function HomelandBreedLand:GetCurPhases()
    return self._curPhases
end

function HomelandBreedLand:GetCurTree()
    return self._cfgResultTree
end

function HomelandBreedLand:GetRemainTime()
    return self._endTime - self._svrTimeModule:GetServerTime() * 0.001
end

function HomelandBreedLand:InBreeding()
    return self._curPhases > 0
end

--是否已经长成
function HomelandBreedLand:IsMature()
    return self._curPhases >= self._finalPhases
end

function HomelandBreedLand:_InitVisitEft()
    ---@type UIHomelandModule
    local uiModule = GameGlobal.GetUIModule(HomelandModule)
    if uiModule:GetClient():IsVisit() then
        local info = uiModule:GetVisitInfo().cultivation_info
        ---@type LandCultivationInfo
        local landInfo = info.land_cultivation_infos[self:PstID()]

        if landInfo then --有地块
            if not self:IsMature() and not self:Visit_IsWatered() then --还未长成
                --拜访时该地块可浇水
                local offset
                if self._curPhases == 0 then
                    offset = Vector3(0, 0, 0)
                elseif self._curPhases == 1 then
                    offset = Vector3(0, 0.2, 0)
                elseif self._curPhases == 2 then
                    offset = Vector3(0, 0.5, 0)
                else
                    offset = Vector3(0, 0, 0)
                end
                self._waterEffReq =
                    ResourceManager:GetInstance():SyncLoadAsset("eff_jy_meme_jiaoshui.prefab", LoadType.GameObject)
                self._waterEft = self._waterEffReq.Obj
                self._waterEft:SetActive(true)
                local t = self._waterEft.transform
                t.position = self._pos + offset
                ---@type UnityEngine.Animation
                local anim = self._waterEft:GetComponent(typeof(UnityEngine.Animation))
                anim:PlayQueued("effanim_hl_meme_jiaoshui_in", UnityEngine.QueueMode.PlayNow)
                anim:PlayQueued("effanim_hl_meme_jiaoshui_loop", UnityEngine.QueueMode.CompleteOthers)
            end
        end
    end
end

function HomelandBreedLand:HideWaterEft(TT)
    if not self._waterEft then
        return
    end
    ---@type UnityEngine.Animation
    local anim = self._waterEft:GetComponent(typeof(UnityEngine.Animation))
    anim:Play("effanim_hl_meme_jiaoshui_out")
    YIELD(TT, 300)
    if not self._active then
        return
    end
    if self._waterEffReq then
        self._waterEft = nil
        self._waterEffReq:Dispose()
        self._waterEffReq = nil
    end
end

--阶段变化
function HomelandBreedLand:OnPhaseChange(TT, phases, name)
    if phases == 3 then
        if self._loopTask then
            GameGlobal.TaskManager():KillTask(self._loopTask)
            self._loopTask = nil
        end
    end
    if self._sprite then
        self._sprite:ShowSprite(false)
    end
    --召唤
    if self._sprite and not self._isVisit then
        self._sprite:ShowSprite(true)
        self._sprite:PlayAnimation("zhaohuan")
        self._sprite:PlayEffect("zhaohuan")
    end
    YIELD(TT, 2000)
    --施肥
    if self._sprite and not self._isVisit then
        self._sprite:PlayAnimation("shifei")
        self._sprite:PlayEffect("shifei")
    end
    YIELD(TT, 2100)
    --地块表现
    if phases == 1 then
        if not self._isVisit then
            self._landEffectObjs["p1"]:SetActive(true)
        end
        YIELD(TT, 200)
        self:_DestroyTree()
        self:_LoadTree(name)
        YIELD(TT, 1000)
        self._landEffectObjs["p1"]:SetActive(false)
        YIELD(TT, 1000)
        if self._sprite and not self._isVisit then
            self._sprite:ShowSprite(false)
            self._sprite:PlayEffect("xiaoshi")
        end
    elseif phases == 2 then
        if not self._isVisit then
            self._landEffectObjs["p2"]:SetActive(true)
        end
        local animation = self._landEffectObjs["p2"]:GetComponent(typeof(UnityEngine.Animation))
        if animation then
            animation:Play("effanim_jy_pt_bianhuan")
        end
        self:_DestroyTree()
        self:_LoadTree(name)
        YIELD(TT, 2500)
        self._landEffectObjs["p2"]:SetActive(false)
        if self._sprite and not self._isVisit then
            self._sprite:ShowSprite(false)
            self._sprite:PlayEffect("xiaoshi")
        end
    elseif phases == 3 then
        if self._sprite and not self._isVisit then
            self._sprite:ShowSprite(false)
            self._sprite:PlayEffect("xiaoshi")
        end
        YIELD(TT, 500)
        if not self._isVisit then
            self._landEffectObjs["p3"]:SetActive(true)
        end
        local animation = self._landEffectObjs["p3"]:GetComponent(typeof(UnityEngine.Animation))
        if animation then
            animation:Play("effanim_jy_pt_bianhuan")
        end
        YIELD(TT, 100)
        self:_DestroyTree()
        self:_LoadTree(name)
        YIELD(TT, 2700)
        self._landEffectObjs["p3"]:SetActive(false)
    end
end

--循环播放浇水动画
function HomelandBreedLand:_AutoLoop()
    if self._isVisit then
        return
    end
    if self._curPhases == 3 then
        if self._loopTask then
            GameGlobal.TaskManager():KillTask(self._loopTask)
            self._loopTask = nil
        end
        return
    end
    if self._breedCfg then
        self._loopTask =
            GameGlobal.TaskManager():StartTask(
            function(TT)
                local nextTime =
                    self._breedCfg.LoopInterval +
                    math.random(self._breedCfg.RandomValue[1], self._breedCfg.RandomValue[2])
                YIELD(TT, nextTime * 1000)
                --召唤
                if self._sprite then
                    self._sprite:ShowSprite(true)
                    self._sprite:PlayAnimation("zhaohuan")
                    self._sprite:PlayEffect("zhaohuan")
                end
                YIELD(TT, 2000)
                --浇水
                if self._sprite then
                    self._sprite:ShowSprite(true)
                    self._sprite:PlayAnimation("jiaoshui")
                    self._sprite:PlayEffect("jiaoshui")
                end
                YIELD(TT, 6000)
                --消失
                if self._sprite then
                    self._sprite:ShowSprite(false)
                    self._sprite:PlayEffect("xiaoshi")
                end
                self:_AutoLoop()
            end
        )
    end
end

function HomelandBreedLand:_InitLandEffect()
    for key, value in pairs(HomelandBreedLandEffect) do
        local req = ResourceManager:GetInstance():SyncLoadAsset(value, LoadType.GameObject)
        local obj = nil
        if req and req.Obj then
            obj = req.Obj
            obj.transform:SetParent(self:Transform())
            obj.transform.localPosition = Vector3.zero
            obj.transform.localRotation = Quaternion.Euler(0, 0, 0)
            obj:SetActive(false)
        end
        self._landEffectReqs[key] = req
        self._landEffectObjs[key] = obj
    end
end

function HomelandBreedLand:Visit_IsWatered()
    local list = self._homelandModule:GetHomelandInfo().visit_info.cultivation_list
    return table.icontains(list, self:PstID())
end

function HomelandBreedLand:_OnFriendSpeed(pstId)
    if self._pstid == pstId then
        self:RefreshPhases()
    end
end

--模拟态变培育过程
function HomelandBreedLand:SimulateTreeStateChg(TT)
    if not self._cfgResultTree then
        return
    end
    self._finalPhases = #self._cfgResultTree.PhasesModel
    self._curPhases = self._finalPhases - 1

    --拜访
    if self._isVisit then
        self._curPhases = self._finalPhases
        self:_LoadTree(self._cfgResultTree.PhasesModel[self._finalPhases])
        return
    end

    --移除交互点
    self:ResetInteractPoint()

    --树苗
    self:_LoadTree(self._cfgResultTree.PhasesModel[self._curPhases])

    self._curPhases = self._finalPhases
    self:OnPhaseChange(TT, self._curPhases, self._cfgResultTree.PhasesModel[self._curPhases])

    --刷新交互点
    self:RefreshInteractPoint()
end