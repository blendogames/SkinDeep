#include "sys/platform.h"

#include "Game_local.h"
#include "Player.h"
#include "sb_record.h"
#include "sb_awareness.h"

CLASS_DECLARATION( idEntity, idStBrielleAwarenessDirector )
END_CLASS

idStBrielleAwarenessDirector::idStBrielleAwarenessDirector() {
	lastTier = -1;
	nextCheckTime = 0;
	checkIntervalMS = 250;
	debug = false;

	annexLedgerWasInside = false;
	annexCorrectionApplied = false;
	annexPhotoConfigured = false;
	annexPhonePulseBright = false;
	annexPhoneNextPulseTime = 0;

	annexFiledPersonActive = false;
	annexFiledPersonNextMoveTime = 0;
	annexFiledPersonObservedSince = 0;
}

void idStBrielleAwarenessDirector::Spawn( void ) {
	idStBrielleRecord::EnsureDefaults();

	checkIntervalMS = spawnArgs.GetInt( "check_interval_ms", "250" );
	if ( checkIntervalMS < 50 ) {
		checkIntervalMS = 50;
	}

	debug = spawnArgs.GetBool( "awareness_debug", "0" );

	if ( spawnArgs.GetBool( "fire_current_on_spawn", "1" ) ) {
		lastTier = -1;
	} else {
		lastTier = static_cast<int>( idStBrielleRecord::GetAwarenessTier() );
	}

	annexLedgerWasInside = false;
	annexCorrectionApplied = false;
	annexPhotoConfigured = false;
	annexPhonePulseBright = false;
	annexPhoneNextPulseTime = gameLocal.time;

	annexFiledPersonActive = false;
	annexFiledPersonNextMoveTime = gameLocal.time;
	annexFiledPersonObservedSince = 0;

	nextCheckTime = gameLocal.time;
	BecomeActive( TH_THINK );
}

void idStBrielleAwarenessDirector::Think( void ) {
	if ( gameLocal.time < nextCheckTime ) {
		return;
	}

	nextCheckTime = gameLocal.time + checkIntervalMS;

	// Map-specific presentation remains invisible to the player. The same
	// director handles the Annex sequence and the tiny post-Annex city handoff.
	UpdateAnnexSequence();
	ConfigureCityGlimpse();
	UpdateCityInvestigation();

	const int tier = static_cast<int>( idStBrielleRecord::GetAwarenessTier() );
	if ( tier == lastTier ) {
		return;
	}

	if ( debug ) {
		gameLocal.Printf(
			"[ST. BRIELLE AWARENESS] %s -> %s (value %d)\n",
			lastTier < 0 ? "uninitialized" :
				idStBrielleRecord::GetAwarenessTierName(
					static_cast<idStBrielleRecord::awarenessTier_t>( lastTier ) ),
			idStBrielleRecord::GetAwarenessTierName(
				static_cast<idStBrielleRecord::awarenessTier_t>( tier ) ),
			idStBrielleRecord::GetAwareness()
		);
	}

	lastTier = tier;
	ActivateTierTargets( tier );
}

void idStBrielleAwarenessDirector::ActivateTierTargets( int tier ) {
	const idStr prefix = va( "tier%d_target", tier );
	const idKeyValue *kv = spawnArgs.MatchPrefix( prefix.c_str() );

	while ( kv ) {
		const char *entityName = kv->GetValue().c_str();
		idEntity *ent = gameLocal.FindEntity( entityName );

		if ( !ent ) {
			gameLocal.Warning(
				"idStBrielleAwarenessDirector '%s' could not find tier target '%s'.",
				GetName(), entityName
			);
		} else if ( ent->RespondsTo( EV_Activate ) || ent->HasSignal( SIG_TRIGGER ) ) {
			ent->Signal( SIG_TRIGGER );
			ent->ProcessEvent( &EV_Activate, this );
		}

		kv = spawnArgs.MatchPrefix( prefix.c_str(), kv );
	}
}

void idStBrielleAwarenessDirector::ConfigureNotice( idEntity *notice,
	const char *kicker, const char *title,
	const char *line1, const char *line2, const char *line3, const char *line4,
	const char *footer, const char *duration ) {
	if ( !notice ) {
		return;
	}

	notice->spawnArgs.Set( "notice_kicker", kicker ? kicker : "" );
	notice->spawnArgs.Set( "notice_title", title ? title : "" );
	notice->spawnArgs.Set( "notice_line1", line1 ? line1 : "" );
	notice->spawnArgs.Set( "notice_line2", line2 ? line2 : "" );
	notice->spawnArgs.Set( "notice_line3", line3 ? line3 : "" );
	notice->spawnArgs.Set( "notice_line4", line4 ? line4 : "" );
	notice->spawnArgs.Set( "notice_footer", footer ? footer : "" );
	notice->spawnArgs.Set( "notice_duration", duration ? duration : "6.0" );
}

