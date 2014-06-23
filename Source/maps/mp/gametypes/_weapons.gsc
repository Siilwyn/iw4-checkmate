#include common_scripts\utility;
#include maps\mp\_utility;

attachmentGroup(attachmentName)
{
    return tableLookup("mp/attachmentTable.csv", 4, attachmentName, 2);
}

getAttachmentList()
{
    attachmentList = [];
    
    index = 0;
    attachmentName = tableLookup("mp/attachmentTable.csv", 9, index, 4);
    
    while(attachmentName != "")
    {
        attachmentList[attachmentList.size] = attachmentName;
        
        index++;
        attachmentName = tableLookup("mp/attachmentTable.csv", 9, index, 4);
    }
    
    return alphabetize(attachmentList);
}

init()
{
    level.scavenger_altmode = true;
    level.scavenger_secondary = true;
    
    level.maxPerPlayerExplosives = max(getIntProperty("scr_maxPerPlayerExplosives", 2), 1);
    level.riotShieldXPBullets = getIntProperty("scr_riotShieldXPBullets", 15);

    switch(getIntProperty("perk_scavengerMode", 0))
    {
        case 1:
            level.scavenger_altmode = false;
            break;

        case 2:
            level.scavenger_secondary = false;
            break;
            
        case 3:
            level.scavenger_altmode = false;
            level.scavenger_secondary = false;
            break;      
    }
    
    attachmentList = getAttachmentList();
    
    max_weapon_num = 149;

    level.weaponList = [];
    for(weaponId = 0; weaponId <= max_weapon_num; weaponId++)
    {
        weapon_name = tablelookup("mp/statstable.csv", 0, weaponId, 4);
        if(weapon_name == "")
            continue;
        
        if(!isSubStr(tableLookup("mp/statsTable.csv", 0, weaponId, 2), "weapon_"))
            continue;
        
        level.weaponList[level.weaponList.size] = weapon_name + "_mp";
        attachmentNames = [];
        for(innerLoopCount = 0; innerLoopCount < 10; innerLoopCount++)
        {
            attachmentName = tablelookup("mp/statStable.csv", 0, weaponId, innerLoopCount + 11);
            
            if(attachmentName == "")
                break;
            
            attachmentNames[attachmentName] = true;
        }
        
        attachments = [];
        foreach(attachmentName in attachmentList)
        {
            if(!isDefined(attachmentNames[attachmentName]))
                continue;
        
            level.weaponList[level.weaponList.size] = weapon_name + "_" + attachmentName + "_mp";
            attachments[attachments.size] = attachmentName;
        }
        
        attachmentCombos = [];
        for(i = 0; i <(attachments.size - 1); i++)
        {
            colIndex = tableLookupRowNum("mp/attachmentCombos.csv", 0, attachments[i]);
            for(j = i + 1; j < attachments.size; j++)
            {
                if(tableLookup("mp/attachmentCombos.csv", 0, attachments[j], colIndex) == "no")
                    continue;
                    
                attachmentCombos[attachmentCombos.size] = attachments[i] + "_" + attachments[j];
            }
        }
        
        foreach(combo in attachmentCombos)
        {
            level.weaponList[level.weaponList.size] = weapon_name + "_" + combo + "_mp";
        }
    }

    foreach(weaponName in level.weaponList)
    {
        precacheItem(weaponName);
    }
    
    precacheItem("flare_mp");
    precacheItem("scavenger_bag_mp");
    precacheItem("frag_grenade_short_mp");  
    precacheItem("destructible_car");
    
    precacheShellShock("default");
    precacheShellShock("concussion_grenade_mp");
    thread maps\mp\_flashgrenades::main();
    thread maps\mp\_entityheadicons::init();
    
    claymoreDetectionConeAngle = 70;
    level.claymoreDetectionDot = cos(claymoreDetectionConeAngle);
    level.claymoreDetectionMinDist = 20;
    level.claymoreDetectionGracePeriod = .75;
    level.claymoreDetonateRadius = 192;
    
    level.stingerFXid = loadfx("explosions/aerial_explosion_large");
    
    level.primary_weapon_array = [];
    level.side_arm_array = [];
    level.grenade_array = [];
    level.inventory_array = [];
    level.stow_priority_model_array = [];
    level.stow_offset_array = [];
    
    max_weapon_num = 149;
    for(i = 0; i < max_weapon_num; i++)
    {
        weapon = tableLookup("mp/statsTable.csv", 0, i, 4);
        stow_model = tableLookup("mp/statsTable.csv", 0, i, 9);
        
        if(stow_model == "")
            continue;
        
        precacheModel(stow_model);
        
        if(isSubStr(stow_model, "weapon_stow_"))
            level.stow_offset_array[ weapon ] = stow_model;
        else
            level.stow_priority_model_array[ weapon + "_mp" ] = stow_model;
    }
    
    precacheModel("weapon_claymore_bombsquad");
    precacheModel("weapon_c4_bombsquad");
    precacheModel("projectile_m67fraggrenade_bombsquad");
    precacheModel("projectile_semtex_grenade_bombsquad");
    precacheModel("weapon_light_stick_tactical_bombsquad");
    
    level.killStreakSpecialCaseWeapons = [];
    level.killStreakSpecialCaseWeapons["cobra_player_minigun_mp"] = true;
    level.killStreakSpecialCaseWeapons["artillery_mp"] = true;
    level.killStreakSpecialCaseWeapons["stealth_bomb_mp"] = true;
    level.killStreakSpecialCaseWeapons["pavelow_minigun_mp"] = true;
    level.killStreakSpecialCaseWeapons["sentry_minigun_mp"] = true;
    level.killStreakSpecialCaseWeapons["harrier_20mm_mp"] = true;
    level.killStreakSpecialCaseWeapons["ac130_105mm_mp"] = true;
    level.killStreakSpecialCaseWeapons["ac130_40mm_mp"] = true;
    level.killStreakSpecialCaseWeapons["ac130_25mm_mp"] = true;
    level.killStreakSpecialCaseWeapons["remotemissile_projectile_mp"] = true;
    level.killStreakSpecialCaseWeapons["cobra_20mm_mp"] = true;
    level.killStreakSpecialCaseWeapons["sentry_minigun_mp"] = true;
    
    level thread onPlayerConnect();
    
    level.c4explodethisframe = false;
    
    array_thread(getEntArray("misc_turret", "classname"), ::turret_monitorUse);
}

bombSquadWaiter()
{
    self endon("disconnect");
    
    for(;;)
    {
        self waittill("grenade_fire", weaponEnt, weaponName);
        
        team = level.otherTeam[self.team];
        
        if(weaponName == "c4_mp")
            weaponEnt thread createBombSquadModel("weapon_c4_bombsquad", "tag_origin", team, self);
        else if(weaponName == "claymore_mp")
            weaponEnt thread createBombSquadModel("weapon_claymore_bombsquad", "tag_origin", team, self);
        else if(weaponName == "frag_grenade_mp")
            weaponEnt thread createBombSquadModel("projectile_m67fraggrenade_bombsquad", "tag_weapon", team, self);
        else if(weaponName == "frag_grenade_short_mp")
            weaponEnt thread createBombSquadModel("projectile_m67fraggrenade_bombsquad", "tag_weapon", team, self);
        else if(weaponName == "semtex_mp")
            weaponEnt thread createBombSquadModel("projectile_semtex_grenade_bombsquad", "tag_weapon", team, self);
    }
}

