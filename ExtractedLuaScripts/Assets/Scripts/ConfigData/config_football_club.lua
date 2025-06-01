local config_football_club = {
	[50001] = {
		[10001] = {
			["clubId"] = 50001,
			["comment"] = "管理中心",
			["desc"] = "TXT_FBCLUB_101_13_DESC",
			["icon"] = "icon_building_50001_2",
			["id"] = 10001,
			["name"] = "TXT_FBCLUB_10001_NAME",
			["objName"] = "ClubCenter",
			["room"] = "ClubCenter_sfx",
			["unlockRequire"] = 0,
			["unlockRoom"] = 0,
			["unlockTime"] = 0,
		}
		,
		[10002] = {
			["clubId"] = 50001,
			["comment"] = "俱乐部球馆",
			["desc"] = "TXT_FBCLUB_102_15_DESC",
			["icon"] = "icon_building_50002",
			["id"] = 10002,
			["name"] = "TXT_FBCLUB_10002_NAME",
			["objName"] = "Stadium",
			["room"] = "Stadium_sfx",
			["unlockRequire"] = 0,
			["unlockRoom"] = 0,
			["unlockTime"] = 0,
		}
		,
		[10003] = {
			["clubId"] = 50001,
			["comment"] = "训练场",
			["desc"] = "TXT_FBCLUB_103_8_DESC",
			["icon"] = "icon_building_50003",
			["id"] = 10003,
			["name"] = "TXT_FBCLUB_10003_NAME",
			["objName"] = "TrainingGround",
			["room"] = "TrainingGround_sfx",
			["unlockRequire"] = 100000,
			["unlockRoom"] = 10002,
			["unlockTime"] = 60,
		}
		,
		[10005] = {
			["clubId"] = 50001,
			["comment"] = "保健中心",
			["desc"] = "TXT_FBCLUB_105_1_DESC",
			["icon"] = "icon_building_50005",
			["id"] = 10005,
			["name"] = "TXT_FBCLUB_10005_NAME",
			["objName"] = "HealthCenter",
			["room"] = "HealthCenter_sfx",
			["unlockRequire"] = 100000,
			["unlockRoom"] = 10002,
			["unlockTime"] = 60,
		}
		,
	}
	,
}
return config_football_club