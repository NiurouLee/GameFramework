--[[
    N34坦克的炮台拼装指令

    拒绝承诺该指令可复用于其他单位。尝试复用即理解并同意承担一切后果。
]]

require("base_ins_r")

_class("TankLinkTowerToBodyInstruction", BaseInstruction)
---@class TankLinkTowerToBodyInstruction: BaseInstruction
TankLinkTowerToBodyInstruction = TankLinkTowerToBodyInstruction

function TankLinkTowerToBodyInstruction:Constructor(paramList)
    self._towerResourceName = paramList.towerResourceName
    self._bindGameObjectName = paramList.bindGameObjectName
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function TankLinkTowerToBodyInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local fxsvc = world:GetService("Effect")

    local towerEntity = fxsvc:CreateEffectEntity()
    towerEntity:ReplaceAsset(NativeUnityPrefabAsset:New(self._towerResourceName, true))

    local csCasterTransform = casterEntity:View():GetGameObject().transform
    local csTowerGameObject = towerEntity:View():GetGameObject()
    local csTowerTransform = csTowerGameObject.transform

    --材质动画支持
    local csMaterialAnim = csTowerGameObject:GetComponent(typeof(MaterialAnimation))
    if (not csMaterialAnim) or (tostring(csMaterialAnim) == "null") then
        csMaterialAnim = csTowerGameObject:AddComponent(typeof(MaterialAnimation))

        local resServ = world.BW_Services.ResourcesPool
        local container = resServ:LoadAsset("globalShaderEffects.asset")
        towerEntity:AddMaterialAnimationComponent(container, csMaterialAnim)
        casterEntity:MaterialAnimationComponent():AddLinkMaterialAnimEntity(towerEntity)
    end

    --GameObjectHelper返回的是个CS.UnityEngine.Transform，虽然是很方便吧
    local csCasterRoot = GameObjectHelper.FindChild(csCasterTransform, "Root")
    csTowerTransform:SetParent(csCasterRoot)
    csTowerTransform.localPosition = Vector3.zero
    csTowerTransform.localRotation = Quaternion.Euler(0, 0, 0)

    towerEntity:AddAnimatorController({}, {})
    if not casterEntity:HasAnimatorController() then
        casterEntity:AddAnimatorController({}, {})
    end
    casterEntity:AnimatorController():AddLinkAnimatorEntity(towerEntity)
    if not casterEntity:HasEffectHolder() then
        casterEntity:AddEffectHolder()
    end

    local cEffectHolder = casterEntity:EffectHolder()
    cEffectHolder:AttachEffect(BattleConst.Tank2002901TowerEffectKey, towerEntity)
end

function TankLinkTowerToBodyInstruction:GetCacheResource()
    return {{self._towerResourceName, 1}}
end