void idStBrielleAwarenessDirector::ConfigureInteractable( idEntity *ent,
	const char *newDisplayName, const char *action, const char *targetName, bool useOnce ) {
	if ( !ent ) {
		return;
	}

	ent->spawnArgs.Set( "displayname", newDisplayName ? newDisplayName : "" );
	ent->spawnArgs.Set( "stbrielle_action", action ? action : "INTERACT" );
	ent->spawnArgs.Set( "stbrielle_interact", "1" );
	ent->spawnArgs.Set( "stbrielle_activate_targets", "1" );
	ent->spawnArgs.Set( "stbrielle_use_once", useOnce ? "1" : "0" );
	ent->spawnArgs.Set( "stbrielle_interact_debug", "1" );
	ent->spawnArgs.Set( "target", targetName ? targetName : "" );
	ent->displayName = newDisplayName ? newDisplayName : "";

	for ( int i = 1; i < 16; ++i ) {
		ent->spawnArgs.Delete( va( "target%d", i ) );
	}
	ent->targets.Clear();

	if ( !idStr::Icmp( ent->GetName(), "annex_notice_board" ) ) {
		ent->GetPhysics()->SetContents( CONTENTS_SOLID );
	}

	ent->FindTargets();
}

void idStBrielleAwarenessDirector::ConfigureAnnexPhoto( bool corrected ) {
	idEntity *photo = gameLocal.FindEntity( "annex_notice_board" );
	idEntity *notice = gameLocal.FindEntity( "annex_workorder_notice" );
	if ( !photo || !notice ) {
		return;
	}

	ConfigureInteractable( photo, "MUNICIPAL ANNEX STAFF PHOTOGRAPH", "INSPECT", "annex_workorder_notice", false );

	if ( corrected ) {
		ConfigureNotice(
			notice,
			"OFFICE OF PERPETUAL RECORD / PERSONNEL",
			"MUNICIPAL ANNEX STAFF / 1987",
			"IMAGE COUNT: SIX",
			"UNLISTED INDIVIDUAL: $PLAYER",
			"ROOM 214: ASSIGNED / PRESENT",
			"APPOINTMENT TIME: 23:44",
			"CITY COPY / PHOTOGRAPH 6-B / CORRECTED",
			"8.0"
		);
	} else {
		ConfigureNotice(
			notice,
			"OFFICE OF PERPETUAL RECORD / PERSONNEL",
			"MUNICIPAL ANNEX STAFF / 1987",
			"IMAGE COUNT: FIVE",
			"ARCHIVES / CONTINUITY / BUILDING SERVICES",
			"ROOM 214: NO ASSIGNMENT",
			"NEGATIVE FILE: VERIFIED",
			"CITY COPY / PHOTOGRAPH 6-B",
			"7.0"
		);
	}

	annexPhotoConfigured = true;
}

void idStBrielleAwarenessDirector::ConfigureAnnexPhone( void ) {
	idEntity *phoneSurface = gameLocal.FindEntity( "annex_reception_countertop" );
	idEntity *notice = gameLocal.FindEntity( "annex_breaker_notice" );
	if ( !phoneSurface || !notice ) {
		return;
	}

	const bool phoneAnswered = idStBrielleRecord::GetBool( "sb_annex_phone_answered", false );
	phoneSurface->spawnArgs.Set( "snd_annex_phone_ring", "snd_stbrielle_annex_phone_ring" );

	if ( phoneAnswered ) {
		phoneSurface->StopSound( SND_CHANNEL_BODY, false );
		phoneSurface->spawnArgs.Set( "stbrielle_interact", "0" );
		return;
	}

	ConfigureInteractable( phoneSurface, "RECEPTION TELEPHONE", "ANSWER", "annex_breaker_notice", true );
	ConfigureNotice(
		notice,
		"MUNICIPAL VOICE SERVICE / INTERNAL",
		"CALL CONNECTED / LINE 04-214",
		"CALLER: ROOM 214",
		"VOICE MATCH: $PLAYER",
		"PLACED: 23:44 / RECEIVED: 23:44",
		"TRANSCRIPT: YOU LEFT BEFORE YOU ARRIVED.",
		"LINE PHYSICALLY DISCONNECTED / 1971",
		"8.0"
	);

	phoneSurface->StartSound( "snd_annex_phone_ring", SND_CHANNEL_BODY, 0, false, NULL );
}

