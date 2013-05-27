class SmartDMScoreBoard extends TournamentScoreBoard config( SmartDMScoreboard );

#exec texture IMPORT NAME=meter FILE=Textures\meter.pcx GROUP=SmartDM MIPS=OFF
#exec texture IMPORT NAME=shade File=Textures\shade.pcx GROUP=SmartDM MIPS=OFF
#exec texture IMPORT NAME=faceless File=Textures\faceless.pcx GROUP=SmartDM

var ScoreBoard NormalScoreBoard;
var SmartDMGameReplicationInfo SDMGame;
var SmartDMPlayerReplicationInfo OwnerStats;

var int TryCount;
var PlayerPawn PlayerOwner;

var string DeathsText, FragsText, SepText, MoreText, HeaderText ,CreditText;
var int LastSortTime, MaxMeterWidth;
var byte ColorChangeSpeed, RowColState;
var color White, Gray, DarkGray, Yellow, RedColor, BlueColor, RedHeaderColor, BlueHeaderColor, StatsColor, FooterColor, HeaderColor, TinyInfoColor, HeaderTinyInfoColor;
var float StatsTextWidth, StatHeight, MeterHeight, NameHeight, ColumnHeight, StatBlockHeight;
var float LeftStartX, RightStartX ,ColumnWidth, StatWidth, StatsHorSpacing, ShadingSpacingX, HeaderShadingSpacingY, ColumnShadingSpacingY;
var float StartY, StatLineHeight, StatBlockSpacing, StatIndent ,MidSpacingPercent;
var TournamentGameReplicationInfo pTGRI;
var PlayerReplicationInfo pPRI;
var Font StatFont, CapFont, FooterFont, GameEndedFont, PlayerNameFont, DeathsFont, TinyInfoFont;
var Font PtsFont22, PtsFont20, PtsFont18, PtsFont16, PtsFont14, PtsFont12;

var int MaxFrags, MaxDeaths ,MaxSpreeEnd ,MaxSucide ,MaxSurv ,MaxPL ,MaxNetSpeed;
var int TotPlayers;
var bool bStarted;
var bool bEndHandled;
var bool bLMS;

//User's settings
var() config bool bShowNetSpeedAndPL;

struct FlagData
{
	var string Prefix;
	var texture Tex;
};
var FlagData FD[32]; // there can be max 32 so max 32 different flags
var int saveindex; // new loaded flags will be saved in FD[index]

function int GetFlagIndex(string Prefix)
{
	local int i;
	for(i=0;i<32;i++)
		if(FD[i].Prefix == Prefix)
			return i;
	FD[saveindex].Prefix=Prefix;
	FD[saveindex].Tex=texture(DynamicLoadObject(SDMGame.CountryFlagsPackage$"."$Prefix, class'Texture'));
	i=saveindex;
	saveindex = (saveindex+1) % 256;
	return i;
}

function PostBeginPlay()
{
  super.PostBeginPlay();

  SaveConfig();
  PlayerOwner = PlayerPawn( Owner );
  pTGRI = TournamentGameReplicationInfo( PlayerOwner.GameReplicationInfo );
  pPRI = PlayerOwner.PlayerReplicationInfo;
  LastSortTime = -100;

  // Preload
  PtsFont22 = Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
  PtsFont20 = Font( DynamicLoadObject( "LadderFonts.UTLadder20", class'Font' ) );
  PtsFont18 = Font( DynamicLoadObject( "LadderFonts.UTLadder18", class'Font' ) );
  PtsFont16 = Font( DynamicLoadObject( "LadderFonts.UTLadder16", class'Font' ) );
  PtsFont14 = Font( DynamicLoadObject( "LadderFonts.UTLadder14", class'Font' ) );
  PtsFont12 = Font( DynamicLoadObject( "LadderFonts.UTLadder12", class'Font' ) );

  SpawnNormalScoreBoard();
  if( NormalScoreBoard == none ) SetTimer( 1.0 , True );
  else
  {
      bStarted = True;
      SetTimer( 3.0, true);
  }
}

// Try to spawn a local instance of the original scoreboard class if it doesn't exist already.
function SpawnNormalScoreBoard()
{
  if( SDMGame == none )
  {
    foreach AllActors( class'SmartDMGameReplicationInfo', SDMGame ) break;
  }
  if( SDMGame == none ) return;

  //Scoreboard settings
  if( !SDMGame.bNewFragSystem ) FragsText = "Score";
  if( InStr ( pTGRI.GameClass, "LastManStanding" ) != -1 )
  {
   FragsText = "Lives";
   DeathsText = "Kills";
   bLMS = true;
  }

  OwnerStats = SDMGame.GetStats( PlayerOwner );

  if( SDMGame.NormalScoreBoardClass == none )
  {
    Log( "Unable to identify original ScoreBoard type. Retrying in 1 second." , 'SmartDM' );
    return;
  }

  if( SDMGame.NormalScoreBoardClass == self.Class )
  {
    NormalScoreBoard = Spawn( class'TournamentScoreBoard', PlayerOwner );
    Log( "Cannot use itself. Using the default DM ScoreBoard instead." , 'SmartDM' );
    return;
  }

  if( SDMGame.NormalScoreBoardClass != none )
  {
    NormalScoreBoard = Spawn( SDMGame.NormalScoreBoardClass, PlayerOwner );
    Log( "Determined and spawned original scoreboard as" @ NormalScoreBoard, 'SmartDM' );
  }
}

