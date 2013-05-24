SmartDM
=======

SmartDM is a mutator for Unreal Tournament G.O.T.Y, which adds a smart scoreboard and many new statistics/features for 
Deathmatches.

DETAILS
========
* Version - 0.8.4.9
* Release Date - July 03, 2011


COMPATIBILITY
==================================================================================================

SmartDM supports non-team gametypes:

1. DeathMatch 
2. LastManStanding



FEATURES
==================================================================================================

Scoreboard
-----------
SmartDM has been designed to support external scoreboards. If you are developer, you are more than 
welcome to make custom scorboards (like snowyscoreboard etc).
I have provided a default scoreboard. An extract from its readme.



        Product - SmartDMScoreBoard 
        Version - 0.8.4.9.1.0
        Author  - The_Cowboy
        Release Date - July 03, 2011
        ==================================================================================================
        COMPATIBILITY
        ==================================================================================================
        This version can detect default LMS and shows Lives left instead of Score/Frags.
        
        
        ==================================================================================================
        FEATURES
        ==================================================================================================

        This ScoreBoard has somewhat same looks as that of SmartCTF.

        -> Player's faces 

        -> country flags 

        -> Frags/Score
        If bNewFragSystem is set to true then Frags are shown else Score (Frags-deaths) are shown in 
        Deathmatch.In LMS Lives left are shown.

        -> Pickups
          SB = Shield Belts
          TH = Thigh Pads
          AM = Amplifiers
          JB = Jump Boots
          AR = Armors
          These are shown in right side of the player's face ,in small font.

        -> Other stuff
          TIME = Time played on the server
          HS = Head Shots taken

        -> Stats
        -> Eff = Efficiency is defined by Frags/(Frags+Deaths).It is shown in % and a bar is displayed
        -> Surv = Survivability is defined as timeawake( time between spawn and death )/num_of_deaths
        -> SprEnd = Number of SpreesEnded by the player
        -> Sucides
        -> MultKil = Multi kills
          DK = Double Kill
          TK = triple kill
          MK = multi kill   
          MeK = megak ill
          UK = Ultra kill
          MK = monster kill
        -> Sprees
          KS = Killing SPree
          RA = Rampage
          DO = Dominating
          UN = Unstoppable
          GD = Godlike
        -> PlayerNames are followed by their ranks

        -> In LMS the players havin 0 lives left are shown in grey.

        -> Server's name and time elasped are shown in the footer
 
 
        ==================================================================================================
        INSTALLATION
        ==================================================================================================

        Turn off the server!
        Scoreboard084910.u to system folder

        Open server.ini 
        Scroll to [Engine.GameEngine] section and add
        
        ServerPackages=SmartDMScoreBoard084910

        Open SmartDM.ini and set 
        ScoreBoardType=SmartDMScoreBoard084910.SmartDMScoreBoard


        ==================================================================================================
        CONFIGURING SmartDMScoreboard
        ==================================================================================================

        No configuration!


        ==================================================================================================
        THANKS
        ==================================================================================================

        SMartDMScoreBoard is based on code of SmartCTF4D. Therefore I want to thank all of its authors. Let me 
        name them

        1){PiN}Kev
        2){DnF2}SiNiSTeR 
        3)Rush

        Besides I would like to thank D for his nice suggestions and beta testing.  


SmartDM can automatically bind "ShowScoreboard" to F3.

Player statistics
------------------
SmartDM tracks interesting player statistics which further create interest in gameplay.

* Efficiency (Calculated in scoreboard)
* Pickups - All pickups like armour, shieldbelts, amplifiers, jumpboots and any custom pickup. 
* Survivability - Defined by (AwakeTime)/(num_of_deaths)
                  AwakeTime is time difference of spawntime of player and his/her death.
* Suicides
* SpreeEnds - Number of sprees ended by this player.
* Sprees - Tracked till Godlike (after godlike messages are shown but not recorded).
* MultiLevelKills - Tracked till MonsterKills.       
* TimePlayed
* Headshots
* SpawnKills
* Frags



Detections
-----------
SmartDM detects longrange kills and multilevel kills and announces same. Read settings 
sections for more info.


Server Information
-------------------
ServerInfo pops up when F2 is pressed. It shows the records of players having best stats.


IpToCountry Support
-------------------
SmartDM has IpToCountry support. It means you can see the country flag below the face of the
player in scoreboard. SmartDM recommends latest version of IpToCountry.




INSTALLATION
==================================================================================================

* Turn off the server!
* Extract SmartDM(version).u and Scoreboard.u (or any SmartDM compatible Scoreboard) to system folder
* Open server.ini 
* Scroll to [Engine.GameEngine] section. There you you should add ServerPackages and ServerActor variables as follows
        
        ServerPackages=SmartDM0849
        ServerPackages=SmartDMScoreBoard084910 (or custom scoreboard)
        ServerActors=ipToCountry.LinkActor
        ServerActors=UTPureRC7G.UTPureSA
        ServerActors=SmartDM0849.SmartDMServerActor

* Be carefull to follow this order of server variables. That is SmartDM serveractors should come after 
iptocountry and utpure (if you have) serveractors.




CONFIGURING SmartDM
==================================================================================================

* bEnabled=True
* CountryFlagsPackage=CountryFlags2

* bEnhancedMultiKill=True
For announcing MultiLevelKilling.You should not use MonsterAnnouncer or similar mods 
if you set this to true 

* EnhancedMultiKillBroadcast=2
This will decide from which multi level kill the message should be broadcasted
2 = all multilevel kills will be broadcasted
3 = all multilevel kills after double kill will be broadcasted.
4 = so on...... 

* bSmartDMServerInfo=True
* bSpawnkillDetection=True
* SpawnKillTimeArena=1.000000
* SpawnKillTimeNW=3.500000
* bAfterGodLikeMsg=True
* bStatsDrawFaces=True
* bDrawLogo=True
* bSDMSbDef=True
Should SmartDM scoreboard be the default one ?

* bShowSpecs=True
Should spectators be shown ?

* bDoKeybind=True
* SbDelay=4
After how much seconds should the scoreboard load.

* bShowLongRangeMsg=False
* bShowSpawnKillerGlobalMsg=True

* bNewFragSystem=False
If set to true, frags will be shown instead of score
Note:
Score = Frags-Deaths
Frags = Number of kills
If this is set true then match will end only if player gets Frags = FragLimit of game
 
* ScoreBoardType=SmartDMScoreBoard0849-10.SmartDMScoreBoard  
 
 
Rest options (not mentioned here but shown in SmartDM.ini) and not yet functional.




THANKS
==================================================================================================

SMartDM is based on code of SmartCTF. Therefore I want to thank all of its authors. Let me name them

* {PiN}Kev
* {DnF2}SiNiSTeR 
* Rush
* adminthis
* Spongebob

Besides I would like to thank D for his nice suggestions and beta testing.  




FEEDBACK
==================================================================================================

If you have some suggestions then please inform me here
http://www.unrealadmin.org/forums/showthread.php?t=30603&highlight=smartdm


 