createBombSquadModel(modelName, tagName, teamName, owner)
{
    bombSquadModel = spawn("script_model",(0,0,0));
    bombSquadModel hide();
    wait(0.05);
    
    if(!isDefined(self))
        return;
    
    bombSquadModel thread bombSquadVisibilityUpdater(teamName, owner);
    bombSquadModel setModel(modelName);
    bombSquadModel linkTo(self, tagName,(0,0,0),(0,0,0));
    bombSquadModel SetContents(0);
    
    self waittill("death");
    
    bombSquadModel delete();
}

bombSquadVisibilityUpdater(teamName, owner)
{
    self endon("death");

    foreach(player in level.players)
    {
        if(level.teamBased)
        {
            if(player.team == teamName && player _hasPerk("specialty_detectexplosive"))
                self showToPlayer(player);
        }
        else
        {
            if(isDefined(owner) && player == owner)
                continue;
            
            if(!player _hasPerk("specialty_detectexplosive"))
                continue;
                
            self showToPlayer(player);
        }       
    }
    
    for(;;)
    {
        level waittill_any("joined_team", "player_spawned", "changed_kit");
        
        self hide();

        foreach(player in level.players)
        {
            if(level.teamBased)
            {
                if(player.team == teamName && player _hasPerk("specialty_detectexplosive"))
                    self showToPlayer(player);
            }
            else
            {
                if(isDefined(owner) && player == owner)
                    continue;
                
                if(!player _hasPerk("specialty_detectexplosive"))
                    continue;
                    
                self showToPlayer(player);
            }       
        }
    }
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);

        player.hits = 0;
        player.hasDoneCombat = false;

        player KC_RegWeaponForFXRemoval("remotemissile_projectile_mp");

        player thread onPlayerSpawned();
        player thread bombSquadWaiter();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("spawned_player");
        
        self.currentWeaponAtSpawn = self getCurrentWeapon();
        
        self.empEndTime = 0;
        self.concussionEndTime = 0;
        self.hasDoneCombat = false;
        self thread watchWeaponUsage();
        self thread watchGrenadeUsage();
        self thread watchWeaponChange();
        self thread watchStingerUsage();
        self thread watchJavelinUsage();
        self thread watchMissileUsage();
        self thread watchSentryUsage();
        self thread watchWeaponReload();
        self thread maps\mp\gametypes\_class::trackRiotShield();

        self.lastHitTime = [];
        
        self.droppedDeathWeapon = undefined;
        self.tookWeaponFrom = [];
        
        self thread updateStowedWeapon();
        
        self thread updateSavedLastWeapon();
        
        if(self hasWeapon("semtex_mp"))
            self thread monitorSemtex();
        
        self.currentWeaponAtSpawn = undefined;
    }
}

WatchStingerUsage()
{
    self maps\mp\_stinger::StingerUsageLoop();
}

WatchJavelinUsage()
{
    self maps\mp\_javelin::JavelinUsageLoop();
}

watchWeaponChange()
{
    self endon("death");
    self endon("disconnect");
    
    self thread watchStartWeaponChange();
    self.lastDroppableWeapon = self.currentWeaponAtSpawn;
    self.hitsThisMag = [];

    weapon = self getCurrentWeapon();
    
    if(isCACPrimaryWeapon(weapon) && !isDefined(self.hitsThisMag[ weapon ]))
        self.hitsThisMag[ weapon ] = weaponClipSize(weapon);

    self.bothBarrels = undefined;

    if(isSubStr(weapon, "ranger"))
        self thread watchRangerUsage(weapon);

    while(1)
    {
        self waittill("weapon_change", newWeapon);
        
        tokedNewWeapon = StrTok(newWeapon, "_");

        self.bothBarrels = undefined;

        if(isSubStr(newWeapon, "ranger"))
            self thread watchRangerUsage(newWeapon);

        if(tokedNewWeapon[0] == "gl" ||(tokedNewWeapon.size > 2 && tokedNewWeapon[2] == "attach"))
            newWeapon = self getCurrentPrimaryWeapon();

        if(newWeapon != "none")
        {
            if(isCACPrimaryWeapon(newWeapon) && !isDefined(self.hitsThisMag[ newWeapon ]))
                self.hitsThisMag[ newWeapon ] = weaponClipSize(newWeapon);
        }
        self.changingWeapon = undefined;
        if(mayDropWeapon(newWeapon))
            self.lastDroppableWeapon = newWeapon;
    }
}

watchStartWeaponChange()
{
    self endon("death");
    self endon("disconnect");
    self.changingWeapon = undefined;

    while(1)
    {
        self waittill("weapon_switch_started", newWeapon);
        self.changingWeapon = newWeapon;
    }
}

watchWeaponReload()
{
    self endon("death");
    self endon("disconnect");

    for(;;)
    {
        self waittill("reload");

        weaponName = self getCurrentWeapon();

        self.bothBarrels = undefined;
        
        if(!isSubStr(weaponName, "ranger"))
            continue;

        self thread watchRangerUsage(weaponName);
    }
}

watchRangerUsage(rangerName)
{
    rightAmmo = self getWeaponAmmoClip(rangerName, "right");
    leftAmmo = self getWeaponAmmoClip(rangerName, "left");

    self endon("reload");
    self endon("weapon_change");

    for(;;)
    {
        self waittill("weapon_fired", weaponName);
        
        if(weaponName != rangerName)
            continue;

        self.bothBarrels = undefined;

        if(isSubStr(rangerName, "akimbo"))
        {
            newLeftAmmo = self getWeaponAmmoClip(rangerName, "left");
            newRightAmmo = self getWeaponAmmoClip(rangerName, "right");

            if(leftAmmo != newLeftAmmo && rightAmmo != newRightAmmo)
                self.bothBarrels = true;
            
            if(!newLeftAmmo || !newRightAmmo)
                return;
                
                
            leftAmmo = newLeftAmmo;
            rightAmmo = newRightAmmo;
        }
        else if(rightAmmo == 2 && !self getWeaponAmmoClip(rangerName, "right"))
        {
            self.bothBarrels = true;
            return;
        }
    }
}

isHackWeapon(weapon)
{
    if(weapon == "radar_mp" || weapon == "airstrike_mp" || weapon == "helicopter_mp")
        return true;
    if(weapon == "briefcase_bomb_mp")
        return true;
    return false;
}

mayDropWeapon(weapon)
{
    return false;
}

dropWeaponForDeath(attacker)
{
    return;
}

detachIfAttached(model, baseTag)
{
    attachSize = self getAttachSize();
    
    for(i = 0; i < attachSize; i++)
    {
        attach = self getAttachModelName(i);
        
        if(attach != model)
            continue;
        
        tag = self getAttachTagName(i);         
        self detach(model, tag);
        
        if(tag != baseTag)
        {
            attachSize = self getAttachSize();
            
            for(i = 0; i < attachSize; i++)
            {
                tag = self getAttachTagName(i);
                
                if(tag != baseTag)
                    continue;
                    
                model = self getAttachModelName(i);
                self detach(model, tag);
                
                break;
            }
        }       
        return true;
    }
    return false;
}

