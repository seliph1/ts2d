local enum = {}

enum.ENTITY_TYPE={
	[0]="Info_T",
	[1]="Info_CT",
	[2]="Info_VIP",
	[3]="Info_Hostage",
	[4]="Info_RescuePoint",
	[5]="Info_BombSpot",
	[6]="Info_EscapePoint",
	[7]="Info_Target",
	[8]="Info_Animation",
	[9]="Info_Storm",
	[10]="Info_TileFX",
	[11]="Info_NoBuying",
	[12]="Info_NoWeapons",
	[13]="Info_NoFOW",
	[14]="Info_Quake",
	[15]="Info_CTF_Flag",
	[16]="Info_OldRender",
	[17]="Info_Dom_Point",
	[18]="Info_NoBuildings",
	[19]="Info_BotNode",
	[20]="Info_TeamGate",
	[21]="Env_Item",
	[22]="Env_Sprite",
	[23]="Env_Sound",
	[24]="Env_Decal",
	[25]="Env_Breakable",
	[26]="Env_Explode",
	[27]="Env_Hurt",
	[28]="Env_Image",
	[29]="Env_Object",
	[30]="Env_Building",
	[31]="Env_NPC",
	[32]="Env_Room",
	[33]="Env_Light",
	[34]="Env_LightStripe",
	[35]="Env_Cube3D",
	[50]="Gen_Particles",
	[51]="Gen_Sprites",
	[52]="Gen_Weather",
	[53]="Gen_FX",
	[70]="Func_Teleport",
	[71]="Func_DynWall",
	[72]="Func_Message",
	[73]="Func_GameAction",
	[80]="Info_NoWeather",
	[81]="Info_RadarIcon",
	[90]="Trigger_Start",
	[91]="Trigger_Move",
	[92]="Trigger_Hit",
	[93]="Trigger_Use",
	[94]="Trigger_Delay",
	[95]="Trigger_Once",
	[96]="Trigger_If"
}

enum.itemname = {
	["USP"]=1;
	["GLOCK"]=2;
	["DEAGLE"]=3;
	["P228"]=4;
	["ELITE"]=5;
	["FIVE-SEVEN"]=6;
	["M3"]=10;
	["XM1014"]=11;
	["MP5"]=20;
	["TMP"]=21;
	["P90"]=22;
	["MAC 10"]=23;
	["UMP45"]=24;
	["AK-47"]=30;
	["SG552"]=31;
	["M4A1"]=32;
	["AUG"]=33;
	["SCOUT"]=34;
	["AWP"]=35;
	["G3SG1"]=36;
	["SG550"]=37;
	["GALIL"]=38;
	["FAMAS"]=39;
	["M249"]=40;
	["TACTICAL SHIELD"]=41;
	["SHIELD"]=41;
	["LASER"]=45;
	["FLAMETHROWER"]=46;
	["RPG LAUNCHER"]=47;
	["ROCKET LAUNCHER"]=48;
	["GRENADE LAUNCHER"]=49;
	["HE"]=51;
	["FLASHBANG"]=52;
	["SMOKE GRENADE"]=53;
	["SMOKE"]=53;
	["FLARE"]=54;
	["DEFUSE KIT"]=56;
	["KEVLAR"]=57;
	["KEVLAR+HELM"]=58;
	["NIGHT VISION"]=59;
	["GAS MASK"]=60;
	["PRIMARY AMMO"]=61;
	["SECONDARY AMMO"]=62;
	["MEDIKIT"]=64;
	["BANDAGE"]=65;
	["COINS"]=66;
	["MONEY"]=67;
	["GOLD"]=68;
	["MACHETE"]=69;
	["GAS GRENADE"]=72;
	["GAS"]=72;
	["MOLOTOV COCKTAIL"]=73;
	["MOLOTOV"]=73;
	["WRENCH"]=74;
	["SNOWBALL"]=75;
	["AIR STRIKE"]=76;
	["MINE"]=77;
	["CLAW"]=78;
	["LIGHT ARMOR"]=79;
	["ARMOR"]=80;
	["HEAVY ARMOR"]=81;
	["MEDIC ARMOR"]=82;
	["SUPER ARMOR"]=83;
	["STEALTH SUIT"]=84;
	["STEALTH ARMOR"]=84;
	["STEALTH"]=84;
	["CHAINSAW"]=85;
	["GUT BOMB"]=86;
	["LASER MINE"]=87;
	["PORTAL GUN"]=88;
	["PORTAL"]=88;
	["SATCHEL CHARGE"]=89;
	["SATCHEL"]=89;
	["M134"]=90;
	["FN F2000"]=91;
	["TESLA"]=92;
}

