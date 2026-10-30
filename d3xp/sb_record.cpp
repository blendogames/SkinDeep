#include "sys/platform.h"

#include "Game_local.h"
#include "Player.h"
#include "sb_record.h"

static const char *SB_KEY_CAMPAIGN_VERSION = "sb_campaign_version";
static const char *SB_KEY_CYCLE = "sb_cycle";
static const char *SB_KEY_AWARENESS = "sb_awareness";
static const char *SB_KEY_RECORD_STABILITY = "sb_record_stability";

void idStBrielleRecord::EnsureDefaults() {
	if ( !Has( SB_KEY_CAMPAIGN_VERSION ) ) {
		SetInt( SB_KEY_CAMPAIGN_VERSION, CAMPAIGN_VERSION );
	}
	if ( !Has( SB_KEY_CYCLE ) ) {
		SetInt( SB_KEY_CYCLE, CYCLE_WATER );
	}
	if ( !Has( SB_KEY_AWARENESS ) ) {
		SetInt( SB_KEY_AWARENESS, 0 );
	}
	if ( !Has( SB_KEY_RECORD_STABILITY ) ) {
		SetInt( SB_KEY_RECORD_STABILITY, 100 );
	}
}

bool idStBrielleRecord::Has( const char *key ) {
	return key && key[0] && gameLocal.persistentLevelInfo.FindKey( key ) != NULL;
}

idStr idStBrielleRecord::GetString( const char *key, const char *defaultValue ) {
	if ( !key || !key[0] ) {
		return defaultValue ? defaultValue : "";
	}
	return gameLocal.persistentLevelInfo.GetString( key, defaultValue ? defaultValue : "" );
}

int idStBrielleRecord::GetInt( const char *key, int defaultValue ) {
	if ( !key || !key[0] ) {
		return defaultValue;
	}
	idStr fallback = va( "%d", defaultValue );
	return gameLocal.persistentLevelInfo.GetInt( key, fallback.c_str() );
}

bool idStBrielleRecord::GetBool( const char *key, bool defaultValue ) {
	if ( !key || !key[0] ) {
		return defaultValue;
	}
	return gameLocal.persistentLevelInfo.GetBool( key, defaultValue ? "1" : "0" );
}

void idStBrielleRecord::SetString( const char *key, const char *value ) {
	if ( !key || !key[0] ) {
		gameLocal.Warning( "StBrielleRecord: refusing to set an empty key." );
		return;
	}

	if ( idStr::Icmpn( key, "sb_", 3 ) != 0 ) {
		gameLocal.Warning( "StBrielleRecord: key '%s' does not use the recommended sb_ prefix.", key );
	}

	gameLocal.persistentLevelInfo.Set( key, value ? value : "" );
}

void idStBrielleRecord::SetInt( const char *key, int value ) {
	if ( !key || !key[0] ) {
		gameLocal.Warning( "StBrielleRecord: refusing to set an empty key." );
		return;
	}
	gameLocal.persistentLevelInfo.SetInt( key, value );
}

void idStBrielleRecord::SetBool( const char *key, bool value ) {
	if ( !key || !key[0] ) {
		gameLocal.Warning( "StBrielleRecord: refusing to set an empty key." );
		return;
	}
	gameLocal.persistentLevelInfo.SetBool( key, value );
}

int idStBrielleRecord::AddInt( const char *key, int delta ) {
	const int newValue = GetInt( key, 0 ) + delta;
	SetInt( key, newValue );
	return newValue;
}

bool idStBrielleRecord::ToggleBool( const char *key ) {
	const bool newValue = !GetBool( key, false );
	SetBool( key, newValue );
	return newValue;
}

void idStBrielleRecord::Clear( const char *key ) {
	if ( !key || !key[0] ) {
		return;
	}
	gameLocal.persistentLevelInfo.Delete( key );
}

idStBrielleRecord::cycle_t idStBrielleRecord::GetCycle() {
	int value = GetInt( SB_KEY_CYCLE, CYCLE_WATER );
	if ( value < CYCLE_INK ) {
		value = CYCLE_INK;
	} else if ( value > CYCLE_CODE ) {
		value = CYCLE_CODE;
	}
	return static_cast<cycle_t>( value );
}

void idStBrielleRecord::SetCycle( cycle_t cycle ) {
	int value = static_cast<int>( cycle );
	if ( value < CYCLE_INK ) {
		value = CYCLE_INK;
	} else if ( value > CYCLE_CODE ) {
		value = CYCLE_CODE;
	}
	SetInt( SB_KEY_CYCLE, value );
}

int idStBrielleRecord::GetAwareness() {
	return GetInt( SB_KEY_AWARENESS, 0 );
}

int idStBrielleRecord::AddAwareness( int amount ) {
	int value = GetAwareness() + amount;
	if ( value < 0 ) {
		value = 0;
	} else if ( value > 100 ) {
		value = 100;
	}
	SetInt( SB_KEY_AWARENESS, value );
	return value;
}

