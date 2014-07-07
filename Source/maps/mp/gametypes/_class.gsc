#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    level.classMap["class0"] = 0;
    level.classMap["class1"] = 1;
    level.classMap["class2"] = 2;
    level.classMap["class3"] = 3;
    level.classMap["class4"] = 4;
    level.classMap["class5"] = 5;
    level.classMap["class6"] = 6;
    level.classMap["class7"] = 7;
    level.classMap["class8"] = 8;
    level.classMap["class9"] = 9;
    level.classMap["class10"] = 10;
    level.classMap["class11"] = 11;
    level.classMap["class12"] = 12;
    level.classMap["class13"] = 13;
    level.classMap["class14"] = 14;
    
    level.classMap["custom1"] = 0;
    level.classMap["custom2"] = 1;
    level.classMap["custom3"] = 2;
    level.classMap["custom4"] = 3;
    level.classMap["custom5"] = 4;
    level.classMap["custom6"] = 5;
    level.classMap["custom7"] = 6;
    level.classMap["custom8"] = 7;
    level.classMap["custom9"] = 8;
    level.classMap["custom10"] = 9;
    
    level.classMap["copycat"] = -1;
    
    level.defaultClass = "CLASS_ASSAULT";
    
    level.classTableName = "mp/classTable.csv";
    
    precacheShader("specialty_pistoldeath");
    precacheShader("specialty_finalstand");
    
    level thread onPlayerConnecting();
}

getClassChoice(response)
{
    assert(isDefined(level.classMap[response]));
    
    return response;
}

getWeaponChoice(response)
{
    tokens = strtok(response, ",");
    if(tokens.size > 1)
        return int(tokens[1]);
    else
        return 0;
}

logClassChoice(class, primaryWeapon, specialType, perks)
{
    if(class == self.lastClass)
        return;

    self logstring("choseclass: " + class + " weapon: " + primaryWeapon + " special: " + specialType);      
    for(i=0; i<perks.size; i++)
        self logstring("perk" + i + ": " + perks[i]);
    
    self.lastClass = class;
}

cac_getWeapon(classIndex, weaponIndex)
{
    return self getPlayerData("customClasses", classIndex, "weaponSetups", weaponIndex, "weapon");
}

cac_getWeaponAttachment(classIndex, weaponIndex)
{
    return self getPlayerData("customClasses", classIndex, "weaponSetups", weaponIndex, "attachment", 0);
}

cac_getWeaponAttachmentTwo(classIndex, weaponIndex)
{
    return self getPlayerData("customClasses", classIndex, "weaponSetups", weaponIndex, "attachment", 1);
}

cac_getWeaponCamo(classIndex, weaponIndex)
{
    return self getPlayerData("customClasses", classIndex, "weaponSetups", weaponIndex, "camo");
}

cac_getPerk(classIndex, perkIndex)
{
    return self getPlayerData("customClasses", classIndex, "perks", perkIndex);
}

cac_getKillstreak(classIndex, streakIndex)
{
    return self getPlayerData("killstreaks", streakIndex);
}

cac_getDeathstreak(classIndex)
{
    return self getPlayerData("customClasses", classIndex, "perks", 4);
}

cac_getOffhand(classIndex)
{
    return self getPlayerData("customClasses", classIndex, "specialGrenade");
}

table_getWeapon(tableName, classIndex, weaponIndex)
{
    if(weaponIndex == 0)
        return tableLookup(tableName, 0, "loadoutPrimary", classIndex + 1);
    else
        return tableLookup(tableName, 0, "loadoutSecondary", classIndex + 1);
}

table_getWeaponAttachment(tableName, classIndex, weaponIndex, attachmentIndex)
{
    tempName = "none";
    
    if(weaponIndex == 0)
    {
        if(!isDefined(attachmentIndex) || attachmentIndex == 0)
            tempName = tableLookup(tableName, 0, "loadoutPrimaryAttachment", classIndex + 1);
        else
            tempName = tableLookup(tableName, 0, "loadoutPrimaryAttachment2", classIndex + 1);
    }
    else
    {
        if(!isDefined(attachmentIndex) || attachmentIndex == 0)
            tempName = tableLookup(tableName, 0, "loadoutSecondaryAttachment", classIndex + 1);
        else
            tempName = tableLookup(tableName, 0, "loadoutSecondaryAttachment2", classIndex + 1);
    }
    
    if(tempName == "" || tempName == "none")
        return "none";
    else
        return tempName;
    
    
}

