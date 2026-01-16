---@class UIActivityN29DetectiveMapPoint : UICustomWidget
_class("UIActivityN29DetectiveMapPoint", UICustomWidget)
UIActivityN29DetectiveMapPoint = UIActivityN29DetectiveMapPoint

function UIActivityN29DetectiveMapPoint:Constructor(uiview)
    self._isExplored = true  --是否探索过
    self._isLock = true
end

function UIActivityN29DetectiveMapPoint:OnShow(uiParams)
    self:_GetComponent()
end

function UIActivityN29DetectiveMapPoint:_GetComponent()
    self._icon = self:GetUIComponent("RawImageLoader","icon")
    self._title = self:GetUIComponent("UILocalizationText","title")
    self._newObj = self:GetGameObject("new")
    self._markObj = self:GetGameObject("mark")
    self._parent = self:GetGameObject("parent")
    self._rect = self:GetUIComponent("RectTransform","rect")
    self._playerImg = self:GetUIComponent("RawImageLoader","playerImg")
    self._playerImgRect = self:GetUIComponent("RectTransform","playerImg")
    self._pointBtn = self:GetGameObject("pointBtn")
    self._anim = self:GetUIComponent("Animation","rect")

    self._rect.anchorMax = Vector2(0.5,0.5)
    self._rect.anchorMin = Vector2(0.5,0.5)
end

function UIActivityN29DetectiveMapPoint:SetData(data,campaign,psdid,stage)
    self._data = data
    self._campaign = campaign
    local localProcess = campaign:GetLocalProcess()
    self._compInfo = localProcess:GetComponentInfo(ECampaignN29ComponentID.ECAMPAIGN_N29_DETECTIVE)
    self._clueInfo = self._compInfo.cur_info
    self._psdId = psdid
    self._curStage = stage
    self._legalClueList = {}    --阶段合法线索列表

    --self:GetLegalClueList()
    self:CheckPointIsOver()
    self:InitData()
end

--通过阶段获得合法线索列表
function UIActivityN29DetectiveMapPoint:GetLegalClueList()
    local stageCfg = Cfg.cfg_component_detective_stage{}
    for i, cfg in pairs(stageCfg) do
        if i > self._curStage then
            return
        end
        local stageClues = cfg.ClueList
        table.appendArray(self._legalClueList,stageClues)
    end
end

function UIActivityN29DetectiveMapPoint:InitData()
    --设置初始位置
    local position = self._data.Position
    self._rect.anchoredPosition = Vector2(position[1]/10,position[2]/10)
    if self._data.PointPic then
        self._playerImg:LoadImage(self._data.PointPic)
        self._playerImgRect.sizeDelta = Vector2(self._data.PointPicSize[1],self._data.PointPicSize[2])
        if self._data.Scale then
            local scale = self._data.Scale * 0.01
            self._playerImgRect.localScale = Vector3(scale, scale, 1)
        end
    end
end

function UIActivityN29DetectiveMapPoint:GetCfg()
    return self._data
end

--获得锁定状态
function UIActivityN29DetectiveMapPoint:GetIsLockStatue()
    return self._isLock
end

--获得坐标位置X
function UIActivityN29DetectiveMapPoint:GetContentXPos()
    return self._rect.anchoredPosition.x
end

--获得坐标位置Y
function UIActivityN29DetectiveMapPoint:GetContentYPos()
    return self._rect.anchoredPosition.y
end

--从锁定状态切换到解锁状态
function UIActivityN29DetectiveMapPoint:SetUnLock(callback)
    self:StartTask(self._SetUnLockAnim,self,callback)
end

function UIActivityN29DetectiveMapPoint:_SetUnLockAnim(TT,callback)
    --此处需要改成播放动效
    self:SetPointActive(true)
    self:SetLock(false)
    self._newObj:SetActive(true)
    self:CheckPointIsOver()
    self._anim:Play("uieff_UIN29DetectiveMapPoint_unlock")
    YIELD(TT,600)
    self._anim:Play("uieff_UIN29DetectiveMapPoint_unlockedswing")
    if callback then
        callback()
    end
end

--取消new
function UIActivityN29DetectiveMapPoint:CancelNew()
    UIN29DetectiveHelper.SetOpenIdKey(self._psdId,"UIActivityN29DetectiveMapPoint"..self._data.ID)
    self._newObj:SetActive(false)
end

function UIActivityN29DetectiveMapPoint:SetLock(isLock,isAnim)
    self:StartTask(self._SetLock,self,isLock,isAnim)
end

