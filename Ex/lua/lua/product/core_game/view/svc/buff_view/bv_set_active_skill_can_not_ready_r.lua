--[[
    设置主动技不能使用 --sp巴顿 主动技为能量体系，但释放后即使能量充足也需要禁用
]]
_class("BuffViewSetActiveSkillCanNotReady", BuffViewBase)
---@class BuffViewSetActiveSkillCanNotReady : BuffViewBase
BuffViewSetActiveSkillCanNotReady = BuffViewSetActiveSkillCanNotReady

function BuffViewSetActiveSkillCanNotReady:PlayView(TT)
    ---@type BuffResultSetActiveSkillCanNotReady
    local res = self._buffResult
    local buffseq = res:GetBuffSeq()
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffseq)
    if not viewInstance then
        Log.error(self._className, "no viewInstance! entity=", self._entity:GetID())
        return
    end

    if self._entity:HasPetPstID() then
        local extraSkillID = res:GetExtraSkillID()
        local petPstID = self._entity:PetPstID():GetPstID()
        
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.SetActiveSkillCanNotReady,
            petPstID,
            res:IsCanNotReady(),
            buffseq,
            extraSkillID
        )
        local ready = res:IsReady()
        --可以释放
        if ready then
            if extraSkillID then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillGetReady, petPstID,extraSkillID, ready)
            else
                GameGlobal.EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, ready)
            end
        else
            if extraSkillID then
                GameGlobal:EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillCancelReady, petPstID,extraSkillID,0)
            else
                GameGlobal:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, petPstID,0)
            end
        end
    end
end
_class("BuffViewResetActiveSkillCanNotReady", BuffViewSetActiveSkillCanNotReady)
---@class BuffViewResetActiveSkillCanNotReady : BuffViewSetActiveSkillCanNotReady
BuffViewResetActiveSkillCanNotReady = BuffViewResetActiveSkillCanNotReady