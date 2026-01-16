require "bounce_obj_mgr"
--对局控制器
---@class BounceController : Object
_class("BounceController", Object)
BounceController = BounceController

function BounceController:Constructor()
    --对局数据
    ---@type BounceData
    self.bounceData = BounceData:New()

    --怪物对象池
    ---@type BounceMonsterPool
    self.monsterPool = BounceMonsterPool:New()

    --对象管理
    ---@type BounceObjMgr
    self.objMgr = BounceObjMgr:New()

    --怪物生成器
    ---@type MonsterGenerator[]
    self.monsterGenerator = {}

    self.firstGuideStepPositionKeys=
    {
        "guide1180082",
        "guide1180083",
        "guide1180085",
        "guide1180086",
        "guide1180087",
    }

    self.secondGuideStepPositionKeys=
    {
        "guide1180092",
        "guide1180093",
        "guide1180094",
    }

    self.guideModule = GameGlobal.GetModule(GuideModule)
end

function BounceController:Init(uiController, levelId, selectPlayer, historyBestScore)
    ---@type UIBounceMainController
    self.uiController = uiController
    self.bounceData:Init(levelId, selectPlayer, historyBestScore)
    MonsterFactory.Init()
    EffectManager.Init()
    --objMgr
    self.objMgr:Init(self)

    self.uiController:SetViewVisibleByBouceState(StateBounce.Init)

    --fsm
    self.fsm = StateMachineManager:GetInstance():CreateStateMachine("StateBounce", StateBounce)
    self.fsm:SetData(self) -- 上下文
    self.fsm:Init(StateBounce.Init)
end


function BounceController:OnQuick()
    self.fsm:SetData(nil)
    StateMachineManager:GetInstance():DestroyStateMachine(self.fsm.Id)
    self.fsm = nil
    MonsterFactory.Destroy()
    EffectManager.Destroy()
    BouncePlayerData.DebugIns = nil
end

function  BounceController:OnRestartGame()
    self.objMgr:Reset()
    self:ChgFsmState(StateBounce.Prepare)
end

function BounceController:GetData()
   return self.bounceData 
end

---@return UIBounceMainController
function BounceController:GetUIController()
    return self.uiController
end

---@return BounceObjMgr
function BounceController:GetObjMgr()
    return self.objMgr
end

---@return BounceMonsterPool
function BounceController:GetMonsterPool()
    return self.monsterPool
end

---@return MonsterGenerator[]
function BounceController:GetMonsterGenerator()
    return self.monsterGenerator
end

---@return UnityEngine.RectTransform
function BounceController:GetObjectsRoot()
    return self.uiController:GetCanvasRt()
end

function BounceController:IsOvering()
    return self.bounceData.isOvering
end

----战斗时间轴更新
function BounceController:OnUpdate(deltaTimeMS)
    EffectManager.Update(deltaTimeMS)
    if self.bounceData.isGuiding and   GuideHelper.IsUIGuideShow() then
        return
    end

    if self.bounceData.isGuiding  then
        local isGuiding = self.guideModule:IsGuideProcess(self.bounceData.guidingId)
        self.bounceData:SetIsGuiding(isGuiding)
    end

    if self.bounceData.isOvering then
       self.bounceData.overTime = self.bounceData.overTime - deltaTimeMS
       if self.bounceData.overTime <= 0 then
            self.bounceData.isOvering = false
            local params = self:GetOverParam()
            self:ChgFsmState(StateBounce.Over, params)
            return
       end
    end

    if self.fsm then
        self.fsm:OnUpdate(deltaTimeMS)
    end
end

--jump cmd
function BounceController:OnJump(fromPC)
    if self.bounceData.isGuiding and   not GuideHelper.IsUIGuideShow() then
        return
    end

    if self.bounceData.isOvering then
        return
    end
    if fromPC and self.bounceData.isGuiding then
        local res = self:CheckKeyOperate("JumpBtn")
        if not res then
            return
        end
    end

    local curState = self.fsm:GetCurState()
    curState:OnJump()
end

--attack cmd
function BounceController:OnAttack(fromPC)
    if self.bounceData.isGuiding and   not GuideHelper.IsUIGuideShow() then
        return
    end

    if self.bounceData.isOvering then
        return
    end

    if fromPC and self.bounceData.isGuiding then
        local res = self:CheckKeyOperate("AttackBtn")
        if not res then
            return
        end
    end

    local curState = self.fsm:GetCurState()
    curState:OnAttack()
end