table_getWeaponCamo(tableName, classIndex, weaponIndex)
{
    if(weaponIndex == 0)
        return tableLookup(tableName, 0, "loadoutPrimaryCamo", classIndex + 1);
    else
        return tableLookup(tableName, 0, "loadoutSecondaryCamo", classIndex + 1);
}

table_getEquipment(tableName, classIndex, perkIndex)
{
    assert(perkIndex < 5);
    return tableLookup(tableName, 0, "loadoutEquipment", classIndex + 1);
}

table_getPerk(tableName, classIndex, perkIndex)
{
    assert(perkIndex < 5);
    return tableLookup(tableName, 0, "loadoutPerk" + perkIndex, classIndex + 1);
}

table_getOffhand(tableName, classIndex)
{
    return tableLookup(tableName, 0, "loadoutOffhand", classIndex + 1);
}

table_getDeathstreak(tableName, classIndex)
{
    return tableLookup(tableName, 0, "loadoutDeathstreak", classIndex + 1);
}

getClassIndex(className)
{
    assert(isDefined(level.classMap[className]));
    
    return level.classMap[className];
}

cloneLoadout()
{
}

giveLoadout(team, class, allowCopycat)
{
    self takeAllWeapons();
    self _clearPerks();
    self _detachAll();
    
    primaryIndex = 0;
    
    self.specialty = [];
    
    allowCopycat = false;
    
    primaryWeapon = undefined;
    
    switch(self.role)
    {
        case "assassin":
            loadoutPrimary = "cheytac";
            loadoutPrimaryAttachment = "none";
            loadoutPrimaryAttachment2 = "none";
            loadoutPrimaryCamo = "none";
            loadoutSecondary = "usp_tactical";
            loadoutSecondaryAttachment = "none";
            loadoutSecondaryAttachment2 = "none";
            loadoutSecondaryCamo = "none";
            loadoutEquipment = "specialty_null";
            loadoutPerk1 = "specialty_fastreload";
            loadoutPerk2 = "specialty_explosivedamage";
            loadoutPerk3 = "specialty_heartbreaker";
            loadoutOffhand = "none";
            loadoutDeathStreak = "specialty_null";
            break;
            
        case "guard":
            loadoutPrimary = level.weapons[self.weaponIndex];
            loadoutPrimaryAttachment = "none";
            loadoutPrimaryAttachment2 = "none";
            loadoutPrimaryCamo = "none";
            loadoutSecondary = "none";
            loadoutSecondaryAttachment = "none";
            loadoutSecondaryAttachment2 = "none";
            loadoutSecondaryCamo = "none";
            loadoutEquipment = "specialty_null";
            loadoutPerk1 = "specialty_null";
            loadoutPerk2 = "specialty_null";
            loadoutPerk3 = "specialty_null";
            loadoutOffhand = "none";
            loadoutDeathStreak = "specialty_null";
            break;
            
        case "king":
            loadoutPrimary = "ranger";
            loadoutPrimaryAttachment = "none";
            loadoutPrimaryAttachment2 = "none";
            loadoutPrimaryCamo = "none";
            loadoutSecondary = "coltanaconda";
            loadoutSecondaryAttachment = "none";
            loadoutSecondaryAttachment2 = "none";
            loadoutSecondaryCamo = "none";
            loadoutEquipment = "claymore_mp";
            loadoutPerk1 = "specialty_scavenger";
            loadoutPerk2 = "specialty_null";
            loadoutPerk3 = "specialty_pistoldeath";
            loadoutOffhand = "none";
            loadoutDeathStreak = "specialty_null";
            break;
            
        case "initialAssassin":
            loadoutPrimary = "cheytac";
            loadoutPrimaryAttachment = "none";
            loadoutPrimaryAttachment2 = "none";
            loadoutPrimaryCamo = "none";
            loadoutSecondary = "coltanaconda_tactical";
            loadoutSecondaryAttachment = "none";
            loadoutSecondaryAttachment2 = "none";
            loadoutSecondaryCamo = "none";
            loadoutEquipment = "semtex_mp";
            loadoutPerk1 = "specialty_fastreload";
            loadoutPerk2 = "specialty_bulletdamage";
            loadoutPerk3 = "specialty_heartbreaker";
            loadoutOffhand = "none";
            loadoutDeathStreak = "specialty_null";
            break;
            
        default:
            loadoutPrimary = "usp";
            loadoutPrimaryAttachment = "none";
            loadoutPrimaryAttachment2 = "none";
            loadoutPrimaryCamo = "none";
            loadoutSecondary = "none";
            loadoutSecondaryAttachment = "none";
            loadoutSecondaryAttachment2 = "none";
            loadoutSecondaryCamo = "none";
            loadoutEquipment = "specialty_null";
            loadoutPerk1 = "specialty_null";
            loadoutPerk2 = "specialty_null";
            loadoutPerk3 = "specialty_null";
            loadoutOffhand = "none";
            loadoutDeathStreak = "specialty_null";
            break;
    }
    
    self.loadoutPrimary = loadoutPrimary;
    self.loadoutPrimaryCamo = int(tableLookup("mp/camoTable.csv", 1, loadoutPrimaryCamo, 0));
    self.loadoutSecondary = loadoutSecondary;
    self.loadoutSecondaryCamo = int(tableLookup("mp/camoTable.csv", 1, loadoutSecondaryCamo, 0));
    
    primaryName = buildWeaponName(loadoutPrimary, loadoutPrimaryAttachment, loadoutPrimaryAttachment2);
    self _giveWeapon(primaryName, self.loadoutPrimaryCamo);
    secondaryName = buildWeaponName(loadoutSecondary, loadoutSecondaryAttachment, loadoutSecondaryAttachment2);
    self _giveWeapon(secondaryName, self.loadoutSecondaryCamo);
    
    self SetOffhandPrimaryClass("other");
    
    self _SetActionSlot(1, "");
    self _SetActionSlot(3, "altMode");
    self _SetActionSlot(4, "");
    
    if(loadoutDeathStreak != "specialty_null" && getTime() == self.spawnTime)
    {
        deathVal = int(tableLookup("mp/perkTable.csv", 1, loadoutDeathStreak, 6));
        
        if(self getPerkUpgrade(loadoutPerk1) == "specialty_rollover" || self getPerkUpgrade(loadoutPerk2) == "specialty_rollover" || self getPerkUpgrade(loadoutPerk3) == "specialty_rollover")
            deathVal -= 1;
        
        if(self.pers["cur_death_streak"] == deathVal)
        {
            self thread maps\mp\perks\_perks::givePerk(loadoutDeathStreak);
            self thread maps\mp\gametypes\_hud_message::splashNotify(loadoutDeathStreak);
        }
        else if(self.pers["cur_death_streak"] > deathVal)
            self thread maps\mp\perks\_perks::givePerk(loadoutDeathStreak);
    }
    
    self loadoutAllPerks(loadoutEquipment, loadoutPerk1, loadoutPerk2, loadoutPerk3);
    self setKillstreaks(self.role);
    self setSpecials(self.role);
    
    if(self hasPerk("specialty_extraammo", true))
    {
        self giveMaxAmmo(primaryName);
        if(getWeaponClass(secondaryName) != "weapon_projectile")
            self giveMaxAmmo(secondaryName);
    }
    
    self setSpawnWeapon(primaryName);
    
    primaryTokens = strtok(primaryName, "_");
    self.pers["primaryWeapon"] = primaryTokens[0];
    
    offhandSecondaryWeapon = loadoutOffhand + "_mp";
    if(loadoutOffhand == "flash_grenade")
        self SetOffhandSecondaryClass("flash");
    else
        self SetOffhandSecondaryClass("smoke");
    
    self giveWeapon(offhandSecondaryWeapon);
    if(loadOutOffhand == "flash_grenade" || loadOutOffhand == "concussion_grenade")
        self setWeaponAmmoClip(offhandSecondaryWeapon, 2);
    else
        self setWeaponAmmoClip(offhandSecondaryWeapon, 1);
    
    primaryWeapon = primaryName;
    self.primaryWeapon = primaryWeapon;
    self.secondaryWeapon = secondaryName;
    
    self maps\mp\gametypes\_teams::playerModelForWeapon(self.pers["primaryWeapon"], getBaseWeaponName(secondaryName));
    
    self.isSniper = (weaponClass(self.primaryWeapon) == "sniper");
    
    self maps\mp\gametypes\_weapons::updateMoveSpeedScale("primary");
    
    self maps\mp\perks\_perks::cac_selector();
    
    self notify("changed_kit");
    self notify("giveLoadout");
}

