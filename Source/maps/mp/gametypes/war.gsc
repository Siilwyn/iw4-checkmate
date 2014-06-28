// Checkmate by Siilwyn
// Thanks to the community at http://itsmods.com/

// https://github.com/Siilwyn/iw4-checkmate/
// Version 0.1

#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::SetupCallBacks();
    maps\mp\gametypes\_globallogic::SetupCallBacks();
    
    registerTimeLimitDvar(level.gameType, 10, 0, 1440);
    registerScoreLimitDvar(level.gameType, 500, 0, 5000);
    registerRoundLimitDvar(level.gameType, 1, 0, 10);
    registerWinLimitDvar(level.gameType, 1, 0, 10);
    registerRoundSwitchDvar(level.gameType, 3, 0, 30);
    registerNumLivesDvar(level.gameType, 0, 0, 10);
    registerHalfTimeDvar(level.gameType, 0, 0, 1);
    
    level.teamBased = true;
    level.onPrecacheGameType = ::onPrecacheGameType;
    level.onStartGameType = ::onStartGameType;
    level.getSpawnPoint = ::getSpawnPoint;
    level.onPlayerKilled = ::onPlayerKilled;
    
    game["dialog"]["gametype"] = "tm_death_pro";
    
    if(getDvarInt("g_hardcore"))
        game["dialog"]["gametype"] = "hc_tm_death_pro";
    else if(getDvarInt("camera_thirdPerson"))
        game["dialog"]["gametype"] = "thirdp_tm_death_pro";
}

onPrecacheGameType()
{
    game["headicon_allies"] = maps\mp\gametypes\_teams::getTeamHeadIcon("allies");
    precacheHeadIcon(game["headicon_allies"]);
}

onStartGameType()
{
    setClientNameMode("auto_change");
    
    if(!isdefined(game["switchedsides"]))
        game["switchedsides"] = false;
    
    if(game["switchedsides"])
    {
        oldAttackers = game["attackers"];
        oldDefenders = game["defenders"];
        game["attackers"] = oldDefenders;
        game["defenders"] = oldAttackers;
    }
    
    setObjectiveText("allies", "Keep the king alive!");
    setObjectiveText("axis", "Kill the king and his guards.");
    setObjectiveScoreText("allies", "Protect the king and survive to win.");
    setObjectiveScoreText("axis", "Assassinate the king and kill his guards for support.");
    setObjectiveHintText("allies", "Keep the king alive at any cost.");
    setObjectiveHintText("axis", "Eliminate the king!");
    
    setDvarIfUninitialized("scr_cm_diehard", 2);
    setDvarIfUninitialized("scr_cm_nuke", 1);
    
    level.nuke = getDvarInt("scr_cm_nuke");
    level.dieHardMode = getDvarInt("scr_cm_diehard");
    
    setDvar("ui_gametype", "Checkmate");
    setDvar("didyouknow", "Checkmate modification made by Siilwyn. ^0(0.1)");
    setDvar("g_TeamName_Allies", "Guardians");
    setDvar("g_TeamName_Axis", "Assassins");
    setDvar("scr_teambalance", "0");
    setDvar("ui_allow_teamchange", 0);
    
    level.spawnMins = (0, 0, 0);
    level.spawnMaxs = (0, 0, 0);
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_tdm_spawn_allies_start");
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints("mp_tdm_spawn_axis_start");
    maps\mp\gametypes\_spawnlogic::addSpawnPoints("allies", "mp_tdm_spawn");
    maps\mp\gametypes\_spawnlogic::addSpawnPoints("axis", "mp_tdm_spawn");
    level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter(level.spawnMins, level.spawnMaxs);
    setMapCenter(level.mapCenter);
    
    allowed[0] = "war";
    allowed[1] = "airdrop_pallet";
    maps\mp\gametypes\_gameobjects::main(allowed);
    
    level thread onPlayerConnect();
    level thread setRoles();
    setSpecialLoadouts();
}

onPlayerConnect()
{
    while(!level.gameEnded)
    {
        level waittill("connected", player);
        
        player.firstSpawn = true;
        player.canUpgrade = false;
        player.weaponIndex = 0;
        
        player setClientDvar("cg_scoreboardPingGraph", 0);
        player setClientDvar("cg_scoreboardPingText", 1);
        player setClientDvar("cg_fovScale", 1.125);
        
        if(isDefined(level.king))
            player setAssassin();
        else
            player setGuard();
        
        player thread onPlayerDisconnect();
    }
}

onPlayerDisconnect()
{
    self waittill("disconnect");
    updateTeamScores();
    
    if(self.role == "king")
        level thread setRoles();
}

