--[[------------------------------------------------------------------------------------------
    LegacyAnimationComponent : 老式动画控制组件
]]--------------------------------------------------------------------------------------------

---@class LegacyAnimationComponent: Object
_class( "LegacyAnimationComponent", Object )

function LegacyAnimationComponent:Constructor(animNameList)
    ---以传进来的顺序播放
    self._animNameList = animNameList
end

function LegacyAnimationComponent:GetLegacyAnimationList()
    return self._animNameList
end

function LegacyAnimationComponent:SetLegacyAnimationList(animList)
    self._animNameList = animList
end

---这个成员不能放到构造里，可能会导致
function LegacyAnimationComponent:SetU3DAnimationCmpt(u3dAnimCmpt)
    self._u3dAnimCmpt = u3dAnimCmpt
end

function LegacyAnimationComponent:GetU3DAnimationCmpt()
    return self._u3dAnimCmpt
end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function LegacyAnimationComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function LegacyAnimationComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return LegacyAnimationComponent
function Entity:LegacyAnimation()
    return self:GetComponent(self.WEComponentsEnum.LegacyAnimation)
end


function Entity:HasLegacyAnimation()
    return self:HasComponent(self.WEComponentsEnum.LegacyAnimation)
end


function Entity:AddLegacyAnimation(animNameList)
    local index = self.WEComponentsEnum.LegacyAnimation;
    local component = LegacyAnimationComponent:New(animNameList)
    ---@type ViewComponent
    local viewCmpt = self:View()
    if viewCmpt then
        ---@type UnityViewWrapper
        local viewWrapper = viewCmpt.ViewWrapper
        if  viewWrapper.GameObject then
            local gameObject = viewWrapper.GameObject
            if gameObject.transform.position.y==  BattleConst.CacheHeight   then
                if #animNameList > 1 then
                    for _, v in ipairs(animNameList) do
                        if v ~="OffScreenNormal" then
                             Log.exception("位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..v, Log.traceback())
                        end
                    end
                else
                    local curAnim = animNameList[1]
                    if curAnim~="OffScreenNormal" then
                        Log.exception("位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..curAnim, Log.traceback())
                    end
                end
            end
        end
    end
    self:AddComponent(index, component)
end


function Entity:ReplaceLegacyAnimation(animNameList)
    local index = self.WEComponentsEnum.LegacyAnimation;
    ---@type LegacyAnimationComponent
    local component = self:LegacyAnimation()
    component:SetLegacyAnimationList(animNameList)
    self:ReplaceComponent(index, component)

    ---@type ViewComponent
    local viewCmpt = self:View()
    if viewCmpt then 
        ---@type UnityViewWrapper
        local viewWrapper = viewCmpt.ViewWrapper
        if   viewWrapper.GameObject then 
            local gameObject = viewWrapper.GameObject
            if gameObject.transform.position.y==  BattleConst.CacheHeight   then
                if #animNameList > 1 then
                    for _, v in ipairs(animNameList) do
                        if v ~="OffScreenNormal" then
                            Log.exception("位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..v, Log.traceback())
                        end
                    end
                else
                    local curAnim = animNameList[1]
                    if curAnim~="OffScreenNormal" then
                        Log.exception("位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..curAnim, Log.traceback())
                    end
                end
            end
        end
    end
end


function Entity:RemoveLegacyAnimation()
    if self:HasLegacyAnimation() then
        self:RemoveComponent(self.WEComponentsEnum.LegacyAnimation)
    end
end