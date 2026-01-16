---@class HomelandSceneEffect:Object
_class("HomelandSceneEffect", Object)
HomelandSceneEffect = HomelandSceneEffect
--添加这个类，是因为客户端表现和逻辑耦合了,HomelandClient最终在清理一次
--比如头顶气泡类属于行为类，当行为切换时，气泡类直接就消失了，一些表现无法展示，为了少改代码，所以抽出特效类
--如果特效只有loop循环就不需要处理逻辑了

---唯一id
---特效名字effectName
---3个阶段动画：in、loop、out
function HomelandSceneEffect:Constructor(ids, effectName, inAni, loopAni, outAni)
    self._Ids = ids
    self._Req = ResourceManager:GetInstance():SyncLoadAsset(effectName, LoadType.GameObject)
    if(self._Req == nil) then
        Log.error("HomelandSceneEffect SyncLoadAsset error ",effectName)
    end
    self._Obj = self._Req.Obj
    self._visible = false
    self._Obj:SetActive(self._visible)

    self._InAni = inAni
    self._LoopAni = loopAni
    self._OutAni = outAni   

    --self._EftAni = self._Obj:GetComponent(typeof(UnityEngine.Animation))
    self._EftAni = self._Obj:GetComponent("Animation")

    self._InTimer = nil
    self._LoopTimer = nil
    self._OutTimer = nil
end

---特效缩放
function HomelandSceneEffect:SetScale(value)
    self._Obj.transform.localScale = value
end

---
function HomelandSceneEffect:SetVisible(value)
    if self._visible == value then
        return
    end

    self._visible = value
    self._Obj:SetActive(self._visible)
end

---
function HomelandSceneEffect:UpdatePosRota(pos, rota)
    if self._visible == false then
        return
    end

    self._Obj.transform.position = pos
    self._Obj.transform.rotation = rota
end

---
function HomelandSceneEffect:SetPos(pos)
    self._Obj.transform.position = pos
end
---
function HomelandSceneEffect:SetRota(rota)
    self._Obj.transform.rotation = rota
end

--开始播放
function HomelandSceneEffect:Execute()
    self:SetVisible(true)

    self:PlayIn()
end

--退出播放
function HomelandSceneEffect:Exit()
    if self:PlayOut() == false then
        self:KillSelf()
    end
end

--生命结束，预备删除
function HomelandSceneEffect:KillSelf()
    local homeModule = GameGlobal.GetUIModule(HomelandModule)
    local homeClient = homeModule:GetClient()
    local effMng = homeClient:GetHomelandSceneEffectManager()
    effMng:DeletEffect(self._Ids)
end

--强制销毁，退场景主动调用，或者生命周期彻底结束自行调用
function HomelandSceneEffect:Dispose()

    if self._InTimer ~= nil then
        GameGlobal.Timer():CancelEvent(self._InTimer)
    end
    if self._LoopTimer ~= nil then
        GameGlobal.Timer():CancelEvent(self._LoopTimer)
    end
    if self._OutTimer ~= nil then
        GameGlobal.Timer():CancelEvent(self._OutTimer)
    end

    if self._Req ~= nil then
        self._Obj:SetActive(false)
        self._Req:Dispose()
    end   

    self._visible = false
    self._Obj = nil
    self._Req = nil
end

--
function HomelandSceneEffect:PlayIn()
    if self._EftAni ~= nil and self._InAni ~= nil and self._InAni ~= "" then
        if self._EftAni:Play(self._InAni) == true then
            local tt = self._EftAni:GetClip(self._InAni).length*1000
            self._InTimer = GameGlobal.Timer():AddEvent( tt, function() 
                self._InTimer = nil
                self:PlayLoop() end)
        end
    end
end

--
function HomelandSceneEffect:PlayLoop()
    if self._EftAni ~= nil and self._LoopAni ~= nil and self._LoopAni ~= "" then
        if self._EftAni:Play(self._LoopAni) == true then
            local tt = self._EftAni:GetClip(self._LoopAni).length*1000
            self._LoopTimer = GameGlobal.Timer():AddEvent( tt, function() 
            self._LoopTimer = nil end)
        end
    end
end

--如果退出气泡时间比较久，且需要有坐标变化，这里需要处理下，使用AddEvent自循环即可，暂时没有需求也没时间写了
function HomelandSceneEffect:PlayOut()
    if self._EftAni == nil then
        return false
    end

    if self._OutAni ~= nil and self._OutAni ~= "" then
        if self._EftAni:Play(self._OutAni) == true then
            local tt = self._EftAni:GetClip(self._OutAni).length*1000
            self._OutTimer = GameGlobal.Timer():AddEvent( tt, function() 
                self._OutTimer = nil
                self:KillSelf() end)

            return true
        end
    end

    self._EftAni:Stop()
    return false
end