--小游戏输入模块，包括键盘输入
---@class UIBounceInput : UICustomWidget
_class("UIBounceInput", UICustomWidget)
UIBounceInput = UIBounceInput

--初始化
function UIBounceInput:OnShow(uiParams)
    self:InitWidget()
  
end

--获取ui组件
function UIBounceInput:InitWidget()
    self._atlas = self:GetAsset("UIN28MinigameIn.spriteatlas", LoadType.SpriteAtlas)
    --输入控制
    self._Input = GameGlobal.EngineInput()
    local btnGO = self:GetGameObject("JumpBtn")
    self._jumpImg = btnGO:GetComponent(typeof(UnityEngine.UI.Image))
    local etl = UICustomUIEventListener.Get(btnGO)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            if self._jumpCall then 
                self._jumpCall()
            end 
        end
    ) 

    btnGO = self:GetGameObject("AttackBtn")
    self._attackImg = btnGO:GetComponent(typeof(UnityEngine.UI.Image))
    local etl = UICustomUIEventListener.Get(btnGO)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            if self._attackCall then 
                self._attackCall()
            end 
        end
    ) 
    if IsPc() or IsUnityEditor() then
        -- self._jumpImg.sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..0)
        -- self._attackImg.sprite = self._atlas:GetSprite("N28_yrj_jngq_figure0"..0)
    end 
end
--设置数据
---@param attackCall function 攻击回调
---@param jumpCall   function 跳跃回调 
function UIBounceInput:Init(attackCall, jumpCall)
    self._attackCall = attackCall
    self._jumpCall = jumpCall
end
function UIBounceInput:OnUpdate(deltaTimeMS)
    self:OnPCInputUpdate()
end

function UIBounceInput:AttackBtnOnClick()
    if self._attackCall then 
        self._attackCall()
    end 
end

function UIBounceInput:OnPCInputUpdate()
    if IsPc() or IsUnityEditor() then
        if (self._Input.GetKeyDown(UnityEngine.KeyCode.R)) then
            if self._attackCall then 
                self._attackCall(true)
            end 
        end
        if (self._Input.GetKeyDown(UnityEngine.KeyCode.T)) then
            if self._jumpCall then 
                self._jumpCall(true)
            end 
        end
    else 
       
    end 
end


