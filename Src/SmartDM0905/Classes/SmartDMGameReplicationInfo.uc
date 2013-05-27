// This class gets spawned in the mutator, serverside.
// Because of its Role, it will also get copied to clients.
// The replicated variables are accessible there.

class SmartDMGameReplicationInfo expands ReplicationInfo;

var int TickRate;
var bool bStatsDrawFaces, bPlay30SecSound, bDrawLogo, bShowSpecs, bDoKeybind ,bNewFragSystem;
var private bool TimerRunning;
var float SbDelayC;
var string CountryFlagsPackage;
var class<ScoreBoard> NormalScoreBoardClass;
var SmartDMEndStats EndStats;
var SmartDMPlayerReplicationInfo PRIArray[64];
var bool bInitialized, bServerInfoSetServerSide, bDoneBind, bSDMSbDef ;
var class<HUD> DefaultHUDType;

replication
{
  // Settings
  reliable if( Role == ROLE_Authority )
    bPlay30SecSound, bStatsDrawFaces, bDrawLogo, bSDMSbDef, CountryFlagsPackage, bShowSpecs, bDoKeybind ,bNewFragSystem;

  reliable if( Role == ROLE_Authority )
    bInitialized, TickRate, NormalScoreBoardClass, EndStats, bServerInfoSetServerSide, DefaultHUDType, DoBind, SbDelayC;
}

simulated function PostBeginPlay()
{
  ClearStats();
  SetTimer( 0.5, true );
}

simulated function Timer()
{
	local PlayerPawn P;

	RefreshPRI();

	if (Level.Netmode == NM_DedicatedServer || bDoneBind || !bDoKeybind) return; // Only execute on clients,  if bind hasn't been done yet and if bind should be done.

	foreach AllActors(class 'PlayerPawn', P)
	if (Viewport(P.Player) != None) break;
	if(P!=None) DoBind(P);
	bDoneBind=true;
}

simulated function SmartDMPlayerReplicationInfo GetStats( Actor P )
{
  local int i;
  local PlayerReplicationInfo PRI;

  if( !P.IsA( 'Pawn' ) ) return None;
  PRI = Pawn( P ).PlayerReplicationInfo;
  if( PRI == None ) return None;

  for( i = 0; i < 64; i++ )
  {
    if( PRIArray[i] == None ) break;
    if( PRIArray[i].Owner == PRI ) return PRIArray[i];
  }
  return None;
}

simulated function SmartDMPlayerReplicationInfo GetStatsByPRI( PlayerReplicationInfo PRI )
{
  local int i;

  if( PRI == None ) return None;
  for( i = 0; i < 64; i++ )
  {
    if( PRIArray[i] == None ) break;
    if( PRIArray[i].Owner == PRI ) return PRIArray[i];
  }
  return None;
}

simulated function SmartDMPlayerReplicationInfo GetStatNr( byte i )
{
  return PRIArray[i];
}

simulated function ClearStats()
{
  local int i;
  for( i = 0; i < 64; i++ )
  {
    if( PRIArray[i] == None ) break;
    PRIArray[i].ClearStats();
  }
}

simulated function RefreshPRI()
{
  local SmartDMPlayerReplicationInfo PRI;
  local int i;

  for( i = 0; i < 64; i++ ) PRIArray[i] = None;

  i = 0;
  ForEach AllActors( class'SmartDMPlayerReplicationInfo', PRI )
  {
    if( i < 64 )
    {
      if( PRI.Owner != None ) PRIArray[i++] = PRI;
    }
    else break;
  }
}

simulated function DoBind(PlayerPawn P)
{
	local string keyBinding;

		if ((InStr( Caps(P.ConsoleCommand("Keybinding F3")), "MUTATE SMARTDM SHOWSTATS") == -1))
		{
			keyBinding = P.ConsoleCommand("Keybinding F3");
			P.ConsoleCommand("SET INPUT F3 mutate smartdm showstats|"$keyBinding);
		}
}

defaultproperties
{
    RemoteRole=2
}