idStBrielleRecord::awarenessTier_t idStBrielleRecord::GetAwarenessTier() {
	return GetAwarenessTierForValue( GetAwareness() );
}

idStBrielleRecord::awarenessTier_t idStBrielleRecord::GetAwarenessTierForValue( int value ) {
	if ( value >= 50 ) {
		return AWARENESS_RUPTURE;
	}
	if ( value >= 25 ) {
		return AWARENESS_CORRECTING;
	}
	if ( value >= 10 ) {
		return AWARENESS_OBSERVING;
	}
	if ( value >= 1 ) {
		return AWARENESS_NOTICED;
	}
	return AWARENESS_DORMANT;
}

const char *idStBrielleRecord::GetAwarenessTierName( awarenessTier_t tier ) {
	switch ( tier ) {
		case AWARENESS_NOTICED:
			return "noticed";
		case AWARENESS_OBSERVING:
			return "observing";
		case AWARENESS_CORRECTING:
			return "correcting";
		case AWARENESS_RUPTURE:
			return "rupture";
		case AWARENESS_DORMANT:
		default:
			return "dormant";
	}
}

CLASS_DECLARATION( idTarget, idTarget_StBrielleRecord )
	EVENT( EV_Activate, idTarget_StBrielleRecord::Event_Activate )
END_CLASS

void idTarget_StBrielleRecord::Spawn( void ) {
	idStBrielleRecord::EnsureDefaults();
}

void idTarget_StBrielleRecord::Event_Activate( idEntity *activator ) {
	const char *key = spawnArgs.GetString( "record_key", "" );
	const char *mode = spawnArgs.GetString( "record_mode", "set" );
	const char *value = spawnArgs.GetString( "record_value", "1" );

	if ( !key || !key[0] ) {
		gameLocal.Warning( "idTarget_StBrielleRecord '%s' has no record_key.", GetName() );
		return;
	}

	if ( idStr::Icmp( mode, "set" ) == 0 ) {
		idStBrielleRecord::SetString( key, value );
	} else if ( idStr::Icmp( mode, "add" ) == 0 ) {
		idStBrielleRecord::AddInt( key, atoi( value ) );
	} else if ( idStr::Icmp( mode, "toggle" ) == 0 ) {
		idStBrielleRecord::ToggleBool( key );
	} else if ( idStr::Icmp( mode, "clear" ) == 0 ) {
		idStBrielleRecord::Clear( key );
	} else {
		gameLocal.Warning( "idTarget_StBrielleRecord '%s' has unknown record_mode '%s'.", GetName(), mode );
		return;
	}

	if ( spawnArgs.GetBool( "record_debug", "0" ) ) {
		gameLocal.Printf( "[ST. BRIELLE RECORD] %s (%s) => '%s'\n",
			key, mode, idStBrielleRecord::GetString( key, "<missing>" ).c_str() );
	}

	ActivateTargets( activator );

	if ( spawnArgs.GetBool( "record_once", "1" ) ) {
		PostEventMS( &EV_Remove, 0 );
	}
}

CLASS_DECLARATION( idTarget, idTarget_StBrielleRecordCheck )
	EVENT( EV_Activate, idTarget_StBrielleRecordCheck::Event_Activate )
END_CLASS

void idTarget_StBrielleRecordCheck::Spawn( void ) {
	idStBrielleRecord::EnsureDefaults();
}

bool idTarget_StBrielleRecordCheck::EvaluateCondition( void ) const {
	const char *key = spawnArgs.GetString( "record_key", "" );
	const char *compare = spawnArgs.GetString( "record_compare", "equals" );
	const char *expected = spawnArgs.GetString( "record_value", "1" );

	if ( !key || !key[0] ) {
		return false;
	}

	if ( idStr::Icmp( compare, "exists" ) == 0 ) {
		return idStBrielleRecord::Has( key );
	}
	if ( idStr::Icmp( compare, "missing" ) == 0 ) {
		return !idStBrielleRecord::Has( key );
	}
	if ( idStr::Icmp( compare, "true" ) == 0 ) {
		return idStBrielleRecord::GetBool( key, false );
	}
	if ( idStr::Icmp( compare, "false" ) == 0 ) {
		return !idStBrielleRecord::GetBool( key, false );
	}

	const idStr actual = idStBrielleRecord::GetString( key, "" );

	if ( idStr::Icmp( compare, "equals" ) == 0 ) {
		return idStr::Icmp( actual.c_str(), expected ) == 0;
	}
	if ( idStr::Icmp( compare, "not_equals" ) == 0 ) {
		return idStr::Icmp( actual.c_str(), expected ) != 0;
	}

	const int actualInt = atoi( actual.c_str() );
	const int expectedInt = atoi( expected );

	if ( idStr::Icmp( compare, "gt" ) == 0 ) {
		return actualInt > expectedInt;
	}
	if ( idStr::Icmp( compare, "gte" ) == 0 ) {
		return actualInt >= expectedInt;
	}
	if ( idStr::Icmp( compare, "lt" ) == 0 ) {
		return actualInt < expectedInt;
	}
	if ( idStr::Icmp( compare, "lte" ) == 0 ) {
		return actualInt <= expectedInt;
	}

	gameLocal.Warning( "idTarget_StBrielleRecordCheck '%s' has unknown record_compare '%s'.", GetName(), compare );
	return false;
}

