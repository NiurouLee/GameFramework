---@class UnityEngine.Graphics : object
---@field activeColorGamut UnityEngine.ColorGamut
---@field activeTier UnityEngine.Rendering.GraphicsTier
---@field activeColorBuffer UnityEngine.RenderBuffer
---@field activeDepthBuffer UnityEngine.RenderBuffer
local m = {}
function m.ClearRandomWriteTargets() end
---@param buffer UnityEngine.Rendering.CommandBuffer
function m.ExecuteCommandBuffer(buffer) end
---@param buffer UnityEngine.Rendering.CommandBuffer
---@param queueType UnityEngine.Rendering.ComputeQueueType
function m.ExecuteCommandBufferAsync(buffer, queueType) end
---@overload fun(colorBuffer:UnityEngine.RenderBuffer, depthBuffer:UnityEngine.RenderBuffer, mipLevel:int, face:UnityEngine.CubemapFace, depthSlice:int):void
---@overload fun(colorBuffers:table, depthBuffer:UnityEngine.RenderBuffer):void
---@overload fun(setup:UnityEngine.RenderTargetSetup):void
---@overload fun(rt:UnityEngine.RenderTexture):void
---@overload fun(rt:UnityEngine.RenderTexture, mipLevel:int):void
---@overload fun(rt:UnityEngine.RenderTexture, mipLevel:int, face:UnityEngine.CubemapFace):void
---@overload fun(colorBuffer:UnityEngine.RenderBuffer, depthBuffer:UnityEngine.RenderBuffer):void
---@overload fun(colorBuffer:UnityEngine.RenderBuffer, depthBuffer:UnityEngine.RenderBuffer, mipLevel:int):void
---@overload fun(colorBuffer:UnityEngine.RenderBuffer, depthBuffer:UnityEngine.RenderBuffer, mipLevel:int, face:UnityEngine.CubemapFace):void
---@param rt UnityEngine.RenderTexture
---@param mipLevel int
---@param face UnityEngine.CubemapFace
---@param depthSlice int
function m.SetRenderTarget(rt, mipLevel, face, depthSlice) end
---@overload fun(index:int, uav:UnityEngine.ComputeBuffer, preserveCounterValue:bool):void
---@overload fun(index:int, uav:UnityEngine.ComputeBuffer):void
---@param index int
---@param uav UnityEngine.RenderTexture
function m.SetRandomWriteTarget(index, uav) end
---@overload fun(src:UnityEngine.Texture, srcElement:int, dst:UnityEngine.Texture, dstElement:int):void
---@overload fun(src:UnityEngine.Texture, srcElement:int, srcMip:int, dst:UnityEngine.Texture, dstElement:int, dstMip:int):void
---@overload fun(src:UnityEngine.Texture, srcElement:int, srcMip:int, srcX:int, srcY:int, srcWidth:int, srcHeight:int, dst:UnityEngine.Texture, dstElement:int, dstMip:int, dstX:int, dstY:int):void
---@param src UnityEngine.Texture
---@param dst UnityEngine.Texture
function m.CopyTexture(src, dst) end
---@overload fun(src:UnityEngine.Texture, srcElement:int, dst:UnityEngine.Texture, dstElement:int):bool
---@param src UnityEngine.Texture
---@param dst UnityEngine.Texture
---@return bool
function m.ConvertTexture(src, dst) end
---@overload fun():UnityEngine.Rendering.GPUFence
---@param stage UnityEngine.Rendering.SynchronisationStage
---@return UnityEngine.Rendering.GPUFence
function m.CreateGPUFence(stage) end
---@overload fun(fence:UnityEngine.Rendering.GPUFence):void
---@param fence UnityEngine.Rendering.GPUFence
---@param stage UnityEngine.Rendering.SynchronisationStage
function m.WaitOnGPUFence(fence, stage) end
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, sourceRect:UnityEngine.Rect, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int, mat:UnityEngine.Material, pass:int):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int, mat:UnityEngine.Material, pass:int):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, mat:UnityEngine.Material, pass:int):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, sourceRect:UnityEngine.Rect, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int, color:UnityEngine.Color, mat:UnityEngine.Material):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, sourceRect:UnityEngine.Rect, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int, color:UnityEngine.Color):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, sourceRect:UnityEngine.Rect, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int, mat:UnityEngine.Material):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, sourceRect:UnityEngine.Rect, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int, mat:UnityEngine.Material):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, leftBorder:int, rightBorder:int, topBorder:int, bottomBorder:int):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture, mat:UnityEngine.Material):void
---@overload fun(screenRect:UnityEngine.Rect, texture:UnityEngine.Texture):void
---@param screenRect UnityEngine.Rect
---@param texture UnityEngine.Texture
---@param sourceRect UnityEngine.Rect
---@param leftBorder int
---@param rightBorder int
---@param topBorder int
---@param bottomBorder int
---@param color UnityEngine.Color
---@param mat UnityEngine.Material
---@param pass int
function m.DrawTexture(screenRect, texture, sourceRect, leftBorder, rightBorder, topBorder, bottomBorder, color, mat, pass) end
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, materialIndex:int):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4):void
---@param mesh UnityEngine.Mesh
---@param position UnityEngine.Vector3
---@param rotation UnityEngine.Quaternion
---@param materialIndex int
function m.DrawMeshNow(mesh, position, rotation, materialIndex) end
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, probeAnchor:UnityEngine.Transform, useLightProbes:bool):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:bool, receiveShadows:bool, useLightProbes:bool):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, probeAnchor:UnityEngine.Transform, lightProbeUsage:UnityEngine.Rendering.LightProbeUsage, lightProbeProxyVolume:UnityEngine.LightProbeProxyVolume):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:bool, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, position:UnityEngine.Vector3, rotation:UnityEngine.Quaternion, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, probeAnchor:UnityEngine.Transform):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:bool, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, probeAnchor:UnityEngine.Transform):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, probeAnchor:UnityEngine.Transform, useLightProbes:bool):void
---@overload fun(mesh:UnityEngine.Mesh, matrix:UnityEngine.Matrix4x4, material:UnityEngine.Material, layer:int, camera:UnityEngine.Camera, submeshIndex:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, probeAnchor:UnityEngine.Transform, lightProbeUsage:UnityEngine.Rendering.LightProbeUsage):void
---@param mesh UnityEngine.Mesh
---@param position UnityEngine.Vector3
---@param rotation UnityEngine.Quaternion
---@param material UnityEngine.Material
---@param layer int
---@param camera UnityEngine.Camera
---@param submeshIndex int
---@param properties UnityEngine.MaterialPropertyBlock
---@param castShadows bool
---@param receiveShadows bool
---@param useLightProbes bool
function m.DrawMesh(mesh, position, rotation, material, layer, camera, submeshIndex, properties, castShadows, receiveShadows, useLightProbes) end
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera, lightProbeUsage:UnityEngine.Rendering.LightProbeUsage, lightProbeProxyVolume:UnityEngine.LightProbeProxyVolume):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int, properties:UnityEngine.MaterialPropertyBlock):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, count:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera, lightProbeUsage:UnityEngine.Rendering.LightProbeUsage):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, matrices:table, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera, lightProbeUsage:UnityEngine.Rendering.LightProbeUsage):void
---@param mesh UnityEngine.Mesh
---@param submeshIndex int
---@param material UnityEngine.Material
---@param matrices table
---@param count int
---@param properties UnityEngine.MaterialPropertyBlock
---@param castShadows UnityEngine.Rendering.ShadowCastingMode
---@param receiveShadows bool
---@param layer int
---@param camera UnityEngine.Camera
---@param lightProbeUsage UnityEngine.Rendering.LightProbeUsage
---@param lightProbeProxyVolume UnityEngine.LightProbeProxyVolume
function m.DrawMeshInstanced(mesh, submeshIndex, material, matrices, count, properties, castShadows, receiveShadows, layer, camera, lightProbeUsage, lightProbeProxyVolume) end
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int, properties:UnityEngine.MaterialPropertyBlock):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera):void
---@overload fun(mesh:UnityEngine.Mesh, submeshIndex:int, material:UnityEngine.Material, bounds:UnityEngine.Bounds, bufferWithArgs:UnityEngine.ComputeBuffer, argsOffset:int, properties:UnityEngine.MaterialPropertyBlock, castShadows:UnityEngine.Rendering.ShadowCastingMode, receiveShadows:bool, layer:int, camera:UnityEngine.Camera, lightProbeUsage:UnityEngine.Rendering.LightProbeUsage):void
---@param mesh UnityEngine.Mesh
---@param submeshIndex int
---@param material UnityEngine.Material
---@param bounds UnityEngine.Bounds
---@param bufferWithArgs UnityEngine.ComputeBuffer
---@param argsOffset int
---@param properties UnityEngine.MaterialPropertyBlock
---@param castShadows UnityEngine.Rendering.ShadowCastingMode
---@param receiveShadows bool
---@param layer int
---@param camera UnityEngine.Camera
---@param lightProbeUsage UnityEngine.Rendering.LightProbeUsage
---@param lightProbeProxyVolume UnityEngine.LightProbeProxyVolume
function m.DrawMeshInstancedIndirect(mesh, submeshIndex, material, bounds, bufferWithArgs, argsOffset, properties, castShadows, receiveShadows, layer, camera, lightProbeUsage, lightProbeProxyVolume) end
---@overload fun(topology:UnityEngine.MeshTopology, vertexCount:int):void
---@param topology UnityEngine.MeshTopology
---@param vertexCount int
---@param instanceCount int
function m.DrawProcedural(topology, vertexCount, instanceCount) end
---@overload fun(topology:UnityEngine.MeshTopology, bufferWithArgs:UnityEngine.ComputeBuffer):void
---@param topology UnityEngine.MeshTopology
---@param bufferWithArgs UnityEngine.ComputeBuffer
---@param argsOffset int
function m.DrawProceduralIndirect(topology, bufferWithArgs, argsOffset) end
---@overload fun(source:UnityEngine.Texture, dest:UnityEngine.RenderTexture, scale:UnityEngine.Vector2, offset:UnityEngine.Vector2):void
---@overload fun(source:UnityEngine.Texture, dest:UnityEngine.RenderTexture, mat:UnityEngine.Material, pass:int):void
---@overload fun(source:UnityEngine.Texture, dest:UnityEngine.RenderTexture, mat:UnityEngine.Material):void
---@overload fun(source:UnityEngine.Texture, mat:UnityEngine.Material, pass:int):void
---@overload fun(source:UnityEngine.Texture, mat:UnityEngine.Material):void
---@param source UnityEngine.Texture
---@param dest UnityEngine.RenderTexture
function m.Blit(source, dest) end
---@param source UnityEngine.Texture
---@param dest UnityEngine.RenderTexture
---@param mat UnityEngine.Material
---@param offsets table
function m.BlitMultiTap(source, dest, mat, offsets) end
UnityEngine = {}
UnityEngine.Graphics = m
return m