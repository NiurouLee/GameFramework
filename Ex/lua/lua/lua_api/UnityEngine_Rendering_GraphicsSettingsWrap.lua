---@class UnityEngine.Rendering.GraphicsSettings : UnityEngine.Object
---@field transparencySortMode UnityEngine.TransparencySortMode
---@field transparencySortAxis UnityEngine.Vector3
---@field lightsUseLinearIntensity bool
---@field lightsUseColorTemperature bool
---@field useScriptableRenderPipelineBatching bool
---@field logWhenShaderIsCompiled bool
---@field renderPipelineAsset UnityEngine.Experimental.Rendering.RenderPipelineAsset
local m = {}
---@overload fun(defineHash:UnityEngine.Rendering.BuiltinShaderDefine):bool
---@param tier UnityEngine.Rendering.GraphicsTier
---@param defineHash UnityEngine.Rendering.BuiltinShaderDefine
---@return bool
function m.HasShaderDefine(tier, defineHash) end
---@param type UnityEngine.Rendering.BuiltinShaderType
---@param mode UnityEngine.Rendering.BuiltinShaderMode
function m.SetShaderMode(type, mode) end
---@param type UnityEngine.Rendering.BuiltinShaderType
---@return UnityEngine.Rendering.BuiltinShaderMode
function m.GetShaderMode(type) end
---@param type UnityEngine.Rendering.BuiltinShaderType
---@param shader UnityEngine.Shader
function m.SetCustomShader(type, shader) end
---@param type UnityEngine.Rendering.BuiltinShaderType
---@return UnityEngine.Shader
function m.GetCustomShader(type) end
UnityEngine = {}
UnityEngine.Rendering = {}
UnityEngine.Rendering.GraphicsSettings = m
return m