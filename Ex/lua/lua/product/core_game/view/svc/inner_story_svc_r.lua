--[[------------------------------------------------------------------------------------------
    InnerStoryService 局内剧情服务
]] --------------------------------------------------------------------------------------------

_class("InnerStoryService", BaseService)
---@class InnerStoryService:BaseService
InnerStoryService = InnerStoryService

function InnerStoryService:Constructor(world)
end

function InnerStoryService:CheckInnerStory(type, param, showType)
    ---进这里的只有回合相关的用判断 其余的都配了就是有了

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local waveIndex = utilStatSvc:GetStatCurWaveIndex()
    local waveRoundNum = utilStatSvc:GetStatCurWaveRoundNum()
    local totalWaveRoundNum = utilStatSvc:GetStatCurWaveTotalRoundCount()

    if
        type == StoryShowType.WaveAndRoundBeginPlayerRound or type == StoryShowType.WaveAndRoundAfterPlayerRound or
            type == StoryShowType.WaveAndRoundBeginMonsterRound or
            type == StoryShowType.WaveAndRoundAfterMonsterRound
     then
        local tmpList = string.split(param, ",")

        if
            waveIndex == tonumber(tmpList[1]) and totalWaveRoundNum == tonumber(tmpList[2]) and
                not self:IsInnerStoryShowedInCurWaveAndCurRound(showType, type, waveIndex, waveRoundNum)
         then
            return true
        else
            return false
        end
    else
        return true
    end
end

function InnerStoryService:CheckMonsterShowAndDeadStoryBanner(type, monsterID)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type LevelConfigData
    local levelConfigData = cfgService:GetLevelConfigData()
    ---@type table<number,LevelStoryBannerParam>
    local bannerParam = levelConfigData:GetLevelStoryBannerParam()
    for k, v in pairs(bannerParam) do
        if v:GetType() == type then
            if type == StoryShowType.AfterMonsterDead then
                local tmpList = string.split(v:GetParam(), ",")
                if
                    tonumber(tmpList[1]) == monsterID and
                        tonumber(tmpList[2]) == self:_GetBattleStatComponent():GetCurWaveIndex()
                 then
                    local bShow = true
                    if not self:_GetBattleStatComponent():IsMonsterShowBannerCurWave(monsterID) then
                        self:_GetBattleStatComponent():AddDeadMonsterShowBanner(monsterID)
                    else
                        bShow = false
                    end
                    if bShow then
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowStoryBanner, v:GetID(), v:GetShowType())
                        Log.debug("Show Banner ID ", v:GetID(), "Type:", type)
                        return true
                    else
                        return false
                    end
                end
            else
                if tonumber(v:GetParam()) == monsterID then
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowStoryBanner, v:GetID(), v:GetShowType())
                    Log.debug("Show Banner ID ", v:GetID(), "Type:", type)
                end
            end
        end
    end
    return false
end

