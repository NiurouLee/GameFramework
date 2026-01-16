---@class HomelandFishMatch:Object
_class("HomelandFishMatch", Object)
HomelandFishMatch = HomelandFishMatch

-- 钓鱼比赛结束类型
--- @class FishMatchEndType
local FishMatchEndType = {
    MATCHEND_CLOSE = 1, -- 玩家手动关闭
    MATCHEND_WIN = 2, -- 玩家获胜
    MATCHEND_LOSE = 3, -- 光灵获胜
    MATCHEND_COMPLETE = 4, --比赛完成
}
_enum("FishMatchEndType", FishMatchEndType)

---@param mainCfg table
---@param pet HomelandPet
function HomelandFishMatch:Constructor(mainCfg,pet,istask)
    self._mainCfg = mainCfg
    self._matchID = mainCfg.MatchID  --比赛id
    self._matchcfg = Cfg.cfg_homeland_fishmatch_match[mainCfg.MatchID]
    self._pet = pet
    self._petID = self._mainCfg.PetID
    self._posIndex = 1  --位置索引
    self._isTempPet = false 
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)

    if self._cbFishMatchEnd == nil  then
        self._cbFishMatchEnd = GameHelper:GetInstance():CreateCallback(self.FishMatchEnd, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.FishMatchEnd, self._cbFishMatchEnd)
    end
    self.istask = istask
    self:_CreatePet(self._pet)
end

function HomelandFishMatch:Dispose()
    if self._cbFishMatchEnd then 
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.FishMatchEnd,self._cbFishMatchEnd )
        self._cbFishMatchEnd = nil 
    end 
end

function HomelandFishMatch:GetMainID()
    return self._mainCfg.ID
end

--获得比赛ID
function HomelandFishMatch:GetMatchID()
    return self._matchID
end

--获得比赛配置
function HomelandFishMatch:GetMatchCfg()
    return self._matchcfg
end

--获得比赛取消对话
function HomelandFishMatch:GetCancelChatID()
    return self._matchcfg.CancelChatID
end

--获得与光灵对话chatID
function HomelandFishMatch:GetChatID()
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    local isWin = times and (times > 0)  --钓鱼比赛成功次数
    if isWin then
        return self._matchcfg.WinChatID
    else
        return self._matchcfg.NormalChatID
    end
end

--获得与光灵二次对话chatID
function HomelandFishMatch:GetSecChatID()
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    local isWin = times and (times > 0)  --钓鱼比赛成功次数
    if isWin then
        return self._matchcfg.SecWinChatID
    else
        return self._matchcfg.SecChatID
    end
end

--获得与光灵邀请钓鱼的标题
function HomelandFishMatch:GetFishMatchInteractTitle()
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    local isWin = times and (times > 0)  --钓鱼比赛成功次数
    if isWin then
        return self._matchcfg.WinInteractTxt
    else
        return self._matchcfg.NormalInteractTxt
    end
end

--获得与光灵钓鱼比赛的标题
function HomelandFishMatch:GetFishMatchPlayInteractTitle()
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    local isWin = times and (times > 0)  --钓鱼比赛成功次数
    if isWin then
        return self._matchcfg.SecWinInteractTxt
    else
        return self._matchcfg.SecInteractTxt
    end
end

--获得取消光灵钓鱼比赛的标题
function HomelandFishMatch:GetCancelFishMatchInteractTitle()
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    local isWin = times and (times > 0)  --钓鱼比赛成功次数
    if isWin then
        return self._matchcfg.SecWinCancelTxt
    else
        return self._matchcfg.SecCancelTxt
    end
end

--获得与光灵再见标题
function HomelandFishMatch:GetByeFishMatchInteractTitle()
    return self._matchcfg.SecByeTxt
end

--获得比赛成功次数
function HomelandFishMatch:GetWinTimes()
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    return times
end

--比赛
function HomelandFishMatch:PetMatchCancel()
    local behaviour = self._pet:GetPetBehavior()
    if behaviour:GetHasBehaviors() then
        self._pet:SetOccupied(HomelandPetOccupiedType.None)
        self._pet:BreakUpMatch()
        behaviour:ChangeBehavior(HomelandPetBehaviorType.Roam)
        self:Dispose()
    end
