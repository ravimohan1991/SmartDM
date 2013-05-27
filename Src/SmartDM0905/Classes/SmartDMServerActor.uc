class SmartDMServerActor expands Actor;

function PostBeginPlay()
{
  if( DeathMatchPlus( Level.Game ) != none && !Level.Game.bTeamGame )
  {
    Log( "ServerActor, Spawning and adding Mutator...", 'SmartDM' );
    Level.Game.BaseMutator.AddMutator( Level.Game.Spawn( class'SmartDM' ) );
  }
  Destroy();
}

defaultproperties
{
    bHidden=True
}
