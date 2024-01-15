      ******************************************************************
      * GAMECON : constants. World extent excluded - read from the
      * mask at runtime (gamesta.cpy WS-WORLD-WIDTH/HEIGHT).
      ******************************************************************
      * zoom := WIN-WIDTH / WS-SCREEN-WIDTH
       01  WS-SCREEN-WIDTH         PIC S9(9) COMP-5 VALUE 384.
       01  WS-SCREEN-HEIGHT        PIC S9(9) COMP-5 VALUE 216.
       01  WS-VOID-MARGIN          PIC S9(9) COMP-5 VALUE 250.

      * pixel = subpixel / WS-SUBPIXEL-SCALE
       01  WS-SUBPIXEL-SCALE       PIC S9(9) COMP-5 VALUE 8.

       01  WS-GRAVITY              PIC S9(9) COMP-5 VALUE 4.
       01  WS-MOVE-SPEED           PIC S9(9) COMP-5 VALUE 20.
      * peak height = impulse^2 / (2 . gravity . scale)
       01  WS-JUMP-IMPULSE         PIC S9(9) COMP-5 VALUE -80.
       01  WS-MAX-FALL-SPEED       PIC S9(9) COMP-5 VALUE 72.
       01  WS-FRAME-MILLIS         PIC S9(9) COMP-5 VALUE 16.

       01  WS-PLAYER-WIDTH         PIC S9(9) COMP-5 VALUE 14.
       01  WS-PLAYER-HEIGHT        PIC S9(9) COMP-5 VALUE 23.
       01  WS-SPAWN-X              PIC S9(9) COMP-5 VALUE 1000.
       01  WS-SPAWN-Y              PIC S9(9) COMP-5 VALUE 0.

       01  WS-COIN-VALUE           PIC S9(9) COMP-5 VALUE 100.
