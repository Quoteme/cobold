      ******************************************************************
      * GAMESTA : mutable state, one record per session.
      * Every field is PIC S9(9) COMP-5 (a full word): the CALL
      * boundary to SDLSHIM reads/writes 4 bytes regardless of a
      * field's own PICTURE, so no field here may be narrower.
      ******************************************************************
       01  WS-PLAYER.
      * PLY-X, PLY-Y, PLY-VX, PLY-VY : subpixels. PLY-PX, PLY-PY :=
      * floor(PLY-X / scale), floor(PLY-Y / scale) - the projection
      * every paragraph but 2200 actually reads.
           05  PLY-X               PIC S9(9) COMP-5.
           05  PLY-Y               PIC S9(9) COMP-5.
           05  PLY-VX              PIC S9(9) COMP-5.
           05  PLY-VY              PIC S9(9) COMP-5.
           05  PLY-PX              PIC S9(9) COMP-5.
           05  PLY-PY              PIC S9(9) COMP-5.
           05  PLY-FACING          PIC S9(9) COMP-5.
               88  PLY-FACING-RIGHT        VALUE 0.
               88  PLY-FACING-LEFT         VALUE 1.
           05  PLY-GROUNDED-FLAG   PIC S9(9) COMP-5.
               88  PLY-IS-GROUNDED         VALUE 1.
               88  PLY-IS-AIRBORNE         VALUE 0.
           05  PLY-ANIM-STATE      PIC S9(9) COMP-5.
               88  PLY-ANIM-IDLE           VALUE 0.
               88  PLY-ANIM-WALK           VALUE 1.
           05  PLY-ANIM-CLOCK      PIC S9(9) COMP-5.
           05  PLY-ANIM-FRAME      PIC S9(9) COMP-5.

       01  WS-GAME-STATUS          PIC S9(9) COMP-5.
           88  GAME-STATUS-RUNNING         VALUE 0.
           88  GAME-STATUS-WON             VALUE 1.
           88  GAME-STATUS-QUIT            VALUE 99.

       01  WS-INPUT.
           05  IN-QUIT             PIC S9(9) COMP-5.
               88  QUIT-REQUESTED          VALUE 1.
           05  IN-LEFT             PIC S9(9) COMP-5.
               88  LEFT-HELD               VALUE 1.
           05  IN-RIGHT            PIC S9(9) COMP-5.
               88  RIGHT-HELD              VALUE 1.
           05  IN-JUMP             PIC S9(9) COMP-5.
               88  JUMP-HELD               VALUE 1.

       01  WS-CAMERA.
           05  CAM-X               PIC S9(9) COMP-5.
           05  CAM-Y               PIC S9(9) COMP-5.

      * read from the mask image, not declared
       01  WS-WORLD-WIDTH          PIC S9(9) COMP-5.
       01  WS-WORLD-HEIGHT         PIC S9(9) COMP-5.
       01  WS-VOID-Y               PIC S9(9) COMP-5.
      * (WORLD-WIDTH - PLAYER-WIDTH) . scale
       01  WS-MAX-PLY-X-SUB        PIC S9(9) COMP-5.

      * one CALL's argument and result: World x Z x Z -> B
       01  WS-CHECK-X              PIC S9(9) COMP-5.
       01  WS-CHECK-Y              PIC S9(9) COMP-5.
       01  WS-MASK-HIT             PIC S9(9) COMP-5.
           88  MASK-IS-SOLID               VALUE 1.
       01  WS-DID-CORRECT          PIC S9(9) COMP-5.
           88  CORRECTED-A-COLLISION       VALUE 1.

       01  WS-LEDGER.
           05  LEDGER-BALANCE      PIC S9(9) COMP-5 VALUE 0.
           05  LEDGER-OVERDRAFTS   PIC S9(9) COMP-5 VALUE 0.

       01  WS-SDL-RC               PIC S9(9) COMP-5.
           88  PRESENTATION-LAYER-OK       VALUE 0.

       01  WS-CURRENT-TIER         PIC X(10).
