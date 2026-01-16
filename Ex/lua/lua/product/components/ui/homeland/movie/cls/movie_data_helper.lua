_class("MovieDataHelper", Object)
---@class MovieDataHelper : Object
MovieDataHelper = MovieDataHelper

function MovieDataHelper:Constructor()
    self:Init()
end

function MovieDataHelper:Init()
    self._cfgMovie = Cfg.cfg_homeland_movice {}
    self._cfgMovieItem = Cfg.cfg_homeland_movice_item {}
    self._cfgMovieScore = Cfg.cfg_homeland_movice_score {}
    self._cfgAnonymousLetter = Cfg.cfg_homeland_anonymous_letter{}
end 

---@param id number
function MovieDataHelper:GetMovieCfgByMovieId(id)
    local cfg = self._cfgMovie[id]
    return cfg
end

---@param id number
function MovieDataHelper:GetMovieItemTitleById(id,phase)
    local movieCfg = self:GetMovieCfgByMovieId(id)
    if not movieCfg then
       return 
    end 

    if phase == MoviePrepareType.PT_Scene then 
        local endList = {} 
        for i = 1, 2 do
            table.insert(endList,movieCfg.ItemPosList[i])
        end 
        return endList
    end 
    if phase == MoviePrepareType.PT_Prop then 
        local endList = {} 
        for i = 3, #movieCfg.ItemPosList do
            table.insert(endList,movieCfg.ItemPosList[i])
        end 
        return endList
    end 
    if phase == MoviePrepareType.PT_Actor then 
        return movieCfg.RolePosList
    end 
end

function MovieDataHelper:GetMovieItemByItemId(itemid)
    return self._cfgMovieItem[itemid]
end

function MovieDataHelper:GetSkinByPrefabId(petID)
    local cfg =  Cfg.cfg_pet_skin { Prefab = petID..".prefab"}
    return cfg
 end

function MovieDataHelper:GetArchitectureItemCfg(itemid)
    local cfg = Cfg.cfg_item_architecture{}
    return cfg[itemid]
end

--获取
---@param id number
function MovieDataHelper:GetAnonymousMovieTimeById(id)
    self._unlockTime=self._cfgAnonymousLetter[id].UnlockTime--表中解锁时间

    local loginModule = GameGlobal.GetModule(LoginModule)
    local unlockTime = loginModule:GetTimeStampByTimeStr(self._unlockTime,Enum_DateTimeZoneType.E_ZoneType_GMT)

    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = math.floor(self._svrTimeModule:GetServerTime()*0.001)--服务器时间
    local sec = nowTime - unlockTime
    return sec
end

--获取所有匿名信件id
function MovieDataHelper:GetAllAnonymousId()
    local AnonymousId={}
    for k, v in ipairs(self._cfgAnonymousLetter) do  
        table.insert(AnonymousId,v.ID)
    end
    return AnonymousId
end

--排序
function MovieDataHelper:SortAnonymous()
    local sortId = self:GetAllAnonymousId()

    local sortFuc= function(a, b)
        local acout = self:GetAnonymousCountdownTimeById(a)
        local bcount = self:GetAnonymousCountdownTimeById(b)
        return  acout < bcount
    end
    table.sort(sortId, sortFuc)
    return sortId

end

--获取倒计时
---@param id number
function MovieDataHelper:GetAnonymousCountdownTimeById(id)
    self._unlockTime=self._cfgAnonymousLetter[id].UnlockTime--表中解锁时间
    
    local loginModule = GameGlobal.GetModule(LoginModule)
    local unlockTime = loginModule:GetTimeStampByTimeStr(self._unlockTime,Enum_DateTimeZoneType.E_ZoneType_GMT)
    
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = math.floor(self._svrTimeModule:GetServerTime()*0.001)--服务器时间

    local countdown = unlockTime - nowTime
    return countdown
end

function MovieDataHelper:GetFormatTimerStr(time)
    local timeStr = nil
    local hour, min,second= MovieDataHelper:Time2Str(time)

    if hour > 0 and min ~= 0 then
        if min<10 then
            timeStr = hour .. ":0" .. min
        else
            timeStr = hour .. ":" .. min
        end
    elseif hour > 0 and min == 0 then
        timeStr = hour .. ":00"
    elseif min > 0 then
        timeStr = "00:" .. min
    elseif hour == 0 and min == 0 and second>0 then
        timeStr = "00:01"
    else
        timeStr = nil
    end
    return timeStr
end
--
function MovieDataHelper:Time2Str(time)
    local second = time % 60
    local min = math.floor(time / 60) % 60
    local hour = math.floor(time / 60 / 60)
    return hour, min,second
end

--判断当前是否有匿名奖励
function MovieDataHelper:ShowOrNot()
    local Anonymousname={}
    for k, v in ipairs(self._cfgAnonymousLetter) do  
        table.insert(Anonymousname,v.ID)
    end
    ---@type HomelandModule
    local homeModule = GameGlobal.GetModule(HomelandModule)
    local Anonymouslist = homeModule:GetAnonymousLetterRreward()

    if #Anonymouslist==0 then
        for _, v in ipairs(Anonymousname) do
            local sec=self:GetAnonymousMovieTimeById(v)
            if sec > 0  then
                return true,v
            end
        end
    else
        --是否领过奖

        for k1, v1 in ipairs(Anonymousname) do
            for k2, v2 in ipairs(Anonymouslist) do
                --删除重复table数据
                for i=1,#Anonymouslist do
                if  v1 == v2 then         
                    table.remove(Anonymousname, k1)
                end
                end
            end
        end
        --是否到时间
        for _, v in ipairs(Anonymousname) do
            local sec=self:GetAnonymousMovieTimeById(v)
            if sec > 0  then
                return true,v
            end
        end
    end
    return false
end