_detachAll()
{
    if(isDefined(self.hasRiotShield) && self.hasRiotShield)
    {
        if(self.hasRiotShieldEquipped)
        {
            self DetachShieldModel("weapon_riot_shield_mp", "tag_weapon_left");
            self.hasRiotShieldEquipped = false;
        }
        else
        {
            self DetachShieldModel("weapon_riot_shield_mp", "tag_shield_back");
        }
        
        self.hasRiotShield = false;
    }
    
    self detachAll();
}

isPerkUpgraded(perkName)
{
    perkUpgrade = tablelookup("mp/perktable.csv", 1, perkName, 8);
    
    if(perkUpgrade == "" || perkUpgrade == "specialty_null")
        return false;
        
    if(!self isItemUnlocked(perkUpgrade))
        return false;
        
    return true;
}

getPerkUpgrade(perkName)
{
    perkUpgrade = tablelookup("mp/perktable.csv", 1, perkName, 8);
    
    if(perkUpgrade == "" || perkUpgrade == "specialty_null")
        return "specialty_null";
        
    if(!self isItemUnlocked(perkUpgrade))
        return "specialty_null";
        
    return(perkUpgrade);
}

loadoutAllPerks(loadoutEquipment, loadoutPerk1, loadoutPerk2, loadoutPerk3)
{
    loadoutEquipment = maps\mp\perks\_perks::validatePerk(1, loadoutEquipment);
    loadoutPerk1 = maps\mp\perks\_perks::validatePerk(1, loadoutPerk1);
    loadoutPerk2 = maps\mp\perks\_perks::validatePerk(2, loadoutPerk2);
    loadoutPerk3 = maps\mp\perks\_perks::validatePerk(3, loadoutPerk3);

    self maps\mp\perks\_perks::givePerk(loadoutEquipment);
    self maps\mp\perks\_perks::givePerk(loadoutPerk1);
    self maps\mp\perks\_perks::givePerk(loadoutPerk2);
    self maps\mp\perks\_perks::givePerk(loadoutPerk3);
    
    perkUpgrd[0] = tablelookup("mp/perktable.csv", 1, loadoutPerk1, 8);
    perkUpgrd[1] = tablelookup("mp/perktable.csv", 1, loadoutPerk2, 8);
    perkUpgrd[2] = tablelookup("mp/perktable.csv", 1, loadoutPerk3, 8);
    
    foreach(upgrade in perkUpgrd)
    {
        if(upgrade == "" || upgrade == "specialty_null")
            continue;
            
        if(self isItemUnlocked(upgrade))
            self maps\mp\perks\_perks::givePerk(upgrade);
    }

}

