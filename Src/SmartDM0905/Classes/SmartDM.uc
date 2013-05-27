class SmartDM expands Mutator config( SmartDM );

#exec texture IMPORT NAME=powered File=Textures\powered.pcx GROUP=SmartDM MIPS=OFF

/* Server Vars */
var SmartDMGameReplicationInfo SDMGame;
var string Version;
var int MsgPID;
var bool bForcedEndGame, bTournamentGameStarted, bStartTimeCorrected;
var PlayerPawn LostLead;

/* Client Vars */
var byte TRCount;
var bool bClientJoinPlayer, bGameEnded, bInitSb;
var int LogoCounter, DrawLogo, SbCount;
var float SbDelayC;
var PlayerPawn PlayerOwner;
var FontInfo MyFonts;
var TournamentGameReplicationInfo pTGRI;
var PlayerReplicationInfo pPRI;
var ChallengeHUD MyHUD;
var color White, Gray;

/* Server Vars Configurable */
var() config bool bEnabled;
var() config string ScoreBoardType;
var() config string CountryFlagsPackage;
var() config bool bEnhancedMultiKill;
var() config byte EnhancedMultiKillBroadcast;
var() config bool bSmartDMServerInfo;
var() config bool bSpawnkillDetection;
var() config float SpawnKillTimeArena;
var() config float SpawnKillTimeNW;
var() config bool bNewFragSystem;
var() config bool bAfterGodLikeMsg;
var() config bool bStatsDrawFaces;
var() config bool bDrawLogo;
var() config bool bSDMSbDef;
var() config bool bShowSpecs;
var() config bool bDoKeybind;
var() config bool bExtraMsg;
var() config float SbDelay;
var() config float MsgDelay;
var(SmartDMMessages) config bool bShowLongRangeMsg;
var(SmartDMMessages) config bool bShowSpawnKillerGlobalMsg;
//var(SmartDMSounds) config bool bPlayLeadSound;
var(SmartDMSounds) config bool bPlay30SecSound;

var texture powered;

event Spawned()
{
  super.Spawned();

  SDMGame = Level.Game.Spawn( class'SmartDMGameReplicationInfo' );

  if( !ValidateSmartDMMutator() )
  {
    SDMGame.Destroy();
    Destroy();
  }
}

/*
 * Returns True or False whether to keep this SmartDM mutator instance, and sets bInitialized accordingly.
 */
function bool ValidateSmartDMMutator()
{
  local Mutator M;
  local bool bRunning;

  M = Level.Game.BaseMutator;
  while( M != None )
  {
    if( M != Self && M.Class == Self.Class )
    {
      bRunning = True;
      break;
    }
    M = M.NextMutator;
  }

  if( !bEnabled )
    Log( "Instance" @ Name @ "not loaded because bEnabled in .ini = False.", 'SmartDM' );
  else if( bRunning )
    Log( "Instance" @ name @ "not loaded because it is already running.", 'SmartDM' );
  else
    SDMGame.bInitialized = True;

  return SDMGame.bInitialized;
}

/*
 * Get the original Scoreboard and store for SmartDMScoreboard/Custom Scoreboard reference.
 */
function PreBeginPlay()
{
  local Mutator M;
  local class<scoreboard> SmartScoreBoard;

  super.PreBeginPlay();

  Log( "Searching for Smart Scoreboard..." , 'SmartDM' );
  SmartScoreBoard = class<scoreboard>( DynamicLoadObject( ScoreBoardType ,class'Class' ) );

  SDMGame.NormalScoreBoardClass = Level.Game.ScoreBoardType;

  if( SmartScoreBoard != none )
  {
   Log( "SUCCESS - A Smart Scoreboard is found" , 'SmartDM' );
   Log( "SmartDM"$Version$" will use "$SmartScoreboard$" as its Scoreboard" , 'SmartDM' );
   Level.Game.ScoreBoardType = SmartScoreBoard;//class'SmartDMScoreBoard';
  }
  else
  {
   Log( "WANRING!! Smart ScoreBoard not found ", 'SmartDM' );
   Log( "WANRING!! Using epic's default Scoreboard ", 'SmartDM' );
  }

  Log( "Original Scoreboard determined as" @ SDMGame.NormalScoreBoardClass, 'SmartDM' );

  // Change F2 Server Info screen, compatible with UTPure
  if( bSmartDMServerInfo )
  {
    class<ChallengeHUD>( Level.Game.HUDType ).default.ServerInfoClass = class'SmartDMServerInfo';
    for( M = Level.Game.BaseMutator; M != None; M = M.NextMutator )
    {
      if( M.IsA( 'UTPure' ) ) // Let UTPure rehandle the scoreboard
      {
        M.PreBeginPlay();
        SDMGame.bServerInfoSetServerSide = True; // No need for the old fashioned way - it can be set server side.
        Log( "Notified UTPure HUD to use SmartDM ServerInfo.", 'SmartDM' );
        break;
      }
    }
    if( SDMGame.bServerInfoSetServerSide && Level.Game.HUDType.Name != 'PureDMHUD' )
    {
      // In this scenario another mod intervered and we still have to do it the old fashion way.
      SDMGame.bServerInfoSetServerSide = False;
      Log( "HUD is not the UTPure HUD but" @ Level.Game.HUDType.Name $ ", so SmartDM ServerInfo will be set clientside.", 'SmartDM' );
    }
    if( !SDMGame.bServerInfoSetServerSide ) SDMGame.DefaultHUDType = Level.Game.HUDType; // And in the old fashion way, the client will have to know the current HUD type.
  }
  else
  {
    SDMGame.bServerInfoSetServerSide = True; // We didn't change anything, but neither do we want clientside intervention.
  }
}


