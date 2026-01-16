---@class GraphicUtli : object
local m = {}
function m.Test() end
---@param camera UnityEngine.Camera
---@return bool
function m.isSceneCamera(camera) end
---@param shaderName string
---@return string
function m.ShaderNameToAssetName(shaderName) end
---@param shaderName string
---@return UnityEngine.Shader
function m.FindFromBundle(shaderName) end
---@param shaderName string
---@return UnityEngine.Shader
function m.Find(shaderName) end
---@param rt UnityEngine.RenderTexture
function m.ReleaseTempRT(rt) end
---@param obj UnityEngine.Object
function m.DestoryObject(obj) end
GraphicUtli = m
return m