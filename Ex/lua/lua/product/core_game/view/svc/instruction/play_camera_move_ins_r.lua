require("base_ins_r")
---@class PlayCameraMoveInstruction: BaseInstruction
_class("PlayCameraMoveInstruction", BaseInstruction)
PlayCameraMoveInstruction = PlayCameraMoveInstruction

function PlayCameraMoveInstruction:Constructor(paramList)
    self._index = tonumber(paramList["index"])
    self._moveTime = tonumber(paramList["moveTime"])
    self._waitTime = tonumber(paramList["waitTime"])
    self._resetTime = tonumber(paramList["resetTime"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCameraMoveInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local minHeight = BattleConst.MinScreenHeight
    local maxHeight = BattleConst.MaxScreenHeight
    local offset = BattleConst.CameraOffsetArray[self._index]
    local maxOffsetX = offset.x
    local maxOffsetY = offset.y
    local maxOffsetZ = offset.z

    local world = casterEntity:GetOwnerWorld()
    --获取摄像机
    local mainCamera = world:MainCamera():Camera()
    --获取释放者的位置
    local location = casterEntity:Location()
    local casterPos = location.Position
    --释放者的视口坐标
    local viewPortPos = mainCamera:WorldToViewportPoint(casterPos)
    if viewPortPos.y <= minHeight then
        return
    end
    --计算偏移值
    local percent = (viewPortPos.y - minHeight) / (maxHeight - minHeight)
    if percent > 1 then
        percent = 1
    end
    local offsetY = maxOffsetY * percent
    local offsetX = maxOffsetX * percent
    local offsetZ = maxOffsetZ * percent
    --移动摄像机
    local cameraTran = mainCamera.transform
    local targetPos = cameraTran:TransformPoint(Vector3(offsetX, offsetY, offsetZ))
    local originalPos = cameraTran.position
    cameraTran:DOMove(targetPos, self._moveTime / 1000.0, false)
    YIELD(TT, self._moveTime)
    YIELD(TT, self._waitTime)
    cameraTran:DOMove(originalPos, self._resetTime / 1000.0, false)
    YIELD(TT, self._resetTime)
end