/*
 * Startup and initialize.
 */
function PostBeginPlay()
{
  local Actor A;
  local Actor IpToCountry;

  Level.Game.Spawn( class'SmartDMSpawnNotifyPRI');

  SaveConfig(); // Create the .ini if its not already there.

  // Since we have problem replicating config variables...
  SDMGame.bPlay30SecSound = bPlay30SecSound;
  SDMGame.bStatsDrawFaces = bStatsDrawFaces;
  SDMGame.bDrawLogo = bDrawLogo;
  SDMGame.CountryFlagsPackage = CountryFlagsPackage;
  SDMGame.bSDMSbDef = bSDMSbDef;
  SDMGame.bShowSpecs = bShowSpecs;
  SDMGame.bDoKeybind = bDoKeybind;
  SDMGame.bNewFragSystem = bNewFragSystem;
  SDMGame.SbDelayC = SbDelayC;

  // Works serverside!
  if( bEnhancedMultiKill ) Level.Game.DeathMessageClass = class'SmartDMEnhancedDeathMessagePlus';

  SDMGame.EndStats = Spawn( class'SmartDMEndStats', self );

  super.PostBeginPlay();

  if( Level.NetMode == NM_DedicatedServer ) SetTimer( 1.0 , True);

  MsgPID=-1; // First PID is 0, so it wouldn't get messaged if we kept MsgPID at it's default value.

  Log( "SmartDM" @ Version @ "loaded successfully.", 'SmartDM' );
}

function ModifyPlayer( Pawn Other )
{
  local SmartDMPlayerReplicationInfo OtherStats;

  OtherStats = SDMGame.GetStats( Other );
  if( OtherStats == None ) return;

  if( !OtherStats.bHadFirstSpawn )
  {
    OtherStats.bHadFirstSpawn = True;
    FirstSpawn( Other );
    OtherStats.SpawnTime = Level.TimeSeconds;
  }
  else
    OtherStats.SpawnTime = Level.TimeSeconds;

  super.ModifyPlayer( Other );
}

/*
 * Gets called when a new player or bot joins the game, that is when they first spawn.
 */
function FirstSpawn( Pawn Other )
{
  local byte ID;
  local string SkinName, FaceName;

  // Additional logging, useful for player tracking
  if( Level.Game.LocalLog != none && PlayerPawn( Other ) != none && Other.bIsPlayer )
  {
    ID = PlayerPawn( Other ).PlayerReplicationInfo.PlayerID;
    Level.Game.LocalLog.LogSpecialEvent( "IP", ID, PlayerPawn( Other ).GetPlayerNetworkAddress() );
    Level.Game.LocalLog.LogSpecialEvent( "player", "NetSpeed", ID, PlayerPawn( Other ).Player.CurrentNetSpeed );
    Level.Game.LocalLog.LogSpecialEvent( "player", "Fov", ID, PlayerPawn( Other ).FovAngle );
    Level.Game.LocalLog.LogSpecialEvent( "player", "VoiceType", ID, Other.VoiceType );
    if( Other.IsA( 'TournamentPlayer' ) )
    {
      if( Other.Skin == None )
      {
        Other.static.GetMultiSkin( Other, SkinName, FaceName );
      }
      else
      {
        SkinName = string( Other.Skin );
        FaceName = "None";
      }
      Level.Game.LocalLog.LogSpecialEvent( "player", "Skin", ID, SkinName );
      Level.Game.LocalLog.LogSpecialEvent( "player", "Face", ID, FaceName );
    }
  }
}

/*
 * Adjust SmartDMPlayerReplication Data.
 */
