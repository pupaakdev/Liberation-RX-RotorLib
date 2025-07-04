params ["_base_position", "_enable_objectives", "_enable_defenders"];

private _fob_templates = [
    "scripts\fob_templates\template5.sqf",
    "scripts\fob_templates\template4.sqf",
    "scripts\fob_templates\template3.sqf",
    "scripts\fob_templates\template2.sqf",
    "scripts\fob_templates\template1.sqf"
];

// Build Base
private _base_objects = [];
private _base_objectives = [];
private _base_defenders = [];
private _template_selected = selectRandom _fob_templates;
private _template = ([] call compile preprocessFileLineNumbers _template_selected);
private _template_name =  _template select 0;
private _objects_to_build = _template select 1;
private _objectives_to_build = _template select 2;
private _defenders_to_build = _template select 3;
private _base_corners =  _template select 4;
diag_log format ["--- LRX Spawn Outpost %1 pos %2 at %3", _template_name, _base_position, time];

private ["_nextclass", "_nextobject", "_nextpos", "_nextdir"];
{
	_nextclass = _x select 0;
	_nextpos = _x select 1;
	_nextpos = [((_base_position select 0) + (_nextpos select 0)),((_base_position select 1) + (_nextpos select 1)),0];
	_nextdir = _x select 2;

	_nextobject = _nextclass createVehicle _nextpos;
    _nextobject allowDamage false;
    _nextobject setPosATL _nextpos;
    if (_nextclass isKindOf "HBarrier_base_F") then {
        _nextobject setVectorDirAndUp [[-cos _nextdir, sin _nextdir, 0] vectorCrossProduct surfaceNormal _nextpos, surfaceNormal _nextpos];
     } else {
        _nextobject setVectorDirAndUp [[_nextdir, _nextdir, 0], [0,0,1]];
    };

	_base_objects pushBack _nextobject;
    sleep 0.1;
} foreach _objects_to_build;
sleep 1;

// Add Objective to destroy
if (_enable_objectives) then {
    {
        _nextclass = _x select 0;
        _nextpos = _x select 1;
        _nextpos = [((_base_position select 0) + (_nextpos select 0)),((_base_position select 1) + (_nextpos select 1)),0.5];
        _nextdir = _x select 2;

        _nextobject = _nextclass createVehicle [(_nextpos select 0) + floor(random 500),(_nextpos select 1) + floor(random 500),0.5];
        _nextobject allowDamage false;
        _nextobject setVectorUp [0,0,1];
        _nextobject setPos _nextpos;
        _nextobject setDir _nextdir;

        _base_objectives pushBack _nextobject;
    } foreach _objectives_to_build;
    sleep 4;
};

{
    _x setDamage 0;
    _x setVariable ["R3F_LOG_disabled", true, true];
    if (_x isKindof "AllVehicles" || _x in _base_objectives) then {
        _x allowDamage true;
        _x addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
        [_x, "lock", "server"] call F_vehicleLock;
    };
} foreach (_base_objectives + _base_objects);

// Add Defenders
private _grpdefenders = grpNull;
private _grpsentry = grpNull;
private _defenders = [];

if (_enable_defenders) then {
    private _classname = _defenders_to_build apply { _x select 0 };
    _grpdefenders = [_base_position, _classname, GRLIB_side_enemy, "building", true] call F_libSpawnUnits;
    {
        _unit = _x;
        _nextentry = _defenders_to_build select _forEachIndex;
        _nextpos = _nextentry select 1;
        _nextpos = [((_base_position select 0) + (_nextpos select 0)),((_base_position select 1) + (_nextpos select 1)),(_nextpos select 2)];
        _nextdir = _nextentry select 2;
        _nextobject setDir _nextdir;
        _unit setUnitPos "UP";
        _unit disableAI "PATH";
        _unit setPos _nextpos;
        [_unit, true] spawn building_defence_ai;
        [_unit] spawn reammo_ai;
    } forEach (units _grpdefenders);

    private _sentry = ceil ((5 + (floor (random 4))) * (sqrt (GRLIB_unitcap)) );
    private _base_sentry_pos = [(_base_position select 0) + ((_base_corners select 0) select 0), (_base_position select 1) + ((_base_corners select 0) select 1),0];
    _grpsentry = [_base_sentry_pos, ([] call F_getAdaptiveSquadComp), GRLIB_side_enemy, "infantry", true] call F_libSpawnUnits;
    [_grpsentry] call F_deleteWaypoints;
    {
        _waypoint = _grpsentry addWaypoint [[((_base_position select 0) + (_x select 0)), ((_base_position select 1) + (_x select 1)),0], 0];
        _waypoint setWaypointType "MOVE";
        _waypoint setWaypointSpeed "LIMITED";
        _waypoint setWaypointBehaviour "SAFE";
        _waypoint setWaypointCompletionRadius 5;
    } foreach _base_corners;

    _waypoint = _grpsentry addWaypoint [[(_base_position select 0) + ((_base_corners select 0) select 0), (_base_position select 1) + ((_base_corners select 0) select 1),0], 0];
    _waypoint setWaypointType "CYCLE";
};

[ _base_objects, _base_objectives, _grpdefenders, _grpsentry ];
