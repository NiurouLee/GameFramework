---@class Spine.Skeleton : object
---@field Data Spine.SkeletonData
---@field Bones Spine.ExposedList
---@field UpdateCacheList Spine.ExposedList
---@field Slots Spine.ExposedList
---@field DrawOrder Spine.ExposedList
---@field IkConstraints Spine.ExposedList
---@field PathConstraints Spine.ExposedList
---@field TransformConstraints Spine.ExposedList
---@field Skin Spine.Skin
---@field R float
---@field G float
---@field B float
---@field A float
---@field Time float
---@field X float
---@field Y float
---@field ScaleX float
---@field ScaleY float
---@field RootBone Spine.Bone
local m = {}
function m:UpdateCache() end
---@overload fun(parent:Spine.Bone):void
function m:UpdateWorldTransform() end
function m:SetToSetupPose() end
function m:SetBonesToSetupPose() end
function m:SetSlotsToSetupPose() end
---@param boneName string
---@return Spine.Bone
function m:FindBone(boneName) end
---@param boneName string
---@return int
function m:FindBoneIndex(boneName) end
---@param slotName string
---@return Spine.Slot
function m:FindSlot(slotName) end
---@param slotName string
---@return int
function m:FindSlotIndex(slotName) end
---@overload fun(newSkin:Spine.Skin):void
---@param skinName string
function m:SetSkin(skinName) end
---@overload fun(slotIndex:int, attachmentName:string):Spine.Attachment
---@param slotName string
---@param attachmentName string
---@return Spine.Attachment
function m:GetAttachment(slotName, attachmentName) end
---@param slotName string
---@param attachmentName string
function m:SetAttachment(slotName, attachmentName) end
---@param constraintName string
---@return Spine.IkConstraint
function m:FindIkConstraint(constraintName) end
---@param constraintName string
---@return Spine.TransformConstraint
function m:FindTransformConstraint(constraintName) end
---@param constraintName string
---@return Spine.PathConstraint
function m:FindPathConstraint(constraintName) end
---@param delta float
function m:Update(delta) end
---@param x float
---@param y float
---@param width float
---@param height float
---@param vertexBuffer float[]
function m:GetBounds(x, y, width, height, vertexBuffer) end
Spine = {}
Spine.Skeleton = m
return m