function bool PreventDeath( Pawn Victim, Pawn Killer, name DamageType, vector HitLocation )
{
  local PlayerReplicationInfo VictimPRI, KillerPRI;
  local bool bPrevent;
  local Pawn pn;
  local float TimeAwake;
  local SmartDMPlayerReplicationInfo KillerStats, VictimStats;
  local int VFragSpree;

  bPrevent = super.PreventDeath( Victim, Killer, DamageType, HitLocation );
  if( bPrevent ) return bPrevent; // Player didn't die, so return.

  // If there is no victim, return.
  if( Victim == None ) return bPrevent;
  VictimPRI = Victim.PlayerReplicationInfo;
  if( VictimPRI == none || !Victim.bIsPlayer || ( VictimPRI.bIsSpectator && !VictimPRI.bWaitingPlayer ) ) return bPrevent;
  VictimStats = SDMGame.GetStats( Victim );

  if( VictimStats == none )  return bPrevent;

  VFragSpree = VictimStats.FragSpree; // To see weather he was on spree
  TimeAwake = Level.TimeSeconds - VictimStats.SpawnTime;
  if( VictimStats.bHadFirstSpawn ) //Strange time comes when this check is not done
  {
   VictimStats.AwakeTime += TimeAwake;
   VictimStats.SurCount++;
  }

  switch( VictimStats.FragSpree/5 )
  {
   case 0:
          break;
   case 1: VictimStats.KillingSpree++;
          break;
   case 2: VictimStats.Rampage++;
          break;
   case 3: VictimStats.Dominating++;
          break;
   case 4: VictimStats.Unstoppable++;
          break;
   default: VictimStats.GodLike++;
          break;
  }
  VictimStats.FragSpree = 0; // Reset FragSpree for Victim
  VictimStats.SpawnKillSpree = 0;

  // if there is no killer / suicide, return.
  if( Killer == None || Killer == Victim )
  {
    if( bEnhancedMultiKill && EnhancedMultiKillBroadcast > 0 ) VictimStats.MultiLevel = 0;
    VictimStats.Sucide++;
    return bPrevent;
  }
  KillerPRI = Killer.PlayerReplicationInfo;
  if( KillerPRI == None || !Killer.bIsPlayer || ( KillerPRI.bIsSpectator && !KillerPRI.bWaitingPlayer ) ) return bPrevent;
  KillerStats = SDMGame.GetStats( Killer );

  if( KillerStats == none )  return bPrevent;

  // Increase Frags and FragSpree for Killer (Play "Too Easy" at 30)
  KillerStats.Frags++;
  KillerStats.FragSpree++;

  if( VFragSpree >= 5 )
   KillerStats.SpreeEnded++;

  switch( VictimStats.MultiLevel )
     {
      case 0:
              break;
      case 1: VictimStats.DoubleKill++;
              break;
      case 2: VictimStats.TripleKill++;
              break;
      case 3: VictimStats.MultiKill++;
              break;
      case 4: VictimStats.Megakill++;
              break;
      case 5: VictimStats.UltraKill++;
              break;
      default: VictimStats.MonsterKill++;
              break;
     }
  VictimStats.MultiLevel = 0;

  if( Level.TimeSeconds - KillerStats.LastKillTime < 3 )
   {
     KillerStats.MultiLevel++;
     if( KillerStats.MultiLevel + 1 >= EnhancedMultiKillBroadcast ) Level.Game.BroadcastMessage( KillerPRI.PlayerName @ class'SmartDMEnhancedMultiKillMessage'.static.GetBroadcastString( KillerStats.MultiLevel ) );
   }
  else
   {
     switch( KillerStats.MultiLevel )
     {
      case 0:
              break;
      case 1: KillerStats.DoubleKill++;
              break;
      case 2: KillerStats.TripleKill++;
              break;
      case 3: KillerStats.MultiKill++;
              break;
      case 4: KillerStats.Megakill++;
              break;
      case 5: KillerStats.UltraKill++;
              break;
      default: KillerStats.MonsterKill++;
              break;
     }
     KillerStats.MultiLevel = 0;
   }
  KillerStats.LastKillTime = Level.TimeSeconds;


  if( bAfterGodLikeMsg && ( KillerStats.FragSpree == 30 || KillerStats.FragSpree == 35 ) )
  {
    for( pn = Level.PawnList; pn != None; pn = pn.NextPawn )
    {
      if( pn.IsA( 'TournamentPlayer' ) )
        pn.ReceiveLocalizedMessage( class'SmartDMSpreeMsg', KillerStats.FragSpree / 5 - 1, KillerPRI );
    }
  }

  // Uber / Long Range kill if not sniper, HeadShot, trans, deemer, instarifle, or vengeance relic.
  if( bShowLongRangeMsg && TournamentPlayer( Killer ) != None )
  {
    if( DamageType != 'shot' && DamageType != 'decapitated' && DamageType != 'Gibbed' && DamageType != 'RedeemerDeath' && SuperShockRifle( Killer.Weapon ) == none && DamageType != 'Eradicated' )
    {
      if( VSize( Killer.Location - Victim.Location ) > 1536 )
      {
        if( VSize( Killer.Location - Victim.Location ) > 3072 )
        {
          Killer.ReceiveLocalizedMessage( class'SmartDMCoolMsg', 2, KillerPRI, VictimPRI );
        }
        else
        {
          Killer.ReceiveLocalizedMessage( class'SmartDMCoolMsg', 1, KillerPRI, VictimPRI );
        }
        // Log special kill.
        if( Level.Game.LocalLog != None ) Level.Game.LocalLog.LogSpecialEvent( "longrangekill", KillerPRI.PlayerID, VictimPRI.PlayerID );
      }
    }
  }

  // HeadShot tracking
  if( DamageType == 'decapitated' && KillerStats != none ) KillerStats.HeadShots++;

  // Spawnkill detection
  if( bSpawnkillDetection && DamageType != 'Gibbed' ) // No telefrags
  {
    if( Level.Game.BaseMutator.MutatedDefaultWeapon() != class'Botpack.ImpactHammer' )
    { // Arena mutator used, spawnkilling must be extreme to count
      if( TimeAwake <= SpawnKillTimeArena )
      {
        Killer.ReceiveLocalizedMessage( class'SmartDMCoolMsg', 5, KillerPRI, VictimPRI );
        if( KillerStats != none ) KillerStats.SpawnKillSpree++;
        if( Level.Game.LocalLog != none ) Level.Game.LocalLog.LogSpecialEvent( "spawnkill", KillerPRI.PlayerID, VictimPRI.PlayerID, 0 );
        if( bShowSpawnKillerGlobalMsg && KillerStats != none && KillerStats.SpawnKillSpree > 2 ) BroadcastLocalizedMessage( class'SmartDMMessage', 0, KillerPRI, VictimPRI );
      }
    }
    else // No arena mutator
    {
      if( TimeAwake < SpawnKillTimeNW )
      {
        Killer.ReceiveLocalizedMessage( class'SmartDMCoolMsg', 5, KillerPRI, VictimPRI );
        if( KillerStats != None ) KillerStats.SpawnKillSpree++;
        if( Level.Game.LocalLog != none ) Level.Game.LocalLog.LogSpecialEvent( "spawnkill", KillerPRI.PlayerID, VictimPRI.PlayerID, 0 );
        if( bShowSpawnKillerGlobalMsg && KillerStats != none && KillerStats.SpawnKillSpree > 2 ) BroadcastLocalizedMessage( class'SmartDMMessage', 0, KillerPRI, VictimPRI );
      }
    }
  }
  return bPrevent;
}

