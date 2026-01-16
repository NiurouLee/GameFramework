---@class HomelandFish:Object
_class("HomelandFish", Object)
HomelandFish = HomelandFish

function HomelandFish:Constructor(fishId)
    self._fishItemId = fishId --鱼的itemid
    local cfg = Cfg.cfg_item_homeland_fish[fishId]
    if not cfg then
        cfg = Cfg.cfg_item_wishing_coin[fishId]
    end
    if not cfg then
        Log.fatal("随机的鱼的ID错误：", fishId)
    end
    local fishingOperator = cfg.FishingOperator
    self._fishPowerLargeRange = fishingOperator[1] --鱼的力量大的范围
    self._rightPowerRange = fishingOperator[2] --正确力量的范围
    self._playerPowerLargeRange = fishingOperator[3] --人的力量大的范围
    self._decouplingTime = cfg.DecouplingTime / 1000 --鱼脱钩的时间
    self._lineBreakTime = cfg.LineBreakTime / 1000 --绳子断的时间
    if cfg.MoveRang then
        self._moveRange = cfg.MoveRange / 1000 --鱼移动的范围
    else
        self._moveRange = 1
    end
    if self._moveSpeed then
        self._moveSpeed = cfg.MoveSpeed / 1000 --鱼移动的速度
    else
        self._moveSpeed = 1
    end
    self._fishPowerSpeed = cfg.FishPowerSpeed
    self._fishRacePowerSpeed=cfg.FishRacePowerSpeed--比赛鱼的力量
    self._fishInvitePowerSpeed = cfg.FishInvitePowerSpeed--邀请鱼的力量

    self._model = cfg.FishEffect
    --正常钓鱼手感变化参数
    self._fishingOldOperator = cfg.FishingOldOperator


    Log.fatal("鱼id",fishId)

    if cfg == Cfg.cfg_item_homeland_fish[fishId] then
        --比赛钓鱼手感变化参数
        self._fishingRaceOperator = cfg.FishingRaceOperator
        --邀请钓鱼手感变化参数
        self._fishingInvitOperator = cfg.FishingInvitOperator

        local fishingOperatorRace = cfg.RaceType
        if fishingOperatorRace~=nil then
            self._fishPowerLargeRangeRace = fishingOperatorRace[1] --鱼的力量大的范围
            self._rightPowerRangeRace = fishingOperatorRace[2] --正确力量的范围
            self._playerPowerLargeRangeRace = fishingOperatorRace[3] --人的力量大的范围
        end
        local fishingOperatorInvite = cfg.InviteType
        if fishingOperatorInvite~=nil then
            self._fishPowerLargeRangeInvite = fishingOperatorInvite[1] --鱼的力量大的范围
            self._rightPowerRangeInvite = fishingOperatorInvite[2] --正确力量的范围
            self._playerPowerLargeRangeInvite = fishingOperatorInvite[3] --人的力量大的范围
        end
        
    elseif cfg == Cfg.cfg_item_wishing_coin[fishId] then
       --幸运币杂物
        local fishingOperator = cfg.FishingOperator
        self._fishPowerLargeRangeRace = fishingOperator[1] --鱼的力量大的范围
        self._rightPowerRangeRace = fishingOperator[2] --正确力量的范围
        self._playerPowerLargeRangeRace = fishingOperator[3] --人的力量大的范围
        
        self._fishPowerLargeRangeInvite = fishingOperator[1] --鱼的力量大的范围
        self._rightPowerRangeInvite= fishingOperator[2] --正确力量的范围
        self._playerPowerLargeRangeInvite = fishingOperator[3] --人的力量大的范围
    end
end

function HomelandFish:GetModel()
    return self._model
end