void idStBrielleAwarenessDirector::ConfigureAnnexExit( bool reviewed ) {
	idEntity *exitTerminal = gameLocal.FindEntity( "annex_exit_terminal" );
	idEntity *notice = gameLocal.FindEntity( "annex_exit_complete_notice" );
	if ( !exitTerminal || !notice ) {
		return;
	}

	if ( idStBrielleRecord::GetBool( "sb_annex_complete", false ) ) {
		ConfigureInteractable( exitTerminal, "CONTINUITY EXIT / FILED", "FILED", "", true );
		exitTerminal->spawnArgs.Set( "stbrielle_interact", "0" );
		exitTerminal->targets.Clear();
		ConfigureNotice(
			notice,
			"MUNICIPAL CONTINUITY / EXIT CONTROL",
			"RETURN FILED",
			"NAME: $PLAYER",
			"PRIOR DEPARTURE: 23:44",
			"RETURN: 23:44",
			"CONTINUITY HOLD: RELEASED",
			"YOU MAY PROCEED",
			"8.0"
		);
		return;
	}

	if ( reviewed ) {
		ConfigureInteractable( exitTerminal, "CONTINUITY EXIT", "RETURN", "annex_exit_ready_check", true );
		ConfigureNotice(
			notice,
			"MUNICIPAL CONTINUITY / EXIT CONTROL",
			"DEPARTURE CORRECTION ACCEPTED",
			"NAME: $PLAYER",
			"PRIOR DEPARTURE: 23:44",
			"CURRENT STATUS: PRESENT",
			"ACTION: RETURN TO FILE",
			"ONE RETURN AUTHORIZED",
			"8.0"
		);
	} else {
		ConfigureInteractable( exitTerminal, "CONTINUITY EXIT / CLOSED", "REVIEW", "annex_exit_complete_notice", true );
		ConfigureNotice(
			notice,
			"MUNICIPAL CONTINUITY / EXIT CONTROL",
			"DEPARTURE ALREADY FILED",
			"NAME: $PLAYER",
			"DEPARTURE: 23:44",
			"CURRENT STATUS: PRESENT",
			"SECOND DEPARTURE: NOT PERMITTED",
			"YOU MAY NOT LEAVE TWICE",
			"8.0"
		);
	}
}

void idStBrielleAwarenessDirector::ConfigureAnnexDeparture( idPlayer *player ) {
	idEntity *exitTerminal = gameLocal.FindEntity( "annex_exit_terminal" );
	idEntity *notice = gameLocal.FindEntity( "annex_exit_complete_notice" );
	if ( !exitTerminal || !notice || !player ) {
		return;
	}

	if ( idStBrielleRecord::GetBool( "sb_annex_departed", false ) ) {
		gameLocal.sessionCommand = "map sb01_cityglimpse";
		return;
	}

	const char *action = exitTerminal->spawnArgs.GetString( "stbrielle_action", "" );
	const bool interactive = exitTerminal->spawnArgs.GetBool( "stbrielle_interact", "0" );

	if ( idStr::Icmp( action, "LEAVE" ) != 0 ) {
		ConfigureInteractable(
			exitTerminal,
			"MUNICIPAL ANNEX / EXTERIOR RELEASED",
			"LEAVE",
			"annex_exit_complete_notice",
			true
		);
		ConfigureNotice(
			notice,
			"MUNICIPAL CONTINUITY / EXIT CONTROL",
			"EXTERIOR RELEASED",
			"ANNEX FILE: CLOSED",
			"PERSONNEL DUPLICATE: WITHDRAWN",
			"DEPARTURE STATUS: ACCEPTED",
			"PUBLIC WAY ACCESS: RESTORED",
			"CIVITAS INCOMPLETA / 23:44",
			"7.0"
		);
		return;
	}

	// The interaction system disables a successful one-use frob. That becomes
	// the authoritative signal that the player actually chose to leave.
	if ( !interactive ) {
		idStBrielleRecord::SetBool( "sb_annex_departed", true );
		idStBrielleRecord::SetBool( "sb_cityglimpse_unlocked", true );
		gameLocal.sessionCommand = "map sb01_cityglimpse";

		if ( debug ) {
			gameLocal.Printf( "[ST. BRIELLE ANNEX] exterior released; loading city glimpse\n" );
		}
	}
}