trackRiotShield()
{
    self endon("death");
    self endon("disconnect");

    self.hasRiotShield = self hasWeapon("riotshield_mp");
    self.hasRiotShieldEquipped =(self.currentWeaponAtSpawn == "riotshield_mp");
    
    if(self.hasRiotShield)
    {
        if(self.hasRiotShieldEquipped)
        {
            self AttachShieldModel("weapon_riot_shield_mp", "tag_weapon_left");
        }
        else
        {
            self AttachShieldModel("weapon_riot_shield_mp", "tag_shield_back");
        }
    }
    
    for(;;)
    {
        self waittill("weapon_change", newWeapon);
        
        if(newWeapon == "riotshield_mp")
        {
            if(self.hasRiotShieldEquipped)
                continue;
            
            if(self.hasRiotShield)
                self MoveShieldModel("weapon_riot_shield_mp", "tag_shield_back", "tag_weapon_left");
            else
                self AttachShieldModel("weapon_riot_shield_mp", "tag_weapon_left");
            
            self.hasRiotShield = true;
            self.hasRiotShieldEquipped = true;
        }
        else if(self.hasRiotShieldEquipped)
        {
            assert(self.hasRiotShield);
            self.hasRiotShield = self hasWeapon("riotshield_mp");
            
            if(self.hasRiotShield)
                self MoveShieldModel("weapon_riot_shield_mp", "tag_weapon_left", "tag_shield_back");
            else
                self DetachShieldModel("weapon_riot_shield_mp", "tag_weapon_left");
            
            self.hasRiotShieldEquipped = false;
        }
        else if(self.hasRiotShield)
        {
            if(!self hasWeapon("riotshield_mp"))
            {
                self DetachShieldModel("weapon_riot_shield_mp", "tag_shield_back");
                self.hasRiotShield = false;
            }
        }
    }
}

