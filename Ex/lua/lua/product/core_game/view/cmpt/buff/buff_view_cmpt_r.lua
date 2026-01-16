--[[
    buff表现组件，与buff触发相关的表现
]]
_class("BuffViewComponent", Object)
---@class BuffViewComponent:Object
BuffViewComponent = BuffViewComponent

function BuffViewComponent:Constructor()
    self._viewInstanceArray = {}
    self._viewData = {}

    ---锁血相关
    self._lockIndex = 0
    self._lockGSMState = 0
    ---@type number
    self._lockHpRoundIndex = 0
    self._isAlwaysHPLock = false
    ---锁血相关
end

function BuffViewComponent:AddBuffViewInstance(viewInstance)
    table.insert(self._viewInstanceArray, viewInstance)
end

---@param buffViewInstance BuffViewInstance
function BuffViewComponent:RemoveBuffViewInstance(buffViewInstance)
    table.removev(self._viewInstanceArray, buffViewInstance)
    Log.debug("RemoveBuffViewInstance() entity=", self._entity:GetID(), " buffseq=", buffViewInstance:BuffSeq())
end

function BuffViewComponent:GetBuffViewInstanceArray()
    return self._viewInstanceArray
end

---@return BuffViewInstance|nil
function BuffViewComponent:GetBuffViewInstance(seq)
    for i, buffView in ipairs(self._viewInstanceArray) do
        if buffView:BuffSeq() == seq then
            return buffView
        end
    end
end

--根据效果类型获取第一个buffViewInstance
function BuffViewComponent:GetSingleBuffByBuffEffect(et)
    for i, buffView in ipairs(self._viewInstanceArray) do
        if buffView:GetBuffEffectType() == et then
            return buffView
        end
    end
    return nil
end

function BuffViewComponent:HasBuffEffect(et)
    for i, buffView in ipairs(self._viewInstanceArray) do
        if buffView:GetBuffEffectType() == et then
            return true
        end
    end
    return false
end

----region 锁血
function BuffViewComponent:GetHPLockIndex()
    return self._lockIndex
end

function BuffViewComponent:ResetHPLockState()
    self._lockHpRoundIndex = 0
    self._lockIndex = 0
    self._lockGSMState = 0
end

function BuffViewComponent:IsAlwaysHPLock()
    return self._isAlwaysHPLock
end

function BuffViewComponent:AddHpLockState(roundIndex, lockIndex, lockGSMState, isAlwaysHPLock,lockHPType, unlockHPIndex)
    self._lockHpRoundIndex = roundIndex
    self._lockIndex = lockIndex
    self._lockGSMState = lockGSMState
    self._isAlwaysHPLock = isAlwaysHPLock
    self._lockHPType = lockHPType
    self._unlockIndex = unlockHPIndex
end

function BuffViewComponent:GetUnlockHPIndex()
    return self._unlockIndex
end

function BuffViewComponent:IsHPNeedUnLock(roundIndex, nowGSMState)
    if self:IsAlwaysHPLock() then
        return false
    end
    if roundIndex and self._lockHpRoundIndex ~= 0 and self._lockHpRoundIndex == roundIndex then
        if self._lockGSMState == GameStateID.MonsterTurn then
            if self._lockHPType == LockHPType.MonsterTurnUnLock then
                return true
            end
            if self._lockGSMState == nowGSMState then
                return true
            end
        else
            return true
        end
    end
    return false
end
---endregion 锁血
--获得可以展示的buff列表
--该列表使用ID排重，只用了buff表里的是否显示字段
--onBlood表示在血条上显示护盾  特殊处理
---@param onBlood boolean
function BuffViewComponent:GetBuffViewShowList(onBlood)
    local buffIDList = {}
    local showList = {}

    for i, buffView in ipairs(self._viewInstanceArray) do
        local isShowBuffIcon = self:_GetBuffShowBuffIcon(buffView, onBlood)
        local canShowBuff = self:_GetShowBuffLayer(buffView)

        --不重复的ID and 配表显示图标
        if not table.intable(buffIDList, buffView:BuffID()) and isShowBuffIcon and canShowBuff then
            table.insert(buffIDList, buffView:BuffID())
            table.insert(showList, buffView)
        end
    end
    return showList
end

