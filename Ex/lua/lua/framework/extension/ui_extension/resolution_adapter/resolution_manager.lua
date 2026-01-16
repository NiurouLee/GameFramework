--[[------------------------------------------------------------------------------------------
**********************************************************************************************
分辨率适配管理器
关于刘海：
1、优先UI设置的刘海宽
2、其次使用配置的刘海范围(默认)
3、最后使用Unity提供的接口

关于锚点：
AnchorAreaPanel.cs
1、默认按设计的最大宽高比和最小宽高比来锚，保证锚点不在黑边中
2、如果黑边小于正在调整的刘海宽，使用安全区来锚
SafeAreaPanel.cs
1、使用安全区来锚

**********************************************************************************************
]] --------------------------------------------------------------------------------------------

local openSafeWide = true
--刘海适配开关
local openFitMaxWidthHeight = true
--最大宽高适配开关

local PIXELSIZE_BASEHEIGHT = 1080 -- 基准高
local PIXELSIZE_BASEWIDTH = 1920 -- 基准宽

--每个项目都需要定最大宽高比和最小宽高比，由此换算出底图范围和锚点位置
local MAX_WIDTH_HEIGHT_RATIO_W = 2539 --最大宽高比的宽
local MAX_WIDTH_HEIGHT_RATIO_H = 1080 --最大宽高比的高
local MIN_WIDTH_HEIGHT_RATIO_W = 2732 --最小宽高比的宽
local MIN_WIDTH_HEIGHT_RATIO_H = 2048 --最小宽高比的高

--无黑边时的AnchorInfo值
local FULL_SCREEN_ANCHOR_INFO = Vector4(0, 0, 1, 1)

---@class ResolutionType
_enum(
    "ResolutionType",
    {
        Normal = "Normal",
        SafeWide = "SafeWide"
    }
)

---@class ResolutionManager:Object
_class("ResolutionManager", Object)
ResolutionManager = ResolutionManager

local BANG_WIDTH_KEY = "BangWidthKey"
local BANG_WIDTH_REGISTERED_KEY = "IsBangWidthRegisteredKey"

local NO_CASE = string.nocase
local SCREEN = UnityEngine.Screen
local EQUAL_IGNORE_CASE = string.equal_with_ignorecase

local SCREEN_STANDARDRATE = PIXELSIZE_BASEWIDTH / PIXELSIZE_BASEHEIGHT -- 基准比例
local ANCHOR_MAX_WIDTH = MAX_WIDTH_HEIGHT_RATIO_W * (PIXELSIZE_BASEHEIGHT / MAX_WIDTH_HEIGHT_RATIO_H)
local ANCHOR_MAX_HEIGHT = MIN_WIDTH_HEIGHT_RATIO_H * (PIXELSIZE_BASEWIDTH / MIN_WIDTH_HEIGHT_RATIO_W)
local FIX_SAFEAREA_ANDROID_KEY = "FixSafeareaAndroidKey"
local MAX_SCREEN_CHANGE_SCALE = 1

local RuntimePlatform = UnityEngine.RuntimePlatform
function ResolutionManager:Constructor()
    -- --测试代码
    -- LocalDB.Delete(BANG_WIDTH_KEY)
    -- LocalDB.Delete(BANG_WIDTH_REGISTERED_KEY)
    Log.debug(
        "[UIResolution] unity safearea:",
        SCREEN.safeArea,
        ", unity screen width:",
        SCREEN.width,
        ", height:",
        SCREEN.height
    )

    self.data = nil
    self.bOpenSafeWide = false -- 是否开启刘海屏适配
    self.bSafeWide = false -- 是否是刘海屏
    self.safeWideWidthByConfig = 0 -- 配置的刘海屏的安全区域

    -- 超过支持分辨率后的强制黑边宽高
    self.blackWidth = 0
    self.blackHeight = 0
    self.permanentBlackSides = nil
    self.blackSideLeftRectTrans = nil 
    self.blackSideRightRectTrans = nil
    self.blackSideTopRectTrans = nil
    self.blackSideBottomRectTrans = nil
end

