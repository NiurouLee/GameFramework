---@class UIPetIntimacyStarGroup:UICustomWidget
_class("UIPetIntimacyStarGroup", UICustomWidget)
UIPetIntimacyStarGroup = UIPetIntimacyStarGroup

---@param pet MatchPet
function UIPetIntimacyStarGroup:SetData(pet, scale, spacing)
    if not pet then
        return
    end

    local constMax = 6
    local petStar = pet:GetPetStar()
    local awakenStep = pet:GetPetAwakening()

    local objs = UIWidgetHelper.SpawnObjects(self, "_root", "UIPetIntimacyStar", constMax)
    for i = 1, #objs do
        objs[i]:GetGameObject():SetActive(i <= petStar)
        objs[i]:Refresh(i <= awakenStep)
    end

    scale = scale or 1
    self:_SetScale(Vector3(scale, scale, scale))
    self:_SetSpacing(spacing or 0)
end

---@param scale Vector3
function UIPetIntimacyStarGroup:_SetScale(scale)
    local trans = self:GetUIComponent("RectTransform", "_root")
    trans.localScale = scale
end

function UIPetIntimacyStarGroup:_SetSpacing(x)
    local grid = self:GetUIComponent("GridLayoutGroup", "_root")
    grid.spacing = Vector2(x, 0)
end