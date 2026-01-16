---重构原来的Pet
---分离成客户端与服务端共享的局内match_pet，和客户端独有的pet

_class("MatchPet", Object)
---@class MatchPet:Object
MatchPet = MatchPet

function MatchPet:Constructor(data)
    if data then
        self:SetData(data)
    end
end

function MatchPet:SetData(data)
    ---@type MatchPetInfo
    self._data = data
    local templateID = self:GetTemplateID()
    self._cfg_pet = Cfg.cfg_pet[templateID]
    self._cfg_level = Cfg["cfg_pet_level_" .. templateID .. "_" .. self:GetPetGrade()] {Level = self:GetPetLevel()}
    if self._cfg_level ~= nil then
        self._cfg_level = self._cfg_level[1]
    elseif self:GetPetGrade() ~= 0 and self:GetPetLevel() ~= 1 then
        Log.error("[pet] SetData cfg_pet_level ", templateID, " error ", self:GetPetGrade(), self:GetPetLevel())
    end
    self._cfg_grade = Cfg.cfg_pet_grade {PetID = templateID, Grade = self:GetPetGrade()}
    if self._cfg_grade ~= nil then
        self._cfg_grade = self._cfg_grade[1]
    elseif self:GetPetGrade() ~= 0 and self:GetPetLevel() ~= 1 then
        Log.error("[pet] SetData cfg_pet_grade error ", templateID, self:GetPetGrade(), self:GetPetLevel())
    end
    self._cfg_awakening = Cfg.cfg_pet_awakening {PetID = templateID, Awakening = self:GetPetAwakening()}
    if self._cfg_awakening ~= nil then
        self._cfg_awakening = self._cfg_awakening[1]
    elseif self:GetPetGrade() ~= 0 and self:GetPetLevel() ~= 1 then
    --Log.error("[pet] SetData cfg_pet_awakening error ", templateID, self:GetPetAwakening())
    end
    self._cfg_affinity = Cfg.cfg_pet_affinity {PetID = templateID, AffinityLevel = self:GetPetAffinityLevel()}
    if self._cfg_affinity then
        self._cfg_affinity = self._cfg_affinity[1]
    elseif self:GetPetAffinityLevel() > 0 then
        Log.error(
            "[pet] SetData cfg_pet_affinity error tplid:",
            templateID,
            " AffinityLevel:",
            self:GetPetAffinityLevel()
        )
    end

    self._petAttrDict = {
        [PetAttributeType.Attack] = {str = "attack", GetValFunc = self.GetPetAttack},
        [PetAttributeType.Defence] = {str = "defence", GetValFunc = self.GetPetDefence},
        [PetAttributeType.HP] = {str = "health", GetValFunc = self.GetPetHealth}
    }
    self._petSkillDict = {
        [PetSkillType.SkillType_Active] = {str = "major_des", GetIdFunc = self.GetPetActiveSkill},
        [PetSkillType.SkillType_ChainSkill] = {str = "chain_des", GetIdFunc = self.GetPetChainSkills},
        [PetSkillType.SkillType_Passive] = {str = "equip_des", GetIdFunc = self.GetPetPassiveSkill}
    }
    ---@type ResPetSkill
    self._SkillRes = ResourceHelper:GetInstance():GetPetSKill()
    ---@type ResPetEquip
    self._EquipRes = ResourceHelper:GetInstance():GetPetEquip()
    ---@type ResPetEquipRefine
    self._EquipRefineRes = ResourceHelper:GetInstance():GetPetEquipRefine()

    self._afterDamage = data.after_damage or 0
    self._attack = data.attack and data.attack > 0 and data.attack or self:getAttr("Attack")
    self._defense = data.defense and data.defense > 0 and data.defense or self:getAttr("Defence")
    self._maxhp = data.max_hp and data.max_hp > 0 and data.max_hp or self:getAttr("Health")
    self._maxhp = math.floor(self._maxhp)
    self._power = data.pet_power or -1
    self._legendPower = data.pet_legendPower or 0
    self._curHp = data.cur_hp and data.cur_hp > 0 and data.cur_hp or self._maxhp
    if self._power == -1 then
        local activeSkillID = self:GetPetActiveSkill()
        local cfgv = Cfg.cfg_pet_battle_skill[activeSkillID]
        if cfgv then
            self._power = cfgv.TriggerParam
        else
            Log.fatal("### can not find cfg in cfg_pet_battle_skill. activeSkillID=", activeSkillID)
        end
    end
    local petSkillCfg =
        Cfg.cfg_pet_skill {PetID = templateID, Grade = self:GetPetGrade(), Awakening = self:GetPetAwakening()}
    if petSkillCfg and #petSkillCfg > 0 then
        --local featureCfgHelper = FeatureConfigHelper:New()
        --self._featureList = featureCfgHelper:ParseCustomFeatureList(petSkillCfg.FeautreList)
        self._featureList = petSkillCfg[1].FeatureList
    --原始配置数据 {[featureType]={}}
    end
end

function MatchPet:CalAttr()
    self._attack = self:getAttr("Attack")
    self._defense = self:getAttr("Defence")
    self._maxhp = self:getAttr("Health")
    self._maxhp = math.floor(self._maxhp)
end

-- 重复抽取次数
function MatchPet:RepeatGetTimes()
    return self._data.repet_get_times
end

--队伍中的位置
function MatchPet:GetTeamSlot()
    return self._data.team_slot
end

--唯一id
function MatchPet:GetPstID()
    return self._data.pet_pstid
end

--配置id
function MatchPet:GetTemplateID()
    return self._data.template_id
end

--装备精炼等级
function MatchPet:GetEquipRefineLv()
    return self._data.equip_refine_lv
end
function MatchPet:GetEquipRefineMaxLv()
    local cfgs = Cfg.cfg_pet_equip_refine{PetID=self:GetTemplateID()}
    if cfgs then
        return table.count(cfgs)
    end
    return 0
end
--名字
function MatchPet:GetPetName()
    return self._cfg_pet.Name
end

--英文名字
function MatchPet:GetPetEnglishName()
    return self._cfg_pet.EnglishName
end

--昵称
function MatchPet:GetPetNickName()
    return self._cfg_pet.NickName
end

--标签
function MatchPet:GetPetTags()
    return self._cfg_pet.Tags
end

--
function MatchPet:GetBinderPetID()
    return self._cfg_pet.BinderPetID
end

function MatchPet:IsMyTag(nTag)
    local l_tags = self:GetPetTags()
    for key, value in ipairs(l_tags) do
        if value == nTag then
            return true
        end
    end
    return false
end

--是传说光灵
function MatchPet:IsLegendPet()
    return self._cfg_pet.LegendPet == 1
end

--等级
function MatchPet:GetPetLevel()
    return self._data.level
end

--经验
function MatchPet:GetPetExp()
    return self._data.exp
end

--阶段
function MatchPet:GetPetGrade()
    return self._data.grade
end

--觉醒
function MatchPet:GetPetAwakening()
    return self._data.awakening
end

--亲密度等级
function MatchPet:GetPetAffinityLevel()
    return self._data.affinity_level
end

function MatchPet:GetPetAffinityMaxLevel()
    local affinityCfg = Cfg.cfg_pet_affinity_exp {}
    if affinityCfg == nil then
        return 0
    end
    return #affinityCfg
end

--亲密度经验
function MatchPet:GetPetAffinityExp()
    return math.floor(self._data.affinity_exp)
end

function MatchPet:GetPetAffinityMaxExp(level)
    if level == self:GetPetAffinityMaxLevel() then
        return Cfg.cfg_pet_affinity_exp[level].NeedAffintyExp - Cfg.cfg_pet_affinity_exp[level - 1].NeedAffintyExp
    end
    local exp = Cfg.cfg_pet_affinity_exp[level + 1].NeedAffintyExp - Cfg.cfg_pet_affinity_exp[level].NeedAffintyExp
    return exp
