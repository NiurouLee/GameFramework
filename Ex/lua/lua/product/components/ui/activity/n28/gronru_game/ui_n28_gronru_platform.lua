---@class UIN28GronruPlatform : UIController
_class("UIN28GronruPlatform", UIController)
UIN28GronruPlatform = UIN28GronruPlatform

-- 功能类型
--- @class UIN28GronruPlatformType
local UIN28GronruPlatformType =
{
    -- 1：空白页面
    -- 2：贡露的游戏"
    Album_Page_Empty = 1,
    Album_Page_Game = 2,

    -- 1：不可点击，报警
    -- 2：贡露大冒险详情界面"
    Album_Project_Alarm = 1,
    Album_Project_Adventure = 2,

    -- 1：游戏
    -- 2：社区"
    Adventure_Steam_Game = 1,
    Adventure_Steam_Community = 2,

    -- 1：发生错误提示
    -- 2：贡露大冒险
    -- 3：评测论坛"
    Adventure_Page_Error = 1,
    Adventure_Page_Entrance = 2,
    Adventure_Page_Forum = 3,

    -- 1：点赞
    -- 2：拍砖"
    Forum_Comment_Agree = 1,
    Forum_Comment_Disagree = 2,

    -- 1：短款布局
    -- 2：长款布局"
    Forum_Layout_Short = 1,
    Forum_Layout_Long = 2,
}
_enum("UIN28GronruPlatformType", UIN28GronruPlatformType)

--
function UIN28GronruPlatform:Constructor()

end

--
function UIN28GronruPlatform:LoadDataOnEnter(TT, res, uiParams)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign.New()
    self._campaign:LoadCampaignInfo(
            TT,
            res,
            ECampaignType.CAMPAIGN_TYPE_N28_MINI_GAME,
            ECampaignN28MiniGameComponentID.ECAMPAIGN_BOUNCE_MISSION)

    ---@type CCampaignN28MiniGame
    self._localProcess = self._campaign:GetLocalProcess()
    if not self._localProcess then
        return
    end

    self._campaign:ReLoadCampaignInfo_Force(TT, res)
end

--
function UIN28GronruPlatform:OnShow(uiParams)
    self._arrowPage = self:GetUIComponent("Image", "arrowPage")
    self._arrowProject = self:GetUIComponent("Image", "arrowProject")
    self._txtBrowserPage = self:GetUIComponent("UILocalizationText", "txtBrowserPage")
    self._txtBrowserProject = self:GetUIComponent("UILocalizationText", "txtBrowserProject")

    self._uiGameAlbum = self:GetUIComponent("UISelectObjectPath", "uiGameAlbum")
    self._uiGameAdventure = self:GetUIComponent("UISelectObjectPath", "uiGameAdventure")

    self._uiWidgetAlbum = self._uiGameAlbum:SpawnObject("UIN28GronruGameAlbum")
    self._uiWidgetAdventure = self._uiGameAdventure:SpawnObject("UIN28GronruGameAdventure")

    self._animation = self:GetUIComponent("Animation", "animation")

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIN28GronruGame.spriteatlas", LoadType.SpriteAtlas)

    -- self:DetachAllEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)

    self:ShowGameAdventure()
    self:ShowGameAlbum()

    local backToAdventure = uiParams[1]
    if backToAdventure then
        self:ShowGameAdventure()
    end
end

--
function UIN28GronruPlatform:OnHide()

end

function UIN28GronruPlatform:BtnCloseOnClick(go)
    self:SwitchState(UIStateType.UIMain)
end

function UIN28GronruPlatform:BtnReturnOnClick(go)
    self:ShowGameAlbum()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BounceFolder)
end

function UIN28GronruPlatform:OnActivityCloseEvent(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN28GronruPlatform:ShowGameAlbum()
    self._uiGameAlbum:Engine().gameObject:SetActive(true)
    self._uiGameAdventure:Engine().gameObject:SetActive(false)

    self._uiWidgetAlbum = self._uiGameAlbum:SpawnObject("UIN28GronruGameAlbum")
    self._uiWidgetAlbum:Flush()
end

function UIN28GronruPlatform:ShowGameAdventure()
    self._uiGameAlbum:Engine().gameObject:SetActive(false)
    self._uiGameAdventure:Engine().gameObject:SetActive(true)

    self._uiWidgetAdventure = self._uiGameAdventure:SpawnObject("UIN28GronruGameAdventure")
    self._uiWidgetAdventure:Flush()
end

function UIN28GronruPlatform:BrowserPath(isPage, txtPathName)
    if isPage then
        self._arrowPage.gameObject:SetActive(txtPathName ~= nil)
        self._txtBrowserPage.gameObject:SetActive(txtPathName ~= nil)

        if txtPathName ~= nil then
            self._txtBrowserPage:SetText(txtPathName)
        end
    else
        self._arrowProject.gameObject:SetActive(txtPathName ~= nil)
        self._txtBrowserProject.gameObject:SetActive(txtPathName ~= nil)

        if txtPathName ~= nil then
            self._txtBrowserProject:SetText(txtPathName)
        end
    end
end

---@return UnityEngine.U2D.SpriteAtlas
function UIN28GronruPlatform:GetSpriteAtlas()
    return self._atlas
end

function UIN28GronruPlatform:GetDefaultProject()
    return self._uiWidgetAlbum:GetDefaultProject()
end

function UIN28GronruPlatform:GetMissionComponent()
    return self._localProcess:GetComponent(ECampaignN28MiniGameComponentID.ECAMPAIGN_BOUNCE_MISSION)
end

function UIN28GronruPlatform:PlayAnimation(animName, duration, cbComplete)
    local lockName = "UIN28GronruPlatform:PlayAnimation_" .. animName

    TaskManager:GetInstance():StartTask(function(TT)
        self:Lock(lockName)

        self._animation:Play(animName)
        YIELD(TT, duration)

        self:UnLock(lockName)

        if cbComplete then
            cbComplete()
        end
    end)
end