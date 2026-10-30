#pragma once

#include "Entity.h"

// Per-map interpreter for the global St. Brielle Cycle.
//
// A cycle director activates mapper-authored targets whenever sb_cycle changes.
// Prefixes:
//   ink_target*
//   brass_target*
//   water_target*
//   code_target*
//
// Targets are entity names. Numeric suffixes can be added for multiple targets,
// e.g. water_target1, water_target2.
class idStBrielleCycleDirector : public idEntity {
public:
	CLASS_PROTOTYPE( idStBrielleCycleDirector );

	idStBrielleCycleDirector();

	virtual void		Spawn( void );
	virtual void		Think( void );
	virtual void		Save( idSaveGame *savefile ) const;
	virtual void		Restore( idRestoreGame *savefile );

private:
	int					lastCycle;
	int					nextCheckTime;
	int					checkIntervalMS;
	bool				debug;

	void				ActivateCycleTargets( int cycle );
	const char *		GetCyclePrefix( int cycle ) const;
};