void idStBrielleAwarenessDirector::ConfigureCityGlimpse( void ) {
	idEntity *notice = gameLocal.FindEntity( "cityglimpse_arrival_notice" );
	if ( !notice ) {
		return;
	}

	if ( notice->spawnArgs.GetBool( "stbrielle_runtime_configured", "0" ) ) {
		return;
	}

	const bool contact = idStBrielleRecord::GetBool( "sb_annex_filed_person_contact", false );
	const int contactCount = idStBrielleRecord::GetInt( "sb_annex_filed_person_contact_count", 0 );
	const int stability = idStBrielleRecord::GetInt( "sb_record_stability", 100 );

	idStr personnelLine;
	if ( contact ) {
		personnelLine = va( "PERSONNEL CONTACT EXCEPTION: RETAINED / %d", contactCount );
	} else {
		personnelLine = "PERSONNEL DUPLICATE: WITHDRAWN";
	}
	idStr stabilityLine = va( "RECORD STABILITY: %d%%", stability );

	ConfigureNotice(
		notice,
		"CITY OF ST. BRIELLE / PUBLIC WAY",
		"MUNICIPAL ANNEX / DEPARTURE RECEIVED",
		"ANNEX FILE: CLOSED",
		personnelLine.c_str(),
		stabilityLine.c_str(),
		"CONTINUITY STATUS: ACTIVE",
		"CIVITAS INCOMPLETA / WATER CYCLE / 23:44",
		"9.0"
	);
	notice->spawnArgs.Set( "stbrielle_runtime_configured", "1" );

	idEntity *recordLight = gameLocal.FindEntity( "cityglimpse_record_light" );
	if ( recordLight ) {
		if ( contact ) {
			recordLight->SetColor( 0.48f, 0.045f, 0.065f );
		} else if ( stability < 85 ) {
			recordLight->SetColor( 0.36f, 0.20f, 0.08f );
		} else {
			recordLight->SetColor( 0.14f, 0.46f, 0.38f );
		}
	}
}

void idStBrielleAwarenessDirector::UpdateCityInvestigation( void ) {
	// Progression is authored in the map's Record targets. This method only
	// presents it, so restoring a save or revisiting cannot re-award an outcome.
	idEntity *dispatch = gameLocal.FindEntity( "city_dispatch" );
	idPlayer *player = gameLocal.GetLocalPlayer();
	if ( !dispatch ) {
		if ( player && player->hud && player->hud->GetStateBool( "sb_assignment_visible" ) ) {
			player->hud->SetStateBool( "sb_assignment_visible", false );
			player->hud->StateChanged( gameLocal.time );
		}
		return;
	}

	const bool rosterRead = idStBrielleRecord::GetBool( "sb_city_roster_read", false );
	const bool testimonyRead = idStBrielleRecord::GetBool( "sb_city_testimony_read", false );
	const int decision = idStBrielleRecord::GetInt( "sb_city_certification", 0 );
	const bool dispatched = idStBrielleRecord::GetBool( "sb_city_dispatch_received", false );
	const bool ready = rosterRead && testimonyRead;

	const char *objective;
	if ( dispatched ) {
		objective = "FILE CLOSED / MERCURIA ASSIGNMENT RECEIVED";
	} else if ( decision != 0 ) {
		objective = "COLLECT YOUR ASSIGNMENT / CENTRAL DISPATCH";
	} else if ( ready ) {
		objective = "EAST DESK / CHOOSE ONE SEAL / FILING IS FINAL";
	} else if ( rosterRead ) {
		objective = "READ THE WITNESS SLIP / SOUTH SIDE";
	} else if ( testimonyRead ) {
		objective = "READ THE CITY ROSTER / NORTH SIDE";
	} else {
		objective = "COMPARE CITY ROSTER AND WITNESS SLIP";
	}

	if ( player && player->hud ) {
		player->hud->SetStateBool( "sb_assignment_visible", true );
		player->hud->SetStateString( "sb_assignment_text", objective );
		player->hud->StateChanged( gameLocal.time );
	}

	// Keep both plates usable for reviewing the filed decision. Map-side guards
	// reject early or repeated certification, including between director ticks.
	const char *action = decision != 0 ? "REVIEW" : ( ready ? "CERTIFY" : "CHECK" );
	idEntity *official = gameLocal.FindEntity( "city_certify_official" );
	idEntity *witness = gameLocal.FindEntity( "city_certify_witness" );
	if ( official ) {
		official->spawnArgs.Set( "stbrielle_action", action );
	}
	if ( witness ) {
		witness->spawnArgs.Set( "stbrielle_action", action );
	}
	dispatch->spawnArgs.Set( "stbrielle_action", dispatched ? "REVIEW" : ( decision != 0 ? "COLLECT" : "CHECK" ) );

	// The original evidence remains readable; the roster adds the filed result.
	idEntity *roster = gameLocal.FindEntity( "city_roster_notice" );
	if ( roster ) {
		roster->spawnArgs.Set( "notice_line4", decision == 2 ?
			"AMENDMENT: SECOND DEPARTURE RETAINED" : ( decision == 1 ?
			"CERTIFIED: SECOND DEPARTURE STRUCK" : "SECOND DEPARTURE: NO SUCH PERSON" ) );
	}

	idEntity *light = gameLocal.FindEntity( "city_certification_light" );
	if ( light ) {
		if ( decision == 1 ) {
			light->SetColor( 0.16f, 0.50f, 0.36f );
		} else if ( decision == 2 ) {
			light->SetColor( 0.62f, 0.12f, 0.08f );
		} else if ( ready ) {
			light->SetColor( 0.70f, 0.48f, 0.20f );
		} else {
			light->SetColor( 0.12f, 0.18f, 0.25f );
		}
	}

	// The empty pavement acquires a second personnel image only if the player
	// preserves the witness account. This is a consequence, not another enemy.
	idEntity *trace = gameLocal.FindEntity( "city_retained_witness" );
	if ( trace ) {
		if ( decision == 2 && trace->IsHidden() ) {
			trace->Show();
		} else if ( decision != 2 && !trace->IsHidden() ) {
			trace->Hide();
		}
	}
}