setRoles()
{
    level endon("game_ended");
    level waittill("prematch_over");
    
    while(level.players.size < 2)
        wait(2.00);
    
    level.king = level.players[randomInt(level.players.size)];
    level.assassin = level.players[randomInt(level.players.size)];
    
    while(level.king == level.assassin)
        level.assassin = level.players[randomInt(level.players.size)];
    
    level.king setKing();
    printOnPlayers(level.king + " " + "chosen as king!");
    level.assassin setInitialAssassin();
    printOnPlayers(level.assassin + " " + "chosen as assassin!");
}

setSpecialLoadouts()
{
    level.weapons = [];
    level.weapons[0] = "beretta";
    level.weapons[1] = "coltanaconda";
    level.weapons[2] = "tmp";
    level.weapons[3] = "spas12";
    level.weapons[4] = "uzi";
    level.weapons[5] = "pp2000";
    level.weapons[6] = "mp5k";
    level.weapons[7] = "ump45";
    level.weapons[8] = "aa12";
    level.weapons[9] = "p90";
    level.weapons[10] = "m16";
    level.weapons[11] = "masada";
    level.weapons[12] = "scar";
    level.weapons[13] = "ak47";
    level.weapons[14] = "m240";
    level.weapons[15] = "rpd";
}

getSpawnPoint()
{
    spawnTeam = self.pers["team"];
    if(game["switchedsides"])
        spawnTeam = getOtherTeam(spawnTeam);
    
    if(level.inGracePeriod)
    {
        spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_tdm_spawn_" + spawnTeam + "_start");
        spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnPoints);
    }
    else
    {
        spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints(spawnTeam);
        spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnPoints);
    }
    
    return spawnPoint;
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId)
{
    if(self.role == "king")
    {
        attacker.finalKill = true;
        level thread maps\mp\gametypes\_gamelogic::endGame("axis", "The king has died.");
        return;
    }
    if(isPlayer(attacker) && self != attacker)
    {
        if(attacker.role == "guard")
        {
            attacker.weaponIndex++;
            if(attacker.canUpgrade == false && attacker.weaponIndex < level.weapons.size)
                attacker thread updateWeapon();
        }
        else if(attacker.role == "king" && level.teamCount["axis"] > 2 && self.role != "initialAssassin")
            self setGuard();
        else
            self setAssassin();
    }
    else
    {
        self setAssassin();
    }
}

setKing()
{
    if(!isAlive(self))
        self thread maps\mp\gametypes\_playerlogic::spawnClient();
    
    self.role = "king";
    
    self.maxhealth = 300;
    self.health = self.maxhealth;
    self.headicon = game["headicon_allies"];
    self.headiconteam = "allies";
    
    self maps\mp\gametypes\_class::giveLoadout("allies", "king", false);
    self detachAll();
    [[game[self.team + "_model"]["RIOT"]]]();
    
    self addToTeam("allies");
}

setGuard()
{
    self.role = "guard";
    
    self maps\mp\gametypes\_class::giveLoadout("allies", "guard", false);
    
    self addToTeam("allies");
}

setInitialAssassin()
{
    self.role = "initialAssassin";
    
    self maps\mp\gametypes\_class::giveLoadout("axis", "initialAssassin", false);
    
    self addToTeam("axis");
}

setAssassin()
{
    self.role = "assassin";
    self.canUpgrade = false;
    
    self maps\mp\gametypes\_class::giveLoadout("axis", "assassin", false);
    
    self addToTeam("axis");
}

updateTeamScores()
{
    game["teamScores"]["axis"] = level.teamCount["axis"];
    setTeamScore("axis", level.teamCount["axis"]);
    game["teamScores"]["allies"] = level.teamCount["allies"];
    setTeamScore("allies", level.teamCount["allies"]);
}

updateWeapon()
{
    self endon("death");
    self endon("disconnect");
    
    self.canUpgrade = true;
    self setLowerMessage("activate", "Press ^3[{+activate}]^7 for the next weapon.");
    
    currentWeapon = level.weapons[self.weaponIndex - 1] + "_mp";
    
    self notifyOnPlayerCommand("F", "+activate");
    self waittill("F");
    
    if(self.weaponIndex > level.weapons.size)
        self.weaponIndex = level.weapons.size;
    
    nextWeapon = level.weapons[self.weaponIndex] + "_mp";
    
    self giveWeapon(nextWeapon, 0, false);
    self switchToWeapon(nextWeapon);
    self takeWeapon(currentWeapon);
    
    self.canUpgrade = false;
    self clearLowerMessage("activate");
}

addToTeam(teamName)
{    
    self closeMenus();
    
    if(self.team != teamName)
    {
        if(self.sessionstate == "playing")
        {
            self.switching_teams = true;
            self.joining_team = teamName;
            self.leaving_team = self.team;
            self suicide();
        }
        
        self maps\mp\gametypes\_menus::addToTeam(teamName);
        
        self notify("end_respawn");
    }
    
    updateTeamScores();
}
