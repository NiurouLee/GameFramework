require "homelandpet_behavior_base"

---@class HomelandPetBehaviorSwimmingPool:HomelandPetBehaviorBase
_class("HomelandPetBehaviorSwimmingPool", HomelandPetBehaviorBase)
HomelandPetBehaviorSwimmingPool = HomelandPetBehaviorSwimmingPool

---游泳这个交互行为的阶段
--- @class HomelandPetSwimStage
local HomelandPetSwimStage = {
    Coming = 1, --正在来的路上
    Entering = 2, --进入外侧点，向泳池内侧点移动
    Swimming = 3, --游泳中
    Leaving = 4, --正准备离开,向泳池内侧点移动
    Exiting = 5, --进入内侧点，向泳池外侧点移动
    Finish = 6 --完成
}
_enum("HomelandPetSwimStage", HomelandPetSwimStage)

function HomelandPetBehaviorSwimmingPool:Constructor(behaviorType, pet)
    HomelandPetBehaviorSwimmingPool.super.Constructor(self, behaviorType, pet)
    self._buildManager = self._homelandClient:BuildManager()
    self._petManager = self._homelandClient:PetManager()
    ---@type HomelandPetManager
    self._homelandPetManager = self._homelandClient:PetManager()
    ---@type HomelandPetComponentMove
    self._moveComponent = self:GetComponent(HomelandPetComponentType.Move)
    ---@type HomelandPetComponentSwim
    self._swimComponent = self:GetComponent(HomelandPetComponentType.Swim)
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)
    self._pet = pet
    ---@type UnityEngine.AI.NavMeshAgent
    self._navMeshAgent = self._pet:GetNavMeshAgent()

    --水花特效
    self._floatEffectName = "eff_yyc_yy_shuihua01.prefab"
    self._swimEffectName = "eff_yyc_yy_shuihua02.prefab"
    self._floatEffect = nil
    self._swimEffect = nil
end

function HomelandPetBehaviorSwimmingPool:Enter()
    HomelandPetBehaviorSwimmingPool.super.Enter(self)
    if self._params ~= nil then
        self._buildingset = true
    else
        self._buildingset = false
    end
    local buildings =
        self._buildManager:GetBuildingsFilter(
        function(building)
            return self:BuildingFilter(building)
        end
    )
    local buildingCount = table.count(buildings)
    if buildingCount <= 0 then
        self._pet:GetPetBehavior():RandomBehavior()
        return
    end

    local petSkinID = self._needChangeSkinID or self._pet:SkinID()
    local cfgSwimmingPoolPet = Cfg.cfg_homeland_swimming_pool_pet[petSkinID]
    self._cfgSwimmingPoolPet = cfgSwimmingPoolPet
    if not cfgSwimmingPoolPet then
        return
    end

    ---@type HomeBuilding
    local building = buildings[math.random(1, buildingCount)]
    ---@type HomelandSwimmingPool
    self._building = building

    --去泳池的目标点不从表里找交互点，从建筑中找
    self._freePath, self._insidePos, self._outsidePos = self._building:GetPathPos()
    if not self._freePath then
        self._pet:GetPetBehavior():RandomBehavior()
        return
    end

    --移动组件朝向入口
    self._moveComponent:SetTarget(self._outsidePos)
    self._stage = HomelandPetSwimStage.Coming

    --水面线，光灵的指定骨骼低于这个高度就变成游泳
    --水面线=建筑的高度+水面的高度+光灵自己的休整
    self._waterLineHeight = self._building:GetSwimmingPoolWaterHeight()

    -- 如果动作类型是游泳，重新开始游泳行为
    if self._pet:GetMotionType() == HomelandPetMotionType.Swim then
        self:OnChangeSwimStage(HomelandPetSwimStage.Swimming)
    end

    --每次重新进入游泳行为的时候 清空上一次存储的下一行为
    self._nextBehavior = nil
    self._nextBehaviorArgs = nil
end