void idStBrielleAwarenessDirector::ApplyAnnexCorrection( void ) {
	if ( annexCorrectionApplied ) {
		return;
	}

	idEntity *arch = gameLocal.FindEntity( "annex_gate_arch_b" );
	if ( arch ) {
		arch->SetOrigin( idVec3( 36.0f, 0.0f, 0.0f ) );
	}

	idEntity *ceilingPool = gameLocal.FindEntity( "annex_ceiling_pool_3" );
	if ( ceilingPool && ceilingPool->RespondsTo( EV_Activate ) ) {
		ceilingPool->ProcessEvent( &EV_Activate, this );
	}

	idEntity *photoCorrection = gameLocal.FindEntity( "annex_room214_absence_trace" );
	if ( photoCorrection ) {
		photoCorrection->SetOrigin( idVec3( -672.0f, -75.0f, -24.0f ) );
		photoCorrection->Show();
	}

	const idDeclSkin *room214CorrectedSkin = declManager->FindSkin( "stbrielle/room214_corrected", false );
	if ( room214CorrectedSkin ) {
		const char *room214Visuals[] = {
			"annex_room214_contents",
			"annex_room214_reveal_frame",
			"annex_214_ledger"
		};
		for ( int i = 0; i < 3; ++i ) {
			idEntity *room214Entity = gameLocal.FindEntity( room214Visuals[i] );
			if ( room214Entity ) {
				room214Entity->SetSkin( room214CorrectedSkin );
				room214Entity->UpdateVisuals();
			}
		}
	} else if ( debug ) {
		gameLocal.Warning( "[ST. BRIELLE ANNEX] Room 214 corrected skin was not found." );
	}

	idEntity *room214Frame = gameLocal.FindEntity( "annex_room214_reveal_frame" );
	if ( room214Frame ) {
		const idVec3 frameOrigin = room214Frame->GetPhysics()->GetOrigin();
		room214Frame->SetOrigin( frameOrigin + idVec3( -2.0f, 3.0f, -3.5f ) );
		room214Frame->UpdateVisuals();
	}

	idEntity *room214RevealLight = gameLocal.FindEntity( "annex_room214_light" );
	if ( room214RevealLight ) {
		room214RevealLight->SetOrigin( idVec3( 732.0f, 251.0f, 174.0f ) );
		room214RevealLight->SetColor( 0.17f, 0.24f, 0.34f );
	}

	idEntity *room214LightA = gameLocal.FindEntity( "annex_214_inner_light_a" );
	if ( room214LightA ) {
		room214LightA->SetOrigin( idVec3( 748.0f, 247.0f, 226.0f ) );
		room214LightA->SetColor( 0.38f, 0.45f, 0.52f );
		room214LightA->spawnArgs.Set( "snd_room214_threshold", "snd_stbrielle_room214_threshold" );
		if ( !room214LightA->IsPlayingSound( SND_CHANNEL_BODY ) ) {
			room214LightA->StartSound( "snd_room214_threshold", SND_CHANNEL_BODY, 0, false, NULL );
		}
	}

	idEntity *room214LightB = gameLocal.FindEntity( "annex_214_inner_light_b" );
	if ( room214LightB ) {
		room214LightB->SetOrigin( idVec3( 866.0f, 277.0f, 118.0f ) );
		room214LightB->SetColor( 0.22f, 0.018f, 0.034f );
	}

	ConfigureAnnexPhoto( true );
	ConfigureAnnexPhone();

	const bool phoneAnswered = idStBrielleRecord::GetBool( "sb_annex_phone_answered", false );
	if ( !phoneAnswered ) {
		idEntity *exitTerminal = gameLocal.FindEntity( "annex_exit_terminal" );
		if ( exitTerminal ) {
			ConfigureInteractable( exitTerminal, "CONTINUITY EXIT / HOLD", "HOLD", "", true );
			exitTerminal->spawnArgs.Set( "stbrielle_interact", "0" );
			exitTerminal->spawnArgs.Set( "stbrielle_activate_targets", "0" );
			exitTerminal->targets.Clear();
		}
	}

	idEntity *phoneLight = gameLocal.FindEntity( "annex_workorder_light" );
	if ( phoneLight ) {
		phoneLight->SetOrigin( idVec3( -420.0f, 64.0f, 92.0f ) );
		if ( phoneAnswered ) {
			phoneLight->SetColor( 0.07f, 0.025f, 0.018f );
		} else {
			phoneLight->SetColor( 0.86f, 0.22f, 0.055f );
		}
	}

	annexPhonePulseBright = !phoneAnswered;
	annexPhoneNextPulseTime = gameLocal.time + 450;
	annexCorrectionApplied = true;

	if ( debug ) {
		gameLocal.Printf( "[ST. BRIELLE ANNEX] post-214 continuity correction applied\n" );
	}
}

