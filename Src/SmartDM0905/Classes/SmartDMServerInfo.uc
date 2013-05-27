class SmartDMServerInfo expands ServerInfoCTF;

#exec texture IMPORT NAME=shade File=Textures\shade.pcx GROUP=SmartDM MIPS=OFF

var SmartDMGameReplicationInfo SDMGame;
var PlayerPawn PlayerOwner;
var string MapNameText;
var bool bFontUpdated;
var float LastUpdateTime;
var float HeaderHeight, CatHeight, TextHeight, SmallTextHeight, VSpacing, BorderSpacing, TotalHeight;
var float StartY, Y, SideSpacing;
var Color HeaderBlue, TextBlue, InfoWhite;

function PostBeginPlay()
{
  if( SDMGame == none )
  {
    foreach AllActors( class'SmartDMGameReplicationInfo', SDMGame ) break;
  }

  super.PostBeginPlay();
}

function RenderInfo( Canvas C )
{
  local float XL;
  local GameReplicationInfo GRI;

  if( Level.TimeSeconds - LastUpdateTime > 0.5 ) bFontUpdated = False;
  if( !bFontUpdated )
  {
    C.Font = MyFonts.GetHugeFont( C.ClipX );
    C.StrLen( "Test", XL, HeaderHeight );
    C.Font = MyFonts.GetBigFont( C.ClipX );
    C.StrLen( "Test", XL, CatHeight );
    C.Font = MyFonts.GetSmallFont( C.ClipX );
    C.StrLen( "Test", XL, TextHeight );
    C.Font = MyFonts.GetSmallFont( C.ClipX );
    C.StrLen( "Test", XL, SmallTextHeight );
    CatHeight = CatHeight * 1.2;
    TextHeight = TextHeight * 1.2;
    SmallTextHeight = SmallTextHeight * 1.1;
    VSpacing = HeaderHeight * 0.8;
    BorderSpacing = VSpacing;
    TotalHeight = 1.5 * HeaderHeight + 2 * BorderSpacing + CatHeight * 3 + TextHeight * 6 + SmallTextHeight * 7 + VSpacing * 3;
    StartY = C.ClipY / 2 - TotalHeight / 2;
    SideSpacing = C.ClipX / 10;
    bFontUpdated = True;
    LastUpdateTime = Level.TimeSeconds;
  }

  GRI = PlayerPawn(Owner).GameReplicationInfo;

  DrawTitle( C );
  DrawContactInfo( C, GRI );
  DrawMOTD( C, GRI );
  DrawGameStats( C, GRI );
  DrawServerStats( C, GRI );
  DrawLeaderBoard( C, GRI );
}

function DrawTitle( Canvas C )
{
  Y = StartY;

  C.Style = ERenderStyle.STY_Modulated;
  C.SetPos( SideSpacing - BorderSpacing, Y );
  C.DrawRect( texture'shade', C.ClipX - 2 * SideSpacing + 2 * BorderSpacing , TotalHeight );
  C.Style = ERenderStyle.STY_Translucent;
  C.DrawColor.R = 32;
  C.DrawColor.G = 32;
  C.DrawColor.B = 32;
  C.SetPos( SideSpacing - BorderSpacing, Y );
  C.DrawPattern( texture'newblue', C.ClipX - 2 * SideSpacing + 2 * BorderSpacing , 1.5 * HeaderHeight, 1.0 );
  C.Style = ERenderStyle.STY_Normal;

  C.Font = MyFonts.GetHugeFont( C.ClipX );
  C.DrawColor = HeaderBlue;

  C.bCenter = True;
  C.SetPos( 0, Y + 0.25 * HeaderHeight );
  C.DrawText( ServerInfoText, True );
  C.bCenter = False;

  Y += 1.5 * HeaderHeight + BorderSpacing;
}

function DrawContactInfo( Canvas C, GameReplicationInfo GRI )
{
  local float XL, YL, XL2, YL2;

  C.DrawColor = HeaderBlue;
  C.Font = MyFonts.GetBigFont( C.ClipX );
  C.StrLen( "TEMP", XL, YL );

  C.SetPos( SideSpacing, Y );
  C.DrawText( ContactInfoText, True);

  C.DrawColor = TextBlue;
  C.Font = MyFonts.GetSmallFont( C.ClipX );
  C.StrLen( "TEMP", XL2, YL2 );

  C.SetPos( SideSpacing, Y + CatHeight );
  C.DrawText( NameText, True);

  C.SetPos( SideSpacing, Y + CatHeight + TextHeight );
  C.DrawText( AdminText, True);

  C.SetPos( SideSpacing, Y + CatHeight + 2 * TextHeight);
  C.DrawText( EMailText, True);

  C.DrawColor = InfoWhite;
  C.SetPos( SideSpacing + XL2 * 2, Y + CatHeight );
  C.DrawText( GRI.ServerName, True);

  C.SetPos( SideSpacing + XL2 * 2, Y + CatHeight + TextHeight );
  if( GRI.AdminName != "" )
    C.DrawText( GRI.AdminName, True );
  else
    C.DrawText( UnknownText, True );

  C.SetPos( SideSpacing + XL2 * 2, Y + CatHeight + 2 * TextHeight );
  if( GRI.AdminEmail != "" )
    C.DrawText( GRI.AdminEmail, True );
  else
    C.DrawText( UnknownText, True );
}

