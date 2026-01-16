--负责buff生命周期管理和触发器、执行器、结果的容器
BuffHandlerType = {
    LoadHandler = 1,
    ActiveHandler = 2,
    ExecuteHandler = 3,
    DeactivateHandler = 4,
    UnloadHandler = 5
}

_class("BuffInstance", Object)
---@class BuffInstance:Object
BuffInstance = BuffInstance

function BuffInstance:Constructor(buffSeq, buffID, entity, world, context, alterLayer, changeLayerCount)
    --buff唯一ID
    self._buffSeq = buffSeq
    --buff配置ID
    self._buffID = buffID
    ---@type Entity
    self._entity = entity
    ---@type MainWorld
    self._world = world
    self._context = context
    --激活状态
    self._active = false
    --挂载状态
    self._unload = false

    --回合计数
    self._buffRoundCount = 0
    --触发计数
    self._buffExecCount = 0
    --配置
    ---@type ConfigService
    local sConfig = world:GetService("Config")
    self._buffConfigData = sConfig:GetBuffConfigData(buffID)
    --如果是圣物记录ID
    self._relicId = 0

    local cfg = self._buffConfigData:GetData()
    self._maxBuffRoundCount = cfg.RoundCount
    self._maxBuffExecCount = cfg.ExecCount
    self._maxBuffLayerCount = cfg.LayerCount
    --相同effect的buff共享layer
    ---@type BuffLogicService
    self._buffsvc = world:GetService("BuffLogic")
    self._buffLayerName = self._buffsvc:GetBuffLayerName(self:GetBuffEffectType())

    self._init = false
    ---创建buff的时候初始化加了个层数
    if context and context.layer and type(context.layer) == "number" then
        self:AddLayerCount(context.layer)
    end

    self._casterSnapAttackValue = 0 ---创建buffinstance时刻施法者的攻击值镜像
    self:DoSnapShotValue(context)

    self._maxCountDown = cfg.CountDown --倒计时

    self._alterLayer  = alterLayer
    self._changeLayerCount = changeLayerCount
end

function BuffInstance:ViewInstance()
    return self._viewInstance
end

function BuffInstance:IsInit()
    return self._init
end

---根据cfg_pet_equip处理cfg_buff
function BuffInstance:GetEquipIntensifiedCfg(equipIntensifyParams)
    local cfg = self._buffConfigData:GetData() --cfg即为cfg_buff的一条buff的配置
    local tmpCfg = {}
    ---TODO 优化一下写法
    tmpCfg["Load"] = {}
    tmpCfg["Load"].logic = table.cloneconf(cfg.LoadLogic) or {}
    tmpCfg["Active"] = {}
    tmpCfg["Active"].logic = table.cloneconf(cfg.ActiveLogic) or {}
    tmpCfg["Active"].trigger = table.cloneconf(cfg.ActiveTrigger)
    tmpCfg["Exec"] = {}
    tmpCfg["Exec"].logic = table.cloneconf(cfg.ExecLogic) or {}
    tmpCfg["Exec"].trigger = table.cloneconf(cfg.ExecTrigger)
    tmpCfg["Deactive"] = {}
    tmpCfg["Deactive"].logic = table.cloneconf(cfg.DeactiveLogic) or {}
    tmpCfg["Deactive"].trigger = table.cloneconf(cfg.DeactiveTrigger)
    tmpCfg["Unload"] = {}
    tmpCfg["Unload"].logic = table.cloneconf(cfg.UnloadLogic) or {}
    tmpCfg["Unload"].trigger = table.cloneconf(cfg.UnloadTrigger)
    self._buffsvc:DoEquipIntensify(self._buffID, tmpCfg, equipIntensifyParams)

    return tmpCfg
end

