// Checkmate by Siilwyn
// Thanks to the community at http://itsmods.com/

// https://github.com/Siilwyn/iw4-checkmate/
// Version 0.2

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
    level.onTimeLimit = ::onTimeLimit;
    
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
    
    setDvarIfUninitialized("scr_cm_timelimit", 5);
    setDvarIfUninitialized("scr_cm_nuke", 1);
    setDvarIfUninitialized("scr_cm_diehard", 2);
    setDvarIfUninitialized("scr_cm_falldamage", 1);
    
    level.timeLimit = getDvarInt("scr_cm_timelimit");
    level.scoreLimit = getDvarInt("sv_maxclients");
    level.nuke = getDvarInt("scr_cm_nuke");
    level.dieHardMode = getDvarInt("scr_cm_diehard");
    level.fallDamage = getDvarInt("scr_cm_falldamage");
    
    setDvar("ui_gametype", "Checkmate");
    setDvar("didyouknow", "Checkmate modification made by Siilwyn. ^0(0.2)");
    
    setDvar("g_TeamName_Allies", "Guardians");
    setDvar("g_TeamName_Axis", "Assassins");
    setDvar("scr_war_timelimit", level.timelimit);
    setDvar("scr_war_scorelimit", level.scorelimit);
    setDvar("scr_teambalance", 0);
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
    level thread setRoles(true);
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
        
        self notifyOnPlayerCommand("use_upgrade", "+activate");
        self notifyOnPlayerCommand("use_description", "+actionslot 1");
        
        if(isDefined(level.king))
            player setAssassin();
        else
            player setGuard();
        
        player thread toggleDescription();
        player thread onPlayerDisconnect();
    }
}

toggleDescription()
{
    self endon("disconnect");
    
    self.descriptionElem = createDescription();
    self.inMenu = false;
    
    wait(20.00);
    
    while(!level.gameEnded)
    {
        self waittill("use_description");
        
        if(!self.inMenu)
        {
            self.inMenu = true;
            
            self setClientDvar("ui_drawcrosshair", 0);
            
            self.descriptionElem fadeOverTime(1);
            self.descriptionElem.alpha = 0.75;
            self.descriptionElem.title fadeOverTime(1);
            self.descriptionElem.title.alpha = 1;
            self.descriptionElem.titleSub fadeOverTime(1);
            self.descriptionElem.titleSub.alpha = 1;
            self.descriptionElem.content fadeOverTime(1);
            self.descriptionElem.content.alpha = 1;
            self.descriptionElem.content2 fadeOverTime(1);
            self.descriptionElem.content2.alpha = 1;
            self.descriptionElem.content3 fadeOverTime(1);
            self.descriptionElem.content3.alpha = 1;
            self.descriptionElem.content4 fadeOverTime(1);
            self.descriptionElem.content4.alpha = 1;
        }
        else if(self.inMenu)
        {
            self.inMenu = false;
            
            self setClientDvar("ui_drawcrosshair", 1);
            self setWaterSheeting(1, 2);
            
            self.descriptionElem fadeOverTime(0.8);
            self.descriptionElem.alpha = 0;
            self.descriptionElem.title fadeOverTime(0.8);
            self.descriptionElem.title.alpha = 0;
            self.descriptionElem.titleSub fadeOverTime(0.8);
            self.descriptionElem.titleSub.alpha = 0;
            self.descriptionElem.content fadeOverTime(0.8);
            self.descriptionElem.content.alpha = 0;
            self.descriptionElem.content2 fadeOverTime(0.8);
            self.descriptionElem.content2.alpha = 0;
            self.descriptionElem.content3 fadeOverTime(0.8);
            self.descriptionElem.content3.alpha = 0;
            self.descriptionElem.content4 fadeOverTime(0.8);
            self.descriptionElem.content4.alpha = 0;
        }
    }
}

