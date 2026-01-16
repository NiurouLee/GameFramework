---@class UnityEngine.GL : object
---@field wireframe bool
---@field sRGBWrite bool
---@field invertCulling bool
---@field modelview UnityEngine.Matrix4x4
---@field TRIANGLES int
---@field TRIANGLE_STRIP int
---@field QUADS int
---@field LINES int
---@field LINE_STRIP int
local m = {}
---@param x float
---@param y float
---@param z float
function m.Vertex3(x, y, z) end
---@param v UnityEngine.Vector3
function m.Vertex(v) end
---@param x float
---@param y float
---@param z float
function m.TexCoord3(x, y, z) end
---@param v UnityEngine.Vector3
function m.TexCoord(v) end
---@param x float
---@param y float
function m.TexCoord2(x, y) end
---@param unit int
---@param x float
---@param y float
---@param z float
function m.MultiTexCoord3(unit, x, y, z) end
---@param unit int
---@param v UnityEngine.Vector3
function m.MultiTexCoord(unit, v) end
---@param unit int
---@param x float
---@param y float
function m.MultiTexCoord2(unit, x, y) end
---@param c UnityEngine.Color
function m.Color(c) end
function m.Flush() end
function m.RenderTargetBarrier() end
---@param m UnityEngine.Matrix4x4
function m.MultMatrix(m) end
function m.PushMatrix() end
function m.PopMatrix() end
function m.LoadIdentity() end
function m.LoadOrtho() end
---@overload fun(left:float, right:float, bottom:float, top:float):void
function m.LoadPixelMatrix() end
---@param mat UnityEngine.Matrix4x4
function m.LoadProjectionMatrix(mat) end
function m.InvalidateState() end
---@param proj UnityEngine.Matrix4x4
---@param renderIntoTexture bool
---@return UnityEngine.Matrix4x4
function m.GetGPUProjectionMatrix(proj, renderIntoTexture) end
---@param callback System.IntPtr
---@param eventID int
function m.IssuePluginEvent(callback, eventID) end
---@param mode int
function m.Begin(mode) end
function m.End() end
---@overload fun(clearDepth:bool, clearColor:bool, backgroundColor:UnityEngine.Color):void
---@param clearDepth bool
---@param clearColor bool
---@param backgroundColor UnityEngine.Color
---@param depth float
function m.Clear(clearDepth, clearColor, backgroundColor, depth) end
---@param pixelRect UnityEngine.Rect
function m.Viewport(pixelRect) end
---@param clearDepth bool
---@param camera UnityEngine.Camera
function m.ClearWithSkybox(clearDepth, camera) end
UnityEngine = {}
UnityEngine.GL = m
return m