--初始化时调用
--安卓折叠屏手机分辨率变化时调用
function ResolutionManager.CalculateBlack(self)
    if not _G.APPVER1220 then
        --ResolutionManager.CalculateUIResolution()
        --GameGlobal.EventDispatcher():Dispatch(GameEventType.UIBlackChange)
        --return
    end
    ---@type ResolutionManager
    self = self or GameGlobal.ResolutionManager()
    if openFitMaxWidthHeight then
        local blackWidth = math.ceil((ResolutionManager.RealWidth() - ANCHOR_MAX_WIDTH) * 0.5)
        --blackWidth = 400 --强制设置黑边
        if blackWidth < 0 then
            blackWidth = 0
        end
        self.blackWidth = blackWidth
        local blackHeight = math.ceil((ResolutionManager.RealHeight() - ANCHOR_MAX_HEIGHT) * 0.5)
        if blackHeight < 0 then
            blackHeight = 0
        end
        self.blackHeight = blackHeight
        
        self:RefreshPermanentBlackSides()
        
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIBlackChange)
    end
end

function ResolutionManager:Init()
    ResolutionManager.CalculateBlack(self) --计算黑边放在构造函数之后

    Log.debug(
        "[UIResolution]realWidth=",
        ResolutionManager.RealWidth(),
        " realHeight=",
        ResolutionManager.RealHeight(),
        ",openFitMaxWidthHeight=",
        openFitMaxWidthHeight,
        ",blackWidth=",
        self.blackWidth,
        ",blackHeight=",
        self.blackHeight
    )

    self.data = Cfg.cfg_device_safe_area()
    self:SetResolution()
end

---@param uiRootGameObject UnityEngine.GameObject
function ResolutionManager:InitAfterUI(uiRootGameObject)
    local permanentBlackSidesTrans = uiRootGameObject.transform:Find("UICameras/depth_top/UI/TopPanel/PermanentBlackSides")
    self.permanentBlackSides = permanentBlackSidesTrans.gameObject
    self.blackSideLeftRectTrans = permanentBlackSidesTrans:GetChild(0)
    self.blackSideRightRectTrans = permanentBlackSidesTrans:GetChild(1)
    self.blackSideTopRectTrans = permanentBlackSidesTrans:GetChild(2)
    self.blackSideBottomRectTrans = permanentBlackSidesTrans:GetChild(3)
    
    self:RefreshPermanentBlackSides()
end

function ResolutionManager.CalculateUIResolution()
    self = self or GameGlobal.ResolutionManager()
    local vector2 = Vector2(SCREEN.width, SCREEN.height)
    local scaleFactor = 0
    scaleFactor = Mathf.Min(vector2.x / PIXELSIZE_BASEWIDTH, vector2.y / PIXELSIZE_BASEHEIGHT)
    --canvasscaler在expand模式下计算出来canvas的像素尺寸
    local sizeDelta = Vector2(SCREEN.width / scaleFactor, SCREEN.height / scaleFactor)
    local info = ResolutionManager.GeAnchorInfo(-1)
    local blackW = (info.x * sizeDelta.x) * 2

    local w = 0
    if sizeDelta.x - blackW < PIXELSIZE_BASEWIDTH then
        w = PIXELSIZE_BASEWIDTH + blackW
    else
        w = sizeDelta.x
    end
    --正常情况下canvas在窄屏下宽度是1920,但带黑边的窄屏需要特殊适配,将宽度拉宽
    self.canvasRefrenceWidth = w
    Log.info("[Resolution] Canvas默认宽度:", w)
end

function ResolutionManager:RefreshPermanentBlackSides()
    if not self.permanentBlackSides then
        return
    end

    if self.blackWidth == 0 and self.blackHeight == 0 then
        if _G.APPVER1220 then
            self.permanentBlackSides:SetActive(false)
        else
            self.permanentBlackSides:SetActive(true)
        end
    else
        self.permanentBlackSides:SetActive(true)
        self.blackSideLeftRectTrans.sizeDelta = Vector2(self.blackWidth, 0)
        self.blackSideRightRectTrans.sizeDelta = Vector2(self.blackWidth, 0)
        self.blackSideTopRectTrans.sizeDelta = Vector2(0, self.blackHeight)
        self.blackSideBottomRectTrans.sizeDelta = Vector2(0, self.blackHeight)
    end