function ScoreKill(Pawn Killer, Pawn Other)
{
  local SmartDMPlayerReplicationInfo KillerStats;
  local PlayerPawn PPK;

  super.ScoreKill( Killer, Other );

  if( Killer != none )
   KillerStats = SDMGame.GetStats( Killer );

  if( bNewFragSystem && KillerStats != none )
   Killer.PlayerReplicationInfo.Score = KillerStats.Frags; //the easiest way!
 /*
  if( bPlayLeadSound )
  {
   if( LostLead != none )
   {
    PPK = FindTopScorer( LostLead );
    if( PPK != none )
    {
     LostLead.ReceiveLocalizedMessage( class'SmartDMAudioMsg', 1 );
     LostLead = none;
    }
   }
   else
   {
    PPK = FindTopScorer( none );
    PPK.ReceiveLocalizedMessage( class'SmartDMAudioMsg', 0 );
    LostLead = PPK;
   }
  }   */
}
/*
function PlayerPawn FindTopScorer( PlayerPawn PP )
{
  local Pawn P ,RetP;
  local float MaxScore;

  MaxScore = -100;

  if( PP != none )
  {
   MaxScore = PP.PlayerReplicationInfo.Score;
   for( P = Level.PawnList; P != None; P = P.NextPawn)
   {
     if( PlayerPawn( P ) != PP && P.PlayerReplicationInfo.Score >= MaxScore )
      RetP = P;
     else
      RetP = none;
   }
  }
  else
  {
   for( P = Level.PawnList; P != None; P = P.NextPawn)
   {
     if( P.PlayerReplicationInfo.Score > MaxScore )
      {
       MaxScore = P.PlayerReplicationInfo.Score;
       RetP = P;
      }
   }
  }

  return PlayerPawn( RetP );
}
 */
/*
 * ShieldBelt + Damage Amp tracking, spawnkill detection.
 */
function bool HandlePickupQuery( Pawn Other, Inventory Item, out byte bAllowPickup )
{
  local SmartDMPlayerReplicationInfo OtherStats;

  OtherStats = SDMGame.GetStats( Other );
  if( OtherStats == none ) return super.HandlePickupQuery( Other, Item, bAllowPickup );

  if( Item.IsA( 'UT_ShieldBelt' ) ) OtherStats.ShieldBelts++;
  if( Item.IsA( 'UDamage' ) ) OtherStats.Amps++;
  if( Item.IsA( 'Armor2' ) ) OtherStats.Armors++;
  if( Item.IsA( 'ThighPads' ) ) OtherStats.ThighPads++;
  if( Item.IsA( 'UT_JumpBoots' ) ) OtherStats.JumpBoots++;
  if( Item.IsA( 'UT_invisibility' ) ) OtherStats.Invi++;

  // For spawnkill detection
  if( bSpawnkillDetection  && OtherStats.SpawnTime != 0 )
  {
    if( Item.IsA( 'TournamentWeapon' ) || Item.IsA( 'UT_ShieldBelt' ) || Item.IsA( 'UDamage' ) || Item.IsA( 'HealthPack' ) || Item.IsA( 'UT_Invisibility' ) )
    {
      // This player has picked up a certain item making a kill on him no longer be qualified as a spawnkill.
      OtherStats.SpawnTime = 0;
    }
  }

  return super.HandlePickupQuery( Other, Item, bAllowPickup );
}

/*
 * Clear stats.
 */
function ClearStats()
{
  SDMGame.ClearStats();
}

/*
 * Give info on 'mutate smartdm' commands.
 */
