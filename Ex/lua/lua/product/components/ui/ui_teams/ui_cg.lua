---@class UICG:Object
_class("UICG", Object)
UICG = UICG

---@private
function UICG.GetResType(resName)
    local resType = UICGResType.CG
    if string.endwith(resName, "_cg") then
        resType = UICGResType.CG
    elseif string.find(resName, "_spine_") then
        resType = UICGResType.Spine
    end
    return resType
end
---@private
---设置默认值
function UICG.SetDefaultValue(tran)
    if not tran then
        return
    end
    tran.anchoredPosition = Vector2.zero
    tran.localScale = Vector3.one
end

---@public
---@param tran Transform 要设置位置的结点
---@param uiName string 界面名
---@param resName string 资源名
function UICG.SetTransform(tran, uiName, resName, cfgGroupIndex)
    cfgGroupIndex = cfgGroupIndex or 1
    --设置Transform
    local cfg = Cfg.pet_cg_transform {ResName = resName, UIName = uiName}
    if not cfg then
        UICG.SetDefaultValue(tran)
        return
    end
    local v = cfg[1]
    if not v then
        UICG.SetDefaultValue(tran)
        return
    end
    local resType = UICG.GetResType(resName)
    local transform = nil
    if resType == UICGResType.CG then
        transform = v.CGTransform
    elseif resType == UICGResType.Spine then
        transform = v.SpineTransform
    else
        Log.fatal("### UICG unknown resType:", resName, uiName)
    end
    if not transform then
        UICG.SetDefaultValue(tran)
        return
    end
    local startIndex = (cfgGroupIndex - 1) * 5
    local posX, posY, scale, width, height =
        transform[startIndex + 1],
        transform[startIndex + 2],
        transform[startIndex + 3],
        transform[startIndex + 4],
        transform[startIndex + 5]
    tran.anchoredPosition = Vector2(posX, posY)
    tran.localScale = Vector3(scale, scale, scale)
    if width and height then
        tran.sizeDelta = Vector2(width, height)
    end
end

--- @class UICGResType
local UICGResType = {
    CG = 0, --立绘
    Spine = 1 --spine
}
_enum("UICGResType", UICGResType)
