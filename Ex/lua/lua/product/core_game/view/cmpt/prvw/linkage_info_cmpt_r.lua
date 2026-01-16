--[[------------------------------------------------------------------------------------------
    LinkageInfoComponent : 连线信息组件
]] --------------------------------------------------------------------------------------------

---@class LinkageInfoComponent: Object
_class("LinkageInfoComponent", Object)
LinkageInfoComponent = LinkageInfoComponent

function LinkageInfoComponent:Constructor(linkTextOffset, attackRateOffset, maxCount,world)
    ---@type MainWorld
    self._world= world
    self._linkTextOffset = Vector3(linkTextOffset[1], linkTextOffset[2], 0)
    self._attackRateOffset = Vector3(attackRateOffset[1], attackRateOffset[2], 0)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()
    self._maxCount = superChainCount

    --self._attackRateText = nil
    self._pathCountText = nil
    self._pathCountGroup = nil
    self._linkageRoot = nil
    self._superChain = nil
    self._chainPathIconContainer = nil
    self._superchainPathIconContainer = nil
    ---@type UnityEngine.GameObject
    self._onlyMaxPrefabGO = nil
    ---@type UnityEngine.GameObject
    self._superChainEffGO = nil

    ---@type RawImageLoader
    self._chainIconLoader = nil
    ---@type RawImageLoader
    self._superchainIconLoader = nil

    self._previewPetEntityID = 0
end

function LinkageInfoComponent:SetRenderObject(linkageGameObject)
    self._linkageRoot = linkageGameObject
    local linkageRootTrans = linkageGameObject.transform

    local tempObject = GameObjectHelper.FindChild(linkageRootTrans, "PathCountText")
    self._pathCountText = tempObject:GetComponent("UILocalizationText")

    self._pathCountGroup = GameObjectHelper.FindChild(linkageRootTrans, "PathCountGroup")
    self._superChain = GameObjectHelper.FindChild(linkageRootTrans, "SuperChain")

    local transformChainPathIcon = GameObjectHelper.FindChild(self._pathCountGroup, "PetIconContainer")
    self._chainPathIconContainer = transformChainPathIcon.gameObject
    local goIconLoader = GameObjectHelper.FindChild(transformChainPathIcon, "IconLoader").gameObject
    self._chainIconLoader = goIconLoader:GetComponent("RawImageLoader")

    local transformSuperchainIcon = GameObjectHelper.FindChild(self._superChain, "PetIconContainer")
    self._superchainPathIconContainer = transformSuperchainIcon.gameObject
    local goSuperIconLoader = GameObjectHelper.FindChild(transformSuperchainIcon, "IconLoader").gameObject
    self._superchainIconLoader = goSuperIconLoader:GetComponent("RawImageLoader")

    local transformEffSuperChain_BG = GameObjectHelper.FindChild(self._superChain, "EffSuperChain_BG")
    self._superChainEffGO =transformEffSuperChain_BG.gameObject
    local transformEffNoSuperChain_BG = GameObjectHelper.FindChild(self._superChain, "EffNoSuperChain_BG")
    self._onlyMaxPrefabGO = transformEffNoSuperChain_BG.gameObject
end

---@param ePet Entity
function LinkageInfoComponent:SetChainSkillPet(ePet)
    local strIconLoader = tostring(self._chainIconLoader)
    if strIconLoader == "nil" or strIconLoader == "" then
        return
    end

    if ePet:GetID() == self._previewPetEntityID then
        return
    end

    self._previewPetEntityID = ePet:GetID()

    local cPetPstID = ePet:PetPstID()
    if not cPetPstID then
        return
    end
    local pstID = cPetPstID:GetPstID()

    local world = ePet:GetOwnerWorld()
    ---@type MatchPet
    local matchPet = world.BW_WorldInfo:GetPetData(pstID)
    if not matchPet then
        return
    end

    local templateID = matchPet:GetTemplateID()
    local cfgPetTemplate = Cfg.cfg_pet[templateID]
    if not cfgPetTemplate then
        return
    end

    local strPetIcon = matchPet:GetPetHead(PetSkinEffectPath.HEAD_ICON_CHAIN_SKILL_PREVIEW)
    self._chainIconLoader:LoadImage(strPetIcon)
    self._chainPathIconContainer:SetActive(true)

    self._superchainIconLoader:LoadImage(strPetIcon)
    self._superchainPathIconContainer:SetActive(true)
