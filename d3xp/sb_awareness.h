#pragma once

#include "Entity.h"

class idPlayer;

// Per-map interpreter for the global St. Brielle Awareness value.
//
// The director never exposes Awareness to the player directly. Instead it
// activates mapper-authored reactions when the persistent value enters a new
// tier. A map can have one director with any number of:
//
//   tier0_target*
//   tier1_target*
//   tier2_target*
//   tier3_target*
//   tier4_target*
//
// Each value is the name of an entity to activate when that tier becomes
// current.
//
// Spawn args:
//   check_interval_ms      Poll interval. Default 250.
//   fire_current_on_spawn  Fire the current tier once after map spawn.
//   awareness_debug        Print Awareness tier transitions to the console.
class idStBrielleAwarenessDirector : public idEntity {
public:
	CLASS_PROTOTYPE( idStBrielleAwarenessDirector );

	idStBrielleAwarenessDirector();

	virtual void		Spawn( void );
	virtual void		Think( void );
	virtual void		Save( idSaveGame *savefile ) const;
	virtual void		Restore( idRestoreGame *savefile );

private:
	int					lastTier;
	int					nextCheckTime;
	int					checkIntervalMS;
	bool				debug;

	// Annex vertical-slice state. These are local presentation flags; durable
	// progression remains in idStBrielleRecord.
	bool				annexLedgerWasInside;
	bool				annexCorrectionApplied;
	bool				annexPhotoConfigured;
	bool				annexPhonePulseBright;
	int					annexPhoneNextPulseTime;

	// First hostile encounter: after the continuity return is FILED, the sixth
	// personnel-image trace detaches from the photograph and advances whenever
	// it is not directly observed. Contact is non-lethal but persists in Record.
	bool				annexFiledPersonActive;
	int					annexFiledPersonNextMoveTime;
	int					annexFiledPersonObservedSince;

	void				ActivateTierTargets( int tier );
	void				UpdateAnnexSequence( void );
	void				ApplyAnnexCorrection( void );
	void				UpdateAnnexFiledPerson( idPlayer *player );
	void				ConfigureAnnexDeparture( idPlayer *player );
	void				ConfigureCityGlimpse( void );
	void				UpdateCityInvestigation( void );
	void				ConfigureAnnexPhoto( bool corrected );
	void				ConfigureAnnexPhone( void );
	void				ConfigureAnnexExit( bool reviewed );
	void				ConfigureInteractable( idEntity *ent, const char *displayName, const char *action, const char *targetName, bool useOnce );
	void				ConfigureNotice( idEntity *notice, const char *kicker, const char *title,
						const char *line1, const char *line2, const char *line3, const char *line4,
						const char *footer, const char *duration );
};
