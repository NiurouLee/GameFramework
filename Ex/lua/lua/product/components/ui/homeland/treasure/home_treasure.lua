--[[
    家园宝物对象
]]
_class("HomelandTreasure", Object)
HomelandTreasure = HomelandTreasure

function HomelandTreasure:Constructor(mng, birthId, info)
    self._birthID = birthId

    ---@type treasureInfo
    self._info = info
    local pos = Cfg.cfg_homeland_treasure_birth[birthId].BirthPos
    self._position = Vector3(pos[1], pos[2], pos[3])

    self:HitPos(self._position)

    self._associatePos =
        Vector3(self._position.x + info.asso_pos.x, self._position.y, self._position.z + info.asso_pos.z)

    self:HitPos(self._associatePos)

    ---@type HomelandTreasureManager
    self._treasureMng = mng

    self._objFadeCpt = nil

    self._isEnd = false
    self._isOperateUI = false
    
end

function HomelandTreasure:Dispose()
    self:ClearinteractPoint()
    ---@type InteractPointManager
    local interactPointManager = self._treasureMng:HomelandClient():InteractPointManager()
    if self._interactArea then
        interactPointManager:RemoveBuildInteractArea(self._interactArea)
    end
    if self._treasureBoard then
        self._treasureBoard:Dispose()
    end

    if self._reqDugEff ~= nil then
        self._reqDugEff:Dispose()
        self._reqDugEff = nil
    end

    self._isEnd = false
    self._pet = nil
    self.mShowEftAni = nil
end

function HomelandTreasure:Show(parent)
    local homelandClient = self._treasureMng:HomelandModule():GetUIModule():GetClient()
    self.mChar = homelandClient:CharacterManager()
    ---@type HomelandMainCharacterController
    self.mCC = self.mChar:MainCharacterController()

    self.conCfg = Cfg.cfg_homeland_treasure_content[self._info.content_id]

    --加载宝物
    self._req = ResourceManager:GetInstance():SyncLoadAsset(self.conCfg.Prefab, LoadType.GameObject)
    if not self._req then
        Log.error("找不到宝物模型:", self.conCfg.Prefab)
        return
    end

    self._objFadeCpt = self._req.Obj:GetComponent(typeof(FadeComponent))

    if self.conCfg.PrefabEffect ~= "" then
        self._reqEff = ResourceManager:GetInstance():SyncLoadAsset(self.conCfg.PrefabEffect, LoadType.GameObject)
        if not self._reqEff then
            Log.error("找不到宝物特效:", self.conCfg.PrefabEffect)
            return
        end

        self._reqEff.Obj.transform:SetParent(parent)
        self._reqEff.Obj.transform.position = self._position
        self._reqEff.Obj:SetActive(true)
    end

    ---@type UnityEngine.GameObject
    self._go = self._req.Obj
    ---@type UnityEngine.Transform
    self._transform = self._go.transform
    self._transform:SetParent(parent)
    self._transform.position = self._position
    self._go:SetActive(true)

    if self._info.content_view_id == TreasureViewType.TVT_NULL then
        --nothings
    elseif self._info.content_view_id == TreasureViewType.TVT_SIGN then
        --显示木牌
        self:ShowBoard(parent, self._info.tips_id)
    elseif self._info.content_view_id == TreasureViewType.TVT_ASSO then
        --显示光灵
        self:ShowPet(self._info.pet_id)
    end

    --注册交互点
    ---@type InteractPointManager
    local interactPointManager = self._treasureMng:HomelandClient():InteractPointManager()
    self._interactPoint = interactPointManager:AddBuildInteractPoint(self, self._birthID, InteractPointType.Treasure)
    if self._info.state == TreasureState.TS_BORN then
        self._interactArea = interactPointManager:AddBuildInteractArea(self, self:GetDetectRange())
    else
        self:MiniMapEvent()
    end
end

--
function HomelandTreasure:MiniMapEvent(isFirst)
    if self._info.content_view_id == TreasureViewType.TVT_NULL then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.MinimapAddIcon,
            HomelandMapIconType.Treasure,
            self._birthID,
            self._transform,
            isFirst
        )
    elseif self._info.content_view_id == TreasureViewType.TVT_SIGN then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.MinimapAddIcon,
            HomelandMapIconType.Treasure,
            self._birthID,
            self._transform,
            isFirst
        )
    elseif self._info.content_view_id == TreasureViewType.TVT_ASSO then
    end