// In the case of the 'normal scoreboard' not being replicated properly, try every second
// to see if it has.
function Timer()
{
  if( !bStarted )
  {
      if( NormalScoreBoard == None )
      {
        TryCount++;
        SpawnNormalScoreBoard();
      }

      if( NormalScoreBoard != None )
      {
        bStarted = True;
        SetTimer( 3.0, True );
      }
      else if( TryCount > 3 )
      {
        Log( "Given up. Using the default DM ScoreBoard instead." , 'SmartDM' );

        if( NormalScoreBoard == None )
        {
          NormalScoreBoard = Spawn( class'TournamentScoreBoard', PlayerOwner );
          Log( "Spawned as" @ NormalScoreBoard, 'SmartDM' );
        }
        bStarted = True;
        SetTimer( 3.0, True );
      }
    }
}

function ShowScores( Canvas C )
{
  if( SDMGame == none || OwnerStats == none )
  {
    if( NormalScoreBoard != none ) NormalScoreBoard.ShowScores( C );
    else PlayerOwner.bShowScores = False;
    return;
  }

  if( OwnerStats.bEndStats && !bEndHandled )
  {
      bEndHandled = true;
      SetTimer(10, true);
  }

  if( OwnerStats.bViewingStats )
    SmartDMShowScores( C );
  else
  {
    if( NormalScoreBoard == none ) SmartDMShowScores( C );
    else NormalScoreBoard.ShowScores( C );
  }

  if( OwnerStats.IndicatorVisibility > 0 ) ShowIndicator( C );
}

function ShowIndicator( Canvas C )
{
  local float BlockLen, LineHeight;

  C.DrawColor.R = OwnerStats.IndicatorVisibility;
  C.DrawColor.G = OwnerStats.IndicatorVisibility;
  C.DrawColor.B = OwnerStats.IndicatorVisibility;
  C.Style = ERenderStyle.STY_Translucent;
  C.Font = C.SmallFont;
  C.StrLen( "Scoreboard:", BlockLen, LineHeight );
  C.SetPos( C.ClipX - BlockLen - 16, 16 );
  C.DrawText( "Scoreboard:" );
  C.SetPos( C.ClipX - BlockLen, 16 + LineHeight );
  C.DrawText( "Default" );
  C.SetPos( C.ClipX - BlockLen, 16 + 2 * LineHeight );
  C.DrawText( "SmartDM" );
  if( OwnerStats.bViewingStats ) C.SetPos( C.ClipX - BlockLen - 16, 16 + 2 * LineHeight );
  else C.SetPos( C.ClipX - BlockLen - 16, 16 + LineHeight );
  C.DrawIcon( texture'UWindow.MenuTick', 1 );
  C.Style = ERenderStyle.STY_Normal;

  if( Level.TimeSeconds - OwnerStats.IndicatorStartShow > 2 ) OwnerStats.IndicatorVisibility = 0;
}

