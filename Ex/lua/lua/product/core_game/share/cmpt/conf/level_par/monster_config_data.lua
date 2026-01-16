--[[------------------------------------------------------------------------------------------
    MonsterConfigData : 怪物数据
]] --------------------------------------------------------------------------------------------
---@class MonsterADHFormulaType
local MonsterADHFormulaType = {
    ByLeaderLevel = 1,
    Maze = 2, ---秘境使用
    N4AttackAndDefense = 3, ---N4活动设置攻击和防御
    N4HP = 4, ---N4活动设置血量
    N25MiniMaze = 5, ---N25新增
}
_enum("MonsterADHFormulaType", MonsterADHFormulaType)
_class("MonsterConfigData", Object)
---@class MonsterConfigData: Object
MonsterConfigData = MonsterConfigData

function MonsterConfigData:Constructor(world)
    self._world = world
    ---@type AffixService
    self._affixSvc = self._world:GetService("Affix")
end

function MonsterConfigData:GetMonsterObject(monsterID)
    if not Cfg.cfg_monster[monsterID] then
        Log.fatal("MonsterConfigData:GetMonsterObject monsterID:", monsterID)
    end
    return Cfg.cfg_monster[monsterID]
end

function MonsterConfigData:GetMonsterClass(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return self:GetMonsterClassByMonsterConfig(monsterConfig)
end

---获取MonsterClass的列表
function MonsterConfigData:GetMonsterClassList()
    local listConfig = Cfg.cfg_monster_class()
    local listReturn = {}
    for key, value in pairs(listConfig) do
        table.insert(listReturn, key)
    end
    return listReturn
end

---获取所有相同ClassID的所有MonsterID列表
function MonsterConfigData:GetMonsterListByClassID(nClassID)
    local listConfig = Cfg.cfg_monster()
    local listReturn = {}
    for key, value in pairs(listConfig) do
        if nClassID == value.ClassID then
            table.insert(listReturn, value)
        end
    end
    return listReturn
end

---获取所有相同ClassID的所有MonsterID列表
function MonsterConfigData:GetMonsterListByGroupID(nGroupID)
    local listConfig = Cfg.cfg_monster()
    local listReturn = {}
    for key, value in pairs(listConfig) do
        if nGroupID == value.GroupID then
            table.insert(listReturn, value)
        end
    end
    return listReturn
end

function MonsterConfigData:GetMonsterClassByMonsterConfig(monsterConfig)
    if nil == monsterConfig then
        return nil
    end
    local monsterClassID = monsterConfig.ClassID
    if not Cfg.cfg_monster_class[monsterClassID]  then
        Log.exception("MonsterConfigData:GetMonsterClassByMonsterConfig is nil monsterClassID:",monsterConfig.ClassID," MonsterID:",monsterConfig.ID)
    end
    return Cfg.cfg_monster_class[monsterClassID]
end

function MonsterConfigData:GetCacheSkillIds(monsterID)
    local ret = {}
    --出场技
    local nAppearSkillID = self:GetAppearSkillID(monsterID)
    if nAppearSkillID and nAppearSkillID > 0 then
        table.insert(ret, nAppearSkillID)
    end
    --技能
    local idss = self:GetMonsterSkillIDs(monsterID)
    for _, t in ipairs(idss) do
        table.appendArray(ret, t)
    end

    --死亡技能
    local nDieSkillID = self:GetMonsterDeathSkillID(monsterID)
    if monsterID and monsterID > 0 then
        table.insert(ret, nDieSkillID)
    end
    return ret
end

--region 逻辑数据区
----------------------------------------------------------------
function MonsterConfigData:_GetMonsterProp(configData)
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
        else
            ---公式3、4、5均是取词条难度系数 只是系数为配置中的不同列
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

---提取怪物的攻击力
function MonsterConfigData:GetMonsterAttack(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return self:_GetMonsterProp(monsterConfig.Attack)
end

---提取怪物的防御力
function MonsterConfigData:GetMonsterDefense(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return self:_GetMonsterProp(monsterConfig.Defense)
end

---提取怪物的闪避概率
function MonsterConfigData:GetMonsterEvade(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return monsterConfig.Evade
end

---提取怪物的血
function MonsterConfigData:GetMonsterHealth(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return self:_GetMonsterProp(monsterConfig.Health)
end

---提取怪物的元素类
function MonsterConfigData:GetMonsterElementType(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return monsterConfig.ElementType
end

---提取吸收系数： 普攻
function MonsterConfigData:GetAbsorbNormal(nMonsterID)
    local monsterConfig = self:GetMonsterObject(nMonsterID)
    return monsterConfig.AbsorbNormal or 1
end

---提取吸收系数： 连锁
function MonsterConfigData:GetAbsorbChain(nMonsterID)
    local monsterConfig = self:GetMonsterObject(nMonsterID)
    return monsterConfig.AbsorbChain or 1
end

---提取吸收系数： 主动技
function MonsterConfigData:GetAbsorbActive(nMonsterID)
    local monsterConfig = self:GetMonsterObject(nMonsterID)
    return monsterConfig.AbsorbActive or 1
end

function MonsterConfigData:GetEliteIDArray(nMonsterID)
    --QA：MSG52326 精英词缀随机功能，调整接口，此处只返回配置的ID列表
    local monsterConfig = self:GetMonsterObject(nMonsterID)
    local tmpEliteID = {}
    if monsterConfig.EliteID then
        for i, buffID in ipairs(monsterConfig.EliteID) do
            table.insert(tmpEliteID, buffID)
        end
    end
    --local retEliteID = self._affixSvc:ReplaceMonsterEliteBuff(nMonsterID, tmpEliteID)
    --retEliteID = self._affixSvc:AddMonsterEliteBuff(nMonsterID, retEliteID)
    return tmpEliteID
end

function MonsterConfigData:GetEliteIDRandomParam(nMonsterID)
    local monsterConfig = self:GetMonsterObject(nMonsterID)
    local randomParam = table.cloneconf(monsterConfig.EliteIDRandom)
    return randomParam
end

--endregion 逻辑数据区
----------------------------------------------------------------

---提取怪物模板ID
function MonsterConfigData:GetMonsterClassID(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return monsterConfig.ClassID
end

---提取怪物移动速度
---@param monsterID number
---@return number
function MonsterConfigData:GetMonsterSpeed(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.MoveSpeed
end

---提取怪物行动力3u82
---@param monsterID number
---@return number
function MonsterConfigData:GetMonsterStep(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.Step
    -- return monsterConfig.Step or 1;
end

---怪物AI ID
---@param monsterID number
---@return number
function MonsterConfigData:GetMonsterAIID(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.AIID
end

---怪物前置行动AI ID
---@param monsterID number
---@return number
function MonsterConfigData:GetMonsterPreMoveAIID(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.PreMoveAIID
end

---怪物反制AI ID
---@param monsterID number
---@return number
function MonsterConfigData:GetMonsterAntiAttackAIID(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.AntiAttackAIID
end

---怪物反制AI的参数
---@param monsterID number
function MonsterConfigData:GetMonsterAntiAttackParam(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.AntiAttackParam
end

---预览AI的技能：只能从对应的分支内选取特定Order的分
---@param monsterID number
---@return number
function MonsterConfigData:GetMonsterPreviewAIOrder(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.PreviewAIOrder
end

--提取怪物的永久特效ID列表
function MonsterConfigData:GetMonsterPermanentEffectID(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    local effectArray = monsterConfig.PermanentEffect
    return effectArray
end

--提取怪物的待机特效ID列表
function MonsterConfigData:GetMonsterIdleEffectID(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    local effectArray = monsterConfig.IdleEffect
    return effectArray
end

--技能列
function MonsterConfigData:GetMonsterSkillIDs(monsterID)
    local monsterObject = self:GetMonsterClass(monsterID)
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    return affixService:ChangeMonsterSkillID(monsterID, monsterObject.SkillID)
end

---怪物掉落ID列表
function MonsterConfigData:GetMonsterDropIDs(monsterID)
    local monsterObject = self:GetMonsterObject(monsterID)
    return monsterObject.DropArray
end

---可否移动
function MonsterConfigData:CanMove(monsterID)
    -- Log.warn(self._className, "CanMove(number) cannot judge  Consider `buffLogicService:CheckCanBeHitBack(entity)` instead. ")
    local monsterObject = self:GetMonsterClass(monsterID)
    return monsterObject.CanMove
end

---可否转向
function MonsterConfigData:CanTurn(monsterID)
    local monsterObject = self:GetMonsterClass(monsterID)
    return monsterObject.CanTurn
end

function MonsterConfigData:GetStoryTips(monsterID)
    local monsterObject = self:GetMonsterClass(monsterID)
    return monsterObject.StoryTips
end

function MonsterConfigData:GetDeathShowType(monsterID)
    local monsterObject = self:GetMonsterClass(monsterID)
    return monsterObject.DeathShowType
end

function MonsterConfigData:GetDeathShowEffectID(monsterID)
    local deathShowParam = self:GetMonsterClass(monsterID).DeathShowParam
    if deathShowParam ~= nil then
        return deathShowParam.deathEffectID
    end
end

function MonsterConfigData:GetDeathAudioID(monsterID)
    local deathShowParam = self:GetMonsterClass(monsterID).DeathAudioParam
    if deathShowParam ~= nil then
        return deathShowParam.deathAudioID
    end
end

---音效是否随着动作一起播放
function MonsterConfigData:DeathAudioSyncAnimation(monsterID)
    local deathShowParam = self:GetMonsterClass(monsterID).DeathAudioParam
    if deathShowParam ~= nil then
        return deathShowParam.syncAnimation
    end
end

function MonsterConfigData:GetSkillIDs(monsterID)
    local monsterObject = self:GetMonsterClass(monsterID)
    return monsterObject.SkillIDs or {}
end

---2020-05-07 韩玉信，修改出场表现为技能播放的形式
function MonsterConfigData:GetAppearSkillID(monsterID)
    local skillIds = self:GetSkillIDs(monsterID)
    return self._affixSvc:ReplaceMonsterSpSkill(monsterID, skillIds.Appear, ReplaceMonsterSpSkillType.Appear)
    --if skillIds then
    --    return skillIds.Appear
    --end
end

---怪物掉落技
function MonsterConfigData:GetDropSkillID(monsterID)
    local skillIds = self:GetSkillIDs(monsterID)
    return self._affixSvc:ReplaceMonsterSpSkill(monsterID, skillIds.Drop, ReplaceMonsterSpSkillType.Drop)
    --if skillIds then
    --    return skillIds.Drop
    --end
end

---怪物返场技：目前无词条更换返场技需求，暂时不处理词条
function MonsterConfigData:GetBackSkillID(monsterID)
    local skillIds = self:GetSkillIDs(monsterID)
    if skillIds then
        return skillIds.Back
    end
end

---提取怪物AI目标
---@param monsterID number
function MonsterConfigData:GetMonsterAITargetType(monsterID)
    --MSG57269 cfg_monster.xlsx里如果配置了该列，则优先使用
    local monsterConfig = self:GetMonsterObject(monsterID)
    if monsterConfig.AITargetType then
        return monsterConfig.AITargetType
    else
        local monsterClassConfig = self:GetMonsterClass(monsterID)
        return monsterClassConfig.AITargetType
    end
end

----------------------------------------------------------------
---提取一个怪物的占格信息
---@param monsterID number
---@return array
function MonsterConfigData:ExplainMonsterArea(areaStrArray)
    local areaPosArray = {}
    for index = 1, #areaStrArray do
        local posStr = areaStrArray[index]
        local numStr = string.split(posStr, ",")
        local vec2 = Vector2(tonumber(numStr[1]), tonumber(numStr[2]))
        areaPosArray[#areaPosArray + 1] = vec2
    end

    return areaPosArray
end

---提取一个怪物的占格信
---@param monsterID number
---@return array
function MonsterConfigData:GetMonsterArea(monsterID)
    local monsterClass = self:GetMonsterClass(monsterID)
    if not monsterClass then
        Log.fatal("No Find Monster ID:", monsterID)
        local areaPosArray = {}
        return areaPosArray
    end
    return self:ExplainMonsterArea(monsterClass.Area)
end

---提取怪物类型
function MonsterConfigData:GetMonsterType(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.MonsterType
end

---提取怪物分组编号
function MonsterConfigData:GetMonsterGroupID(monsterID)
    local monsterConfig = self:GetMonsterObject(monsterID)
    return monsterConfig.GroupID
end

---提取怪物的资源路
function MonsterConfigData:GetMonsterResPath(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    if not monsterConfig then
        Log.fatal("No Find Monster ID:", monsterID)
    end
    return monsterConfig.ResPath
end

---提取怪物的卡牌资
function MonsterConfigData:GetMonsterCardResPath(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.CardResPath
end

---提取怪物的中心点偏移
function MonsterConfigData:GetMonsterOffset(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    local offsetStr = monsterConfig.PositionOffset
    local strArray = string.split(offsetStr, ",")
    local offset = Vector2(tonumber(strArray[1]), tonumber(strArray[2]))

    return offset
end

function MonsterConfigData:GetMonsterDamageOffset(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    local offsetStr = monsterConfig.DamageOffset
    local strArray = string.split(offsetStr, ",")
    local offset = Vector2(strArray[1], strArray[2])

    return offset
end

---提取怪物的头顶坐标偏
function MonsterConfigData:GetMonsterHPHeightOffset(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.HeightOffset
end

---判断怪物类型是否是boss
function MonsterConfigData:IsBoss(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    local monsterType = monsterConfig.MonsterType
    if monsterType == MonsterType.Boss or monsterType == MonsterType.WorldBoss then
        return true
    end

    return false
end

function MonsterConfigData:IsWorldBoss(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    local monsterType = monsterConfig.MonsterType
    if monsterType == MonsterType.WorldBoss then
        return true
    end

    return false
end

---提取怪物名称
function MonsterConfigData:GetMonsterName(monsterID)
    local monsterClass = self:GetMonsterClass(monsterID)
    if not monsterClass then
        Log.fatal("### [boss warning]", monsterID, "not in cfg_monster.")
    end
    return monsterClass.Name
end

function MonsterConfigData:GetStoryTipsOffset(monsterID)
    local monsterClass = self:GetMonsterClass(monsterID)
    return monsterClass.TipsOffset
end

---return table<table<number,number>,string>
function MonsterConfigData:GetMonsterOffSetWithBindPos(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    if nil == configData then
        return
    end
    return configData.AreaWithHitBindPos
end

function MonsterConfigData:GetMonsterBindPos(monsterID, monsterGridPos, gridPos, bodyArea)
    local OffsetWithBindPos = self:GetMonsterOffSetWithBindPos(monsterID)
    if OffsetWithBindPos then
        --local bodyArea = self:GetMonsterArea(monsterID)

        local deltaPos = nil
        for _, v in pairs(bodyArea) do
            local bodyGridPos = Vector2(v.x + monsterGridPos.x, v.y + monsterGridPos.y)
            if bodyGridPos == gridPos then
                deltaPos = v
                break
            end
        end
        if deltaPos then
            for k, v in pairs(OffsetWithBindPos) do
                if k[1] == deltaPos.x and k[2] == deltaPos.y then
                    return v
                end
            end
        end
        Log.fatal(
            "Get OffsetWithBindPos Failed MonsterID:",
            monsterID,
            "GridPos:",
            gridPos,
            "MonsterGridPos:",
            monsterGridPos
        )
        return nil
    else
        Log.fatal("Get OffsetWithBindPos Failed MonsterID:", monsterID)
        return nil
    end
end

function MonsterConfigData:GetMonsterBornType(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    return configData.BornType
end

function MonsterConfigData:GetMonsterHPSep(monsterID)
    local config = self:GetMonsterClass(monsterID)
    if config then
        return config.HealthSep
    end
    return nil
end

---@class MonsterRaceType
---@field Land number
---@field Fly number
local MonsterRaceType = {
    Land = 1,
    Fly = 2
}
_enum("MonsterRaceType", MonsterRaceType)

---获得怪物种族类型 是飞行还是陆行
function MonsterConfigData:GetMonsterRaceType(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    if monsterConfig == nil then
        Log.error("monsterID error ", monsterID)
    end
    if monsterConfig.RaceType then
        return monsterConfig.RaceType
    else
        return nil
    end
end

---获得怪物死亡技能ID
function MonsterConfigData:GetMonsterDeathSkillID(monsterID)
    local skills = self:GetSkillIDs(monsterID)
    return self._affixSvc:ReplaceMonsterSpSkill(monsterID, skills.Die, ReplaceMonsterSpSkillType.Die)
    --if skills then
    --    return skills.Die
    --end
end

--是否为常规体型
---@return boolean
function MonsterConfigData:IsRegularShape(monsterID)
    local monsterConfig = self:GetMonsterClass(monsterID)
    if monsterConfig then
        return not monsterConfig.IsIrregular
    else
        Log.fatal("[MonsterConfig] monster not found: ", monsterID)
    end
end

--怪物登场时默认的Buff
function MonsterConfigData:GetBornBuffList(monsterID)
    local buffList = {}
    local monsterConfig = self:GetMonsterClass(monsterID)
    if not monsterConfig then
        Log.fatal("[MonsterConfig] monster class not found: ", monsterID)
    elseif monsterConfig.BornBuffs then
        table.appendArray(buffList, monsterConfig.BornBuffs)
    end

    local objectConfig = self:GetMonsterObject(monsterID)
    local tmpBuffList = {}
    if objectConfig.BuffList then
        for i, buffID in ipairs(objectConfig.BuffList) do
            table.insert(tmpBuffList, buffID)
        end
    end
    local objectBuffList = self._affixSvc:ReplaceMonsterBuff(monsterID, tmpBuffList)

    objectBuffList = self._affixSvc:AddMonsterBuff(monsterID, objectBuffList)
    if not objectConfig then
        Log.fatal("[MonsterConfig] monster object not found: ", monsterID)
    elseif objectBuffList then
        table.appendArray(buffList, objectBuffList)
    end

    return buffList
end

--获取特殊材质动画
function MonsterConfigData:GetMonsterShaderEffect(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    return configData.ShaderEffect
end

function MonsterConfigData:Block(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    return configData.Block or 1
end

function MonsterConfigData:GetHybridSkillPreviewMode(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    return (configData.HybridSkillPreviewMode or 0), configData.HybridSkillPreviewParam
end

function MonsterConfigData:GetWorldBossConfig(monsterID)
    local cfg = Cfg.cfg_world_boss_hp[monsterID]
    if not cfg then
        Log.fatal("cfg_world_boss_hp no ID:", monsterID)
    end
    return cfg.Stage, cfg.HPImage
end

function MonsterConfigData:IsEliteMonster(monsterID)
    return (#(self:GetEliteIDArray(monsterID)) > 0)
end

function MonsterConfigData:IsDisableEliteEffect(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    if configData.ExtraParams then
        return configData.ExtraParams.DisableEliteEffect
    end
    return false
end

---@return boolean
function MonsterConfigData:IsHasPassiveSkillInfo(monsterID)
    local infos = self:GetMonsterPassiveInfo(monsterID)
    if not infos or #infos == 0 then
        return false
    end
    return true
end

function MonsterConfigData:GetMonsterPassiveInfo(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    if configData then
        return configData.PassiveSkillInfos
    else
        return nil
    end
end

function MonsterConfigData:GetMonsterHUDHPWidthScale(monsterID)
    local objConfigData = self:GetMonsterObject(monsterID)
    -- 个体scale优先class的scale
    if objConfigData.HPSliderWidthScale then
        return objConfigData.HPSliderWidthScale
    end

    local classConfigData = self:GetMonsterClass(monsterID)
    -- class的scale系数优先于默认值
    if classConfigData.HPSliderWidthScale then
        return classConfigData.HPSliderWidthScale
    end

    -- 默认值
    return 1
end

---@class MonsterPassiveInfoType
---@field Base number
---@field AntiSkill number
local MonsterPassiveInfoType = {
    Base = 1, ---基础被动
    AntiSkill = 2 ---反制技能
}
_enum("MonsterPassiveInfoType", MonsterPassiveInfoType)

function MonsterConfigData:GetMonsterSnakeBodyEffectID(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    if configData then
        return configData.SnakeBodyEffect
    else
        return nil
    end
end

function MonsterConfigData:GetMonsterDamageSyncMonsterID(monsterID)
    local configData = self:GetMonsterClass(monsterID)
    if configData then
        return configData.DamageSyncMonsterID
    else
        return nil
    end
end


function MonsterConfigData:GetMonsterHUDHPBarType(monsterID)
    local objectConfig = self:GetMonsterObject(monsterID)
    -- 个体配置优先
    if objectConfig.HPSliderColor then
        return objectConfig.HPSliderColor
    end

    -- 模板配置
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.HPSliderColor or MonsterHUDHPBarType.Red -- Red是默认值
end


---@class MonsterCampType
---@field AnGui number
---@field BaiYeCheng number
---@field QiGuang number
local MonsterCampType = {
    AnGui = 1,     ---暗鬼
    BaiYeCheng = 2,---白夜城
    QiGuang = 3,   ---启光
}
_enum("MonsterCampType", MonsterCampType)
---@return MonsterCampType
function MonsterConfigData:GetMonsterCampType(monsterID)
    -- 模板配置
    local monsterConfig = self:GetMonsterClass(monsterID)
    return monsterConfig.CampType or MonsterCampType.AnGui
end