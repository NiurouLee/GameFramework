require("base_ins_r")
---@class PlayCasterChangeMaterialInstruction: BaseInstruction
_class("PlayCasterChangeMaterialInstruction", BaseInstruction)
PlayCasterChangeMaterialInstruction = PlayCasterChangeMaterialInstruction

---@class ChangeMaterialType
local ChangeMaterialType = {
    Modify = 0, ---修改材质
    Revert = 1, ---还原材质
 }
 ChangeMaterialType = ChangeMaterialType
_enum("ChangeMaterialType", ChangeMaterialType)

---@class ModelPartType
local ModelPartType = {
    Body = 0, ---躯干
    Weapon = 1, ---武器
 }
 ModelPartType = ModelPartType
_enum("ModelPartType", ModelPartType)

function PlayCasterChangeMaterialInstruction:Constructor(paramList)
    ---@type ChangeMaterialType
    self._changeType = tonumber(paramList["type"])
    ---@type ModelPartType
    self._part = tonumber(paramList["part"])

    ---要替换成的目标材质
    self._matResName = paramList["mat"]

    self._nodeName = paramList["nodeName"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterChangeMaterialInstruction:DoInstruction(TT,casterEntity,phaseContext)
    if self._changeType == ChangeMaterialType.Modify then 
        self:_ModifyMaterial(casterEntity)
    elseif self._changeType == ChangeMaterialType.Revert then 
        self:_RevertMaterial(casterEntity)
    end
end

---@param casterEntity Entity
function PlayCasterChangeMaterialInstruction:_ModifyMaterial(casterEntity)
    ---@type BackUpMaterialComponent
    local backupCmpt = casterEntity:BackUpMaterial()
    if backupCmpt == nil then 
        casterEntity:AddBackUpMaterial()
        backupCmpt = casterEntity:BackUpMaterial()
    end

    local casterObj = casterEntity:View().ViewWrapper.GameObject
    if self._part == ModelPartType.Body then 
        ---@type UnityEngine.SkinnedMeshRenderer
        local bodyRender = GameObjectHelper.FindFirstSkinedMeshRender(casterObj)
        if bodyRender ~= nil then 
            self:_SetNewMaterial(bodyRender,backupCmpt)
        end
    elseif self._part == ModelPartType.Weapon then 
        ---@type UnityEngine.SkinnedMeshRenderer
        local weaponRender = self:FindWeaponSkinnedMeshRender(casterObj.transform,self._nodeName)
        if weaponRender ~= nil then
            self:_SetNewMaterial(weaponRender,backupCmpt)
        end
    end
end

---@param backupCmpt BackUpMaterialComponent
function PlayCasterChangeMaterialInstruction:_SetNewMaterial(render,backupCmpt)
    local newBodyMat = backupCmpt:GetBackUpMaterial(self._part)
    if not newBodyMat then
        ---加载material资源
        local matResRequest = ResourceManager:GetInstance():SyncLoadAsset(self._matResName, LoadType.Mat)
        newBodyMat = UnityEngine.Material:New(matResRequest.Obj)
        backupCmpt:SetBackUpRequest(self._matResName,matResRequest)
    end

    ---旧的材质存起来
    local sharedMaterials = render.sharedMaterials
    local curMat = sharedMaterials[0]
    backupCmpt:SetBackUpMaterial(self._part,curMat)

    ---再赋予新材质
    local newMats = {}
    newMats[#newMats + 1] = newBodyMat
    render.sharedMaterials = newMats
end

function PlayCasterChangeMaterialInstruction:_RevertMaterial(casterEntity)
    ---@type BackUpMaterialComponent
    local backupCmpt = casterEntity:BackUpMaterial()
    local casterObj = casterEntity:View().ViewWrapper.GameObject

    if self._part == ModelPartType.Body then 
        ---@type UnityEngine.SkinnedMeshRenderer
        local bodyRender = GameObjectHelper.FindFirstSkinedMeshRender(casterObj)
        if bodyRender ~= nil then 
            self:_SetNewMaterial(bodyRender,backupCmpt)
        end
    elseif self._part == ModelPartType.Weapon then 
        ---@type UnityEngine.SkinnedMeshRenderer
        local weaponRender = self:FindWeaponSkinnedMeshRender(casterObj.transform,self._nodeName)
        if weaponRender ~= nil then
            self:_SetNewMaterial(weaponRender,backupCmpt)
        end
    end
end

function PlayCasterChangeMaterialInstruction:FindWeaponSkinnedMeshRender(casterObj,weaponName)
    local transform = GameObjectHelper.FindChild(casterObj,weaponName)
    if not transform then 
        return nil
    end

    local render = transform.gameObject:GetComponent(typeof(UnityEngine.SkinnedMeshRenderer))
    return render
end