end

--获取星灵好感度升到下一级的进度，返回0-1，好感度满级后返回1
function MatchPet:GetPetAffinityLevelUpPercent()
    local curLevel = self:GetPetAffinityLevel()
    local maxLevel = self:GetPetAffinityMaxLevel()
    if curLevel == maxLevel then
        return 1
    end
    local deltaExp = self:GetPetAffinityMaxExp(curLevel)
    local curExp = self:GetPetAffinityExp() - Cfg.cfg_pet_affinity_exp[curLevel].NeedAffintyExp
    return curExp / deltaExp
end

--当前触发的剧情id
function MatchPet:GetTriggeredStoryId()
    return self._data.triggered_story_id
end

-- 是否触发了随机剧情
function MatchPet:IsTriggeredStory()
    ---@type AircraftModule
    local airModule = GameGlobal.GetModule(AircraftModule)
    local stories = airModule:GetPetStroyEventId(self:GetPstID())
    if stories and table.count(stories) > 0 then
        return true
    end
    return false
    --[[

        if self._data.triggered_story_id ~= nil and self._data.triggered_story_id > 0 then
            local event =
            Cfg.cfg_pet_affinity_event {StoryEventID = self._data.triggered_story_id, PetID = self:GetTemplateID()}
            if event and table.count(event) > 0 then
                local chat_id = event[1].StoryEventChatID
                if chat_id > 0 then -- 如果该剧情有触发终端消息 先判断终端消息是否完成
                    local l_QuestChatModule = GameGlobal.GetModule(QuestChatModule)
                    local chat_state = l_QuestChatModule:GetPetChatState(self._petData:GetTemplateID(), chat_id)
                    if
                    chat_state == QuestChatStatus.E_ChatState_Completed or
                    chat_state == QuestChatStatus.E_ChatState_Taken
                    then
                        return true
                    else
                        return false
                    end
                end
            end
        end
        return self._data.triggered_story_id ~= nil and self._data.triggered_story_id > 0
        ]]
end
--当前触发的任务id
function MatchPet:GetTriggeredTaskId()
    return self._data.triggered_task_id
end

function MatchPet:IsFinishedStory(nStoryEventId)
    for index, value in ipairs(self._data.story_finish_record) do
        if value == nStoryEventId then
            return true
        end
    end

    return false
end
---返回成功完成的剧情数量
function MatchPet:GetFinishedStoryCount()
    return table.count(self._data.story_finish_record)
end

--星级
function MatchPet:GetPetStar()
    return self._cfg_pet.Star
end

--职业
function MatchPet:GetProf()
    return self._cfg_pet.Prof
end

-- 保持与服务器函数名一致
function MatchPet:GetJob()
    return self:GetProf()
end

--主元素
function MatchPet:GetPetFirstElement()
    return self._cfg_pet.FirstElement
end

--副元素(等于0时视为没有副属性)
function MatchPet:GetPetSecondElement()
    if self:GetPetGrade() >= self._cfg_pet.Element2NeedGrade then
        if self._cfg_pet.SecondElement > 0 then
            return self._cfg_pet.SecondElement
        end
    end
end

function MatchPet:GetHPOffset()
    local realSkinId = 0
    if MatchPet.IsEffectByPetSkin(PetSkinEffectPath.MODEL_INGAME) then
        if self._data.current_skin and self._data.current_skin > 1 then
            realSkinId = self._data.current_skin
        end
    end
    if realSkinId == 0 then
        local petCfg = self._cfg_pet
        if not petCfg then
            Log.fatal("###[GetHPOffset] pet cfg is nil ! id --> ", tid, "| grade --> ", grade)
            return 0.15
        end
        realSkinId = petCfg.SkinId
    end
    local cfg = Cfg.cfg_pet_skin[realSkinId]
    if not cfg then
        Log.fatal("###[GetHPOffset] skin cfg is nil ! id --> ", tid, "| grade --> ", grade)
        return nil
    end
    return cfg.HeightOffset
end

function MatchPet:GetStoryTipsOffset()
    return self._cfg_pet.TipsHeightOffSet
end

--元素组
function MatchPet:GetPetElements()
    return {self:GetPetFirstElement(), self:GetPetSecondElement()}
end

function MatchPet:GetPetChinaTag()
    return self._cfg_pet.ChinaTag
end

