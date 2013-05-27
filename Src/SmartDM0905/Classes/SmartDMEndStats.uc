class SmartDMEndStats expands EndStats config( user );

replication
{
  reliable if( Role == ROLE_Authority )
     MostFrags, MostHeadShots, MostSurvivability, MostSprees, MostMultiLevelKills;
}

struct BestSomething {
   var int Count;
   var string PlayerName;
   var string MapName;
   var string RecordDate;
};

//var globalconfig BestSomething MostPoints;
var globalconfig BestSomething MostFrags;
var globalconfig BestSomething MostHeadShots;
var globalconfig BestSomething MostSurvivability;
var globalconfig BestSomething MostSprees;
var globalconfig BestSomething MostMultiLevelKills;

defaultproperties
{
    bAlwaysRelevant=True
}