deletePickupAfterAWhile()
{
    self endon("death");
    
    wait 60;

    if(!isDefined(self))
        return;

    self delete();
}

getItemWeaponName()
{
    classname = self.classname;
    assert(getsubstr(classname, 0, 7) == "weapon_");
    weapname = getsubstr(classname, 7);
    return weapname;
}

watchPickup()
{
    self endon("death");
    
    weapname = self getItemWeaponName();
    
    while(1)
    {
        self waittill("trigger", player, droppedItem);
        
        if(isdefined(droppedItem))
            break;
    }

    assert(isdefined(player.tookWeaponFrom));

    droppedWeaponName = droppedItem getItemWeaponName();
    if(isdefined(player.tookWeaponFrom[ droppedWeaponName ]))
    {
        droppedItem.owner = player.tookWeaponFrom[ droppedWeaponName ];
        droppedItem.ownersattacker = player;
        player.tookWeaponFrom[ droppedWeaponName ] = undefined;
    }
    droppedItem thread watchPickup();
    
    if(isdefined(self.ownersattacker) && self.ownersattacker == player)
    {
        player.tookWeaponFrom[ weapname ] = self.owner;
    }
    else
    {
        player.tookWeaponFrom[ weapname ] = undefined;
    }
}

itemRemoveAmmoFromAltModes()
{
    origweapname = self getItemWeaponName();
    
    curweapname = weaponAltWeaponName(origweapname);
    
    altindex = 1;
    while(curweapname != "none" && curweapname != origweapname)
    {
        self itemWeaponSetAmmo(0, 0, 0, altindex);
        curweapname = weaponAltWeaponName(curweapname);
        altindex++;
    }
}

handleScavengerBagPickup(scrPlayer)
{
    self endon("death");
    level endon("game_ended");

    assert(isDefined(scrPlayer));

    self waittill("scavenger", destPlayer);
    assert(isDefined(destPlayer));

    destPlayer notify("scavenger_pickup");
    destPlayer playLocalSound("scavenger_pack_pickup");
    
    offhandWeapons = destPlayer getWeaponsListOffhands();
    
    if(destPlayer _hasPerk("specialty_tacticalinsertion") && destPlayer getAmmoCount("flare_mp") < 1)
        destPlayer _setPerk("specialty_tacticalinsertion"); 
    
    foreach(offhand in offhandWeapons)
    {       
        currentClipAmmo = destPlayer GetWeaponAmmoClip(offhand);
        destPlayer SetWeaponAmmoClip(offhand, currentClipAmmo + 1);
    }

    primaryWeapons = destPlayer getWeaponsListPrimaries();  
    foreach(primary in primaryWeapons)
    {
        if(!isCACPrimaryWeapon(primary) && !level.scavenger_secondary)
            continue;
            
        currentStockAmmo = destPlayer GetWeaponAmmoStock(primary);
        addStockAmmo = weaponClipSize(primary);
        
        destPlayer setWeaponAmmoStock(primary, currentStockAmmo + addStockAmmo);

        altWeapon = weaponAltWeaponName(primary);

        if(!isDefined(altWeapon) ||(altWeapon == "none") || !level.scavenger_altmode)
            continue;

        currentStockAmmo = destPlayer GetWeaponAmmoStock(altWeapon);
        addStockAmmo = weaponClipSize(altWeapon);

        destPlayer setWeaponAmmoStock(altWeapon, currentStockAmmo + addStockAmmo);
    }
    
    destPlayer maps\mp\gametypes\_damagefeedback::updateDamageFeedback("scavenger");
}

dropScavengerForDeath(attacker)
{
    if(level.inGracePeriod)
        return;
    
    if(!isDefined(attacker))
        return;

    if(attacker == self)
        return;

    dropBag = self dropScavengerBag("scavenger_bag_mp");    
    dropBag thread handleScavengerBagPickup(self);

}

getWeaponBasedGrenadeCount(weapon)
{
    return 2;
}

getWeaponBasedSmokeGrenadeCount(weapon)
{
    return 1;
}

getFragGrenadeCount()
{
    grenadetype = "frag_grenade_mp";

    count = self getammocount(grenadetype);
    return count;
}

getSmokeGrenadeCount()
{
    grenadetype = "smoke_grenade_mp";

    count = self getammocount(grenadetype);
    return count;
}

watchWeaponUsage(weaponHand)
{
    self endon("death");
    self endon("disconnect");
    level endon("game_ended");
    
    for(;;)
    {   
        self waittill("weapon_fired", weaponName);

        self.hasDoneCombat = true;

        if(!maps\mp\gametypes\_weapons::isPrimaryWeapon(weaponName) && !maps\mp\gametypes\_weapons::isSideArm(weaponName))
            continue;
        
        if(isDefined(self.hitsThisMag[ weaponName ]))
            self thread updateMagShots(weaponName);
            
        totalShots = self maps\mp\gametypes\_persistence::statGetBuffered("totalShots") + 1;
        hits = self maps\mp\gametypes\_persistence::statGetBuffered("hits");
        self maps\mp\gametypes\_persistence::statSetBuffered("totalShots", totalShots);
        self maps\mp\gametypes\_persistence::statSetBuffered("accuracy", int(hits * 10000 / totalShots));       
        self maps\mp\gametypes\_persistence::statSetBuffered("misses", int(totalShots - hits));
    }
}

updateMagShots(weaponName)
{
    self endon("death");
    self endon("disconnect");
    self endon("updateMagShots_" + weaponName);
    
    self.hitsThisMag[ weaponName ]--;
    
    wait(0.05);
    
    self.hitsThisMag[ weaponName ] = weaponClipSize(weaponName);
}

checkHitsThisMag(weaponName)
{
    self endon("death");
    self endon("disconnect");

    self notify("updateMagShots_" + weaponName);
    waittillframeend;
    
    if(self.hitsThisMag[ weaponName ] == 0)
    {
        weaponClass = getWeaponClass(weaponName);
        
        maps\mp\gametypes\_missions::genericChallenge(weaponClass);

        self.hitsThisMag[ weaponName ] = weaponClipSize(weaponName);
    }   
}

checkHit(weaponName, victim)
{
    if(!maps\mp\gametypes\_weapons::isPrimaryWeapon(weaponName) && !maps\mp\gametypes\_weapons::isSideArm(weaponName))
        return;

    waittillframeend;

    if(isDefined(self.hitsThisMag[ weaponName ]))
        self thread checkHitsThisMag(weaponName);

    if(!isDefined(self.lastHitTime[ weaponName ]))
        self.lastHitTime[ weaponName ] = 0;
    
    if(self.lastHitTime[ weaponName ] == getTime())
        return;

    self.lastHitTime[ weaponName ] = getTime();

    totalShots = self maps\mp\gametypes\_persistence::statGetBuffered("totalShots");        
    hits = self maps\mp\gametypes\_persistence::statGetBuffered("hits") + 1;

    if(hits <= totalShots)
    {
        self maps\mp\gametypes\_persistence::statSetBuffered("hits", hits);
        self maps\mp\gametypes\_persistence::statSetBuffered("misses", int(totalShots - hits));
        self maps\mp\gametypes\_persistence::statSetBuffered("accuracy", int(hits * 10000 / totalShots));
    }
}

