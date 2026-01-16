require "state"
---@class StateBouncePlayerBase : State
_class("StateBouncePlayerBase", State)
StateBouncePlayerBase = StateBouncePlayerBase

function StateBouncePlayerBase:Init()
    if not self.player then
         ---@type BouncePlayer
        self.player = self.fsm:GetData()
        ---@type BouncePlayerData
        self.playerData = self.player:GetBouncePlayerData()
        ---@type BounceData
        self.bounceData = self.player:GetBounceData()

        ---@type StateBouncePlayer
        local stateType = self:GetStateType()
        if stateType then
            self._animationCfg = Cfg.cfg_bounce_player_animation[stateType]
        end
    end
end

function StateBouncePlayerBase:GetStateType()
    return nil
end

function StateBouncePlayerBase:GetBehavior(behaviorName)
    return self.player:GetBehavior(behaviorName)
 end

function StateBouncePlayerBase:Destroy()
end

--jump cmd
function StateBouncePlayerBase:OnJump()
end

--attack cmd
function StateBouncePlayerBase:OnAttack()
end

--播放动画，并返回动画时常
---@return number
function StateBouncePlayerBase:PlayAnim()
    local aniName, duration = self:GetAniNameAndDuration()
    if not aniName then
        return 0
    end

    local animBehaviour = self.player:GetBehavior("BouncePlayerBeHaviorAnimation")
    if not animBehaviour then
        return 0
    end

   -- Log.debug("[bounce] BouncePlayer PlayAnim " .. aniName .. "  -- " .. self.bounceData.durationMs)
    animBehaviour:PlayAnimation(aniName)
    return duration
end

--获得动画名称和时常
function StateBouncePlayerBase:GetAniNameAndDuration()
    if not self._animationCfg then
        return nil
    end
    local name = self._animationCfg.Name
    if not name or name == "" then
        return nil
    end

    local duration = self._animationCfg.Duration  or 0
    return name, duration
end

--获得特效名称
function StateBouncePlayerBase:GetEffName()
    if not self._animationCfg then
        return nil
    end

    local name = self._animationCfg.Eff
    if not name or name == "" then
        return nil
    end

    return name
end

--获得碰撞区域名称
function StateBouncePlayerBase:GetRectNames()
    if not self._animationCfg then
        return nil
    end

    return self._animationCfg.BaseRect, self._animationCfg.WeaponRect
end

function StateBouncePlayerBase:ShowDebugRect()
    if not BounceDebug.ShowObjRect then
        return
    end
    if not self.player.debugRect then
        self.player.debugRect = {}
    end
    for k, v in pairs(self.player.debugRect) do
        --v.enabled = false
        v.gameObject:SetActive(false)
    end
    local baseRectName, weaponName = self:GetRectNames();
    if baseRectName then
        self:ShowDebugRectBy(baseRectName)
    end

    if weaponName then
        self:ShowDebugRectBy(weaponName, true)
    end
end

function StateBouncePlayerBase:ShowDebugRectBy(name, isWeapon)
    if not self.player.debugRect then
        self.player.debugRect = {}
    end
    local image = self.player.debugRect[name]
    if not image then
        local viewBehavior = self:GetBehavior(BouncePlayerBeHaviorView:Name())
        if not  viewBehavior then
            return
        end
        local rectRt = viewBehavior:GetBox(name)
        if not rectRt then
            return
        end
        image = rectRt.gameObject:AddComponent(typeof(UnityEngine.UI.Image))
        if image then
            if isWeapon then
                image.color = Color(1,0,0,0.4)
            else
                image.color = Color(0,1,0,0.4)
            end
        end
        self.player.debugRect[name] = image;
    else
       -- image.enabled = true
       image.gameObject:SetActive(true)
    end
end