function Mutate( string MutateString, PlayerPawn Sender )
{
  local int ID;
  local string SoundsString, MsgsString, CMsgsString;
  local SmartDMPlayerReplicationInfo SenderStats;

  if( Left( MutateString, 7 ) ~= "SmartDM" )
  {
    ID = Sender.PlayerReplicationInfo.PlayerID;

    if( Mid( MutateString, 8, 9 ) ~= "ShowStats" || Mid( MutateString, 8, 5 ) ~= "Stats" )
    {
      SenderStats = SDMGame.GetStats( Sender );
      if( SenderStats != none ) SenderStats.ToggleStats();
    }
    else if( Mid( MutateString, 8, 10 ) ~= "ForceStats" )
    {
      SenderStats = SDMGame.GetStats( Sender );
      if( SenderStats != none ) SenderStats.ShowStats();
    }
    else if( Mid( MutateString, 8, 8 ) ~= "ForceEnd" )
    {
      if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
      {
        Sender.ClientMessage( "You need to be logged in as admin to force the game to end." );
      }
      else
      {
        BroadcastMessage( Sender.PlayerReplicationInfo.PlayerName @ "forced the game to end." );
        bForcedEndGame = True;
        Level.Game.EndGame( "forced by admin" );
      }
    }
    else if( Mid( MutateString, 8, 10 ) ~= "ClearStats" )
    {
      if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
      {
        Sender.ClientMessage( "You need to be logged in as admin to be able to clear the stats." );
      }
      else
      {
        ClearStats();
        Sender.ClientMessage( "Stats cleared." );
      }
    }
    else
    {
      Sender.ClientMessage( "SmartDM by The_Cowboy !");
      Sender.ClientMessage( "- To toggle stats, bind a key or type in console: 'Mutate SmartDM Stats'" );
      Sender.ClientMessage( "- Type 'Mutate DMInfo' for SmartDM settings." );
      Sender.ClientMessage( "- Type 'Mutate SmartDM Rules' for new point system definition." );
      Sender.ClientMessage( "- Type 'Mutate SmartDM ForceEnd' to end a game." );
    }
  }
  /*else if( Left( MutateString, 7 ) ~= "CTFInfo" )
  {
    SoundsString = "";
    if( bPlayCaptureSound ) SoundsString = SoundsString @ "Capture";
    if( bPlayAssistSound ) SoundsString = SoundsString @ "Assist";
    if( bPlaySavedSound ) SoundsString = SoundsString @ "Saved";
    if( bPlayLeadSound ) SoundsString = SoundsString @ "Lead";
    if( bPlay30SecSound ) SoundsString = SoundsString @ "30SecLeft";
    if( SoundsString == "" ) SoundsString = "All off";
    if( Left( SoundsString, 1 ) == " " ) SoundsString = Mid( SoundsString, 1 );
    MsgsString = "";
    if( CoverMsgType == 1 ) MsgsString = MsgsString @ "Covers<priv.con>";
    if( CoverMsgType == 2 ) MsgsString = MsgsString @ "Covers<pub.con>";
    if( CoverMsgType == 3 ) MsgsString = MsgsString @ "Covers";
    if( CoverSpreeMsgType == 1 ) MsgsString = MsgsString @ "Coversprees<priv.con>";
    if( CoverSpreeMsgType == 2 ) MsgsString = MsgsString @ "Coversprees<pub.con>";
    if( CoverSpreeMsgType == 3 ) MsgsString = MsgsString @ "Coversprees";
    if( SealMsgType == 1 ) MsgsString = MsgsString @ "Seals<priv.con>";
    if( SealMsgType == 2 ) MsgsString = MsgsString @ "Seals<pub.con>";
    if( SealMsgType == 3 ) MsgsString = MsgsString @ "Seals";
    if( SavedMsgType == 1 ) MsgsString = MsgsString @ "Saved<priv.con>";
    if( SavedMsgType == 2 ) MsgsString = MsgsString @ "Saved<pub.con>";
    if( SavedMsgType == 3 ) MsgsString = MsgsString @ "Saved";
    if( MsgsString == "" ) MsgsString = "All off";
    if( Left( MsgsString, 1 ) == " " ) MsgsString = Mid( MsgsString, 1 );
    CMsgsString = "";
    if( bShowAssistConsoleMsg ) CMsgsString = CMsgsString @ "AssistBonus";
    if( bShowSealRewardConsoleMsg ) CMsgsString = CMsgsString @ "SealReward";
    if( bShowCoverRewardConsoleMsg ) CMsgsString = CMsgsString @ "CoverReward";
    if( bShowLongRangeMsg ) CMsgsString = CMsgsString @ "LongRangeKill";
    if( CMsgsString == "" ) CMsgsString = "All off";
    if( Left( CMsgsString, 1 ) == " " ) CMsgsString = Mid( CMsgsString, 1 );
    Sender.ClientMessage( "- bExtraStats:" @ bExtraStats);
    Sender.ClientMessage( "- Sounds:" @ SoundsString );
    Sender.ClientMessage( "- Msgs:" @ MsgsString );
    Sender.ClientMessage( "- Private Msgs:" @ CMsgsString );
    Sender.ClientMessage( "- bFixFlagBug:" @ bFixFlagBug );
    Sender.ClientMessage( "- bEnhancedMultiKill:" @ bEnhancedMultiKill $ ", Broadcast Level:" @ EnhancedMultiKillBroadcast );
    Sender.ClientMessage( "- bShowFCLocation:" @ bShowFCLocation );
    if( bSpawnKillDetection ) Sender.ClientMessage( "- bSpawnKillDetection: True, global Msg:" @ bShowSpawnKillerGlobalMsg $ ", Penalty:" @ SpawnKillPenalty @ "pts" );
    else Sender.ClientMessage( "- bSpawnKillDetection: False" );
    Sender.ClientMessage( "- Overtime Control:" @ bEnableOvertimeControl @ "( Type 'Mutate OverTime' )" );
    Sender.ClientMessage( "- Scores: ( Type 'Mutate SmartCTF Rules' )");
  }
  else if( Left( MutateString, 8 ) ~= "OverTime" )
  {
    if( !DeathMatchPlus( Level.Game ).bTournament )
    {
      Sender.ClientMessage( "Not in Tournament Mode: Default Sudden Death Overtime behaviour." );
    }
    else if( !bEnableOvertimeControl )
    {
      Sender.ClientMessage( "Overtime Control is not enabled: Default UT Sudden Death functionality." );
      Sender.ClientMessage( "Admins can use: admin set SmartCTF bEnableOvertimeControl True" );
    }
    else
    {
      if( Left( MutateString, 11 ) ~= "OverTime On" )
      {
        if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
        {
          Sender.ClientMessage( "You need to be logged in as admin to change this setting." );
        }
        else
        {
          bOvertime = True;
          SaveConfig();
          BroadcastLocalizedMessage( class'SmartCTFCoolMsg', 3 );
        }
      }
      else if( Left( MutateString, 12 ) ~= "OverTime Off" )
      {
        if( !Sender.PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone )
        {
          Sender.ClientMessage( "You need to be logged in as admin to change this setting." );
        }
        else
        {
          bOvertime = False;
          SaveConfig();
          BroadcastLocalizedMessage( class'SmartCTFCoolMsg', 4 );
        }
      }
      else
      {
        if( Sender.PlayerReplicationInfo.bAdmin || Level.NetMode == NM_StandAlone ) Sender.ClientMessage( "Usage: Mutate OverTime On|Off" );
        if( !bOvertime ) Sender.ClientMessage( "Sudden Death Overtime is DISABLED." );
        else Sender.ClientMessage( "Sudden Death Overtime is ENABLED (default)." );
        Sender.ClientMessage( "Remember 'Disabled' Setting:" @ bRememberOvertimeSetting );
      }
    }
  } */

  super.Mutate( MutateString, Sender );
}