function HomelandPetBehaviorSwimmingPool:OnChangeSwimStage(stage)
    if not self._building then
        --打开界面的时候人还在，点击UI的时候也在，点完UI，光灵在清退列表中了。此时光灵自己出泳池了
        return
    end

    self._stage = stage

    if self._stage == HomelandPetSwimStage.Leaving then
        --停止游泳行为
        self._swimComponent:Exit()

        --重新随机一条路径
        if not self._freePath then
            self._freePath, self._insidePos, self._outsidePos = self._building:GetPathPos()
        end

        self._moveComponent:Stop()
        self._moveComponent:Resting()
        self._moveComponent:SetTarget(self._insidePos)
        
    elseif self._stage == HomelandPetSwimStage.Swimming then
        --游泳开始时间
        self._startSwimTime = GameGlobal:GetInstance():GetCurrentTime()
        local swimDurationTime = self._cfgBehaviorLib.InteractLoopTime
        self._finishSwimTime = self._startSwimTime + swimDurationTime

        self._moveComponent:Stop()
        self._moveComponent:Resting()
        self._moveComponent:SetTarget(self._pet:GetPosition())

        --传参给游泳行为
        self._swimComponent:Play(self._building)
    elseif self._stage == HomelandPetSwimStage.Finish then
        self:OnFinishDoSomething()
    end
end

---正在泳池中
function HomelandPetBehaviorSwimmingPool:IsInSwimmingPool()
    return self._stage ~= HomelandPetSwimStage.Coming and self._stage ~= HomelandPetSwimStage.Finish
end

function HomelandPetBehaviorSwimmingPool:Update(dms)
    HomelandPetBehaviorSwimmingPool.super.Update(self, dms)
    --泳池没了
    if not self._building or self._building:IsDelete() then
        self:OnChangeSwimStage(HomelandPetSwimStage.Finish)
        return
    end

    if self._stage == HomelandPetSwimStage.Coming then
        if self._moveComponent.state == HomelandPetComponentState.Success then
            -- --来的路上，泳池没了
            -- if not self._building then
            --     self._pet:GetPetBehavior():RandomBehavior()
            --     return
            -- end

            --可能是其他行为导致了移动结束
            local distance = Vector3.Distance(self._pet:GetPosition(), self._outsidePos)
            if distance > 1 then
                self._moveComponent:Stop()
                self._moveComponent:Resting()
                self._moveComponent:SetTarget(self._outsidePos)
                return
            end

            --走到入口如果泳池满了就终止
            if self._building:GetSwimmingPoolIsFull() then
                self._pet:GetPetBehavior():RandomBehavior()
                return
            end

            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.OnPetBehaviorInteractingFurniture,
                true,
                self._pet,
                self._building,
                self._buildingset
            )

            --添加光灵进泳池
            self._building:AddSwimmingPet(self._pet)
            self._pet:SetInteractingBuilding(self._building)

            self._moveComponent:Stop()
            self._moveComponent:Resting()
            self._moveComponent:SetTarget(self._insidePos)
            self._stage = HomelandPetSwimStage.Entering

            --0层的1 + 2层的4 =5
            self._navMeshAgent.areaMask = 5

            --换皮肤
            if self._needChangeSkinID then
                self._pet:SetPoolAndOldSkin(self._building,self._pet:SkinID(),self._pet:ClothSkinID())
                self:ChangePetSkin(self._needChangeSkinID,self._needChangeClothSkinID)
            end

            --为光灵加载游泳动作，需要在换皮以后用泳装皮肤ID再加载
            self._pet:LoadExtraAnimation()

            ---@type UnityEngine.Animation
            self._animation = self._pet:GetAnimation()
        end
    elseif self._stage == HomelandPetSwimStage.Entering then
        self:CheckPetMotionType()
        if self._moveComponent.state == HomelandPetComponentState.Success then
            -- --来的路上，泳池没了
            -- if not self._building then
            --     self._pet:GetPetBehavior():RandomBehavior()
            --     return
            -- end

            self._stage = HomelandPetSwimStage.Swimming
            --游泳开始时间
            self._startSwimTime = GameGlobal:GetInstance():GetCurrentTime()
            local swimDurationTime = self._cfgBehaviorLib.InteractLoopTime
            self._finishSwimTime = self._startSwimTime + swimDurationTime
            --只有2层
            self._navMeshAgent.areaMask = 4
            --归还路径
            if self._freePath then
                self._building:GiveBackPath(self._freePath)
                self._freePath = nil
            end

            --水花特效
            self:ShowFloatEffect(true)

            --传参给游泳行为
            self._swimComponent:Play(self._building)
        end
    elseif self._stage == HomelandPetSwimStage.Swimming then
        self:CheckPetMotionType()
        --游泳中
        local curTime = GameGlobal:GetInstance():GetCurrentTime()
        if curTime > self._finishSwimTime then
            --停止游泳行为
            self._swimComponent:Exit()

            --重新随机一条路径
            if not self._freePath then
                self._freePath, self._insidePos, self._outsidePos = self._building:GetPathPos()
            end

            self._moveComponent:Stop()
            self._moveComponent:Resting()
            self._moveComponent:SetTarget(self._insidePos)

            self._stage = HomelandPetSwimStage.Leaving
        end
    elseif self._stage == HomelandPetSwimStage.Leaving then
        self:CheckPetMotionType()
        if self._moveComponent.state == HomelandPetComponentState.Success then
            self._stage = HomelandPetSwimStage.Exiting

            self._moveComponent:Stop()
            self._moveComponent:Resting()
            self._moveComponent:SetTarget(self._outsidePos)

            --0层的1 + 2层的4 =5
            self._navMeshAgent.areaMask = 5

        -- --水花特效
        -- self:ShowFloatEffect(false)
        -- self:ShowSwimEffect(false)
        end
    elseif self._stage == HomelandPetSwimStage.Exiting then
        self:CheckPetMotionType()
        if self._moveComponent.state == HomelandPetComponentState.Success then
            self._stage = HomelandPetSwimStage.Finish
        end
        
    elseif self._stage == HomelandPetSwimStage.Finish then
        self:OnFinishDoSomething()
    end
