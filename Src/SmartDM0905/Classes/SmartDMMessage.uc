// Above all other messages.
class SmartDMMessage extends LocalMessagePlus;


var string SpawnKillMsg;

static function float GetOffset( int Switch, float YL, float ClipY )
{
  return ( default.YPos / 768.0 ) * ClipY - 3 * YL;
}

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  if (RelatedPRI_1 == None) return "";

  switch( Switch )
  {
      case 0: // Spawnkilling
      return RelatedPRI_1.PlayerName @ default.SpawnKillMsg;
  }
  return "";
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  super.ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

  switch( Switch )
  {
    case 5: // Cover spree - guitarsound for player, spreesound for all
      if( RelatedPRI_1 == P.PlayerReplicationInfo ) P.ClientPlaySound( sound'CaptureSound', , true );
      else P.PlaySound( sound'SpreeSound', , 4.0 );
      break;
  }
}

defaultproperties
{
    SpawnKillMsg="is a spawnkilling lamer!"
    FontSize=1
    bIsSpecial=True
    bIsUnique=True
    bFadeMessage=True
    DrawColor=(R=24,G=192,B=24,A=0),
    YPos=196.00
    bCenter=True
}