function DrawMOTD( Canvas C, GameReplicationInfo GRI )
{
  local float XL, YL, XL2, YL2;

  C.DrawColor = HeaderBlue;

  C.Font = MyFonts.GetBigFont( C.ClipX );
  C.StrLen( "TEMP", XL, YL );

  C.SetPos( SideSpacing * 6, Y );
  C.DrawText( MOTD, True );

  C.DrawColor = InfoWhite;

  C.Font = MyFonts.GetSmallFont( C.ClipX );
  C.StrLen( "TEMP", XL2, YL2 );

  C.StrLen( GRI.MOTDLine1, XL2, YL2 );
  C.SetPos( SideSpacing * 6, Y + CatHeight );
  C.DrawText( GRI.MOTDLine1, True );

  C.StrLen( GRI.MOTDLine2, XL2, YL2 );
  C.SetPos( SideSpacing * 6, Y + CatHeight + TextHeight );
  C.DrawText( GRI.MOTDLine2, True );

  C.StrLen( GRI.MOTDLine3, XL2, YL2 );
  C.SetPos( SideSpacing * 6, Y + CatHeight + 2 * TextHeight );
  C.DrawText( GRI.MOTDLine3, True );

  C.StrLen( GRI.MOTDLine4, XL2, YL2 );
  C.SetPos( SideSpacing * 6, Y + CatHeight + 3 * TextHeight );
  C.DrawText( GRI.MOTDLine4, True );

  Y += CatHeight + 4 * TextHeight + VSpacing;
}

function DrawGameStats( Canvas C, GameReplicationInfo GRI )
{
  local float XL, YL, XL2, YL2;
  local int i, NumBots;

  C.DrawColor = HeaderBlue;

  C.Font = MyFonts.GetBigFont( C.ClipX );
  C.StrLen( "TEMP", XL, YL );

  C.SetPos( SideSpacing, Y );
  C.DrawText( GameStatsText, True );

  C.DrawColor = TextBlue;

  C.Font = MyFonts.GetSmallFont( C.ClipX );
  C.StrLen( "TEMP", XL2, YL2 );

  C.SetPos( SideSpacing, Y + CatHeight );
  C.DrawText( GameTypeText, True );

  C.SetPos( SideSpacing, Y + CatHeight + TextHeight );
  C.DrawText( PlayersText, True );

  C.DrawColor = InfoWhite;

  C.SetPos( SideSpacing * 2, Y + CatHeight );
  C.DrawText( "Smart Death Match", True); // GRI.GameName

  for( i = 0; i < 32; i++ )
  {
    if( ( GRI.PRIArray[i] != none ) && ( GRI.PRIArray[i].bIsABot ) ) NumBots++;
  }
  C.SetPos( SideSpacing * 2, Y + CatHeight + TextHeight );
  C.DrawText( GRI.NumPlayers $ "   [" $ NumBots @ BotText $ "]", True );
}

function DrawServerStats( canvas C, GameReplicationInfo GRI )
{
  local float XL, YL, XL2, YL2;
  local TournamentGameReplicationInfo TGRI;

  C.DrawColor = HeaderBlue;

  C.Font = MyFonts.GetBigFont( C.ClipX );
  C.StrLen( "TEMP", XL, YL );

  C.SetPos( SideSpacing * 6, Y );
  C.DrawText( ServerStatsText, True );

  C.DrawColor = TextBlue;

  C.Font = MyFonts.GetSmallFont( C.ClipX );
  C.StrLen( "TEMP", XL2, YL2 );

  C.SetPos( SideSpacing * 6, Y + CatHeight );
  C.DrawText( GamesHostedText, True);

  C.SetPos( SideSpacing * 6, Y + CatHeight + TextHeight );
  C.DrawText( FlagsCapturedText, True);

  C.DrawColor = InfoWhite;

  TGRI = TournamentGameReplicationInfo( GRI );

  C.SetPos( SideSpacing * 7.25, Y + CatHeight );
  C.DrawText( TGRI.TotalGames, True );

  C.SetPos( SideSpacing * 7.25, Y + CatHeight + TextHeight );
  C.DrawText( TGRI.TotalFlags, True );

  Y += CatHeight + 2 * TextHeight + VSpacing;
}