---参数是装备强化Buff的逻辑
function BuffInstance:InitBuffHandler(equipIntensifyParams)
    self._init = true

    local tmpCfg = self:GetEquipIntensifiedCfg(equipIntensifyParams)

    --触发回调处理器
    self._buffHandler = {}
    self._buffHandler[BuffHandlerType.LoadHandler] =
        BuffLoadHandler:New(self, {{NotifyType.BuffLoad}, {TriggerType.Always}}, tmpCfg["Load"].logic)
    self._buffHandler[BuffHandlerType.ActiveHandler] =
        BuffActiveHandler:New(self, tmpCfg["Active"].trigger, tmpCfg["Active"].logic)
    self._buffHandler[BuffHandlerType.ExecuteHandler] =
        BuffExecuteHandler:New(self, tmpCfg["Exec"].trigger, tmpCfg["Exec"].logic)
    self._buffHandler[BuffHandlerType.DeactivateHandler] =
        BuffDeactiveHandler:New(self, tmpCfg["Deactive"].trigger, tmpCfg["Deactive"].logic)
    self._buffHandler[BuffHandlerType.UnloadHandler] =
        BuffUnloadHandler:New(self, tmpCfg["Unload"].trigger, tmpCfg["Unload"].logic)

    --默认不激活
    self:SetActive(false)
    --卸载永远激活
    self._buffHandler[BuffHandlerType.UnloadHandler]:SetActive(true)

    --根据装备配置修改buffInstance某些字段
    self._buffsvc:UpdateBuffInstanceField(self, equipIntensifyParams)
end

--buff激活和失效
function BuffInstance:SetActive(active)
    self._active = active
    self._buffHandler[BuffHandlerType.ExecuteHandler]:SetActive(active)
    self._buffHandler[BuffHandlerType.DeactivateHandler]:SetActive(active)
    self._buffHandler[BuffHandlerType.ActiveHandler]:SetActive(not active)
end

--是否激活
function BuffInstance:IsActive()
    return self._active
end

--挂载
function BuffInstance:Load()
    local notify = NTBuffLoad:New(self._entity)
    for i, h in ipairs(self._buffHandler) do
        if table.icontains(h:GetNotifyType(), NotifyType.BuffLoad) and h:GetTrigger():IsSatisfied(notify) then
            h:OnTrigger(notify)
        end
    end

    self._world:GetService("Trigger"):Notify(
        NTAddBuffEnd:New(self._entity, self._buffSeq, self._buffID, self:GetBuffEffectType())
    )

    if self:GetBuffType() == BuffType.Control then
        ---@type NTAddControlBuffEnd
        local nt = NTAddControlBuffEnd:New(self._entity, self._buffSeq, self._buffID, self:GetBuffEffectType())
        self._world:GetService("Trigger"):Notify(nt)
    end
end

function BuffInstance:IsUnload()
    return self._unload
end

--手动卸载
function BuffInstance:Unload(notify, isUnloadByTrigger)
    if self._unload then
        return
    end

    --失活逻辑应该执行一下
    if self._active then
        self:SetActive(false)
        self._buffHandler[BuffHandlerType.DeactivateHandler]:OnTrigger(notify)
    end

    -- 所有的卸载逻辑都应该执行
    if not isUnloadByTrigger then
        self._buffHandler[BuffHandlerType.UnloadHandler]:OnTrigger(notify)
    end
    self:OnUnload(notify, false)
    self._world:GetService("Trigger"):Notify(
        NTRemoveBuffEnd:New(self._entity, self._buffSeq, self._buffID, self:GetBuffEffectType())
    )
    self._unload = true
end

--自动、手动卸载回调
function BuffInstance:OnUnload(notify, checkUnload)
    if checkUnload and self._unload then
        return
    end
    
    for i, h in pairs(self._buffHandler) do
        h:Detach()
    end

    local nt = nil
    if notify then
        nt = notify:GetNotifyType()
    end
    self:PrintBuffInstanceLog(
        "buffinstance unload! entity=",
        self._entity:GetID(),
        " buffseq=",
        self._buffSeq,
        " buffid=",
        self._buffID,
        " notify=",
        GetEnumKey("NotifyType", nt)
    )

    local res = DataBuffDelResult:New(self._entity:GetID(), self._buffSeq, self._buffID, nt)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
end

function BuffInstance:GetUnloadNotifyType()
    local h = self._buffHandler[BuffHandlerType.UnloadHandler]
    return h:GetNotifyType()
end

function BuffInstance:GetBuffExecCount()
    return self._buffExecCount
end

