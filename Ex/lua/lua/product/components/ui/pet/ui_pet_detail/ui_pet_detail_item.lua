---@class UIPetDetailItem : UICustomWidget
_class("UIPetDetailItem", UICustomWidget)
UIPetDetailItem = UIPetDetailItem
function UIPetDetailItem:Constructor()
    self._index = 0
    self._isCurrent = false
    self._dynamicAndStaticState = DynamicAndStaticState.None
    ---@type PetModule
    self._module = GameGlobal.GetModule(PetModule)
    self._open = true
end

function UIPetDetailItem:OnShow(uiParams)
    self._cg = self:GetUIComponent("RawImageLoader", "cg")
    ---@type UnityEngine.UI.RawImage
    self._rawImage = self:GetUIComponent("RawImage", "cg")
    self._cgGo = self:GetGameObject("cg")
    self._spine = self:GetUIComponent("RectTransform", "spine")
    self._spineGo = self:GetGameObject("spine")
    self._center = self:GetUIComponent("RectTransform", "center")

    self:AttachEvents()
end

function UIPetDetailItem:AttachEvents()
    self:AttachEvent(GameEventType.PetUpGradeEvent, self.ObservationUpGradeRefresh)
    self:AttachEvent(GameEventType.PetDetailChangeCgState, self.ChangeDynamicAndStatic)
    self:AttachEvent(GameEventType.CheckIsCurrent, self.CheckIsCurrent)
end
function UIPetDetailItem:RemoveEvents()
    self:DetachEvent(GameEventType.PetUpGradeEvent, self.ObservationUpGradeRefresh)
    self:DetachEvent(GameEventType.PetDetailChangeCgState, self.ChangeDynamicAndStatic)
    self:DetachEvent(GameEventType.CheckIsCurrent, self.CheckIsCurrent)
end

--突破
function UIPetDetailItem:ObservationUpGradeRefresh(pstid)
    if self._pstid == pstid then
        ---@type Pet
        self._pet = self._module:GetPet(pstid)
        local matName = self._pet:GetPetStaticBody(PetSkinEffectPath.BODY_AWAKE)
        local spineName = self._pet:GetPetSpine(PetSkinEffectPath.BODY_AWAKE)

        self:LoadCgSync(matName, true)
        self:LoadSpineSync(spineName, true)
    end
end

function UIPetDetailItem:OnHide()
    self._index = 0
    if self._matAsset then
        self._matAsset:Dispose()
    end
    if self._spineAsset then
        self._spineAsset:Dispose()
    end
    self:RemoveEvents()
end

function UIPetDetailItem:OnHideCallBack()
    if self._matAsset then
        self._matAsset:Dispose()
    end
    if self._spineAsset then
        self._spineAsset:Dispose()
    end
    self._spineAsset = nil
    self._matAsset = nil
end

function UIPetDetailItem:SetData(index, pet, state, matName, spineName, spineRoot, idx)
    self._index = index
    self._isCurrent = (self._index == idx)
    ---@type MatchPet
    self._pet = pet
    self._pstid = self._pet:GetPstID()
    self._petid = self._pet:GetTemplateID()
    self._spineRoot = spineRoot
    self._state = state

    local size = Cfg.cfg_global["ui_interface_common_size"].ArrayValue
    self._cgGo:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
    self:ChangeDynamicAndStatic(self._index, state)
    --if math.abs(self._index - idx) <= 1 then
    if self._isCurrent then
        --如果是当前的，先把alpha置为1
        --否则为0
        --[[
            GameGlobal.TaskManager():StartTask(self.OnSetData, self, matName)
            
            GameGlobal.TaskManager():StartTask(self.OnSetDataSpine, self, spineName)
            ]]
        --同步

        self:LoadCgSync(matName)
        self:LoadSpineSync(spineName)
    else
        --异步
        GameGlobal.TaskManager():StartTask(self.OnSetData, self, matName, true)

        GameGlobal.TaskManager():StartTask(self.OnSetDataSpine, self, spineName, true)
    end
end
function UIPetDetailItem:RefreshSkinAppearance(matName, spineName)
    self:LoadCgSync(matName, true)
    self:LoadSpineSync(spineName, true)
