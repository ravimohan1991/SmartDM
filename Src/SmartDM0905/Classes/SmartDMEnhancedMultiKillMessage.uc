//=============================================================================
// SmartCTFEnhancedMultiKillMessage.
// - v1.0 29-Feb-2004 by {DnF2}SiNiSTeR -
//=============================================================================
class SmartDMEnhancedMultiKillMessage extends MultiKillMessage;

// Extended Multikills adds 2 more to the list :]
// These Announcer sounds already were included in the orginal game, just not used.
// It also doesn't stop after 9 times ;p

#exec OBJ LOAD FILE=..\Sounds\Announcer.uax

var(Messages) localized string MegaKillString;

static function int GetFontSize( int Switch )
{
  if( Switch < 3 ) return default.FontSize;
  else return 2;
}

static function string GetString( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  switch( Switch )
  {
    case 0:  return "";
       break;
    case 1:  return default.DoubleKillString;
       break;
    case 2:  return default.TripleKillString;
       break;
    case 3:  return default.MultiKillString;
       break;
    case 4:  return default.MegaKillString;
       break;
    case 5:  return default.UltraKillString;
       break;
    default: return default.MonsterKillString;
       break;
  }
}

static function string GetBroadcastString( int MultiLevel )
{
  if( MultiLevel == 5 ) return "had an" @ static.GetString( MultiLevel );
  else return "had a" @ static.GetString( MultiLevel );
}

static simulated function ClientReceive( PlayerPawn P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
  super( LocalMessagePlus ).ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );

  switch( Switch )
  {
    case 0:  break;
    case 1:  P.ClientPlaySound( sound'Announcer.DoubleKill', , true );
       break;
    case 2:  P.ClientPlaySound( sound'Announcer.TripleKill', , true );
       break;
    case 3:  P.ClientPlaySound( sound'Announcer.MultiKill', , true );
       break;
    case 4:  P.ClientPlaySound( sound'Announcer.MegaKill', , true );
       break;
    case 5:  P.ClientPlaySound( sound'Announcer.UltraKill', , true );
       break;
    default: P.ClientPlaySound( sound'Announcer.MonsterKill', , true );
       break;
  }
}

static function color GetColor( optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2 )
{
  local Color cres;

  cres = Default.DrawColor;
  if( Switch >= 1 && Switch <= 5 )
  {
    cres.G = 48 * ( 5 - Switch );
    return cres;
  }
  else if( Switch > 5 )
  {
    cres.B = Min( 48 * ( Switch - 5 ), 255 );
    return cres;
  }
  else
  {
    return cres;
  }
}

defaultproperties
{
    MegaKillString="MEGA KILL!"
}
