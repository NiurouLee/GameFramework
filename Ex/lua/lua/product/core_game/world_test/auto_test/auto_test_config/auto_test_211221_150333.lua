AutoTest_211221_150333={
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
			action = "SetTeamPowerFull",
			args = {
				name = "team",
				name_select_index = 0,
				},
			},
		[4] = {
			action = "SetEntityHPPercent",
			args = {
				name = "team",
				percent = 0.5,
				},
			},
		[5] = {
			action = "AddTrap",
			args = {
				dir = 1,
				disableai = true,
				id = 2012,
				name = "j1",
				pos = 503,
				},
			},
		[6] = {
			action = "CheckGridTrap",
			args = {
				exist = false,
				pos = 503,
				trapIds = {
					[1] = 2001.0,
					},
				trigger = 88,
				},
			},
		[7] = {
			action = "FakeCastSkill",
			args = {
				name = "p1",
				pickUpPos = {
					[1] = 502.0,
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
			action = "CheckGridTrap",
			args = {
				exist = true,
				pos = 503,
				trapIds = {
					[1] = 2001.0,
					},
				trigger = 88,
				},
			},
		[10] = {
			action = "FakeCastSkill",
			args = {
				name = "p2",
				pickUpPos = {
					[1] = 502.0,
					},
				},
			},
		[11] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		[12] = {
			action = "CheckEntityChangeHP",
			args = {
				compare = "<",
				name = "team",
				trigger = 88,
				},
			},
		[13] = {
			action = "FakeInputChain",
			args = {
				chainPath = {
					[1] = 502.0,
					[2] = 503.0,
					},
				pieceType = 1,
				},
			},
		[14] = {
			action = "WaitGameFsm",
			args = {
				id = 5,
				},
			},
		name = "碎石掉绷带，回血",
		},
	},
name = "碎石掉绷带，回血",
petList = {
	[1] = {
		awakening = 0,
		equiplv = 1,
		grade = 0,
		id = 1601051,
		level = 1,
		name = "p1",
		},
	[2] = {
		awakening = 0,
		equiplv = 1,
		grade = 0,
		id = 1400831,
		level = 1,
		name = "p2",
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