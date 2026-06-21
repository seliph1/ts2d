-- CS2D Lua Hooks
-- Auto-generated hook functions based on CS2D documentation

--timer(1000, "parse", -1, "msg hello")
do return end

addhook("always", "Hook_always")
function Hook_always()
  --print("always")
end

addhook("assist", "Hook_assist")
function Hook_assist(killer_id, victim_id, weapon_id)
  print("assist")
end

addhook("attack", "Hook_attack")
function Hook_attack(id)
  --print(string.format("Player [ID: %s] attacked!", id))
end

addhook("attack2", "Hook_attack2")
function Hook_attack2(id, mode)
end

addhook("bombdefuse", "Hook_bombdefuse")
function Hook_bombdefuse(id, x, y)
  print("bombdefuse")
end

addhook("bombexplode", "Hook_bombexplode")
function Hook_bombexplode(x, y, player_id)
  print("bombexplode")
end

addhook("bombplant", "Hook_bombplant")
function Hook_bombplant(id, x, y)
  print("bombplant")
end

addhook("break", "Hook_break")
function Hook_break(x, y, object_id, player_id)
  print("break")
end

addhook("build", "Hook_build")
function Hook_build(id, type, x, y, mode, object_id)
  print("build")
end

addhook("buildattempt", "Hook_buildattempt")
function Hook_buildattempt(id, type, x, y, mode)
  print("buildattempt")
end

addhook("buy", "Hook_buy")
function Hook_buy(id, weapon_id)
  print("buy")
end

addhook("clientdata", "Hook_clientdata")
function Hook_clientdata(id, data_type, data1, data2)
  print("clientdata")
end

addhook("clientsetting", "Hook_clientsetting")
function Hook_clientsetting(id, setting_name, value)
  print("clientsetting")
end

addhook("collect", "Hook_collect")
function Hook_collect(id, item_id, item_type, x, y)
  print("collect")
end

addhook("connect", "Hook_connect")
function Hook_connect(id)
  print("connect")
end

addhook("connect_attempt", "Hook_connect_attempt")
function Hook_connect_attempt(ip, port, name, password)
  print("connect_attempt")
end

addhook("connect_initplayer", "Hook_connect_initplayer")
function Hook_connect_initplayer(id)
  print("connect_initplayer")
end

addhook("die", "Hook_die")
function Hook_die(victim_id, killer_id, weapon_id, x, y)
  --print("die")
end

addhook("disconnect", "Hook_disconnect")
function Hook_disconnect(id, reason)
  --print("disconnect")
end

addhook("dominate", "Hook_dominate")
function Hook_dominate(killer_id, victim_id)
  print("dominate")
end

addhook("drop", "Hook_drop")
function Hook_drop(id, item_id, item_type, x, y)
  print("drop")
end

addhook("endround", "Hook_endround")
function Hook_endround(mode)
  print("endround")
end

addhook("flagcapture", "Hook_flagcapture")
function Hook_flagcapture(id, team, x, y)
  print("flagcapture")
end

addhook("flagtake", "Hook_flagtake")
function Hook_flagtake(id, team, x, y)
  print("flagtake")
end

addhook("flashlight", "Hook_flashlight")
function Hook_flashlight(id, mode)
  print("flashlight")
end

addhook("hit", "Hook_hit")
function Hook_hit(victim_id, source_id, weapon_id, damage, armor_damage)
  --print("hit")
end

addhook("hitzone", "Hook_hitzone")
function Hook_hitzone(id, zone)
  print("hitzone")
end

addhook("hostagedamage", "Hook_hostagedamage")
function Hook_hostagedamage(hostage_id, damage, source_id, weapon_id)
  print("hostagedamage")
end

addhook("hostagekill", "Hook_hostagekill")
function Hook_hostagekill(hostage_id, killer_id, weapon_id)
  print("hostagekill")
end

addhook("hostagerescue", "Hook_hostagerescue")
function Hook_hostagerescue(id, hostage_id)
  print("hostagerescue")
end

addhook("hostageuse", "Hook_hostageuse")
function Hook_hostageuse(id, hostage_id, mode)
  print("hostageuse")
end

addhook("httpdata", "Hook_httpdata")
function Hook_httpdata(id, length, data)
  print("httpdata")
end

addhook("itemfadeout", "Hook_itemfadeout")
function Hook_itemfadeout(item_id, x, y)
  print("itemfadeout")
end

addhook("join", "Hook_join")
function Hook_join(id, team)
  --print("join")
end

addhook("key", "Hook_key")
function Hook_key(id, key, state)
  print("key")
end

addhook("kill", "Hook_kill")
function Hook_kill(killer_id, victim_id, weapon_id, x, y)
  --print("kill")
end

addhook("leave", "Hook_leave")
function Hook_leave(id, team)
  --print("leave")
end