--正常钓鱼中鱼的速度力量
function HomelandFish:GetFishPowerSpeed(time)
    if self._fishPowerSpeed == nil or #self._fishPowerSpeed <= 0 then
        return -1
    end

    for i = 1, #self._fishPowerSpeed do
        local tmp = self._fishPowerSpeed[i]
        if time >= tmp.range[1] and time <= tmp.range[2] then
            return tmp.value / 1000
        end
    end

    return self._fishPowerSpeed[#self._fishPowerSpeed].value / 1000
end

--比赛钓鱼中鱼的速度力量
function HomelandFish:GetRaceFishPowerSpeed(time)
    if self._fishRacePowerSpeed == nil or #self._fishRacePowerSpeed <= 0 then
        return -1
    end

    for i = 1, #self._fishRacePowerSpeed do
        local tmp = self._fishRacePowerSpeed[i]
        if time >= tmp.range[1] and time <= tmp.range[2] then
            return tmp.value / 1000
        end
    end

    return self._fishRacePowerSpeed[#self._fishRacePowerSpeed].value / 1000
end

--邀请钓鱼中鱼的速度力量
function HomelandFish:GetInviteFishPowerSpeed(time)
    if self._fishInvitePowerSpeed == nil or #self._fishInvitePowerSpeed <= 0 then
        return -1
    end

    for i = 1, #self._fishInvitePowerSpeed do
        local tmp = self._fishInvitePowerSpeed[i]
        if time >= tmp.range[1] and time <= tmp.range[2] then
            return tmp.value / 1000
        end
    end

    return self._fishInvitePowerSpeed[#self._fishInvitePowerSpeed].value / 1000
end

--获取物品Id
function HomelandFish:GetItemId()
    return self._fishItemId
end

--获取鱼脱钩的时间长度
function HomelandFish:GetDecouplingTime()
    return self._decouplingTime
end

--获取绳子断的时间长度
function HomelandFish:GetLineBreakTime()
    return self._lineBreakTime
end

--获取力的范围
function HomelandFish:GetPowerRange()
    return 0, self._fishPowerLargeRange + self._rightPowerRange + self._playerPowerLargeRange
end

--新增获取比赛钓鱼 力的范围
function HomelandFish:GetRacePowerRange()
    return 0, self._fishPowerLargeRangeRace + self._rightPowerRangeRace + self._playerPowerLargeRangeRace
end
--新增获取邀请钓鱼 力的范围
function HomelandFish:GetInvitePowerRange()
    return 0, self._fishPowerLargeRangeInvite + self._rightPowerRangeInvite + self._playerPowerLargeRangeInvite
end

--获取正确的力的范围
function HomelandFish:GetRightPowerRange()
    return self._fishPowerLargeRange, self._fishPowerLargeRange + self._rightPowerRange
end

--获取比赛钓鱼 正确力的范围
function HomelandFish:GetRaceRightPowerRange()
    return self._fishPowerLargeRangeRace, self._fishPowerLargeRangeRace + self._rightPowerRangeRace
end

--获取邀请钓鱼 正确力的范围
function HomelandFish:GetInviteRightPowerRange()
    return self._fishPowerLargeRangeInvite, self._fishPowerLargeRangeInvite + self._rightPowerRangeInvite
end

--获取鱼移动的范围
function HomelandFish:GetMoveRange()
    return self._moveRange
end

--获取鱼移动的速度
function HomelandFish:GetMoveSpeed()
    return self._moveSpeed
end

--获取能量条移动速度
function HomelandFish:GetGameMoveSpeed(type,n)
    if type==3 then
        if self._fishingRaceOperator == nil then
            return nil
        else
            if n <= #self._fishingRaceOperator then
                self._moveSpeed=self._fishingRaceOperator[n][1]
            else
                self._moveSpeed=0
            end
            return self._moveSpeed/100
        end
    elseif type==5 then
        if self._fishingInvitOperator == nil then
            return nil
        else
            if n <= #self._fishingInvitOperator then
                self._moveSpeed=self._fishingInvitOperator[n][1]
            else
                self._moveSpeed=0
            end
            return self._moveSpeed/100
        end
    elseif type ==6 or type == 1 then
        if self._fishingOldOperator == nil then
            return nil
        else
            if n <= #self._fishingOldOperator then
                self._moveSpeed=self._fishingOldOperator[n][1]
            else
                self._moveSpeed=0
            end
            return self._moveSpeed/100
        end
    end
end

--获取能量条移动时间 
function HomelandFish:GetMoveTime(type,n)
    if type==3 then
        if self._fishingRaceOperator == nil then
            return nil
        else
            if n <= #self._fishingRaceOperator then
                self._moveTime=self._fishingRaceOperator[n][2]
            else
                -- n=#self._fishingRaceOperator
                -- self._moveTime=self._fishingRaceOperator[n][2]
                self._moveTime=0
            end
            return self._moveTime
        end
    elseif type==5 then
        if self._fishingInvitOperator == nil then
            return nil
        else
            if n <= #self._fishingInvitOperator then
                self._moveTime=self._fishingInvitOperator[n][2]
            else
                -- n = #self._fishingInvitOperator
                -- self._moveTime=self._fishingInvitOperator[n][2]
                self._moveTime=0
            end
            return self._moveTime
        end
    elseif type ==6 or type == 1 then
        if self._fishingOldOperator == nil then
            return nil
        else
            if n <= #self._fishingOldOperator then
                self._moveTime=self._fishingOldOperator[n][2]
            else
                -- n=#self._fishingOldOperator
                -- self._moveTime=self._fishingOldOperator[n][2]
                self._moveTime=0
            end
            return self._moveTime
        end
    end
    return self._moveTime
end

--获取能量条变化格数
function HomelandFish:GetChangeLength(type,n)
    if type==3 then
        if self._fishingRaceOperator == nil then
            return nil
        else
            if n <= #self._fishingRaceOperator then
                self._changeLength=self._fishingRaceOperator[n][3]
            else
                -- n = #self._fishingRaceOperator
                -- self._changeLength=self._fishingRaceOperator[n][3]
                self._changeLength=0
            end
            return self._changeLength
        end
    elseif type==5 then
        if self._fishingInvitOperator == nil then
            return nil
        else
            if n <= #self._fishingInvitOperator then
                self._changeLength=self._fishingInvitOperator[n][3]
            else
                -- n = #self._fishingInvitOperator
                -- self._changeLength=self._fishingInvitOperator[n][3]
                self._changeLength=0
            end
            return self._changeLength
        end
    elseif type ==6 or type == 1 then
        if self._fishingOldOperator == nil then
            return nil
        else
            if n <= #self._fishingOldOperator then
                self._changeLength=self._fishingOldOperator[n][3]
            else
                -- n = #self._fishingOldOperator
                -- self._changeLength=self._fishingOldOperator[n][3]
                self._changeLength=0
            end
            return self._changeLength
        end
    end
end
--获取能量条变化时间
function HomelandFish:GetChangeTime(type,n)
    if type==3 then
        if self._fishingRaceOperator == nil then
            return nil
        else
            if n <= #self._fishingRaceOperator then
                self._changeTime=self._fishingRaceOperator[n][4]
            else
                -- n = #self._fishingRaceOperator
                -- self._changeTime=self._fishingRaceOperator[n][4]
                self._changeTime=0
            end
            return self._changeTime
        end
    elseif type==5 then
        if self._fishingInvitOperator == nil then
            return nil
        else
            if n <= #self._fishingInvitOperator then
                self._changeTime=self._fishingInvitOperator[n][4]
            else
                -- n = #self._fishingInvitOperator
                -- self._changeTime=self._fishingInvitOperator[n][4]
                self._changeTime=0
            end
            return self._changeTime
        end
    elseif type ==6 or type == 1 then
        if self._fishingOldOperator == nil then
            return nil
        else
            if n <= #self._fishingOldOperator then
                self._changeTime=self._fishingOldOperator[n][4]
            else
                -- n = #self._fishingOldOperator
                -- self._changeTime=self._fishingOldOperator[n][4]
                self._changeTime=0
            end
            return self._changeTime
        end
    end
end


