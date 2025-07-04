params [ ["_mission_cost", 0], "_caller" ];

private _all_possible_sectors = ([SpawnMissionMarkers] call checkSpawn) apply { _x select 0 };
if (count _all_possible_sectors == 0) exitWith { [gamelogic, "Could not find position for fob hunting mission"] remoteExec ["globalChat", 0] };

_spawn_marker = selectRandom _all_possible_sectors;
GRLIB_secondary_used_positions pushbackUnique _spawn_marker;

diag_log format ["--- LRX: %1 start static mission: Fob Hunting at %2", _caller, time];
resources_intel = resources_intel - _mission_cost;
GRLIB_secondary_in_progress = 0;
publicVariable "GRLIB_secondary_in_progress";

[2] remoteExec ["remote_call_intel", 0];

private _base_position = markerpos _spawn_marker;
private _base_output = [_base_position, true, true] call createOutpost;
private _base_objects = _base_output select 0;
private _base_objectives = _base_output select 1;
private _grpdefenders = _base_output select 2;
private _grpsentry = _base_output select 3;

secondary_objective_position_marker = _base_position;
publicVariable "secondary_objective_position_marker";
sleep 1;

waitUntil {
	sleep 5;
	( { alive _x } count _base_objectives == 0 )
};

[3] remoteExec ["remote_call_intel", 0];

combat_readiness = 15 max round (combat_readiness * GRLIB_secondary_objective_impact);
stats_secondary_objectives = stats_secondary_objectives + 1;

{
	if (typeOf _x isKindof "AllVehicles") then {
		_x setVariable ["GRLIB_vehicle_owner", "", true];
		_x lock 0;
	};
} foreach _base_objects;

[_base_objectives + _base_objects, _base_position, _grpdefenders, _grpsentry] spawn {
	sleep 300;
	private _vehicles = (_this select 0);
	[_vehicles] call cleanMissionVehicles;

	{ deleteVehicle _x } forEach ((nearestObjects [(_this select 1), ["Ruins_F"], 100]) select { getObjectType _x == 8 });
	{ deleteVehicle _x } forEach units (_this select 2);
	{ deleteVehicle _x } forEach units (_this select 3);

	GRLIB_secondary_in_progress = -1;
	publicVariable "GRLIB_secondary_in_progress";
	GRLIB_secondary_used_positions = [];
};
