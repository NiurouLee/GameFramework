require("base_ins_r")
---@class PlaySkillCGEffectInstruction: BaseInstruction
_class("PlaySkillCGEffectInstruction", BaseInstruction)
PlaySkillCGEffectInstruction = PlaySkillCGEffectInstruction

function PlaySkillCGEffectInstruction:Constructor(paramList)
    self._waitTime = tonumber(paramList["waitTime"])

    self._offsetPos = Vector2.zero
    self._offsetScale = 1

    --MSG45523
    --指令里配置的光灵模板id，之前没用，现在用于CacheResource
    --本方光灵通过PetModule获取对应的MatchPet数据。黑拳赛里用默认皮肤就可以。
    self._cfgPetID = tonumber(paramList["petID"])
end

---@param ePet Entity
function PlaySkillCGEffectInstruction:_InitCgData(ePet)
    local world = ePet:GetOwnerWorld()

    local cPetPstID = ePet:PetPstID()
    if not cPetPstID then
        return
    end
    local pstID = cPetPstID:GetPstID()
    self._petID = cPetPstID:GetTemplateID()

    ---@type MatchPet
    local matchPet = world.BW_WorldInfo:GetPetData(pstID)
    if not matchPet then
        Log.fatal("###[PlaySkillCGEffectInstruction]InitCgData GetPetData is nil ! id --> ", pstID)
        return
    end

    local skinId = matchPet:GetSkinId()
    local cfg = Cfg.cfg_pet_skin[skinId]
    if not cfg then
        Log.fatal("### no skinId in cfg_pet_skin. skinId=", skinId)
        return
    end
    self._effectRes = cfg.ActiveSkillEff .. ".prefab"

    local petCG = cfg.SimpleCG
    if not petCG then
        petCG = cfg.StaticBody
    end
    self._petCGMat = petCG .. ".mat"
    local logo = matchPet:GetPetLogo()
    self._petIconMat = logo .. ".mat"

    --有主动技专有配置，则读取主动技配置，否则使用结算配置
    local cfg = Cfg.pet_cg_transform {ResName = petCG, UIName = "ActiveSkill"}
    if not cfg then
        cfg = Cfg.pet_cg_transform {ResName = petCG, UIName = "UIBattleResultComplete"}
    end
    if cfg then
        local v = cfg[1]
        if v then
            local offposOri = Vector2(0, 400) --cg偏移及缩放 策划确认配置
            local scaleOri = 1
            if v.CGTransform then
                self._offsetPos.x = offposOri.x + v.CGTransform[1]
                self._offsetPos.y = offposOri.y + v.CGTransform[2]
                self._offsetScale = scaleOri * v.CGTransform[3]
            else
                self._offsetPos.x = offposOri.x
                self._offsetPos.y = offposOri.y
                self._offsetScale = scaleOri
            end
        end
    end

    return true
end

---@param casterEntity Entity
function PlaySkillCGEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    -- 初始化失败不再继续
    if not self:_InitCgData(casterEntity) then
        return
    end

    ---@type BattleRenderConfigComponent
    local cBattleRenderConfig = world:BattleRenderConfig()
    local canPlayCG = cBattleRenderConfig:GetCanPlaySkillSpineInBattle(self._effectRes, self._petID) ---在局外设置界面 可以设置是否播放CG
    if not canPlayCG then
        return
    end

    local skillID = self:GetSkillID(casterEntity)

    -- CG内容的刷新和相关资源的加载都丢进一个单独的界面里了
    GameGlobal.UIStateManager():ShowDialog("UIBattleUltraSkillCG", {
        effectRes = self._effectRes,
        petCGMat = self._petCGMat,
        offsetPos = self._offsetPos,
        offsetScale = self._offsetScale,
        petIconMat = self._petIconMat,
        skillID = skillID
    })

    YIELD(TT, self._waitTime)

    GameGlobal.UIStateManager():CloseDialog("UIBattleUltraSkillCG")
end

--相机后处理

function PlaySkillCGEffectInstruction:GetCacheResource(skillConfig,skinId)
    local t = {}
    if self._cfgPetID then
        local curSkinId = 0
        if skinId and skinId > 0 then
            curSkinId = skinId
        end
        -- local world = BattleStatHelper._GetMainWorld()
        -- if world then
        --     --主要处理本地光灵，黑拳赛对面的光灵是否正常cache无视
        --     local localPetList = world.BW_WorldInfo:GetLocalMatchPetList()
        --     if localPetList then
        --         for i,v in ipairs(localPetList) do
        --             local dataTmpID = v:GetTemplateID()
        --             if dataTmpID == self._cfgPetID then
        --                 skinId = v:GetSkinId()
        --                 break
        --             end
        --         end
        --     end
        --     self:_CollectRes(t,self._cfgPetID,skinId)
            
        --     if world:MatchType() == MatchType.MT_BlackFist then
        --         skinId = 0
        --         local remotePetList = world.BW_WorldInfo:GetRemoteMatchPetList()
        --         if remotePetList then
        --             for i,v in ipairs(remotePetList) do
        --                 local dataTmpID = v:GetTemplateID()
        --                 if dataTmpID == self._cfgPetID then
        --                     skinId = v:GetSkinId()
        --                     break
        --                 end
        --             end
        --         end
        --         self:_CollectRes(t,self._cfgPetID,skinId)
        --     end
        -- end
        self:_CollectRes(t,self._cfgPetID,curSkinId)
    end
    return t
end
function PlaySkillCGEffectInstruction:_CollectRes(t,petTemplateId,skinId)
    local cfg = Cfg.cfg_pet_skin[skinId]
    if not cfg then
        return
    end
    if cfg.ActiveSkillEff then
        local effectRes = cfg.ActiveSkillEff .. ".prefab"
        table.insert(t, {effectRes, 1})
    end
    local petCG = cfg.SimpleCG
    if not petCG then
        petCG = cfg.StaticBody
    end
    if petCG then
        local petCGMat = petCG .. ".mat"
        table.insert(t, {petCGMat, 1})
    end
    local cfg_pet = Cfg.cfg_pet[petTemplateId]
    if cfg_pet then
        local logo = cfg_pet.Logo
        if logo then
            local petIconMat = logo .. ".mat"
            table.insert(t, {petIconMat, 1})
        end
    end
end