end

function HomelandPetBehaviorSwimmingPool:OnFinishDoSomething()
    self._buildingset = false

    if not self._building then
        return
    end

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.OnPetBehaviorInteractingFurniture,
        false,
        self._pet,
        self._building,
        self._buildingset
    )

    --删除泳池交互中的光灵
    self._building:RemovSwimmingPet(self._pet)
    self._pet:SetInteractingBuilding(nil)

    --归还路径
    if self._freePath then
        self._building:GiveBackPath(self._freePath)
        self._freePath = nil
    end
    --结束游泳
    self._navMeshAgent.areaMask = 1

    if self._moveComponent then
        self._moveComponent:Stop()
        self._moveComponent:Resting()
    end
    if self._swimComponent then
        self._swimComponent:Exit()
    end

    self._pet:SetMotionType(HomelandPetMotionType.None)
    if self._pet._petTransform.localPosition.y ~= 0 then
        self._pet._petTransform.localPosition = Vector3(0, 0, 0)
    end

    if self._animation then
        self._animation:CrossFade(HomelandPetAnimName.Stand)
    end

    --进入阶段是还没有创建这个特效的
    if self._floatEffect then
        self._floatEffect:SetActive(false)
    end
    if self._swimEffect then
        self._swimEffect:SetActive(false)
    end

    self._building = nil

    --如果在游泳中被邀请指定了下一个行为
    if self._nextBehavior  then
        if self._nextBehaviorArgs:IsMaxInteractable()then 
            self._pet:GetPetBehavior():RandomBehavior()
            return 
        end  
        --这里是原本HomelandPetBehavior:ChangeBehavior(behaviorType, args)的流程
        ---@type HomelandPetBehavior
        local behaviourMgr = self._pet:GetPetBehavior()
        behaviourMgr:OnChangeToNextBehavior(self._nextBehavior, self._nextBehaviorArgs)
        self._nextBehavior = nil
        self._nextBehaviorArgs = nil
    else
        self._pet:GetPetBehavior():RandomBehavior()
    end
end

---需要注意 这里是从游泳行为进入其他行为（比如泳池中进入交互和跟随）
function HomelandPetBehaviorSwimmingPool:Exit()
    HomelandPetBehaviorSwimmingPool.super.Exit(self)

    --归还路径
    if self._freePath then
        self._building:GiveBackPath(self._freePath)
        self._freePath = nil
    end

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.OnPetBehaviorInteractingFurniture,
        false,
        self._pet,
        self._building,
        self._buildingset
    )
    self._pet:SetInteractingBuilding(nil)
    -- if self._floatEffectResRequest then
    --     self._floatEffect = nil
    --     self._floatEffectResRequest:Dispose()
    --     self._floatEffectResRequest = nil
    -- end

    -- if self._swimEffectResRequest then
    --     self._swimEffect = nil
    --     self._swimEffectResRequest:Dispose()
    --     self._swimEffectResRequest = nil
    -- end
end

