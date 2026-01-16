---@class UnityEngine.Rendering.CommandBuffer : object
---@field name string
---@field sizeInBytes int
local m = {}
---@overload fun(src:UnityEngine.Rendering.RenderTargetIdentifier, srcElement:int, dst:UnityEngine.Rendering.RenderTargetIdentifier, dstElement:int):void
---@param src UnityEngine.Rendering.RenderTargetIdentifier
---@param dst UnityEngine.Rendering.RenderTargetIdentifier
function m:ConvertTexture(src, dst) end
---@overload fun(src:UnityEngine.ComputeBuffer, size:int, offset:int, callback:System.Action):void
---@overload fun(src:UnityEngine.Texture, callback:System.Action):void
---@overload fun(src:UnityEngine.Texture, mipIndex:int, callback:System.Action):void
---@overload fun(src:UnityEngine.Texture, mipIndex:int, dstFormat:UnityEngine.TextureFormat, callback:System.Action):void
---@overload fun(src:UnityEngine.Texture, mipIndex:int, x:int, width:int, y:int, height:int, z:int, depth:int, callback:System.Action):void
---@overload fun(src:UnityEngine.Texture, mipIndex:int, x:int, width:int, y:int, height:int, z:int, depth:int, dstFormat:UnityEngine.TextureFormat, callback:System.Action):void
---@param src UnityEngine.ComputeBuffer
---@param callback System.Action
function m:RequestAsyncReadback(src, callback) end
---@param invertCulling bool
function m:SetInvertCulling(invertCulling) end
---@overload fun(computeShader:UnityEngine.ComputeShader, name:string, val:float):void
---@param computeShader UnityEngine.ComputeShader
---@param nameID int
---@param val float
function m:SetComputeFloatParam(computeShader, nameID, val) end
---@overload fun(computeShader:UnityEngine.ComputeShader, name:string, val:int):void
---@param computeShader UnityEngine.ComputeShader
---@param nameID int
---@param val int
function m:SetComputeIntParam(computeShader, nameID, val) end
---@overload fun(computeShader:UnityEngine.ComputeShader, name:string, val:UnityEngine.Vector4):void
---@param computeShader UnityEngine.ComputeShader
---@param nameID int
---@param val UnityEngine.Vector4
function m:SetComputeVectorParam(computeShader, nameID, val) end
---@overload fun(computeShader:UnityEngine.ComputeShader, name:string, values:table):void
---@param computeShader UnityEngine.ComputeShader
---@param nameID int
---@param values table
function m:SetComputeVectorArrayParam(computeShader, nameID, values) end
---@overload fun(computeShader:UnityEngine.ComputeShader, name:string, val:UnityEngine.Matrix4x4):void
---@param computeShader UnityEngine.ComputeShader
---@param nameID int
---@param val UnityEngine.Matrix4x4
function m:SetComputeMatrixParam(computeShader, nameID, val) end
---@overload fun(computeShader:UnityEngine.ComputeShader, name:string, values:table):void
---@param computeShader UnityEngine.ComputeShader
---@param nameID int
---@param values table
function m:SetComputeMatrixArrayParam(computeShader, nameID, values) end
---@overload fun(computeShader:UnityEngine.ComputeShader, kernelIndex:int, name:string, buffer:UnityEngine.ComputeBuffer):void
---@param computeShader UnityEngine.ComputeShader
---@param kernelIndex int
---@param nameID int
---@param buffer UnityEngine.ComputeBuffer
function m:SetComputeBufferParam(computeShader, kernelIndex, nameID, buffer) end
---@param src UnityEngine.ComputeBuffer
---@param dst UnityEngine.ComputeBuffer
---@param dstOffsetBytes uint
function m:CopyCounterValue(src, dst, dstOffsetBytes) end
function m:Clear() end
function m:ClearRandomWriteTargets() end
---@param pixelRect UnityEngine.Rect
function m:SetViewport(pixelRect) end
---@param scissor UnityEngine.Rect
function m:EnableScissorRect(scissor) end
function m:DisableScissorRect() end
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int, enableRandomWrite:bool, memorylessMode:UnityEngine.RenderTextureMemoryless):void
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int, enableRandomWrite:bool):void
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int):void
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite):void
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat):void
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int, filter:UnityEngine.FilterMode):void
---@overload fun(nameID:int, width:int, height:int, depthBuffer:int):void
---@overload fun(nameID:int, width:int, height:int):void
---@overload fun(nameID:int, desc:UnityEngine.RenderTextureDescriptor, filter:UnityEngine.FilterMode):void
---@overload fun(nameID:int, desc:UnityEngine.RenderTextureDescriptor):void
---@param nameID int
---@param width int
---@param height int
---@param depthBuffer int
---@param filter UnityEngine.FilterMode
---@param format UnityEngine.RenderTextureFormat
---@param readWrite UnityEngine.RenderTextureReadWrite
---@param antiAliasing int
---@param enableRandomWrite bool
---@param memorylessMode UnityEngine.RenderTextureMemoryless
---@param useDynamicScale bool
function m:GetTemporaryRT(nameID, width, height, depthBuffer, filter, format, readWrite, antiAliasing, enableRandomWrite, memorylessMode, useDynamicScale) end
---@overload fun(nameID:int, width:int, height:int, slices:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int, enableRandomWrite:bool):void
---@overload fun(nameID:int, width:int, height:int, slices:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int):void
---@overload fun(nameID:int, width:int, height:int, slices:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite):void
---@overload fun(nameID:int, width:int, height:int, slices:int, depthBuffer:int, filter:UnityEngine.FilterMode, format:UnityEngine.RenderTextureFormat):void
---@overload fun(nameID:int, width:int, height:int, slices:int, depthBuffer:int, filter:UnityEngine.FilterMode):void
---@overload fun(nameID:int, width:int, height:int, slices:int, depthBuffer:int):void
---@overload fun(nameID:int, width:int, height:int, slices:int):void
---@param nameID int
---@param width int
---@param height int
---@param slices int
---@param depthBuffer int
---@param filter UnityEngine.FilterMode
---@param format UnityEngine.RenderTextureFormat
---@param readWrite UnityEngine.RenderTextureReadWrite
---@param antiAliasing int
---@param enableRandomWrite bool
---@param useDynamicScale bool
function m:GetTemporaryRTArray(nameID, width, height, slices, depthBuffer, filter, format, readWrite, antiAliasing, enableRandomWrite, useDynamicScale) end
---@param nameID int
function m:ReleaseTemporaryRT(nameID) end
---@overload fun(clearDepth:bool, clearColor:bool, backgroundColor:UnityEngine.Color):void
---@param clearDepth bool
---@param clearColor bool
---@param backgroundColor UnityEngine.Color
---@param depth float
function m:ClearRenderTarget(clearDepth, clearColor, backgroundColor, depth) end
---@overload fun(name:string, value:float):void
---@param nameID int
---@param value float
function m:SetGlobalFloat(nameID, value) end
---@overload fun(name:string, value:int):void
---@param nameID int
---@param value int
function m:SetGlobalInt(nameID, value) end
---@overload fun(name:string, value:UnityEngine.Vector4):void
---@param nameID int
---@param value UnityEngine.Vector4
function m:SetGlobalVector(nameID, value) end
---@overload fun(name:string, value:UnityEngine.Color):void
---@param nameID int
---@param value UnityEngine.Color
function m:SetGlobalColor(nameID, value) end
---@overload fun(name:string, value:UnityEngine.Matrix4x4):void
---@param nameID int
---@param value UnityEngine.Matrix4x4
function m:SetGlobalMatrix(nameID, value) end
---@param keyword string
function m:EnableShaderKeyword(keyword) end
---@param keyword string
function m:DisableShaderKeyword(keyword) end
---@param view UnityEngine.Matrix4x4
function m:SetViewMatrix(view) end
---@param proj UnityEngine.Matrix4x4
function m:SetProjectionMatrix(proj) end
---@param view UnityEngine.Matrix4x4
---@param proj UnityEngine.Matrix4x4
function m:SetViewProjectionMatrices(view, proj) end
---@param bias float
---@param slopeBias float
function m:SetGlobalDepthBias(bias, slopeBias) end
---@overload fun(propertyName:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@overload fun(propertyName:string, values:table):void
---@param nameID int
---@param values table
function m:SetGlobalFloatArray(nameID, values) end
---@overload fun(propertyName:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@overload fun(propertyName:string, values:table):void
---@param nameID int
---@param values table
function m:SetGlobalVectorArray(nameID, values) end
---@overload fun(propertyName:string, values:table):void
---@overload fun(nameID:int, values:table):void
---@overload fun(propertyName:string, values:table):void
---@param nameID int
---@param values table
function m:SetGlobalMatrixArray(nameID, values) end
---@overload fun(name:string, value:UnityEngine.ComputeBuffer):void
---@param nameID int
---@param value UnityEngine.ComputeBuffer
function m:SetGlobalBuffer(nameID, value) end
---@param name string
function m:BeginSample(name) end
---@param name string
function m:EndSample(name) end
---@overload fun(rt:UnityEngine.Rendering.RenderTargetIdentifier, loadAction:UnityEngine.Rendering.RenderBufferLoadAction, storeAction:UnityEngine.Rendering.RenderBufferStoreAction):void
---@overload fun(rt:UnityEngine.Rendering.RenderTargetIdentifier, colorLoadAction:UnityEngine.Rendering.RenderBufferLoadAction, colorStoreAction:UnityEngine.Rendering.RenderBufferStoreAction, depthLoadAction:UnityEngine.Rendering.RenderBufferLoadAction, depthStoreAction:UnityEngine.Rendering.RenderBufferStoreAction):void
---@overload fun(rt:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int):void
---@overload fun(rt:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int, cubemapFace:UnityEngine.CubemapFace):void
---@overload fun(rt:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int, cubemapFace:UnityEngine.CubemapFace, depthSlice:int):void
---@overload fun(color:UnityEngine.Rendering.RenderTargetIdentifier, depth:UnityEngine.Rendering.RenderTargetIdentifier):void
---@overload fun(color:UnityEngine.Rendering.RenderTargetIdentifier, depth:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int):void
---@overload fun(color:UnityEngine.Rendering.RenderTargetIdentifier, depth:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int, cubemapFace:UnityEngine.CubemapFace):void
---@overload fun(color:UnityEngine.Rendering.RenderTargetIdentifier, depth:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int, cubemapFace:UnityEngine.CubemapFace, depthSlice:int):void
---@overload fun(color:UnityEngine.Rendering.RenderTargetIdentifier, colorLoadAction:UnityEngine.Rendering.RenderBufferLoadAction, colorStoreAction:UnityEngine.Rendering.RenderBufferStoreAction, depth:UnityEngine.Rendering.RenderTargetIdentifier, depthLoadAction:UnityEngine.Rendering.RenderBufferLoadAction, depthStoreAction:UnityEngine.Rendering.RenderBufferStoreAction):void
---@overload fun(colors:table, depth:UnityEngine.Rendering.RenderTargetIdentifier):void
---@overload fun(binding:UnityEngine.Rendering.RenderTargetBinding):void
---@param rt UnityEngine.Rendering.RenderTargetIdentifier
function m:SetRenderTarget(rt) end
function m:Dispose() end
function m:Release() end
---@overload fun():UnityEngine.Rendering.GPUFence
---@param stage UnityEngine.Rendering.SynchronisationStage
---@return UnityEngine.Rendering.GPUFence
function m:CreateGPUFence(stage) end
---@overload fun(fence:UnityEngine.Rendering.GPUFence):void
---@param fence UnityEngine.Rendering.GPUFence
---@param stage UnityEngine.Rendering.SynchronisationStage
function m:WaitOnGPUFence(fence, stage) end
---@overload fun(computeShader:UnityEngine.ComputeShader, nameID:int, values:table):void
---@param computeShader UnityEngine.ComputeShader
---@param name string
---@param values table
function m:SetComputeFloatParams(computeShader, name, values) end
---@overload fun(computeShader:UnityEngine.ComputeShader, nameID:int, values:table):void
---@param computeShader UnityEngine.ComputeShader
---@param name string
---@param values table
function m:SetComputeIntParams(computeShader, name, values) end
---@overload fun(computeShader:UnityEngine.ComputeShader, kernelIndex:int, nameID:int, rt:UnityEngine.Rendering.RenderTargetIdentifier):void
---@overload fun(computeShader:UnityEngine.ComputeShader, kernelIndex:int, name:string, rt:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int):void
---@overload fun(computeShader:UnityEngine.ComputeShader, kernelIndex:int, nameID:int, rt:UnityEngine.Rendering.RenderTargetIdentifier, mipLevel:int):void
---@param computeShader UnityEngine.ComputeShader
---@param kernelIndex int
---@param name string
---@param rt UnityEngine.Rendering.RenderTargetIdentifier
function m:SetComputeTextureParam(computeShader, kernelIndex, name, rt) end
---@overload fun(computeShader:UnityEngine.ComputeShader, kernelIndex:int, indirectBuffer:UnityEngine.ComputeBuffer, argsOffset:uint):void
---@param computeShader UnityEngine.ComputeShader
---@param kernelIndex int
---@param threadGroupsX int
---@param threadGroupsY int
---@param threadGroupsZ int
function m:DispatchCompute(computeShader, kernelIndex, threadGroupsX, threadGroupsY, threadGroupsZ) end
---@param rt UnityEngine.RenderTexture
function m:GenerateMips(rt) end
---@param rt UnityEngine.RenderTexture
---@param target UnityEngine.RenderTexture
function m:ResolveAntiAliasedSurface(rt, target) end
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, submeshIndex:int, shaderPass:int):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, submeshIndex:int):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material):void
---@param mesh UnityEngine.Mesh
---@param matrix UnityEngine.Matrix4x4
---@param material UnityEngine.Material
---@param submeshIndex int
---@param shaderPass int
---@param properties UnityEngine.MaterialPropertyBlock
function m:DrawMesh(mesh, matrix, material, submeshIndex, shaderPass, properties) end
---@overload fun(renderer:UnityEngine.Renderer, material:UnityEngine.Material, submeshIndex:int):void
---@overload fun(renderer:UnityEngine.Renderer, material:UnityEngine.Material):void
---@param renderer UnityEngine.Renderer
---@param material UnityEngine.Material
---@param submeshIndex int
---@param shaderPass int
function m:DrawRenderer(renderer, material, submeshIndex, shaderPass) end
---@overload fun(matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, shaderPass:int, topology:UnityEngine.MeshTopology, vertexCount:int, instanceCount:int):void
---@overload fun(matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, shaderPass:int, topology:UnityEngine.MeshTopology, vertexCount:int):void
---@param matrix UnityEngine.Matrix4x4
---@param material UnityEngine.Material
---@param shaderPass int
---@param topology UnityEngine.MeshTopology
---@param vertexCount int
---@param instanceCount int
---@param properties UnityEngine.MaterialPropertyBlock
function m:DrawProcedural(matrix, material, shaderPass, topology, vertexCount, instanceCount, properties) end
---@overload fun(matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, shaderPass:int, topology:UnityEngine.MeshTopology, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int):void
---@overload fun(matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, shaderPass:int, topology:UnityEngine.MeshTopology, bufferWithArgs:UnityEngine.ComputeBuffer):void
---@param matrix UnityEngine.Matrix4x4
---@param material UnityEngine.Material
---@param shaderPass int
---@param topology UnityEngine.MeshTopology
---@param bufferWithArgs UnityEngine.ComputeBuffer
---@param argsOffset int
---@param properties UnityEngine.MaterialPropertyBlock
function m:DrawProceduralIndirect(matrix, material, shaderPass, topology, bufferWithArgs, argsOffset, properties) end
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, shaderPass:int, matrices:table, count:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, shaderPass:int, matrices:table):void
---@param mesh UnityEngine.Mesh
---@param submeshIndex int
---@param material UnityEngine.Material
---@param shaderPass int
---@param matrices table
---@param count int
---@param properties UnityEngine.MaterialPropertyBlock
function m:DrawMeshInstanced(mesh, submeshIndex, material, shaderPass, matrices, count, properties) end
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, shaderPass:int, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, shaderPass:int, bufferWithArgs:UnityEngine.ComputeBuffer):void
---@param mesh UnityEngine.Mesh
---@param submeshIndex int
---@param material UnityEngine.Material
---@param shaderPass int
---@param bufferWithArgs UnityEngine.ComputeBuffer
---@param argsOffset int
---@param properties UnityEngine.MaterialPropertyBlock
function m:DrawMeshInstancedIndirect(mesh, submeshIndex, material, shaderPass, bufferWithArgs, argsOffset, properties) end
---@overload fun(index:int, buffer:UnityEngine.ComputeBuffer, preserveCounterValue:bool):void
---@overload fun(index:int, buffer:UnityEngine.ComputeBuffer):void
---@param index int
---@param rt UnityEngine.Rendering.RenderTargetIdentifier
function m:SetRandomWriteTarget(index, rt) end
---@overload fun(src:UnityEngine.Rendering.RenderTargetIdentifier, srcElement:int, dst:UnityEngine.Rendering.RenderTargetIdentifier, dstElement:int):void
---@overload fun(src:UnityEngine.Rendering.RenderTargetIdentifier, srcElement:int, srcMip:int, dst:UnityEngine.Rendering.RenderTargetIdentifier, dstElement:int, dstMip:int):void
---@overload fun(src:UnityEngine.Rendering.RenderTargetIdentifier, srcElement:int, srcMip:int, srcX:int, srcY:int, srcWidth:int, srcHeight:int, dst:UnityEngine.Rendering.RenderTargetIdentifier, dstElement:int, dstMip:int, dstX:int, dstY:int):void
---@param src UnityEngine.Rendering.RenderTargetIdentifier
---@param dst UnityEngine.Rendering.RenderTargetIdentifier
function m:CopyTexture(src, dst) end
---@overload fun(source:UnityEngine.Texture, dest:UnityEngine.Rendering.RenderTargetIdentifier, scale:UnityEngine.Vector2, offset:UnityEngine.Vector2):void
---@overload fun(source:UnityEngine.Texture, dest:UnityEngine.Rendering.RenderTargetIdentifier, mat:UnityEngine.Material):void
---@overload fun(source:UnityEngine.Texture, dest:UnityEngine.Rendering.RenderTargetIdentifier, mat:UnityEngine.Material, pass:int):void
---@overload fun(source:UnityEngine.Rendering.RenderTargetIdentifier, dest:UnityEngine.Rendering.RenderTargetIdentifier):void
---@overload fun(source:UnityEngine.Rendering.RenderTargetIdentifier, dest:UnityEngine.Rendering.RenderTargetIdentifier, scale:UnityEngine.Vector2, offset:UnityEngine.Vector2):void
---@overload fun(source:UnityEngine.Rendering.RenderTargetIdentifier, dest:UnityEngine.Rendering.RenderTargetIdentifier, mat:UnityEngine.Material):void
---@overload fun(source:UnityEngine.Rendering.RenderTargetIdentifier, dest:UnityEngine.Rendering.RenderTargetIdentifier, mat:UnityEngine.Material, pass:int):void
---@param source UnityEngine.Texture
---@param dest UnityEngine.Rendering.RenderTargetIdentifier
function m:Blit(source, dest) end
---@overload fun(nameID:int, value:UnityEngine.Rendering.RenderTargetIdentifier):void
---@param name string
---@param value UnityEngine.Rendering.RenderTargetIdentifier
function m:SetGlobalTexture(name, value) end
---@param shadowmap UnityEngine.Rendering.RenderTargetIdentifier
---@param mode UnityEngine.Rendering.ShadowSamplingMode
function m:SetShadowSamplingMode(shadowmap, mode) end
---@param callback System.IntPtr
---@param eventID int
function m:IssuePluginEvent(callback, eventID) end
---@param callback System.IntPtr
---@param eventID int
---@param data System.IntPtr
function m:IssuePluginEventAndData(callback, eventID, data) end
---@param callback System.IntPtr
---@param command uint
---@param source UnityEngine.Rendering.RenderTargetIdentifier
---@param dest UnityEngine.Rendering.RenderTargetIdentifier
---@param commandParam uint
---@param commandFlags uint
function m:IssuePluginCustomBlit(callback, command, source, dest, commandParam, commandFlags) end
---@param callback System.IntPtr
---@param targetTexture UnityEngine.Texture
---@param userData uint
function m:IssuePluginCustomTextureUpdateV2(callback, targetTexture, userData) end
UnityEngine = {}
UnityEngine.Rendering = {}
UnityEngine.Rendering.CommandBuffer = m
return m