end

--将光灵设置回原点
function HomelandFishMatch:PetSetBornPos()
    --暂时先这么写 直接判断pet有问题
    local behaviour = self._pet:GetPetBehavior()
    if behaviour:GetHasBehaviors() then
        self._pet:SetPosition(Vector3(0,0,0))
    end
end

--结束对话回调  邀请钓鱼比赛
function HomelandFishMatch:EndTalkCallback()
    GameGlobal.TaskManager():CoreGameStartTask(self._ChangeBothPos,self)
end

--传送
function HomelandFishMatch:_ChangeBothPos(TT)
    CutsceneManager.ExcuteCutsceneIn(UIStateType.UIHomeStoryController .. "DirectIn")
    YIELD(TT,1000)
    CutsceneManager.ExcuteCutsceneOut()

    local petPos,playerPos = self:_GetCloesestPos()
    local tmpPetRot = self._mainCfg.PetRotList[self._posIndex]
    local petRot = Quaternion.Euler(Vector3(tmpPetRot[1],tmpPetRot[2],tmpPetRot[3]))
    local tmpPlayerRot = self._mainCfg.RotList[self._posIndex]
    local playerRot = Quaternion.Euler(Vector3(tmpPlayerRot[1],tmpPlayerRot[2],tmpPlayerRot[3]))

    self._pet:SetPosition(petPos)
    self._pet:SetRotation(petRot)
    
    ---@type ClientHomelandInfo
    local homelandInfo = self._homelandModule:GetHomelandInfo()
    local times = homelandInfo.fishing_data.challenge_pet_times[self._mainCfg.PetID]
    local isWin = times and (times > 0)  --钓鱼比赛成功次数
    if self.istask then 
    
    else 
        if isWin then
            self._pet:SetMatchChatID(self._matchcfg.SecWinChatID)
        else
            self._pet:SetMatchChatID(self._matchcfg.SecChatID)
        end
    end
   
    --设置主角位置
    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    local character = homelandClient:CharacterManager():MainCharacterController()
    character:SetLocation(playerPos, playerRot)
end

--获得最近的点位
---@return Vector3 petPos
---@return Vector3 playerPos
function HomelandFishMatch:_GetCloesestPos()
    local posList = self._mainCfg.PetPosList
    local minDis = math.maxinteger
    for i,v in pairs(posList) do
        local cal = v[1]^2 + v[2]^2 + v[3]^2
        if cal < minDis then
            self._posIndex = i
            minDis = cal
        end
    end

    local tmpPetRot = posList[self._posIndex]
    local tmpPlayerRot = self._mainCfg.PosList[self._posIndex]
    local petPos = Vector3(tmpPetRot[1]/1000,tmpPetRot[2]/1000,tmpPetRot[3]/1000)
    local playerPos = Vector3(tmpPlayerRot[1]/1000,tmpPlayerRot[2]/1000,tmpPlayerRot[3]/1000)

    return petPos, playerPos
end

--结束对话回调  开始钓鱼比赛
function HomelandFishMatch:StartMatchTalkCallBack()
    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    local character = homelandClient:CharacterManager():MainCharacterController()
    character:SetForbiddenMove(true,HomelandActorStateType.Idle)
    character:SetIsFishMach(true)

    GameGlobal.TaskManager():CoreGameStartTask(self._StartMatch,self)
end

function HomelandFishMatch:_StartMatch(TT)
    CutsceneManager.ExcuteCutsceneIn(UIStateType.UIHomeStoryController .. "DirectIn")
    YIELD(TT,500)

    self:OnStart()
    --设置玩家位置 旋转
    local petPos,playerPos = self:_GetCloesestPos()
    local tmpPlayerRot = self._mainCfg.RotList[self._posIndex]
    local playerRot = Quaternion.Euler(Vector3(tmpPlayerRot[1],tmpPlayerRot[2],tmpPlayerRot[3]))

    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    local character = homelandClient:CharacterManager():MainCharacterController()
    character:SetLocation(playerPos, playerRot)
    character:SetCameraForward()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.FishMatchReady,self._mainCfg.ID,self)
    YIELD(TT,500)
    CutsceneManager.ExcuteCutsceneOut()