end 

--region 接口
function ResolutionManager.InvokeBangWidthChangedListeners(uiBangWidth)
    UIHelper.InvokeBangWidthChangeListeners(uiBangWidth)
end
function ResolutionManager.BangWidthLocalDBKey()
    return BANG_WIDTH_KEY, BANG_WIDTH_REGISTERED_KEY
end

---通过设计的最大宽高的锚点信息
---@return Vector4
function ResolutionManager.GeFullScreenAnchorInfo()
    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()
    local blackWidth = ResolutionManager.BlackWidth()
    local blackHeight = ResolutionManager.BlackHeight()

    local minY = blackHeight / realHeight
    local MaxY = 1 - minY
    local minX = blackWidth / realWidth
    local MaxX = 1 - minX

    local vec4 = Vector4(minX, minY, MaxX, MaxY)

    local depth_top = UnityEngine.GameObject.Find("depth_top")
    if depth_top then
        local depth_topTran = depth_top.transform
        local cameraTran = depth_topTran:Find("Camera")
        if cameraTran then
            local camera = cameraTran:GetComponent("Camera")
            if camera then
                if vec4 ~= FULL_SCREEN_ANCHOR_INFO then
                    camera.enabled = true
                else
                    camera.enabled = false
                end
            end
        end
    end

    return vec4
end

---通过安全区换算的锚点信息
---@return Vector4
function ResolutionManager.GeAnchorInfo(curBangWidth)
    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()
    local blackWidth = ResolutionManager.BlackWidth()
    local blackHeight = ResolutionManager.BlackHeight()

    local minY = blackHeight / realHeight
    local MaxY = 1 - minY

    --锚点的X值会受安全区的影响
    local bangWidth = nil
    if curBangWidth and curBangWidth >= 0 then
        --当前刘海宽
        bangWidth = curBangWidth
    else
        --最大刘海宽
        bangWidth = ResolutionManager.BangWidth()
    end
    local vec4 = nil
    if bangWidth < blackWidth then --用黑边锚
        --用黑边锚
        local minX = blackWidth / realWidth
        local MaxX = 1 - minX
        vec4 = Vector4(minX, minY, MaxX, MaxY)
    else --用安全区锚
        vec4 = ResolutionManager.GeAnchorInfoBySafeArea(curBangWidth)
        vec4.y = minY
        vec4.w = MaxY
    end

    local depth_top = UnityEngine.GameObject.Find("depth_top")
    if depth_top then
        local depth_topTran = depth_top.transform
        local cameraTran = depth_topTran:Find("Camera")
        if cameraTran then
            local camera = cameraTran:GetComponent("Camera")
            if camera then
                if vec4 ~= FULL_SCREEN_ANCHOR_INFO then
                    camera.enabled = true
                else
                    camera.enabled = false
                end
            end
        end
    end

    return vec4
end

---通过安全区换算的锚点信息
---@return Vector4
function ResolutionManager.GeAnchorInfoBySafeArea(uiBangWidth)
    local x, y, w, h
    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()

    local bangWidth, byEngine
    if uiBangWidth and uiBangWidth >= 0 then
        bangWidth = uiBangWidth
    else
        bangWidth, byEngine = ResolutionManager.BangWidth()
    end
    if byEngine then
        if PLATFORM == RuntimePlatform.Android then --Android then --Android和Ios SCREEN.safeArea返回的值含义不一样
            realWidth = ResolutionManager.RealWidth()
            realHeight = ResolutionManager.RealHeight()
            x = bangWidth
            y = 0
            w = realWidth - x * 2
            h = realHeight
        else
            realWidth = ResolutionManager.ScreenWidth()
            realHeight = ResolutionManager.ScreenHeight()
            local safeArea = SCREEN.safeArea
            x = safeArea.x
            y = 0
            w = safeArea.width
            h = realHeight
        end
    else
        if bangWidth >= 0 then
            x, y, w, h = ResolutionManager.GetSafeAreaByBang(bangWidth)
        end
    end

    local vec4 = ResolutionManager.GeAnchorInfoBySafeAreaInternal(x, y, w, h, realWidth, realHeight)
    return vec4