end

--
function HomelandTreasure:ClearinteractPoint()
    if self._info.content_view_id == TreasureViewType.TVT_ASSO and self._pet ~= nil then
        self._pet:GetPetBehavior():ChangeBehavior(self.conCfg.AssoState)
        self._pet:SetOccupied(HomelandPetOccupiedType.None)
        self._pet = nil
    end

    ---@type InteractPointManager
    local interactPointManager = self._treasureMng:HomelandClient():InteractPointManager()
    if self._interactPoint then
        interactPointManager:RemoveBuildInteractPoint(self._interactPoint)
    end
    self._interactPoint = nil

    if self._req ~= nil then
        self._req:Dispose()
        self._req = nil
    end

    if self._reqEff ~= nil then
        self._reqEff:Dispose()
        self._reqEff = nil
    end

    self:OperateMainUI()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnRemoveMinimapIconMark, HomelandMapIconType.Treasure, self._birthID)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.MinimapRemoveIcon, HomelandMapIconType.Treasure, self._birthID)    
end

--
function HomelandTreasure:OperateMainUI()
    if self._isOperateUI == false then
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideHomelandMainUI, true, false)
    self._isOperateUI = false
end

function HomelandTreasure:GetBirthID()
    return self._birthID
end

function HomelandTreasure:GetPos()
    return self._position
end

--发现范围
function HomelandTreasure:GetDetectRange()
    local range = Cfg.cfg_homeland_global["TreasureDetectedRange"].FloatValue
    return range
end

function HomelandTreasure:GetViewType()
    return self._info.content_view_id
end

function HomelandTreasure:GetAssociatePetID()
    return self._info.petid
end

--
function HomelandTreasure:GetState()
    return self._info.state
end

--
function HomelandTreasure:GetGameObj()
    return self._req
end

--加载木牌并显示
function HomelandTreasure:ShowBoard(parent, tipsid)
    ---@type InteractPointManager
    local interactPointManager = self._treasureMng:HomelandClient():InteractPointManager()
    local board = HomelandTreasureBoard:New(interactPointManager)
    board:Show(parent, self._associatePos, self._position, tipsid)
    self._treasureBoard = board
end

--加载光灵并显示
function HomelandTreasure:ShowPet(petid)
    local petMng = self._treasureMng:HomelandClient():PetManager()
    ---@type HomelandPet
    self._pet = petMng:GetPetByPstID(petid)
    if self._pet ~= nil then
        local vvv = self._position - self._associatePos
        --self._pet_rota = Quaternion.FromToRotation(self._pet:AgentTransform().forward, vvv)
        if vvv:Magnitude() < 1e-6 then
            self._pet_rota = Vector3.zero
        else
            self._pet_rota = Quaternion.LookRotation(vvv).eulerAngles
        end

        self._pet:SetOccupied(HomelandPetOccupiedType.Treasure, self._birthID)
        self._pet:SetPosition(self._associatePos)

        self._pet:GetPetBehavior():ChangeBehavior(HomelandPetBehaviorType.TreasureIdle)
    end
end

--交互
function HomelandTreasure:InteractPoint(TT)
    --播放表现
    self.mCC:SetForbiddenMove(true)
    local anitime = self.mCC:GetAnimLength(self.conCfg.DigAnimTime) * 1000
    self.mCC:SetAnimatorTrigger(self.conCfg.DigAnim)
    AudioHelperController.PlayUISoundAutoReleaseDelay(CriAudioIDConst.HomelandAudioShowTreaseure, 0)
    local cfg = GameGlobal.GetUIModule(HomelandModule):GetCurrentToolCfg(ToolType.TT_SHOVEL)
    local eftObj = self.mCC:AttachEffect(self.conCfg.ShowEffect, self.conCfg.AttachPath)
    if eftObj ~= nil then
        self.mShowEftAni = eftObj:GetComponentInChildren(typeof(UnityEngine.Animation))
        self.mShowEftAni:Play(self.conCfg.EffectAni)
    end

    if self.conCfg.BeDugEffect ~= "" then
        self._reqDugEff = ResourceManager:GetInstance():SyncLoadAsset(self.conCfg.BeDugEffect, LoadType.GameObject)
        if not self._reqDugEff then
            Log.error("找不到挖宝宝物特效:", self.conCfg.BeDugEffect)
        end

        self._reqDugEff.Obj.transform:SetParent(self._transform.parent)
        self._reqDugEff.Obj.transform.position = self._position
        self._reqDugEff.Obj:SetActive(true)

    end

    YIELD(TT, self.conCfg.DigDelay)
    self.mCC:AttachModel(cfg.Res, cfg.AttachPath)
    local delaytime = anitime - self.conCfg.DigDelay
    YIELD(TT, delaytime)

    self:ReqTreasure(TT)
