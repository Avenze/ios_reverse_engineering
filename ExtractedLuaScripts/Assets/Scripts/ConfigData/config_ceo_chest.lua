local config_ceo_chest = {
	["free"] = {
		["chest_content"] = "1727:1,1725:1",
		["chest_cooltime"] = 30,
		["chest_desc"] = "TXT_CEO_CHEST_FREE_DESC",
		["chest_icon"] = "icon_ceo_chest_free",
		["chest_limit"] = 3,
		["chest_name"] = "TXT_CEO_CHEST_FREE_NAME",
		["chest_prefab"] = "CEO_chest_free",
		["chest_type"] = "free",
		["id"] = 1,
	}
	,
	["normal"] = {
		["chest_content"] = "1727:3,1726:1",
		["chest_cooltime"] = 0,
		["chest_desc"] = "TXT_CEO_CHEST_NORMAL_DESC",
		["chest_icon"] = "icon_ceo_chest_normal",
		["chest_key_require"] = "normal:10",
		["chest_limit"] = 0,
		["chest_name"] = "TXT_CEO_CHEST_NORMAL_NAME",
		["chest_prefab"] = "CEO_chest_normal",
		["chest_type"] = "normal",
		["id"] = 2,
	}
	,
	["premium"] = {
		["chest_content"] = "1728:2,1729:100",
		["chest_cooltime"] = 0,
		["chest_desc"] = "TXT_CEO_CHEST_PREMIUM_DESC",
		["chest_icon"] = "icon_ceo_chest_premium",
		["chest_key_require"] = "premium:10",
		["chest_limit"] = 0,
		["chest_name"] = "TXT_CEO_CHEST_PREMIUM_NAME",
		["chest_prefab"] = "CEO_chest_premium",
		["chest_type"] = "premium",
		["id"] = 3,
	}
	,
}
return config_ceo_chest