function SmartDMShowScores( Canvas C )
{
  local int ID, i, j, Time, AvgPing, AvgPL, TotSB, TotAmp;
  local float Eff;
  local int X, Y ,LeftY ,RightY ,TempSc;
  local float Nil, DummyX, DummyY, SizeX, SizeY, Buffer, Size;
  local byte LabelDrawn[2], Rendered;
  local Color PlayerColor, TempColor;
  local string TempStr;
  local SmartDMPlayerReplicationInfo PlayerStats, PlayerStats2;
  local int FlagShift; /* shifting elements to fit a flag */

  if( Level.TimeSeconds - LastSortTime > 0.5 )
  {
    SortScores( 32 );
    RecountNumbers();
    InitStatBoardConstPos( C );
   // CompressStatBoard( C ); No,not in this version
  }

  Y = int( StartY );
  LeftY = Y;
  RightY = Y;

  C.Style = ERenderStyle.STY_Normal;

  // FOR EACH PLAYER DRAW INFO
  for( i = 0; i < 32; i++ )
  {
    if( Ordered[i] == none ) break;
    PlayerStats = SDMGame.GetStatsByPRI( Ordered[i] );
    if( PlayerStats == None ) continue;

    // Get the ID of the ith player
    ID = Ordered[i].PlayerID;

    // set the pos depending on Rank
    if( i%2 == 0 )//left side
    {
      X = LeftStartX;
      Y = LeftY;
    }
    else
    {
      X = RightStartX;
      Y = RightY;
    }

    C.DrawColor = RedColor;
    C.Font = FooterFont;
    C.StrLen( "Test", Nil, DummyY );
    C.Font = PlayerNameFont;
    C.StrLen( "TEST", SizeX, SizeY );

    // DRAW THE INDIVIDUAL SCORES with the cool Flag icons (masked because of black borders)

    if(  Y + 10 + SizeY + HeaderShadingSpacingY*2 + ColumnShadingSpacingY + NameHeight + StatBlockHeight + StatBlockSpacing > C.ClipY - DummyY * 5  )
    {
      if( i%2 == 0 ) //Draw only on middle from Left side (check not needed but still :)
      {
       C.DrawColor = RedColor;
       C.Font = FooterFont;
       C.StrLen( "[" @ TotPlayers - Rendered @ MoreText @ "]" , Size, DummyY );
       C.SetPos( X + ColumnWidth + ( MidSpacingPercent * C.ClipX )/2 - Size/2, Y + DummyY * 2 );
       C.DrawText( "[" @ TotPlayers - Rendered @ MoreText @ "]" );
      }
      break;
    }
    else
    {
     C.bNoSmooth = False;
     //C.Font = PlayerNameFont;
     C.Style = ERenderStyle.STY_Translucent;
     C.DrawColor = RedHeaderColor;
     C.StrLen( FragsText, SizeX, SizeY );
     C.Style = ERenderStyle.STY_Modulated;
     C.SetPos( X - ShadingSpacingX, Y - HeaderShadingSpacingY );
     C.DrawRect( texture'shade', ColumnWidth + ( ShadingSpacingX * 2 ) , SizeY + HeaderShadingSpacingY*2 + ColumnShadingSpacingY + NameHeight + StatBlockHeight + StatBlockSpacing );
     C.Style = ERenderStyle.STY_Translucent;
     C.SetPos( X - ShadingSpacingX, Y - HeaderShadingSpacingY );
     C.DrawPattern( texture'blueskin2', ColumnWidth + ( ShadingSpacingX * 2 ) , SizeY + ( HeaderShadingSpacingY * 2 ) , 1 );

     if( bLMS && Ordered[i].Score < 1 )
      C.DrawColor = Gray;
     else
      C.DrawColor = RedColor;

     C.SetPos( X, Y - ( ( 32 - SizeY ) / 2 ) ); // Y - 4
     C.DrawIcon( texture'I_TeamR', 0.5 );

     if( bLMS && Ordered[i].Score < 1 )
      C.DrawColor = Gray;
     else
      C.DrawColor = BlueColor;;
     C.Font = CapFont;
     C.StrLen(  i+1, DummyX, DummyY );
     C.Style = ERenderStyle.STY_Normal;
     C.SetPos( X + StatIndent, Y - ( ( DummyY - SizeY ) / 2 ) );
     C.DrawText( ( i+1 ) );

     //Draw the Deaths/Frags text
     C.Font = PlayerNameFont;
     C.SetPos( X + ColumnWidth - SizeX, Y );
     C.DrawText( FragsText );
     C.Font = DeathsFont;
     C.StrLen( DeathsText $ SepText, Buffer, Nil );
     C.SetPos( X + ColumnWidth - SizeX - Buffer, Y );
     C.DrawText( DeathsText $ SepText );

     // Draw the player name
     C.Font = PlayerNameFont;
     C.StrLen( "TEST", Nil, DummyY );
     C.SetPos( X + StatIndent + DummyX + 2 * StatsHorSpacing, Y - ( ( DummyY - SizeY ) / 2 ) );
     if( Ordered[i].bAdmin ) C.DrawColor = White;
     else if( bLMS && Ordered[i].Score < 1 )
     {
      if( Ordered[i].PlayerID == pPRI.PlayerID ) C.DrawColor = DarkGray;
      else C.DrawColor = Gray;
     }
     else if( Ordered[i].PlayerID == pPRI.PlayerID ) C.DrawColor = Yellow;
     else C.DrawColor = BlueColor;
     TempColor = C.DrawColor;
     C.DrawText( Ordered[i].PlayerName );
     //C.StrLen( Ordered[i].PlayerName, Size, Buffer );

     C.bNoSmooth = True;
     Y += SizeY + HeaderShadingSpacingY + ColumnShadingSpacingY;

     C.Font = FooterFont;
     C.StrLen( "Test", Nil, DummyY );


      // Draw the face
      C.bNoSmooth = False;
      C.DrawColor = White;
      C.Style = ERenderStyle.STY_Translucent;
      C.SetPos( X, Y );
      if( SDMGame.bStatsDrawFaces && Ordered[i].TalkTexture != none ) C.DrawIcon( Ordered[i].TalkTexture, 0.5 );
      else C.DrawIcon( texture'faceless', 0.5 );
      C.SetPos( X, Y );
      C.DrawColor = DarkGray;
      C.DrawIcon( texture'IconSelection', 1 );
      C.Style = ERenderStyle.STY_Normal;
      C.bNoSmooth = True;

      C.DrawColor = TinyInfoColor;
      C.Font = TinyInfoFont;
      C.StrLen( "TEST", Buffer, DummyY );

      // Draw Time, HS, SB, Amp + more stuff
      C.SetPos( X + StatIndent + StatsHorSpacing , Y + ( NameHeight - DummyY * 2 ) / 2 );
      TempStr = "";
      TempSc = int( SelElem( PlayerStats.PlayerStatsString, 15 ) );
      if( TempSc != 0 ) TempStr = TempStr $ "SB:" $ TempSc ;
      TempSc = int( SelElem( PlayerStats.PlayerStatsString, 16 ) );
      if( TempSc != 0 ) TempStr = TempStr @ "AM:" $ TempSc;
      TempSc = int( SelElem( PlayerStats.PlayerStatsString, 17 ) );
      if( TempSc != 0 ) TempStr = TempStr @ "AR:" $ TempSc;
      TempSc = int( SelElem( PlayerStats.PlayerStatsString, 18 ) );
      if( TempSc != 0 ) TempStr = TempStr @ "JB:" $ TempSc;
      TempSc = int( SelElem( PlayerStats.PlayerStatsString, 19 ) );
      if( TempSc != 0 ) TempStr = TempStr @ "IN:" $ TempSc;
      TempSc = int( SelElem( PlayerStats.PlayerStatsString, 21 ) );
      if( TempSc != 0 ) TempStr = TempStr @ "TH:" $ TempSc;
     // if( Left( TempStr, 1 ) == " " ) TempStr = Mid( TempStr, 1 );
      C.DrawText( TempStr );
      TempStr = "";
      Time = Max( 1, ( Level.TimeSeconds + pPRI.StartTime - Ordered[i].StartTime ) / 60 );
      TempStr = "TIME:" $ Time;
      if( PlayerStats.HeadShots != 0 ) TempStr = TempStr @ "HS:" $ PlayerStats.HeadShots;
      C.SetPos( X + StatIndent + StatsHorSpacing, Y + ( NameHeight - DummyY * 2 ) / 2 + DummyY );
      C.DrawText( TempStr );

      // Draw the country flag
      if(PlayerStats.CountryPrefix != "")
      {
        C.SetPos( X+8, Y + StatIndent);
        C.bNoSmooth = False;
        C.DrawColor = White;
        C.DrawIcon(FD[GetFlagIndex(PlayerStats.CountryPrefix)].Tex, 1.0);
        FlagShift=12;
        C.bNoSmooth = True;
      }
      else
        FlagShift=0;
      // Draw Bot or Ping/PL
      C.SetPos( X, Y + StatIndent + FlagShift);
      if( Ordered[i].bIsABot )
      {
        C.DrawText( "BOT" );
      }
      else
      {
        C.DrawColor = HeaderTinyInfoColor;
        TempStr = "PI:" $ Ordered[i].Ping;
        if( Len( TempStr ) > 5 ) TempStr = "P:" $ Ordered[i].Ping;
        if( Len( TempStr ) > 5 ) TempStr = string( Ordered[i].Ping );
        C.DrawText( TempStr );
        if( !bShowNetSpeedAndPL )
        {
         C.SetPos( X, Y + StatIndent + DummyY + FlagShift);
         TempStr = "PL:" $ Ordered[i].PacketLoss $ "%";
         if( Len( TempStr ) > 5 ) TempStr = "L:" $ Ordered[i].PacketLoss $ "%";
         if( Len( TempStr ) > 5 ) TempStr = "L:" $ Ordered[i].PacketLoss;
         if( Len( TempStr ) > 5 ) TempStr = Ordered[i].PacketLoss $ "%";
         C.DrawText( TempStr );
        }
      }

      C.Font = PlayerNameFont;
      C.DrawColor = TempColor;

      // Draw Death/Frags/Score
      if( !SDMGame.bNewFragSystem || bLMS )
      {
       C.StrLen( int(Ordered[i].Score), Size, DummyY );
       C.SetPos( X + ColumnWidth - Size, Y );
       C.DrawText( int(Ordered[i].Score) );
      }
      else
      {
       C.StrLen( PlayerStats.Frags, Size, DummyY );
       C.SetPos( X + ColumnWidth - Size, Y );
       C.DrawText( PlayerStats.Frags );
      }

      if( !bLMS )
      {
       C.Font = DeathsFont;
       C.StrLen( int(Ordered[i].Deaths) $ SepText, Buffer, SizeY );
       C.SetPos( X + ColumnWidth - Size - Buffer, Y );
       C.DrawText( int(Ordered[i].Deaths) $ SepText );
      }
      else
      {
       C.Font = DeathsFont;
       C.StrLen( PlayerStats.Frags $ SepText, Buffer, SizeY );
       C.SetPos( X + ColumnWidth - Size - Buffer, Y );
       C.DrawText( PlayerStats.Frags $ SepText );
      }

      Y += NameHeight;

      // Set the Font for the stat drawing
      C.Font = StatFont;

      if( PlayerStats.Frags + Ordered[i].Deaths == 0 ) Eff = 0;
      else Eff = ( PlayerStats.Frags / ( PlayerStats.Frags + Ordered[i].Deaths ) ) * 100;
      DrawStatType( C, X, Y, 1, 1, "Eff:", Eff, 100 ,true);
      //DrawSurv( C, X, Y, 2, 1, "Surv:", int(SelElem(PlayerStats.PlayerStatsString,20)), 100 ,true);
      if( !bShowNetSpeedAndPL || Ordered[i].bIsABot )
      {
       DrawStatType( C, X, Y, 2, 1, "Surv:", int(SelElem(PlayerStats.PlayerStatsString,20)), MaxSurv );
       DrawStatType( C, X, Y, 3, 1, "SpreEnd:", int(SelElem(PlayerStats.PlayerStatsString,13)), MaxSpreeEnd );
      }
      else
      {
       DrawNetSpeed( C, X, Y, 3, 1, "NS:", PlayerStats.NetSpeed, MaxNetSpeed );
       DrawStatType( C, X, Y, 2, 1, "PL:", Ordered[i].PacketLoss, MaxPL ,true);
      }
      DrawStatType( C, X, Y, 1, 2, "Sucides:",int(SelElem(PlayerStats.PlayerStatsString,14)), MaxSucide );
      DrawSpree( C, X, Y, 2, 2, "Sprees:", PlayerStats.PlayerStatsString);
      DrawMultiKill( C, X, Y, 3, 2, "MultKils:", PlayerStats.PlayerStatsString );


      Y += StatBlockHeight + StatBlockSpacing + 10;
    }

    // Alter the LeftY or RightY and do next player
    if( i%2 == 0 )
     LeftY = Y;
    else
     RightY = Y;
    Rendered++;

  } //End of PRI for loop

  DrawHeader( C );
  DrawFooters( C );
}