--触发计数
function BuffInstance:AddExecuteCount(notify, val)
    local totalCount = self._maxBuffExecCount or 0
    if totalCount <= 0 then
        return
    end

    self._buffExecCount = self._buffExecCount + val
    if self._buffExecCount >= totalCount then
        self:Unload(notify)
    end
end

function BuffInstance:GetBuffRoundCount()
    return self._buffRoundCount
end

--回合计数
function BuffInstance:AddRoundCount(notify)
    local totalCount = self._maxBuffRoundCount or 0
    if totalCount <= 0 then
        return
    end
    self._buffRoundCount = self._buffRoundCount + 1
    if self._buffRoundCount >= totalCount then
        self:PrintBuffInstanceLog(
            "entity=",
            self._entity:GetID(),
            " buffid=",
            self._buffID,
            " unload by round ! round count=",
            self._buffRoundCount
        )
        self:Unload(notify)
    end

    self:PrintBuffInstanceLog(
        "KZY_ForTest: entity id =",
        self._entity:GetID(),
        " buff id =",
        self._buffID,
        " round count =",
        self._buffRoundCount,
        " notify =",
        GetEnumKey("NotifyType", notify)
    )
    self._world:EventDispatcher():Dispatch(
        GameEventType.DataBuffRoundCount,
        self._entity:GetID(),
        self._buffSeq,
        self._buffRoundCount
    )
end

function BuffInstance:AddMaxRoundCount(cnt)
    if self._maxBuffRoundCount == 0 then
        Log.error(self._className, "unlimited round count cannot be added. ")
        return
    end

    if self._maxBuffRoundCount + cnt == 0 then
        Log.error(self._className, "cannot turn a buff into unlimited round one. ")
        return
    end

    self._maxBuffRoundCount = self._maxBuffRoundCount + cnt

    self._world:EventDispatcher():Dispatch(
        GameEventType.DataBuffMaxRoundCount,
        self._entity:GetID(),
        self._buffSeq,
        self._maxBuffRoundCount
    )
end

function BuffInstance:GetMaxRoundCount()
    return self._maxBuffRoundCount
end

function BuffInstance:GetBuffLayerName()
    return self._buffLayerName
end

function BuffInstance:GetLayerCount()
    return self._entity:BuffComponent():GetBuffValue(self._buffLayerName) or 0
end

--层数计数[同effect的buff共享layer]
function BuffInstance:AddLayerCount(layer)
    local old_layer = self:GetLayerCount()
    local new_layer = layer + old_layer
    if self._maxBuffLayerCount > 0 and new_layer > self._maxBuffLayerCount then
        new_layer = self._maxBuffLayerCount
    end
    self:SetLayerCount(new_layer)
    local changeLayer = new_layer - old_layer
    return new_layer, changeLayer
end

---FIXME: 有坑：layer大于maxBuffLayerCount的话，逻辑会直接不生效
function BuffInstance:SetLayerCount(layer)
    if layer < 0 or (self._maxBuffLayerCount > 0 and layer > self._maxBuffLayerCount) then
        return
    end

    local before = self._entity:BuffComponent():GetBuffValue(self._buffLayerName) or 0
    if self._entity and self._entity:HasSkillInfo() and (before > layer) then
        local cSkillInfo = self._entity:SkillInfo()
        if cSkillInfo:IsBuffIDPassiveCount(self._buffID) then
            local sub = before - layer

            local cBuff = self._entity:BuffComponent()
            local passiveSkillRecord = cBuff:GetBuffValue("PassiveSkillCostCountByRound") or {}
            local roundCount = self._world:BattleStat():GetLevelTotalRoundCount()
            if not passiveSkillRecord[roundCount] then
                passiveSkillRecord[roundCount] = sub
            else
                passiveSkillRecord[roundCount] = passiveSkillRecord[roundCount] + sub
            end

            cBuff:SetBuffValue("PassiveSkillCostCountByRound", passiveSkillRecord)
        end
    end

    self._entity:BuffComponent():SetBuffValue(self._buffLayerName, layer)
end

---更新self._maxBuffLayerCount
function BuffInstance:SetMaxBuffLayerCount(maxBuffLayerCount)
    self._maxBuffLayerCount = maxBuffLayerCount
end

function BuffInstance:GetMaxBuffLayerCount()
    return self._maxBuffLayerCount
end