attackerCanDamageItem(attacker, itemOwner)
{
    return friendlyFireCheck(itemOwner, attacker);
}

friendlyFireCheck(owner, attacker, forcedFriendlyFireRule)
{
    if(!isdefined(owner))
        return true;

    if(!level.teamBased)
        return true;

    attackerTeam = attacker.team;

    friendlyFireRule = level.friendlyfire;
    if(isdefined(forcedFriendlyFireRule))
        friendlyFireRule = forcedFriendlyFireRule;

    if(friendlyFireRule != 0)
        return true;

    if(attacker == owner)
        return true;

    if(!isdefined(attackerTeam))
        return true;

    if(attackerTeam != owner.team)
        return true;

    return false;
}

watchGrenadeUsage()
{
    self endon("death");
    self endon("disconnect");

    self.throwingGrenade = undefined;
    self.gotPullbackNotify = false;

    if(getIntProperty("scr_deleteexplosivesonspawn", 1) == 1)
    {
        if(isdefined(self.c4array))
        {
            for(i = 0; i < self.c4array.size; i++)
            {
                if(isdefined(self.c4array[ i ]))
                    self.c4array[ i ] delete();
            }
        }
        self.c4array = [];
        
        if(isdefined(self.claymorearray))
        {
            for(i = 0; i < self.claymorearray.size; i++)
            {
                if(isdefined(self.claymorearray[ i ]))
                    self.claymorearray[ i ] delete();
            }
        }
        self.claymorearray = [];
    }
    else
    {
        if(!isdefined(self.c4array))
            self.c4array = [];
        if(!isdefined(self.claymorearray))
            self.claymorearray = [];
    }

    thread watchC4();
    thread watchC4Detonation();
    thread watchC4AltDetonation();
    thread watchClaymores();
    thread deleteC4AndClaymoresOnDisconnect();

    self thread watchForThrowbacks();

    for(;;)
    {
        self waittill("grenade_pullback", weaponName);

        self.hasDoneCombat = true;

        if(weaponName == "claymore_mp")
            continue;

        self.throwingGrenade = weaponName;
        self.gotPullbackNotify = true;
        
        if(weaponName == "c4_mp")
            self beginC4Tracking();
        else
            self beginGrenadeTracking();
            
        self.throwingGrenade = undefined;
    }
}

beginGrenadeTracking()
{
    self endon("death");
    self endon("disconnect");
    self endon("offhand_end");
    self endon("weapon_change");

    startTime = getTime();

    self waittill("grenade_fire", grenade, weaponName);

    if((getTime() - startTime > 1000) && weaponName == "frag_grenade_mp")
        grenade.isCooked = true;

    self.changingWeapon = undefined;

    if(weaponName == "frag_grenade_mp" || weaponName == "semtex_mp")
    {
        grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
        grenade.originalOwner = self;
    }

    if(weaponName == "flash_grenade_mp" || weaponName == "concussion_grenade_mp")
    {
        grenade.owner = self;
        grenade thread empExplodeWaiter();
    }
}

AddMissileToSightTraces(team)
{
    self.team = team;
    level.missilesForSightTraces[ level.missilesForSightTraces.size ] = self;
    
    self waittill("death");
    
    newArray = [];
    foreach(missile in level.missilesForSightTraces)
    {
        if(missile != self)
            newArray[ newArray.size ] = missile;
    }
    level.missilesForSightTraces = newArray;
}

watchMissileUsage()
{
    self endon("death");
    self endon("disconnect");

    for(;;)
    {
        self waittill("missile_fire", missile, weaponName);
        
        if(isSubStr(weaponName, "gl_"))
        {
            missile.primaryWeapon = self getCurrentPrimaryWeapon();
            missile thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
        }
        
        switch(weaponName)
        {
            case "at4_mp":
            case "stinger_mp":
                level notify("stinger_fired", self, missile, self.stingerTarget);
                self thread setAltSceneObj(missile, "tag_origin", 65);
                break;
            case "javelin_mp":
                level notify("stinger_fired", self, missile, self.javelinTarget);
                self thread setAltSceneObj(missile, "tag_origin", 65);
                break;          
            default:
                break;
        }

        switch(weaponName)
        {
            case "at4_mp":
            case "javelin_mp":
            case "rpg_mp":
            case "ac130_105mm_mp":
            case "ac130_40mm_mp":
            case "remotemissile_projectile_mp":
                missile thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
            default:
                break;
        }
    }
}

watchSentryUsage()
{
    self endon("death");
    self endon("disconnect");

    for(;;)
    {
        self waittill("sentry_placement_finished", sentry);
        
        self thread setAltSceneObj(sentry, "tag_flash", 65);
    }
}

empExplodeWaiter()
{
    self thread maps\mp\gametypes\_shellshock::endOnDeath();
    self endon("end_explode");

    self waittill("explode", position);

    ents = getEMPDamageEnts(position, 512, false);

    foreach(ent in ents)
    {
        if(isDefined(ent.owner) && !friendlyFireCheck(self.owner, ent.owner))
            continue;

        ent notify("emp_damage", self.owner, 8.0);
    }
}

beginC4Tracking()
{
    self endon("death");
    self endon("disconnect");

    self waittill_any("grenade_fire", "weapon_change", "offhand_end");
}

watchForThrowbacks()
{
    self endon("death");
    self endon("disconnect");

    for(;;)
    {
        self waittill("grenade_fire", grenade, weapname);
        
        if(self.gotPullbackNotify)
        {
            self.gotPullbackNotify = false;
            continue;
        }
        if(!isSubStr(weapname, "frag_") && !isSubStr(weapname, "semtex_"))
            continue;
        
        grenade.threwBack = true;
        self thread incPlayerStat("throwbacks", 1);

        grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
        grenade.originalOwner = self;
    }
}

watchC4()
{
    self endon("spawned_player");
    self endon("disconnect");

    while(1)
    {
        self waittill("grenade_fire", c4, weapname);
        if(weapname == "c4" || weapname == "c4_mp")
        {
            if(!self.c4array.size)
                self thread watchC4AltDetonate();

            if(self.c4array.size)
            {
                self.c4array = array_removeUndefined(self.c4array);
                
                if(self.c4array.size >= level.maxPerPlayerExplosives)
                {
                    self.c4array[0] detonate();
                }
            }

            self.c4array[ self.c4array.size ] = c4;
            c4.owner = self;
            c4.team = self.team;
            c4.activated = false;
            c4.weaponName = weapname;

            c4 thread maps\mp\gametypes\_shellshock::c4_earthQuake();
            c4 thread c4Activate();
            c4 thread c4Damage();
            c4 thread c4EMPDamage();
            c4 thread c4EMPKillstreakWait();
        }
    }
}

c4EMPDamage()
{
    self endon("death");

    for(;;)
    {
        self waittill("emp_damage", attacker, duration);

        playfxOnTag(getfx("sentry_explode_mp"), self, "tag_origin");

        self.disabled = true;
        self notify("disabled");

        wait(duration);

        self.disabled = undefined;
        self notify("enabled");
    }
}

