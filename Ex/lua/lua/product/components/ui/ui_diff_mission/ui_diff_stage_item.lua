---@class UIDiffStageItem:UICustomWidget
_class("UIDiffStageItem", UICustomWidget)
UIDiffStageItem = UIDiffStageItem
--困难关关卡
function UIDiffStageItem:OnShow(uiParam)
    self:GetComponents()
end
function UIDiffStageItem:GetComponents()
    self._nameTex = self:GetUIComponent("UILocalizationText","name")
    self._typeImg = self:GetUIComponent("Image","type")
    self._finishGo = self:GetGameObject("finish")
    self._teamGo = self:GetGameObject("team")
    self._teamPool = self:GetUIComponent("UISelectObjectPath","team")
    self._rect = self:GetUIComponent("RectTransform","rect")

    self._atlas = self:GetAsset("UIDiffMission.spriteatlas", LoadType.SpriteAtlas)
end
function UIDiffStageItem:OnValue()
    self._nameTex:SetText(StringTable.Get(self._stage:Name()))
    local team = self._stage:Team()
    local pets = team:GetPets()
    local finish = false
    if pets and next(pets) then
        for _, pstid in pairs(pets) do
            if pstid >0 then
                finish = true
                break
            end
        end
    end
    self._finishGo:SetActive(finish)

    local teamCount = 5
    self._teamPool:SpawnObjects("UIDiffStageTeamItem",teamCount)
    ---@type UIDiffStageTeamItem[]
    local pools = self._teamPool:GetAllSpawnList()
    for i = 1, #pools do
        local item = pools[i]
        item:SetData(pets[i])
    end

    local sprite
    if self._stage:Type() == DiffMissionType.Boss then
        sprite = self._atlas:GetSprite("map_black_icon15")
    else
        sprite = self._atlas:GetSprite("map_black_icon12")
    end
    self._typeImg.sprite = sprite

    self._rect.anchoredPosition = self._pos
end
function UIDiffStageItem:FlushTeam()
    local team = self._stage:Team()
    local pets = team:GetPets()
    local finish = false
    if pets and next(pets) then
        for _, pstid in pairs(pets) do
            if pstid >0 then
                finish = true
                break
            end
        end
    end
    self._finishGo:SetActive(finish)
    local teamCount = 5
    self._teamPool:SpawnObjects("UIDiffStageTeamItem",teamCount)
    ---@type UIDiffStageTeamItem[]
    local pools = self._teamPool:GetAllSpawnList()
    for i = 1, #pools do
        local item = pools[i]
        item:SetData(pets[i])
    end
end
function UIDiffStageItem:SetData(stage,pos,cb)
    ---@type DiffMissionStage
    self._stage = stage
    self._cb = cb
    self._pos = pos
    self:OnValue()
end
function UIDiffStageItem:OnHide()
    -- body
end
function UIDiffStageItem:BgOnClick(go)
    if self._cb then
        self._cb(self._stage)
    end
end