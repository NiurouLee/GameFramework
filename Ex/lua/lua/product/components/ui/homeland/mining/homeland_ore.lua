_class( "HomelandOre", Object )
---@class HomelandOre: Object
HomelandOre = HomelandOre

---@class OreState
local OreState= {
    Empty = 1,   -- 空状态
    Half = 2,   -- 减半状态
    Full = 3,   -- 满状态
}
_enum("OreState", OreState)

function HomelandOre:Constructor(oreID, oreGO, oreCfg, miningManager)
    ---@type number
    self._oreID = oreID
    ---@type UnityEngine.GameObject
    self._oreGO = oreGO
    ---@type table<string, number>
    self._oreCfg = oreCfg
    ---@type HomelandminingManager
    self._miningManager = miningManager

    ---@type number 已經挖掘次數
    self._dropTimes = 0
    self._nextRefreshTime = 0
    ---@type number
    self._cutTimes = 0
    ---@type H3DTimerEvent
    self._timerEvent = nil
    ---@type H3DTimerEvent
    self._refreshEvent = nil 
    ---@type UnityEngine.GameObject
    self._oreStateGo = oreGO

    ---@type number 清空砍伐次数的持续未砍伐时间(ms)
    self._clearCutTimesTime = 1000 * 60 * 30
    ---@type string
    self._oreGoName = {"CutForbidden.prefab","CutForbidden.prefab","CutForbidden.prefab"}
    ---@type Vector3
    self._oreStateGoOffset = Vector3(0, 0, 0)

    ---@type table<string, number>
    self._serverData  = nil 
    ---@type number
    self._refreshTimesTime = nil 

    self._needRefresh = true
    ---@type OreState
    self._oreState = nil 
    self._stoneLod0 =   self._oreGO.transform:Find("model/hl_envpfb_props_ore_01/meshroot/hl_envmod_props_ore_01_LOD0/hl_envmod_props_ore_01_part01")
    self._stoneLod1 =   self._oreGO.transform:Find("model/hl_envpfb_props_ore_01/meshroot/hl_envmod_props_ore_01_LOD1/hl_envmod_props_ore_01_part01")
    if(self._stoneLod0 == nil) then
        Log.error("HomelandOre:Constructor _stone = nil oreID ",self._oreID,self._oreGO.name)
    end

    self._objFadeCpt0 = self._stoneLod0:GetComponent(typeof(FadeComponent))
end


function HomelandOre:Dispose()
    if self._timerEvent then
        self._timerEvent:Cancel()
    end

    if self._oreStateGo then
        UIHelper.DestroyGameObject(self._oreStateGo)
        self._oreStateGo = nil
    end
end

function HomelandOre:ID()
    return self._oreID
end

function HomelandOre:GetInteractRedStatus()
    return false
end
-- 进交互领域
function HomelandOre:EnterInteractScope()
    self:RefreshOnOreStateChange()
end

function HomelandOre:LeaveInteractScope()
    if self._oreStateGo then
        -- UIHelper.DestroyGameObject(self._oreStateGo)
        -- self._oreStateGo = nil
    end    
end

function HomelandOre:RefreshOnOreStateChange()
    if not self._oreState then 
        self._oreState = self:GetOreState()
    else 
        if self:GetOreState() == self._oreState  then
            return 
        else 
            self._oreState = self:GetOreState()
        end
    end

    if self._oreState == OreState.Empty then
        self:Disappear() 
    else
        self._objFadeCpt0.Alpha = 1
        self._stoneLod0.gameObject:SetActive(true)
        self._stoneLod1.gameObject:SetActive(true)
    end
end

function HomelandOre:SetOreServerData(data)
    self._serverData = data
    -- if not self._needRefresh then 
    --     return
    -- end
    self:SetDropTimes(data.drop_times)
    self._needRefresh  =  self:CheckNeedRefresh() 
end

function HomelandOre:SetDropTimes(dropTimes)
    self._dropTimes = dropTimes
    self:RefreshOnOreStateChange()
end

