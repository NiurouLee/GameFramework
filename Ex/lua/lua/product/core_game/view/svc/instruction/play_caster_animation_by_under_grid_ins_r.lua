require("base_ins_r")

---@class PlayCasterAnimationByUnderGridInstruction: BaseInstruction
_class("PlayCasterAnimationByUnderGridInstruction", BaseInstruction)
PlayCasterAnimationByUnderGridInstruction = PlayCasterAnimationByUnderGridInstruction

function PlayCasterAnimationByUnderGridInstruction:Constructor(paramList)
    self._redAnim = paramList["redAnim"]
    self._yellowAnim = paramList["yellowAnim"]
    self._blueAnim = paramList["blueAnim"]
    self._greenAnim = paramList["greenAnim"]
    local deadPlay = tonumber(paramList["deadPlay"]) or 0
    if deadPlay == 1 then
        self._deadPlay = true
    end
end

---@param casterEntity Entity
function PlayCasterAnimationByUnderGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type Entity
    local e = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end
    if not e:HasView() then
        Log.fatal("view not found, cant play legacy animation")
        return
    end
    self._world = e:GetOwnerWorld()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if utilDataSvc:IsEntityLogicDead(e) and not self._deadPlay then
        return
    end
    ---@type Vector2
    local gridPos = e:GetRenderGridPosition()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pieceType = utilDataSvc:GetPieceType(gridPos)
    local animName
    if pieceType == PieceType.Blue then
        animName = self._blueAnim
    elseif pieceType == PieceType.Red then
        animName = self._redAnim
    elseif pieceType == PieceType.Green then
        animName = self._greenAnim
    elseif pieceType == PieceType.Yellow then
        animName = self._yellowAnim
    else
        animName = self._blueAnim
    end
    local go = e:View():GetGameObject()
    ---@type UnityEngine.Animation
    local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
    if anim == nil then
        Log.fatal("Cant play legacy animation, animation not found in ", go.name)
        return
    end

    ---已经播放了，则不变
    if not anim:IsPlaying(animName) then
        anim:Play(animName)
    end
end