--头像
---@param path PetSkinEffectPath
function MatchPet:GetPetHead(path)
    return HelperProxy:GetInstance():GetPetHead(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.Head
    -- else
    --     return self._cfg_grade.Head
    -- end
end
function MatchPet:GetPetVideo(path)
    return HelperProxy:GetInstance():GetPetVideo(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
end
---@param path PetSkinEffectPath
function MatchPet:GetPetItemIcon(path)
    return HelperProxy:GetInstance():GetPetItemIcon(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)

    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.ItemIcon
    -- else
    --     return self._cfg_grade.ItemIcon
    -- end
end

--皮肤ID
function MatchPet:GetSkinId()
    if self._data.current_skin and self._data.current_skin > 1 then
        return self._data.current_skin
    end
    local skinId = 1
    if self:GetPetGrade() == 0 then
        skinId = self._cfg_pet.SkinId
    else
        skinId = self._cfg_grade.SkinId
    end
    return skinId or 1
end

--立绘
---@param path PetSkinEffectPath
function MatchPet:GetPetBody(path)
    return HelperProxy:GetInstance():GetPetBody(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.Body
    -- else
    --     return self._cfg_grade.Body
    -- end
end
---@param path PetSkinEffectPath
function MatchPet:GetBattleMes(path)
    return HelperProxy:GetInstance():GetPetBattleMes(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)

    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.BattleMes
    -- else
    --     return self._cfg_grade.BattleMes
    -- end
end
---@param path PetSkinEffectPath
function MatchPet:GetHeadChain(path)
    return HelperProxy:GetInstance():GetPetHeadChain(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.HeadChain
    -- else
    --     return self._cfg_grade.HeadChain
    -- end
end

--编队立绘
---@param path PetSkinEffectPath
function MatchPet:GetPetTeamBody(path)
    return HelperProxy:GetInstance():GetPetTeamBody(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.TeamBody
    -- else
    --     return self._cfg_grade.TeamBody
    -- end
end

--获取下阶立绘的名字
function MatchPet:GetPetNextGradeBodyName()
    local data = {BodyName = "", StaticBody = ""}
    local next_grade = self:GetPetGrade() + 1
    if next_grade > self:GetMaxGrade() then
        return data
    else
        --data.StaticBody = _cfg_grade_next[1].StaticBody
        local _cfg_grade_next = Cfg.cfg_pet_grade {PetID = self:GetTemplateID(), Grade = next_grade}
        data.BodyName = _cfg_grade_next[1].BodyName
        data.StaticBody =
            HelperProxy:GetInstance():GetPetStaticBody(self:GetTemplateID(), next_grade, 0, PetSkinEffectPath.NO_EFFECT)
    end
    return data
end

--静态立绘
---@param path PetSkinEffectPath
function MatchPet:GetPetStaticBody(path)
    return HelperProxy:GetInstance():GetPetStaticBody(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.StaticBody
    -- else
    --     return self._cfg_grade.StaticBody
    -- end
end
---@param path PetSkinEffectPath
function MatchPet:GetPetBattleResultCG(path)
    return HelperProxy:GetInstance():GetPetSimpleCg(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.BattleResultCG
    -- else
    --     return self._cfg_grade.BattleResultCG
    -- end
end

--风船入驻立绘
---@param path PetSkinEffectPath
function MatchPet:GetPetAircraftBody(path)
    return HelperProxy:GetInstance():GetPetAircraftBody(
        self:GetTemplateID(),
        self:GetPetGrade(),
        self:GetSkinId(),
        path
    )
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.AircraftBody
    -- else
    --     return self._cfg_grade.AircraftBody
    -- end
end
---@param path PetSkinEffectPath
function MatchPet:GetPetSpine(path)
    return HelperProxy:GetInstance():GetPetSpine(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.Spine
    -- else
    --     return self._cfg_grade.Spine
    -- end
end

--星灵logo
function MatchPet:GetPetLogo()
    return self._cfg_pet.Logo
end
--描述
function MatchPet:GetPetDes()
    if self:GetPetGrade() == 0 then
        return ""
    else
        return self._cfg_grade.Des
    end
end

---static begin---
function MatchPet.IsEffectByPetSkin(path)
    if not path then
        return true
    end
    local cfg = Cfg.cfg_pet_skin_effect_filter[path]
    if cfg then
        return cfg.Effected
    end
    return true
end
function MatchPet.GetPetSkinCfg(tid, grade, skinId, path)
    local realSkinId = 0
    if MatchPet.IsEffectByPetSkin(path) then
        if skinId and skinId > 1 then
            realSkinId = skinId
        end
    end
    if realSkinId == 0 then
        if grade == 0 then
            local petCfg = Cfg.cfg_pet[tid]
            if not petCfg then
                Log.fatal(
                    "###[GetPetSkinCfg] pet cfg is nil ! id --> ",
                    tid,
                    "| grade --> ",
                    grade,
                    "| skinId --> ",
                    skinId,
                    "| path --> ",
                    path
                )
                return nil
            end
            realSkinId = petCfg.SkinId
        else
            local gradeCfg = Cfg.cfg_pet_grade {PetID = tid, Grade = grade}[1]
            if not gradeCfg then
                Log.fatal(
                    "###[GetPetSkinCfg] grade cfg is nil ! id --> ",
                    tid,
                    "| grade --> ",
                    grade,
                    "| skinId --> ",
                    skinId,
                    "| path --> ",
                    path
                )
                return nil
            end
            realSkinId = gradeCfg.SkinId
        end
    end
    local cfg = Cfg.cfg_pet_skin[realSkinId]
    if not cfg then
        Log.fatal(
            "###[GetPetSkinCfg] skin cfg is nil ! id --> ",
            tid,
            "| grade --> ",
            grade,
            "| skinId --> ",
            skinId,
            "| path --> ",
            path
        )
        return nil
    end
    return cfg
end

---static end---
--模型
---@param path PetSkinEffectPath
function MatchPet:GetPetPrefab(path)
    local cfg = MatchPet.GetPetSkinCfg(self:GetTemplateID(), self:GetPetGrade(), self:GetSkinId(), path)
    if not cfg then
        Log.fatal(
            "###[GetPetPrefab] cfg is nil ! id --> ",
            tid,
            "| grade --> ",
            grade,
            "| skinId --> ",
            skinId,
            "| path --> ",
            path
        )
        return nil
    end
    return cfg.Prefab
    --return HelperProxy:GetInstance():GetPetPrefab(self:GetTemplateID(),self:GetPetGrade(),self:GetSkinId(),path)
    -- if self:GetPetGrade() == 0 then
    --     return self._cfg_pet.Prefab
    -- else
    --     return self._cfg_grade.Prefab
    -- end
end

--特殊材质动画
function MatchPet:GetPetShaderEffect()
    return self._cfg_pet.ShaderEffect
end

--普通攻击id(不会改变)
--上面的 20/06/16已经是变化的了，哈哈
function MatchPet:GetNormalSkill()
    local petid = self:GetTemplateID()
    local grade = self:GetPetGrade()
    local awakening = self:GetPetAwakening()

    return self._SkillRes:GetNormalSKill(petid, grade, awakening)
end

--主动技能id
function MatchPet:GetPetActiveSkill(grade, awakening)
    local petid = self:GetTemplateID()
    local realGrade = grade or self:GetPetGrade()
    local realAwakening = awakening or self:GetPetAwakening()

    return self._SkillRes:GetActiveSkill(petid, realGrade, realAwakening)
end

--附加主动技能id列表
function MatchPet:GetPetExtraActiveSkill(grade, awakening)
    local equipRefineActiveSkillList = self:GetEquipRefineExtraActiveSkill()
    if equipRefineActiveSkillList then 
        return equipRefineActiveSkillList
    end

    local petid = self:GetTemplateID()
    local _grade = grade or self:GetPetGrade()
    local _awakening = awakening or self:GetPetAwakening()

    return self._SkillRes:GetExtraActiveSkill(petid, _grade, _awakening)
end

--被动技能id
function MatchPet:GetPetPassiveSkill(grade, awakening)
    local petid = self:GetTemplateID()
    local _grade = grade or self:GetPetGrade()
    local _awakening = awakening or self:GetPetAwakening()

    return self._SkillRes:GetPassiveSkill(petid, _grade, _awakening)
end

--连锁技ID
function MatchPet:GetPetChainSkills(grade, awakening)
    local petid = self:GetTemplateID()
    local _grade = grade or self:GetPetGrade()
    local _awakening = awakening or self:GetPetAwakening()

    return self._SkillRes:GetChainSkill(petid, _grade, _awakening)
end

--强化Buff
function MatchPet:GetPetIntensifyBuffList(grade, awakening)
    local petid = self:GetTemplateID()
    local _grade = grade or self:GetPetGrade()
    local _awakening = awakening or self:GetPetAwakening()

    return self._SkillRes:GetIntensifyBuffList(petid, _grade, _awakening)
end

--连锁技数据，给局内用
function MatchPet:GetChainSkillInfo(grade, awakening)
    local skills = self:GetPetChainSkills(grade, awakening)
    local ret = {}
    for i, v in ipairs(skills) do
        if v > 0 then
            ret[i] = {Skill = v, Chain = BattleSkillCfg(v).TriggerParam}
        end
    end
    return ret
end

--生活技能id
function MatchPet:GetPetWorkSkills(grade, awakening)
    local petid = self:GetTemplateID()
    local _grade = grade or self:GetPetGrade()
    local _awakening = awakening or self:GetPetAwakening()

    local ss = self._SkillRes:GetWorkSkill(petid, _grade, _awakening)
    if not ss then
        return nil
    end
    local works = {}
    for i = 1, #ss do
        local wkid = ss[i]
        if self:CheckWorkSkillOpen(wkid) then
            works[#works + 1] = wkid
        end
    end
    return works
end

--获得默认技能
function MatchPet:GetDefaultSkills(petId)
    local skillinfo = self._SkillRes:GetSKill(petId, 0, 0)
    if skillinfo == nil then
        return nil
    end

    --临时这么写
    return skillinfo.ActiveSkill, skillinfo.ChainSkill1, skillinfo.PassiveSkill
end

function MatchPet:SkillRelated(room_type)
    local skills = self:GetPetWorkSkills()
    for _, skill in ipairs(skills) do
        local cfg = Cfg.cfg_work_skill {ID = skill}
        if cfg and room_type == cfg[1].RoomType then
            return true
        end
    end
    return false
end

--内部函数，外部不要用
function MatchPet:getAttr(attr)
    --等级加成
    local value = self._cfg_level and self._cfg_level[attr] or 0

    --进阶加成
    if self:GetPetGrade() > 0 then
        value = value + self._cfg_grade[attr]
    end

    --觉醒加成
    if self:GetPetAwakening() > 0 then
        --Log.debug("attr..Percent : ", attr .. "Percent")
        local attrName = attr .. "Percent"
        value =
            math.floor(
            value + self._cfg_awakening[attr] + (self._cfg_awakening[attrName] * self._cfg_level[attr] / 100)
        )
    end

    --亲密度等级加成
    if self:GetPetAffinityLevel() and self:GetPetAffinityLevel() > 0 then
        value = value + self._cfg_affinity[attr]
    end

    --装备加成
    local el = self:GetEquipCfg()
    if el ~= nil then
        value = value + el[attr]
    end

    --装备精炼
    local equipRefine = self:GetEquipRefineCfg()
    if equipRefine ~= nil then 
        value = value + equipRefine[attr]
    end

    return value
end

function MatchPet:GetPetAffinityAttrAdded(attr)
    local value = 0
    if self:GetPetAffinityLevel() and self:GetPetAffinityLevel() > 0 then
        value = value + self._cfg_affinity[attr]
    end
    return value
end

--攻击
function MatchPet:GetPetAttack()
    return self._attack
end

--防御
function MatchPet:GetPetDefence()
    return self._defense
end

--血量
function MatchPet:GetPetHealth()
    return self._maxhp
end

function MatchPet:GetPetCurHealth()
    return self._curHp
end

--cd
function MatchPet:GetPetPower()
    return self._power
end

--传说光灵能量
function MatchPet:GetPetLegendPower()
    return self._legendPower
end

--暴击
function MatchPet:GetPetCrit()
    return self:getAttr("Crit")
end

--暴伤
function MatchPet:GetPetCritHurt()
    return self:getAttr("CritHurt")
end

--闪避
function MatchPet:GetPetDoge()
    return self:getAttr("Doge")
end

--命中
function MatchPet:GetPetHit()
    return self:getAttr("Hit")
end

--进阶属性加成
function MatchPet:GetPetGradeAttr(attr)
    if self:GetPetGrade() > 0 then
        return self._cfg_grade[attr]
    end
    return 0
end

--觉醒属性加成
function MatchPet:GetPetAwakeningAttr(attr)
    if self:GetPetAwakening() > 0 then
        return self._cfg_awakening[attr]
    end
end

--亲密度属性加成
function MatchPet:GetPetAffinityAttr(attr)
    if self:GetPetAffinityLevel() > 0 then
        return self._cfg_affinity[attr]
    end
    return 0
end

--当前阶段最大等级
function MatchPet:GetMaxLevel()
    local cfgs = Cfg["cfg_pet_level_" .. self:GetTemplateID() .. "_" .. self:GetPetGrade()]()
    local max = 1 --level最小为1
    for _, c in pairs(cfgs) do --不能改ipairs
        if max < c.Level then
            max = c.Level
        end
    end
    return max
end

--当前阶段最大Grade
function MatchPet:GetMaxGrade()
    local cfgs = Cfg.cfg_pet_grade {PetID = self:GetTemplateID()}
    local max = 0 --Grade最小值为0
    for _, c in ipairs(cfgs) do
        if max < c.Grade then
            max = c.Grade
        end
    end
    return max
end

--当前阶段最大Awakening
function MatchPet:GetMaxAwakening()
    local cfgs = Cfg.cfg_pet_awakening {PetID = self:GetTemplateID()}
    local max = 0 --Awakening最小值为0
    if cfgs ~= nil then
        for _, c in ipairs(cfgs) do
            if max < c.Awakening then
                max = c.Awakening
            end
        end
    end
    return max
end

--升级所需要的经验(总)
function MatchPet:GetLevelUpNeedExp()
    if self:GetPetLevel() >= self:GetMaxLevel() then
        Log.error("pet is max level")
        return nil
    end
    local cfg = self:GetLevelConfig(self:GetPetLevel() + 1)
    return cfg.NeedExp
end

--亲密度升级所需要的亲密度(总)
function MatchPet:GetAffinityLevelUpNeedExp()
    local cfg = Cfg.cfg_pet_affinity_exp[self._data.affinity_level]
    if cfg ~= nil then
        return cfg.NeedAffintyExp
    end
end

--得到某个等级的配置
function MatchPet:GetLevelConfig(level)
    local cfg = Cfg["cfg_pet_level_" .. self:GetTemplateID() .. "_" .. self:GetPetGrade()] {Level = level}
    if cfg ~= nil then
        return cfg[1]
    end
end

function MatchPet:GetCurrentLevelConfig()
    return self._cfg_level
end

--得到所有觉醒路点
function MatchPet:GetAwakeningConfig()
    local cfgs = Cfg.cfg_pet_awakening {PetID = self:GetTemplateID()}
    for i = #cfgs, 1, -1 do
        if cfgs[i].Awakening <= 0 then -- 过滤无效值
            table.remove(cfgs, i)
        end
    end
    return cfgs
end

--根据排序类型计算排序值
function MatchPet:GetSortValue(sort_type)
    if sort_type == PetSortType.Attack then
        return self:GetPetAttack()
    end
    if sort_type == PetSortType.Defence then
        return self:GetPetDefence()
    end
    if sort_type == PetSortType.Element then
        return self:GetPetFirstElement()
    end
    if sort_type == PetSortType.Star then
        return self:GetPetStar()
    end
    if sort_type == PetSortType.Health then
        return self:GetPetHealth()
    end
    if sort_type == PetSortType.Level then
        return self:GetPetLevel() + self:GetPetGrade() * 1000 + self:GetPetAwakening() * 10000
    end
    if sort_type == PetSortType.Affinity then
        return self:GetPetAffinityLevel()
    end
end

PetSkillChangeState = {
    NoChange = 0, --没改变
    Improved = 1, --提升
    NewGain = 2 --新获得
}

function MatchPet:GetChainSkillsByAwakening(awakening)
    local skills = {}
    local cfg = {}
    if awakening > self:GetMaxAwakening() then
        return nil
    end
    if awakening == 0 then
        cfg = Cfg.cfg_pet[self._data.template_id]
    else
        cfg = Cfg.cfg_pet_awakening {PetID = self:GetTemplateID(), Awakening = awakening}
        if not cfg then
            return nil
        end
        cfg = cfg[1]
    end

    skills = self:GetChainSkillInfo(nil, awakening)
    return skills
end

function MatchPet:GetSkillsByGrade(grade)
    local cfg = {}
    if grade == 0 then
        cfg = Cfg.cfg_pet[self._data.template_id]
    else
        cfg = Cfg.cfg_pet_grade {PetID = self:GetTemplateID(), Grade = grade}
        if not cfg then
            return nil
        end
        cfg = cfg[1]
    end

    local extra_skill_list = self:GetPetExtraActiveSkill(grade)
    local extra_skill_single = 0
    if extra_skill_list then
        extra_skill_single = extra_skill_list[1]
    end
    local data = {
        active_skill = self:GetPetActiveSkill(grade),
        extra_skill = extra_skill_single,
        chain_skills = self:GetPetChainSkills(grade),
        work_skills = self:GetPetWorkSkills(grade),
        passive_skills = self:GetPetPassiveSkill(grade),
        body = HelperProxy:GetInstance():GetPetStaticBody(self:GetTemplateID(), grade, 0, PetSkinEffectPath.NO_EFFECT)
        --body = cfg.StaticBody
    }

    return data
end
--得到进阶后的技能变化和技能id
function MatchPet:GetUpgradeChangeWithSkillID()
    local grade = self:GetPetGrade()
    if grade >= self:GetMaxGrade() then
        return nil
    end

    local next_grade_skills = self:GetSkillsByGrade(grade + 1)
    local cur_grade_skills = self:GetSkillsByGrade(grade)

    local change_data = {
        active_skill_status = {},
        extra_skill_status = {},
        chain_skills_status = {},
        work_skills_status = {},
        passive_skills_status = {},
        body_status = {}
    }

    -- 主动技能
    if cur_grade_skills.active_skill ~= next_grade_skills.active_skill then
        change_data.active_skill_status.state = PetSkillChangeState.Improved
        change_data.active_skill_status.from = cur_grade_skills.active_skill
        change_data.active_skill_status.to = next_grade_skills.active_skill
    else
        change_data.active_skill_status.state = PetSkillChangeState.NoChange
        change_data.active_skill_status.from = cur_grade_skills.active_skill
        change_data.active_skill_status.to = next_grade_skills.active_skill
    end

    -- 附加技能
    if cur_grade_skills.extra_skill ~= next_grade_skills.extra_skill then
        if cur_grade_skills.extra_skill == 0 then
            change_data.extra_skill_status.state = PetSkillChangeState.NewGain
            change_data.extra_skill_status.from = cur_grade_skills.extra_skill
            change_data.extra_skill_status.to = next_grade_skills.extra_skill
        else
            change_data.extra_skill_status.state = PetSkillChangeState.Improved
            change_data.extra_skill_status.from = cur_grade_skills.extra_skill
            change_data.extra_skill_status.to = next_grade_skills.extra_skill
        end
    else
        change_data.extra_skill_status.state = PetSkillChangeState.NoChange
        change_data.extra_skill_status.from = cur_grade_skills.extra_skill
        change_data.extra_skill_status.to = next_grade_skills.extra_skill
    end

    -- 立绘
    if cur_grade_skills.body ~= next_grade_skills.body then
        change_data.body_status.state = PetSkillChangeState.NewGain
        change_data.body_status.from = cur_grade_skills.body
        change_data.body_status.to = next_grade_skills.body
    else
        change_data.body_status.state = PetSkillChangeState.NoChange
        change_data.body_status.from = cur_grade_skills.body
        change_data.body_status.to = next_grade_skills.body
    end

    -- 连锁技能
    for i = 1, #cur_grade_skills.chain_skills do
        local chain_skill = cur_grade_skills.chain_skills[i]
        local next_skill = next_grade_skills.chain_skills[i]
        if chain_skill == nil and next_skill == nil then
            break
        end
        if chain_skill ~= next_skill then
            if chain_skill == nil then
                change_data.chain_skills_status[i] = {}
                change_data.chain_skills_status[i].state = PetSkillChangeState.NewGain
                change_data.chain_skills_status[i].from = chain_skill
                change_data.chain_skills_status[i].to = next_skill
            else
                change_data.chain_skills_status[i] = {}
                change_data.chain_skills_status[i].state = PetSkillChangeState.Improved
                change_data.chain_skills_status[i].from = chain_skill
                change_data.chain_skills_status[i].to = next_skill
            end
        else
            change_data.chain_skills_status[i] = {}
            change_data.chain_skills_status[i].state = PetSkillChangeState.NoChange
            change_data.chain_skills_status[i].from = chain_skill
            change_data.chain_skills_status[i].to = next_skill
        end
    end

    -- 工作技能
    for i = 1, 3 do
        local workskill = cur_grade_skills.work_skills[i]
        local next_skill = next_grade_skills.work_skills[i]
        if not workskill and not next_skill then
            break
        end
        if workskill ~= next_skill then
            if workskill == nil then
                change_data.work_skills_status[i] = {}
                change_data.work_skills_status[i].state = PetSkillChangeState.NewGain
                change_data.work_skills_status[i].from = workskill
                change_data.work_skills_status[i].to = next_skill
            else
                change_data.work_skills_status[i] = {}
                change_data.work_skills_status[i].state = PetSkillChangeState.Improved
                change_data.work_skills_status[i].from = workskill
                change_data.work_skills_status[i].to = next_skill
            end
        else
            change_data.work_skills_status[i] = {}
            change_data.work_skills_status[i].state = PetSkillChangeState.NoChange
            change_data.work_skills_status[i].from = workskill
            change_data.work_skills_status[i].to = next_skill
        end
    end

    --被动技能
    if cur_grade_skills.passive_skills ~= next_grade_skills.passive_skills then
        if cur_grade_skills.passive_skills == 0 then
            change_data.passive_skills_status.state = PetSkillChangeState.NewGain
            change_data.passive_skills_status.from = cur_grade_skills.passive_skills
            change_data.passive_skills_status.to = next_grade_skills.passive_skills
        else
            change_data.passive_skills_status.state = PetSkillChangeState.Improved
            change_data.passive_skills_status.from = cur_grade_skills.passive_skills
            change_data.passive_skills_status.to = next_grade_skills.passive_skills
        end
    else
        change_data.passive_skills_status.state = PetSkillChangeState.NoChange
        change_data.passive_skills_status.from = cur_grade_skills.passive_skills
        change_data.passive_skills_status.to = next_grade_skills.passive_skills
    end

    return change_data
end

---@public
---@param attrType PetAttributeType 属性枚举
---@return string
---根据属性枚举获取self._petAttrDict中的字符串
function MatchPet:GetAttrStr(attrType)
    return self._petAttrDict[attrType].str or ""
end

---@public
---@param attrType PetAttributeType 属性枚举
---@return string
---根据属性枚举获取self._petAttrDict中的取值函数
function MatchPet:GetAttrFunc(attrType)
    return self._petAttrDict[attrType].GetValFunc or nil
end

---@public
---@param skillType PetSkillType 属性枚举
---@return table
---根据技能枚举获取self._petSkillDict中的对象
function MatchPet:GetSkillByType(skillType)
    return self._petSkillDict[skillType] or nil
end

--当前所在房间id

--工作技能
---@param room_type AirRoomType
---@param skill_type WorkSkillType
function MatchPet:GetWorkSkillAffinity(room_type, skill_type)
    local vv = 0
    local skills = self:GetPetWorkSkills()
    for _, skill_id in ipairs(skills) do
        local cfg = Cfg.cfg_work_skill[skill_id]
        if cfg then
            if cfg.RoomType == room_type and cfg.WorkEffect[1] == skill_type then
                vv = vv + cfg.WorkEffect[2]
            end
        end
    end
    return vv
end

--工作技能
---@param room_type AirRoomType
---@param skill_type WorkSkillType
---av 绝对值加成 mv 百分比加成
function MatchPet:GetWorkSkillEffectVV(work_type, room_type)
    local av = 0
    local mv = 0
    local skills = self:GetPetWorkSkills()
    if skills == nil then
        return av, mv
    end
    for _, skill_id in ipairs(skills) do
        local cfg = Cfg.cfg_work_skill[skill_id]
        if cfg and cfg.RoomType == room_type and cfg.WorkEffect[1] == work_type then
            av = av + cfg.WorkEffect[2]
            mv = mv + cfg.WorkEffect[3]
        end
    end
    return av, mv
end

function MatchPet:IsEffectiveSkill(room_type)
    local skills = self:GetPetWorkSkills()
    for _, skill_id in ipairs(skills) do
        local cfg = Cfg.cfg_work_skill[skill_id]
        if cfg then
            if cfg.RoomType == room_type then
                return true
            end
        end
    end
    return false
end
function MatchPet:HaveType(choose_types)
    local ret = false
    for key, value in pairs(choose_types) do --不确定是否可以ipairs
        if value == AircraftEnterChooseType.MasterCtrl then --工作技能是否对主控室有效
            ret = self:IsEffectiveSkill(AirRoomType.CentralRoom)
        elseif value == AircraftEnterChooseType.Power then
            ret = self:IsEffectiveSkill(AirRoomType.PowerRoom)
        elseif value == AircraftEnterChooseType.Replay then
            ret = self:IsEffectiveSkill(AirRoomType.MazeRoom)
        elseif value == AircraftEnterChooseType.Catch then
            ret = self:IsEffectiveSkill(AirRoomType.EvilRoom)
        elseif value == AircraftEnterChooseType.Puri then
            ret = self:IsEffectiveSkill(AirRoomType.PurifyRoom)
        end
        if ret then
            return ret
        end
    end

    return ret
end

--获取星灵可能存在的所有工作技能
function MatchPet:PetGradeNewSkill()
    --[[local cur_grade = self:GetPetGrade()
    local all_work_skills = {}
    if cur_grade == 0 then
        all_work_skills[#all_work_skills + 1] = {
            Grade = 0,
            WorkSkill1 = self._cfg_pet.WorkSkill1,
            WorkSkill2 = self._cfg_pet.WorkSkill2,
            WorkSkill3 = self._cfg_pet.WorkSkill3
        }
    end

    local cfgs = Cfg.cfg_pet_grade {PetID = self:GetTemplateID()}
    table.sort(
        cfgs,
        function(a, b)
            return a.Grade < b.Grade
        end
    )
    for id, cfg in pairs(cfgs) do
        if cur_grade <= cfg.Grade then
            all_work_skills[#all_work_skills + 1] = {
                Grade = cfg.Grade,
                WorkSkill1 = cfg.WorkSkill1,
                WorkSkill2 = cfg.WorkSkill2,
                WorkSkill3 = cfg.WorkSkill3
            }
        end
    end

    local work_skill_l = 0
    local work_skill_2 = 0
    local work_skill_3 = 0
    local res = {}
    for id, cfg in pairs(all_work_skills) do
        if cfg.WorkSkill1 ~= 0 and work_skill_l == 0 then
            work_skill_l = cfg.WorkSkill1
            res[#res + 1] = {Grade = cfg.Grade, NewSkill = work_skill_l}
        end
        if cfg.WorkSkill2 ~= 0 and work_skill_2 == 0 then
            work_skill_2 = cfg.WorkSkill2
            res[#res + 1] = {Grade = cfg.Grade, NewSkill = work_skill_2}
        end
        if cfg.WorkSkill3 ~= 0 and work_skill_3 == 0 then
            work_skill_3 = cfg.WorkSkill3
            res[#res + 1] = {Grade = cfg.Grade, NewSkill = work_skill_3}
        end
        if #res >= 3 then
            break
        end
    end--]]
    local petid = self:GetTemplateID()
    local grade = self:GetMaxGrade()
    local awakening = self:GetPetAwakening()

    local work_skill_l = 0
    local work_skill_2 = 0
    local work_skill_3 = 0
    local res = {}

    --todo临时这么写
    for i = 0, grade do
        local wks = self._SkillRes:GetSKill(petid, i, awakening)

        if wks.WorkSkill1 then
            if wks.WorkSkill1 ~= 0 and work_skill_l == 0 then
                if self:CheckWorkSkillOpen(wks.WorkSkill1) then
                    work_skill_l = wks.WorkSkill1
                    res[#res + 1] = {Grade = i, NewSkill = work_skill_l}
                end
            end
        end
        if wks.WorkSkill2 then
            if wks.WorkSkill2 ~= 0 and work_skill_2 == 0 then
                if self:CheckWorkSkillOpen(wks.WorkSkill2) then
                    work_skill_2 = wks.WorkSkill2
                    res[#res + 1] = {Grade = i, NewSkill = work_skill_2}
                end
            end
        end
        if wks.WorkSkill3 then
            if wks.WorkSkill3 ~= 0 and work_skill_3 == 0 then
                if self:CheckWorkSkillOpen(wks.WorkSkill3) then
                    work_skill_3 = wks.WorkSkill3
                    res[#res + 1] = {Grade = i, NewSkill = work_skill_3}
                end
            end
        end
        if #res >= 3 then
            break
        end
    end

    return res
end
--工作技能进行战术室开启筛选
function MatchPet:CheckWorkSkillOpen(skillID)
    --如果是战术室相关并且战术室未开启,技能为空
    local cfg_work_skill = Cfg.cfg_work_skill[skillID]
    if not cfg_work_skill then
        Log.error("###[MatchPet] cfg_work_skill is nil ! id --> ", skillID)
    end
    local roomType = cfg_work_skill.RoomType
    local airModule = GameGlobal.GetModule(AircraftModule)
    if roomType == AirRoomType.TacticRoom and not airModule:GetSwitchOpenState(16) then
        return false
    end
    return true
end

function MatchPet:GetPetCamp()
    local cfgPetTagList = self._cfg_pet.Tags
    local tcfgPetTags = Cfg.cfg_pet_tags
    for i = 1, #cfgPetTagList do
        local tagID = cfgPetTagList[i]
        if (tcfgPetTags[tagID].tagType) == PetTagType.Camp then
            return tagID
        end
    end

    Log.error("Pet camp tag not found: petTemplateID=", self._cfg_pet.ID)
    return nil
end

-- 是否有先制攻击
function MatchPet:HasPreEmptiveAttack()
    local petid = self:GetTemplateID()
    local grade = self:GetPetGrade()
    local awakening = self:GetPetAwakening()

    local list = self._SkillRes:GetIntensifyBuffList(petid, grade, awakening)
    if list then
        local i = table.ikey(list, BattleConst.PreAttackBuffId)
        if i then
            return i > 0
        else
            return false
        end
    else
        return false
    end
end

function MatchPet:GetTaskInfoVec()
    return self._data.task_info
end

function MatchPet:GetFirstTaskInfo()
    local len = #self._data.task_info
    if len <= 0 then
        return nil
    end

    return self._data.task_info[1]
end

function MatchPet:GetAfterDamage()
    return self._afterDamage
end

--是否可以入住工作室
function MatchPet:IsWrok()
    local ss = self._data.mask_state & PetMaskState.PMS_Dispatch
    return ss <= 0
end
--是否可以派遣
function MatchPet:IsDispatch()
    -- local mm = PetMaskState.PMS_Story | PetMaskState.PMS_Work | PetMaskState.PMS_Dispatch | PetMaskState.PMS_Present
    -- local mm = PetMaskState.PMS_Dispatch
    -- local ss = self._data.mask_state & mm
    -- return ss <= 0
    return true
end

--是否:PetMaskState
function MatchPet:IsPetMaskState(maskState)
    local ss = self._data.mask_state & maskState
    return ss <= 0
end

--装备等级
function MatchPet:GetEquipLv()
    return self._data.equip_lv
end

-- 助战key 有则是助战星灵 没有则用自己的
function MatchPet:GetHelpPetKey()
    return self._data.m_nHelpPetKey
end

function MatchPet:IsHelpPet()
    return self:GetHelpPetKey() > 0
end

--装备开启
function MatchPet:OpenEquip()
    if self._data.equip_lv > 0 then
        return true
    end
    return false
end

--获取装备cfg
---@param level 为nil则取当前等级
function MatchPet:GetEquipCfg(level)
    if level == nil then
        level = self:GetEquipLv()
        if level == nil then 
            return nil
        end
    end
    if level <= 0 then
        return nil
    end

    local cfgid = self:GetTemplateID()
    return self._EquipRes:GetRes(cfgid, level)
end

---@return PetEquipRefineStatus
function MatchPet:GetEquipRefineStatus()
    local lv = self._data.equip_refine_lv
    if lv > 0 then
        return PetEquipRefineStatus.UNLOCK --已解锁
    end
    local cfgs = Cfg.cfg_pet_equip_refine{PetID = self:GetTemplateID(), Level = 1} --只需查下等级为1的
    if not cfgs or #cfgs == 0 then
        return PetEquipRefineStatus.NO_OPEN --未开放
    end

    --检查开放条件
    local cfg = cfgs[1]
    local strCondition = cfg.OpenCondition
    local conditions = StrToArray2:GetInstance():GetArray(strCondition, '&', ',', nil, true)
    local isOpen = true
    for k, v in pairs(conditions) do
        if not ConditionCheck:GetInstance():Check(v) then
            isOpen = false
           break
        end
    end

    if isOpen then
        return PetEquipRefineStatus.UNLOCK 
    end
    return PetEquipRefineStatus.OPEN_LOCK 
end

function MatchPet:GetEquipIntensifyParams()
    local res = self:GetEquipCfg()
    if res then
        return res.elementParam
    else
        --Log.fatal("GetEquipCfg Failed ")
    end
    return nil
end

function MatchPet:GetPropertyRestraint()
    local res = self:GetEquipCfg()
    if res then
        return res.PropertyRestraint
    end
    return 0
end

----------------------
--region 获取不包含突破的攻防血数值
function MatchPet:getAttWithoutBreak(attr)
    --等级加成
    local value = self._cfg_level and self._cfg_level[attr] or 0
    --觉醒加成
    if self:GetPetGrade() > 0 then
        value = value + self._cfg_grade[attr]
    end
    --突破加成
    -- if self:GetPetAwakening() > 0 then
    --     Log.debug("attr..Percent : ", attr .. "Percent")
    --     local attrName = attr .. "Percent"
    --     value =
    --         math.floor(
    --         value + self._cfg_awakening[attr] + (self._cfg_awakening[attrName] * self._cfg_level[attr] / 100)
    --     )
    -- end
    --亲密度等级加成
    -- if self:GetPetAffinityLevel() and self:GetPetAffinityLevel() > 0 then
    --     value = value + self._cfg_affinity[attr]
    -- end
    --装备加成
    local el = self:GetEquipCfg()
    if el ~= nil then
        value = value + el[attr]
    end

    --装备精炼
    local equipRefine = self:GetEquipRefineCfg()
    if equipRefine ~= nil then 
        value = value + equipRefine[attr]
    end

    return value
end
function MatchPet:NoBreak_Attack()
    return self:getAttWithoutBreak("Attack")
end
function MatchPet:NoBreak_Defence()
    return self:getAttWithoutBreak("Defence")
end
function MatchPet:NoBreak_Health()
    return self:getAttWithoutBreak("Health")
end

--是否满突破
function MatchPet:IsBreakFull()
    return self:GetPetAwakening() >= self:GetPetStar()
end

--是否能够突破
---@return boolean,number
function MatchPet:CanPetBreak()
    local itemModule = GameGlobal.GetModule(ItemModule)
    local stage = self:GetPetAwakening()   -- 当前突破等级
    local matCfg = self:GetAwakeningConfig() --获得觉醒材料
    local maxStage = self:GetMaxAwakening()
    self._isHightLevelPet = false
    self._firstBreak = 0

    if stage >= maxStage or #matCfg <= 3 then
        return false,0
    end

    --+1表示突破到下一级需要的材料
    local curMat = matCfg[stage+1].NeedItem
    --材料
    local mats = {}
    for i = 1, #curMat do
        local value = curMat[i]
        local content = string.split(value, ",")
        local mat = {}
        mat.id = tonumber(content[1])
        mat.count = tonumber(content[2])
        mats[#mats + 1] = mat
    end

    --如果材料数量小于2或者第二个材料的id是星辰材料（传说光灵）则不能突破
    if (mats[2] and  mats[2].id == 3801001) then
        return false,0
    end

    if self:GetPetStar() >= 5 then 
        self._isHightLevelPet = true 
        for i = 1, #matCfg do
            local value = matCfg[i].NeedItem
            if #value == 2 then 
                self._firstBreak = i
                break
            end 
        end
    end 

    local addItemFun = function (tab,item)
        if not tab then
           return 
        end 
        for index, value in ipairs(tab) do
            if value.id == item.id then
                value.count  = value.count + item.count
                return 
            end 
        end
        local newItem = {}
        newItem.id = item.id
        newItem.count = item.count
        table.insert(tab,newItem)
    end
    
    -- 第一次心珀 之前总材料
    self._totleUseItems = {}
    if stage < self._firstBreak and self._isHightLevelPet then 
        for i = stage + 1 ,self._firstBreak  do
            local needItem = matCfg[i].NeedItem
            for i = 1, #needItem do
                local value = needItem[i]
                local content = string.split(value, ",")
                local item = {}
                item.id = tonumber(content[1])
                item.count = tonumber(content[2])
                addItemFun(self._totleUseItems,item)
            end
        end 
    end 

    if stage < self._firstBreak and self._isHightLevelPet then
        local needNum1 = itemModule:GetItemCount(self._totleUseItems[1].id)
        local needNum2 = itemModule:GetItemCount(self._totleUseItems[2].id)
        return needNum1 >= self._totleUseItems[1].count and needNum2 >= self._totleUseItems[2].count,needNum2
    end
    --检查数量够不够
    local needNum1 = itemModule:GetItemCount(mats[1].id)
    local needNum2 = itemModule:GetItemCount(mats[2].id)

    if needNum1 >= mats[1].count and needNum2 >= mats[2].count then
        return true,needNum2
    else
        return false,0
    end
end

--是否需要显示突破红点
function MatchPet:IsShowRedPoint()
    local petID = self:GetTemplateID()
    local stage = self:GetPetAwakening()

    --玩家openID
    local roleModule = GameGlobal.GetModule(RoleModule)
    local openID = roleModule:GetPstId()
    local canBreak,needNum2 = self:CanPetBreak()
    --openID + petID + 数量 + 当前阶级
    local key = openID..petID..needNum2..stage
    if stage < self._firstBreak and self._isHightLevelPet then 
        needNum2 = 1 
        key  = openID..petID..needNum2..self._firstBreak.."New"
    end
    if canBreak then
        if LocalDB.GetInt(key) == 2 then
            return false
        end
        LocalDB.SetInt(key, 1)
        return true
    else
        return false
    end
end

--取消显示突破红点
function MatchPet:CancelRedPoint()--玩家openID
    local itemModule = GameGlobal.GetModule(ItemModule)
    local roleModule = GameGlobal.GetModule(RoleModule)
    local openID = roleModule:GetPstId()
    local petID = self:GetTemplateID()
    local stage = self:GetPetAwakening()
    local matCfg = self:GetAwakeningConfig() --获得觉醒材料
    local maxStage = self:GetMaxAwakening()
    if stage >= maxStage or #matCfg <= 3 then
        return
    end
    local needNum2 = 0
    if stage < self._firstBreak and self._isHightLevelPet then
        local useNum1 = itemModule:GetItemCount(self._totleUseItems[1].id)
        local useNum2 = itemModule:GetItemCount(self._totleUseItems[2].id)
        local canRed =  useNum1 >= self._totleUseItems[1].count and useNum2 >= self._totleUseItems[2].count
        if not canRed then
           return  
        end 
        needNum2 = 1
    else 
        --+1表示突破到下一级需要的材料
        local curMat = matCfg[stage+1].NeedItem
        --材料
        local mats = {}
        for i = 1, #curMat do
            local value = curMat[i]
            local content = string.split(value, ",")
            local mat = {}
            mat.id = tonumber(content[1])
            mat.count = tonumber(content[2])
            mats[#mats + 1] = mat
        end
        needNum2 = itemModule:GetItemCount(mats[2].id)
    end

    local key = openID..petID..needNum2..stage
    if stage < self._firstBreak and self._isHightLevelPet then 
        key  = openID..petID..needNum2..self._firstBreak.."New"
    end
    LocalDB.SetInt(key, 2)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckCardAwakeRedPoint)
end

--是否需要显示皮肤红点
function MatchPet:IsShowSkinRedPoint()
    local petModule = GameGlobal.GetModule(PetModule)
    local petId = self:GetTemplateID()
    local petSkinCfg = Cfg.cfg_pet_skin {PetId = petId}
    ---@type pet_skin_data
    local skinsStateData = petModule:GetPetSkinsData(petId)
    for idx, skinCfg in ipairs(petSkinCfg) do
        ---@type DPetSkinDetailCard
        local uiSkinData = DPetSkinDetailCard:New(skinCfg)
        uiSkinData:SetIsTipsDetail(true)
        local is_obtain = false
        uiSkinData:SetIsCurrentSkin(false)
        if skinsStateData then
            local obtainedSkinInfo = skinsStateData.skin_info
            if obtainedSkinInfo then
                for _, skinInfo in pairs(obtainedSkinInfo) do
                    if skinInfo and (skinInfo.skin_id == skinCfg.id) then
                        is_obtain = true
                        uiSkinData:SetUnlockCg(skinInfo.unlock_CG)
                        break
                    end
                end
            end
        end
        uiSkinData:SetObtained(is_obtain)
        local storyId = uiSkinData.cfg.StoryId
        if is_obtain and not uiSkinData:IsUnlockCg() and storyId then
            return true
        end
    end
    return false
end

--连线移动中的特效表现
function MatchPet:GetChainMoveEffect()
    local realSkinId = 0
    if MatchPet.IsEffectByPetSkin(PetSkinEffectPath.MODEL_INGAME) then
        if self._data.current_skin and self._data.current_skin > 1 then
            realSkinId = self._data.current_skin
        end
    end
    if realSkinId == 0 then
        local petCfg = self._cfg_pet
        realSkinId = petCfg.SkinId
    end
    local cfg = Cfg.cfg_pet_skin[realSkinId]
    if not cfg then
        return nil
    end
    return cfg.MoveEffect
end
---获取模块列表
function MatchPet:GetFeatureList()
    return self._featureList
    --原始配置数据 {[featureType]={}}
end
--获取是否是绑定的星灵
function MatchPet:IsBinderPet(petid)
    local cfg = Cfg.cfg_pet{}
    if cfg then
        if petid == self:GetTemplateID() then
            return
        end
        local cfg_a = cfg[self:GetTemplateID()]
        if not cfg_a then
            Log.error("###[MatchPet] cfg_a is nil ! id --> ",self:GetTemplateID())
            return
        end
        local binderID = cfg_a.BinderPetID
        if binderID and binderID == petid then
            return true
        end

        local cfg_b = cfg[petid]
        if not cfg_b then
            Log.error("###[MatchPet] cfg_b is nil ! id --> ",petid)
            return
        end
        local binderID = cfg_b.BinderPetID
        if binderID and binderID == self:GetTemplateID() then
            return true
        end
    end
    return false
end

---@param level 为nil则取当前等级
function MatchPet:GetEquipRefineCfg(level)
    if level == nil then
        level = self:GetEquipRefineLv()
        if level == nil then 
            return nil
        end
    end
    if level <= 0 then
        return nil
    end

    local cfgid = self:GetTemplateID()
    return self._EquipRefineRes:GetRes(cfgid, level)
end

function MatchPet:GetEquipRefineIntensifyParams()
    ---提取单行数据
    local res = self:GetEquipRefineCfg()
    if res then
        return res.elementParam
    else
        --Log.fatal("GetEquipCfg Failed ")
    end
    return nil
end

function MatchPet:GetEquipRefineBuffListData()
    local res = self:GetEquipRefineCfg()
    if res then 
        return res.BuffID
    end
end

---装备精炼里配置的额外连锁技
function MatchPet:GetPetExtraChainSkillList()
    local res = self:GetEquipRefineCfg()
    if res then 
        return res.ExtraChainSkill
    end
end

---重置额外主动技
function MatchPet:GetEquipRefineExtraActiveSkill()
    local res = self:GetEquipRefineCfg()
    if res then 
        return res.ExtraActiveSkill
    end
end

function MatchPet:GetEquipRefineFeatureList()
    local res = self:GetEquipRefineCfg()
    if res then 
        return res.FeatureList
    end
end
function MatchPet:GetEquipRefineVariantActiveSkillInfo()
    local res = self:GetEquipRefineCfg()
    if res then
        return res.VariantActiveSkillInfo
    end
end

function MatchPet:GetPetSupplyPieceWeights()
    return self._cfg_pet.SupplyPieceWeight
end

--endregion
----------------------
--时装 影响开关 功能枚举 cfg_pet_skin_effect_filter.xlsx
--- @class PetSkinEffectPath
local PetSkinEffectPath = {
    NO_EFFECT = 0, --不影响
    HEAD_ICON_INGAME = 1, --头像：局内头像
    HEAD_ICON_CHAIN_SKILL_PREVIEW = 2, --头像：连锁技释放预览
    HEAD_ICON_CHANGE_ASSIST = 3, --头像：更换立绘头像
    HEAD_ICON_WE_CHAT = 4, --头像：终端头像
    HEAD_ICON_DISPATCH = 5, --头像：派遣
    HEAD_ICON_AIR_STORY_TIPS = 6, --头像：风船剧情提示
    HEAD_ICON_CHAT_FIREND = 7, --头像：chat_friend
    HEAD_ICON_PLAYER_INFO_HELP = 8, --头像：玩家信息中助战管理
    BODY_PET_DETAIL = 9, --立绘：光灵详情
    BODY_LEVLE_UP = 10, --立绘：升级
    BODY_GRADE = 11, --立绘：觉醒
    BODY_AWAKE = 12, --立绘：突破
    BODY_INTO_AIRCRAFT = 13, --立绘：风船入驻
    BODY_HELP = 14, --立绘：助战查看
    BODY_INGAME_PREVIEW = 15, --立绘：局内预览
    BODY_CHANGE_ASSIST = 16, --立绘：更换立绘
    BODY_FILES = 17, --立绘：档案
    BODY_BATTLE_RESULT = 18, --立绘：战斗结算
    CARD_PET_LIST = 19, --卡牌：光灵列表(Body)
    CARD_TEAM = 20, --卡牌：编队(TeamBody)
    CARD_TEAM_SELECT = 21, --卡牌：编队选择(Body)
    CARD_ROLE_RELATION = 22, --卡牌：人事情报(Body)
    CARD_TOWER = 23, --卡牌：塔(Body)
    CARD_DISPATCH = 24, --卡牌：派遣(Body)
    CARD_TEAM_MOVE_HELP_PET = 25, --卡牌：
    CARD_HELP_MANAGER = 26, --卡牌：助战管理（VideoIcon)
    CARD_HELP_SELECT = 27, --卡牌：助战选择（VideoIcon)
    CARD_DRAW_MULTI = 28, --卡牌：多抽展示（TeamBody）
    CARD_TOWER_TEAM_BODY = 29, --卡牌：塔(TeamBody)(目前没用）
    CARD_CARD_WE_CHAT_ROLE = 30, --卡牌：wechat 光灵选择（TeamBody）
    MODEL_INGAME = 31, --模型：局内
    MODEL_AIRCRAFT = 32, --模型：风船
    BODY_AIRCRAFT_ROOM_INTERACT = 33, --立绘：风船房间交互
    BODY_PET_INTIMACY = 34, --立绘：光灵好感度
    BODY_INTO_AIRCRAFT_AIRBODY = 35, --立绘：风船入驻（AircraftBody）
    BODY_INGAME_TEAM = 36, --立绘：局内队伍（BattleMes）
    HEAD_AIRCRAFT_INTERACT = 37, --头像：风船交互
    HEAD_ICON_PET_INTIMACY = 38, --头像：好感度
    HEAD_ICON_STORY = 39, --头像：剧情
    ITEM_ICON_PET_DETAIL = 40, --物品图标：光灵详情
    ITEM_ICON_PET_INTIMACY = 41, --物品图标：光灵好感度
    ITEM_ICON_HELP = 42, --物品图标：助战
    MODEL_MAZE = 43 --模型：迷宫
}
_enum("PetSkinEffectPath", PetSkinEffectPath)


--装备精炼状态
--- @class PetEquipRefineStatus
local PetEquipRefineStatus = {
    NO_OPEN = 0, --未开放
    OPEN_LOCK = 1, --已开放未解锁
    UNLOCK = 2  --已解锁
}
_enum("PetEquipRefineStatus", PetEquipRefineStatus)