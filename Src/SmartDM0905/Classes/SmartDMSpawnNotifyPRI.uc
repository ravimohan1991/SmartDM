class SmartDMSpawnNotifyPRI expands SpawnNotify;

var Actor IpToCountry;
var bool bChecked;

simulated event Actor SpawnNotification( Actor A )
{
  local Actor Search;
  local SmartDMPlayerReplicationInfo RI;

  if( A.Owner == None ) return A;
  if( !A.Owner.IsA( 'PlayerPawn' ) && !A.Owner.IsA( 'Bot' ) ) return A;
  if( !Pawn( A.Owner ).bIsPlayer ) return A;

  if(!bChecked)
  {
     foreach Level.Game.AllActors(class'Actor', Search, 'IpToCountry')
     {
       IpToCountry=Search;
       break;
     }
     bChecked=True;
  }
  // Spawn SmartDM PRI for this pawn on the server
  RI=Spawn( class'SmartDMPlayerReplicationInfo', A );
  if(IpToCountry != None)
  {
    RI.IpToCountry=IpToCountry;
    RI.bIpToCountry=True;
  }
  return A;
}

defaultproperties
{
    ActorClass=Class'Engine.PlayerReplicationInfo'
}
