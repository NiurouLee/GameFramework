--[[
    处理宿舍剪影
]]
---@class UIDomitorySketch:Object
_class("UIDomitorySketch", Object)
UIDomitorySketch = UIDomitorySketch

function UIDomitorySketch:Constructor(rawimage)
    ---@type UnityEngine.UI.RawImage
    self._sketchImage = rawimage
    self._req = ResourceManager:GetInstance():SyncLoadAsset("HomeDomitorySketch.prefab", LoadType.GameObject)
    local sketchGo = self._req.Obj
    sketchGo:SetActive(true)
    sketchGo.transform.position = Vector3(1000, 1000, 1000)
    ---@type UnityEngine.Camera
    local camera = sketchGo:GetComponent(typeof(UnityEngine.Camera))
    camera.clearFlags = UnityEngine.CameraClearFlags.Color
    camera.backgroundColor = Color.clear
    local rect = self._sketchImage.rectTransform.rect
    self._imageWidth = rect.width
    self._imageHeight = rect.height
    local rt =
        UnityEngine.RenderTexture.GetTemporary(
        self._imageWidth,
        self._imageHeight,
        16,
        UnityEngine.RenderTextureFormat.ARGB32
    )
    camera.targetTexture = rt
    camera:SetReplacementShader(GraphicUtli.Find("H3D/Actor/SketchBlack"), "")
    self._sketchCamera = camera
    self._sketchImage.texture = rt
    self._sketchParent = self._sketchCamera.transform
    ---@type table<number,HomelandPetRequestSync>
    self._petReqPool = {}

    --气泡相关
    self._imageRect = self._sketchImage.rectTransform
    self._bubbleTr = self._imageRect:Find("Bubble")
    self._bubbleLoader = self._bubbleTr.gameObject:GetComponent(typeof(RawImageLoader))
    ---@type table<number,UnityEngine.Transform>
    self._petHeadTrans = {}
    self._bubbleIndex = {1, 2, 3, 4}
    self._bubbleImages = {
        "n17_dorm_bubble01"
    }
    self._curBubbleIndex = nil
    self._curBubbleImage = nil
    self._bubbleImageIndex = {}
    for i = 1, #self._bubbleImages do
        self._bubbleImageIndex[i] = i
    end

    self._timer = 0
end

function UIDomitorySketch:Update(dtMs)
    self._timer = self._timer - dtMs
    if self._timer < 0 then
        self:_ResetBubble()
    end
end

function UIDomitorySketch:Dispose()
    self._sketchCamera:ResetReplacementShader()
    self._sketchCamera = nil
    self._req:Dispose()
    self._req = nil
    for _, req in pairs(self._petReqPool) do
        req:Dispose()
    end
    self._petReqPool = nil
end

---@param pets table<number,Pet>
function UIDomitorySketch:OnChange(pets)
    local tmpReqs = {}
    for i = 1, 4 do
        ---@type Pet
        local pet = pets[i]
        local petTr = nil
        if pet then
            local petID = pet:GetTemplateID()
            ---@type HomelandPetRequestSync
            local req = self._petReqPool[petID]
            if req then
                self._petReqPool[petID] = nil
            else
                local prefab =
                    HelperProxy:GetInstance():GetPetPrefab(
                    petID,
                    pet:GetPetGrade(),
                    pet:GetSkinId(),
                    PetSkinEffectPath.MODEL_AIRCRAFT
                )
                req = HomelandPetRequestSync:New(petID, pet:GetPstID(), prefab, nil)
            end
            req:PetGameObject():SetActive(true)
            petTr = req:PetGameObject().transform
            local root = petTr:Find("Root")
            --默认隐藏武器
            for i = 0, root.childCount - 1 do
                local child = root:GetChild(i)
                if string.find(child.name, "weapon") then
                    child.gameObject:SetActive(false)
                end
            end
            petTr:SetParent(self._sketchParent:GetChild(i - 1))
            petTr.localPosition = Vector3.zero
            petTr.localRotation = Quaternion.identity
            petTr.localScale = Vector3.one
            tmpReqs[petID] = req
        end
        local head = nil
        if petTr then
            head = GameObjectHelper.FindChild(petTr, "Bip001 Head")
            if not head then
                Log.exception("星灵没有头部挂点:", petTr.name)
            end
        end
        self._petHeadTrans[i] = head
    end
    for _, req in pairs(self._petReqPool) do
        req:Dispose()
    end
    self._petReqPool = tmpReqs
    self:ResetStartBubble()
end

function UIDomitorySketch:AllPetPlayAnimation(animName)
    if self._petReqPool == nil then
        return
    end

    for k, v in pairs(self._petReqPool) do
        v:PetAnimation():Play(animName)
    end
end

function UIDomitorySketch:PlayAnimation(petID, animName)
    local petReq = nil
    if self._petReqPool ~= nil then
        petReq = self._petReqPool[petID]
    end

    if petReq ~= nil then
        petReq:PetAnimation():Play(animName)
    end
end

function UIDomitorySketch:ResetStartBubble()
    self._timer = math.random(3000, 6000)
    self._curBubbleImage = nil
    self._curBubbleIndex = nil
    self._bubbleTr.gameObject:SetActive(false)
end

function UIDomitorySketch:_ResetBubble()
    self._timer = math.random(5000, 10000)
    table.shuffle(self._bubbleIndex)
    for i = 1, 4 do
        local idx = self._bubbleIndex[i]
        local head = self._petHeadTrans[idx]
        if head and idx ~= self._curBubbleIndex then
            self._curBubbleIndex = idx

            table.shuffle(self._bubbleImageIndex)
            local image = nil
            for j = 1, #self._bubbleImages do
                local imageIdx = self._bubbleImageIndex[j]
                if imageIdx ~= self._curBubbleImage then
                    image = self._bubbleImages[imageIdx]
                    break
                end
            end
            if image then
                if not self._curBubbleImage then
                    self._bubbleTr.gameObject:SetActive(true)
                end
                self._bubbleLoader:LoadImage(image)
                self._curBubbleImage = image
                local pos = self:_GetLocalPos(head)
                self._bubbleTr.localPosition = pos
            else
                if self._curBubbleImage then
                    self._bubbleTr.gameObject:SetActive(false)
                end
                self._curBubbleImage = nil
            end
            break
        end
    end
end

function UIDomitorySketch:_GetLocalPos(head)
    local screenPositon = self._sketchCamera:WorldToScreenPoint(head.position)
    return Vector3(screenPositon.x, screenPositon.y + 15, 0)
end