buildWeaponName(baseName, attachment1, attachment2)
{
    if(!isDefined(level.letterToNumber))
        level.letterToNumber = makeLettersToNumbers();
    
    if(getDvarInt("scr_game_perks") == 0)
    {
        attachment2 = "none";

        if(baseName == "onemanarmy")
            return("beretta_mp");
    }

    weaponName = baseName;
    attachments = [];

    if(attachment1 != "none" && attachment2 != "none")
    {
        if(level.letterToNumber[attachment1[0]] < level.letterToNumber[attachment2[0]])
        {
            
            attachments[0] = attachment1;
            attachments[1] = attachment2;
            
        }
        else if(level.letterToNumber[attachment1[0]] == level.letterToNumber[attachment2[0]])
        {
            if(level.letterToNumber[attachment1[1]] < level.letterToNumber[attachment2[1]])
            {
                attachments[0] = attachment1;
                attachments[1] = attachment2;
            }
            else
            {
                attachments[0] = attachment2;
                attachments[1] = attachment1;
            }   
        }
        else
        {
            attachments[0] = attachment2;
            attachments[1] = attachment1;
        }       
    }
    else if(attachment1 != "none")
    {
        attachments[0] = attachment1;
    }
    else if(attachment2 != "none")
    {
        attachments[0] = attachment2;   
    }
    
    foreach(attachment in attachments)
    {
        weaponName += "_" + attachment;
    }

    if(!isValidWeapon(weaponName + "_mp"))
        return(baseName + "_mp");
    else
        return(weaponName + "_mp");
}

makeLettersToNumbers()
{
    array = [];
    
    array["a"] = 0;
    array["b"] = 1;
    array["c"] = 2;
    array["d"] = 3;
    array["e"] = 4;
    array["f"] = 5;
    array["g"] = 6;
    array["h"] = 7;
    array["i"] = 8;
    array["j"] = 9;
    array["k"] = 10;
    array["l"] = 11;
    array["m"] = 12;
    array["n"] = 13;
    array["o"] = 14;
    array["p"] = 15;
    array["q"] = 16;
    array["r"] = 17;
    array["s"] = 18;
    array["t"] = 19;
    array["u"] = 20;
    array["v"] = 21;
    array["w"] = 22;
    array["x"] = 23;
    array["y"] = 24;
    array["z"] = 25;
    
    return array;
}