end

function LinkageInfoComponent:HideChainSkillPet()
    local strIconLoader = tostring(self._chainIconLoader)
    if strIconLoader == "nil" or strIconLoader == "" then
        return
    end

    self._previewPetEntityID = 0
    self._chainPathIconContainer:SetActive(false)
    self._superchainPathIconContainer:SetActive(false)
end

function LinkageInfoComponent:SetLinkCount(linkCount)
    if self._linkageRoot == nil then
        return
    end

    local realLinkCount = linkCount - 1
    if realLinkCount < 1 then
        self._linkageRoot:SetActive(false)
    else
        --self._attackRateText.text = attackRateFormat
        self._linkageRoot:SetActive(true)
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local superChainCount = utilData:GetCurrentTeamSuperChainCount()
        self._maxCount = superChainCount
        if realLinkCount < self._maxCount then
            self._pathCountGroup.gameObject:SetActive(true)
            self._superChain.gameObject:SetActive(false)
            self._onlyMaxPrefabGO:SetActive(false)
            self._superChainEffGO:SetActive(false)

            local linkCountFormat = 0
            if realLinkCount < 10 then
                linkCountFormat = "0" .. realLinkCount
            else
                linkCountFormat = realLinkCount
            end
            self._pathCountText:SetText(linkCountFormat)
        else
            self._pathCountGroup.gameObject:SetActive(false)
            self._superChain.gameObject:SetActive(true)
            
            ---@type UtilDataServiceShare
            local utilDataSvc = self._world:GetService("UtilData")
            if utilDataSvc:IsCloseAuroraTime() then
                self._superChainEffGO:SetActive(false)
                self._onlyMaxPrefabGO:SetActive(true)
            else
                self._superChainEffGO:SetActive(true)
                self._onlyMaxPrefabGO:SetActive(false)
            end

        end

        local num = math.floor(realLinkCount / 10 + 1)
        local lastNum = realLinkCount
        if lastNum >= 10 then
            lastNum = realLinkCount % 10
        end
        local attackRateFormat = "*" .. num .. "." .. lastNum
    end
end

function LinkageInfoComponent:SetLinkagePos(pos)
    if self._linkageRoot == nil then
        return
    end
    self._pathCountGroup.transform.position = pos + self._linkTextOffset
    self._superChain.transform.position = pos + self._linkTextOffset
end

function LinkageInfoComponent:Destructor()
end

----------------------------------------------------------------------
function Entity:LinkageInfo()
    return self:GetComponent(self.WEComponentsEnum.LinkageInfo)
end

function Entity:HasLinkageInfo()
    return self:HasComponent(self.WEComponentsEnum.LinkageInfo)
end

function Entity:AddLinkageInfo(linkTextOffset, attackRateOffset, maxCount)
    local index = self.WEComponentsEnum.LinkageInfo
    local world = self:GetOwnerWorld()
    local component = LinkageInfoComponent:New(linkTextOffset, attackRateOffset, maxCount,world)
    self:AddComponent(index, component)
end

function Entity:ReplaceLinkageInfo(linkTextOffset, attackRateOffset, maxCount)
    local index = self.WEComponentsEnum.LinkageInfo
    local world = self:GetOwnerWorld()
    local component = LinkageInfoComponent:New(linkTextOffset, attackRateOffset, maxCount,world)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveLinkageInfo()
    if self:HasLinkageInfo() then
        self:RemoveComponent(self.WEComponentsEnum.LinkageInfo)
    end
end
