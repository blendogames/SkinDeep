#pragma once

#include "Target.h"

// Persistent campaign state for the St. Brielle project.
//
// Values are stored in gameLocal.persistentLevelInfo so they survive saves and
// can be read by later maps in the campaign. Use the "sb_" prefix for project
// keys to avoid collisions with legacy Skin Deep progression data.
class idStBrielleRecord {
public:
	static const int CAMPAIGN_VERSION = 1;

	enum cycle_t {
		CYCLE_INK = 0,
		CYCLE_BRASS,
		CYCLE_WATER,
		CYCLE_CODE
	};

	enum awarenessTier_t {
		AWARENESS_DORMANT = 0,
		AWARENESS_NOTICED,
		AWARENESS_OBSERVING,
		AWARENESS_CORRECTING,
		AWARENESS_RUPTURE
	};

	static void			EnsureDefaults();

	static bool			Has( const char *key );
	static idStr		GetString( const char *key, const char *defaultValue = "" );
	static int			GetInt( const char *key, int defaultValue = 0 );
	static bool			GetBool( const char *key, bool defaultValue = false );

	static void			SetString( const char *key, const char *value );
	static void			SetInt( const char *key, int value );
	static void			SetBool( const char *key, bool value );
	static int			AddInt( const char *key, int delta );
	static bool			ToggleBool( const char *key );
	static void			Clear( const char *key );

	static cycle_t		GetCycle();
	static void			SetCycle( cycle_t cycle );
	static int			GetAwareness();
	static int			AddAwareness( int amount );
	static awarenessTier_t	GetAwarenessTier();
	static awarenessTier_t	GetAwarenessTierForValue( int value );
	static const char *	GetAwarenessTierName( awarenessTier_t tier );
};

// Map target that mutates the persistent Record when activated.
//
// Spawn args:
//   record_key       e.g. "sb_room_214_exists"
//   record_mode      set | add | toggle | clear
//   record_value     value for set/add (default "1")
//   record_once      remove after activation (default "1")
//   record_debug     print mutation to console (default "0")
class idTarget_StBrielleRecord : public idTarget {
public:
	CLASS_PROTOTYPE( idTarget_StBrielleRecord );

	virtual void		Spawn( void );

private:
	void				Event_Activate( idEntity *activator );
};

// Map target that activates its normal targets only when a persistent Record
// condition evaluates true.
//
// Spawn args:
//   record_key       key to inspect
//   record_compare   equals | not_equals | gt | gte | lt | lte | true | false | exists | missing
//   record_value     comparison value (default "1")
//   record_once      remove after a successful activation (default "0")
//   record_debug     print the comparison result (default "0")
class idTarget_StBrielleRecordCheck : public idTarget {
public:
	CLASS_PROTOTYPE( idTarget_StBrielleRecordCheck );

	virtual void		Spawn( void );

private:
	void				Event_Activate( idEntity *activator );
	bool				EvaluateCondition( void ) const;
};


// HUD notice target for St. Brielle civic documents, terminals, and quiet
// supernatural feedback.
//
// Spawn args:
//   notice_title     large title
//   notice_kicker    small institutional heading
//   notice_line1..4  body rows
//   notice_footer    small footer / provenance
//   notice_duration  seconds before the card clears (default 5.0)
//   $PLAYER          in any notice string is replaced with the local ui_name
class idTarget_StBrielleNotice : public idTarget {
public:
	CLASS_PROTOTYPE( idTarget_StBrielleNotice );

	virtual void		Spawn( void );

private:
	void				Event_Activate( idEntity *activator );
	void				Event_Clear( void );
};
