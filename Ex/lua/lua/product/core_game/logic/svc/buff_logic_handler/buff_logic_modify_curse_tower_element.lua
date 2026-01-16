--[[
    根据诅咒塔的位置，修改诅咒塔的元素类型
]]

_class("BuffLogicModifyCurseTowerElement", BuffLogicBase)
BuffLogicModifyCurseTowerElement = BuffLogicModifyCurseTowerElement

function BuffLogicModifyCurseTowerElement:Constructor(buffInstance, logicParam)
end

function BuffLogicModifyCurseTowerElement:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type GridLocationComponent
    local gridLocCmpt = e:GridLocation()
    local curGridPos = gridLocCmpt:GetGridPos()

    ---@type CurseTowerComponent
    local curseTowerCmpt = e:CurseTower()
    if not curseTowerCmpt then 
        return 
    end

    local towerIndex = self:CalcTowerIndex(curGridPos)
    curseTowerCmpt:SetTowerIndex(towerIndex)

    local targetElement = self:CalcCurseTowerElement(towerIndex)
    e:ReplaceElement(targetElement)

    return true
end

function BuffLogicModifyCurseTowerElement:CalcTowerIndex(towerPos)
    local xEqualOne = (towerPos.x - 1 < 0.99)
    local xEqualEight = (towerPos.x - 8 < 0.99)

    local yEqualOne = (towerPos.y - 1 < 0.99)
    local yEqualEight = (towerPos.y - 8 < 0.99)

    if xEqualOne and yEqualOne then 
        return 4
    end

    if xEqualEight and yEqualOne then 
        return 3
    end

    if xEqualEight and yEqualEight then 
        return 2
    end

    return 1
end

function BuffLogicModifyCurseTowerElement:CalcCurseTowerElement(towerIndex)
    ---@type Entity
    local teamEntity =  self._world:Player():GetLocalTeamEntity()
    local teamOrder = teamEntity:Team():GetTeamOrder()
    local teamCount = #teamOrder
    local petPstID = -1
    if teamCount >= towerIndex then 
        petPstID = teamOrder[towerIndex]
    else
        petPstID = teamOrder[teamCount]
    end

    
    ---@type Entity
    local petEntity = teamEntity:Team():GetPetEntityByPetPstID(petPstID)
    if petEntity == nil then 
        return ElementType.ElementType_None
    end

    ---@type ElementComponent
    local elementCmpt = petEntity:Element()
    return elementCmpt:GetPrimaryType()
end