function InitStatBoardConstPos( Canvas C )
{
  local float Nil, LeftSpacingPercent, RightSpacingPercent;

  CapFont = Font'LEDFont2';
  FooterFont = MyFonts.GetSmallestFont( C.ClipX );
  GameEndedFont = MyFonts.GetHugeFont( C.ClipX );
  PlayerNameFont = MyFonts.GetBigFont( C.ClipX );
  TinyInfoFont = C.SmallFont;

  if( PlayerNameFont == PtsFont22 ) DeathsFont = PtsFont18;
  else if( PlayerNameFont == PtsFont20 ) DeathsFont = PtsFont18;
  else if( PlayerNameFont == PtsFont18 ) DeathsFont = PtsFont14;
  else if( PlayerNameFont == PtsFont16 ) DeathsFont = PtsFont12;
  else DeathsFont = font'SmallFont';

  C.Font = PlayerNameFont;
  C.StrLen( "Player", Nil, NameHeight );

  StartY = ( 120.0 / 1024.0 ) * C.ClipY;
  ColorChangeSpeed = 100; // Influences how 'fast' the color changes from white to green. Higher = faster.

  LeftSpacingPercent = 0.045;
  MidSpacingPercent = 0.10;
  RightSpacingPercent = 0.045;
  LeftStartX = LeftSpacingPercent * C.ClipX;
  ColumnWidth = ( ( 1 - LeftSpacingPercent - MidSpacingPercent - RightSpacingPercent ) / 2 * C.ClipX );
  RightStartX = LeftStartX + ColumnWidth + ( MidSpacingPercent * C.ClipX );
  ShadingSpacingX = ( 10.0 / 1024.0 ) * C.ClipX;
  HeaderShadingSpacingY = ( 32 - NameHeight ) / 2 + ( ( 4.0 / 1024.0 ) * C.ClipX );
  ColumnShadingSpacingY = ( 10.0 / 1024.0 ) * C.ClipX;

  StatsHorSpacing = ( 5.0 / 1024.0 ) * C.ClipX;
  StatIndent = ( 32 + StatsHorSpacing ); // For face + flag icons

  InitStatBoardDynamicPos( C );
}