--逻辑效果叠加
--[[
    改动说明：
    以前的需求是叠加回合数、效果数值，实际使用中只有带层数的buff才叠加，而且叠加处理是直接调用DoLogic()
    这样叠加就简化成buff挂载时修改buff逻辑结果了，只有loadLogic可以直接调用，其他logic时机不满足
]]
function BuffInstance:DoOverlap(buffID, context, equipIntensifyParams)
    local baseCfg = self._world:GetService("Config"):GetBuffConfigData(buffID)
    local tmpCfg = self:GetEquipIntensifiedCfg(equipIntensifyParams)

    self._buffHandler[BuffHandlerType.LoadHandler]:DoOverlap(tmpCfg["Load"].logic, context)
    -- self._buffHandler[BuffHandlerType.UnloadHandler]:DoOverlap(tmpCfg["Unload"].logic, context)
    -- self._buffHandler[BuffHandlerType.ActiveHandler]:DoOverlap(tmpCfg["Active"].logic, context)
    -- self._buffHandler[BuffHandlerType.DeactivateHandler]:DoOverlap(tmpCfg["Deactive"].logic, context)
    -- self._buffHandler[BuffHandlerType.ExecuteHandler]:DoOverlap(tmpCfg["Exec"].logic, context)
end

--序号
function BuffInstance:BuffSeq()
    return self._buffSeq
end

--ID
function BuffInstance:BuffID()
    return self._buffID
end

--配置
function BuffInstance:BuffConfigData()
    return self._buffConfigData
end

function BuffInstance:World()
    return self._world
end

--获取实体
---@return Entity
function BuffInstance:Entity()
    return self._entity
end

--外部参数表
function BuffInstance:Context()
    return self._context
end

function BuffInstance:SetContext(context)
    self._context = context
end

function BuffInstance:GetBuffTargetEntityID()
    return self._entity:GetID()
end

--buff类型
function BuffInstance:GetBuffType()
    return self._buffConfigData:GetBuffType()
end

--效果类型
function BuffInstance:GetBuffEffectType()
    return self._buffConfigData:GetBuffEffectType()
end

--优先级
function BuffInstance:GetBuffPriority()
    return self._buffConfigData:GetBuffPriority()
end

--设置圣物ID
function BuffInstance:SetRelicID(relicID)
    self._relicId = relicID
end

function BuffInstance:PrintBuffInstanceLog(...)
    if self._world and self._world:IsDevelopEnv() then
        Log.debug(...)
    end
end

---创建BuffInstance时，记录一次后续会用到的数据
---例如攻击者的攻击力之类的
function BuffInstance:DoSnapShotValue(context)
    if not context then 
        return
    end

    if context.casterEntity then 
        ---@type AttributesComponent
        local attrCmpt = context.casterEntity:Attributes()
        if attrCmpt then 
            self._casterSnapAttackValue = attrCmpt:GetAttribute("Attack")
        end
    end
end

---返回初始的攻击力
function BuffInstance:GetSnapCasterAttack()
    return self._casterSnapAttackValue
end

--region CountDown
function BuffInstance:GetMaxCountDown()
    return self._maxCountDown
end

function BuffInstance:AddCountDown(countDown)
    local maxCountDown = self:GetMaxCountDown()
    if not maxCountDown then
        return
    end

    local old_countDown = self:GetCountDown()
    local new_countDown = countDown + old_countDown

    self:SetCountDown(new_countDown)
    local changecountDown = new_countDown - old_countDown
    return new_countDown, changecountDown
end

function BuffInstance:GetCountDown()
    local countDown =
        self._entity:BuffComponent():GetBuffValue(self._buffLayerName .. "CountDown") or self._maxCountDown
    return countDown
end

function BuffInstance:SetCountDown(countDown)
    local maxCountDown = self:GetMaxCountDown()
    if not maxCountDown then
        return
    end

    if countDown < 0 then
        return
    end

    self._entity:BuffComponent():SetBuffValue(self._buffLayerName .. "CountDown", countDown)
end

--endregion CountDown

function BuffInstance:GetAlterLayerOnLoad()
    return self._alterLayer
end

function BuffInstance:GetChangeLayerCount()
    return self._changeLayerCount
end
