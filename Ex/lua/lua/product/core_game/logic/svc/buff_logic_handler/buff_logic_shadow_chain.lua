--[[
    全息投影
]]
_class("BuffLogicShadowChain", BuffLogicBase)
BuffLogicShadowChain = BuffLogicShadowChain

function BuffLogicShadowChain:Constructor(buffInstance, logicParam)
    self._damagePercent = logicParam.damagePercent
    --投影的模型 如果是nil 则是自己
    self._shadowPrefab = logicParam.shadowPrefab
    self._shadowCreate = logicParam.shadowCreate or 1
end

function BuffLogicShadowChain:DoLogic()
    local e = self._buffInstance:Entity()


    ---@type BuffComponent
    local buffComponent = e:BuffComponent()

    --创建虚影实体
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    local shadowEntity = entityService:_CreateTeamMemberShadow(e)
    buffComponent:SetBuffValue("ShadowChainEntityID", shadowEntity:GetID())

    --设置虚影的技能伤害
    local damagePercent
    ---@type BuffInstance
    local buffShadowChainSKillPro = buffComponent:GetSingleBuffByBuffEffect(BuffEffectType.ShadowChainSKillPro)
    if self._buffInstance:GetBuffEffectType() == BuffEffectType.ShadowChainSKill and buffShadowChainSKillPro then
        --如果(队员身上有小恶狗的被动 and 自己是圣物) 那么圣物的添加 只是增加伤害系数
        damagePercent = buffComponent:GetBuffValue("ShadowChainDamagePercent") or 1
        damagePercent = damagePercent + self._damagePercent
    else
        --第一次小恶狗 or 圣物添加前没有小恶狗被动
        damagePercent = self._damagePercent
    end

    buffComponent:SetBuffValue("ShadowChainDamagePercent", damagePercent)

    local buffResult = BuffResultShadowChain:New(shadowEntity:GetID(),e:PetPstID():GetPstID(),self._shadowPrefab,self._shadowCreate,e:GetID())
    return buffResult
end