---被邀请做下一个交互行为
function HomelandPetBehaviorSwimmingPool:BeInvitedToNextBehavior(nextBehavior, args)
    self._nextBehavior = nextBehavior
    self._nextBehaviorArgs = args

    if self._stage == HomelandPetSwimStage.Coming then
        --在来泳池的路上 直接结束
        self:OnChangeSwimStage(HomelandPetSwimStage.Finish)
    elseif self._stage >= HomelandPetSwimStage.Leaving then
        --已经在离开了 什么都不做  等待自己结束就行
        -- self:OnChangeSwimStage(HomelandPetSwimStage.Finish)
    else
        --这里主要是进入中 和游泳中
        self:OnChangeSwimStage(HomelandPetSwimStage.Leaving)
    end
end

function HomelandPetBehaviorSwimmingPool:CheckPetMotionType()
    if not self._animation then
        ---@type UnityEngine.Animation
        self._animation = self._pet:GetAnimation()
    end

    local petTransform = self._pet._petTransform
    local motionType = self._pet:GetMotionType()
    --修正=当前agent坐标+胸口高度-水面高度
    local offsetPosY = self._pet:GetPosition().y + self._cfgSwimmingPoolPet.ChestHeight - self._waterLineHeight

    if motionType == HomelandPetMotionType.None then
        if offsetPosY <= 0 then
            --切换状态
            self._pet:SetMotionType(HomelandPetMotionType.Swim)
            --切换动作
            if self._animation:IsPlaying(HomelandPetAnimName.Stand) then
                self._animation:CrossFade(HomelandPetAnimName.Float)
            elseif self._animation:IsPlaying(HomelandPetAnimName.Walk) then
                self._animation:CrossFade(HomelandPetAnimName.Swim)
            elseif self._animation:IsPlaying(HomelandPetAnimName.Run) then
                self._animation:CrossFade(HomelandPetAnimName.FastSwim)
            end
        end

        if petTransform.localPosition.y ~= 0 then
            petTransform.localPosition = Vector3(0, 0, 0)
        end
    elseif motionType == HomelandPetMotionType.Swim then
        if offsetPosY > 0 then
            self._pet:SetMotionType(HomelandPetMotionType.None)

            if self._animation:IsPlaying(HomelandPetAnimName.Float) then
                self._animation:CrossFade(HomelandPetAnimName.Stand)
            elseif self._animation:IsPlaying(HomelandPetAnimName.Swim) then
                self._animation:CrossFade(HomelandPetAnimName.Walk)
            elseif self._animation:IsPlaying(HomelandPetAnimName.FastSwim) then
                self._animation:CrossFade(HomelandPetAnimName.Run)
            end

            --退出游泳状态的时候
            --水花特效
            self:ShowFloatEffect(false)
            self:ShowSwimEffect(false)
        end

        if petTransform.localPosition.y ~= -offsetPosY then
            petTransform.localPosition = Vector3(0, -offsetPosY, 0)
        end
    end
end