function InnerStoryService:CheckMonsterShowAndDeadStoryTips(type, monsterID, monsterEntityID)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    local storyTips = monsterConfigData:GetStoryTips(monsterID)
    if not storyTips then
        return
    end
    for _, v in pairs(storyTips) do
        if v.Type == type then
            local tmpList = string.split(v.Param, ",")
            local rand = Mathf.Random(1, 100)
            if rand <= tonumber(tmpList[1]) then
                local index = Mathf.Random(2, #tmpList)
                self:DoMonsterStoryTips(monsterID, monsterEntityID, tonumber(tmpList[index]))
            end
        end
    end
end

function InnerStoryService:CheckStoryTips(type)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type LevelConfigData
    local levelConfigData = cfgService:GetLevelConfigData()
    ---@type table<number,LevelStoryTipsParam>
    local tipsParam = levelConfigData:GetLevelStoryTipsParam()

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local waveIndex = utilStatSvc:GetStatCurWaveIndex()
    local waveRoundNum = utilStatSvc:GetStatCurWaveRoundNum()

    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()

    for k, v in pairs(tipsParam) do
        if v:GetType() == type then
            if self:CheckInnerStory(type, v:GetParam(), "tips") then
                battleRenderCmpt:AddInnerStoryShowed("tips", type, waveIndex, waveRoundNum)
                if v:GetSpeakerType() == StoryTipsSpeakerType.Pet then
                    local entity = self._world:Player():GetLocalTeamEntity()
                    local petPstID = entity:PetPstID():GetPstID()
                    self:DoPetStoryTips(petPstID, entity, v:GetID())
                elseif v:GetSpeakerType() == StoryTipsSpeakerType.Monster then
                    local monsterTemplateID = v:GetSpeakerMonsterID()
                    local monsterEntity = nil
                    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
                    for _, e in ipairs(monsterGroup:GetEntities()) do
                        if e:MonsterID():GetMonsterID() == monsterTemplateID then
                            monsterEntity = e
                            break
                        end
                    end
                    self:DoMonsterStoryTips(v:GetSpeakerMonsterID(), monsterEntity:GetID(), v:GetID())
                end
            end
        end
    end
end

function InnerStoryService:CheckStoryBanner(type)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type LevelConfigData
    local levelConfigData = cfgService:GetLevelConfigData()
    ---@type table<number,LevelStoryBannerParam>
    local bannerParam = levelConfigData:GetLevelStoryBannerParam()

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local waveIndex = utilStatSvc:GetStatCurWaveIndex()
    local waveRoundNum = utilStatSvc:GetStatCurWaveRoundNum()

    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()

    for k, v in pairs(bannerParam) do
        if v:GetType() == type then
            if self:CheckInnerStory(type, v:GetParam(), "Banner") then
                battleRenderCmpt:AddInnerStoryShowed("Banner", type, waveIndex, waveRoundNum)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowStoryBanner, v:GetID(), v:GetShowType())
                Log.debug("Show Banner ID ", v:GetID(), "Type:", type)
                return true
            end
        end
    end
    return false
end

function InnerStoryService:DoMonsterStoryTips(monsterTemplateID, monsterEntityID, tipsID)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    local offset = monsterConfigData:GetStoryTipsOffset(monsterTemplateID)
    self:DoStoryTips(monsterEntityID, offset, tipsID)
end

function InnerStoryService:DoTrapStoryTips(trapTemplateID, tarpEntity, tipsID)
    if not tarpEntity then
        local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        for _, e in ipairs(trapGroup:GetEntities()) do
            if e:TrapRender():GetTrapID() == trapTemplateID then
                tarpEntity = e
                break
            end
        end
    end
    if not tarpEntity then
        Log.fatal("MonsterEntity is Nil ", Log.traceback())
        return
    end
    ---@type ConfigService
    local cfgService = self._configService
    ---@type TrapConfigData
    local trapConfigData = cfgService:GetTrapConfigData()
    local offset = trapConfigData:GetStoryTipsOffset(trapTemplateID)
    self:DoStoryTips(tarpEntity:GetID(), offset, tipsID)
end

function InnerStoryService:DoPetStoryTips(petPstID, petEntity, tipsID)
    local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
    local offset = petData:GetStoryTipsOffset()
    self:DoStoryTips(petEntity:GetID(), offset, tipsID)
end

function InnerStoryService:DoChessStoryTips(chessClassID, chessEntityID, tipsID)
    ---@type ConfigService
    local cfgService = self._configService
    ---@type ChessPetConfigData
    local chessPetConfigData = cfgService:GetChessPetConfigData()
    local offset = chessPetConfigData:GetTipsOffset(chessClassID)
    self:DoStoryTips(chessEntityID, offset, tipsID)
end

function InnerStoryService:DoStoryTips(entityID, offset, tipsID)
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")
    local tipsEntity = entityService:CreateRenderEntity(EntityConfigIDRender.HeadStoryTips, false)
    tipsEntity:AddInnerStoryTipsComponent(entityID, offset, tipsID)
end

---@param  showType string
---@param type StoryShowType
function InnerStoryService:IsInnerStoryShowedInCurWaveAndCurRound(showType, type, waveIndex, roundNum)
    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()
    local showedData = battleRenderCmpt:GetInnerStoryShowed()
    for _, v in pairs(showedData) do
        if v:IsMe(type, showType, waveIndex, roundNum) then
            return true
        end
    end
    return false
end