addhook("log", "Hook_log")
function Hook_log(text)
  print("log")
end

addhook("mapchange", "Hook_mapchange")
function Hook_mapchange(map_name)
  print("mapchange")
end

addhook("menu", "Hook_menu")
function Hook_menu(id, menu_title, button_id)
  print("menu")
end

addhook("minute", "Hook_minute")
function Hook_minute()
  --print("minute")
end

addhook("move", "Hook_move")
function Hook_move(id, x, y, walk)
  --print("move")
end

addhook("movetile", "Hook_movetile")
function Hook_movetile(id, tile_x, tile_y)
  --print("movetile")
end

addhook("ms100", "Hook_ms100")
function Hook_ms100()
  --print("ms100")
end

addhook("name", "Hook_name")
function Hook_name(id, old_name, new_name)
  print("name")
end

addhook("objectdamage", "Hook_objectdamage")
function Hook_objectdamage(object_id, damage, source_id, weapon_id)
  print("objectdamage")
end

addhook("objectkill", "Hook_objectkill")
function Hook_objectkill(object_id, killer_id, weapon_id)
  print("objectkill")
end

addhook("objectupgrade", "Hook_objectupgrade")
function Hook_objectupgrade(object_id, new_level)
  print("objectupgrade")
end

addhook("parse", "Hook_parse")
function Hook_parse(text)
  --print("parse")
end

addhook("projectile", "Hook_projectile")
function Hook_projectile(owner_id, weapon_id, x, y)
  print("projectile")
end

addhook("projectile_impact", "Hook_projectile_impact")
function Hook_projectile_impact(projectile_id, x, y, tile_x, tile_y)
  print("projectile_impact")
end

addhook("radio", "Hook_radio")
function Hook_radio(id, radio_message)
  print("radio")
end

addhook("rcon", "Hook_rcon")
function Hook_rcon(text)
  print("rcon")
end

addhook("reload", "Hook_reload")
function Hook_reload(id)
  print("reload")
end

addhook("say", "Hook_say")
function Hook_say(id, text)
  --print(id, "says :", text)
end

addhook("sayteam", "Hook_sayteam")
function Hook_sayteam(id, text)
  print("sayteam")
end

addhook("sayteamutf8", "Hook_sayteamutf8")
function Hook_sayteamutf8(id, text)
  print("sayteamutf8")
end

addhook("sayutf8", "Hook_sayutf8")
function Hook_sayutf8(id, text)
end

addhook("second", "Hook_second")
function Hook_second()
  --print("second")
end

addhook("select", "Hook_select")
function Hook_select(id, weapon_type, mode)
  --print("select")
end

addhook("serveraction", "Hook_serveraction")
function Hook_serveraction(id, action)
  print("serveraction")
end

addhook("shieldhit", "Hook_shieldhit")
function Hook_shieldhit(id, source_id, weapon_id, damage)
  print("shieldhit")
end

addhook("shutdown", "Hook_shutdown")
function Hook_shutdown()
  print("shutdown")
end

addhook("spawn", "Hook_spawn")
function Hook_spawn(id, x, y)
  --print("spawn")
end

addhook("specswitch", "Hook_specswitch")
function Hook_specswitch(id, mode)
  print("specswitch")
end

addhook("spray", "Hook_spray")
function Hook_spray(id)
  print("spray")
end

addhook("startround", "Hook_startround")
function Hook_startround(mode)
  print("startround")
end

addhook("startround_prespawn", "Hook_startround_prespawn")
function Hook_startround_prespawn(mode)
  print("startround_prespawn")
end

addhook("suicide", "Hook_suicide")
function Hook_suicide(id)
  print("suicide")
end

addhook("team", "Hook_team")
function Hook_team(id, team, look)
  print("team")
end

addhook("trigger", "Hook_trigger")
function Hook_trigger(trigger_name, source_id)
  print("trigger")
end

addhook("triggerentity", "Hook_triggerentity")
function Hook_triggerentity(entity_name, source_id)
  print("triggerentity")
end

addhook("turretscan", "Hook_turretscan")
function Hook_turretscan(object_id, player_id)
  print("turretscan")
end

addhook("use", "Hook_use")
function Hook_use(id, event, data, x, y)
  print(id, event, data, x, y)
end

addhook("usebutton", "Hook_usebutton")
function Hook_usebutton(id, x, y)
  print("usebutton")
end

addhook("vipescape", "Hook_vipescape")
function Hook_vipescape(id, x, y)
  print("vipescape")
end

addhook("voice", "Hook_voice")
function Hook_voice(id, mode)
  print("voice")
end

addhook("vote", "Hook_vote")
function Hook_vote(text)
  print("vote")
end

addhook("walkover", "Hook_walkover")
function Hook_walkover(id, item_id, item_type, x, y)
  print("walkover")
end
