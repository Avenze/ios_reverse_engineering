local config_emergency = {
	[200] = {
		["cd"] = 600,
		["emergency_3d"] = {
			[1] = "PoweroffUI",
			[3] = "PoweroffUI",
			[8] = "PoweroffUI",
			[9] = "PoweroffUI",
		}
		,
		["emergency_ui"] = {
			[1] = "PowerOff",
			[3] = "PowerOff",
			[8] = "PowerOff",
			[9] = "PowerOff",
		}
		,
		["happen_probility"] = function(n) return n-50 end,
		["happen_threshold"] = 100,
		["id"] = 200,
		["room_category"] = {
			[1] = 1,
			[2] = 3,
			[3] = 8,
			[4] = 9,
		}
		,
		["room_category_tag"] = 778,
		["room_node"] = {
			[1] = "PowerOff",
			[3] = "PowerOff",
			[8] = "PowerOff",
			[9] = "PowerOff",
		}
		,
	}
	,
	[201] = {
		["cd"] = 600,
		["emergency_3d"] = {
			[3] = "OverheatUI",
			[4] = "LeakageUI",
			[8] = "FacilityDamageUI",
			[9] = "FacilityDamageUI",
		}
		,
		["emergency_ui"] = {
			[3] = "OverHeat",
			[4] = "WaterLeakage",
			[8] = "FacilityDamage",
			[9] = "FacilityDamage",
		}
		,
		["happen_probility"] = function(n) return (n-60)*3 end,
		["happen_threshold"] = 60,
		["id"] = 201,
		["random_interval"] = 5,
		["room_category"] = {
			[1] = 3,
			[2] = 4,
			[3] = 8,
			[4] = 9,
		}
		,
		["room_category_tag"] = 792,
		["room_node"] = {
			[3] = "OverHeat",
			[4] = "WaterLeakage",
			[8] = "FacilityDamage",
			[9] = "FacilityDamage",
		}
		,
	}
	,
	[202] = {
		["cd"] = 600,
		["emergency_3d"] = {
			[1] = "NetoffUI",
		}
		,
		["emergency_ui"] = {
			[1] = "NetOff",
		}
		,
		["happen_probility"] = function(n) return (n-1550)/15 end,
		["happen_threshold"] = 1600,
		["id"] = 202,
		["random_interval"] = 100,
		["room_category"] = {
			[1] = 1,
		}
		,
		["room_category_tag"] = 2,
		["room_node"] = {
			[1] = "NetOff",
		}
		,
	}
	,
}
return config_emergency