---@param building HomelandSwimmingPool
---@return boolean
function HomelandPetBehaviorSwimmingPool:BuildingFilter(building,noCheckfull)
    --这个建筑是泳池
    local cfgSwimmingPool = Cfg.cfg_homeland_swimming_pool[building:GetBuildId()]
    if not cfgSwimmingPool then
        return false
    end
    self._cfgSwimmingPool = cfgSwimmingPool

    --判断建筑是否解锁
    if not building:IsSwimmable() then
        return false
    end

    --该光灵是正在泳池中（泳池中被其他行为打断，再次进行判断）
    local petIsInSwimmingPool = building:PetIsInSwimmingPool(self._pet)

    --判断建筑中正在交互的光灵数量是否达到上限，走到这里的都是泳池，可以直接用泳池方法
    local swimmingPoolIsFull = building:GetSwimmingPoolIsFull()

    if not petIsInSwimmingPool and (swimmingPoolIsFull and (not noCheckfull) ) then
        return false
    end

    --判断距离
    if Vector3.Distance(self._pet:GetPosition(), building:Pos()) > cfgSwimmingPool.Range then
        return false
    end

    --需要替换的皮肤
    self._needChangeSkinID = nil

    --是否可以
    local unRestraint = false
    --没配特定皮肤，谁都可以
    if not cfgSwimmingPool.PetSkinIDs then
        unRestraint = true
    else
        --可以游泳的皮肤
        local canSwimSkinIds = {}
        local canSwimClothSkinIds = {}
        --当前光灵的所有皮肤
        ---@type pet_skin_data
        local skinsStateData = self._petModule:GetPetSkinsData(self._pet:TemplateID())
        if skinsStateData then
            local obtainedSkinInfo = skinsStateData.skin_info
            if obtainedSkinInfo then
                for _, skinInfo in pairs(obtainedSkinInfo) do
                    if skinInfo then
                        local skinPetCfg = Cfg.cfg_pet_skin {id = skinInfo.skin_id}
                        local skinIDStr = string.gsub(skinPetCfg[1].Prefab, ".prefab", "")
                        local skinID = tonumber(skinIDStr)

                        --皮肤是该建筑允许的
                        if table.icontains(cfgSwimmingPool.PetSkinIDs, skinID) then
                            table.insert(canSwimSkinIds, skinID)
                            table.insert(canSwimClothSkinIds, skinInfo.skin_id)
                        end
                    end
                end
            end
        end

        --可以游泳的皮肤大于0
        if table.count(canSwimSkinIds) > 0 then
            --当前的皮肤就是泳装皮肤
            if table.icontains(canSwimSkinIds, self._pet:SkinID()) then
            else
                --需要换装
                local swimwearIndex = math.random(1, #canSwimSkinIds)
                self._needChangeSkinID = canSwimSkinIds[swimwearIndex]
                self._needChangeClothSkinID = canSwimClothSkinIds[swimwearIndex]
            end
            unRestraint = true
        end
    end

    return unRestraint
end
---
function HomelandPetBehaviorSwimmingPool:ShowFloatEffect(visible)
    if not self._floatEffect then
        self._floatEffectResRequest =
            ResourceManager:GetInstance():SyncLoadAsset(self._floatEffectName, LoadType.GameObject)
        if self._floatEffectResRequest then
            self._floatEffect = self._floatEffectResRequest.Obj
            ---@type UnityEngine.Transform
            local tran = self._floatEffect.transform
            tran.parent = self._pet:AgentTransform()
            local offsetPosY = self._cfgSwimmingPool.WaterHeight - self._pet:GetPosition().y
            tran.localPosition = Vector3(0, offsetPosY, 0)
            tran.localRotation = Quaternion.identity
        end
    end

    if not self._floatEffect then
        return
    end

    self._floatEffect:SetActive(visible)
    -- if visible then
    --     local offsetPosY = self._cfgSwimmingPool.WaterHeight - self._pet:GetPosition().y
    --     self._floatEffect.transform.localPosition = Vector3(0, offsetPosY, 0)
    -- end
end

function HomelandPetBehaviorSwimmingPool:ShowSwimEffect(visible)
    if not self._swimEffect then
        self._swimEffectResRequest =
            ResourceManager:GetInstance():SyncLoadAsset(self._swimEffectName, LoadType.GameObject)
        if self._swimEffectResRequest then
            self._swimEffect = self._swimEffectResRequest.Obj
            self._swimEffect:SetActive(true)
            ---@type UnityEngine.Transform
            local tran = self._swimEffect.transform
            tran.parent = self._pet:AgentTransform()
            local offsetPosY = self._cfgSwimmingPool.WaterHeight - self._pet:GetPosition().y
            tran.localPosition = Vector3(0, offsetPosY, 0)
            tran.localRotation = Quaternion.identity
        end
    end

    if not self._swimEffect then
        return
    end

    self._swimEffect:SetActive(visible)
end
--切换皮肤
function HomelandPetBehaviorSwimmingPool:ChangePetSkin(SkinID,ClothSkinID)
    --小地图
    if self._pet._miniMapVisible then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.MinimapRemoveIcon,
            HomelandMapIconType.Pet,
            self._pet._data:TmpID()
        )
    end
    --特效
    local req =
        ResourceManager:GetInstance():SyncLoadAsset(
        self._cfgSwimmingPoolPet.ChangeSkinEffectName,
        LoadType.GameObject
    )
    if req then
        req.Obj:SetActive(true)
        ---@type UnityEngine.Transform
        local tran = req.Obj.transform
        tran.position = self._pet:AgentTransform().position
        tran.localRotation = Quaternion.identity
    end
    self._homelandPetManager:ChangePetSkin(self._pet, SkinID, ClothSkinID)
    --小地图
    if self._pet._miniMapVisible then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.MinimapAddIcon,
            HomelandMapIconType.Pet,
            self._pet._data:TmpID(),
            self._pet._petAgentTransform,
            self._pet
        )
    end
    --换装材质动画
    self._pet:PlayMaterialAnim("eff_yyc_hz_switch_glow")
    --所有的组件需要重新加载一下（动画组件跟随旧预制体被删了，重新添加引用）
    self._pet:ReloadBehaviorComponent()
end