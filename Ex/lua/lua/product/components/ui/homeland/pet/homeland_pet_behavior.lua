---@class HomelandPetBehavior:Object
_class("HomelandPetBehavior", Object)
HomelandPetBehavior = HomelandPetBehavior

function HomelandPetBehavior:Constructor(pet)
    ---@type HomelandPet
    self._pet = pet
    ---@type table<HomelandPetBehaviorType, HomelandPetBehaviorBase>
    self._allBehaviors = {}
    ---@type HomelandPetBehaviorBase
    self._curBehavior = nil
    ---@type HomelandClient
    self._homelandClient = self._pet:GetHomelandClient()
    ---@type HomelandPetBehaviorFactory
    self._behaviorFactory = self._homelandClient:PetManager():GetBehaviorFactory()
    self._totalWeight = 0
    self._weightArray = {}
    self._cfgBehavior = Cfg.cfg_homeland_pet[self._pet:TemplateID()]
    self:_InitBehaviors()
    ---@type table<HomelandPetBehaviorType, number>
    self._coolingBehaviors = {}
    self._tempCoolingBehaviorTypes = {}
    self._curBehaviorArgs = {}  --当前状态参数
    self._lastBehaviorArgs = {}  --上个状态的参数
    self._storyArg = {}  --Story参数
    self._storyCallback = nil --story回调
end
--初始化一个pet所拥有的行为
function HomelandPetBehavior:_InitBehaviors()
    if not self._cfgBehavior then
        Log.error("Homeland Pet No Behavior Cfg.", self._pet:TemplateID())
        return
    end
    for _, behaviorTypeWeight in pairs(self._cfgBehavior.Behaviors) do
        ---@type HomelandPetBehaviorType
        local behaviorType = behaviorTypeWeight[1]
        if not self._allBehaviors[behaviorType] then
            self._allBehaviors[behaviorType] = self._behaviorFactory:CreateHomelandPetBehavior(behaviorType, self._pet)
        end
    end
end

---@param behaviorType HomelandPetBehaviorType
function HomelandPetBehavior:GetHomelandPetBehavior(behaviorType)
    return self._allBehaviors[behaviorType]
end

---在光灵更换皮肤后，需要对所有行为的所有组件重新添加引用关系
function HomelandPetBehavior:ReloadBehaviorComponent()
    for _, behavior in pairs(self._allBehaviors) do
        behavior:ReLoadBehaviorComponent()
    end
end

function HomelandPetBehavior:Update(deltaTime)
    if not self._curBehavior then
        return
    end
    self:_UpdateCoolingBehavior(deltaTime)
    if self._curBehavior:Done() then
        self:_RandomBehavior()
    end
    self._curBehavior:Update(deltaTime)
end

function HomelandPetBehavior:RandomBehavior()
    self:_RandomBehavior()
end

--随机行为, 默认free
function HomelandPetBehavior:_RandomBehavior()
    if self._pet:IsOccupied() then
        local tb = {
            [HomelandPetOccupiedType.Treasure] = HomelandPetBehaviorType.TreasureIdle,
            [HomelandPetOccupiedType.StoryWaiting] = HomelandPetBehaviorType.StoryWaitingStand
        }
        local occupiedType = self._pet:GetOccupiedType()
        local behaviorType = tb[occupiedType]
        if behaviorType then
            self:ChangeBehavior(behaviorType)
            return
        end
    end
    
    if not self._cfgBehavior then
        return
    end
    if self._curBehavior then
        local cfg = self._curBehavior:GetCfg()
        if cfg.NextBehaviorType then
            self:ChangeBehavior(cfg.NextBehaviorType)
            return
        end
    end
    local behaviorType = HomelandPetBehaviorType.Free
    local totalWeight = self:_GetTotalWeight()
    if totalWeight > 0 then
        local randomWeight = math.random(1, totalWeight)
        for _type, _weight in pairs(self._weightArray) do
            if randomWeight > _weight[1] and randomWeight <= _weight[2] then
                behaviorType = _type
                break
            end
        end
    end
    self:ChangeBehavior(behaviorType)
end
function HomelandPetBehavior:_GetTotalWeight()
    self._totalWeight = 0
    self._weightArray = {}
    for _, _typeWeight in pairs(self._cfgBehavior.Behaviors) do
        if not self:InCooling(_typeWeight[1]) and _typeWeight[2] > 0 then
            local weight = self._totalWeight + _typeWeight[2]
            self._weightArray[_typeWeight[1]] = {self._totalWeight, weight}
            self._totalWeight = weight
        end
    end
    return self._totalWeight
end
function HomelandPetBehavior:StartBehavior(behaviorType)
    if behaviorType then
        self:ChangeBehavior(behaviorType)
    else
        self:_RandomBehavior()
    end
end