function HomelandOre:SetRefreshTime(nextTime)
    -- if not self._needRefresh then 
    --     return
    -- end
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = self._timeModule:GetServerTime()
    self._nextRefreshTime = nextTime*1000 - nowTime
    if self._nextRefreshTime  >  0 and not self._refreshEvent  then
        self._refreshEvent = GameGlobal.Timer():AddEvent( self._nextRefreshTime, function()
            self._refreshEvent:Cancel()
            self._refreshEvent = nil 
            self._needRefresh  = true
            GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandRefreshOreInfo)
        end)
    end
end

function HomelandOre:IncreaseDropTimes()
    self._dropTimes = self._dropTimes + 1
    self:RefreshOnOreStateChange()
    self._needRefresh = self:CheckNeedRefresh()  
end

function HomelandOre:ResetClearTimer()
    if self._timerEvent then
        self._timerEvent:Cancel()
        self._timerEvent = nil
    end
    self._timerEvent = GameGlobal.Timer():AddEvent(self._clearCutTimesTime, function()
        self._cutTimes = 0
    end)
end

function HomelandOre:ClearCutTimes()
    self._cutTimes = 0
    if self._timerEvent then
        self._timerEvent:Cancel()
        self._timerEvent = nil
    end
    
end

function HomelandOre:IncreaseCutTimes()
    self._cutTimes = self._cutTimes + 1
    return self._cutTimes
end

function HomelandOre:GetInteractPosition(index)
    if self._interactpos == nil then
        self._interactpos = self._oreGO.transform.position
    end
    return self._interactpos
end

function HomelandOre:RefreshOreState(state)
    if state == OreState.Full then  

    elseif state == OreState.Half then 

    elseif state == OreState.Empty then 

    end  
end

function HomelandOre:ClearRefreshTimeEvent() 
    self._refreshEvent = nil 
end 

function HomelandOre:GetOreServerId() 
    if self._serverData then
        return  self._serverData.mine_id
    end
end 

function HomelandOre:CheckCanCut() 
   return  not (self._dropTimes  >= self._oreCfg.DropLimit )
end 

function HomelandOre:CheckNeedRefresh()  
    if self._dropTimes  >= self._oreCfg.DropLimit then 
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandOreRefresh)
        return true
    end
    return false
end

function HomelandOre:GetOreState()  
    local curState = OreState.Empty
    if self._dropTimes >= self._oreCfg.DropLimit then
        curState = OreState.Empty
    elseif self._dropTimes >= (self._oreCfg.DropLimit/2) and self._dropTimes < self._oreCfg.DropLimit then
        curState = OreState.Half
    else 
        curState = OreState.Full
    end
    return curState
end 


function HomelandOre:GetPlayerDirection(chara)  
    if not  self._oreStateGo then 
       return  chara._currentForward
    end 
    local pos = self._oreStateGo.transform.position
    local vec = Vector3(pos.x,0,pos.z)
    local charaPos =  Vector3(chara:Transform().position.x,0,chara:Transform().position.z)
    return vec - charaPos
end

function HomelandOre:GetCutRadius()
    return self._oreCfg.CutRadius
end

function HomelandOre:GetOreEffectPos(chara)
    local path = ""
    if self._oreStateGo then 
         local cfg = GameGlobal.GetUIModule(HomelandModule):GetCurrentToolCfg(ToolType.TT_PICK)
         path =  cfg.AttachPath
         local data =  string.split(cfg.Res, ".prefab")
         return path.."/"..data[1]
    end 
    return path
end 

function HomelandOre:Disappear() 
    TaskManager:GetInstance():StartTask(
        function(TT)
            local addtime = 0
            local anitime = 1
            local aptime = 1 / 20--消失的速率
            while (addtime < anitime) do
                self._objFadeCpt0.Alpha = self._objFadeCpt0.Alpha - aptime
                addtime = addtime + 0.05
                YIELD(TT, 10)
            end
            self._objFadeCpt0.Alpha = 0
            self._stoneLod0.gameObject:SetActive(false)
            self._stoneLod1.gameObject:SetActive(false)
        end
    )

end 

