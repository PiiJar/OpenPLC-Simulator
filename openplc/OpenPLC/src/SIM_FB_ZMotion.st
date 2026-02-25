(* ============================================================
   SIM_FB_ZMotion.st — Vertical (Z) motion simulation
   
   Simulates 2D transporter lift/sink with realistic physics:
   - Slow start / fast middle / slow end speed profiles
   - Different slow zones for wet vs dry stations
   - Device delays and drip delays
   
   Coordinate convention: z=0 is bottom (sunk), z=z_total is top (lifted)
   
   LIFT sequence (z_stage 1-5):
     1: Init delay  (device_delay + dropping_time)
     2: Slow lift    0 → slow_zone
     3: Fast lift    → (z_total - z_slow_end_mm)
     4: Slow end     → z_total_mm
     5: Drip delay   at top position
   
   SINK sequence (z_stage 6-8):
     6: Init delay  (device_delay + drip_delay)
     7: Fast sink    z_total → slow_zone
     8: Slow sink    → 0 mm
   
   Caller sets z_stage and z_timer_s before first call.
   Output 'done' pulses TRUE when sequence completes.
   ============================================================ *)

FUNCTION_BLOCK SIM_FB_ZMotion
VAR_INPUT
  delta_t       : REAL;    (* Cycle time in seconds *)
  station_kind  : INT;     (* KIND_DRY=0, KIND_WET=1 *)
  z_total_mm    : REAL;    (* Total Z travel distance *)
  z_slow_dry_mm : REAL;    (* Slow zone for dry stations *)
  z_slow_wet_mm : REAL;    (* Slow zone for wet stations *)
  z_slow_end_mm : REAL;    (* Slow zone at end of travel *)
  z_slow_mm_s   : REAL;    (* Slow speed mm/s *)
  z_fast_mm_s   : REAL;    (* Fast speed mm/s *)
  drip_delay_s  : REAL;    (* Drip delay after lift *)
END_VAR
VAR_IN_OUT
  z_mm      : REAL;        (* Current Z position *)
  z_stage   : INT;         (* Current motion stage *)
  z_timer_s : REAL;        (* Delay timer *)
END_VAR
VAR_OUTPUT
  done : BOOL;             (* TRUE when sequence complete *)
END_VAR
VAR_EXTERNAL CONSTANT
  KIND_WET : INT;
END_VAR
VAR
  slow_zone : REAL;
END_VAR

  done := FALSE;

  (* Select slow zone based on station kind *)
  IF station_kind = KIND_WET THEN
    slow_zone := z_slow_wet_mm;
  ELSE
    slow_zone := z_slow_dry_mm;
  END_IF;

  CASE z_stage OF

    (* === LIFT: stages 1-5 — nosto altaasta ylös (z kasvaa: 0 → z_total) === *)

    1: (* Init delay: device_delay + dropping_time *)
      z_timer_s := z_timer_s - delta_t;
      IF z_timer_s <= 0.0 THEN
        z_stage := 2;
        z_mm := 0.0;
      END_IF;

    2: (* Slow lift start — hidas nosto nesteestä *)
      z_mm := z_mm + z_slow_mm_s * delta_t;
      IF z_mm >= slow_zone THEN
        z_stage := 3;
      END_IF;

    3: (* Fast lift — nopea nosto *)
      z_mm := z_mm + z_fast_mm_s * delta_t;
      IF z_mm >= (z_total_mm - z_slow_end_mm) THEN
        z_stage := 4;
      END_IF;

    4: (* Slow lift end — hidas loppunosto *)
      z_mm := z_mm + z_slow_mm_s * delta_t;
      IF z_mm >= z_total_mm THEN
        z_mm := z_total_mm;
        z_timer_s := drip_delay_s;
        z_stage := 5;
      END_IF;

    5: (* Drip delay — tippumisviive yläasemassa *)
      z_timer_s := z_timer_s - delta_t;
      IF z_timer_s <= 0.0 THEN
        z_stage := 0;
        done := TRUE;
      END_IF;

    (* === SINK: stages 6-8 — lasku altaaseen (z pienenee: z_total → 0) === *)

    6: (* Init delay: device_delay + drip_delay *)
      z_timer_s := z_timer_s - delta_t;
      IF z_timer_s <= 0.0 THEN
        z_stage := 7;
      END_IF;

    7: (* Fast sink — nopea lasku *)
      z_mm := z_mm - z_fast_mm_s * delta_t;
      IF z_mm <= slow_zone THEN
        z_stage := 8;
      END_IF;

    8: (* Slow sink — hidas lasku nesteeseen *)
      z_mm := z_mm - z_slow_mm_s * delta_t;
      IF z_mm <= 0.0 THEN
        z_mm := 0.0;
        z_stage := 0;
        done := TRUE;
      END_IF;

  END_CASE;

END_FUNCTION_BLOCK