--改变光灵行为的唯一指定接口
---@param behaviorType HomelandPetBehaviorType
function HomelandPetBehavior:ChangeBehavior(behaviorType, args, isInteract, index)
    local nextBehavior = self._allBehaviors[behaviorType]
    if not nextBehavior then
        Log.error("HomelandPet Have't This Behavior. behaviorType:", behaviorType)
        return
    end
    self._lastBehaviorArgs = self._curBehaviorArgs
    self._curBehaviorArgs = {behaviorType = behaviorType,args = args,isInteract = isInteract,index = index}
    self:_AddCoolingBehavior(nextBehavior)
    if not self._curBehavior then
        self._curBehavior = nextBehavior
        self._curBehavior:OnEnter(args, index)
        self._curBehavior:Enter()
    else
        if self._curBehavior:CanInterrupt() then
            --被邀请打断 and 并且当前是游泳
            if isInteract and self._curBehavior:GetBehaviorType() == HomelandPetBehaviorType.SwimmingPool then
                --当前是游泳行为不能直接退出，需要执行泳池行为里的退出流程，然后在游泳行为里判断有下一个指定行为再执行
                self._curBehavior:BeInvitedToNextBehavior(nextBehavior, args)
                --不执行下面的改变行为
                return
            end
            
            self._curBehavior:Exit()
            self._curBehavior = nextBehavior
            self._curBehavior:OnEnter(args, index)
            self._curBehavior:Enter()
        else
            --Log.error("HomelandPet Cur Behavior Can't Interrupt !", self._curBehavior:GetBehaviorType())
        end
    end
    self._pet:OnBehaviorChanged()
end
function HomelandPetBehavior:CanChange(behaviorType)
    return self._curBehavior and self._curBehavior:CanInterrupt()
end
---一些行为不能被直接打断exit，需要把下个行为传过去，等待该行为自己结束后，回来执行改变到下个行为（游泳）
function HomelandPetBehavior:OnChangeToNextBehavior(nextBehavior, args)
    self._curBehavior = nextBehavior
    self._curBehavior:OnEnter(args)
    self._curBehavior:Enter()
    self._pet:OnBehaviorChanged()
end
function HomelandPetBehavior:Dispose()
    for _, behavior in pairs(self._allBehaviors) do
        behavior:Dispose()
    end
    self._allBehaviors = nil
    self._curBehavior = nil
    self._coolingBehaviors = nil
end
--将状态设置成上一个状态
function HomelandPetBehavior:RecoverBehaviorToLast()
    if self._lastBehaviorArgs then
        local args = self._lastBehaviorArgs
        self:ChangeBehavior(args.behaviorType,args.args,args.isInteract,args.index)
        if self._storyCallback and 
            (args.behaviorType == HomelandPetBehaviorType.StoryWaitingBuild 
            or HomelandPetBehaviorType.StoryWaitingBuildStand 
            or HomelandPetBehaviorType.StoryWaitingStand
            or HomelandPetBehaviorType.StoryWaitingWalk) then
            local storyArgs = self._storyArg
            self._storyCallback(storyArgs.furniture,storyArgs.interactID,storyArgs.id)
        end
    else
        Log.fatal("没有上一个状态！")
    end
end
--设置Story的参数
function HomelandPetBehavior:SetStoryBehaviorArgs(args,callback)
    self._storyArg = args
    self._storyCallback = callback
end
function HomelandPetBehavior:GetCurBehavior()
    return self._curBehavior
end
function HomelandPetBehavior:GetHasBehaviors()
    return self._allBehaviors ~= nil
end

---@return HomelandPetBehaviorType
function HomelandPetBehavior:GetCurBehaviorType()
    return self._curBehavior and self._curBehavior:GetBehaviorType()
end

---@param behavior HomelandPetBehaviorBase
function HomelandPetBehavior:_AddCoolingBehavior(behavior)
    if not behavior then
        return
    end
    ---@type HomelandPetBehaviorType
    local behaviorType = behavior:GetBehaviorType()
    if self._coolingBehaviors[behaviorType] then
        Log.info("Homeland Pet Behavior In Cooling.", behaviorType)
        return
    end
    if behavior:CD() <= 0 then
        return
    end
    self._coolingBehaviors[behaviorType] = behavior:CD()
end

function HomelandPetBehavior:_UpdateCoolingBehavior(deltaTime)
    if table.count(self._coolingBehaviors) <= 0 then
        return
    end
    table.clear(self._tempCoolingBehaviorTypes)
    for _behaviorType, _ in pairs(self._coolingBehaviors) do
        if self._curBehavior:GetBehaviorType() ~= _behaviorType then
            self._coolingBehaviors[_behaviorType] = self._coolingBehaviors[_behaviorType] - deltaTime
            if self._coolingBehaviors[_behaviorType] <= 0 then
                table.insert(self._tempCoolingBehaviorTypes, _behaviorType)
            end
        end
    end
    if #self._tempCoolingBehaviorTypes > 0 then
        for _, behaviorType in pairs(self._tempCoolingBehaviorTypes) do
            self._coolingBehaviors[behaviorType] = nil
        end
    end
end

---@param behaviorType HomelandPetBehaviorType
function HomelandPetBehavior:InCooling(behaviorType)
    return self._coolingBehaviors[behaviorType]
end