function InitStatBoardDynamicPos( Canvas C , optional int Rows , optional int Cols , optional Font NewStatFont , optional float LineSpacing , optional float BlockSpacing )
{
  if( Rows == 0 ) Rows = 3;
  if( Cols == 0 ) Cols = 2;
  if( LineSpacing == 0 ) LineSpacing = 0.9;
  if( BlockSpacing == 0 ) BlockSpacing = 1;

  if( Rows == 2 && Cols == 3 ) RowColState = 1;
  else RowColState = 0;

  StatWidth = ( ( ColumnWidth - StatIndent ) / Cols ) - ( StatsHorSpacing * ( Cols - 1 ) );

  if( NewStatFont == none ) StatFont = MyFonts.GetSmallestFont( C.ClipX );
  else StatFont = NewStatFont;
  C.Font = StatFont;
  C.StrLen( "FlagKls: 00", StatsTextWidth, StatHeight );

  MaxMeterWidth = StatWidth - StatsTextWidth - StatsHorSpacing;
  StatLineHeight = StatHeight * LineSpacing;
  MeterHeight = Max( 1, StatLineHeight * 0.3 );
  StatBlockSpacing = StatLineHeight * BlockSpacing;

  StatBlockHeight = Rows * StatLineHeight;

  if( pTGRI.NumPlayers % 2 == 0 )
   ColumnHeight = ( pTGRI.NumPlayers/2 ) * ( NameHeight + StatBlockHeight + StatBlockSpacing ) - StatBlockSpacing;
  else
   ColumnHeight = ( pTGRI.NumPlayers/2 + 1 ) * ( NameHeight + StatBlockHeight + StatBlockSpacing ) - StatBlockSpacing;
}

function CompressStatBoard( Canvas C , optional int Level )
{
  local float EndY, Nil, DummyY;

  C.Font = FooterFont;
  C.StrLen( "Test", Nil, DummyY );

  EndY = StartY + ColumnHeight + ( ColumnShadingSpacingY * 2 ) + NameHeight + HeaderShadingSpacingY;
  if( EndY > C.ClipY - DummyY * 5 )
  {
    if( Level == 0 )
    {
      InitStatBoardDynamicPos( C, , , , 0.8 );
    }
    else if( Level == 1 )
    {
      InitStatBoardDynamicPos( C, 2, 3 );
    }
    else if( Level == 2 )
    {
      InitStatBoardDynamicPos( C, 2, 3, Font( DynamicLoadObject( "UWindowFonts.Tahoma10", class'Font' ) ) , 1.0 , 1.0 );
    }
    else
    {
      // We did all the compression we can do. Draw 'More' labels later.
      // First find the columnheight for the amount of players that fit on it.
      ColumnHeight = int( ( C.ClipY - ( EndY - ColumnHeight ) - DummyY * 5 + StatBlockSpacing ) / ( NameHeight + StatBlockHeight + StatBlockSpacing ) )
        * ( NameHeight + StatBlockHeight + StatBlockSpacing ) - StatBlockSpacing;
      return;
    }
    // Did some compression, see if we need more.
    CompressStatBoard( C , Level + 1 );
  }
  // No compression at all or no more compression needed.
  return;
}

/*
 * Draw a specific stat
 * X, Y = Upper left corner of stats ( row,col: 1,1)
 */
function DrawStatType( Canvas C, int X, int Y, int Row, int Col, string Label, int Count, int Total ,optional bool bIsPercent)
{
  local float Size, DummyY;
  local int ColorChange, M;

  X += StatIndent + ( ( StatWidth + StatsHorSpacing ) * ( Col - 1 ) );
  Y += ( StatLineHeight * ( Row - 1 ) );

  C.DrawColor = StatsColor;
  C.SetPos( X, Y );
  C.DrawText( Label );
  if( bIsPercent )
  {
   C.StrLen( string(Count)$"%", Size, DummyY );
   C.SetPos( X + StatsTextWidth - Size, Y );
   C.DrawText( string(Count)$"%" ); //text
  }
  else
  {
   C.StrLen( Count, Size, DummyY );
   C.SetPos( X + StatsTextWidth - Size, Y );
   C.DrawText( Count ); //text
  }
  if( Count > 0 )
  {
    ColorChange = ColorChangeSpeed * loge( Count );
    if( ColorChange > 255 ) ColorChange = 255;
    C.DrawColor.R = StatsColor.R - ColorChange;
    C.DrawColor.B = StatsColor.B - ColorChange;
  }
  M = GetMeterLength( Count, Total );
  C.SetPos( X + StatsTextWidth + StatsHorSpacing, Y + ( ( StatHeight - MeterHeight ) / 2 ) );
  C.DrawRect( texture'meter', M, MeterHeight ); //meter
}

