---@class H3D.UGUI.CircleOutline : H3D.UGUI.ModifiedShadow
---@field circleCount int
---@field firstSample int
---@field sampleIncrement int
---@field addMult bool
local m = {}
---@param verts table
function m:ModifyVertices(verts) end
H3D = {}
H3D.UGUI = {}
H3D.UGUI.CircleOutline = m
return m