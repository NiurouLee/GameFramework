--[[------------------------------------------------------------------------------------------
    DropService 处理掉落的公共服务 
]] --------------------------------------------------------------------------------------------

_class("DropService", BaseService)
---@class DropService:BaseService
DropService = DropService

function DropService:Constructor(world)

end

---执行actor身上的掉落
---@param dropID number 掉落ID
---@param hostEntityID number 掉落的宿主Entity ID
---@param isHide boolean 是否隐藏
function DropService:DoActorDrop(dropID, hostEntityID, isHide)
    ---@type ConfigService
    local configService = self._configService
    ---@type MonsterDropConfigData
    local dropConfigData = configService:GetMonsterDropConfigData()
    local dropItemID = dropConfigData:GetMonsterDropItemID(dropID)
    local dropCount = self:_CalcRandomDropCount(dropID)
    ---@type MonsterDropItemConfigData
    local dropItemConfig = configService:GetMonsterDropItemConfigData(dropItemID)

    local hostEntity = self._world:GetEntityByID(hostEntityID)
    if dropItemConfig:GetPickupType(dropItemID) == DropPickUpType.Auto then
        if dropItemConfig:GetDropEffectType(dropItemID) == DropEffectType.InBag then
            local assetID = tonumber(dropItemConfig:GetDropEffectParam(dropItemID)[1])
            local battleStatCmpt = self._world:BattleStat()
            if battleStatCmpt:AssignWaveResult() then -- 如果是指定结束波次之后的波次不享受双倍券奖励
                self:_GetBattleStatComponent():AddDropRoleAssetNoDouble(assetID, dropCount)
            else
                self:_GetBattleStatComponent():AddDropRoleAsset(assetID, dropCount)
            end

            local retAssest = RoleAsset:New()
            retAssest.assetid = assetID
            retAssest.count = dropCount
            return retAssest
        end
    else
    end
end

---计算随机掉落数量
---@return number 掉落的数量
function DropService:_CalcRandomDropCount(dropID)
    ---@type ConfigService
    local configService = self._configService
    ---@type MonsterDropConfigData
    local dropConfigData = configService:GetMonsterDropConfigData()
    local dropMinCount = dropConfigData:GetMonsterDropMinCount(dropID)
    local dropMaxCount = dropConfigData:GetMonsterDropMaxCount(dropID)
    local dropProb = dropConfigData:GetMonsterDropProbability(dropID)

    ---todo 这里的随机方法后边也许会抽成公共的接口
    local randomNum = self:_GetRandomNumber()
    if randomNum > dropProb then
        return 0
    end

    ---随机一个掉落数量
    local dropCount = self:_GetRandomNumber(dropMinCount, dropMaxCount)
    return dropCount
end
