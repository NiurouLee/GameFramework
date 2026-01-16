---@class UIActivityMissionNodeInfo:Object
_class("UIActivityMissionNodeInfo", Object)
UIActivityMissionNodeInfo = UIActivityMissionNodeInfo

function UIActivityMissionNodeInfo:Constructor()
    self.campaignMissionId = 0 -- 关卡id
    self.pos = Vector2.zero -- 节点坐标
    self.name = ""
    self.title = ""
    self.type = 0 -- 关卡类型
    self.isSLevel = false
    self.state = nil -- 关卡通关状态
    self.starCount = 0 -- 星星数量

    self._missionModule = GameGlobal.GetModule(MissionModule)
end

function UIActivityMissionNodeInfo:Init(id, posX, posY, name, title, type, isSLevel, state, starCount)
    self.campaignMissionId = id
    self.pos.x = posX
    self.pos.y = posY
    self.name = name
    self.title = title
    self.type = type
    self.isSLevel = isSLevel
    self.state = state
    self.starCount = starCount
end

---@public
---@return DiscoveryStageState
---当前结点的状态
function UIActivityMissionNodeInfo:State()
    if self.stages then
        local passCount = 0
        local canActiveCount = 0
        for i, v in ipairs(self.stages) do
            if v.state == DiscoveryStageState.Nomal then
                passCount = passCount + 1
            elseif v.state == DiscoveryStageState.CanPlay then
                canActiveCount = canActiveCount + 1
            end
        end
        if passCount > 0 then --只要有一个关卡通关，该路点就是通关状态
            return DiscoveryStageState.Nomal
        end
        if canActiveCount > 0 then --只要有一个可激活关卡，该路点就是可挑战状态
            return DiscoveryStageState.CanPlay
        end
    end
    return nil --否则就是未激活状态，不可见
end

--region FisrtShow
---@return boolean 是否是第一次显示
function UIActivityMissionNodeInfo:IsFirstShow()
    local playerPrefsKey = self:GetFirstShowKey()
    local isFirst = UnityEngine.PlayerPrefs.GetInt(playerPrefsKey, 0)
    return isFirst == 0
end
function UIActivityMissionNodeInfo:SaveIsFirstShow()
    local playerPrefsKey = self:GetFirstShowKey()
    UnityEngine.PlayerPrefs.SetInt(playerPrefsKey, 1)
end
function UIActivityMissionNodeInfo:GetFirstShowKey()
    local playerPrefsKey = self:GetPstId() .. "UIActivityMissionNodeInfoIsFirstShow" .. self.id
    return playerPrefsKey
end

---@private
function UIActivityMissionNodeInfo:GetPstId()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    return roleModule:GetPstId()
end
--endregion
