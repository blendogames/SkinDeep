#include "sys/platform.h"

#include "Game_local.h"
#include "sb_record.h"
#include "sb_cycle.h"

CLASS_DECLARATION( idEntity, idStBrielleCycleDirector )
END_CLASS

idStBrielleCycleDirector::idStBrielleCycleDirector() {
	lastCycle = -1;
	nextCheckTime = 0;
	checkIntervalMS = 250;
	debug = false;
}

void idStBrielleCycleDirector::Spawn( void ) {
	idStBrielleRecord::EnsureDefaults();

	checkIntervalMS = spawnArgs.GetInt( "check_interval_ms", "250" );
	if ( checkIntervalMS < 50 ) {
		checkIntervalMS = 50;
	}

	debug = spawnArgs.GetBool( "cycle_debug", "0" );

	if ( spawnArgs.GetBool( "fire_current_on_spawn", "1" ) ) {
		lastCycle = -1;
	} else {
		lastCycle = static_cast<int>( idStBrielleRecord::GetCycle() );
	}

	nextCheckTime = gameLocal.time;
	BecomeActive( TH_THINK );
}

void idStBrielleCycleDirector::Think( void ) {
	if ( gameLocal.time < nextCheckTime ) {
		return;
	}

	nextCheckTime = gameLocal.time + checkIntervalMS;

	const int cycle = static_cast<int>( idStBrielleRecord::GetCycle() );
	if ( cycle == lastCycle ) {
		return;
	}

	if ( debug ) {
		gameLocal.Printf( "[ST. BRIELLE CYCLE] %d -> %d (%s)\n",
			lastCycle, cycle, GetCyclePrefix( cycle ) );
	}

	lastCycle = cycle;
	ActivateCycleTargets( cycle );
}

const char *idStBrielleCycleDirector::GetCyclePrefix( int cycle ) const {
	switch ( cycle ) {
		case idStBrielleRecord::CYCLE_INK:
			return "ink";
		case idStBrielleRecord::CYCLE_BRASS:
			return "brass";
		case idStBrielleRecord::CYCLE_CODE:
			return "code";
		case idStBrielleRecord::CYCLE_WATER:
		default:
			return "water";
	}
}

void idStBrielleCycleDirector::ActivateCycleTargets( int cycle ) {
	const idStr prefix = va( "%s_target", GetCyclePrefix( cycle ) );
	const idKeyValue *kv = spawnArgs.MatchPrefix( prefix.c_str() );

	while ( kv ) {
		const char *entityName = kv->GetValue().c_str();
		idEntity *ent = gameLocal.FindEntity( entityName );

		if ( !ent ) {
			gameLocal.Warning(
				"idStBrielleCycleDirector '%s' could not find cycle target '%s'.",
				GetName(), entityName
			);
		} else if ( ent->RespondsTo( EV_Activate ) || ent->HasSignal( SIG_TRIGGER ) ) {
			ent->Signal( SIG_TRIGGER );
			ent->ProcessEvent( &EV_Activate, this );
		}

		kv = spawnArgs.MatchPrefix( prefix.c_str(), kv );
	}
}

void idStBrielleCycleDirector::Save( idSaveGame *savefile ) const {
	savefile->WriteInt( lastCycle );
	savefile->WriteInt( nextCheckTime );
	savefile->WriteInt( checkIntervalMS );
	savefile->WriteBool( debug );
}

void idStBrielleCycleDirector::Restore( idRestoreGame *savefile ) {
	savefile->ReadInt( lastCycle );
	savefile->ReadInt( nextCheckTime );
	savefile->ReadInt( checkIntervalMS );
	savefile->ReadBool( debug );

	BecomeActive( TH_THINK );
}
