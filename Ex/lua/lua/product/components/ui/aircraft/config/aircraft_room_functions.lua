--房间信息特殊处理标志
UIAircraftRoomFuncSpecailTag = {
    Ambient2Liking = 1, --主控室，氛围兑换好感度
    RoomAndRelic = 2, --秘境室，房间与圣物类型
    DoubleCouponStore = 3, --资源室，双倍券存储
    DrawCouponStore = 4, --灯塔室，抽卡券存储
    AtomStore = 5, --原子剂存储
    AtomDiscount = 6, --原子剂折扣
    SmeltRoomTip = 7, --熔炼室文本提示
    DispatchCount = 8, --派遣室可派遣次数
    DispatchTeam = 9, --派遣室派遣队伍
    DispatchRecoverSpeedUp = 10, --派遣室加速派遣恢复
    DispatchMaxCount = 11, --派遣室派遣次数上限
    DispatchRecoverOne = 12, --派遣室恢复1次派遣
    DispatchTaskMaxStr = 13, --派遣室任务最高星级
    TapeStorage = 14, --卡带存储
    TapeCountdown = 15, --卡带恢复倒计时
    TacticWorkSkill = 16, --战术室工作技，加速战例卡带制造
    none = 999
}

UIAircraftRoomFunctions = {
    [AirRoomType.CentralRoom] = {
        --主控室
        --房间功能
        roomFunc = {
            [1] = {
                name = "str_aircraft_tip_ambien_ceiling", --氛围上限
                func = "GetAmbientLimit",
                isInt = true
            }
        },
        --设施功能
        facilityFunc = {
            [1] = {
                name = "str_aircraft_tip_ambien_ceiling", --氛围上限
                func = "GetAmbientLimit",
                isInt = true
            }
        },
        --入住功能
        settleFunc = {
            [1] = {
                name = "str_aircraft_add_furniture_affinity", --额外增加家具氛围
                func = "GetAddFurnitureAmbientValue",
                isInt = false,
                isPercent = true --显示带加号的百分比
            }
        }
    },
    [AirRoomType.PowerRoom] = {
        --能源室
        roomFunc = {
            [1] = {
                name = "str_aircraft_func_power", --星能
                func = "GetPowerLimit",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_firefly_recover_speed", --萤火恢复速度
                func = "GetFireflyRecoverSpeed",
                isSpeed = true
            }
        },
        facilityFunc = {
            [1] = {
                name = "str_aircraft_func_power", --星能
                func = "GetPowerLimit",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_firefly_recover_speed", --萤火恢复速度
                func = "GetFireflyRecoverSpeed",
                isSpeed = true
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_func_power", --星能
                func = "GetPowerLimit",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_firefly_recover_speed", --萤火恢复速度
                func = "GetFireflyRecoverSpeed",
                isSpeed = true
            }
        }
    },
    [AirRoomType.MazeRoom] = {
        --秘境室
        roomFunc = {
            [1] = {
                name = "str_aircraft_func_MS_reset_time", --秘境重置倒计时
                func = "GetResetTime",
                countDown = true
            },
            [2] = {
                name = "str_aircraft_func_light_recover_speed", --ms恢复速度/小时
                func = "GetLightSpeed"
            },
            [3] = {
                name = "str_aircraft_maze_coin_increase_to", --旧卷碎片产量提升至
                func = "GetMazeCoinIncrease",
                isPercent = true
            }
        },
        facilityFunc = {
            [1] = {
                name = "str_aircraft_func_MS_reset_time", --秘境重置倒计时
                func = "GetResetTime",
                countDown = true
            },
            [2] = {
                name = "str_aircraft_func_light_recover_speed", --光盏恢复速度
                func = "GetLightSpeed"
            },
            [3] = {
                name = "str_aircraft_maze_coin_increase_to", --旧卷碎片产量提升至
                func = "GetMazeCoinIncrease",
                isPercent = true
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_func_light_recover_speed", --光盏恢复速度
                func = "GetLightSpeed"
            }
        }
    },
    [AirRoomType.ResourceRoom] = {
        --资源室
        roomFunc = {
            [1] = {
                name = "str_aircraft_func_double_coupon_store", --双倍券存储
                func = "GetResCardCount",
                isInt = true,
                specialTag = UIAircraftRoomFuncSpecailTag.DoubleCouponStore --特殊处理标志
            },
            [2] = {
                name = "str_aircraft_func_double_coupon_recover", --双倍券恢复
                func = "GetResCardLeftCDTime",
                countDown = true --显示倒计时
            }
        },
        facilityFunc = {
            [1] = {
                name = "str_aircraft_func_resource_level", --资源本等级
                func = "GetCoinDungeonLevel",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_double_coupon_store", --双倍券存储
                func = "GetResCardCount",
                isInt = true,
                specialTag = UIAircraftRoomFuncSpecailTag.DoubleCouponStore --特殊处理标志
            },
            [3] = {
                name = "str_aircraft_func_double_coupon_recover", --双倍券恢复
                func = "GetResCardLeftCDTime",
                countDown = true --显示倒计时
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_func_double_coupon_recover", --双倍券恢复速度加成百分比
                func = "GetResCardCD",
                isPercent = true, --显示带加号的百分比
                isNagative = true --是否为负面效果（负数时，为增益效果）
            },
            [2] = {
                name = "str_aircraft_func_double_coupon_store",
                func = "GetResCardLimit"
            }
        }
    },
    [AirRoomType.PrismRoom] = {
        --棱镜室
        roomFunc = {
            [1] = {
                name = "str_aircraft_func_phys_ceiling", --体力存储上限
                func = "GetPhysicStorageLimit",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_phys_recover_speed", --体力恢复速度
                func = "GetPhysicSpeed",
                isInt = false
            }
        },
        facilityFunc = {
            [1] = {
                name = "str_aircraft_func_phys_ceiling_added", --增加的体力上限
                func = "GetExPhysicLimit",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_phys_ceiling", --体力存储上限
                func = "GetPhysicStorageLimit",
                isInt = true
            },
            [3] = {
                name = "str_aircraft_func_phys_recover_speed", --体力恢复速度
                func = "GetPhysicSpeed",
                isInt = false
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_func_phys_ceiling", --体力存储上限
                func = "GetPhysicStorageLimit",
                isInt = true
            },
            [2] = {
                name = "str_aircraft_func_phys_recover_speed", --体力恢复速度
                func = "GetPhysicSpeed",
                isInt = false
            }
        }
    },
    [AirRoomType.TowerRoom] = {
        roomFunc = {
            [1] = {
                name = "str_aircraft_func_card_ceiling", --光尘存储
                func = "GetDrawCardCount",
                isInt = true,
                specialTag = UIAircraftRoomFuncSpecailTag.DrawCouponStore --特殊处理标志
            },
            [2] = {
                name = "str_aircraft_func_card_recover", --光尘每小时恢复
                func = "GetDrawCardSpeed"
            }
        },
        --灯塔室
        facilityFunc = {
            [1] = {
                name = "str_aircraft_func_card_ceiling", --光尘存储
                func = "GetDrawCardCount",
                isInt = true,
                specialTag = UIAircraftRoomFuncSpecailTag.DrawCouponStore --特殊处理标志
            },
            [2] = {
                name = "str_aircraft_func_card_recover", --光尘每小时恢复
                func = "GetDrawCardSpeed"
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_func_card_recover", --抽卡券恢复速度加成百分比
                func = "GetDrawCardSpeed"
            },
            [2] = {
                name = "str_aircraft_func_card_ceiling",
                func = "GetOutputLimit"
            }
        }
    },
    --熔炼室
    [AirRoomType.SmeltRoom] = {
        roomFunc = {
            [1] = {
                --原子剂存储
                name = "str_aircraft_atom_store",
                specialTag = UIAircraftRoomFuncSpecailTag.AtomStore
            },
            [2] = {
                --原子剂每小时恢复
                name = "str_aircraft_atom_recover_speed",
                func = "GetOneSpeed"
            },
            [3] = {
                --折扣
                name = "str_aircraft_atom_discount",
                specialTag = UIAircraftRoomFuncSpecailTag.AtomDiscount
            }
        },
        facilityFunc = {
            [1] = {
                --原子剂存储
                name = "str_aircraft_atom_store",
                specialTag = UIAircraftRoomFuncSpecailTag.AtomStore
            },
            [2] = {
                --原子剂每小时恢复
                name = "str_aircraft_atom_recover_speed",
                func = "GetOneSpeed"
            },
            [3] = {
                --文本提示
                specialTag = UIAircraftRoomFuncSpecailTag.SmeltRoomTip
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_atom_discount",
                specialTag = UIAircraftRoomFuncSpecailTag.AtomDiscount
            }
        }
    },
    --派遣室
    [AirRoomType.DispatchRoom] = {
        roomFunc = {
            [1] = {
                --可派遣次数
                name = "str_dispatch_room_dispatch_count",
                specialTag = UIAircraftRoomFuncSpecailTag.DispatchCount
            },
            [2] = {
                --下次派遣回复
                name = "str_dispatch_room_dispatch_recover",
                func = "GetSurplusSecond",
                countDown = true
            },
            [3] = {
                --同时派遣队伍
                name = "str_dispatch_room_dispatch_team",
                specialTag = UIAircraftRoomFuncSpecailTag.DispatchTeam
            }
        },
        facilityFunc = {
            [1] = {
                --派遣次数上限
                name = "str_dispatch_room_dispatch_max_count",
                specialTag = UIAircraftRoomFuncSpecailTag.DispatchMaxCount
            },
            [2] = {
                --恢复1次派遣
                name = "str_dispatch_room_recover_one_dispatch",
                specialTag = UIAircraftRoomFuncSpecailTag.DispatchRecoverOne
            },
            [3] = {
                --任务最高星级
                name = "str_dispatch_room_task_max_star",
                specialTag = UIAircraftRoomFuncSpecailTag.DispatchTaskMaxStr
            }
        },
        settleFunc = {
            [1] = {
                name = "str_dispatch_room_dispatch_recover_speed_up",
                specialTag = UIAircraftRoomFuncSpecailTag.DispatchRecoverSpeedUp
            }
        }
    },
    ---战术室
    [AirRoomType.TacticRoom] = {
        --战术室
        roomFunc = {
            [1] = {
                name = "str_aircraft_tactic_tape_storage", --战例卡带存储
                specialTag = UIAircraftRoomFuncSpecailTag.TapeStorage --特殊处理标志
            },
            [2] = {
                name = "str_aircraft_tactic_tape_production", --卡带制造倒计时
                specialTag = UIAircraftRoomFuncSpecailTag.TapeCountdown --特殊处理标志
            },
            [3] = {
                name = "str_aircraft_tactic_weekly_free_make_times", --每周免费制造次数
                func = "GetWeeklyFreeMakeLimit",
                isInt = true --整数
            }
        },
        facilityFunc = {
            [1] = {
                name = "str_aircraft_tactic_tape_storage", --战例卡带存储
                specialTag = UIAircraftRoomFuncSpecailTag.TapeStorage --特殊处理标志
            },
            [2] = {
                name = "str_aircraft_tactic_tape_production", --卡带制造倒计时
                func = "GetCartridgeDeltaTime",
                countDown = true --显示倒计时,不用特殊处理
            },
            [3] = {
                name = "str_aircraft_tactic_weekly_free_make_times", --每周免费制造次数
                func = "GetWeeklyFreeMakeLimit",
                isInt = true --整数
            }
        },
        settleFunc = {
            [1] = {
                name = "str_aircraft_tactic_make_speedup", --加速卡带制造
                specialTag = UIAircraftRoomFuncSpecailTag.TacticWorkSkill --特殊处理标志
            }
        }
    },
    [AirRoomType.RestRoom] = {
        roomFunc = {}
    },
    [AirRoomType.CoffeeRoom] = {
        roomFunc = {}
    },
    [AirRoomType.WaterBarRoom] = {
        roomFunc = {}
    },
    [AirRoomType.GameRoom] = {
        roomFunc = {}
    }
}