void idStBrielleAwarenessDirector::UpdateAnnexFiledPerson( idPlayer *player ) {
	if ( !player ) {
		return;
	}

	idEntity *filedPerson = gameLocal.FindEntity( "annex_room214_absence_trace" );
	if ( !filedPerson ) {
		return;
	}

	const bool resolved = idStBrielleRecord::GetBool( "sb_annex_filed_person_resolved", false );
	if ( resolved ) {
		filedPerson->StopSound( SND_CHANNEL_BODY, false );
		filedPerson->Hide();
		annexFiledPersonActive = false;
		return;
	}

	if ( !idStBrielleRecord::GetBool( "sb_annex_complete", false ) ) {
		return;
	}

	const idVec3 visualOffset( 539.0f, 260.0f, 174.0f );

	if ( !annexFiledPersonActive ) {
		annexFiledPersonActive = true;
		annexFiledPersonNextMoveTime = gameLocal.time + 1100;
		annexFiledPersonObservedSince = 0;

		const idVec3 startCenter( 300.0f, 0.0f, 82.0f );
		filedPerson->SetOrigin( startCenter - visualOffset );
		filedPerson->Show();
		filedPerson->UpdateVisuals();
		filedPerson->spawnArgs.Set( "snd_filed_person", "snd_stbrielle_annex_filed_person" );
		filedPerson->StartSound( "snd_filed_person", SND_CHANNEL_BODY, 0, false, NULL );

		idEntity *notice = gameLocal.FindEntity( "annex_exit_complete_notice" );
		if ( notice ) {
			ConfigureNotice(
				notice,
				"OFFICE OF PERPETUAL RECORD / PERSONNEL",
				"PHOTOGRAPH 6-B / LOCATION EXCEPTION",
				"IMAGE COUNT: SIX",
				"IMAGE SIX: NOT IN FRAME",
				"CURRENT LOCATION: MUNICIPAL ANNEX",
				"SUBJECT STATUS: APPROACHING",
				"DO NOT CREATE A SECOND COPY",
				"7.0"
			);
			notice->ProcessEvent( &EV_Activate, player );
		}

		if ( debug ) {
			gameLocal.Printf( "[ST. BRIELLE ANNEX] personnel image six detached; first hostile active\n" );
		}
	}

	const idVec3 playerOrigin = player->GetPhysics()->GetOrigin();
	idVec3 filedCenter = filedPerson->GetPhysics()->GetOrigin() + visualOffset;
	idVec3 toPlayer = playerOrigin + idVec3( 0.0f, 0.0f, 54.0f ) - filedCenter;
	const float contactDistance = toPlayer.Length();

	if ( contactDistance < 74.0f ) {
		idStBrielleRecord::SetBool( "sb_annex_filed_person_contact", true );
		idStBrielleRecord::AddInt( "sb_annex_filed_person_contact_count", 1 );
		idStBrielleRecord::AddAwareness( 4 );

		int stability = idStBrielleRecord::GetInt( "sb_record_stability", 100 ) - 15;
		if ( stability < 0 ) {
			stability = 0;
		}
		idStBrielleRecord::SetInt( "sb_record_stability", stability );

		idEntity *notice = gameLocal.FindEntity( "annex_exit_complete_notice" );
		if ( notice ) {
			ConfigureNotice(
				notice,
				"OFFICE OF PERPETUAL RECORD / PERSONNEL",
				"CONTACT RECORDED",
				"SUBJECT: $PLAYER",
				"DUPLICATE PRESENCE: VERIFIED",
				"RECORD STABILITY: REDUCED",
				"CORRECTION REMAINS ACTIVE",
				"THIS CONTACT WILL BE RETAINED",
				"7.0"
			);
			notice->ProcessEvent( &EV_Activate, player );
		}

		float resetX = playerOrigin.x < 0.0f ? playerOrigin.x + 360.0f : playerOrigin.x - 360.0f;
		resetX = idMath::ClampFloat( -620.0f, 620.0f, resetX );
		filedCenter.Set( resetX, 0.0f, 82.0f );
		filedPerson->SetOrigin( filedCenter - visualOffset );
		filedPerson->UpdateVisuals();
		annexFiledPersonObservedSince = 0;
		annexFiledPersonNextMoveTime = gameLocal.time + 2200;
		return;
	}

	renderView_t *view = player->GetRenderView();
	bool observed = false;
	if ( view ) {
		idVec3 toFiledPerson = filedCenter - view->vieworg;
		const float distance = toFiledPerson.Normalize();
		const float facing = view->viewaxis[0] * toFiledPerson;
		observed = distance < 1000.0f && facing > 0.84f;
		if ( observed ) {
			trace_t sight;
			gameLocal.clip.TracePoint( sight, view->vieworg, filedCenter,
				MASK_SOLID | CONTENTS_BODY, player );
			observed = sight.fraction >= 1.0f || sight.c.entityNum == filedPerson->entityNumber;
		}
	}

	if ( observed ) {
		if ( annexFiledPersonObservedSince <= 0 ) {
			annexFiledPersonObservedSince = gameLocal.time;
		}

		if ( gameLocal.time - annexFiledPersonObservedSince >= 2600 ) {
			idStBrielleRecord::SetBool( "sb_annex_filed_person_resolved", true );
			idStBrielleRecord::SetBool( "sb_annex_first_hostile_survived", true );
			idStBrielleRecord::AddAwareness( 1 );
			filedPerson->StopSound( SND_CHANNEL_BODY, false );
			filedPerson->Hide();
			annexFiledPersonActive = false;

			idEntity *notice = gameLocal.FindEntity( "annex_exit_complete_notice" );
			if ( notice ) {
				ConfigureNotice(
					notice,
					"OFFICE OF PERPETUAL RECORD / PERSONNEL",
					"DUPLICATE IMAGE WITHDRAWN",
					"PHOTOGRAPH 6-B: FIVE SUBJECTS",
					"OBSERVATION: ACCEPTED",
					"SECOND PRESENCE: NOT RETAINED",
					"CURRENT STATUS: SINGLE",
					"YOU MAY CONTINUE",
					"8.0"
				);
				notice->ProcessEvent( &EV_Activate, player );
			}

			if ( debug ) {
				gameLocal.Printf( "[ST. BRIELLE ANNEX] personnel image six stabilized and withdrawn\n" );
			}
		}
		return;
	}

	annexFiledPersonObservedSince = 0;

	if ( gameLocal.time < annexFiledPersonNextMoveTime ) {
		return;
	}

	idVec3 target = playerOrigin + idVec3( 0.0f, 0.0f, 54.0f );
	target.y = idMath::ClampFloat( -72.0f, 72.0f, target.y );
	target.z = 82.0f;

	idVec3 advance = target - filedCenter;
	advance.z = 0.0f;
	const float remaining = advance.Normalize();
	if ( remaining > 1.0f ) {
		const float step = idStBrielleRecord::GetAwareness() >= 10 ? 86.0f : 68.0f;
		const float moveDistance = remaining < step ? remaining : step;
		filedCenter += advance * moveDistance;
		filedCenter.x = idMath::ClampFloat( -760.0f, 760.0f, filedCenter.x );
		filedCenter.y = idMath::ClampFloat( -72.0f, 72.0f, filedCenter.y );
		filedCenter.z = 82.0f;
		filedPerson->SetOrigin( filedCenter - visualOffset );
		filedPerson->UpdateVisuals();
	}

	annexFiledPersonNextMoveTime = gameLocal.time + 700;
}

