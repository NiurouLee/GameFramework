--[[------------------------------------------------------------------------------------------
    ChessPetConfigData : 棋子光灵数据，基本上与MonsterConfigData一样
]] --------------------------------------------------------------------------------------------

_class("ChessPetConfigData", Object)
---@class ChessPetConfigData: Object
ChessPetConfigData = ChessPetConfigData

function ChessPetConfigData:Constructor(world)
    self._world = world
    ---@type AffixService
    self._affixSvc = self._world:GetService("Affix")
end

function ChessPetConfigData:GetChessPetObject(chessPetID)
    return Cfg.cfg_chesspet[chessPetID]
end

function ChessPetConfigData:GetChessPetClass(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return self:GetChessPetClassByChessPetConfig(chessPetConfig)
end

---获取ChessPetClass的列表
function ChessPetConfigData:GetChessPetClassList()
    local listConfig = Cfg.cfg_chesspet_class()
    local listReturn = {}
    for key, value in pairs(listConfig) do
        table.insert(listReturn, key)
    end
    return listReturn
end

function ChessPetConfigData:GetChessPetClassByChessPetConfig(chessPetConfig)
    if nil == chessPetConfig then
        return nil
    end
    local chessPetClassID = chessPetConfig.ClassID
    return Cfg.cfg_chesspet_class[chessPetClassID]
end

---需要等技能配置确定后再解析
function ChessPetConfigData:GetChessPetCacheSkillIds(chessPetID)
    local ret = {}

    return ret
end

---逻辑数据区
----------------------------------------------------------------
function ChessPetConfigData:_GetChessPetProp(configData)
    local nData = 0
    if configData.formula then
        if 1 == configData.formula then
            local x = self._world.BW_WorldInfo:GetPlayerLevel()
            nData = x * x * configData.a + x * configData.b + configData.c
        elseif 2 == configData.formula then
            ---@type MazeService
            local mz = self._world:GetService("Maze")
            local x = mz:GetAvgPetLevel()
            local y, z = mz:GetMazeLayerFactor()
            nData = (x * configData.a + y * configData.b + configData.c) * z
        elseif 3 == configData.formula then
            ---暂时的需求是跟3一样只是用不同的系数
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            local y, z = configService:GetAffixHardParam(configData.formula)
            nData = (configData.b * y + configData.c) * z
        elseif 4 == configData.formula then
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            local y, z = configService:GetAffixHardParam(configData.formula)
            nData = (configData.b * y + configData.c) * z
        end
    else
        nData = configData[1]
    end
    return math.ceil(nData)
end

---提取棋子光灵的攻击力
function ChessPetConfigData:GetChessPetAttack(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return self:_GetChessPetProp(chessPetConfig.Attack)
end

---提取棋子光灵的防御力
function ChessPetConfigData:GetChessPetDefense(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return self:_GetChessPetProp(chessPetConfig.Defense)
end

---提取棋子光灵的闪避概率
function ChessPetConfigData:GetChessPetEvade(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return chessPetConfig.Evade
end

---提取棋子光灵的血
function ChessPetConfigData:GetChessPetHealth(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return self:_GetChessPetProp(chessPetConfig.Health)
end

---提取棋子光灵的元素类
function ChessPetConfigData:GetChessPetElementType(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return chessPetConfig.ElementType
end

---提取吸收系数： 普攻
function ChessPetConfigData:GetAbsorbNormal(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return chessPetConfig.AbsorbNormal or 1
end

---提取吸收系数： 连锁
function ChessPetConfigData:GetAbsorbChain(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return chessPetConfig.AbsorbChain or 1
end

---提取吸收系数： 主动技
function ChessPetConfigData:GetAbsorbActive(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return chessPetConfig.AbsorbActive or 1
end

function ChessPetConfigData:GetChessPetEliteIDArray(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    local tmpEliteID = {}
    if chessPetConfig.EliteID then
        for i, buffID in ipairs(chessPetConfig.EliteID) do
            table.insert(tmpEliteID, buffID)
        end
    end
    ---这俩词条函数需要实现
    local retEliteID = self._affixSvc:ReplaceChessPetEliteBuff(chessPetID, tmpEliteID)
    retEliteID = self._affixSvc:AddChessPetEliteBuff(chessPetID, retEliteID)
    return retEliteID or {}
end

---逻辑数据区
----------------------------------------------------------------
---提取棋子光灵模板ID
function ChessPetConfigData:GetChessPetClassID(chessPetID)
    local chessPetConfig = self:GetChessPetObject(chessPetID)
    return chessPetConfig.ClassID
end

--提取棋子光灵的永久特效ID列表
function ChessPetConfigData:GetChessPetPermanentEffectID(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    local effectArray = chessPetConfig.PermanentEffect
    return effectArray
end

--提取棋子光灵的待机特效ID列表
function ChessPetConfigData:GetChessPetIdleEffectID(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    local effectArray = chessPetConfig.IdleEffect
    return effectArray
end

--技能列
function ChessPetConfigData:GetChessPetSkillIDs(chessPetID)
    local monsterObject = self:GetChessPetClass(chessPetID)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:ChangeMonsterSkillID(monsterID, monsterObject.SkillID)
end

---棋子光灵掉落ID列表
function ChessPetConfigData:GetChessPetDropIDs(chessPetID)
    local monsterObject = self:GetChessPetObject(chessPetID)
    return monsterObject.DropArray
end

---可否移动
function ChessPetConfigData:CanMove(chessPetID)
    -- Log.warn(self._className, "CanMove(number) cannot judge  Consider `buffLogicService:CheckCanBeHitBack(entity)` instead. ")
    local monsterObject = self:GetChessPetClass(chessPetID)
    return monsterObject.CanMove
end

---可否转向
function ChessPetConfigData:CanTurn(chessPetID)
    local monsterObject = self:GetChessPetClass(chessPetID)
    return monsterObject.CanTurn
end

function ChessPetConfigData:GetStoryTips(chessPetID)
    local monsterObject = self:GetChessPetClass(chessPetID)
    return monsterObject.StoryTips
end

function ChessPetConfigData:GetDeathShowType(chessPetID)
    local monsterObject = self:GetChessPetClass(chessPetID)
    return monsterObject.DeathShowType
end

function ChessPetConfigData:GetDeathShowEffectID(chessPetID)
    local deathShowParam = self:GetChessPetClass(chessPetID).DeathShowParam
    if deathShowParam ~= nil then
        return deathShowParam.deathEffectID
    end
end

function ChessPetConfigData:GetDeathAudioID(chessPetID)
    local deathShowParam = self:GetChessPetClass(chessPetID).DeathAudioParam
    if deathShowParam ~= nil then
        return deathShowParam.deathAudioID
    end
end

---音效是否随着动作一起播放
function ChessPetConfigData:DeathAudioSyncAnimation(chessPetID)
    local deathShowParam = self:GetChessPetClass(chessPetID).DeathAudioParam
    if deathShowParam ~= nil then
        return deathShowParam.syncAnimation
    end
end

function ChessPetConfigData:GetSkillIDs(chessPetID)
    local monsterObject = self:GetChessPetClass(chessPetID)
    return monsterObject.SkillIDs or {}
end

---提取棋子光灵AI目标
---@param chessPetID number
function ChessPetConfigData:GetChessPetAITargetType(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    return chessPetConfig.AITargetType
end

----------------------------------------------------------------
---提取一个棋子光灵的占格信息
---@param chessPetID number
---@return array
function ChessPetConfigData:ParseChessPetArea(areaStrArray)
    local areaPosArray = {}
    for index = 1, #areaStrArray do
        local posStr = areaStrArray[index]
        local numStr = string.split(posStr, ",")
        local vec2 = Vector2(tonumber(numStr[1]), tonumber(numStr[2]))
        areaPosArray[#areaPosArray + 1] = vec2
    end

    return areaPosArray
end

---提取一个棋子光灵的占格信
---@param chessPetID number
---@return array
function ChessPetConfigData:GetChessPetArea(chessPetID)
    local chessPetClass = self:GetChessPetClass(chessPetID)
    if not chessPetClass then
        Log.fatal("No Find Monster ID:", chessPetID)
        local areaPosArray = {}
        return areaPosArray
    end
    return self:ParseChessPetArea(chessPetClass.Area)
end

---提取棋子光灵的资源
function ChessPetConfigData:GetChessPetResPath(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    return chessPetConfig.ResPath
end

---提取棋子光灵的卡牌资
function ChessPetConfigData:GetChessPetCardResPath(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    return chessPetConfig.CardResPath
end

function ChessPetConfigData:GetChessPetWalkStep(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    return chessPetConfig.Step
end

function ChessPetConfigData:GetChessPetMoveSpeed(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    return chessPetConfig.MoveSpeed
end

---提取棋子光灵的中心点偏移
function ChessPetConfigData:GetChessPetOffset(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    local offsetStr = chessPetConfig.PositionOffset
    local strArray = string.split(offsetStr, ",")
    local offset = Vector2(tonumber(strArray[1]), tonumber(strArray[2]))

    return offset
end

function ChessPetConfigData:GetChessPetDamageOffset(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    local offsetStr = chessPetConfig.DamageOffset
    local strArray = string.split(offsetStr, ",")
    local offset = Vector2(tonumber(strArray[1]), tonumber(strArray[2]))

    return offset
end

---提取棋子光灵的头顶坐标偏
function ChessPetConfigData:GetChessPetHPHeightOffset(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    return chessPetConfig.HeightOffset
end

---提取棋子光灵名称
function ChessPetConfigData:GetChessPetName(chessPetID)
    local chessPetClass = self:GetChessPetClass(chessPetID)
    if not chessPetClass then
        Log.fatal("### [boss warning]", chessPetID, "not in cfg_monster.")
    end
    return chessPetClass.Name
end

---@class ChessPetRaceType
---@field Land number
---@field Fly number
local ChessPetRaceType = {
    Land = 1,
    Fly = 2
}
_enum("ChessPetRaceType", ChessPetRaceType)

---获得棋子光灵种族类型 是飞行还是陆行
function ChessPetConfigData:GetChessPetRaceType(chessPetID)
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    if chessPetConfig == nil then
        Log.error("monsterID error ", chessPetID)
    end

    if chessPetConfig.RaceType then
        return chessPetConfig.RaceType
    else
        return nil
    end
end

---获得棋子光灵死亡技能ID
---这个词条没实现，等有需求再做
function ChessPetConfigData:GetChessPetDeathSkillID(chessPetID)
    local skills = self:GetSkillIDs(chessPetID)
    return self._affixSvc:ReplaceMonsterSpSkill(chessPetID, skills.Die, ReplaceMonsterSpSkillType.Die)
end

--棋子光灵登场时默认的Buff
function ChessPetConfigData:GetBornBuffList(chessPetID)
    local buffList = {}
    local chessPetConfig = self:GetChessPetClass(chessPetID)
    if not chessPetConfig then
        Log.fatal("[ChessPetConfig] chess pet class not found: ", chessPetID)
    elseif chessPetConfig.BornBuffs then
        table.appendArray(buffList, chessPetConfig.BornBuffs)
    end

    local objectConfig = self:GetChessPetObject(chessPetID)
    local tmpBuffList = {}
    if objectConfig.BuffList then
        for i, buffID in ipairs(objectConfig.BuffList) do
            table.insert(buffList, buffID)
        end
    end

    return buffList
end

--获取特殊材质动画
function ChessPetConfigData:GetChessPetShaderEffect(chessPetID)
    local configData = self:GetChessPetClass(chessPetID)
    return configData.ShaderEffect
end

function ChessPetConfigData:Block(chessPetID)
    local configData = self:GetChessPetClass(chessPetID)
    return configData.Block or 1
end

function ChessPetConfigData:GetHybridSkillPreviewMode(chessPetID)
    local configData = self:GetChessPetClass(chessPetID)
    return (configData.HybridSkillPreviewMode or 0), configData.HybridSkillPreviewParam
end

function ChessPetConfigData:IsEliteMonster(chessPetID)
    return (#(self:GetChessPetEliteIDArray(chessPetID)) > 0)
end

function ChessPetConfigData:GetTipsOffset(chessPetID)
    local configData = self:GetChessPetClass(chessPetID)
    return configData.TipsOffset or 0
end