createDescription()
{
    containerElem = newClientHudElem(self);
    containerElem.elemType = "bar";
    containerElem.width = 300;
    containerElem.height = 300;
    containerElem.color = (0, 0, 0);
    containerElem.alpha = 0;
    containerElem.children = [];
    containerElem setParent(level.uiParent);
    containerElem setShader("black", 1000, 1000);
    containerElem setPoint("CENTER", "CENTER", 0, 0);
    
    containerElem.title = createFontString("bigfixed", 0.8);
    containerElem.title.point = "TOPLEFT";
    containerElem.title.xOffset = 10;
    containerElem.title.yOffset = 7;
    containerElem.title.alpha = 0;
    containerElem.title setParent(containerElem);
    containerElem.title setText("Checkmate ^80.2");
    
    containerElem.titleSub = createFontString("default", 0.8);
    containerElem.titleSub.point = "TOPLEFT";
    containerElem.titleSub.xOffset = 11;
    containerElem.titleSub.yOffset = 25;
    containerElem.titleSub.alpha = 0;
    containerElem.titleSub setParent(containerElem);
    containerElem.titleSub setText("By Siilwyn.");
    
    containerElem.content = createFontString("default", 1.0);
    containerElem.content.point = "TOPLEFT";
    containerElem.content.xOffset = 11;
    containerElem.content.yOffset = 45;
    containerElem.content.alpha = 0;
    containerElem.content setParent(containerElem);
    containerElem.content setText("Two teams, the assassins and the guardians, battle respectively to kill or\ndefend the king. At the start of a game two players get randomly picked\nto be the king or first assassin. The assassins win the game by killing");
    
    containerElem.content2 = createFontString("default", 1.0);
    containerElem.content2.point = "TOPLEFT";
    containerElem.content2.xOffset = 11;
    containerElem.content2.yOffset = 80;
    containerElem.content2.alpha = 0;
    containerElem.content2 setParent(containerElem);
    containerElem.content2 setText("the king while the guardians and king win by surviving. The assassins\nstrive to kill the king, they can get more allies by killing guardians\nas they turn into assassins when killed.");
    
    containerElem.content3 = createFontString("default", 1.0);
    containerElem.content3.point = "TOPLEFT";
    containerElem.content3.xOffset = 11;
    containerElem.content3.yOffset = 115;
    containerElem.content3.alpha = 0;
    containerElem.content3 setParent(containerElem);
    containerElem.content3 setText("The king on the other hand tries to stay alive and can turn assassins\ninto guardians by killing them.");
    
    containerElem.content4 = createFontString("default", 1.0);
    containerElem.content4.point = "TOPLEFT";
    containerElem.content4.xOffset = 11;
    containerElem.content4.yOffset = 145;
    containerElem.content4.alpha = 0;
    containerElem.content4 setParent(containerElem);
    containerElem.content4 setText("Guardians start with a pistol and with each kill they get a better weapon,\nthe king has claymores, a shotgun and a pistol.\nThe assassins wear snipers and a tactical knife, the first assassin is\ndangerous because of his semtex and stopping power perk.");
    
    return containerElem;
}

onPlayerDisconnect()
{
    self waittill("disconnect");
    updateTeamScores();
    
    if(self.role == "king" || level.teamCount["axis"] == 0)
        level thread setRoles(false);
}

setRoles(prematchWait)
{
    level endon("game_ended");
    
    if(prematchWait)
        level waittill("prematch_over");
    
    while(level.players.size < 2)
        wait(2.00);
    
    if(!isDefined(level.king))
        level.king = level.players[randomInt(level.players.size)];
    
    if(!isDefined(level.assassin))
        level.assassin = level.players[randomInt(level.players.size)];
    
    while(level.king == level.assassin)
        level.assassin = level.players[randomInt(level.players.size)];
    
    level.king thread setKing();
    printOnPlayers(level.king.name + " " + "chosen as king!");
    level.assassin setInitialAssassin();
    printOnPlayers(level.assassin.name + " " + "chosen as assassin!");
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

onTimeLimit()
{
    level thread maps\mp\gametypes\_gamelogic::endGame("allies", "The king survived.");
}

setKing()
{
    if(!isAlive(self))
        self thread maps\mp\gametypes\_playerlogic::spawnClient();
    
    self.role = "king";
    self addToTeam("allies");
    
    self.maxhealth = 300;
    self.health = self.maxhealth;
    self.headicon = game["headicon_allies"];
    self.headiconteam = "allies";
    
    self maps\mp\gametypes\_class::giveLoadout("allies", "king", false);
    self detachAll();
    [[game[self.team + "_model"]["RIOT"]]]();
    
    wait(3.00);
    teamVoicePrefix = maps\mp\gametypes\_teams::getTeamVoicePrefix(self.team);
    self playSound(teamVoicePrefix + "mp_cmd_followme");
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
    
    if(self.canUpgrade)
    {
        self.canUpgrade = false;
        self clearLowerMessage("activate");
    }
    
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
    
    self waittill("F");
    
    if(self.weaponIndex >= level.weapons.size)
        self.weaponIndex = level.weapons.size - 1;
    
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