c4EMPKillstreakWait()
{
    self endon("death");

    for(;;)
    {
        level waittill("emp_update");

        if((level.teamBased && level.teamEMPed[self.team]) ||(!level.teamBased && isDefined(level.empPlayer) && level.empPlayer != self.owner))
        {
            self.disabled = true;
            self notify("disabled");
        }
        else
        {
            self.disabled = undefined;
            self notify("enabled");
        }
    }
}

setClaymoreTeamHeadIcon(team)
{
    self endon("death");
    wait .05;
    if(level.teamBased)
        self maps\mp\_entityheadicons::setTeamHeadIcon(team,(0, 0, 20));
    else if(isDefined(self.owner))
        self maps\mp\_entityheadicons::setPlayerHeadIcon(self.owner,(0,0,20));
}

watchClaymores()
{
    self endon("spawned_player");
    self endon("disconnect");

    self.claymorearray = [];
    while(1)
    {
        self waittill("grenade_fire", claymore, weapname);
        if(weapname == "claymore" || weapname == "claymore_mp")
        {
            self.claymorearray = array_removeUndefined(self.claymorearray);
            
            if(self.claymoreArray.size >= level.maxPerPlayerExplosives)
                self.claymoreArray[0] detonate();
            
            self.claymorearray[ self.claymorearray.size ] = claymore;
            claymore.owner = self;
            claymore.team = self.team;
            claymore.weaponName = weapname;

            claymore thread c4Damage();
            claymore thread c4EMPDamage();
            claymore thread c4EMPKillstreakWait();
            claymore thread claymoreDetonation();
            claymore thread setClaymoreTeamHeadIcon(self.pers[ "team" ]);
        }
    }
}

claymoreDetonation()
{
    self endon("death");

    self waittill("missile_stuck");

    damagearea = spawn("trigger_radius", self.origin +(0, 0, 0 - level.claymoreDetonateRadius), 0, level.claymoreDetonateRadius, level.claymoreDetonateRadius * 2);
    self thread deleteOnDeath(damagearea);

    while(1)
    {
        damagearea waittill("trigger", player);
        
        if(isdefined(self.owner) && player == self.owner)
            continue;
        
        if(!friendlyFireCheck(self.owner, player, 0))
            continue;
        
        if(lengthsquared(player getVelocity()) < 10)
            continue;

        if(!player shouldAffectClaymore(self))
            continue;

        if(player damageConeTrace(self.origin, self) > 0)
            break;
    }
    
    self playsound("claymore_activated");
    
    
    if(player _hasPerk("specialty_delaymine"))
        wait 3.0;
    else 
        wait level.claymoreDetectionGracePeriod;
        
    self detonate();
}

shouldAffectClaymore(claymore)
{
    if(isDefined(claymore.disabled))
        return false;

    pos = self.origin +(0, 0, 32);

    dirToPos = pos - claymore.origin;
    claymoreForward = anglesToForward(claymore.angles);

    dist = vectorDot(dirToPos, claymoreForward);
    if(dist < level.claymoreDetectionMinDist)
        return false;

    dirToPos = vectornormalize(dirToPos);

    dot = vectorDot(dirToPos, claymoreForward);
    return(dot > level.claymoreDetectionDot);
}

deleteOnDeath(ent)
{
    self waittill("death");
    wait .05;
    if(isdefined(ent))
        ent delete();
}

c4Activate()
{
    self endon("death");

    self waittill("missile_stuck");

    wait 0.05;

    self notify("activated");
    self.activated = true;
}

watchC4AltDetonate()
{
    self endon("death");
    self endon("disconnect");
    self endon("detonated");
    level endon("game_ended");

    buttonTime = 0;
    for(;;)
    {
        if(self UseButtonPressed())
        {
            buttonTime = 0;
            while(self UseButtonPressed())
            {
                buttonTime += 0.05;
                wait(0.05);
            }

            println("pressTime1: " + buttonTime);
            if(buttonTime >= 0.5)
                continue;

            buttonTime = 0;
            while(!self UseButtonPressed() && buttonTime < 0.5)
            {
                buttonTime += 0.05;
                wait(0.05);
            }

            println("delayTime: " + buttonTime);
            if(buttonTime >= 0.5)
                continue;

            if(!self.c4Array.size)
                return;

            self notify("alt_detonate");
        }
        wait(0.05);
    }
}

watchC4Detonation()
{
    self endon("death");
    self endon("disconnect");

    while(1)
    {
        self waittillmatch("detonate", "c4_mp");
        newarray = [];
        for(i = 0; i < self.c4array.size; i++)
        {
            c4 = self.c4array[ i ];
            if(isdefined(self.c4array[ i ]))
                c4 thread waitAndDetonate(0.1);
        }
        self.c4array = newarray;
        self notify("detonated");
    }
}

watchC4AltDetonation()
{
    self endon("death");
    self endon("disconnect");

    while(1)
    {
        self waittill("alt_detonate");
        weap = self getCurrentWeapon();
        if(weap != "c4_mp")
        {
            newarray = [];
            for(i = 0; i < self.c4array.size; i++)
            {
                c4 = self.c4array[ i ];
                if(isdefined(self.c4array[ i ]))
                    c4 thread waitAndDetonate(0.1);
            }
            self.c4array = newarray;
            self notify("detonated");
        }
    }
}

waitAndDetonate(delay)
{
    self endon("death");
    wait delay;

    self waitTillEnabled();

    self detonate();
}

deleteC4AndClaymoresOnDisconnect()
{
    self endon("death");
    self waittill("disconnect");

    c4array = self.c4array;
    claymorearray = self.claymorearray;

    wait .05;

    for(i = 0; i < c4array.size; i++)
    {
        if(isdefined(c4array[ i ]))
            c4array[ i ] delete();
    }
    for(i = 0; i < claymorearray.size; i++)
    {
        if(isdefined(claymorearray[ i ]))
            claymorearray[ i ] delete();
    }
}