function DrawNetSpeed( Canvas C, int X, int Y, int Row, int Col, string Label, int Count, int Total ,optional bool bIsPercent)
{
  local float Size, DummyY;
  local int Perc;

  X += StatIndent + ( ( StatWidth + StatsHorSpacing ) * ( Col - 1 ) );
  Y += ( StatLineHeight * ( Row - 1 ) );

  C.DrawColor = StatsColor;
  C.SetPos( X, Y );
  C.DrawText( Label );

  Perc = (Count*100) / Total;
  C.StrLen( Perc$"%", Size, DummyY );
  C.SetPos( X + StatsTextWidth - Size, Y );
  C.DrawText( Perc$"%" ); //text

  C.SetPos( X + StatsTextWidth + StatsHorSpacing, Y );
  C.DrawText( Count );
}


function DrawSpree( Canvas C, int X, int Y, int Row, int Col, string Label, string Str  )
{
  local float Size, DummyY ,DummyY2;
  local string Temp ,SpreeType[5];
  local int i ,p ,j ,Count;

  SpreeType[0] = "KS";
  SpreeType[1] = "RA";
  SpreeType[2] = "Do";
  SpreeType[3] = "UN";
  SpreeType[4] = "GD";
  X += StatIndent + ( ( StatWidth + StatsHorSpacing ) * ( Col - 1 ) );
  Y += ( StatLineHeight * ( Row - 1 ) );
  Temp = "";
  i = 2;

  C.DrawColor = StatsColor;
  C.SetPos( X, Y );
  C.StrLen( "TEST", Size, DummyY2 );
  C.DrawText( Label );

  C.Font = TinyInfoFont;
  while( i <= 6 )
  {
   p = int( SelElem( Str ,i++ ) );
   if( p != 0 )
   Temp = Temp@SpreeType[j]$":"$p;
   Count += p;
   j++;
  }
  C.StrLen( Temp, Size, DummyY );
  C.SetPos( X + StatsTextWidth  , Y + DummyY2 - DummyY - 3 );//I dont know.The trick should have worked :(.3 is the hit and trial
  C.DrawText( Temp ); //text

  C.Font = StatFont;
  C.StrLen( Count, Size, DummyY );
  C.SetPos( X + StatsTextWidth - Size, Y );
  C.DrawText( Count ); //text
}

function DrawMultiKill( Canvas C, int X, int Y, int Row, int Col, string Label, string Str  )
{
  local float Size, DummyY ,DummyY2;
  local string Temp ,KillType[6];
  local int i ,p ,j ,Count;

  KillType[0] = "DK";
  KillType[1] = "TK";
  KillType[2] = "MK";
  KillType[3] = "MeK";
  KillType[4] = "UK";
  KillType[5] = "MK";
  X += StatIndent + ( ( StatWidth + StatsHorSpacing ) * ( Col - 1 ) );
  Y += ( StatLineHeight * ( Row - 1 ) );
  Temp = "";
  i = 7;

  C.DrawColor = StatsColor;
  C.SetPos( X, Y );
  C.StrLen( "TEST", Size, DummyY2 );
  C.DrawText( Label );

  C.Font = TinyInfoFont;
  while( i <= 12 )
  {
   p = int( SelElem( Str ,i++ ) );
   if( p != 0 )
   Temp = Temp@KillType[j]$":"$p;
   Count += p;
   j++;
  }
  C.StrLen( Temp, Size, DummyY );
  C.SetPos( X + StatsTextWidth  , Y + DummyY2 - DummyY - 3 );
  C.DrawText( Temp ); //text

  C.Font = StatFont;
  C.StrLen( Count, Size, DummyY );
  C.SetPos( X + StatsTextWidth - Size, Y );
  C.DrawText( Count ); //text
}

function DrawSurv( Canvas C, int X, int Y, int Row, int Col, string Label, int Count, int Total ,optional bool bIsPercent)
{
  local float Size, DummyY , DummyY2;
  local int i ;

  X += StatIndent + ( ( StatWidth + StatsHorSpacing ) * ( Col - 1 ) );
  Y += ( StatLineHeight * ( Row - 1 ) );

  C.DrawColor = StatsColor;
  C.SetPos( X, Y );
  C.DrawText( Label );

  C.StrLen( Count, Size, DummyY2 );
  C.SetPos( X + StatsTextWidth - Size , Y );
  C.DrawText( Count ); //text

  C.Font = TinyInfoFont;
  C.StrLen( " seconds", Size, DummyY );
  C.SetPos( X + StatsTextWidth  , Y + DummyY2 - DummyY - 3 );
  C.DrawText( " seconds" ); //text
  C.Font = StatFont;
}