function bool HandleEndGame()
{
  CalcSmartDMEndStats();

  if( NextMutator != None ) return NextMutator.HandleEndGame();
  return False;
}

function CalcSmartDMEndStats()
{
  local SmartDMPlayerReplicationInfo TopSurvivability, TopSprees, TopMultiLevelKills, TopFrags, TopHeadshots;
  local string BestRecordDate;
  local int ID;
  local float PerHour;
  local SmartDMPlayerReplicationInfo PawnStats;
  local PlayerReplicationInfo PRI;
  local byte i;
  local SmartDMEndStats EndStats;

  EndStats = SDMGame.EndStats;

  SDMGame.RefreshPRI();
  for( i = 0; i < 64; i++ )
  {
    PawnStats = SDMGame.GetStatNr( i );
    if( PawnStats == None ) break;

    switch( PawnStats.FragSpree/5 )  //When game ends this is the way to recognize the spreelevel :)
    {
     case 0:
            break;
     case 1: PawnStats.KillingSpree++;
            break;
     case 2: PawnStats.Rampage++;
            break;
     case 3: PawnStats.Dominating++;
            break;
     case 4: PawnStats.Unstoppable++;
            break;
     default: PawnStats.GodLike++;
            break;
     }

     switch( PawnStats.MultiLevel )
     {
      case 0:
              break;
      case 1: PawnStats.DoubleKill++;
              break;
      case 2: PawnStats.TripleKill++;
              break;
      case 3: PawnStats.MultiKill++;
              break;
      case 4: PawnStats.Megakill++;
              break;
      case 5: PawnStats.UltraKill++;
              break;
      default: PawnStats.MonsterKill++;
              break;
     }

    if( TopSurvivability == none || PawnStats.Survivability > TopSurvivability.Survivability ) TopSurvivability = PawnStats;
    if( TopSprees == none || PawnStats.SpreeSum() > TopSprees.SpreeSum() ) TopSprees = PawnStats;
    if( TopMultiLevelKills == none || PawnStats.MultiLevelSum() > TopMultiLevelKills.MultiLevelSum() ) TopMultiLevelKills = PawnStats;
    if( TopFrags == None || PawnStats.Frags > TopFrags.Frags ) TopFrags = PawnStats;
    if( TopHeadshots == none || PawnStats.HeadShots > TopHeadshots.HeadShots ) TopHeadshots = PawnStats;
  }

  PRI = PlayerReplicationInfo( TopSurvivability.Owner );
  if( TopSurvivability.Survivability > EndStats.MostSurvivability.Count && Level.TimeSeconds - PRI.StartTime > 300 && Level.Game.NumPlayers >= 3 )
  {
    EndStats.MostSurvivability.Count = TopSurvivability.Survivability;
    EndStats.MostSurvivability.PlayerName = PRI.PlayerName;
    EndStats.MostSurvivability.MapName = Level.Title;
    TournamentGameInfo(Level.Game).GetTimeStamp( BestRecordDate );
    EndStats.MostSurvivability.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopSprees.Owner );
  if( TopSprees.SpreeSum() > EndStats.MostSprees.Count )
  {
    EndStats.MostSprees.Count = TopSprees.SpreeSum();
    EndStats.MostSprees.PlayerName = PRI.PlayerName;
    EndStats.MostSprees.MapName = Level.Title;
    TournamentGameInfo( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostSprees.RecordDate = BestRecordDate;
  }

  PRI = PlayerReplicationInfo( TopMultiLevelKills.Owner );
  if( TopMultiLevelKills.MultiLevelSum() > EndStats.MostMultiLevelKills.Count )
  {
    EndStats.MostMultiLevelKills.Count = TopMultiLevelKills.MultiLevelSum();
    EndStats.MostMultiLevelKills.PlayerName = PRI.PlayerName;
    EndStats.MostMultiLevelKills.MapName = Level.Title;
    TournamentGameInfo( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostMultiLevelKills.RecordDate = BestRecordDate;
  }


  PRI = PlayerReplicationInfo( TopFrags.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopFrags.Frags / PerHour > EndStats.MostFrags.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostFrags.Count = TopFrags.Frags / PerHour;
    EndStats.MostFrags.PlayerName = PRI.PlayerName;
    EndStats.MostFrags.MapName = Level.Title;
    TournamentGameInfo( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostFrags.RecordDate = BestRecordDate;
  }


  PRI = PlayerReplicationInfo( TopHeadshots.Owner );
  PerHour = ( Level.TimeSeconds - PRI.StartTime ) / 3600;
  if( TopHeadshots.HeadShots / PerHour > EndStats.MostHeadShots.Count && Level.TimeSeconds - PRI.StartTime > 300 )
  {
    EndStats.MostHeadShots.Count = TopHeadshots.HeadShots / PerHour;
    EndStats.MostHeadShots.PlayerName = PRI.PlayerName;
    EndStats.MostHeadShots.MapName = Level.Title;
    TournamentGameInfo( Level.Game ).GetTimeStamp( BestRecordDate );
    EndStats.MostHeadShots.RecordDate = BestRecordDate;
  }

  EndStats.SaveConfig();
}


//----------------------------------------------------------------------------------------------------------------
//------------------------------------------------ CLIENT FUNCTIONS ----------------------------------------------
//----------------------------------------------------------------------------------------------------------------

/*
 * Render the HUD that is startup logo.
 * ONLY gets executed on clients.
 */
simulated event PostRender( Canvas C )
{
  local int i, Y;
  local float DummyY, Size, Temp;
  local string TempStr;

  // Get stuff relating to PlayerOwner, if not gotten. Also spawn Font info.
  if( PlayerOwner == none )
  {
    PlayerOwner = C.Viewport.Actor;
    MyHUD = ChallengeHUD( PlayerOwner.MyHUD );

    pTGRI = TournamentGameReplicationInfo( PlayerOwner.GameReplicationInfo );
    pPRI = PlayerOwner.PlayerReplicationInfo;
    MyFonts = MyHUD.MyFonts;
  }

  // Draw "Powered by.." logo when player joins
  if( DrawLogo != 0 )
  {
    C.Style = ERenderStyle.STY_Translucent;
    if( DrawLogo > 1 )
    {
      C.DrawColor.R = 255 - DrawLogo/2;
      C.DrawColor.G = 255 - DrawLogo/2;
      C.DrawColor.B = 255 - DrawLogo/2;
    }
    else // 1
    {
      C.Style = ERenderStyle.STY_Translucent;
      C.DrawColor = White;
    }
    if(powered == None)
    	powered=texture'powered';
    C.SetPos( C.ClipX - powered.Usize - 16, 40 );
    C.DrawIcon( powered, 1 );
    C.Font = MyFonts.GetSmallFont( C.ClipX );
    C.StrLen( "SmartDM "$Version , Size, DummyY );
    C.SetPos( C.ClipX  - powered.Usize/2 - Size/2 - 16, 40 + 8 + powered.Vsize );
    Temp = DummyY;
    C.DrawText( "SmartDM "$Version );
  }

  C.Style = ERenderStyle.STY_Normal;

  if( NextHUDMutator != None ) NextHUDMutator.PostRender( C );
}


/*
 * Executed on the client when that player joins the server.
 */
simulated function ClientJoinServer( Pawn Other )
{
  if( PlayerPawn( Other ) == None || !Other.bIsPlayer ) return;

  if(SDMGame.bDrawLogo)
  DrawLogo = 1;

  SetTimer( 0.05 , True);

  // Since this gets called in the HUD it needs to be changed clientside.
  if( SDMGame.bPlay30SecSound ) class'TimeMessage'.default.TimeSound[5] = sound'Announcer.CD30Sec';
}

/*
 * Clientside settings that need to be set for the first time, checking for welcome message and
 * end of game screen.
 */
simulated function Tick( float delta )
{
  local SmartDMPlayerReplicationInfo OwnerStats;

  // Execute on client
  if( Level.NetMode != NM_DedicatedServer )
  {
    if( SDMGame == none )
    {
      foreach AllActors( class'SmartDMGameReplicationInfo', SDMGame ) break;
      if( SDMGame == none ) return;

      if( !SDMGame.bServerInfoSetServerSide && SDMGame.DefaultHUDType != none ) // client side required
      {
        class<ChallengeHUD>( SDMGame.DefaultHUDType ).default.ServerInfoClass = class'SmartDMServerInfo';
        Log( "Notified HUD (clientside," @ SDMGame.DefaultHUDType.name $ ") to use SmartDM ServerInfo.", 'SmartDM' );
      }
    }
    if( !SDMGame.bInitialized ) return;

    if( !bHUDMutator ) RegisterHUDMutator();

    if( PlayerOwner != None )
    {
      if( !bClientJoinPlayer )
      {
        bClientJoinPlayer = True;
        ClientJoinServer( PlayerOwner );
      }

      // If Game is over, bring up F3.
      if( PlayerOwner.GameReplicationInfo.GameEndedComments != "" && !bGameEnded )
      {
        bGameEnded = True;
        OwnerStats = SDMGame.GetStatsByPRI( pPRI );
        OwnerStats.bEndStats = True;
        PlayerOwner.ConsoleCommand( "mutate SmartDM ForceStats" );
      }
    }
  }
}

/*
 * For showing the Logo a Timer is used instead of Ticks so its equal for each tickrate.
 * On the server it keeps track of some replicated data and whether a Tournament game is starting.
 */
simulated function Timer()
{
  local bool bReady;
  local Pawn pn;
  local SmartDMPlayerReplicationInfo SenderStats;
  local PlayerPawn PP;

  super.Timer();

  // Clients - 0.05 second timer. Stops after logo is displayed.
  if( Level.NetMode != NM_DedicatedServer )
  {
    if( DrawLogo != 0 && SDMGame.bDrawLogo )
    {
      LogoCounter++;
      if( DrawLogo == 510 )
      {
        DrawLogo = 0;
        if( Role != ROLE_Authority ) SetTimer( 0.0, False ); // client timer off
        else SetTimer( 1.0, True ); // standalone game? keep timer running for bit below.
      }
      else if( LogoCounter > 60 )
      {
        DrawLogo += 8;
        if( DrawLogo > 510 ) DrawLogo = 510;
      }
      else if( LogoCounter == 60 )
      {
        DrawLogo = 5;
      }
    }

	if( !bInitSb && SDMGame.bSDMSbDef )
    {
		if( bGameEnded )
        {
         bInitSb=true;
         return;
        } // Don't interfere with scoreboard showing on game end
		SbCount++;
		if(SbCount > SDMGame.SbDelayC)
        {
		 SenderStats = SDMGame.GetStats( PlayerOwner );
         if( SenderStats != none )
         SenderStats.ShowStats(true);
		 bInitSb=true;
         if(!SDMGame.bDrawLogo && Role != ROLE_Authority) SetTimer(0.0,False);
		}
	}
  }

  // Server - 1 second timer. infinite.
  if( Level.NetMode == NM_DedicatedServer || Role == ROLE_Authority )
  {
    if( ++TRCount > 2 )
    {
      SDMGame.TickRate = int( ConsoleCommand( "get IpDrv.TcpNetDriver NetServerMaxTickRate" ) );
      TRCount = 0;
    }

	SbDelayC = SbDelay*20; // Timer is called every 0.05s, so * 20 converts the value in seconds to our count compatible value
    /*
    // Update config vars to client / manual replication :E
    // Allows for runtime changing of settings.
    if( SDMGame.bShowFCLocation != bShowFCLocation ) SDMGame.bShowFCLocation = bShowFCLocation;
    if( SDMGame.bStatsDrawFaces != bStatsDrawFaces ) SDMGame.bStatsDrawFaces = bStatsDrawFaces;
    if( SDMGame.bDrawLogo != bDrawLogo ) SDMGame.bDrawLogo = bDrawLogo;
	if( SDMGame.bShowSpecs != bShowSpecs ) SDMGame.bShowSpecs = bShowSpecs;
	if( SDMGame.bDoKeybind != bDoKeybind ) SDMGame.bDoKeybind = bDoKeybind;
	if( SDMGame.SbDelayC != SbDelayC ) SDMGame.SbDelayC = SbDelayC;   */


	// UT's built-in messaging spectator is excluded from the spectator list based on its starttime.
	// We need to make sure this does not include any players as well.
	// Update: on slow/exotic servers, the starttime could be delayed (not 0). Let's make sure it is.
	if(!bStartTimeCorrected && bShowSpecs)
	{
	for(pn = Level.PawnList; pn != None; pn = pn.NextPawn){
	if(pn.IsA('PlayerPawn') && pn.PlayerReplicationInfo.StartTime==0) pn.PlayerReplicationInfo.StartTime=1;
	if(!pn.bIsPlayer && pn.PlayerReplicationInfo.Playername=="Player") pn.PlayerReplicationInfo.StartTime=0;
	}
	if(Level.TimeSeconds>=5) bStartTimeCorrected=true; // After five seconds, the messaging spectator(s) should be loaded, so we are done.
	}

	// Since PlayerID's are incremented in the order of player joins [and those joined later cannot have an earlier StartTime than preceding players], this can be reliably used to deliver each player the delayed message only once
	// without having to resort to a large array of PIDs already messaged; we can simply check against the *last* PID messaged instead.
	// Too bad the timer only runs at 1.0. That sorf of defies the purpose of MsgDelay being a float instead of an int. O well... matches nice with SbDelay ;)
	for(pn = Level.PawnList; pn != None; pn = pn.NextPawn)
	if(pn.IsA('PlayerPawn') && pn.bIsPlayer && Level.TimeSeconds - pn.PlayerReplicationInfo.StartTime >= MsgDelay && pn.PlayerReplicationInfo.PlayerID>MsgPID){
	if(!SDMGame.bDrawLogo)
	pn.ClientMessage( "Running SmartDM " $ Version $ ". Type 'Mutate SmartDM' in the console for info." );
	if(bExtraMsg && bDoKeybind && SDMGame.bDrawLogo)
	pn.ClientMessage("Running SmartDM " $ Version $ ". Press F3 to toggle between scoreboards.");
	else if(bExtraMsg && bDoKeybind)
	pn.ClientMessage("Press F3 to toggle between scoreboards."); // Shorter msg, since we already announced we are running SmartDM.
	MsgPID = pn.PlayerReplicationInfo.PlayerID; // Increase to keep track of whom still to message
	}
  }
}

defaultproperties
{
    Version="0.9.0.5"
    White=(R=255,G=255,B=255,A=0),
    Gray=(R=128,G=128,B=128,A=0),
    bEnabled=True
    CountryFlagsPackage="CountryFlags2"
    EnhancedMultiKillBroadcast=2
    bSmartDMServerInfo=True
    bSpawnkillDetection=True
    SpawnKillTimeArena=1.00
    SpawnKillTimeNW=3.50
    bAfterGodLikeMsg=True
    bStatsDrawFaces=True
    bDrawLogo=True
    bSDMSbDef=True
    bShowSpecs=True
    bDoKeybind=True
    bExtraMsg=True
    SbDelay=5.00
    MsgDelay=3.00
    bShowSpawnKillerGlobalMsg=True
    bPlay30SecSound=True
    bAlwaysRelevant=True
    RemoteRole=2
}