c4Damage()
{
    self endon("death");

    self setcandamage(true);
    self.maxhealth = 100000;
    self.health = self.maxhealth;

    attacker = undefined;

    while(1)
    {
        self waittill("damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags);
        if(!isPlayer(attacker))
            continue;
        
        if(!friendlyFireCheck(self.owner, attacker))
            continue;

        if(damage < 5)
            continue;

        break;
    }

    if(level.c4explodethisframe)
        wait .1 + randomfloat(.4);
    else
        wait .05;

    if(!isdefined(self))
        return;

    level.c4explodethisframe = true;

    thread resetC4ExplodeThisFrame();

    if(isDefined(type) &&(isSubStr(type, "MOD_GRENADE") || isSubStr(type, "MOD_EXPLOSIVE")))
        self.wasChained = true;

    if(isDefined(iDFlags) &&(iDFlags & level.iDFLAGS_PENETRATION))
        self.wasDamagedFromBulletPenetration = true;

    self.wasDamaged = true;

    if(level.teamBased)
    {
        if(isdefined(attacker) && isdefined(attacker.pers[ "team" ]) && isdefined(self.owner) && isdefined(self.owner.pers[ "team" ]))
        {
            if(attacker.pers[ "team" ] != self.owner.pers[ "team" ])
                attacker notify("destroyed_explosive");
        }
    }
    else
    {
        if(isDefined(self.owner) && isDefined(attacker) && attacker != self.owner)
            attacker notify("destroyed_explosive");     
    }

    self detonate(attacker);
}

resetC4ExplodeThisFrame()
{
    wait .05;
    level.c4explodethisframe = false;
}

saydamaged(orig, amount)
{
    for(i = 0; i < 60; i++)
    {
        print3d(orig, "damaged! " + amount);
        wait .05;
    }
}

waitTillEnabled()
{
    if(!isDefined(self.disabled))
        return;

    self waittill("enabled");
    assert(!isDefined(self.disabled));
}

detectIconWaiter(detectTeam)
{
    self endon("end_detection");
    level endon("game_ended");

    while(!level.gameEnded)
    {
        self waittill("trigger", player);

        if(!player.detectExplosives)
            continue;

        if(level.teamBased && player.team != detectTeam)
            continue;
        else if(!level.teamBased && player == self.owner.owner)
            continue;

        if(isDefined(player.bombSquadIds[ self.detectId ]))
            continue;

        player thread showHeadIcon(self);
    }
}

setupBombSquad()
{
    self.bombSquadIds = [];

    if(self.detectExplosives && !self.bombSquadIcons.size)
    {
        for(index = 0; index < 4; index++)
        {
            self.bombSquadIcons[ index ] = newClientHudElem(self);
            self.bombSquadIcons[ index ].x = 0;
            self.bombSquadIcons[ index ].y = 0;
            self.bombSquadIcons[ index ].z = 0;
            self.bombSquadIcons[ index ].alpha = 0;
            self.bombSquadIcons[ index ].archived = true;
            self.bombSquadIcons[ index ] setShader("waypoint_bombsquad", 14, 14);
            self.bombSquadIcons[ index ] setWaypoint(false, false);
            self.bombSquadIcons[ index ].detectId = "";
        }
    }
    else if(!self.detectExplosives)
    {
        for(index = 0; index < self.bombSquadIcons.size; index++)
            self.bombSquadIcons[ index ] destroy();

        self.bombSquadIcons = [];
    }
}

showHeadIcon(trigger)
{
    triggerDetectId = trigger.detectId;
    useId = -1;
    for(index = 0; index < 4; index++)
    {
        detectId = self.bombSquadIcons[ index ].detectId;

        if(detectId == triggerDetectId)
            return;

        if(detectId == "")
            useId = index;
    }

    if(useId < 0)
        return;

    self.bombSquadIds[ triggerDetectId ] = true;

    self.bombSquadIcons[ useId ].x = trigger.origin[ 0 ];
    self.bombSquadIcons[ useId ].y = trigger.origin[ 1 ];
    self.bombSquadIcons[ useId ].z = trigger.origin[ 2 ] + 24 + 128;

    self.bombSquadIcons[ useId ] fadeOverTime(0.25);
    self.bombSquadIcons[ useId ].alpha = 1;
    self.bombSquadIcons[ useId ].detectId = trigger.detectId;

    while(isAlive(self) && isDefined(trigger) && self isTouching(trigger))
        wait(0.05);

    if(!isDefined(self))
        return;

    self.bombSquadIcons[ useId ].detectId = "";
    self.bombSquadIcons[ useId ] fadeOverTime(0.25);
    self.bombSquadIcons[ useId ].alpha = 0;
    self.bombSquadIds[ triggerDetectId ] = undefined;
}

getDamageableEnts(pos, radius, doLOS, startRadius)
{
    ents = [];

    if(!isdefined(doLOS))
        doLOS = false;

    if(!isdefined(startRadius))
        startRadius = 0;
    
    radiusSq = radius * radius;
    
    players = level.players;
    for(i = 0; i < players.size; i++)
    {
        if(!isalive(players[ i ]) || players[ i ].sessionstate != "playing")
            continue;

        playerpos = get_damageable_player_pos(players[ i ]);
        distSq = distanceSquared(pos, playerpos);
        if(distSq < radiusSq &&(!doLOS || weaponDamageTracePassed(pos, playerpos, startRadius, players[ i ])))
        {
            ents[ ents.size ] = get_damageable_player(players[ i ], playerpos);
        }
    }
    
    grenades = getentarray("grenade", "classname");
    for(i = 0; i < grenades.size; i++)
    {
        entpos = get_damageable_grenade_pos(grenades[ i ]);
        distSq = distanceSquared(pos, entpos);
        if(distSq < radiusSq &&(!doLOS || weaponDamageTracePassed(pos, entpos, startRadius, grenades[ i ])))
        {
            ents[ ents.size ] = get_damageable_grenade(grenades[ i ], entpos);
        }
    }

    destructibles = getentarray("destructible", "targetname");
    for(i = 0; i < destructibles.size; i++)
    {
        entpos = destructibles[ i ].origin;
        distSq = distanceSquared(pos, entpos);
        if(distSq < radiusSq &&(!doLOS || weaponDamageTracePassed(pos, entpos, startRadius, destructibles[ i ])))
        {
            newent = spawnstruct();
            newent.isPlayer = false;
            newent.isADestructable = false;
            newent.entity = destructibles[ i ];
            newent.damageCenter = entpos;
            ents[ ents.size ] = newent;
        }
    }

    destructables = getentarray("destructable", "targetname");
    for(i = 0; i < destructables.size; i++)
    {
        entpos = destructables[ i ].origin;
        distSq = distanceSquared(pos, entpos);
        if(distSq < radiusSq &&(!doLOS || weaponDamageTracePassed(pos, entpos, startRadius, destructables[ i ])))
        {
            newent = spawnstruct();
            newent.isPlayer = false;
            newent.isADestructable = true;
            newent.entity = destructables[ i ];
            newent.damageCenter = entpos;
            ents[ ents.size ] = newent;
        }
    }
    
    sentries = getentarray("misc_turret", "classname");
    foreach(sentry in sentries)
    {
        entpos = sentry.origin +(0,0,32);
        distSq = distanceSquared(pos, entpos);
        if(distSq < radiusSq &&(!doLOS || weaponDamageTracePassed(pos, entpos, startRadius, sentry)))
        {
            if(sentry.model == "sentry_minigun")
                ents[ ents.size ] = get_damageable_sentry(sentry, entpos);
        }
    }

    return ents;
}

getEMPDamageEnts(pos, radius, doLOS, startRadius)
{
    ents = [];

    if(!isDefined(doLOS))
        doLOS = false;

    if(!isDefined(startRadius))
        startRadius = 0;

    grenades = getEntArray("grenade", "classname");
    foreach(grenade in grenades)
    {
        entpos = grenade.origin;
        dist = distance(pos, entpos);
        if(dist < radius &&(!doLOS || weaponDamageTracePassed(pos, entpos, startRadius, grenade)))
            ents[ ents.size ] = grenade;
    }

    turrets = getEntArray("misc_turret", "classname");
    foreach(turret in turrets)
    {
        entpos = turret.origin;
        dist = distance(pos, entpos);
        if(dist < radius &&(!doLOS || weaponDamageTracePassed(pos, entpos, startRadius, turret)))
            ents[ ents.size ] = turret;
    }
    
    return ents;
}

weaponDamageTracePassed(from, to, startRadius, ent)
{
    midpos = undefined;

    diff = to - from;
    if(lengthsquared(diff) < startRadius * startRadius)
        return true;
    
    dir = vectornormalize(diff);
    midpos = from +(dir[ 0 ] * startRadius, dir[ 1 ] * startRadius, dir[ 2 ] * startRadius);

    trace = bullettrace(midpos, to, false, ent);

    return(trace[ "fraction" ] == 1);
}

damageEnt(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, damagepos, damagedir)
{
    if(self.isPlayer)
    {
        self.damageOrigin = damagepos;
        self.entity thread [[ level.callbackPlayerDamage ]](eInflictor, eAttacker, iDamage, 0, sMeansOfDeath, sWeapon, damagepos, damagedir, "none", 0);
    }
    else
    {
        if(self.isADestructable &&(sWeapon == "artillery_mp" || sWeapon == "claymore_mp") || sWeapon == "stealth_bomb_mp")
            return;

        self.entity notify("damage", iDamage, eAttacker,(0, 0, 0),(0, 0, 0), "mod_explosive", "", "");
    }
}

onWeaponDamage(eInflictor, sWeapon, meansOfDeath, damage, eAttacker)
{
    self endon("death");
    self endon("disconnect");

    switch(sWeapon)
    {
        case "concussion_grenade_mp":
            radius = 512;
            scale = 1 -(distance(self.origin, eInflictor.origin) / radius);

            if(scale < 0)
                scale = 0;

            time = 2 +(4 * scale);
            
            wait(0.05);
            eAttacker notify("stun_hit");
            self shellShock("concussion_grenade_mp", time);
            self.concussionEndTime = getTime() +(time * 1000);
        break;

        case "weapon_cobra_mk19_mp":
        break;

        default:
            maps\mp\gametypes\_shellshock::shellshockOnDamage(meansOfDeath, damage);
        break;
    }

}

isPrimaryWeapon(weapName)
{
    if(weapName == "none")
        return false;
        
    if(weaponInventoryType(weapName) != "primary")
        return false;

    switch(weaponClass(weapName))
    {
        case "rifle":
        case "smg":
        case "mg":
        case "spread":
        case "pistol":
        case "rocketlauncher":
        case "sniper":
            return true;

        default:
            return false;
    }   
}

isAltModeWeapon(weapName)
{
    if(weapName == "none")
        return false;
        
    return(weaponInventoryType(weapName) == "altmode");
}

isInventoryWeapon(weapName)
{
    if(weapName == "none")
        return false;
        
    return(weaponInventoryType(weapName) == "item");
}

isRiotShield(weapName)
{
    if(weapName == "none")
        return false;
        
    return(WeaponType(weapName) == "riotshield");
}

isOffhandWeapon(weapName)
{
    if(weapName == "none")
        return false;
        
    return(weaponInventoryType(weapName) == "offhand");
}

isSideArm(weapName)
{
    if(weapName == "none")
        return false;

    if(weaponInventoryType(weapName) != "primary")
        return false;

    return(weaponClass(weapName) == "pistol");
}

isGrenade(weapName)
{
    weapClass = weaponClass(weapName);
    weapType = weaponInventoryType(weapName);

    if(weapClass != "grenade")
        return false;
        
    if(weapType != "offhand")
        return false;
}

getStowOffsetModel(weaponName)
{
    assert(isDefined(level.stow_offset_array));

    baseName = getBaseWeaponName(weaponName);
    
    return(level.stow_offset_array[baseName]);
}

stowPriorityWeapon()
{
    assert(isdefined(level.stow_priority_model_array));

    foreach(weapon_name, priority_weapon in level.stow_priority_model_array)
    {
        weaponName = getBaseWeaponName(weapon_name);
        weaponList = self getWeaponsListAll();
        
        foreach(weapon in weaponList)
        {
            if(self getCurrentWeapon() == weapon)
                continue;
            
            if(weaponName == getBaseWeaponName(weapon))
                return weaponName + "_mp";
        }
    }

    return "";
}

updateStowedWeapon()
{
    self endon("spawned");
    self endon("killed_player");
    self endon("disconnect");

    self.tag_stowed_back = undefined;
    self.tag_stowed_hip = undefined;
    
    team = self.team;
    class = self.class;
    
    self thread stowedWeaponsRefresh();
    
    while(true)
    {
        self waittill("weapon_change", newWeapon);
        
        if(newWeapon == "none")
            continue;
            
        self thread stowedWeaponsRefresh();
    }
}

stowedWeaponsRefresh()
{
    self endon("spawned");
    self endon("killed_player");
    self endon("disconnect");
    
    detach_all_weapons();
    stow_on_back();
    stow_on_hip();
}

detach_all_weapons()
{
    if(isDefined(self.tag_stowed_back))
        self detach_back_weapon();

    if(isDefined(self.tag_stowed_hip))
        self detach_hip_weapon();
}

detach_back_weapon()
{
    detach_success = self detachIfAttached(self.tag_stowed_back, "tag_stowed_back");
    
    self.tag_stowed_back = undefined;
}

detach_hip_weapon()
{
    detach_success = self detachIfAttached(self.tag_stowed_hip, "tag_stowed_hip");
    
    self.tag_stowed_hip = undefined;
}

stow_on_back()
{
    prof_begin("stow_on_back");
    currentWeapon = self getCurrentWeapon();
    currentIsAlt = isAltModeWeapon(currentWeapon);

    assert(!isDefined(self.tag_stowed_back));

    stowWeapon = undefined;
    stowCamo = 0;
    large_projectile = self stowPriorityWeapon();
    stowOffsetModel = undefined;

    if(large_projectile != "")
    {
        stowWeapon = large_projectile;
    }
    else
    {
        weaponsList = self getWeaponsListPrimaries();
        foreach(weaponName in weaponsList)
        {
            if(weaponName == currentWeapon)
                continue;
            
            invType = weaponInventoryType(weaponName);
            
            if(invType != "primary")
            {
                if(invType == "altmode")
                    continue;
                
                if(weaponClass(weaponName) == "pistol")
                    continue;
            }
            
            if(WeaponType(weaponName) == "riotshield")
                continue;
            
            if(currentIsAlt && weaponAltWeaponName(weaponName) == currentWeapon)
                continue;
                
            stowWeapon = weaponName;
            stowOffsetModel = getStowOffsetModel(stowWeapon);
            
            if(stowWeapon == self.primaryWeapon)
                stowCamo = self.loadoutPrimaryCamo;
            else if(stowWeapon == self.secondaryWeapon)
                stowCamo = self.loadoutSecondaryCamo;
            else
                stowCamo = 0;
        }       
    }

    if(!isDefined(stowWeapon))
    {
        prof_end("stow_on_back");
        return;
    }

    if(large_projectile != "")
    {
        self.tag_stowed_back = level.stow_priority_model_array[ large_projectile ];
    }
    else
    {
        self.tag_stowed_back = getWeaponModel(stowWeapon, stowCamo);    
    }

    if(isDefined(stowOffsetModel))
    {
        self attach(stowOffsetModel, "tag_stowed_back", true);
        attachTag = "tag_stow_back_mid_attach";
    }
    else
    {
        attachTag = "tag_stowed_back";
    }

    self attach(self.tag_stowed_back, attachTag, true);

    hideTagList = GetWeaponHideTags(stowWeapon);

    if(!isDefined(hideTagList))
    {
        prof_end("stow_on_back");
        return;
    }

    for(i = 0; i < hideTagList.size; i++)
        self HidePart(hideTagList[ i ], self.tag_stowed_back);
    
    prof_end("stow_on_back");
}

stow_on_hip()
{
    currentWeapon = self getCurrentWeapon();

    assert(!isDefined(self.tag_stowed_hip));

    stowWeapon = undefined;

    weaponsList = self getWeaponsListOffhands();
    foreach(weaponName in weaponsList)
    {
        if(weaponName == currentWeapon)
            continue;
            
        if(weaponName != "c4_mp" && weaponName != "claymore_mp")
            continue;
        
        stowWeapon = weaponName;
    }

    if(!isDefined(stowWeapon))
        return;

    self.tag_stowed_hip = getWeaponModel(stowWeapon);
    self attach(self.tag_stowed_hip, "tag_stowed_hip_rear", true);

    hideTagList = GetWeaponHideTags(stowWeapon);
    
    if(!isDefined(hideTagList))
        return;
    
    for(i = 0; i < hideTagList.size; i++)
        self HidePart(hideTagList[ i ], self.tag_stowed_hip);
}

updateSavedLastWeapon()
{
    self endon("death");
    self endon("disconnect");

    currentWeapon = self.currentWeaponAtSpawn;
    self.saved_lastWeapon = currentWeapon;

    for(;;)
    {
        self waittill("weapon_change", newWeapon);
    
        if(newWeapon == "none")
        {
            self.saved_lastWeapon = currentWeapon;
            continue;
        }

        weaponInvType = weaponInventoryType(newWeapon);

        if(weaponInvType != "primary" && weaponInvType != "altmode")
        {
            self.saved_lastWeapon = currentWeapon;
            continue;
        }
        
        if(newWeapon == "onemanarmy_mp")
        {
            self.saved_lastWeapon = currentWeapon;
            continue;
        }

        self updateMoveSpeedScale("primary");

        self.saved_lastWeapon = currentWeapon;
        currentWeapon = newWeapon;
    }
}

EMPPlayer(numSeconds)
{
    self endon("disconnect");
    self endon("death");

    self thread clearEMPOnDeath();

}

clearEMPOnDeath()
{
    self endon("disconnect");

    self waittill("death");
}

updateMoveSpeedScale(weaponType)
{   
    if(!isDefined(weaponType) || weaponType == "primary" || weaponType != "secondary")
        weaponType = self.primaryWeapon;
    else
        weaponType = self.secondaryWeapon;
    
    if(isDefined(self.primaryWeapon) && self.primaryWeapon == "riotshield_mp")
    {
        self setMoveSpeedScale(.8 * self.moveSpeedScaler);
        return;
    }
    
    if(!isDefined(weaponType))
        weapClass = "none";
    else 
        weapClass = weaponClass(weaponType);
    
    
    switch(weapClass)
    {
        case "rifle":
            self setMoveSpeedScale(0.95 * self.moveSpeedScaler);
            break;
        case "pistol":
            self setMoveSpeedScale(1.0 * self.moveSpeedScaler);
            break;
        case "mg":
            self setMoveSpeedScale(0.875 * self.moveSpeedScaler);
            break;
        case "smg":
            self setMoveSpeedScale(1.0 * self.moveSpeedScaler);
            break;
        case "spread":
            self setMoveSpeedScale(.95 * self.moveSpeedScaler);
            break;
        case "rocketlauncher":
            self setMoveSpeedScale(0.80 * self.moveSpeedScaler);
            break;
        case "sniper":
            self setMoveSpeedScale(1.0 * self.moveSpeedScaler);
            break;
        default:
            self setMoveSpeedScale(1.0 * self.moveSpeedScaler);
            break;
    }
}

buildWeaponData(filterPerks)
{
    attachmentList = getAttachmentList();       
    max_weapon_num = 149;

    baseWeaponData = [];
    
    for(weaponId = 0; weaponId <= max_weapon_num; weaponId++)
    {
        baseName = tablelookup("mp/statstable.csv", 0, weaponId, 4);
        if(baseName == "")
            continue;

        assetName = baseName + "_mp";

        if(!isSubStr(tableLookup("mp/statsTable.csv", 0, weaponId, 2), "weapon_"))
            continue;
        
        if(weaponInventoryType(assetName) != "primary")
            continue;

        weaponInfo = spawnStruct();
        weaponInfo.baseName = baseName;
        weaponInfo.assetName = assetName;
        weaponInfo.variants = [];

        weaponInfo.variants[0] = assetName;
        attachmentNames = [];
        for(innerLoopCount = 0; innerLoopCount < 6; innerLoopCount++)
        {
            attachmentName = tablelookup("mp/statStable.csv", 0, weaponId, innerLoopCount + 11);
            
            if(filterPerks)
            {
                switch(attachmentName)
                {
                    case "fmj":
                    case "xmags":
                    case "rof":
                        continue;
                }
            }
            
            if(attachmentName == "")
                break;
            
            attachmentNames[attachmentName] = true;
        }

        attachments = [];
        foreach(attachmentName in attachmentList)
        {
            if(!isDefined(attachmentNames[attachmentName]))
                continue;
            
            weaponInfo.variants[weaponInfo.variants.size] = baseName + "_" + attachmentName + "_mp";
            attachments[attachments.size] = attachmentName;
        }

        for(i = 0; i <(attachments.size - 1); i++)
        {
            colIndex = tableLookupRowNum("mp/attachmentCombos.csv", 0, attachments[i]);
            for(j = i + 1; j < attachments.size; j++)
            {
                if(tableLookup("mp/attachmentCombos.csv", 0, attachments[j], colIndex) == "no")
                    continue;
                    
                weaponInfo.variants[weaponInfo.variants.size] = baseName + "_" + attachments[i] + "_" + attachments[j] + "_mp";
            }
        }
        
        baseWeaponData[baseName] = weaponInfo;
    }
    
    return(baseWeaponData);
}

monitorSemtex()
{
    self endon("disconnect");
    self endon("death");
    
    for(;;)
    {
        self waittill("grenade_fire", weapon);

        if(!isSubStr(weapon.model, "semtex"))
            continue;
            
        weapon waittill("missile_stuck", stuckTo);
            
        if(!isPlayer(stuckTo))
            continue;
            
        if(level.teamBased && isDefined(stuckTo.team) && stuckTo.team == self.team)
        {
            weapon.isStuck = "friendly";
            continue;
        }
    
        weapon.isStuck = "enemy";
        weapon.stuckEnemyEntity = stuckTo;
        
        stuckTo maps\mp\gametypes\_hud_message::playerCardSplashNotify("semtex_stuck", self);
        
        self thread maps\mp\gametypes\_hud_message::SplashNotify("stuck_semtex", 100);
        self notify("process", "ch_bullseye");
    }   
}

turret_monitorUse()
{
    for(;;)
    {
        self waittill("trigger", player);
        
        self thread turret_playerThread(player);
    }
}

turret_playerThread(player)
{
    player endon("death");
    player endon("disconnect");

    player notify("weapon_change", "none");
    
    self waittill("turret_deactivate");
    
    player notify("weapon_change", player getCurrentWeapon());
}
