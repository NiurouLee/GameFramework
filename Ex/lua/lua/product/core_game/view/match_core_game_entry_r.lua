--[[------------------------------------------------------------------------------------------
    三消客户端局内入口
]] --------------------------------------------------------------------------------------------
---@class MatchCoreGameEntry:Object
_class("MatchCoreGameEntry", Object)
MatchCoreGameEntry = MatchCoreGameEntry

---@param matchEnterData MatchEnterData
function MatchCoreGameEntry:Constructor(matchEnterData, enterPreferenceData)
    self._matchEnterData = matchEnterData
    self._enterPreferenceData = enterPreferenceData
end

function MatchCoreGameEntry:InitalizeCoreGame()
	---@type MainWorldCreationContext
	local worldInfo  = self._matchEnterData:CreateWorldInfo(MainWorldCreationContextType.Client)
	---局内 是否播放技能动画设定
	worldInfo.enterTime = self._enterPreferenceData.enterTime
	worldInfo.preferenceSkillSpine = self._enterPreferenceData.preferenceSkillSpine
	worldInfo.preferenceSkillSpineLastPlayList = self._enterPreferenceData.preferenceSkillSpineLastPlayList
	worldInfo.hadPlaySkillSpineNameList = self._enterPreferenceData.hadPlaySkillSpineNameList
    ---创建游戏世界
    local clientWorld = ClientWorld:New(worldInfo)
    self.clientWorld = clientWorld
    clientWorld:GetSyncLogger():CheckEnabled()
    clientWorld:GetMatchLogger():CheckEnabled()
    clientWorld:EnterWorld()
    clientWorld:GetDataLogger():EnableDataLog()
    clientWorld:GetDataLogger():AddDataLog("OnBattleStart")

    ---@type ClientTimeService
    self._timeService = self.clientWorld:GetService("Time")
    self._running = true
    self._print_mem_time = 0
end

function MatchCoreGameEntry:Stop()
    self._running = false
end

function MatchCoreGameEntry:Running()
    return self._running
end

function MatchCoreGameEntry:Dispose()
    self._matchEnterData = nil
    self._enterPreferenceData = nil

    self.clientWorld:ExitWorld()
    self.clientWorld:Dispose()

    InnerGameHelperRender:GetInstance():Dispose()
end

function MatchCoreGameEntry:Update(curTimeMS, deltaTimeMS)
    self._timeService:SetCurrentTime(curTimeMS)
    self._timeService:SetDeltaTime(deltaTimeMS)

    self.clientWorld:UpdateWorld(deltaTimeMS)

    self._print_mem_time = self._print_mem_time + deltaTimeMS
    if (self._print_mem_time > 20 * 1000) then
        local memoryCount = math.floor(collectgarbage("count") / 1024)
        Log.prof("[luamem] coregame current memory: ", memoryCount, " MB")
        self._print_mem_time = 0
    end
end

function MatchCoreGameEntry:GetCurWorldStateID()
    if self.clientWorld ~= nil then
        ---@type UtilDataServiceShare
        local utilDataSvc = self.clientWorld:GetService("UtilData")
        return utilDataSvc:GetCurMainStateID()
    end

    return GameStateID.Invalid
end

function MatchCoreGameEntry:InputEnalbe()
    if self.clientWorld ~= nil then
        local isNormalState = self.clientWorld:MainCamera():IsNormalState()

        ---@type UtilDataServiceShare
        local utilDataSvc = self.clientWorld:GetService("UtilData")
        return utilDataSvc:GetMainStateInputEnable() and isNormalState
    end

    return false
end

function MatchCoreGameEntry:IsLinkLineState()
	if self.clientWorld ~= nil then
		---@type MainCameraComponent
		local mainCameraComponent = self.clientWorld:MainCamera()
		local isLinkLineState =	mainCameraComponent:IsFocusPlayer()
		return isLinkLineState
	end
	return false
end

---关闭场景里的相机
function MatchCoreGameEntry:CloseCoreGameCamera()
    if self.clientWorld ~= nil then
        ---@type MainCameraComponent
        local cameraCmpt = self.clientWorld:MainCamera()
        cameraCmpt:CloseCamera()
    end
end
