--[[
    替换指定模版的属性，替换成星灵模型，替换攻击技能表现(映镜-幻象小怪)
    这个buff仅用于创建怪物替换属性！！
]]
_class("BuffLogicChangeAttributesAndModel", BuffLogicBase)
---@class BuffLogicChangeAttributesAndModel:BuffLogicBase
BuffLogicChangeAttributesAndModel = BuffLogicChangeAttributesAndModel

function BuffLogicChangeAttributesAndModel:Constructor(buffInstance, logicParam)
    self._monsterClassIDArray = logicParam.monsterClassIDArray
    self._attributePercent = logicParam.attributePercent or 1
    self._attributeAttack = logicParam.attributeAttack or 0
    self._attributeDefense = logicParam.attributeDefense or 0
    self._attributeEvade = logicParam.attributeEvade or 0
    self._attributeHP = logicParam.attributeHP or 0

    self._usePetModel = logicParam.usePetModel
    self._posIndex = logicParam.posIndex
end

function BuffLogicChangeAttributesAndModel:DoLogic(notify)
    local targetMonsterID
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        local monsterID = monsterEntity:MonsterID():GetMonsterID()

        local monsterClassID = 0
        local cfg = Cfg.cfg_monster[monsterID]
        if cfg and cfg.ClassID then
            monsterClassID = cfg.ClassID
        end

        if table.intable(self._monsterClassIDArray, monsterClassID) then
            targetMonsterID = monsterID
            break
        end
    end

    ---给自动随机召唤测试添加容错。 因为测试的时候可能BOSS不存在，目标不存在
    if not targetMonsterID then
        return
    end

    local configService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = configService:GetMonsterConfigData()

    ---怪物的攻防血数值
    local attack = monsterConfigData:GetMonsterAttack(targetMonsterID)
    local defense = monsterConfigData:GetMonsterDefense(targetMonsterID)
    local nEvade = monsterConfigData:GetMonsterEvade(targetMonsterID)
    local hp = monsterConfigData:GetMonsterHealth(targetMonsterID)
    local elementType = monsterConfigData:GetMonsterElementType(targetMonsterID)

    attack = math.floor(attack * (self._attributePercent + self._attributeAttack))
    defense = math.floor(defense * (self._attributePercent + self._attributeDefense))
    nEvade = math.floor(nEvade * (self._attributePercent + self._attributeEvade))
    hp = math.floor(hp * (self._attributePercent + self._attributeHP))

    --重置数值
    local attributeCmpt = self._entity:Attributes()
    attributeCmpt:Modify("Attack", attack)
    attributeCmpt:Modify("Defense", defense)
    attributeCmpt:Modify("Evade", nEvade)
    attributeCmpt:Modify("HP", hp)
    attributeCmpt:Modify("MaxHP", hp)
    Log.debug("BuffLogicChangeAttributesAndModel ModifyHP =", hp, " defender=", self._entity:GetID())
    --设置元素类型
    self._entity:ReplaceElement(elementType, nil)
    attributeCmpt:SetSimpleAttribute("Element", elementType)

    --如果读取星灵的形象
    if self._usePetModel and self._usePetModel == 1 then
        local entityPos = self._entity:GridLocation():GetGridPos()
        local posIndex = 0
        for i = 1, #self._posIndex do
            local posX = self._posIndex[i][1]
            local posY = self._posIndex[i][2]
            if entityPos.x == posX and entityPos.y == posY then
                posIndex = i
                break
            end
        end

        ---@type Entity
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        local teamOrder = teamEntity:Team():GetTeamOrder()
        if posIndex > #teamOrder then
            posIndex = #teamOrder
        end

        if posIndex == 0 then
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            posIndex = randomSvc:LogicRand(1, #teamOrder)
        end
        local petID = teamOrder[posIndex]

        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local petEntityId = utilDataSvc:GetEntityIDByPstID(petID)

        self._world:EventDispatcher():Dispatch(
            GameEventType.DataBuffValue,
            self._entity:GetID(),
            "ChangeModelWithPetIndex",
            petEntityId
        )
    --return petEntityId
    end
end
