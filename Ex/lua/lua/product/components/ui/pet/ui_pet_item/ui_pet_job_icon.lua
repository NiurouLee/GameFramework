---@class UIPetJobIcon:UICustomWidget
_class("UIPetJobIcon", UICustomWidget)
UIPetJobIcon = UIPetJobIcon

---@param pet MatchPet
function UIPetJobIcon:SetData(pet, type)
    if not pet then
        return
    end

    local prof = pet:GetProf()

    self:_SetImage(type, prof)
    -- self:_SetText(prof)
end

function UIPetJobIcon:_SetImage(type, prof)
    local job2Img = {
        [1] = {                         -- small
            [2001] = "epg_gqxq_icon08", -- 变化
            [2002] = "epg_gqxq_icon06", -- 狙手
            [2003] = "epg_gqxq_icon07", -- 爆破
            [2004] = "epg_gqxq_icon09"  -- 辅助
        },
        [2] = {                         -- large
            [2001] = "epg_gqxq_icon03", -- 变化
            [2002] = "epg_gqxq_icon01", -- 狙手
            [2003] = "epg_gqxq_icon02", -- 爆破
            [2004] = "epg_gqxq_icon04"  -- 辅助
        }
    }

    local info = {
        atlasName = "UIPetJobIcon.spriteatlas",
        spriteName = job2Img[type][prof]
    }

    UIStyleHelper.FitStyle_Widget(info, self, "_icon")
end

function UIPetJobIcon:_SetText(prof)
    -- local job2Tex = {
    --     [2001] = "str_pet_tag_job_name_color_change_1", -- 变化
    --     [2002] = "str_pet_tag_job_name_return_blood_1", -- 狙手
    --     [2003] = "str_pet_tag_job_name_attack_1",       -- 爆破
    --     [2004] = "str_pet_tag_job_name_function_1"      -- 辅助
    -- }

    -- local text = StringTable.Get(job2Tex[prof])
    -- UIWidgetHelper.SetLocalizationText(self, "_txt", text)
end
