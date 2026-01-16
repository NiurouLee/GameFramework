require("base_ins_r")
---对施法者的骨骼结点进行旋转，选择方向根据两次点选计算 第一次点选为主方向，第二次点选确认旋转方向
---@class PlayCasterBoneRotationByPickSectorInstruction: BaseInstruction
_class("PlayCasterBoneRotationByPickSectorInstruction", BaseInstruction)
PlayCasterBoneRotationByPickSectorInstruction = PlayCasterBoneRotationByPickSectorInstruction

function PlayCasterBoneRotationByPickSectorInstruction:Constructor(paramList)
    self._bone = paramList["bone"]
    local absAngle = paramList["absAngle"]
    local absAangleNum = 45
    if absAngle then
        absAangleNum = tonumber(absAngle)
    end
    
    --local finalRotateAngleZ = 0
    --self._rotation = Quaternion.Euler(0, 0, finalRotateAngleZ)
    self._absAngleNum = absAangleNum
    local strDuration = paramList["duration"]
    self._duration = strDuration and tonumber(strDuration) or 0
end

---@param casterEntity Entity
function PlayCasterBoneRotationByPickSectorInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")
    --查找骨骼结点
    local tfBone = self:GetTransform(casterEntity)
    if not tfBone then
        Log.fatal("### PlayCasterBoneRotationByPickSectorInstruction cant find bone", self._bone)
    end

    --根据点选判断正负(旋转方向)
    local finalRotateAngle = 0
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    ---@type Vector2[]
    local scopeGridList = renderPickUpComponent:GetAllValidPickUpGridPos()
    local curPos = casterEntity:GetGridPosition()
    if scopeGridList and #scopeGridList >= 2 then
        local mainDirPos = scopeGridList[1]
        local expandDirPos = scopeGridList[2]
        local mainDir = mainDirPos - curPos
        local expandDir = expandDirPos - mainDirPos
        local mainDirVec3 = Vector3(mainDir.x,mainDir.y,0)
        local expandDirVec3 = Vector3(expandDir.x,expandDir.y,0)
        local crossRes = Vector3.Cross(mainDirVec3, expandDirVec3)
        local angleDirFlag = 0
        if crossRes.z > 0 then--逆时针
            angleDirFlag = -1
        elseif crossRes.z < 0 then --顺时针
            angleDirFlag = 1
        end
        finalRotateAngle = self._absAngleNum * angleDirFlag
    end
    self._rotation = Quaternion.Euler(0, finalRotateAngle, 0)
    
    self:DORotate(TT, casterEntity, world)
end

function PlayCasterBoneRotationByPickSectorInstruction:GetTransform(e)
    local cView = e:View()
    local tran = cView.ViewWrapper.Transform
    local tfBone = GameObjectHelper.FindChild(tran, self._bone)
    return tfBone
end

---@param tfBone UnityEngine.Transform
---@param world MainWorld
function PlayCasterBoneRotationByPickSectorInstruction:DORotate(TT, e, world)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = e:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_RotateByPickSector[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.RotateByPickSector)
    local endRotation = Quaternion.identity
    if resultArray then --有Result优先处理
        for i, result in ipairs(resultArray) do
            local rotateAngle = result:GetRotateAngle()
            local dirNew = result:GetDirNew()
            local rotQua = Quaternion.Euler(0, rotateAngle, 0)
            local tfBone = self:GetTransform(e)
            endRotation = rotQua * tfBone.localRotation
            local oriRotation = tfBone.localRotation
            local tweener = tfBone:DOLocalRotateQuaternion(endRotation, self._duration * 0.001)
            tweener:OnComplete(
                function()
                    local finalDir = tfBone.forward
                    e:SetDirection(finalDir)
                    tfBone.localRotation = oriRotation
                end
            )
        end
        if self._duration > 0 then
            YIELD(TT, self._duration)
        end
    else
        local tfBone = self:GetTransform(e)
        endRotation = self._rotation * tfBone.localRotation
        local oriRotation = tfBone.localRotation
        local tweener = tfBone:DOLocalRotateQuaternion(endRotation, self._duration * 0.001)
        tweener:OnComplete(
            function()
                local finalDir = tfBone.forward
                e:SetDirection(finalDir)
                tfBone.localRotation = oriRotation
            end
        )
        if self._duration > 0 then
            YIELD(TT, self._duration)
        end
    end
end
