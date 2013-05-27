class SmartDMPlayerReplicationInfo expands ReplicationInfo;

// Replicated
var int Frags ,HeadShots;
var string CountryPrefix ,PlayerStatsString; // for IpToCountry
var int NetSpeed;

// Server side
var int SpawnKillSpree, KillingSpree , Rampage,
        Dominating ,Unstoppable ,GodLike, DoubleKill, TripleKill ,MultiKill ,MegaKill ,UltraKill ,
        MonsterKill ,SpreeEnded ,Sucide ,Efficiency ,ShieldBelts, Amps ,Armors ,JumpBoots ,Invi ,Survivability ,ThighPads;
var float LastKillTime;
var int FragSpree;
var int MultiLevel;
var float SpawnTime;
var float AwakeTime;
var int SurCount;
var bool bHadFirstSpawn;

// Client side
var bool bViewingStats;
var bool bEndStats;
var float IndicatorStartShow;
var byte IndicatorVisibility;

var Actor IpToCountry;
var bool bIpToCountry;

replication
{
  // Stats
  reliable if( Role == ROLE_Authority && !PlayerReplicationInfo(Owner).bIsSpectator )
    PlayerStatsString, CountryPrefix ,Frags ,HeadShots ,NetSpeed; //I bet you have not seen this kind of replication before :P

  // Toggle stats functions
  reliable if( Role == ROLE_Authority )
    ToggleStats, ShowStats;
}

function PostBeginPlay()
{
  ClearStats();
  SetTimer( 0.5, true );
}

function Timer()
{
  local string temp;
  local PlayerPawn P;
  if( Owner == None )
  {
    SetTimer( 0.0, False );
    Destroy();
    return;
  }
  if(bIpToCountry)
  {
     if(CountryPrefix == "")
     {
	   if(Owner.Owner.IsA('PlayerPawn'))
	   {
          P=PlayerPawn(Owner.Owner);
	      if(NetConnection(P.Player) != None)
	      {
             temp=P.GetPlayerNetworkAddress();
             temp=Left(temp, InStr(temp, ":"));
             temp=IpToCountry.GetItemName(temp);
             if(temp == "!Disabled") /* after this return, iptocountry won't resolve anything anyway */
                bIpToCountry=False;
             else if(Left(temp, 1) != "!") /* good response */
             {
                CountryPrefix=SelElem(temp, 5);
                if(CountryPrefix=="") /* the country is probably unknown(maybe LAN), so as the prefix */
                  bIpToCountry=False;
             }
	      }
	      else
	         bIpToCountry=False;
	    }
	    else
	       bIpToCountry=False;
      }
      else
         bIpToCountry=False;
  }

  MakePlayerStats();

  if( SurCount != 0 )
   Survivability = int(AwakeTime/SurCount);

  if( PlayerPawn( Owner.Owner ) != none )
  NetSpeed = PlayerPawn( Owner.Owner ).Player.CurrentNetSpeed ;
}

function int SpreeSum()
{
  return KillingSpree + Rampage +  Dominating + Unstoppable + GodLike;
}

function int MultiLevelSum()
{
  return DoubleKill + TripleKill + MultiKill + MegaKill + UltraKill + MonsterKill;
}

function MakePlayerStats()
{
   PlayerStatsString = SpawnKillSpree$":"$KillingSpree$":"$Rampage$":"$Dominating$":"$
                 Unstoppable$":"$GodLike$":"$DoubleKill$":"$TripleKill$":"$MultiKill$
                 ":"$MegaKill$":"$UltraKill$":"$MonsterKill$":"$SpreeEnded$":"$Sucide
                 $":"$ShieldBelts$":"$Amps$":"$Armors$":"$JumpBoots$":"$Invi$":"$Survivability
                 $":"$ThighPads;
}

static final function string SelElem(string Str, int Elem)
{
	local int pos;
	while(Elem-->1)
		Str=Mid(Str, InStr(Str,":")+1);
	pos=InStr(Str, ":");
	if(pos != -1)
    	Str=Left(Str, pos);
    return Str;
}

// Called on the server, executed on the client
simulated function ToggleStats()
{
  local PlayerPawn P;

  if( Owner == None ) return;
  P = PlayerPawn( Owner.Owner );
  if( P == none ) return;

  if( P.Scoring != none && !P.Scoring.IsA( 'SmartDMScoreBoard' ) )
  {
    P.ClientMessage( "Problem loading the SmartDM ScoreBoard..." );
  }
  else
  {
    bViewingStats = !bViewingStats;
    IndicatorStartShow = Level.TimeSeconds;
    IndicatorVisibility = 255;
    P.bShowScores = True;
  }
}

// Called on the client
simulated function ShowStats(optional bool bHide)
{
  local PlayerPawn P;

  if( Owner == None ) return;
  P = PlayerPawn( Owner.Owner );
  if( P == none ) return;

  if( P.Scoring != none && !P.Scoring.IsA( 'SmartDMScoreBoard' ) )
  {
    P.ClientMessage( "Problem loading the SmartDM ScoreBoard..." );
  }
  else
  {
    bViewingStats = True;
    if(!bHide) P.bShowScores = True;
  }
}

function ClearStats()
{
  Frags=0;
  HeadShots=0;
  SpawnKillSpree=0;
  KillingSpree=0;
  Rampage=0;
  Dominating=0;
  Unstoppable=0;
  GodLike=0;
  DoubleKill=0;
  TripleKill=0;
  MultiKill=0;
  MegaKill=0;
  UltraKill=0;
  MonsterKill=0;
  SpreeEnded=0;
  Sucide=0;
  Efficiency=0;
  ShieldBelts=0;
  Amps=0;
  Armors=0;
  JumpBoots=0;
  Invi=0;
  SpawnTime = 0;
  LastKillTime = 0;
  MultiLevel = 0;
  Survivability=0;
  SurCount=0;
}

defaultproperties
{
    NetUpdateFrequency=2.00
}