end

---刘海宽
function ResolutionManager.BangWidth()
    ---保护措施 修复旧底包异常
    local isBangWidthRegistered = LocalDB.GetInt(BANG_WIDTH_REGISTERED_KEY)
    if isBangWidthRegistered > 0 then
        local w = LocalDB.GetInt(BANG_WIDTH_KEY)
        if w > 100 then
            w = 100
            Log.debug("[fx] w >100 old pakge reset")
            LocalDB.SetInt(BANG_WIDTH_KEY,100)
        end
    end

    if ResolutionManager.TheResolutionType() ~= ResolutionType.SafeWide then
        return 0
    end
      
    if not _G.APPVER1220 then
        --[[local isBangWidthRegistered = LocalDB.GetInt(BANG_WIDTH_REGISTERED_KEY)
        if isBangWidthRegistered > 0 then
            local w = LocalDB.GetInt(BANG_WIDTH_KEY)
            return w
        end]]--
    end

    if not ResolutionManager.SafeAreaExist() then
        return 0
    end

    --优先UI设置的刘海宽
    if isBangWidthRegistered > 0 then
        local w = LocalDB.GetInt(BANG_WIDTH_KEY)
        local bangCanvasPixel = ResolutionManager.GetBangCanvasPixelWidthByPercent(w / 100)
        
        if bangCanvasPixel > ResolutionManager.ConfigBangWidth() then
            Log.debug("bangCanvasPixel2",bangCanvasPixel,"ConfigBangWidth",ResolutionManager.ConfigBangWidth())
            return ResolutionManager.ConfigBangWidth()
        end
        Log.debug("[UIResolution]Get Bang from Local DB ", w, " canvas pixel width ", bangCanvasPixel)
        return bangCanvasPixel
    end
    return ResolutionManager.ConfigBangWidth()
end

function ResolutionManager.GetBangCanvasPixelWidthByPercent(percent)    
    return ResolutionManager.ConfigBangWidth() * percent
end

---宽高比低于16:9不进行安全区适配，否则会导致很多界面适配出现问题(即UI内容宽度不可小于1920)
function ResolutionManager.SafeAreaExist()
    --计算刘海比例最大时距离是否小于黑边距离，如果仍小于 没有滑动操作黑边距离的必要。
    local lessBlack = ResolutionManager.CheckSafeWidthLessBlackWidth()
    if lessBlack then
        return false
    end
    return SCREEN.safeArea.width < SCREEN.width and SCREEN.width / SCREEN.height > SCREEN_STANDARDRATE
end

--检测刘海距离缩放是否小于黑边距离。如果刘海最大距离仍然小于黑边距离则禁止玩家调整黑边距离
function ResolutionManager.CheckSafeWidthLessBlackWidth()
    if ResolutionManager.TheResolutionType() ~= ResolutionType.SafeWide then
        return false
    end

    local maxBangWidth = ResolutionManager.GetBangCanvasPixelWidthByPercent(1)
    local blackWidth = ResolutionManager.BlackWidth()
    if maxBangWidth <= blackWidth then
        return true
    end

    return false
end

function ResolutionManager.ConfigBangWidth()

    if not _G.APPVER1220 then
        --return ResolutionManager.OldConfigBangWidth()
    end

    local res = 0
    if SCREEN.width / SCREEN.height <= SCREEN_STANDARDRATE then
        return res, true
    end

    local screenWidth = SCREEN.width
    local rate = ResolutionManager.RealWidth() / screenWidth

    local width =SCREEN.safeArea.width 
    ---用于修正unitybug 某些刘海屏初始化时 保护区域数值不正确
    width = ResolutionManager.FixSafeAreaWidth()
    local w = (screenWidth - width) * rate
    

    if w > 0 then
        if PLATFORM == RuntimePlatform.IPhonePlayer then
            res = w * 0.5
        else
            res = w
        end
    end

    Log.debug("[UIResolution]Get Bang from Unity ", res)
    return res, true
