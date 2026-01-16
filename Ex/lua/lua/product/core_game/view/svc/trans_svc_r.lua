--[[------------------
    Transform服务
--]] ------------------

_class("TransformServiceRenderer", Object)
---@class TransformServiceRenderer:Object
TransformServiceRenderer = TransformServiceRenderer

function TransformServiceRenderer:Constructor(world)
    ---@type MainWorld
	self._world = world
	self._animName ={
        [PieceType.Blue] = "eff_BoundingBox_Blue_loop",
        [PieceType.Green] = "eff_BoundingBox_Green_loop",
        [PieceType.Red] = "eff_BoundingBox_Red_loop",
        [PieceType.Yellow] = "eff_BoundingBox_Yellow_loop",
        [PieceType.None] = "eff_BoundingBox_White_loop"
    }
    self._releaseAnimName = {
        [PieceType.Blue] = "eff_BoundingBox_chain_Blue",
        [PieceType.Green] = "eff_BoundingBox_chain_Green",
        [PieceType.Red] = "eff_BoundingBox_chain_Red",
        [PieceType.Yellow] = "eff_BoundingBox_chain_Yellow",
        [PieceType.None] = "eff_BoundingBox_chain_White",
    }
end

---@param e Entity
function TransformServiceRenderer:SimpleSyncLocation(e)
    local pos = e:Location().Position:Clone()
    local dir = e:Location().Direction:Clone()
	local scale = e:Location().Scale:Clone()
    self:SetEntityLocation(e, pos, dir, scale)
    if e:HasPetPstID() then
        ---@type Entity
        local teamEntity =  e:Pet():GetOwnerTeamEntity()
        local teamLeaderEntityId = teamEntity:Team():GetTeamLeaderEntityID()
		---队长移动带着血条走
		if e:GetID() == teamLeaderEntityId then
			---@type HPComponent
			local hpCmpt = teamEntity:HP()
			hpCmpt:SetHPPosDirty(true)
		end
	else
		---通知血条刷新
		if e:HasHP() then
			---@type HPComponent
			local hpCmpt = e:HP()
			hpCmpt:SetHPPosDirty(true)
		end
	end
end

---@param e Entity
---@param pos Vector3
---@param dir Vector3
---@param scale Vector3
function TransformServiceRenderer:SetEntityLocation(e, pos, dir, scale)
    local view = e:View()
    if scale == nil then
        scale = Vector3(1, 1, 1)
	end
	if view then
        view.ViewWrapper:SyncTransform(pos, dir, scale, e:GetID(), e:HasOutsideRegion())
	end
end

---@param e Entity
function TransformServiceRenderer:PlaySkillRangeAnim(e)
	---@type SkillRangeOutlineComponent
	local skillRangeOutlineComponent = e:SkillRangeOutline()
	local pieceType = skillRangeOutlineComponent:GetPieceType()
	local isPreview = skillRangeOutlineComponent:IsPreview()
	if pieceType ~= nil then
		local view = e:View()
		local go = view:GetGameObject()
		local anim = go:GetComponent(typeof(UnityEngine.Animation))
		anim:Stop()
		if isPreview then
			anim:Play(self._animName[pieceType])
		else
			anim:Play(self._releaseAnimName[pieceType])
		end
	end
end
