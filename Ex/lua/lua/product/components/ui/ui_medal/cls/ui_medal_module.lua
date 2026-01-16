---@class UIMedalModule:UIModule
_class("UIMedalModule", UIModule)
UIMedalModule = UIMedalModule

--勋章是否new
---@return boolean
function UIMedalModule:IsMedalNew()
    local unLock = GameGlobal.GetModule(RoleModule):CheckModuleUnlock(GameModuleID.MD_MEDAL)
    if not unLock then
        return false
    end

    local itemModule = GameGlobal.GetModule(ItemModule)
    return itemModule:HasNewSubTypeItem(ItemSubType.ItemSubType_Medal)
end

--勋章板是否new
---@return boolean
function UIMedalModule:IsMedalBoardNew()
    local unLock = GameGlobal.GetModule(RoleModule):CheckModuleUnlock(GameModuleID.MD_MEDAL)
    if not unLock then
        return false
    end
    
    local itemModule = GameGlobal.GetModule(ItemModule)
    return itemModule:HasNewSubTypeItem(ItemSubType.ItemSubType_Medal_Board)
end