end

function ResolutionManager.OldConfigBangWidth()
    --其次配置的刘海宽,最后使用Unity提供的刘海宽
    local byEngine = false
    local realWidth = ResolutionManager.RealWidth()
    local safeWidth = ResolutionManager.SafeWideWidth()
    local res = 0
    local w = 0
    if safeWidth <= 0 then --使用引擎
        byEngine = true
        safeWidth = SCREEN.safeArea.width
        if PLATFORM == RuntimePlatform.Android then
            local screenWidth = ResolutionManager.ScreenWidth()
            local rate = realWidth / screenWidth
            w = (screenWidth - safeWidth) * rate
        else
            realWidth = ResolutionManager.ScreenWidth()
            w = realWidth - safeWidth
        end
    else
        w = realWidth - safeWidth
    end

    if w > 0 then
        if PLATFORM == RuntimePlatform.Android and byEngine then --Android系统返回有区别
            res = w
        else --iOS系统返回和我们的配置处理一致
            res = w * 0.5 * (ResolutionManager.RealWidth() / realWidth)
        end
    end

    if byEngine then
        Log.debug("[UIResolution]Get Bang from Unity ", res)
    else
        Log.debug("[UIResolution]Get Bang from Our Config ", res)
    end

    return res, byEngine
end

---@return float
function ResolutionManager.FixSafeAreaWidth()
    ---如果不是安卓忽略修正逻辑
    if not IsAndroid() then
        return SCREEN.safeArea.width 
    end
    ---如果没有刘海屏保护忽略修正逻辑
    if not SCREEN.safeArea.x == 0 then
        return SCREEN.safeArea.width 
    end

    local localscale = LocalDB.GetFloat(FIX_SAFEAREA_ANDROID_KEY)
    if localscale ==nil or localscale ==0 then
        localscale = SCREEN.safeArea.width/SCREEN.safeArea.height
        LocalDB.SetFloat(FIX_SAFEAREA_ANDROID_KEY,localscale)
    end
 
   
    if localscale ~=nil then
        local curScale =  SCREEN.safeArea.width/SCREEN.safeArea.height
        if curScale ~= localscale then
            if math.abs(curScale - localscale)>MAX_SCREEN_CHANGE_SCALE then
                return SCREEN.safeArea.width 
            end
            return SCREEN.safeArea.height * localscale
        end
    end
    return SCREEN.safeArea.width 
end

--canvas宽度
function ResolutionManager.RealWidth()
    local screenRate = ResolutionManager.ScreenWidth() / ResolutionManager.ScreenHeight()
    if screenRate > SCREEN_STANDARDRATE then --更宽的屏 高固定
        return PIXELSIZE_BASEHEIGHT * screenRate
    else -- 更窄的屏 宽固定
        return PIXELSIZE_BASEWIDTH
    end
end
--[[
function ResolutionManager.CanvasWidth()
    return GameGlobal.ResolutionManager().canvasRefrenceWidth
end]]

--canvas高度
function ResolutionManager.RealHeight()
    local screenRate = ResolutionManager.ScreenWidth() / ResolutionManager.ScreenHeight()
    if screenRate >= SCREEN_STANDARDRATE then --更宽的屏 高固定
        return PIXELSIZE_BASEHEIGHT
    else --更窄的屏 宽固定
        return PIXELSIZE_BASEWIDTH / screenRate
    end
end
---画面输出的分辨率宽
function ResolutionManager.ScreenWidth()
    return SCREEN.width
end

---画面输出的分辨率高
function ResolutionManager.ScreenHeight()
    return SCREEN.height
end

function ResolutionManager.BlackWidth()
    return GameGlobal.ResolutionManager().blackWidth
end
function ResolutionManager.BlackHeight()
    return GameGlobal.ResolutionManager().blackHeight
end

function ResolutionManager.BaseWidth()
    return PIXELSIZE_BASEWIDTH
end
function ResolutionManager.BaseHeight()
    return PIXELSIZE_BASEHEIGHT
end

--endregion

