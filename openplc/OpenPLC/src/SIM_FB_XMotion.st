(* ============================================================
   SIM_FB_XMotion.st — Horizontal motion with accel / decel
   ============================================================ *)

FUNCTION_BLOCK SIM_FB_XMotion
VAR_INPUT
  delta_t  : REAL;
  x_target : REAL;
  x_min    : REAL;
  x_max    : REAL;
  v_max    : REAL;
  t_acc    : REAL;
  t_dec    : REAL;
END_VAR
VAR_IN_OUT
  x_pos : REAL;
  v_x   : REAL;
END_VAR
VAR_OUTPUT
  arrived : BOOL;
END_VAR
VAR
  drive_target : REAL;
  distance     : REAL;
  dir          : REAL;
  a_acc        : REAL;
  a_dec        : REAL;
  brake_dist   : REAL;
  new_vel      : REAL;
  travel       : REAL;
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
      END_IF;
    END_IF;
  ELSE
    drive_target := x_target;
  END_IF;

  arrived := ABS(x_pos - drive_target) <= 3.0;
  IF arrived THEN
    x_pos := drive_target;
    v_x := 0.0;
    RETURN;
  END_IF;

  IF t_acc <= 0.0 THEN t_acc := 0.001; END_IF;
  IF t_dec <= 0.0 THEN t_dec := 0.001; END_IF;
  IF v_max < 0.0 THEN v_max := 0.0; END_IF;

  a_acc := v_max / t_acc;
  a_dec := v_max / t_dec;

  dir := 1.0;
  IF drive_target < x_pos THEN
    dir := -1.0;
  END_IF;

  distance := ABS(drive_target - x_pos);

  IF a_dec > 0.0 THEN
    brake_dist := (v_x * v_x) / (2.0 * a_dec);
  ELSE
    brake_dist := 0.0;
  END_IF;

  IF brake_dist >= distance THEN
    new_vel := v_x - a_dec * delta_t;
    IF new_vel < 0.0 THEN new_vel := 0.0; END_IF;
  ELSE
    new_vel := v_x + a_acc * delta_t;
    IF new_vel > v_max THEN new_vel := v_max; END_IF;
  END_IF;

  travel := new_vel * delta_t;
  IF travel >= distance THEN
    x_pos := drive_target;
    v_x := 0.0;
    arrived := TRUE;
  ELSE
    x_pos := x_pos + dir * travel;
    v_x := new_vel;
    arrived := FALSE;
  END_IF;
END_FUNCTION_BLOCK