void idStBrielleAwarenessDirector::UpdateAnnexSequence( void ) {
	if ( !gameLocal.FindEntity( "annex_room214_check" ) ) {
		return;
	}

	const bool workOrderRead = idStBrielleRecord::GetBool( "sb_annex_workorder_read", false );
	const bool ledgerRead = idStBrielleRecord::GetBool( "sb_annex_214_ledger_read", false );
	const bool corrected = idStBrielleRecord::GetBool( "sb_annex_after_214", false );

	if ( workOrderRead && !corrected && !annexPhotoConfigured ) {
		ConfigureAnnexPhoto( false );
	}

	if ( corrected && !annexCorrectionApplied ) {
		ApplyAnnexCorrection();
	}

	idPlayer *player = gameLocal.GetLocalPlayer();
	if ( !corrected && ledgerRead && player ) {
		const idVec3 &p = player->GetPhysics()->GetOrigin();

		if ( p.x > 600.0f && p.y > 180.0f && p.y < 340.0f ) {
			annexLedgerWasInside = true;
		}

		if ( annexLedgerWasInside && p.x < 548.0f ) {
			idStBrielleRecord::SetBool( "sb_annex_after_214", true );
			ApplyAnnexCorrection();
		}
	}

	if ( !annexCorrectionApplied ) {
		return;
	}

	idEntity *phoneSurface = gameLocal.FindEntity( "annex_reception_countertop" );
	const bool phoneAnswered = idStBrielleRecord::GetBool( "sb_annex_phone_answered", false );

	if ( !phoneAnswered && phoneSurface && !phoneSurface->spawnArgs.GetBool( "stbrielle_interact", "0" ) ) {
		idStBrielleRecord::SetBool( "sb_annex_phone_answered", true );
		phoneSurface->StopSound( SND_CHANNEL_BODY, false );

		idEntity *phoneLight = gameLocal.FindEntity( "annex_workorder_light" );
		if ( phoneLight ) {
			phoneLight->SetColor( 0.07f, 0.025f, 0.018f );
		}

		ConfigureAnnexExit( false );

		if ( debug ) {
			gameLocal.Printf( "[ST. BRIELLE ANNEX] reception telephone answered; departure record now conflicts\n" );
		}
		return;
	}

	if ( !phoneAnswered && gameLocal.time >= annexPhoneNextPulseTime ) {
		annexPhonePulseBright = !annexPhonePulseBright;
		annexPhoneNextPulseTime = gameLocal.time + ( annexPhonePulseBright ? 420 : 240 );

		idEntity *phoneLight = gameLocal.FindEntity( "annex_workorder_light" );
		if ( phoneLight ) {
			if ( annexPhonePulseBright ) {
				phoneLight->SetColor( 0.86f, 0.22f, 0.055f );
			} else {
				phoneLight->SetColor( 0.12f, 0.035f, 0.020f );
			}
		}
	}

	if ( phoneAnswered ) {
		if ( phoneSurface ) {
			phoneSurface->StopSound( SND_CHANNEL_BODY, false );
		}

		idEntity *exitTerminal = gameLocal.FindEntity( "annex_exit_terminal" );
		if ( !exitTerminal ) {
			return;
		}

		const bool exitReviewed = idStBrielleRecord::GetBool( "sb_annex_exit_reviewed", false );
		const bool exitComplete = idStBrielleRecord::GetBool( "sb_annex_complete", false );
		const bool exitInteractive = exitTerminal->spawnArgs.GetBool( "stbrielle_interact", "0" );
		const char *exitAction = exitTerminal->spawnArgs.GetString( "stbrielle_action", "" );

		if ( exitComplete ) {
			UpdateAnnexFiledPerson( player );

			if ( idStBrielleRecord::GetBool( "sb_annex_filed_person_resolved", false ) ) {
				ConfigureAnnexDeparture( player );
				return;
			}

			if ( idStr::Icmp( exitAction, "FILED" ) != 0 || exitInteractive ) {
				ConfigureAnnexExit( true );
				if ( debug ) {
					gameLocal.Printf( "[ST. BRIELLE ANNEX] continuity return filed; exit correction complete\n" );
				}
			}
			return;
		}

		if ( !exitReviewed ) {
			if ( idStr::Icmp( exitAction, "REVIEW" ) != 0 ) {
				ConfigureAnnexExit( false );
			}

			if ( !exitTerminal->spawnArgs.GetBool( "stbrielle_interact", "0" ) ) {
				idStBrielleRecord::SetBool( "sb_annex_exit_reviewed", true );
				ConfigureAnnexExit( true );

				if ( debug ) {
					gameLocal.Printf( "[ST. BRIELLE ANNEX] duplicate departure reviewed; one return authorized\n" );
				}
			}
		} else if ( idStr::Icmp( exitAction, "RETURN" ) != 0 ) {
			ConfigureAnnexExit( true );
		}
	}
}

