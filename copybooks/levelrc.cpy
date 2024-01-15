      ******************************************************************
      * LEVELRC : LR-TYPE-tagged union, one shape, three readings.
      *   'C' coin (F1,F2 = x,y)   'G' goal (F1..F4 = x,y,w,h)
      *   'T' tier (F1 = threshold, LR-NAME = name)
      ******************************************************************
       01  LEVEL-RECORD.
           05  LR-TYPE             PIC X(1).
           05  LR-F1               PIC S9(4) SIGN LEADING SEPARATE.
           05  LR-F2               PIC S9(4) SIGN LEADING SEPARATE.
           05  LR-F3               PIC S9(4) SIGN LEADING SEPARATE.
           05  LR-F4               PIC S9(4) SIGN LEADING SEPARATE.
           05  LR-NAME             PIC X(10).