---@param buffView BuffViewInstance
---@param onBlood boolean
function BuffViewComponent:_GetBuffShowBuffIcon(buffView, onBlood)
    local onBloodShowLayerShield = onBlood and true or buffView:GetBuffEffectType() ~= BuffEffectType.LayerShield
    local buffShowBuffIcon = buffView:BuffConfigData():GetBuffShowBuffIcon()

    return onBloodShowLayerShield and buffShowBuffIcon
end

--获得UI队伍状态需要展示的buff列表
--该列表使用ID排重，只用了buff表里的是否显示字段
--onBlood表示在血条上显示护盾  特殊处理
---@param onBlood boolean
function BuffViewComponent:GetBuffTeamStateShowList(onBlood)
    local buffIDList = {}
    local showList = {}

    for i, buffView in ipairs(self._viewInstanceArray) do
        local isShowBuffTeamState = self:_GetBuffShowTeamState(buffView, onBlood)
        local canShowBuff = self:_GetShowBuffLayer(buffView)

        --不重复的ID and 配表显示图标
        if not table.intable(buffIDList, buffView:BuffID()) and isShowBuffTeamState and canShowBuff then
            table.insert(buffIDList, buffView:BuffID())
            table.insert(showList, buffView)
        end
    end
    return showList
end

---是否可以显示在ui队伍状态上
---@param buffView BuffViewInstance
---@param onBlood boolean
function BuffViewComponent:_GetBuffShowTeamState(buffView, onBlood)
    local onBloodShowLayerShield = onBlood and true or buffView:GetBuffEffectType() ~= BuffEffectType.LayerShield
    local buffShowTeamState = buffView:BuffConfigData():GetBuffShowTeamState()

    return onBloodShowLayerShield and buffShowTeamState
end


---@param buffView BuffViewInstance
function BuffViewComponent:_GetShowBuffLayer(buffView)
    local buffLayer = buffView:GetLayerCount()
    local isUnload = buffView:IsUnload()

    local hasLayer = buffView:HasLayer()

    --buffLayer返回的是nil   and   view已经显示了
    local isNoLayerBuff = not hasLayer and buffView:IsShow()

    local canShow = isNoLayerBuff or (buffLayer and buffLayer > 0)

    return canShow
end

--buff轮播材质动画列表
function BuffViewComponent:GetMaterialAnimiationArray()
    local anims = {}
    for i, buffv in ipairs(self._viewInstanceArray) do
        local cfg = buffv:BuffConfigData()
        if
            buffv:IsShow() and
                (cfg:GetBuffType() == BuffType.DOT --[[之后将移除该判断："是否轮播"是表现配置而不是类型]] or
                    cfg:GetMaterialAnimationMode() == BuffMaterialAnimationMode.Alternating)
         then
            local anim = cfg:GetMaterialAnimation()
            if not table.icontains(anims, anim) then
                anims[#anims + 1] = anim
            end
        end
    end
    return anims
end

--获取显示在头顶的buff
function BuffViewComponent:GetHeadBuff()
    local min_priority = 0
    local head_buff = nil

    for _, buffv in ipairs(self._viewInstanceArray) do
        --处理优先显示的buff 优先级越小越靠前
        if buffv:GetBuffType() == BuffType.Control and buffv:IsShow() then
            local cfg = buffv:BuffConfigData()
            local priority = cfg:GetBuffPriority()
            if priority > 0 then
                if min_priority == 0 or priority < min_priority then
                    min_priority = priority
                    head_buff = buffv
                end
            end
        end
    end
    return head_buff
end

function BuffViewComponent:GetBuffValue(key)
    return self._viewData[key]
end

function BuffViewComponent:SetBuffValue(key, value)
    self._viewData[key] = value
end

---表现侧查询是否有对应的buff
function BuffViewComponent:HasBuffByID(buffId)
    for _, v in ipairs(self._viewInstanceArray) do
        ---@type BuffViewInstance
        local buffViewInstance = v
        if buffViewInstance:BuffID() == buffId then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------

---@return BuffViewComponent
function Entity:BuffView()
    return self:GetComponent(self.WEComponentsEnum.BuffView)
end

function Entity:AddBuffView()
    local component = BuffViewComponent:New()
    self:AddComponent(self.WEComponentsEnum.BuffView, component)
end

function Entity:RemoveBuffViewInstance(buffViewInstance)
    if self:BuffView() then
        self:BuffView():RemoveBuffViewInstance(buffViewInstance)
    end
end