void idStBrielleAwarenessDirector::Save( idSaveGame *savefile ) const {
	savefile->WriteInt( lastTier );
	savefile->WriteInt( nextCheckTime );
	savefile->WriteInt( checkIntervalMS );
	savefile->WriteBool( debug );

	savefile->WriteBool( annexLedgerWasInside );
	savefile->WriteBool( annexCorrectionApplied );
	savefile->WriteBool( annexPhotoConfigured );
	savefile->WriteBool( annexPhonePulseBright );
	savefile->WriteInt( annexPhoneNextPulseTime );

	savefile->WriteBool( annexFiledPersonActive );
	savefile->WriteInt( annexFiledPersonNextMoveTime );
	savefile->WriteInt( annexFiledPersonObservedSince );
}

void idStBrielleAwarenessDirector::Restore( idRestoreGame *savefile ) {
	savefile->ReadInt( lastTier );
	savefile->ReadInt( nextCheckTime );
	savefile->ReadInt( checkIntervalMS );
	savefile->ReadBool( debug );

	savefile->ReadBool( annexLedgerWasInside );
	savefile->ReadBool( annexCorrectionApplied );
	savefile->ReadBool( annexPhotoConfigured );
	savefile->ReadBool( annexPhonePulseBright );
	savefile->ReadInt( annexPhoneNextPulseTime );

	savefile->ReadBool( annexFiledPersonActive );
	savefile->ReadInt( annexFiledPersonNextMoveTime );
	savefile->ReadInt( annexFiledPersonObservedSince );

	BecomeActive( TH_THINK );
}
