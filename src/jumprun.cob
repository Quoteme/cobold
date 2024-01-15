      ******************************************************************
      * JUMPRUN : GameState -> GameState, once per frame.
      * Rules live here; SDLSHIM (csrc/sdlshim.c) is I/O only.
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. JUMPRUN.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LEVEL-FILE ASSIGN TO "leveldata/level01.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LEVEL-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  LEVEL-FILE.
       COPY "levelrc.cpy".

       WORKING-STORAGE SECTION.
       COPY "gamecon.cpy".
       COPY "gamesta.cpy".
       COPY "leveltb.cpy".
       COPY "dbstate.cpy".

       01  WS-LEVEL-FILE-STATUS    PIC X(2).
           88  LEVEL-FILE-OK               VALUE "00".
       01  WS-END-OF-LEVEL-FILE    PIC X(1) VALUE "N".
           88  END-OF-LEVEL-FILE           VALUE "Y".

       01  WS-WIN-WIDTH             PIC S9(9) COMP-5.
       01  WS-WIN-HEIGHT            PIC S9(9) COMP-5.
       01  WS-FRAME-DIV             PIC S9(9) COMP-5.

       PROCEDURE DIVISION.

       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-GAME-LOOP UNTIL NOT GAME-STATUS-RUNNING
           PERFORM 8000-FINALIZE
           STOP RUN.

      ******************************************************************
      * 1000 - INITIALIZATION
      ******************************************************************
       1000-INITIALIZE.
           SET GAME-STATUS-RUNNING TO TRUE
           PERFORM 1100-LOAD-LEVEL-DATA
           PERFORM 1200-OPEN-PRESENTATION-LAYER
           PERFORM 1300-SPAWN-PLAYER
           PERFORM 1400-OPEN-PERSISTENCE-LAYER.

       1100-LOAD-LEVEL-DATA.
           OPEN INPUT LEVEL-FILE
           IF NOT LEVEL-FILE-OK
               DISPLAY "JUMPRUN-101 CANNOT OPEN LEVEL FILE, STATUS="
                   WS-LEVEL-FILE-STATUS
               SET GAME-STATUS-QUIT TO TRUE
           ELSE
               SET COIN-IDX TO 1
               SET TIER-IDX TO 1
               PERFORM UNTIL END-OF-LEVEL-FILE
                   READ LEVEL-FILE
                       AT END SET END-OF-LEVEL-FILE TO TRUE
                       NOT AT END PERFORM 1150-APPLY-LEVEL-RECORD
                   END-READ
               END-PERFORM
               CLOSE LEVEL-FILE
               COMPUTE WS-COIN-COUNT     = COIN-IDX - 1
               COMPUTE WS-TIER-COUNT     = TIER-IDX - 1
           END-IF.

       1150-APPLY-LEVEL-RECORD.
           EVALUATE LR-TYPE
               WHEN "C"
                   MOVE LR-F1 TO COIN-X(COIN-IDX)
                   MOVE LR-F2 TO COIN-Y(COIN-IDX)
                   MOVE 0     TO COIN-COLLECTED(COIN-IDX)
                   SET COIN-IDX UP BY 1
               WHEN "G"
                   MOVE LR-F1 TO GOAL-X
                   MOVE LR-F2 TO GOAL-Y
                   MOVE LR-F3 TO GOAL-W
                   MOVE LR-F4 TO GOAL-H
               WHEN "T"
                   MOVE LR-F1   TO TIER-THRESHOLD(TIER-IDX)
                   MOVE LR-NAME TO TIER-NAME(TIER-IDX)
                   SET TIER-IDX UP BY 1
               WHEN OTHER
                   DISPLAY "JUMPRUN-102 UNKNOWN LEVEL RECORD TYPE: "
                       LR-TYPE
           END-EVALUATE.

       1200-OPEN-PRESENTATION-LAYER.
           IF GAME-STATUS-RUNNING
               CALL "sdl_init" USING BY REFERENCE
                   WS-SDL-RC WS-WIN-WIDTH WS-WIN-HEIGHT
                   WS-WORLD-WIDTH WS-WORLD-HEIGHT
               IF NOT PRESENTATION-LAYER-OK
                   DISPLAY "JUMPRUN-201 PRESENTATION LAYER DOWN, RC="
                       WS-SDL-RC
                   SET GAME-STATUS-QUIT TO TRUE
               ELSE
                   COMPUTE WS-VOID-Y = WS-WORLD-HEIGHT + WS-VOID-MARGIN
                   COMPUTE WS-MAX-PLY-X-SUB =
                       (WS-WORLD-WIDTH - WS-PLAYER-WIDTH)
                       * WS-SUBPIXEL-SCALE
               END-IF
           END-IF.

       1300-SPAWN-PLAYER.
           COMPUTE PLY-X = WS-SPAWN-X * WS-SUBPIXEL-SCALE
           COMPUTE PLY-Y = WS-SPAWN-Y * WS-SUBPIXEL-SCALE
           MOVE WS-SPAWN-X TO PLY-PX
           MOVE WS-SPAWN-Y TO PLY-PY
           MOVE 0 TO PLY-VX PLY-VY
           SET PLY-FACING-RIGHT  TO TRUE
           SET PLY-IS-AIRBORNE   TO TRUE
           SET PLY-ANIM-IDLE     TO TRUE
           MOVE 0 TO PLY-ANIM-CLOCK PLY-ANIM-FRAME
           MOVE 0 TO LEDGER-BALANCE LEDGER-OVERDRAFTS.

       1400-OPEN-PERSISTENCE-LAYER.
           IF GAME-STATUS-RUNNING
               CALL "db_init" USING BY REFERENCE WS-DB-RC WS-ACCOUNT-ID
               IF NOT DB-CALL-OK
                   DISPLAY "JUMPRUN-401 PERSISTENCE LAYER DOWN, RC="
                       WS-DB-RC
                   SET GAME-STATUS-QUIT TO TRUE
               END-IF
           END-IF.

      ******************************************************************
      * 2000 - ONE ITERATION OF THE GAME LOOP (one rendered frame)
      ******************************************************************
       2000-GAME-LOOP.
           PERFORM 2100-READ-INPUT
           PERFORM 2200-APPLY-PHYSICS
           PERFORM 2300-RESOLVE-COLLISIONS
           PERFORM 2400-UPDATE-CAMERA
           PERFORM 2500-RENDER-FRAME
           CALL "sdl_delay" USING BY REFERENCE WS-FRAME-MILLIS.

       2100-READ-INPUT.
           MOVE 0 TO IN-QUIT IN-LEFT IN-RIGHT IN-JUMP
           CALL "sdl_poll" USING BY REFERENCE
               IN-QUIT IN-LEFT IN-RIGHT IN-JUMP
           IF QUIT-REQUESTED
               SET GAME-STATUS-QUIT TO TRUE
           END-IF
           EVALUATE TRUE
               WHEN LEFT-HELD
                   COMPUTE PLY-VX = 0 - WS-MOVE-SPEED
                   SET PLY-FACING-LEFT TO TRUE
                   SET PLY-ANIM-WALK   TO TRUE
               WHEN RIGHT-HELD
                   MOVE WS-MOVE-SPEED TO PLY-VX
                   SET PLY-FACING-RIGHT TO TRUE
                   SET PLY-ANIM-WALK    TO TRUE
               WHEN OTHER
                   MOVE 0 TO PLY-VX
                   SET PLY-ANIM-IDLE TO TRUE
           END-EVALUATE
           IF JUMP-HELD AND PLY-IS-GROUNDED
               MOVE WS-JUMP-IMPULSE TO PLY-VY
           END-IF.

       2200-APPLY-PHYSICS.
           ADD WS-GRAVITY TO PLY-VY
           IF PLY-VY > WS-MAX-FALL-SPEED
               MOVE WS-MAX-FALL-SPEED TO PLY-VY
           END-IF
           SET PLY-IS-AIRBORNE TO TRUE
           ADD PLY-VX TO PLY-X
           ADD PLY-VY TO PLY-Y
           IF PLY-X < 0
               MOVE 0 TO PLY-X
           END-IF
           IF PLY-X > WS-MAX-PLY-X-SUB
               MOVE WS-MAX-PLY-X-SUB TO PLY-X
           END-IF
      * pixel = subpixel / scale
           COMPUTE PLY-PX = PLY-X / WS-SUBPIXEL-SCALE
           COMPUTE PLY-PY = PLY-Y / WS-SUBPIXEL-SCALE.

       2300-RESOLVE-COLLISIONS.
           PERFORM 2310-RESOLVE-VERTICAL-COLLISION
           PERFORM 2320-RESOLVE-HORIZONTAL-COLLISION
           IF PLY-PY > WS-VOID-Y
               PERFORM 2330-CHARGE-OVERDRAFT
           END-IF
           PERFORM VARYING COIN-IDX FROM 1 BY 1
                   UNTIL COIN-IDX > WS-COIN-COUNT
               IF NOT COIN-IS-COLLECTED(COIN-IDX)
                   PERFORM 2340-COLLECT-COIN
               END-IF
           END-PERFORM
           PERFORM 2350-CHECK-GOAL.

      * argmin_{n>=0} not solid(feet - n.g), stepped rather than solved.
       2310-RESOLVE-VERTICAL-COLLISION.
           SET PLY-IS-AIRBORNE TO TRUE
           MOVE 0 TO WS-DID-CORRECT
           IF PLY-VY >= 0
               PERFORM 2311-CHECK-FEET-SOLID
               PERFORM UNTIL NOT MASK-IS-SOLID
                   SUBTRACT 1 FROM PLY-PY
                   MOVE 1 TO WS-DID-CORRECT
                   PERFORM 2311-CHECK-FEET-SOLID
               END-PERFORM
               IF CORRECTED-A-COLLISION
                   SET PLY-IS-GROUNDED TO TRUE
                   MOVE 0 TO PLY-VY
                   COMPUTE PLY-Y = PLY-PY * WS-SUBPIXEL-SCALE
               END-IF
           ELSE
               PERFORM 2312-CHECK-HEAD-SOLID
               PERFORM UNTIL NOT MASK-IS-SOLID
                   ADD 1 TO PLY-PY
                   MOVE 1 TO WS-DID-CORRECT
                   PERFORM 2312-CHECK-HEAD-SOLID
               END-PERFORM
               IF CORRECTED-A-COLLISION
                   MOVE 0 TO PLY-VY
                   COMPUTE PLY-Y = PLY-PY * WS-SUBPIXEL-SCALE
               END-IF
           END-IF.

       2311-CHECK-FEET-SOLID.
           MOVE PLY-PX TO WS-CHECK-X
           COMPUTE WS-CHECK-Y = PLY-PY + WS-PLAYER-HEIGHT - 1
           CALL "sdl_mask_solid" USING BY REFERENCE
               WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           IF NOT MASK-IS-SOLID
               COMPUTE WS-CHECK-X = PLY-PX + WS-PLAYER-WIDTH - 1
               CALL "sdl_mask_solid" USING BY REFERENCE
                   WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           END-IF.

       2312-CHECK-HEAD-SOLID.
           MOVE PLY-PX TO WS-CHECK-X
           MOVE PLY-PY TO WS-CHECK-Y
           CALL "sdl_mask_solid" USING BY REFERENCE
               WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           IF NOT MASK-IS-SOLID
               COMPUTE WS-CHECK-X = PLY-PX + WS-PLAYER-WIDTH - 1
               CALL "sdl_mask_solid" USING BY REFERENCE
                   WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           END-IF.

       2320-RESOLVE-HORIZONTAL-COLLISION.
           MOVE 0 TO WS-DID-CORRECT
           IF PLY-VX > 0
               PERFORM 2321-CHECK-RIGHT-SOLID
               PERFORM UNTIL NOT MASK-IS-SOLID
                   SUBTRACT 1 FROM PLY-PX
                   MOVE 1 TO WS-DID-CORRECT
                   PERFORM 2321-CHECK-RIGHT-SOLID
               END-PERFORM
           END-IF
           IF PLY-VX < 0
               PERFORM 2322-CHECK-LEFT-SOLID
               PERFORM UNTIL NOT MASK-IS-SOLID
                   ADD 1 TO PLY-PX
                   MOVE 1 TO WS-DID-CORRECT
                   PERFORM 2322-CHECK-LEFT-SOLID
               END-PERFORM
           END-IF
           IF CORRECTED-A-COLLISION
               MOVE 0 TO PLY-VX
               COMPUTE PLY-X = PLY-PX * WS-SUBPIXEL-SCALE
           END-IF.

       2321-CHECK-RIGHT-SOLID.
           COMPUTE WS-CHECK-X = PLY-PX + WS-PLAYER-WIDTH - 1
           MOVE PLY-PY TO WS-CHECK-Y
           CALL "sdl_mask_solid" USING BY REFERENCE
               WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           IF NOT MASK-IS-SOLID
               COMPUTE WS-CHECK-Y = PLY-PY + WS-PLAYER-HEIGHT - 1
               CALL "sdl_mask_solid" USING BY REFERENCE
                   WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           END-IF.

       2322-CHECK-LEFT-SOLID.
           MOVE PLY-PX TO WS-CHECK-X
           MOVE PLY-PY TO WS-CHECK-Y
           CALL "sdl_mask_solid" USING BY REFERENCE
               WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           IF NOT MASK-IS-SOLID
               COMPUTE WS-CHECK-Y = PLY-PY + WS-PLAYER-HEIGHT - 1
               CALL "sdl_mask_solid" USING BY REFERENCE
                   WS-CHECK-X WS-CHECK-Y WS-MASK-HIT
           END-IF.

       2330-CHARGE-OVERDRAFT.
           ADD 1 TO LEDGER-OVERDRAFTS
           PERFORM 1300-SPAWN-PLAYER.

       2340-COLLECT-COIN.
           IF PLY-PX + WS-PLAYER-WIDTH > COIN-X(COIN-IDX)
               AND PLY-PX < COIN-X(COIN-IDX) + 16
               AND PLY-PY + WS-PLAYER-HEIGHT > COIN-Y(COIN-IDX)
               AND PLY-PY < COIN-Y(COIN-IDX) + 16
               SET COIN-IS-COLLECTED(COIN-IDX) TO TRUE
               ADD WS-COIN-VALUE TO LEDGER-BALANCE
           END-IF.

       2350-CHECK-GOAL.
           IF PLY-PX + WS-PLAYER-WIDTH > GOAL-X
               AND PLY-PX < GOAL-X + GOAL-W
               AND PLY-PY + WS-PLAYER-HEIGHT > GOAL-Y
               AND PLY-PY < GOAL-Y + GOAL-H
               SET GAME-STATUS-WON TO TRUE
           END-IF.

       2400-UPDATE-CAMERA.
           COMPUTE CAM-X = PLY-PX - (WS-SCREEN-WIDTH / 2)
           IF CAM-X < 0
               MOVE 0 TO CAM-X
           END-IF
           IF CAM-X > WS-WORLD-WIDTH - WS-SCREEN-WIDTH
               COMPUTE CAM-X = WS-WORLD-WIDTH - WS-SCREEN-WIDTH
           END-IF
           COMPUTE CAM-Y = PLY-PY - (WS-SCREEN-HEIGHT / 2)
           IF CAM-Y < 0
               MOVE 0 TO CAM-Y
           END-IF
           IF CAM-Y > WS-WORLD-HEIGHT - WS-SCREEN-HEIGHT
               COMPUTE CAM-Y = WS-WORLD-HEIGHT - WS-SCREEN-HEIGHT
           END-IF
           ADD 1 TO PLY-ANIM-CLOCK
           IF PLY-ANIM-IDLE
               COMPUTE WS-FRAME-DIV = PLY-ANIM-CLOCK / 17
               COMPUTE PLY-ANIM-FRAME = FUNCTION MOD(WS-FRAME-DIV, 3)
           ELSE
               COMPUTE WS-FRAME-DIV = PLY-ANIM-CLOCK / 6
               COMPUTE PLY-ANIM-FRAME = FUNCTION MOD(WS-FRAME-DIV, 6)
           END-IF.

       2500-RENDER-FRAME.
           CALL "sdl_begin_frame" USING BY REFERENCE
               CAM-X CAM-Y WS-SCREEN-WIDTH WS-SCREEN-HEIGHT
           PERFORM VARYING COIN-IDX FROM 1 BY 1
                   UNTIL COIN-IDX > WS-COIN-COUNT
               IF NOT COIN-IS-COLLECTED(COIN-IDX)
                   CALL "sdl_draw_coin" USING BY REFERENCE
                       COIN-X(COIN-IDX) COIN-Y(COIN-IDX)
               END-IF
           END-PERFORM
           CALL "sdl_draw_goal" USING BY REFERENCE
               GOAL-X GOAL-Y GOAL-W GOAL-H
           CALL "sdl_draw_player" USING BY REFERENCE
               PLY-PX PLY-PY PLY-ANIM-STATE PLY-ANIM-FRAME PLY-FACING
           CALL "sdl_draw_foreground"
           CALL "sdl_end_frame" USING BY REFERENCE
               LEDGER-BALANCE LEDGER-OVERDRAFTS.

      ******************************************************************
      * 8000 - FINALIZATION
      ******************************************************************
       8000-FINALIZE.
           IF PRESENTATION-LAYER-OK
               CALL "sdl_shutdown"
           END-IF
           PERFORM 8100-REPORT-TIER
           PERFORM 8200-POST-LEDGER-ENTRY
           PERFORM 8300-PRINT-STATEMENT.

       8100-REPORT-TIER.
           MOVE "STANDARD  " TO WS-CURRENT-TIER
           SET TIER-IDX TO 1
           SEARCH TIER-ENTRY VARYING TIER-IDX
               AT END
                   CONTINUE
               WHEN LEDGER-BALANCE >= TIER-THRESHOLD(TIER-IDX)
                   MOVE TIER-NAME(TIER-IDX) TO WS-CURRENT-TIER
           END-SEARCH.

       8200-POST-LEDGER-ENTRY.
           MOVE 0 TO WS-WON-FLAG
           IF GAME-STATUS-WON
               MOVE 1 TO WS-WON-FLAG
           END-IF
           IF DB-CALL-OK
               CALL "db_record_run" USING BY REFERENCE
                   WS-ACCOUNT-ID LEDGER-BALANCE LEDGER-OVERDRAFTS
                   WS-CURRENT-TIER WS-WON-FLAG WS-DB-RC
               CALL "db_account_summary" USING BY REFERENCE
                   WS-ACCOUNT-ID WS-RUNS-PLAYED
                   WS-BEST-BALANCE WS-TOTAL-OVERDRAFTS WS-DB-RC
               CALL "db_shutdown"
           END-IF.

       8300-PRINT-STATEMENT.
           EVALUATE TRUE
               WHEN GAME-STATUS-WON
                   DISPLAY "JUMPRUN-000 ACCOUNT SETTLED - LEVEL DONE"
               WHEN OTHER
                   DISPLAY "JUMPRUN-000 SESSION TERMINATED"
           END-EVALUATE
           DISPLAY "JUMPRUN-000 THIS SESSION BALANCE: " LEDGER-BALANCE
           DISPLAY "JUMPRUN-000 THIS SESSION OD CHARGES:"
               LEDGER-OVERDRAFTS
           DISPLAY "JUMPRUN-000 ACCOUNT TIER:         " WS-CURRENT-TIER
           IF DB-CALL-OK
               DISPLAY "JUMPRUN-000 --- ACCOUNT STATEMENT (LEDGER) ---"
               DISPLAY "JUMPRUN-000 SESSIONS PLAYED TO DATE: "
                   WS-RUNS-PLAYED
               DISPLAY "JUMPRUN-000 BEST BALANCE ON RECORD:  "
                   WS-BEST-BALANCE
               DISPLAY "JUMPRUN-000 LIFETIME OVERDRAFTS:     "
                   WS-TOTAL-OVERDRAFTS
           END-IF.