setKillstreaks(role)
{
    self.killStreaks = [];

    if(self _hasPerk("specialty_hardline"))
        modifier = -1;
    else
        modifier = 0;
    
    killStreaks = [];
    
    if(role == "guard"){
        killStreaks[4] = "airdrop";
        killStreaks[8] = "precision_airstrike";
        killStreaks[16] = "predator_missile";
        killStreaks[20] = "sentry";
        killStreaks[32] = "ac130";
        if(level.nuke)
            killStreaks[40] = "nuke";
    }
    
    maxVal = 0;
    foreach(streakVal, streakName in killStreaks)
    {
        if(streakVal > maxVal)
            maxVal = streakVal;
    }

    for(streakIndex = 0; streakIndex <= maxVal; streakIndex++)
    {
        if(!isDefined(killStreaks[streakIndex]))
            continue;
            
        streakName = killStreaks[streakIndex];
            
        self.killStreaks[ streakIndex ] = killStreaks[ streakIndex ];
    }
        
    maxRollOvers = 10;
    newKillstreaks = self.killstreaks;
    for(rollOver = 1; rollOver <= maxRollOvers; rollOver++)
    {
        foreach(streakVal, streakName in self.killstreaks)
        {
            newKillstreaks[ streakVal +(maxVal*rollOver) ] = streakName + "-rollover" + rollOver;
        }
    }
    
    self.killstreaks = newKillstreaks;
}

setSpecials(role)
{
    switch(role)
    {
        case "assassin":
            self setWeaponAmmoClip("usp_tactical_mp", 0);
            self setWeaponAmmoStock("usp_tactical_mp", 0);
            break;
        case "initialAssassin":
            self setWeaponAmmoClip("coltanaconda_tactical_mp", 0);
            self setWeaponAmmoStock("coltanaconda_tactical_mp", 0);
            break;
    }
}

replenishLoadout()
{
    team = self.pers["team"];
    class = self.pers["class"];

    weaponsList = self GetWeaponsListAll();
    for(idx = 0; idx < weaponsList.size; idx++)
    {
        weapon = weaponsList[idx];

        self giveMaxAmmo(weapon);
        self SetWeaponAmmoClip(weapon, 9999);

        if(weapon == "claymore_mp" || weapon == "claymore_detonator_mp")
            self setWeaponAmmoStock(weapon, 2);
    }
    
    if(self getAmmoCount(level.classGrenades[class]["primary"]["type"]) < level.classGrenades[class]["primary"]["count"])
        self SetWeaponAmmoClip(level.classGrenades[class]["primary"]["type"], level.classGrenades[class]["primary"]["count"]);

    if(self getAmmoCount(level.classGrenades[class]["secondary"]["type"]) < level.classGrenades[class]["secondary"]["count"])
        self SetWeaponAmmoClip(level.classGrenades[class]["secondary"]["type"], level.classGrenades[class]["secondary"]["count"]);  
}

onPlayerConnecting()
{
    for(;;)
    {
        level waittill("connected", player);

        if(!isDefined(player.pers["class"]))
        {
            player.pers["class"] = "";
        }
        player.class = player.pers["class"];
        player.lastClass = "";
        player.detectExplosives = false;
        player.bombSquadIcons = [];
        player.bombSquadIds = [];
    }
}

fadeAway(waitDelay, fadeDelay)
{
    wait waitDelay;
    
    self fadeOverTime(fadeDelay);
    self.alpha = 0;
}

setClass(newClass)
{
    self.curClass = newClass;
}

getPerkForClass(perkSlot, className)
{
    class_num = getClassIndex(className);

    if(isSubstr(className, "custom"))
        return cac_getPerk(class_num, perkSlot);
    else
        return table_getPerk(level.classTableName, class_num, perkSlot);
}

classHasPerk(className, perkName)
{
    return(getPerkForClass(0, className) == perkName || getPerkForClass(1, className) == perkName || getPerkForClass(2, className) == perkName);
}

isValidPrimary(refString)
{
    switch(refString)
    {
        case "riotshield":
        case "ak47":
        case "m16":
        case "m4":
        case "fn2000":
        case "masada":
        case "famas":
        case "fal":
        case "scar":
        case "tavor":
        case "mp5k":
        case "uzi":
        case "p90":
        case "kriss":
        case "ump45":
        case "barrett":
        case "wa2000":
        case "m21":
        case "cheytac":
        case "rpd":
        case "sa80":
        case "mg4":
        case "m240":
        case "aug":
            return true;
        default:
            assertMsg("Replacing invalid primary weapon: " + refString);
            return false;
    }
}