end

--走路
function HomelandTreasure:WalkPoint(TT)
    local pos = self.mChar:GetCharacterTransform().position
    local forward = (pos - self._position).normalized
    local tarfor = -forward
    local dis = Cfg.cfg_homeland_global["TreasureInteractRange"].FloatValue
    local targetpos = self._position + forward * dis

    self.mCC:NavigateToPos(TT, targetpos)
    self.mCC:SetForward(tarfor)

    local petMng = self._treasureMng:HomelandClient():PetManager()
    petMng:SetPetsVisible(false, self._info.pet_id)

    self:InteractPoint(TT)
end

--挖宝 这些交互应该放到mng里面实现，否则最后自己删除自己比较乱，但是没时间改了
function HomelandTreasure:Interact()
    if self._isEnd == true then
        return
    end

    local state = self.mCC:State()

    if state == HomelandActorStateType.Navigate or state == HomelandActorStateType.Axe or state == HomelandActorStateType.Pick  then
        return
    end

    --禁止操作 加锁
    GameGlobal.UIStateManager():Lock("HomelandTreasure:Interact")
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandSetMainCharReceiveMoveInput, false)

    if self._pet ~= nil then
        local behaviorType = self._pet:GetPetBehavior():GetCurBehaviorType()
        if behaviorType == HomelandPetBehaviorType.TreasureIdle then
            self._pet:GetPetBehavior():GetCurBehavior():ExitBubble()
        end
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideHomelandMainUI, false, false)
    self._isOperateUI = true

    -- 这里缺少摄像机变化

    TaskManager:GetInstance():StartTask(
        function(TT)
            self:WalkPoint(TT)
        end
    )
end

-- treasure
function HomelandTreasure:ReqTreasure(TT)
    --请求服务器
    local res, assets =
        self._treasureMng:HomelandModule():HomelandChangeTreasureState(TT, self._birthID, TreasureState.TS_GRAB)
    if res:GetSucc() then
        --发送UI 事件，奖励弹框
        GameGlobal.UIStateManager():UnLock("HomelandTreasure:Interact")
        GameGlobal.UIStateManager():ShowDialog(
            "UIHomeShowAwards",
            assets,
            function()
                self:ReqTreasureEnd()
            end
        )
    else
        self.mCC:ReleaseAttachedEffect(self.conCfg.ShowEffect)
        self.mCC:SetForbiddenMove(false)
        self.mCC:ReleaseAttachedModel()

        self:OperateMainUI()
        -- if self._pet ~= nil then
        --     self._pet:GetPetBehavior():ChangeBehavior(HomelandPetBehaviorType.TreasureIdle)
        -- end

        GameGlobal.UIStateManager():UnLock("HomelandTreasure:Interact")
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandSetMainCharReceiveMoveInput, true)
    end
end

