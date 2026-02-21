(************************************************************
* OpenPLC - 2D Physics Core (POUs)
************************************************************)

FUNCTION IsWetStationType : BOOL
VAR_INPUT
  station_type : INT;
END_VAR
IsWetStationType := (station_type = 1) OR (station_type = 11);
END_FUNCTION

FUNCTION FindStationIndexByNumber : INT
VAR_INPUT
  station_number : INT;
END_VAR
VAR
  i : INT;
END_VAR
FindStationIndexByNumber := 0;
FOR i := 1 TO g_station_count DO
  IF g_stations[i].number = station_number THEN
    FindStationIndexByNumber := i;
    RETURN;
  END_IF
END_FOR
END_FUNCTION

FUNCTION GetStationX : REAL
VAR_INPUT
  station_number : INT;
END_VAR
VAR
  idx : INT;
END_VAR
idx := FindStationIndexByNumber(station_number);
IF idx > 0 THEN
  GetStationX := g_stations[idx].x_mm;
ELSE
  GetStationX := 0.0;
END_IF
END_FUNCTION

FUNCTION GetStationType : INT
VAR_INPUT
  station_number : INT;
END_VAR
VAR
  idx : INT;
END_VAR
idx := FindStationIndexByNumber(station_number);
IF idx > 0 THEN
  GetStationType := g_stations[idx].station_type;
ELSE
  GetStationType := 0;
END_IF
END_FUNCTION

FUNCTION GetStationDeviceDelay : REAL
VAR_INPUT
  station_number : INT;
END_VAR
VAR
  idx : INT;
END_VAR
idx := FindStationIndexByNumber(station_number);
IF idx > 0 THEN
  GetStationDeviceDelay := g_stations[idx].device_delay_s;
ELSE
  GetStationDeviceDelay := 0.0;
END_IF
END_FUNCTION

FUNCTION GetStationDroppingTime : REAL
VAR_INPUT
  station_number : INT;
END_VAR
VAR
  idx : INT;
END_VAR
idx := FindStationIndexByNumber(station_number);
IF idx > 0 THEN
  GetStationDroppingTime := g_stations[idx].dropping_time_s;
ELSE
  GetStationDroppingTime := 0.0;
END_IF
END_FUNCTION

FUNCTION_BLOCK FB_XMotion
VAR_INPUT
  dt : REAL;
  x_target : REAL;
  x_min : REAL;
  x_max : REAL;
  v_max : REAL;
  t_acc : REAL;
  t_dec : REAL;
END_VAR
VAR_IN_OUT
  x_pos : REAL;
  v_x : REAL;
END_VAR
VAR_OUTPUT
  arrived : BOOL;
END_VAR
VAR
  drive_target : REAL;
  distance : REAL;
  dir : REAL;
  a_acc : REAL;
  a_dec : REAL;
  brake_dist : REAL;
  new_vel : REAL;
  travel : REAL;
END_VAR

IF (x_max > x_min) THEN
  IF x_pos < x_min THEN
    drive_target := x_min;
  ELSIF x_pos > x_max THEN
    drive_target := x_max;
  ELSE
    IF x_target < x_min THEN
      drive_target := x_min;
    ELSIF x_target > x_max THEN
      drive_target := x_max;
    ELSE
      drive_target := x_target;
    END_IF
  END_IF
ELSE
  drive_target := x_target;
END_IF

arrived := ABS(x_pos - drive_target) <= 3.0;
IF arrived THEN
  x_pos := drive_target;
  v_x := 0.0;
  RETURN;
END_IF

IF t_acc <= 0.0 THEN t_acc := 0.001; END_IF
IF t_dec <= 0.0 THEN t_dec := 0.001; END_IF
IF v_max < 0.0 THEN v_max := 0.0; END_IF

a_acc := v_max / t_acc;
a_dec := v_max / t_dec;

dir := 1.0;
IF drive_target < x_pos THEN
  dir := -1.0;
END_IF

distance := ABS(drive_target - x_pos);

IF a_dec > 0.0 THEN
  brake_dist := (v_x * v_x) / (2.0 * a_dec);
ELSE
  brake_dist := 0.0;
END_IF

IF brake_dist >= distance THEN
  new_vel := v_x - a_dec * dt;
  IF new_vel < 0.0 THEN new_vel := 0.0; END_IF
ELSE
  new_vel := v_x + a_acc * dt;
  IF new_vel > v_max THEN new_vel := v_max; END_IF
END_IF

travel := new_vel * dt;
IF travel >= distance THEN
  x_pos := drive_target;
  v_x := 0.0;
  arrived := TRUE;
ELSE
  x_pos := x_pos + dir * travel;
  v_x := new_vel;
  arrived := FALSE;
END_IF
END_FUNCTION_BLOCK