function DrawFooters( Canvas C )
{
  local float DummyX, DummyY, Nil, X1, Y1;
  local string TextStr;
  local string TimeStr;
  local int Hours, Minutes, Seconds, i;
  local PlayerReplicationInfo PRI;

  C.bCenter = True;
  C.Font = FooterFont;

  // Display server info in bottom center
  C.DrawColor = FooterColor;
  C.StrLen( "Test", DummyX, DummyY );
  C.SetPos( 0, C.ClipY - DummyY );
  TextStr = "Playing" @ Level.Title @ "on" @ pTGRI.ServerName;
  if( SDMGame.TickRate > 0 ) TextStr = TextStr @ "(TR:" @ SDMGame.TickRate $ ")";
  C.DrawText( TextStr );

  // Draw Time
  if( bTimeDown || ( PlayerOwner.GameReplicationInfo.RemainingTime > 0 ) )
  {
    bTimeDown = True;
    if( PlayerOwner.GameReplicationInfo.RemainingTime <= 0 )
    {
      TimeStr = RemainingTime $ "00:00";
    }
    else
    {
      Minutes = PlayerOwner.GameReplicationInfo.RemainingTime / 60;
      Seconds = PlayerOwner.GameReplicationInfo.RemainingTime % 60;
      TimeStr = RemainingTime $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
    }
  }
  else
  {
    Seconds = PlayerOwner.GameReplicationInfo.ElapsedTime;
    Minutes = Seconds / 60;
    Hours = Minutes / 60;
    Seconds = Seconds - ( Minutes * 60 );
    Minutes = Minutes - ( Hours * 60 );
    TimeStr = ElapsedTime $ TwoDigitString( Hours ) $ ":" $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );
  }

	if(SDMGame.bShowSpecs){
		for ( i=0; i<32; i++ )
		{
			if (PlayerPawn(Owner).GameReplicationInfo.PRIArray[i] != None)
			{
				PRI = PlayerPawn(Owner).GameReplicationInfo.PRIArray[i];
				if (PRI.bIsSpectator && !PRI.bWaitingPlayer && PRI.StartTime > 0)
				{
					if(HeaderText=="") HeaderText = pri.Playername; else HeaderText = HeaderText$", "$pri.Playername;
				}
			}
		}
		if (HeaderText=="") HeaderText = "There is currently no one spectating this match."; else HeaderText = HeaderText$".";
	}

  C.SetPos( 0, C.ClipY - 2 * DummyY );
  C.DrawText( "Current Time:" @ GetTimeStr() @ "|" @ TimeStr );


  C.StrLen( HeaderText, DummyX, Nil );
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( 0, C.ClipY - 6 * DummyY );

  if(SDMGame.bShowSpecs)
  {
  C.Font = MyFonts.GetSmallestFont(C.ClipX);
  C.DrawText("Spectators:"@HeaderText);
  HeaderText=""; // This is declared as a global var, so we reset it to start with a clean slate.
  }

  C.StrLen( CreditText, DummyX, DummyY );
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( 0, C.ClipY - 3 * DummyY );
  C.Font = MyFonts.GetSmallestFont(C.ClipX);
  C.DrawColor = Yellow;
  C.DrawText( CreditText );

  C.bCenter = False;
}

function DrawHeader( Canvas C )
{
  local float DummyX, DummyY , ScoreStart;

  if( pTGRI.GameEndedComments == "" )
  {
    C.DrawColor = WhiteColor;
	C.Font = MyFonts.GetHugeFont(C.ClipX);
    C.bCenter = True;
	ScoreStart = 5.0/1024.0 * C.ClipY;
    C.SetPos(0, ScoreStart);
	DrawVictoryConditions(C);
	return;
  }

  C.Font = GameEndedFont;
  C.StrLen( pTGRI.GameEndedComments, DummyX, DummyY );

  C.DrawColor = DarkGray;
  C.Style = ERenderStyle.STY_Translucent;
  C.SetPos( C.ClipX / 2 - DummyX / 2 + 2, DummyY + 2 );
  C.DrawText( pTGRI.GameEndedComments );

  C.DrawColor = HeaderColor;
  C.Style = ERenderStyle.STY_Normal;
  C.SetPos( C.ClipX / 2 - DummyX / 2, DummyY );
  C.DrawText( pTGRI.GameEndedComments );
}
/*
Ok as pointed by iloveut99 ,I need to override this function because
default function will draw time limit on player stats
*/
function DrawVictoryConditions(Canvas Canvas)
{
	local TournamentGameReplicationInfo TGRI;
	local float XL, YL;

	TGRI = TournamentGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	if ( TGRI == None )
		return;

	Canvas.DrawText(TGRI.GameName);
	Canvas.StrLen("Test", XL, YL);
	Canvas.SetPos(0, Canvas.CurY - YL);

	if ( TGRI.FragLimit > 0 )
	{
	  if( !bLMS )
      {
        if ( TGRI.TimeLimit > 0 )
		 Canvas.DrawText(FragGoal@TGRI.FragLimit$" | "$TimeLimit@TGRI.TimeLimit$":00");
        else
         Canvas.DrawText(FragGoal@TGRI.FragLimit);
      }
      else
      {
        if ( TGRI.TimeLimit > 0 )
		 Canvas.DrawText("Lives Limit"@TGRI.FragLimit$" | "$TimeLimit@TGRI.TimeLimit$":00");
        else
         Canvas.DrawText("Lives Limit"@TGRI.FragLimit);
      }
    }
}


/*
 * Returns time and date in a string.
 */
function string GetTimeStr()
{
  local string Mon, Day, Min;

  Min = string( PlayerOwner.Level.Minute );
  if( int( Min ) < 10 ) Min = "0" $ Min;

  switch( PlayerOwner.Level.month )
  {
    case  1: Mon = "Jan"; break;
    case  2: Mon = "Feb"; break;
    case  3: Mon = "Mar"; break;
    case  4: Mon = "Apr"; break;
    case  5: Mon = "May"; break;
    case  6: Mon = "Jun"; break;
    case  7: Mon = "Jul"; break;
    case  8: Mon = "Aug"; break;
    case  9: Mon = "Sep"; break;
    case 10: Mon = "Oct"; break;
    case 11: Mon = "Nov"; break;
    case 12: Mon = "Dec"; break;
  }

  switch( PlayerOwner.Level.dayOfWeek )
  {
    case 0: Day = "Sunday";    break;
    case 1: Day = "Monday";    break;
    case 2: Day = "Tuesday";   break;
    case 3: Day = "Wednesday"; break;
    case 4: Day = "Thursday";  break;
    case 5: Day = "Friday";    break;
    case 6: Day = "Saturday";  break;
  }

  return Day @ PlayerOwner.Level.Day @ Mon @ PlayerOwner.Level.Year $ "," @ PlayerOwner.Level.Hour $ ":" $ Min;
}