function BounceController:CheckKeyOperate(btnEvent)
    local guides = self.guideModule:GetCurGuides()
    if not guides then
        return false
    end
    for _, guide in pairs(guides) do
        ---@type GuideStep
        local curStep = guide:GetCurStep()
        if curStep and curStep.show and curStep.btnGuideCfg and curStep.btnGuideCfg.guideArea == btnEvent then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ForceFinishGuideStep, GuideType.Button)
            return true
        end
    end
    
    return false
end

--统一的改变状态机状态的接口
function BounceController:ChgFsmState(newState, params)
    Log.debug("[bounce] BounceController chgfsmState " .. newState)
    if not self.fsm then
        return
    end
    self.uiController:SetViewVisibleByBouceState(newState, params)
    self.fsm:ChangeState(newState)
end

function BounceController:GetPlayerPrefabName()
        return self.bounceData.palyerRes
end

---怪物死亡
function BounceController:MonsterDead(monsterId)
    local monsterCfg = Cfg.cfg_bounce_monster[monsterId]
    if not monsterCfg then
        return nil
    end
    if monsterCfg.Score then
        self:AddScore(monsterCfg.Score)
    end
    self.uiController:MonsterDead(monsterId)

    --检测结算逻辑
    if self.bounceData.targetMonster > 0  then --杀死目标结算
        if  self.bounceData.targetMonster == monsterId then
            self:StartOver()
            self.bounceData:SetKilledBoss(true)
        end
    else
        if self.bounceData.targetScore <= self.bounceData.score then --达到积分结算
            self:StartOver()
            return
        end
    end
    
    if not self.bounceData.hasGenBoss and self.bounceData.genBossId  and self.bounceData.genBossScore <= self.bounceData.score then
        self.bounceData.hasGenBoss = true
        --产生boss
        local monsterId = self.bounceData.genBossId
        local monster = self.monsterPool:Get(monsterId)
        --SetMonster values
        monster:SetCoreController(self)
        ---@type MonsterBeHaviorView
        local view = monster:GetBehavior(MonsterBeHaviorView.Name())
        if view then
            view:SetParent(self:GetObjectsRoot())
        end
        ---@type MonsterBeHaviorPosition
        local posBehaviour = monster:GetBehavior(MonsterBeHaviorPosition.Name())
        if posBehaviour then
            posBehaviour:SetPosition(self.bounceData.genBossPos)
        end

        self.objMgr:AddMonster(monster)

        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneAccBossEnter)
       
        if self.bounceData.levelId == 6 and not self.guideModule:IsGuideDone(BounceConst.GuideBoss1) then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIBounceMainControllerBoss1)
            self.bounceData.guidingId = BounceConst.GuideBoss1
            local isGuiding = self.guideModule:IsGuideProcess(BounceConst.GuideBoss1)
            self.bounceData:SetIsGuiding(isGuiding)
        end
    end
end

--开始结算
function BounceController:StartOver()
    self.bounceData.isOvering = true
    self.bounceData.overTime = 2000 --ms
end

function BounceController:GetOverParam()
    local param = {}
    param.Score = self.bounceData.score;
    param.HistoryBestScore = self.bounceData.historyBestScore
end

---增加积分
function BounceController:AddScore(score)
    self.bounceData:AddScore(score)
   -- self.bounceData:AddHistoryBestScore()
    self.uiController:ScoreChange(self.bounceData:GetScore())
end

--显示血条
function BounceController:ShowHPProgress(serializeId, maxValue)
    self.uiController:ShowHPProgress(serializeId, maxValue)
end

--隐藏血条
function BounceController:HideHPProgress(serializeId)
    self.uiController:HideHPProgress(serializeId)
end

--血条数据变化
function BounceController:HPProgressChange(serializeId, currentValue, maxValue)
    self.uiController:HPProgressChange(serializeId, currentValue, maxValue)
end

--血条数据变化
function BounceController:GetGameData()
    return self.bounceData
end

function BounceController:GetGuideRt(guideStepKey)
    return self.uiController:GetGuideRt(guideStepKey)
end

function BounceController:SetGuideStepShow(guideStepKey)
    self.uiController:SetGuideStepShow(guideStepKey)
end

function BounceController:SetGuidePosition(key, position)
    self.uiController:SetGuidePosition(key, position)
end

function BounceController:OnTrigerGuideStep(guideStepKey)
    Log.debug("[bounce] Guide_CheckMonsterPosition " .. guideStepKey)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.N28BounceGameArriveTarget, guideStepKey)
    self:SetGuideStepShow(guideStepKey)
end