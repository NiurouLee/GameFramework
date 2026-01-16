AutoTest_211216_120102={
cases = {
	[1] = {
		[1] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[2] = {
			action = "SetTeamPosition",
			args = {
				name = "team",
				pos = 502,
				},
			},
		[3] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2071413,
				name = "e1",
				pos = 108,
				},
			},
		[4] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = ">",
				name = "e1",
				trigger = 88,
				},
			},
		[5] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "damagePercent",
				attr_select_index = 8,
				defname = "e1",
				key = "CalcDamage_5",
				key_select_index = 8,
				skillid = 323116,
				trigger = 102,
				varname = "v2",
				},
			},
		[6] = {
			action = "CheckLocalValue",
			args = {
				target = 2.4000000953674,
				trigger = 88,
				varname = "v2",
				},
			},
		[7] = {
			action = "FakeCastSkill",
			args = {
				name = "p1",
				pickUpPos = {
					[1] = 108.0,
					},
				},
			},
		[8] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[9] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2071413,
				name = "e2",
				pos = 402,
				},
			},
		[10] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2071413,
				name = "e3",
				pos = 603,
				},
			},
		[11] = {
			action = "AddMonster",
			args = {
				dir = 1,
				disableai = true,
				id = 2071413,
				name = "e4",
				pos = 604,
				},
			},
		[12] = {
			action = "CaptureFormulaAttr",
			args = {
				attr = "damagePercent",
				attr_select_index = 8,
				defname = "e4",
				key = "CalcDamage_106",
				key_select_index = 28,
				skillid = 2061161,
				trigger = 102,
				varname = "v1",
				},
			},
		[13] = {
			action = "CheckLocalValue",
			args = {
				target = 0.5,
				trigger = 88,
				varname = "v1",
				},
			},
		[14] = {
			action = "FakeInputChain",
			args = {
				chainPath = {
					[1] = 502.0,
					[2] = 602.0,
					[3] = 601.0,
					[4] = 501.0,
					[5] = 401.0,
					},
				pieceType = 1,
				},
			},
		[15] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		name = "突3：主动强化：伤害系数提高40%  突6连锁技强化：溅射伤害的系数提高到50%",
		},
	},
name = "费劳尔突3突6",
petList = {
	[1] = {
		awakening = 6,
		equiplv = 1,
		grade = 3,
		id = 1601161,
		level = 1,
		name = "p1",
		},
	},
remotePet = {},
setup = {
	[1] = {
		args = {
			levelID = 1,
			matchType = 1,
			},
		setup = "LevelBasic",
		},
	},
}