end
function UIPetDetailItem:LoadCgSync(matName, force)
    if not self._index or self._index == 0 then
        return
    end
    if self._matAsset == nil or force then
        if self._matAsset ~= nil then
            self._matAsset:Dispose()
        end
        local resName = ""
        if matName then
            resName = matName .. ".mat"
            if ResourceManager:GetInstance():HasResource(resName) then
                self._matAsset = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.Mat)
            end
        end
    end
    if self._matAsset == nil or self._matAsset.Obj == nil then
        return
    end
    self._cg:SetMat(matName, self._matAsset.Obj, false)

    UICG.SetTransform(self._cgGo.transform, self:GetName(), matName)

    local alpha = 0
    if force then
        alpha = 1
    end

    self._rawImage.color = Color(1, 1, 1, alpha)
end
function UIPetDetailItem:LoadSpineSync(spineName, force)
    if not self._index or self._index == 0 then
        return
    end
    if self._spineAsset == nil or force then
        if self._spineAsset ~= nil then
            self._spineAsset:Dispose()
            self._spineAsset = nil
        end
        local resName = ""
        if spineName then
            resName = spineName .. ".prefab"
            if ResourceManager:GetInstance():HasResource(resName) then
                self._spineAsset = ResourceManager:GetInstance():SyncLoadAsset(resName, LoadType.GameObject)
            end
        end
    end
    if self._spineAsset == nil then
        Log.fatal("###[UIPetDetailItem]self._spineAsset == nil!spineName-->", spineName)
        return
    end
    if self._spineAsset.Obj == nil then
        Log.fatal("###[UIPetDetailItem]self._spineAsset == nil!spineName-->", spineName)
        return
    end
    self._spineAsset.Obj.transform:SetParent(self._spineGo.transform)
    self._spineAsset.Obj.transform.localPosition = Vector3(0, 0, 0)
    self._spineAsset.Obj.transform.localScale = Vector3(1, 1, 1)
    self._spineAsset.Obj.transform.localRotation = Quaternion(0, 0, 0, 0)
    self._spineAsset.Obj:SetActive(true)
    self:SetSpineMat()
    UICG.SetTransform(self._spineGo.transform, self:GetName(), spineName)

    local alpha = 0
    if force then
        alpha = 1
    end

    if self._spineSke then
        self._spineSke.color = Color(1, 1, 1, alpha)
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.A = alpha
    end
end

function UIPetDetailItem:SetAnimAlpha(alpha)
    self._rawImage.color = Color(1, 1, 1, alpha)
    if self._spineSke then
        self._spineSke.color = Color(1, 1, 1, alpha)
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.A = alpha
    end
end

function UIPetDetailItem:OpenAndCloseOtherAlpha(open)
    self._open = open
end

function UIPetDetailItem:OnSetData(TT, matName, hideAlpha)
    if not self._index or self._index == 0 then
        return
    end

    if self._matAsset == nil then
        local resName = ""
        if matName then
            resName = matName .. ".mat"
            if ResourceManager:GetInstance():HasResource(resName) then
                self._matAsset = ResourceManager:GetInstance():AsyncLoadAsset(TT, resName, LoadType.Mat)
            end
        end

        local logMatName = matName or "nil"
        if self._matAsset == nil then
            Log.fatal(
                "###[UIPetDetailItem] error --> the load asset is nil ! id --> ",
                self._petid,
                " , name is ",
                logMatName
            )
            return
        end
        if self._matAsset.Obj == nil then
            Log.fatal(
                "###[UIPetDetailItem] error --> the load asset obj is nil ! id --> ",
                self._petid,
                " , name is ",
                logMatName
            )
            return
        end
    end

    if not self._index or self._index == 0 then
        self._matAsset:Dispose()
        return
    end

    self._cg:SetMat(matName, self._matAsset.Obj, false)
    UICG.SetTransform(self._cgGo.transform, self:GetName(), matName)

    local alpha = 1
    if hideAlpha then
        alpha = 0
    end
    self._rawImage.color = Color(1, 1, 1, alpha)