enum.items = {
	[1] = {
		name = "USP", -- Display name
		alt_name = "Heckler & Koch USP", -- Name gotten from external source (wikipedia, etc)
		internal_name = "usp", -- Name used internally by code
		category = "secondary", -- Category (primary, secondary, melee, armor, throwable, other [example of other: flag, bomb, medikit] )
		price = 500, -- Value in shop menu
		damage = 24, -- Damage
		ammo_cap = 100, -- Reserve ammo 
		ammo_mag = 12, -- Ammo in magazine
		rate_of_fire = 9, -- Frame delay 
		range = 300, -- Range in pixels 
		weight = 900, -- real-life weight of this weapon, gotten from wikipedia or something
		accuracy = 100,  -- Accuracy in percentage (100% = perfect, decreases by 10% for every point in https://www.cs2d.com/weapons.php)
		common_path = "gfx/weapons/", -- Weapon image source directory
		dropped_image = "usp_d.bmp", -- Dropped image
		held_image = "usp.bmp", -- Held (in hand or worn) image
		display_image = "usp_m.bmp", -- Image that appears when buying
		kill_image = "usp_k.bmp", -- Small icon that appears on the kill log on the top right corner
		player_stance = "handgun", -- Which player sprite should appear when holding/wearing this item (stances: handgun, rifle, melee, object, armor, zombie, nothing)
	};
	
	[30] = {
		name = "AK-47",
		alt_name = "Avtomat Kalashnikova",
		internal_name = "ak47",
		category = "primary",
		price = 2500,
		damage = 22,
		ammo_cap = 90,
		ammo_mag = 30,
		rate_of_fire = 3,
		range = 300,
		weight = 3470,
		accuracy = 70, 
		common_path = "gfx/weapons/",
		dropped_image = "ak47_d.bmp",
		held_image = "ak47.bmp",
		kill_image = "ak47_k.bmp",
		display_image = "ak47_m.bmp", 
		player_stance = "rifle",
		acessory = {};
	};
	
	[32] = {
		name = "M4A1",
		alt_name = "M4A1 Carbine",
		internal_name = "m4a1",
		category = "primary",
		price = 3100,
		damage = 22,
		ammo_cap = 90,
		ammo_mag = 30,
		rate_of_fire = 3,
		range = 300,
		weight = 3520,
		accuracy = 80, 
		common_path = "gfx/weapons/",
		dropped_image = "m4a1_d.bmp",
		held_image = "m4a1.bmp",
		display_image = "m4a1_m.bmp", 
		kill_image = "m4a1_k.bmp",
		player_stance = "rifle",
		acessory = {
			silencer_image = "m4a1_silenced.bmp",
		};
	};
}


enum.item_default = {
	name = "Default Object",
	alt_name = "Default Object",
	internal_name = "default",
	category = "other",
	price = 0,
	damage = 0,
	ammo_cap = 0,
	ammo_mag = 0,
	rate_of_fire = 0,
	range = 0,
	weight = 0,
	accuracy = 0, 
	common_path = "gfx/weapons/",
	dropped_image = "",
	held_image = "",
	display_image = "", 
	kill_image = "",
	player_stance = "object",
	acessory = {};
}

enum.items_meta = {
	__index = function(t, k)
		return enum.item_default
	end
}
setmetatable(enum.items, enum.items_meta)

enum.npc = {
	[1] = {"Zombie", 150}, -- Zombie
	[2] = {"Headcrab", 30},  -- Headcrab
	[3] = {"Snark", 20},  -- Snark
	[4] = {"Vortigaunt", 200}, -- Vortigaunt
	[5] = {"Soldier", 100}, -- Soldier
}


return enum