--region Private
---@private
---获得安全区域宽度
function ResolutionManager.SafeWideWidth()
    local resolutionMng = GameGlobal.ResolutionManager()
    if resolutionMng.bOpenSafeWide then
        if resolutionMng.bSafeWide then
            Log.debug("[UIResolution]current device is safewide type！")
        end
    else
        Log.debug("[UIResolution]safewide type is not open！")
    end
    return resolutionMng.safeWideWidthByConfig
end

---@private
function ResolutionManager:SetResolution()
    if openSafeWide then
        local deviceModel = UIHelper.GetDeviceModel()
        Log.debug("[UIResolution]ResolutionManager:SetResolution, ", deviceModel)

        local nowSafeAreaWidth = -1
        for deviceName, device in next, self.data do
            if EQUAL_IGNORE_CASE(deviceName, deviceModel) then
                nowSafeAreaWidth = device.safeWidth
                break
            end
        end
        if nowSafeAreaWidth ~= -1 then
            Log.debug("[UIResolution]ResolutionManager:SetResolution, nowSafeAreaWidth ", nowSafeAreaWidth)
            self:SetDeviceReslutionInfo(true, nowSafeAreaWidth, true)
        else
            self:SetDeviceReslutionInfo(true, 0, false)
        end
    else
        self:SetDeviceReslutionInfo(false, 0, false)
    end
end

---@private
function ResolutionManager:SetDeviceReslutionInfo(bOpenSafeWide, safeWideWidth, bSafeWide)
    Log.debug(
        "[UIResolution]ResolutionManager:SetDeviceReslutionInfo, bOpenSafeWide= ",
        bOpenSafeWide,
        ", safeWideWidth= ",
        safeWideWidth,
        ", bSafeWide= ",
        bSafeWide
    )
    self.bOpenSafeWide = bOpenSafeWide
    self.safeWideWidthByConfig = safeWideWidth
    self.bSafeWide = bSafeWide
end

---@private
---@return ResolutionType
function ResolutionManager.TheResolutionType()
    local resolutionMng = GameGlobal.ResolutionManager()
    if resolutionMng.bOpenSafeWide then
        return ResolutionType.SafeWide
    else
        return ResolutionType.Normal
    end
end

--基于真实分辨率
---@private
function ResolutionManager.GetSafeAreaByBang(bangWidth)
    -- Log.error("ResolutionManager.GetSafeAreaByBang ",bangWidth)
    local x, y, w, h = 0
    local insets = bangWidth
    if SCREEN.width > SCREEN.height then
        x = insets
        y = 0
    else
        x = 0
        y = insets
    end

    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()

    w = realWidth - x * 2
    h = realHeight - y * 2
    return x, y, w, h
end

---@private
function ResolutionManager.GeAnchorInfoBySafeAreaInternal(x, y, w, h, realWidth, realHeight)
    Log.debug(
        "[UIResolution]New safe area applied : LeftBottom x=",
        x,
        " LeftBottom y=",
        y,
        " w=",
        w,
        " h=",
        h,
        " on full extents ScreenWidth=",
        ResolutionManager.ScreenWidth(),
        " ScreenHeight=",
        ResolutionManager.ScreenHeight(),
        ",\n RealWidth=",
        realWidth,
        ", RealHeight=",
        realHeight
    )

    local anchorMinX = x / realWidth
    local anchorMinY = y / realHeight
    local anchorMaxX = (x + w) / realWidth
    local anchorMaxY = (y + h) / realHeight
    return Vector4(anchorMinX, anchorMinY, anchorMaxX, anchorMaxY)
end
--endregion

---@return boolean 当前设备分辨率是否超出支持的分辨率
function ResolutionManager.IsAspectOutofSupport()
    local aspect = ResolutionManager.ScreenWidth() / ResolutionManager.ScreenHeight()
    return aspect > MAX_WIDTH_HEIGHT_RATIO_W / MAX_WIDTH_HEIGHT_RATIO_H or
        aspect < MIN_WIDTH_HEIGHT_RATIO_W / MIN_WIDTH_HEIGHT_RATIO_H
end