end

--钓鱼比赛结束
--- @param resType FishMatchEndType 
function HomelandFishMatch:FishMatchEnd(resType)
    local endScale = -5  --相机缩放
    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    local character = homelandClient:CharacterManager():MainCharacterController()
    character:SetIsFishMach(false)
    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    ---@type HomelandFollowCameraController
    local cameraCtl = homelandClient:CameraManager():FollowCameraController()
    self._curScale = cameraCtl:CurrentScale()
    self._curXAngle = cameraCtl:NowXAngle()
    self._curRot = cameraCtl:Rotation()

    local cameraPos = self._mainCfg.EndCameraPosList[self._posIndex]
    local cameraRot = self._mainCfg.EndCameraRotList[self._posIndex]
    cameraCtl:UpdatePos(Vector3(cameraPos[1]/1000,cameraPos[2]/1000,cameraPos[3]/1000))
    cameraCtl:SetCamLocation(cameraRot[1]/100,cameraRot[2]/100,cameraRot[3])
    cameraCtl:StopCameraScale(true)
    cameraCtl:HandleScaleForStory(endScale)
end

--钓鱼比赛结束状态恢复
function HomelandFishMatch:FishMatchEndReset()
    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    local character = homelandClient:CharacterManager():MainCharacterController()
    if self._curScale then
        local charaTr = character:Transform()
        local cameraCtl = homelandClient:CameraManager():FollowCameraController()
        cameraCtl:UpdatePos(charaTr.position)
        cameraCtl:SetXRotation(self._curXAngle)
        cameraCtl:SetRotation(self._curRot)
        cameraCtl:StopCameraScale(false)
        cameraCtl:HandleScaleForStory(self._curScale)
    end
    if not  self._isTempPet then 
        self._pet:GetPetBehavior():ChangeBehavior(HomelandPetBehaviorType.FishingPrepare)
    end
    if self._isNpcPet then
        HomelandFishMatchManager:GetInstance():ChangeMatch(nil)
    end
    character:SetForbiddenMove(false,HomelandActorStateType.Idle)
    self:OnEnd()
end

--钓鱼比赛结束
function HomelandFishMatch:_CreatePet(pet)
    if HomelandPet:IsInstanceOfType(pet) then

    elseif HomelandTaskNPC:IsInstanceOfType(pet) then
        --钓鱼比赛
        self._isNpcPet = true
        local homelandClient = self._homelandModule:GetUIModule():GetClient()
        local petMgr = homelandClient:PetManager()
        local petId = pet:PetID()
        local pet,isTemp =  petMgr:GetTempPet(petId)
        self._isTempPet = isTemp
        self._pet = pet
    end
end

function HomelandFishMatch:_GetRunningTask()
    local homelandClient = self._homelandModule:GetUIModule():GetClient()
    local task = homelandClient:GetHomelandTaskManager():GetRuningTask()
    if not task then
        task = homelandClient:GetHomelandTaskManager():GetHomelandStoryTaskManager():GetRuningTaskItem()
    end
    return task
end

function HomelandFishMatch:OnStart()
    if  self._isNpcPet then
        self._task = self:_GetRunningTask()
        if self._task then 
            self._pet._fadeCpt.Alpha = 1
            self._pet._finalVisible = true
            self._pet:_EnableSkinnedMeshRender(true)
            self._pet:SetOccupied(HomelandPetOccupiedType.FishingMatch)
            self._pet:GetPetBehavior():StartBehavior(HomelandPetBehaviorType.FishingMatch)
            self._task:DisposeTrace()
            self._task:DestroyNpcs()
        end 
    end 
end

function HomelandFishMatch:OnEnd()
    if self._isNpcPet then
        if self._isTempPet then 
            local homelandClient = self._homelandModule:GetUIModule():GetClient()
            local petMgr = homelandClient:PetManager()
            petMgr:DeleteTempPet( self._pet:TemplateID())
        else 
        
        end 
        if  not self._task then  
           return 
        end 
        local task = self:_GetRunningTask()
        if task  then 
            task:CreateTaskNpc()
        end 
        self._task = nil 
    end 
end

function HomelandFishMatch:IsTask()
    return self.istask
end