void idTarget_StBrielleRecordCheck::Event_Activate( idEntity *activator ) {
	const bool passed = EvaluateCondition();

	if ( spawnArgs.GetBool( "record_debug", "0" ) ) {
		gameLocal.Printf( "[ST. BRIELLE RECORD CHECK] %s => %s\n",
			spawnArgs.GetString( "record_key", "" ), passed ? "TRUE" : "FALSE" );
	}

	if ( !passed ) {
		// Keep rejection feedback on the same synchronous path as the check.
		// Do not use a target* key here: FindTargets would also fire it on success.
		const char *failureName = spawnArgs.GetString( "record_fail_target", "" );
		if ( failureName[0] ) {
			idEntity *failure = gameLocal.FindEntity( failureName );
			if ( failure && failure != this ) {
				failure->ProcessEvent( &EV_Activate, activator );
			} else {
				gameLocal.Warning( "StBrielleRecordCheck '%s': invalid failure target '%s'.", GetName(), failureName );
			}
		}
		return;
	}

	ActivateTargets( activator );

	if ( spawnArgs.GetBool( "record_once", "0" ) ) {
		PostEventMS( &EV_Remove, 0 );
	}
}


/*
===============================================================================

idTarget_StBrielleNotice

Small diegetic civic/document card drawn through the St. Brielle HUD.

===============================================================================
*/

const idEventDef EV_StBrielleNoticeClear( "<stBrielleNoticeClear>" );

static idStr SB_ExpandNoticeTokens( const char *source, idPlayer *player ) {
	idStr out = source ? source : "";

	idStr playerName = "VISITOR";
	if ( player ) {
		const idDict *info = gameLocal.GetUserInfo( player->entityNumber );
		if ( info ) {
			const char *configuredName = info->GetString( "ui_name", "" );
			if ( configuredName && configuredName[0] ) {
				playerName = configuredName;
			}
		}
	}

	out.Replace( "$PLAYER", playerName.c_str() );
	return out;
}

CLASS_DECLARATION( idTarget, idTarget_StBrielleNotice )
	EVENT( EV_Activate, idTarget_StBrielleNotice::Event_Activate )
	EVENT( EV_StBrielleNoticeClear, idTarget_StBrielleNotice::Event_Clear )
END_CLASS

void idTarget_StBrielleNotice::Spawn( void ) {
}

void idTarget_StBrielleNotice::Event_Activate( idEntity *activator ) {
	idPlayer *player = gameLocal.GetLocalPlayer();
	if ( !player || !player->hud ) {
		return;
	}

	player->hud->SetStateString( "sb_notice_kicker", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_kicker", "" ), player ).c_str() );
	player->hud->SetStateString( "sb_notice_title", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_title", "" ), player ).c_str() );
	player->hud->SetStateString( "sb_notice_line1", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_line1", "" ), player ).c_str() );
	player->hud->SetStateString( "sb_notice_line2", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_line2", "" ), player ).c_str() );
	player->hud->SetStateString( "sb_notice_line3", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_line3", "" ), player ).c_str() );
	player->hud->SetStateString( "sb_notice_line4", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_line4", "" ), player ).c_str() );
	player->hud->SetStateString( "sb_notice_footer", SB_ExpandNoticeTokens( spawnArgs.GetString( "notice_footer", "" ), player ).c_str() );
	player->hud->SetStateBool( "sb_notice_visible", true );
	// A previously opened document must not dismiss a newer document when its
	// own timeout expires. HUD state is already serialized with the player.
	player->hud->SetStateString( "sb_notice_owner", GetName() );
	player->hud->StateChanged( gameLocal.time );

	CancelEvents( &EV_StBrielleNoticeClear );
	const float duration = idMath::ClampFloat( 1.0f, 20.0f, spawnArgs.GetFloat( "notice_duration", "5.0" ) );
	PostEventMS( &EV_StBrielleNoticeClear, SEC2MS( duration ) );

	ActivateTargets( activator );
}

void idTarget_StBrielleNotice::Event_Clear( void ) {
	idPlayer *player = gameLocal.GetLocalPlayer();
	if ( player && player->hud &&
		idStr::Icmp( player->hud->GetStateString( "sb_notice_owner", "" ), GetName() ) == 0 ) {
		player->hud->SetStateBool( "sb_notice_visible", false );
		player->hud->StateChanged( gameLocal.time );
	}
}
