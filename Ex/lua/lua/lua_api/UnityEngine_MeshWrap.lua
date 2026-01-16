---@class UnityEngine.Mesh : UnityEngine.Object
---@field indexFormat UnityEngine.Rendering.IndexFormat
---@field vertexBufferCount int
---@field blendShapeCount int
---@field boneWeights table
---@field bindposes table
---@field isReadable bool
---@field vertexCount int
---@field subMeshCount int
---@field bounds UnityEngine.Bounds
---@field vertices table
---@field normals table
---@field tangents table
---@field uv table
---@field uv2 table
---@field uv3 table
---@field uv4 table
---@field uv5 table
---@field uv6 table
---@field uv7 table
---@field uv8 table
---@field colors table
---@field colors32 table
---@field triangles table
local m = {}
---@param index int
---@return System.IntPtr
function m:GetNativeVertexBufferPtr(index) end
---@return System.IntPtr
function m:GetNativeIndexBufferPtr() end
function m:ClearBlendShapes() end
---@param shapeIndex int
---@return string
function m:GetBlendShapeName(shapeIndex) end
---@param blendShapeName string
---@return int
function m:GetBlendShapeIndex(blendShapeName) end
---@param shapeIndex int
---@return int
function m:GetBlendShapeFrameCount(shapeIndex) end
---@param shapeIndex int
---@param frameIndex int
---@return float
function m:GetBlendShapeFrameWeight(shapeIndex, frameIndex) end
---@param shapeIndex int
---@param frameIndex int
---@param deltaVertices table
---@param deltaNormals table
---@param deltaTangents table
function m:GetBlendShapeFrameVertices(shapeIndex, frameIndex, deltaVertices, deltaNormals, deltaTangents) end
---@param shapeName string
---@param frameWeight float
---@param deltaVertices table
---@param deltaNormals table
---@param deltaTangents table
function m:AddBlendShapeFrame(shapeName, frameWeight, deltaVertices, deltaNormals, deltaTangents) end
---@param uvSetIndex int
---@return float
function m:GetUVDistributionMetric(uvSetIndex) end
---@param vertices table
function m:GetVertices(vertices) end
---@param inVertices table
function m:SetVertices(inVertices) end
---@param normals table
function m:GetNormals(normals) end
---@param inNormals table
function m:SetNormals(inNormals) end
---@param tangents table
function m:GetTangents(tangents) end
---@param inTangents table
function m:SetTangents(inTangents) end
---@overload fun(colors:table):void
---@param colors table
function m:GetColors(colors) end
---@overload fun(inColors:table):void
---@param inColors table
function m:SetColors(inColors) end
---@overload fun(channel:int, uvs:table):void
---@overload fun(channel:int, uvs:table):void
---@param channel int
---@param uvs table
function m:SetUVs(channel, uvs) end
---@overload fun(channel:int, uvs:table):void
---@overload fun(channel:int, uvs:table):void
---@param channel int
---@param uvs table
function m:GetUVs(channel, uvs) end
---@overload fun(submesh:int, applyBaseVertex:bool):table
---@overload fun(triangles:table, submesh:int):void
---@overload fun(triangles:table, submesh:int, applyBaseVertex:bool):void
---@param submesh int
---@return table
function m:GetTriangles(submesh) end
---@overload fun(submesh:int, applyBaseVertex:bool):table
---@overload fun(indices:table, submesh:int):void
---@overload fun(indices:table, submesh:int, applyBaseVertex:bool):void
---@param submesh int
---@return table
function m:GetIndices(submesh) end
---@param submesh int
---@return uint
function m:GetIndexStart(submesh) end
---@param submesh int
---@return uint
function m:GetIndexCount(submesh) end
---@param submesh int
---@return uint
function m:GetBaseVertex(submesh) end
---@overload fun(triangles:table, submesh:int, calculateBounds:bool):void
---@overload fun(triangles:table, submesh:int, calculateBounds:bool, baseVertex:int):void
---@overload fun(triangles:table, submesh:int):void
---@overload fun(triangles:table, submesh:int, calculateBounds:bool):void
---@overload fun(triangles:table, submesh:int, calculateBounds:bool, baseVertex:int):void
---@param triangles table
---@param submesh int
function m:SetTriangles(triangles, submesh) end
---@overload fun(indices:table, topology:UnityEngine.MeshTopology, submesh:int, calculateBounds:bool):void
---@overload fun(indices:table, topology:UnityEngine.MeshTopology, submesh:int, calculateBounds:bool, baseVertex:int):void
---@param indices table
---@param topology UnityEngine.MeshTopology
---@param submesh int
function m:SetIndices(indices, topology, submesh) end
---@param bindposes table
function m:GetBindposes(bindposes) end
---@param boneWeights table
function m:GetBoneWeights(boneWeights) end
---@overload fun():void
---@param keepVertexLayout bool
function m:Clear(keepVertexLayout) end
function m:RecalculateBounds() end
function m:RecalculateNormals() end
function m:RecalculateTangents() end
function m:MarkDynamic() end
---@param markNoLongerReadable bool
function m:UploadMeshData(markNoLongerReadable) end
---@param submesh int
---@return UnityEngine.MeshTopology
function m:GetTopology(submesh) end
---@overload fun(combine:table, mergeSubMeshes:bool, useMatrices:bool):void
---@overload fun(combine:table, mergeSubMeshes:bool):void
---@overload fun(combine:table):void
---@param combine table
---@param mergeSubMeshes bool
---@param useMatrices bool
---@param hasLightmapData bool
function m:CombineMeshes(combine, mergeSubMeshes, useMatrices, hasLightmapData) end
UnityEngine = {}
UnityEngine.Mesh = m
return m