      ******************************************************************
      * LEVELTB : pickups, goal, tier schedule. Geometry itself is the
      * mask image, not a table - see csrc/sdlshim.c sdl_mask_solid.
      ******************************************************************
       01  WS-COIN-TABLE.
           05  COIN-ENTRY OCCURS 8 TIMES INDEXED BY COIN-IDX.
               10  COIN-X          PIC S9(9) COMP-5.
               10  COIN-Y          PIC S9(9) COMP-5.
               10  COIN-COLLECTED  PIC 9(1)  COMP-5.
                   88  COIN-IS-COLLECTED       VALUE 1.
       01  WS-COIN-COUNT           PIC 9(4)  COMP-5 VALUE 0.

       01  WS-GOAL.
           05  GOAL-X              PIC S9(9) COMP-5.
           05  GOAL-Y              PIC S9(9) COMP-5.
           05  GOAL-W              PIC S9(9) COMP-5 VALUE 40.
           05  GOAL-H              PIC S9(9) COMP-5 VALUE 96.

      * tier(balance) := name of last entry with threshold <= balance,
      * entries descending, found by 8100-REPORT-TIER's linear SEARCH.
       01  WS-TIER-TABLE.
           05  TIER-ENTRY OCCURS 6 TIMES INDEXED BY TIER-IDX.
               10  TIER-THRESHOLD  PIC S9(9) COMP-5.
               10  TIER-NAME       PIC X(10).
       01  WS-TIER-COUNT           PIC 9(4)  COMP-5 VALUE 0.