function UIActivityN29DetectiveMapPoint:_SetLock(TT,isLock,isAnim)
    if isLock then
        --被锁定
        self._newObj:SetActive(false)
        self._isLock = true
        self._icon:LoadImage("n29_dt_icon03")
        self._title:SetText(StringTable.Get(self._data.HideName))
        self._markObj:SetActive(false)
    else
        --已解锁
        self._isLock = false
        self._title:SetText(StringTable.Get(self._data.ShowName))
        self._icon:LoadImage(self._data.Icon) 
    end

    -- if isAnim then
    --     if isLock then
    --         self._anim:Play("uieff_UIN29DetectiveMapPoint_lockedin")
    --     else
    --         self._anim:Play("uieff_UIN29DetectiveMapPoint_unlockedin")
    --     end
    --     YIELD(TT,500)
    --     self._anim:Play("uieff_UIN29DetectiveMapPoint_unlockedswing")
    -- end

    self._anim:Play("uieff_UIN29DetectiveMapPoint_unlockedswing")
end

--检查该点位是否探索完毕
function UIActivityN29DetectiveMapPoint:CheckPointIsOver()
    --检查new
    local hasKey = UIN29DetectiveHelper.CheckOpenIdKey(self._psdId,"UIActivityN29DetectiveMapPoint"..self._data.ID)
    if hasKey then
        self._newObj:SetActive(false)
        self:SetPointExplored()
        self._isExplored = true
    else
        self._newObj:SetActive(true)
        self._isExplored = false
    end

    local clueList = self._clueInfo.clue_list

    local needItems = Cfg.cfg_component_detective_waypoint[self._data.ID].WaypointContent
    local isOver = true
    for _, v in pairs(needItems) do
        local talkItem = nil
        if self._data.Type == 1 then
            local cfg = Cfg.cfg_component_detective_suspicious{}
            talkItem = cfg[v]
        else
            local cfg = Cfg.cfg_component_detective_talk{}
            talkItem = cfg[v]
        end 
        --本阶段产出线索
        local stageClues = Cfg.cfg_component_detective_stage[self._curStage].ClueList
        --检查是否已经有该玩法的产出线索
        local isContain = UIN29DetectiveHelper.Contain(clueList,talkItem.ClueId)
        --检查该线索是否是这个阶段产出的
        local isLegal = UIN29DetectiveHelper.Contain(stageClues,talkItem.ClueId)
        if isLegal then
            if not isContain and not talkItem.NeedClue then
                --如果该玩法的线索未持有 且该路点没有前置线索
                isOver = false
                break
            elseif not isContain and talkItem.NeedClue then
                --如果该玩法线索未持有 且有前置线索
                local isAllGet = true
                for i, need in pairs(talkItem.NeedClue) do
                    if not UIN29DetectiveHelper.Contain(clueList,need) then
                        --如果该玩法前置线索未完全持有
                        isAllGet = false
                    end
                end
                if isAllGet then --and not UIN29DetectiveHelper.CheckOpenIdKey(self._psdId,"UIN29DetectiveTalkItemShow"..talkItem.ID) then
                    isOver = false
                end
            end
        end
    end
    

    self._isOver = isOver
    self._markObj:SetActive(not isOver)
end

function UIActivityN29DetectiveMapPoint:GetPointIsOver()
    return self._isLock or self._isOver
end

function UIActivityN29DetectiveMapPoint:SetPointActive(isActive)
    self._parent:SetActive(isActive)
end

--设置成探索过的状态
function UIActivityN29DetectiveMapPoint:SetPointExplored()
    self._title:SetText(StringTable.Get(self._data.ShowName))
    self._icon:LoadImage(self._data.Icon)
end
------------------------------onclick--------------------------------
function UIActivityN29DetectiveMapPoint:PointBtnOnClick()
    --判断活动是否结束
     --- @type SvrTimeModule
     local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
     local curTime = svrTimeModule and math.floor(svrTimeModule:GetServerTime() * 0.001) or 0
     local closeTime =  self._compInfo.m_close_time
     local isOpen = curTime < closeTime
 
     if not isOpen then
         ToastManager.ShowToast(StringTable.Get("str_n24_specialtask_close"))
         self:SwitchState(UIStateType.UIActivityN29MainController)
         return
     end

    if not self._isExplored and not self._isLock then
        self:CancelNew()
        self:SetPointExplored()
    end
    
    self:ShowDialog("UIActivityN29DetectiveWayController",self,self._curStage,self._psdId)
end


function UIActivityN29DetectiveMapPoint:GetPointBtnGo()
    return self._pointBtn
end