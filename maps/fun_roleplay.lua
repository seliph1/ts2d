RP_LUA = true
UTSFX_SILENCED = true
NPC_PROTECTION = false

parse("sv_gamemode 1")
parse("mp_buytime 0")
parse("mp_randomspawn 0")
parse("mp_radar 0")
parse("mp_hud 27")
parse("bot_add_t")
parse("bot_add_ct")
parse("bot_freeze 0")
parse("sv_forcelight 1")
parse("mp_deathdrop 0")
parse("mp_supply_items 66,,,,,,67")
parse("mp_weaponfadeout 60")
parse("mp_killteambuildings 1")
timer(2000,"parse", "mp_randomspawn 0")
timer(500,"parse", "bot_freeze 1")
--parse("trigger light")