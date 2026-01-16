---@class UIPetSkinObtainController : UIController
_class("UIPetSkinObtainController", UIController)
UIPetSkinObtainController = UIPetSkinObtainController
function UIPetSkinObtainController:Constructor()
end
function UIPetSkinObtainController:OnShow(uiParams)
    ---@type RoleAsset
    local skinInfo = uiParams[1]
    if not skinInfo then
        self:Close()
        return
    end
    self._callback = uiParams[2] --关闭回调
    ---@type PetObtainAnimBase
    self._curAnim = nil
    local id = skinInfo.assetid
    local petId = 0
    local skinId = 0
    local isNew = true
    skinId = id
    local curSkinCfg = Cfg.cfg_pet_skin[skinId]
    if curSkinCfg then
        petId = curSkinCfg.PetId
    end
    self._getSkinInfo = ObtainPet:New(petId, isNew,skinId)
    self:InitWidget()
    self._anim = self:getAnim(self._getSkinInfo)
    self._anim:SetAsFirst()
    self._anim:Prepare()
    self:PlayAnimation()
end
function UIPetSkinObtainController:OnHide()
    -- AudioHelperController.ReleaseUISoundById(CriAudioIDConst.DrawCard_suiji)
    -- for key, value in pairs(CriAudioIDConst.DrawStarCardArr) do
    --     AudioHelperController.ReleaseUISoundById(value)
    -- end
    --最后一张卡牌表现在OnHide中析构，避免黑屏
    if self._curAnim then
        self._curAnim:Dispose()
        self._curAnim = nil
    end
    --self._petAudioModule:StopAll()
end
function UIPetSkinObtainController:getAnim(pet)
    return PetSkinObtainAnim:New(pet, nil,self:GetGameObject())
end
function UIPetSkinObtainController:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.closeBtnArea = self:GetGameObject("CloseBtnArea")
    --generated end--
end
function UIPetSkinObtainController:CloseBtnOnClick(go)
    self:Close()
end
function UIPetSkinObtainController:Close()
    if self._callback then
        self._callback()
    end
end


function UIPetSkinObtainController:PlayAnimation()
    if self._curAnim then
        self._curAnim:Dispose()
        self._curAnim = nil
    end

    self.closeBtnArea:SetActive(false)
    self._curAnim = self._anim
    self._curAnim:Start()
    self._isPlaying = true
end
function UIPetSkinObtainController:OnUpdate(dtMS)
    if self._curAnim and self._isPlaying then
        self._curAnim:Update(dtMS)
        if self._curAnim:IsOver() then
            -- self._curAnim = nil
            self.closeBtnArea:SetActive(true)
            self._isPlaying = false
        end
    end
end