function DrawLeaderBoard( Canvas C, GameReplicationInfo GRI )
{
  local float YL;
  local int i;
  local SmartDMEndStats EndStats;
  local string Title, What, Who, Where, When;

  C.DrawColor = HeaderBlue;

  YL = ( CatHeight + SmallTextHeight - 4 ) / 64;
  C.Font = MyFonts.GetBigFont( C.ClipX );
  C.SetPos( SideSpacing + 68 * YL, Y );
  C.DrawText( TopPlayersText, True );

  C.DrawColor = InfoWhite;
  C.Style = ERenderStyle.STY_Translucent;
  C.bNoSmooth = False;
  C.SetPos( SideSpacing, Y );
  C.DrawIcon( texture'UTMenu.TrophyCTF', YL );
  C.SetPos( SideSpacing, Y );

  C.bNoSmooth = True;
  C.Style = ERenderStyle.STY_Normal;

  C.Font = MyFonts.GetSmallestFont( C.ClipX );
  C.DrawColor = TextBlue;

  C.SetPos( SideSpacing * 2.5, Y + CatHeight );
  C.DrawText( BestFPHText, True );

  C.SetPos( SideSpacing * 3.75, Y + CatHeight );
  C.DrawText( BestNameText, True );

  C.SetPos( SideSpacing * 5.75, Y + CatHeight );
  C.DrawText( MapNameText, True );

  C.SetPos( SideSpacing * 7.5, Y + CatHeight );
  C.DrawText( BestRecordSetText, True );

  C.DrawColor = InfoWhite;

  if( SDMGame != none ) EndStats = SDMGame.EndStats;
  if( EndStats != None )
  {
    for( i = 1; i < 6; i++ )
    {
      switch( i )
      {
        case 1:
          Title = "Biggest DM'er";
          What = EndStats.MostFrags.Count @ "frags/h";
          Who = EndStats.MostFrags.PlayerName;
          Where = EndStats.MostFrags.MapName;
          When = EndStats.MostFrags.RecordDate;
          break;
        case 2:
          Title = "Greatest Survivor";
          What = EndStats.MostSurvivability.Count @ "seconds";
          Who = EndStats.MostSurvivability.PlayerName;
          Where = EndStats.MostSurvivability.MapName;
          When = EndStats.MostSurvivability.RecordDate;
          break;
        case 3:
          Title = "Greatest Spree 'Ho";
          What = EndStats.MostSprees.Count@"";
          Who = EndStats.MostSprees.PlayerName;
          Where = EndStats.MostSprees.MapName;
          When = EndStats.MostSprees.RecordDate;
          break;
        case 4:
          Title = "Greatest MultiKiller";
          What = EndStats.MostMultiLevelKills.Count@"";
          Who = EndStats.MostMultiLevelKills.PlayerName;
          Where = EndStats.MostMultiLevelKills.MapName;
          When = EndStats.MostMultiLevelKills.RecordDate;
          break;
        case 5:
          Title = "Hardcore Sniper";
          What = EndStats.MostHeadShots.Count @ "HS/h";
          Who = EndStats.MostHeadShots.PlayerName;
          Where = EndStats.MostHeadShots.MapName;
          When = EndStats.MostHeadShots.RecordDate;
          break;
      }
      if( What == "" ) What = "--";
      if( Who == "" ) Who = "--";
      if( Where == "" ) Where = "--";
      if( When == "" ) When = "--";
      if( Len( Where ) > 20 ) Where = Left( Where, 20 ) $ "..";
      if( Len( Who ) > 25 ) Who = Left( Who, 25 ) $ "..";

      C.DrawColor = TextBlue;
      C.SetPos( SideSpacing, Y + CatHeight + ( ( i + 1 ) * SmallTextHeight ) );
      C.DrawText( Title, True );
      C.DrawColor = InfoWhite;
      C.SetPos( SideSpacing * 2.5, Y + CatHeight + ( ( i + 1 ) * SmallTextHeight ) );
      C.DrawText( What, True );
      C.SetPos( SideSpacing * 3.75, Y + CatHeight + ( ( i + 1 ) * SmallTextHeight ) );
      C.DrawText( Who, True );
      C.SetPos( SideSpacing * 5.75, Y + CatHeight + ( ( i + 1 ) * SmallTextHeight ) );
      C.DrawText( Where, True );
      C.SetPos( SideSpacing * 7.5, Y + CatHeight + ( ( i + 1 ) * SmallTextHeight ) );
      C.DrawText( When, True );
    }
  }
}

defaultproperties
{
    MapNameText="Where"
    HeaderBlue=(R=9,G=151,B=247,A=0),
    TextBlue=(R=0,G=128,B=255,A=0),
    InfoWhite=(R=255,G=255,B=255,A=0),
    TopPlayersText="SmartDM Record Holders"
    BestNameText="Who"
    BestFPHText="What"
    BestRecordSetText="When"
}