function HomelandTreasure:ReqTreasureEnd()
    GameGlobal.UIStateManager():Lock("HomelandTreasure:ReqTreasureEnd")

    if self._pet ~= nil then
        local cfgHome = Cfg.cfg_homeland_pet[self._pet:TemplateID()]
        if cfgHome ~= nil and cfgHome.HappyAnim ~= nil and cfgHome.HappyAnim ~= "" then
            ---@type HomelandPetComponentPlayAnimation
            self._animationComponent =
                self._pet:GetPetBehavior():GetCurBehavior():GetComponent(HomelandPetComponentType.Animation)
            self._animationComponent:Play(cfgHome.HappyAnim)
            self._animationComponent:Resting()
        end
    end

    TaskManager:GetInstance():StartTask(
        function(TT)
            if self.conCfg.UIDelay > 0 then
                YIELD(TT, self.conCfg.UIDelay)
            end

            local anitime = self.mCC:GetAnimLength(self.conCfg.OverAnimTime) * 1000
            self.mCC:SetAnimatorTrigger(self.conCfg.OverAnim)

            if self.mShowEftAni ~= nil then
                self.mShowEftAni:Play(self.conCfg.EffectAniOver)
            end

            local addtime = 0
            local updatetime = 40
            local aptime = 1 / anitime --消失的速率
            local dodtime = self.conCfg.DigOverDelay
            while (addtime < anitime) do
                addtime = addtime + updatetime
                if dodtime ~= 0 and addtime >= dodtime then
                    self.mCC:ReleaseAttachedModel()
                    dodtime = 0
                end

                self._objFadeCpt.Alpha = 1 - addtime * aptime

                YIELD(TT, updatetime)
            end

            self._objFadeCpt.Alpha = 0

            --人物动作的时间，应该是大于特效的动画，时间，这里就不做时间差了
            self.mCC:ReleaseAttachedEffect(self.conCfg.ShowEffect)
            self.mCC:SetForbiddenMove(false)

            local petMng = self._treasureMng:HomelandClient():PetManager()
            petMng:SetPetsVisible(true)

            GameGlobal.UIStateManager():UnLock("HomelandTreasure:ReqTreasureEnd")
            GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandSetMainCharReceiveMoveInput, true)
            self._isEnd = true
            self:ClearinteractPoint()
        end
    )
end

--交互点中点
function HomelandTreasure:GetInteractPosition()
    return self._transform.position
end

--红点
function HomelandTreasure:GetInteractRedStatus()
    return false
end

--pet朝向
function HomelandTreasure:GetPetRota()
    return self._pet_rota
end

--交互区域的中点
function HomelandTreasure:GetInteractAreaPosition()
    return self._transform.position
end

--进入区域行为
function HomelandTreasure:EnterInteractArea()
    self._interactArea:SetActive(false)

    --gameevent 发现宝物，提示文本，地图红点
    local viewType = self:GetViewType()
    if viewType == TreasureViewType.TVT_NULL then
        local param = {StringTable.Get("str_homeland_normal_treasure_tips")}
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.Tex, param)
    elseif viewType == TreasureViewType.TVT_SIGN then
        local param = {StringTable.Get("str_homeland_board_treasure_tips")}
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.Tex, param)
    elseif viewType == TreasureViewType.TVT_ASSO then
        local pet = GameGlobal.GetModule(PetModule):GetPet(self._info.pet_id)
        local icon = HelperProxy:GetInstance():HomeGetBody(self._info.pet_id)
        local name = StringTable.Get(pet:GetPetName())
        local param = {icon, StringTable.Get("str_homeland_pet_treasure_tips", name)}
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIHomeEventTips, UIHomeEventTipsType.PetBody, param)
    end

    TaskManager:GetInstance():StartTask(
        function(TT)
            local res =
                self._treasureMng:HomelandModule():HomelandChangeTreasureState(TT, self._birthID, TreasureState.TS_FIND)
            if res:GetSucc() then
                self._info.state = TreasureState.TS_FIND

                self:MiniMapEvent(true)
            end
        end
    )
end
function HomelandTreasure:LeaveInteractArea()
end

--如果有碰撞点，把碰撞点赋值给配置坐标
--使用这个方法，策划不用配置坐标的y值了
function HomelandTreasure:HitPos(pos)
    local hitdis = 8
    local hit = UnityEngine.AI.NavMeshHit:New()
    local _canStart, _hit = UnityEngine.AI.NavMesh.SamplePosition(pos, hit, hitdis, UnityEngine.AI.NavMesh.AllAreas)
    if _canStart then
        pos.x = _hit.position.x
        pos.y = _hit.position.y
        pos.z = _hit.position.z
    end
end

---@return UnityEngine.GameObject
function HomelandTreasure:GameObject()
    return self._go
end
