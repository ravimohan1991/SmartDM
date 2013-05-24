SmartDM
=======

Mutator for Unreal Tournament G.O.T.Y

==================================================================================================
Product - SmartDM 
Version - 0.8.4.9
Author  - The_Cowboy
Release Date - July 03 ,2011
==================================================================================================

SmartDM is a mutator which adds a smart scoreboard and many new stats/features for Deathmatches.


==================================================================================================
COMPATIBILITY
==================================================================================================

"non-team gametypes"
a) DeathMatch 
b) LastManStanding  


==================================================================================================
FEATURES
==================================================================================================

Scoreboard(s)
~~~~~~~~~~~~~
SmartDM supports external Scoreboards.If you are developer ,you are more than welcome to make new
scorboards (like snowyscoreboard etc ).
I have provided a Default scoreboard.For more information read Scoreboard.txt
SmartDM can automatically bind "ShowScoreboard" to F3.

Stats
~~~~~
SmartDM tracks many interesting stats for DeathMatches.

a) Efficiency (Calculated in scoreboard)
b) Picups - All pickups like armour ,shieldbelts ,amplifiers ,jumpboots etc
c) Survivability - Defined by (AwakeTime)/(num_of_deaths)
                  AwakeTime is time between Spawn of player and his/her death.
d) Sucides
e) SpreeEnds - Number of sprees ended by this player
f) Sprees - Tracked till Godlike ( after godlike messages are shown but not recorded )
g) MultiLevelKills - Tracked till MonsterKills       
h) TimePlayed
g) Headshots
h) SpawnKills
i) Frags - SmartDM 

Detections
~~~~~~~~~~
SmartDM detects longrange kills and multilevel kills and announces same.Read settings sections for more info.


Server Info
~~~~~~~~~~~
ServerInfo pops up when F2 is pressed.It contains the records of Players having best stats.

IpToCountry Support
~~~~~~~~~~~~~~~~~~~
SmartDM has IpToCountry support.
SmartDM recommends latest version of IpToCountry.



==================================================================================================
INSTALLATION
==================================================================================================

Turn off the server!
Extract SmartDM(version).u and Scoreboard.u(Any SmartDM compatible Scoreboard ) to system folder
Turn off the server if not already done!!
Open server.ini 
Scroll to [Engine.GameEngine] section

ServerPackages=SmartDM0849
ServerPackages=SmartDMScoreBoard084910( or custom scoreboard )
ServerActors=ipToCountry.LinkActor
ServerActors=UTPureRC7G.UTPureSA
ServerActors=SmartDM0849.SmartDMServerActor

Be carefull to follow this order of serveractors.That is SmartDM serveractor should come after 
iptocountry and utpure(if you have) serveractors.



==================================================================================================
CONFIGURING SmartDM
==================================================================================================

bEnabled=True
CountryFlagsPackage=CountryFlags2

bEnhancedMultiKill=True
For announcing MultiLevelKilling.You should not use MonsterAnnouncer or similar mods 
if you set this to true 

EnhancedMultiKillBroadcast=2
This will decide from which multi level kill the message should be broadcasted
2 = all multilevel kills will be broadcasted
3 = all multilevel kills after double kill will be broadcasted.
4 = so on...... 

bSmartDMServerInfo=True
bSpawnkillDetection=True
SpawnKillTimeArena=1.000000
SpawnKillTimeNW=3.500000
bAfterGodLikeMsg=True
bStatsDrawFaces=True
bDrawLogo=True
bSDMSbDef=True
Should SmartDM scoreboard be the default one ?

bShowSpecs=True
Should spectators be shown ?

bDoKeybind=True
SbDelay=4
After how much seconds should the scoreboard load.

bShowLongRangeMsg=False
bShowSpawnKillerGlobalMsg=True

bNewFragSystem=False
If set to true, frags will be shown instead of score
Note:
Score = Frags-Deaths
Frags = Number of kills
If this is set true then match will end only if player gets Frags = FragLimit of game
 
ScoreBoardType=SmartDMScoreBoard0849-10.SmartDMScoreBoard  
 
 
Rest options( not mentioned here but shown in SmartDM.ini ) and not yet functional.




==================================================================================================
THANKS
==================================================================================================

SMartDM is based on code of SmartCTF. Therefore I want to thank all of its authors. Let me name them

1){PiN}Kev
2){DnF2}SiNiSTeR 
3)Rush
4)adminthis
5)Spongebob

Besides I would like to thank D for his nice suggestions and beta testing.  



==================================================================================================
FEEDBACK
==================================================================================================

If you have some suggestions then please inform me here
http://www.unrealadmin.org/forums/showthread.php?t=30603&highlight=smartdm


 
