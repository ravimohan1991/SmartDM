class SmartDMEnhancedDeathMessagePlus extends DeathMessagePlus;

static function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  local string MultiStr;

  if( RelatedPRI_1 == P.PlayerReplicationInfo )
  {
    // Interdict and send the child message instead.
    if( TournamentPlayer( P ).myHUD != None )
    {
      //if( class'DeathMessagePlus'.default.ChildMessage == class'KillerMessagePlus' ) class'KillerMessagePlus'.default.YouKilled = "You" @ TournamentGameInfo( P.Level.Game ).default.deathmessage[Rand(32)];
      TournamentPlayer( P ).myHUD.LocalizedMessage( default.ChildMessage, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
      TournamentPlayer( P ).myHUD.LocalizedMessage( default.Class, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
    }

    if( default.bIsConsoleMessage )
    {
      TournamentPlayer( P ).Player.Console.AddString( static.GetString( Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject ) );
    }

    if( ( RelatedPRI_1 != RelatedPRI_2 ) && ( RelatedPRI_2 != None ) )
    {
      if( ( TournamentPlayer( P ).Level.TimeSeconds - TournamentPlayer( P ).LastKillTime < 3 ) && ( Switch != 1 ) )
      {
        TournamentPlayer( P ).MultiLevel++;
        TournamentPlayer( P ).ReceiveLocalizedMessage( class'SmartDMEnhancedMultiKillMessage', TournamentPlayer( P ).MultiLevel , RelatedPRI_1 );
      }
      else
      {
        TournamentPlayer( P ).MultiLevel = 0;
      }
      TournamentPlayer( P ).LastKillTime = TournamentPlayer( P ).Level.TimeSeconds;
    }
    else
    {
      TournamentPlayer( P ).MultiLevel = 0;
    }

    if( ChallengeHUD( P.MyHUD ) != None ) ChallengeHUD( P.MyHUD ).ScoreTime = TournamentPlayer( P ).Level.TimeSeconds;
  }
  else if( RelatedPRI_2 == P.PlayerReplicationInfo )
  {
    TournamentPlayer( P ).ReceiveLocalizedMessage( class'VictimMessage', 0, RelatedPRI_1 );
    super( LocalMessagePlus ).ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
  }
  else
  {
    super( LocalMessagePlus ).ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
  }
}

defaultproperties
{
}