end
function UIPetDetailItem:OnSetDataSpine(TT, spineName, hideAlpha)
    if not self._index or self._index == 0 then
        return
    end
    if self._spineAsset == nil then
        if spineName then
            if ResourceManager:GetInstance():HasResource(spineName .. ".prefab") then
                self._spineAsset = ResourceManager:GetInstance():AsyncLoadAsset(TT, spineName .. ".prefab", LoadType.GameObject)
            end
        end

        if self._spineAsset == nil then
            Log.fatal("###error --> the load asset is nil ! name is ", spineName)
            return
        end

        if self._spineAsset.Obj == nil then
            Log.fatal("###error --> the load asset obj is nil ! name is ", spineName)
            return
        end
    end
    if not self._index or self._index == 0 then
        self._spineAsset:Dispose()
        return
    end
    self._spineAsset.Obj.transform:SetParent(self._spineGo.transform)
    self._spineAsset.Obj.transform.localPosition = Vector3(0, 0, 0)
    self._spineAsset.Obj.transform.localScale = Vector3(1, 1, 1)
    self._spineAsset.Obj.transform.localRotation = Quaternion(0, 0, 0, 0)
    self._spineAsset.Obj:SetActive(true)
    self:SetSpineMat()
    UICG.SetTransform(self._spineGo.transform, self:GetName(), spineName)

    local alpha = 1
    if hideAlpha then
        alpha = 0
    end

    if self._spineSke then
        self._spineSke.color = Color(1, 1, 1, alpha)
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.A = alpha
    end
end

function UIPetDetailItem:SetSpineMat()
    --[[
        --如果不设置没法改变透明，
        ]]
    ---@type Spine.Unity.SkeletonGraphic spine骨骼
    self._spineSke = nil
    ---@type Spine.Unity.Modules.SkeletonGraphicMultiObject
    self._spineSkeMultipleTex = nil

    if self._spineAsset then
        self._spineSke = self._spineAsset.Obj:GetComponentInChildren(typeof(Spine.Unity.SkeletonGraphic))
        self._spineSkeMultipleTex =
            self._spineAsset.Obj:GetComponentInChildren(typeof(Spine.Unity.Modules.SkeletonGraphicMultiObject))
    else
        return
    end

    if self._spineSke then
        self._spineSke.material = UnityEngine.Material:New(self._spineSke.material)
        self._spineSke.material:SetFloat("_StencilComp", 2)
    elseif self._spineSkeMultipleTex then
        self._spineSkeMultipleTex.UseInstanceMaterials = true
        self._spineSkeMultipleTex:UpdateMesh()
        local renderers = self._spineSkeMultipleTex.canvasRenderers
        for i = 0, renderers.Count - 1 do
            local tmp = renderers[i]
            local tmpMat = tmp:GetMaterial(0)
            if tmpMat then
                tmpMat:SetFloat("_StencilComp", 2)
            end
            --renderers[i]:GetMaterial(0):SetFloat("_StencilComp", 2)
        end
    end
end

----------------------------------------动态静态,对外接口
function UIPetDetailItem:ChangeDynamicAndStatic(index, state)
    if index ~= self._index then
        return
    end
    if self._dynamicAndStaticState ~= state then
        self._dynamicAndStaticState = state
        if self._dynamicAndStaticState == DynamicAndStaticState.Dynamic then
            self._cgGo:SetActive(false)
            self._spineGo:SetActive(true)
        elseif self._dynamicAndStaticState == DynamicAndStaticState.Static then
            self._cgGo:SetActive(true)
            self._spineGo:SetActive(false)
        end
    end
end

--function UIPetDetailItem:ChangeCanvasGroupAlpha(alpha) --old
function UIPetDetailItem:ChangeCanvasGroupAlpha(all, centerX)
    if not self._open then
        return
    end

    local dis = math.abs(self._center.position.x - centerX)
    local rate = dis / (all * 0.5)
    if rate > 1 then
        rate = 1
    elseif rate < 0 then
        rate = 0
    end

    local alpha = 1 - rate

    if self._spineAsset ~= nil then
        if self._spineSke then
            self._spineSke.color = Color(1, 1, 1, alpha)
        elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
            self._spineSkeMultipleTex.Skeleton.A = alpha
        end
    end
    self._rawImage.color = Color(1, 1, 1, alpha)
end

function UIPetDetailItem:CheckIsCurrent(curridx)
    self._isCurrent = (self._index == curridx)
end
