--[[------------------------------------------------------------------------------------------
    BackUpMaterialComponent : 备份材质
]]--------------------------------------------------------------------------------------------

---@class BackUpMaterialComponent: Object
_class( "BackUpMaterialComponent", Object )

function BackUpMaterialComponent:Constructor()
    ---key是用来索引，value是具体的材质instance
    self._backUpMatDic = {}

    ---key是资源名，value是Request
    self._backUpReqDic = {}
end

function BackUpMaterialComponent:SetBackUpMaterial(key,mat)
    self._backUpMatDic[key] = mat
end

function BackUpMaterialComponent:SetBackUpRequest(name,resReq)
    self._backUpReqDic[name] = resReq
end

function BackUpMaterialComponent:GetBackUpMaterial(key)
    return self._backUpMatDic[key]
end


function BackUpMaterialComponent:Dispose()
    for k,v in pairs(self._backUpReqDic) do 
        v:Dispose()
    end

    for k,v in pairs(self._backUpMatDic) do 
        UnityEngine.Object.Destroy(v)
    end
end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function BackUpMaterialComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function BackUpMaterialComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return BackUpMaterialComponent
function Entity:BackUpMaterial()
    return self:GetComponent(self.WEComponentsEnum.BackUpMaterial)
end


function Entity:HasBackUpMaterial()
    return self:HasComponent(self.WEComponentsEnum.BackUpMaterial)
end


function Entity:AddBackUpMaterial()
    local index = self.WEComponentsEnum.BackUpMaterial;
    local component = BackUpMaterialComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplaceBackUpMaterial()
    local index = self.WEComponentsEnum.BackUpMaterial;
    local component = BackUpMaterialComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemoveBackUpMaterial()
    if self:HasBackUpMaterial() then
        self:RemoveComponent(self.WEComponentsEnum.BackUpMaterial)
    end
end