/*
 * Length of a meter drawing for a given number A out of B total.
 */
function int GetMeterLength( int A, int B )
{
  local int Result;

  if( B == 0 ) return 0;
  Result = ( A * MaxMeterWidth ) / B;

  if( Result > MaxMeterWidth ) return MaxMeterWidth;
  else return Result;
}

/*
 * Sort PlayerReplicationInfo's on score.
 */
function SortScores( int N )
{
  local byte i, j;
  local bool bSorted;
  local SmartDMPlayerReplicationInfo PlayerStats1, PlayerStats2;

  // Copy PRI array except for spectators.
  j = 0;
  for( i = 0; i < N; i++ )
  {
    if( pTGRI.priArray[i] == none ) break;
    if( pTGRI.priArray[i].bIsSpectator && !pTGRI.priArray[i].bWaitingPlayer ) continue;
    Ordered[j] = pTGRI.priArray[i];
    j++;
  }
  // Clear the remaining entries.
  for( i = j; i < N; i++ )
  {
    Ordered[i] = None;
  }

  for( i = 0; i < N; i++)
  {
    bSorted = True;
    for( j = 0; j < N - 1; j++)
    {
      if( Ordered[j+1] == none ) break;

      if( Ordered[j].Score < Ordered[j+1].Score )
      {
        SwapOrdered( j, j + 1 );
        bSorted = False;
      }
      else if( Ordered[j].Score == Ordered[j+1].Score )
      {
        PlayerStats1 = SDMGame.GetStatsByPRI( Ordered[j] );
        PlayerStats2 = SDMGame.GetStatsByPRI( Ordered[j+1] );
        if( PlayerStats1 != None && PlayerStats2 != None )
        {
          if( PlayerStats1.Frags < PlayerStats2.Frags )
          {
            SwapOrdered( j, j + 1 );
            bSorted = False;
          }
          else if( PlayerStats1.Frags == PlayerStats2.Frags )
          {
            if( Ordered[j].Deaths > Ordered[j+1].Deaths )
            {
              SwapOrdered( j, j + 1 );
              bSorted = False;
            }
          }
        }
      }
    }
    if( bSorted ) break;
  }
  LastSortTime = Level.TimeSeconds;
}

/*
 * Used for sorting.
 */
function SwapOrdered( byte A, byte B )
{
  local PlayerReplicationInfo Temp;
  Temp = Ordered[A];
  Ordered[A] = Ordered[B];
  Ordered[B] = Temp;
}

/*
 * Recalculate the totals for displaying meters on the scoreboards.
 * This way it doesn't get calculated every tick.
 */
function RecountNumbers()
{
  local byte ID, i;
  local SmartDMPlayerReplicationInfo PlayerStats;
  local string temp;

  MaxFrags = 0;
  MaxDeaths = 0;
  MaxSpreeEnd = 0;
  MaxSucide = 0;
  MaxSurv = 0;
  MaxNetSpeed=0;
  MaxPl=0;
  TotPlayers = 0;

  for( i = 0; i < 32; i++ )
  {
    if( Ordered[i] == None ) break;
    if( Ordered[i].bIsSpectator && !Ordered[i].bWaitingPlayer ) continue;

    ID = Ordered[i].PlayerID;

    PlayerStats = SDMGame.GetStatsByPRI( Ordered[i] );
    if( PlayerStats != None )
    {
      if( PlayerStats.Frags > MaxFrags ) MaxFrags = PlayerStats.Frags;
      if( PlayerStats.NetSpeed > MaxNetSpeed )MaxNetSpeed = PlayerStats.NetSpeed;
      temp =  SelElem(PlayerStats.PlayerStatsString ,13);
      if( int( temp ) > MaxSpreeEnd ) MaxSpreeEnd = int( temp );
      temp =  SelElem(PlayerStats.PlayerStatsString ,14);
      if( int( temp ) > MaxSucide ) MaxSucide = int( temp );
      temp = SelElem(PlayerStats.PlayerStatsString,20);
      if( int( temp ) > MaxSurv ) MaxSurv = int( temp );
      TotPlayers++;
    }
    if( Ordered[i].Deaths > MaxDeaths ) MaxDeaths = Ordered[i].Deaths;
    if( Ordered[i].PacketLoss > MaxPL ) MaxPL = Ordered[i].PacketLoss;
  }
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

defaultproperties
{
    DeathsText="Deaths"
    FragsText="Frags"
    SepText=" / "
    MoreText="More..."
    CreditText="[ SmartDM | The_Cowboy | D  ]"
    White=(R=255,G=255,B=255,A=0),
    Gray=(R=128,G=128,B=128,A=0),
    DarkGray=(R=32,G=32,B=32,A=0),
    Yellow=(R=255,G=255,B=0,A=0),
    RedColor=(R=255,G=0,B=0,A=0),
    BlueColor=(R=0,G=128,B=255,A=0),
    RedHeaderColor=(R=64,G=0,B=0,A=0),
    BlueHeaderColor=(R=0,G=32,B=64,A=0),
    StatsColor=(R=255,G=255,B=255,A=0),
    FooterColor=(R=255,G=255,B=255,A=0),
    HeaderColor=(R=255,G=255,B=0,A=0),
    TinyInfoColor=(R=128,G=128,B=128,A=0),
    HeaderTinyInfoColor=(R=192,G=192,B=192,A=0),
    bShowNetSpeedAndPL=True
}