isValidSecondary(refString)
{
    switch(refString)
    {
        case "beretta":
        case "usp":
        case "deserteagle":
        case "coltanaconda":
        case "glock":
        case "beretta393":
        case "pp2000":
        case "tmp":
        case "m79":
        case "rpg":
        case "at4":
        case "stinger":
        case "javelin":
        case "ranger":
        case "model1887":
        case "striker":
        case "aa12":
        case "m1014":
        case "spas12":
        case "onemanarmy":
            return true;
        default:
            assertMsg("Replacing invalid secondary weapon: " + refString);
            return false;
    }
}

isValidAttachment(refString)
{
    switch(refString)
    {
        case "none":
        case "acog":
        case "reflex":
        case "silencer":
        case "grip":
        case "gl":
        case "akimbo":
        case "thermal":
        case "shotgun":
        case "heartbeat":
        case "fmj":
        case "rof":
        case "xmags":
        case "eotech":  
        case "tactical":
            return true;
        default:
            assertMsg("Replacing invalid equipment weapon: " + refString);
            return false;
    }
}

isValidCamo(refString)
{
    switch(refString)
    {
        case "none":
        case "woodland":
        case "desert":
        case "arctic":
        case "digital":
        case "red_urban":
        case "red_tiger":
        case "blue_tiger":
        case "orange_fall":
            return true;
        default:
            assertMsg("Replacing invalid camo: " + refString);
            return false;
    }
}

isValidEquipment(refString)
{
    switch(refString)
    {
        case "frag_grenade_mp":
        case "semtex_mp":
        case "throwingknife_mp":
        case "specialty_tacticalinsertion":
        case "specialty_blastshield":
        case "claymore_mp":
        case "c4_mp":
            return true;
        default:
            assertMsg("Replacing invalid equipment: " + refString);
            return false;
    }
}

isValidOffhand(refString)
{
    switch(refString)
    {
        case "flash_grenade":
        case "concussion_grenade":
        case "smoke_grenade":
            return true;
        default:
            assertMsg("Replacing invalid offhand: " + refString);
            return false;
    }
}

isValidPerk1(refString)
{
    switch(refString)
    {
        case "specialty_marathon":
        case "specialty_fastreload":
        case "specialty_scavenger":
        case "specialty_bling":
        case "specialty_onemanarmy":
            return true;
        default:
            assertMsg("Replacing invalid perk1: " + refString);
            return false;
    }
}

isValidPerk2(refString)
{
    switch(refString)
    {
        case "specialty_bulletdamage":
        case "specialty_lightweight":
        case "specialty_hardline":
        case "specialty_coldblooded":
        case "specialty_explosivedamage":
            return true;
        default:
            assertMsg("Replacing invalid perk2: " + refString);
            return false;
    }
}

isValidPerk3(refString)
{
    switch(refString)
    {
        case "specialty_extendedmelee":
        case "specialty_bulletaccuracy":
        case "specialty_localjammer":
        case "specialty_heartbreaker":
        case "specialty_detectexplosive":
        case "specialty_pistoldeath":
            return true;
        default:
            assertMsg("Replacing invalid perk3: " + refString);
            return false;
    }
}

isValidDeathStreak(refString)
{
    switch(refString)
    {
        case "specialty_copycat":
        case "specialty_combathigh":
        case "specialty_grenadepulldeath":
        case "specialty_finalstand":
            return true;
        default:
            assertMsg("Replacing invalid death streak: " + refString);
            return false;
    }
}

isValidWeapon(refString)
{
    if(!isDefined(level.weaponRefs))
    {
        level.weaponRefs = [];

        foreach(weaponRef in level.weaponList)
            level.weaponRefs[ weaponRef ] = true;
    }

    if(isDefined(level.weaponRefs[ refString ]))
        return true;

    assertMsg("Replacing invalid weapon/attachment combo: " + refString);
    
    return false;
}
