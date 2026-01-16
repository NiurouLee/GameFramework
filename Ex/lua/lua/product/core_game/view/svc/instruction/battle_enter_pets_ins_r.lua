require("base_ins_r")
---@class BattleEnterPetsInstruction: BaseInstruction
_class("BattleEnterPetsInstruction", BaseInstruction)
BattleEnterPetsInstruction = BattleEnterPetsInstruction

function BattleEnterPetsInstruction:Constructor(paramList)
    self._petShowDelay = tonumber(paramList["petShowDelay"]) --光柱特效和宝宝出现间隔

    self._interval = {} --队员出现间隔
    local strParam = paramList["interval"]
    if strParam then
        local arr = string.split(strParam, "|")
        for index, str in ipairs(arr) do
            local n = tonumber(str)
            table.insert(self._interval, n)
        end
    else
        self._interval = {0, 0, 0} --第1，第2，第3，第4两两之间间隔
    end

    self._effLightPillar = tonumber(paramList["effLightPillar"]) --光柱特效
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function BattleEnterPetsInstruction:DoInstruction(TT, casterEntity, phaseContext)
    self._world = casterEntity:GetOwnerWorld()
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    self._ePets =  teamEntity:Team():GetTeamPetEntities()
    for i, e in ipairs(self._ePets) do
        if e then
            self:PlayEffShowPet(e, teamEntity)
            if self._interval and self._interval[i] then
                YIELD(TT, self._interval[i]) --迭代间隔
            end
        end
    end
end

---@param e Entity 宝宝实体
function BattleEnterPetsInstruction:PlayEffShowPet(e, teamEntity)   
    local teamLeaderPetPstID = teamEntity:Team():GetTeamLeaderPetPstID()
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            -- 这个地方
            local petPstIDCmpt = e:PetPstID()
            if petPstIDCmpt:GetPstID() ~= teamLeaderPetPstID then
                self:PlayEffLightPillar(e)
                if self._petShowDelay then
                    YIELD(TT, self._petShowDelay) --光柱特效播放到宝宝出现之间的时长
                end
            end
            self:PlayBattlePermanentEffect(e) --播常驻特效
            e:SetViewVisible(true) --显示
        end,
        self
    )
end

---播放单个光柱特效
---@param e Entity 宝宝实体
function BattleEnterPetsInstruction:PlayEffLightPillar(e)
    if not self._effLightPillar then --如果没有配光柱，就拿宝宝第一属性对应的光柱特效
        self._effLightPillar = self:GetFirstElementEffect(e)
    end
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    sEffect:CreateEffect(self._effLightPillar, e)
end

---@param e Entity
function BattleEnterPetsInstruction:GetFirstElementEffect(e)
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    local elementType = e:Element():GetPrimaryType()
    return sEffect:GetPetShowEffIdByEntity(elementType)
end

---@param e Entity
function BattleEnterPetsInstruction:PlayBattlePermanentEffect(e)
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    local templateID = e:PetPstID():GetTemplateID()
    local cfgPet = Cfg.cfg_pet[templateID]
    local permanentFxArray = cfgPet.BattlePermanentEffect
    if permanentFxArray and #permanentFxArray > 0 then
        for _, effectID in ipairs(permanentFxArray) do
            sEffect:CreateEffect(effectID, e)
        end
    end
end

function BattleEnterPetsInstruction:GetCacheResource()
    local t = {}
    if self._effLightPillar and self._effLightPillar > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effLightPillar].ResPath, 4})
    end
    return t
end
