local config_dialog = {
	[1] = {
		["dialog_cooltime"] = 40,
		["dialog_probility"] = 100,
		["id"] = 1,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_HIGHMOOD1",
			[2] = "TXT_DIALOG_HIGHMOOD2",
			[3] = "TXT_DIALOG_HIGHMOOD3",
			[4] = "TXT_DIALOG_HIGHMOOD4",
		}
		,
		["type"] = 1,
	}
	,
	[2] = {
		["dialog_cooltime"] = 600,
		["dialog_probility"] = 20,
		["id"] = 2,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_ENOUGH_FURNITURE1",
			[2] = "TXT_DIALOG_ENOUGH_FURNITURE2",
			[3] = "TXT_DIALOG_ENOUGH_FURNITURE3",
			[4] = "TXT_DIALOG_ENOUGH_FURNITURE4",
		}
		,
		["type"] = 2,
	}
	,
	[3] = {
		["dialog_cooltime"] = 120,
		["dialog_probility"] = 50,
		["id"] = 3,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_LACK_FURNITURE1",
			[2] = "TXT_DIALOG_LACK_FURNITURE2",
			[3] = "TXT_DIALOG_LACK_FURNITURE3",
			[4] = "TXT_DIALOG_LACK_FURNITURE4",
		}
		,
		["type"] = 3,
	}
	,
	[4] = {
		["dialog_cooltime"] = 60,
		["dialog_probility"] = 20,
		["id"] = 4,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_DESIRE_ROOM1",
			[2] = "TXT_DIALOG_DESIRE_ROOM2",
			[3] = "TXT_DIALOG_DESIRE_ROOM3",
			[4] = "TXT_DIALOG_DESIRE_ROOM4",
		}
		,
		["room_index"] = {
			[1] = "MeetingRoom_101",
			[2] = "RestRoom_106",
			[3] = "EntertainmentRoom_107",
			[4] = "Gym_110",
		}
		,
		["type"] = 4,
	}
	,
	[5] = {
		["dialog_probility"] = 30,
		["id"] = 5,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_LVL%s_EVALUATION1",
			[2] = "TXT_DIALOG_LVL%s_EVALUATION2",
		}
		,
		["type"] = 5,
	}
	,
	[6] = {
		["dialog_cooltime"] = 20,
		["dialog_probility"] = 50,
		["id"] = 6,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_WAITING1",
			[2] = "TXT_DIALOG_WAITING2",
			[3] = "TXT_DIALOG_WAITING3",
		}
		,
		["type"] = 6,
	}
	,
	[7] = {
		["dialog_probility"] = 100,
		["id"] = 7,
		["npc_dialog"] = {
			[1] = "TXT_DIALOG_COMPLAIN1",
			[2] = "TXT_DIALOG_COMPLAIN2",
			[3] = "TXT_DIALOG_COMPLAIN3",
		}
		,
		["type"] = 7,
	}
	,
}
return config_dialog