--[[------------------------------------------------------------------------------------------
    AnimatorControllerComponent : 动画控制组件通过给Animator设置bool或trigger参数来控制动画状态机
]] --------------------------------------------------------------------------------------------

_class("AnimatorControllerComponent", Object)
---@class AnimatorControllerComponent: Object
AnimatorControllerComponent = AnimatorControllerComponent

function AnimatorControllerComponent:Constructor(triggerTable, boolTable, needDirToBoolTable,layerWeightTable)
    ---@type table<int,string>  要执行的Trigger列表
    self.AniTriggerTable = triggerTable or {}
    ---@type table<string,boolean>  要执行的Bool列表
    self.AniBoolTable = boolTable or {}
    ---@type bool  需要旋转控制动作的bool参数
    self.AniNeedDirToBoolTable = needDirToBoolTable or false
    self._LastHitAnimationTime = 0
    self.AnimatorLayerWeightTable = layerWeightTable or {}

    --AnimatorLayerWeightTable 在AnimatorControllerSystem_Render:HandleEntity执行后会清除
    --早苗等切换动作形态的光灵 隐藏再显示后动作形态不对
    self.bKeepAnimatorLayerWeight = false
    --指定找anim组件的节点名 --仲胥 猫
    self.specialAnimRoot = nil

    self.linkAnimatorEntityArray = {}
end

---@param currentTimeMs number 当前的时刻 毫秒
function AnimatorControllerComponent:IsNeedHitAnimation(currentTimeMs)
    local lastTime = self._LastHitAnimationTime

    if currentTimeMs - lastTime > BattleConst.HitAnimationIntervalMs then
        self._LastHitAnimationTime = currentTimeMs
        return true
    else
        return false
    end
end

function AnimatorControllerComponent:AddLinkAnimatorEntity(e)
    table.insert(self.linkAnimatorEntityArray, e)
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return AnimatorControllerComponent
function Entity:AnimatorController()
    return self:GetComponent(self.WEComponentsEnum.AnimatorController)
end

function Entity:HasAnimatorController()
    return self:HasComponent(self.WEComponentsEnum.AnimatorController)
end

function Entity:AddAnimatorController(triggerTable, boolTable)
    local index = self.WEComponentsEnum.AnimatorController
    local component = AnimatorControllerComponent:New(triggerTable, boolTable)
    self:AddComponent(index, component)
end

function Entity:SetAnimatorControllerTriggers(triggerTable)
    if table.count(triggerTable) <= 0 then --传空表不作处理，防止后执行的技能表现中动画为空导致动画不播的问题
        return
    end
    local index = self.WEComponentsEnum.AnimatorController
    local component = self:AnimatorController()
    if component then
        component.AniTriggerTable = triggerTable
        for _, e in ipairs(component.linkAnimatorEntityArray) do
            e:SetAnimatorControllerTriggers(triggerTable)
        end
        self:ReplaceComponent(index, component)
    else
        local component = AnimatorControllerComponent:New(triggerTable)
        self:ReplaceComponent(index, component)
    end
end

---@param boolTable table 键值为string和boolean的table
function Entity:SetAnimatorControllerBools(boolTable)
    local index = self.WEComponentsEnum.AnimatorController
    local component = self:AnimatorController()
    if component then
        for param, value in pairs(boolTable) do
            component.AniBoolTable[param] = value
        end
        for _, e in ipairs(component.linkAnimatorEntityArray) do
            local c = e:AnimatorController()
            for param, value in pairs(boolTable) do
                c.AniBoolTable[param] = value
            end
        end
        self:ReplaceComponent(index, component)
    else
        local component = AnimatorControllerComponent:New({}, boolTable)
        self:ReplaceComponent(index, component)
    end
end

---2020-01-06 韩玉信添加：返回动画配置BOOL数组的值
---@param stBoolParam string
---table<string, boolean> 参数名为key bool为value的table
function Entity:GetAnimatorControllerBoolsData(stBoolParam)
    ---@type AnimatorControllerComponent
    local component = self:AnimatorController()
    if component then
        for param, value in pairs(component.AniBoolTable) do
            if param == stBoolParam then
                return value
            end
        end
    end
    return nil
end

function Entity:RemoveAnimatorController()
    if self:HasAnimatorController() then
        self:RemoveComponent(self.WEComponentsEnum.AnimatorController)
    end
end

function Entity:IsNeedHitAnimation(currentTimeMs)
    if self:HasAnimatorController() then
        local component = self:AnimatorController()
        return component:IsNeedHitAnimation(currentTimeMs)
    end
    return true
end

---播放被击动作
function Entity:SetHitAnimatorControllerTriggers(triggerTable)
    ---@type TimeService
    local timeService = self:GetOwnerWorld():GetService("Time")
    local currentTimeMs = timeService:GetCurrentTimeMs()

    local index = self.WEComponentsEnum.AnimatorController
    local component = self:AnimatorController()
    if component then
        if self:IsNeedHitAnimation(currentTimeMs) then
            component.AniTriggerTable = triggerTable
            self:ReplaceComponent(index, component)

            for _, e in ipairs(component.linkAnimatorEntityArray) do
                e:SetHitAnimatorControllerTriggers(triggerTable)
            end
        end
    else
        local component = AnimatorControllerComponent:New(triggerTable)
        self:ReplaceComponent(index, component)
    end
end
---@param layerWeightTable table key是layerIndex，value是weight
function Entity:SetAnimatorLayerWeight(layerWeightTable)
    local index = self.WEComponentsEnum.AnimatorController
    local component = self:AnimatorController()
    if component then
        for param, value in pairs(layerWeightTable) do
            component.AnimatorLayerWeightTable[param] = value
        end
        self:ReplaceComponent(index, component)

        for _, e in ipairs(component.linkAnimatorEntityArray) do
            e:SetAnimatorLayerWeight(layerWeightTable)
        end
    else
        local component = AnimatorControllerComponent:New({}, {},nil,layerWeightTable)
        self:ReplaceComponent(index, component)
    end
end
function Entity:SetKeepAnimatorLayerWeight(bKeep)
    local index = self.WEComponentsEnum.AnimatorController
    local component = self:AnimatorController()
    if component then
        component.bKeepAnimatorLayerWeight = bKeep
        self:ReplaceComponent(index, component)

        for _, e in ipairs(component.linkAnimatorEntityArray) do
            e:SetKeepAnimatorLayerWeight(bKeep)
        end
    else
        local component = AnimatorControllerComponent:New({}, {},nil,nil)
        component.bKeepAnimatorLayerWeight = bKeep
        self:ReplaceComponent(index, component)
    end
end
function Entity:SetSpecialAnimRoot(specialRoot)
    local index = self.WEComponentsEnum.AnimatorController
    local component = self:AnimatorController()
    if component then
        component.specialAnimRoot = specialRoot
        self:ReplaceComponent(index, component)

        --这俩功能没放在一起过，看上去应该也不是能联动的东西，暂时注掉了
        --for _, e in ipairs(component.linkAnimatorEntityArray) do
        --    e:SetSpecialAnimRoot(specialRoot)
        --end
    else
        local component = AnimatorControllerComponent:New({}, {},nil,nil)
        component.specialAnimRoot = specialRoot
        self:ReplaceComponent(index, component)
    end
end