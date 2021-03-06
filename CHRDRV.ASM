; ********************************
; * Course project in discipline *
; * "Computer Archichtecture"    *
; *                              *
; * Copyright (c) 2000           *
; * by Momchil Hristov Minchev   *
; ********************************

        .8086
        .MODEL COMPACT
        .CODE
        ORG     100H

; ----- MACROS ------------------------------------------------------------

PUSHR   MACRO REG_LST
        IRP   REG, <REG_LST>
              PUSH REG
              ENDM
        ENDM

POPR    MACRO REG_LST
        IRP   REG, <REG_LST>
              POP REG
              ENDM
        ENDM

; ----- TSR PART ----------------------------------------------------------

BEGIN:  JMP     START

INCLUDE CYRILLIC.INC

_STD    DB      "`~@#$^&*()_=+\|qQwWeErRtTyYuUiIoOpP[{]}aAsSdDfFgGhHjJkKlL"
        DB      3BH, ":'", 22H, "zZxXcCvVbBnNmM,<.>/?", 0
_PHN    DB      "чЧ@#$^&*()_эЭюЮяЯвВеЕрРтТъЪуУиИоОпПшШщЩаАсСдДфФгГхХйЙкКлЛ"
        DB      3BH, ":'", 22H, "зЗьЬцЦжЖбБнНмМ,<.>ыЫ", 0
_BDS    DB      "()?+", 22H, "=:/_№I.V\|,ыуУеЕиИшШщЩкКсСдДзЗцЦ", 3BH, "§ьЬ"
        DB      "яЯаАоОжЖгГтТнНвВмМчЧюЮйЙъЪэЭфФхХпПрРлЛбБ", 0
_LN     DB      0DH, 0AH, '$'

_STDSTR DB      " STANDART "
_CYRSTR DB      " CYRILLIC "
_ST2STR DB      " STD KEYB "
_CY2STR DB      " CYR KEYB "
_PHNSTR DB      " PHONETIC "
_BDSSTR DB      " BDS      "
_STRBUF DB      20 DUP(?)

_PRS    DB      0                                ; SPECIAL KEY PRESSED
_LAYOUT DB      0                                ; ALT/STD LAYOUT FLAG
_KEYBRD DB      0                                ; STD/CYR KEYBOARD FLAG
_ORDER  DB      0                                ; PHN/BDS KEYBOARD FLAG
_DRAWF  DB      0                                ; DRAW FLAG
_REDRAW DB      0                                ; RESTORE DRAW FLAG
_COL    DB      ?                                ; COLUMNS FOR DEFAULT MODE

TSR_CS          DW      ?                        ; ORIGINAL CS


INT09H          LABEL   DWORD                    ; ORIGINAL ADDRESSES OF
INT09_OFS       DW      ?                        ; INT 09H
INT09_SEG       DW      ?                        ; AND
INT10H          LABEL   DWORD
INT10_OFS       DW      ?                        ; INT 10H
INT10_SEG       DW      ?

SETFONT PROC    FAR
        PUSHR   <AX, BX, CX, DX, ES, BP>
        MOV     AH, _LAYOUT
        OR      AH, AH
        JNZ     @CYR
        MOV     AX, CS
        MOV     ES, AX
        LEA     BP, FONT
        JMP     SHORT @CLINT
@CYR:   MOV     AX, 1130H
        MOV     BH, 06H
        PUSHF
        CALL    INT10H
@CLINT: MOV     AX, 1100H
        MOV     CX, 256
        XOR     DX, DX
        MOV     BX, 1000H
        PUSHF
        CALL    INT10H
        POPR    <BP, ES, DX, CX, BX, AX>
        RET
SETFONT ENDP

SETKEYB PROC    FAR
        PUSH    SI
        XOR     AX, AX                           ; GET ADDRESS OF
        MOV     ES, AX                           ; LAST PRESSED KEY
        MOV     BX, ES:[41CH]
        CMP     BX, ES:[480H]
        JNE     @SET1
        MOV     BX, ES:[482H]
@SET1:  ADD     BX, 3FEH
        MOV     AX, ES:[BX]
        MOV     DX, BX

        LEA     BX, _STD
        XOR     SI, SI
@S1:    MOV     CL, CS:[BX+SI]
        CMP     CL, AL
        JE      @S2
        OR      CL, CL
        JZ      @S4
        INC     SI
        JMP     SHORT @S1

@S2:    LEA     BX, _PHN
        MOV     CL, _ORDER
        OR      CL, CL
        JZ      @S3
        LEA     BX, _BDS

@S3:    MOV     AL, CS:[BX+SI]
        MOV     BX, DX
        MOV     WORD PTR ES:[BX], AX

@S4:    POP     SI
        RET
SETKEYB ENDP

VADDR   PROC    FAR
        PUSH    DX                               ; GET VIDEO ADDR OF
        MOV     AL, _COL                         ; DL:DH
        MUL     DH
        MOV     BX, AX
        XOR     DH, DH
        ADD     BX, DX
        SHL     BX, 1
        POP     DX
        RET
VADDR   ENDP

DRAWSTR PROC    FAR
        PUSHR   <AX, ES>
        CLI
        MOV     AX, 0B800H
        MOV     ES, AX
        LEA     DI, _STRBUF
        MOV     AH, 0FH
        PUSHF
        CALL    INT10H
        MOV     _COL, AH
        MOV     AH, 03H
        PUSHF
        CALL    INT10H
        MOV     AH, _COL

        SUB     AH, 0AH
        CMP     DL, AH
        JBE     @VDR
        MOV     DL, AH
@VDR:   MOV     CX, 10

        MOV     BH, _DRAWF
        OR      BH, BH
        JZ      @REST1

        MOV     BH, _REDRAW
        OR      BH, BH
        JNZ     @VOUT1
@V1:    CALL    VADDR
        MOV     AX, ES:[BX]
        MOV     CS:[DI], AX
        MOV     AH, CS:[SI]
        MOV     BYTE PTR ES:[BX], AH
        MOV     BYTE PTR ES:[BX+1], 071H
        INC     DL
        INC     SI
        INC     DI
        INC     DI
        LOOP    @V1
        NOT     _REDRAW
        JMP     @VOUT1

@REST1: MOV     BH, _REDRAW
        OR      BH, BH
        JZ      @VOUT1
        MOV     CX, 10
@V2:    CALL    VADDR
        MOV     AX, CS:[DI]
        MOV     WORD PTR ES:[BX], AX
        INC     DL
        INC     DI
        INC     DI
        LOOP    @V2
        NOT     _REDRAW
@VOUT1: POPR    <ES, AX>
        STI
        RET
DRAWSTR ENDP

INT09   PROC    FAR
        PUSHR   <AX, BX, CX, DX, SI, DI, ES, BP>

        CLI
        PUSHF
        CALL    INT09H

        XOR     AX, AX
        MOV     ES, AX
        MOV     BH, 02H
        MOV     AH, ES:[417H]
        CMP     AH, _PRS
        JE      @P3
        MOV     _PRS, AH
        MOV     _DRAWF, 0

        TEST    AH, BH                           ; LEFT SHIFT PRESSED?
        JZ      @P3                              ; NO

        SHR     BH, 1
        TEST    AH, BH                           ; RIGHT SHIFT PRESSED?
        JZ      @P1
        NOT     _LAYOUT
        LEA     SI, _STDSTR
        MOV     AL, _LAYOUT
        OR      AL, AL
        JZ      @L_1
        LEA     SI, _CYRSTR
@L_1:   NOT     _DRAWF
        CALL    SETFONT                          ; SET FONT
        JMP     @P3
@P1:    SHL     BH, 2
        TEST    AH, BH                           ; LSHIFT-CTRL PRESSED?
        JZ      @P2
        NOT     _ORDER
        LEA     SI, _PHNSTR
        MOV     AL, _ORDER
        OR      AL, AL
        JZ      @L_2
        LEA     SI, _BDSSTR
@L_2:   NOT     _DRAWF
        JMP     @P3
@P2:    SHL     BH, 1                            ; LSHIFT-ALT PRESSED?
        TEST    AH, BH
        JZ      @P3
        NOT     _KEYBRD
        LEA     SI, _ST2STR
        MOV     AL, _KEYBRD
        OR      AL, AL
        JZ      @L_3
        LEA     SI, _CY2STR
@L_3:   NOT     _DRAWF

@P3:    CALL    DRAWSTR

@POUT:  MOV     AH, _KEYBRD
        OR      AH, AH
        JZ      @P4
        CALL    SETKEYB
@P4:    POPR    <BP, ES, DI, SI, DX, CX, BX, AX>
        STI
        IRET
INT09   ENDP

INT10   PROC    FAR
        CLI
        CMP     AX, 0BEBEH                       ; RETURN TSR INFO
        JNE     @RINST
        MOV     DS, TSR_CS
        MOV     ES, AX
        MOV     AX, INT09_SEG
        MOV     BX, INT09_OFS
        MOV     CX, INT10_SEG
        MOV     DX, INT10_OFS
        JMP     @I10W

@RINST: PUSHF
        CALL    INT10H
        PUSH    AX
        OR      AH, AH
        JNZ     @I10E
        CMP     AL, 03H
        JBE     @I10Q
        CMP     AL, 07H
        JE      @I10Q
        JMP     SHORT @I10E
@I10Q:  CALL    SETFONT
@I10E:  POP     AX
@I10W:  STI
        IRET
INT10   ENDP

; ----- PROGRAM -----------------------------------------------------------

START:  JMP     @SUXX

_CPRGT  DB      "CHRDRV (c) 2000 by Momchil Hristov Minchev", 0DH, 0AH
        DB      "Cyrillic keyboard driver and font manager", 0DH, 0AH, 0AH
        DB      "Support VGA video adapters", 0DH, 0AH, '$'
_HELP   DB      "Syntax: chrdrv.com [<d:>][<path>][<file>.chr] [-b] [-u]"
        DB      0DH, 0AH, "  <file>.chr - character file"
        DB      0DH, 0AH, "  -b - BDS keyboard (default is phonetic)"
        DB      0DH, 0AH, "  -u - unload driver"
        DB      0DH, 0AH, "  -? - this screen", 0AH
        DB      0DH, 0AH, " [Left-Shift]+[Right-Shift] - switch fonts"
        DB      0DH, 0AH, " [Left-Shift]+[Alt] - switch keyboards"
        DB      0DH, 0AH, " [Left-Shift]+[Ctrl] - phonetic/BDS", 0AH, '$'

_ERR    DB      "ERROR: Unrecognized parameters!$"
        DB      "ERROR: Wrong or missing file specification!$"
        DB      "ERROR: Your video adapter is not VGA!$"
        DB      "ERROR: File corrupted or less then 4096 bytes!$"
_ERRMSG DB      32, 76, 114

_UN_NO  DB      "CHRDRV not resident!$"
_UN_AL  DB      "CHRDRV already loaded!$"
_UN_CU  DB      "CHRDRV can't be unloaded because another TSR!$"
_UN_UN  DB      "CHRDRV unloaded!$"

_FILENM DW    0                                  ; OFFSET FOR FILE NAME
_UNLOAD DB    0                                  ; UNLOAD FLAG
_HELPF  DB    0

@SUXX:  LEA     DX, _CPRGT                       ; COPYRIGHT
        CALL    PRINTLN

        MOV     DL, 1CH                          ; CHECK FOR VGA
        MOV     AH, DL
        XOR     AL, AL
        MOV     CX, 1
        INT     10H
        CMP     AL, DL
        JE      @DOIT                            ; SUPPORTED?
        MOV     BL, _ERRMSG+1                    ; NO
        CALL    ERROR

@DOIT:  PUSH    DS                               ; NORMALIZE PARAMETERS
        MOV     AX, 1211H
        MOV     BX, ES
        MOV     DS, BX
        MOV     SI, 81H
        MOV     DI, SI
        INT     2FH
        POP     DS

        XOR     BX, BX                           ; PROCESS PARAMETERS
        MOV     SI, BX
@@1:    MOV     AL, ES:[BX+81H]
        CMP     AL, 0DH                          ; LAST PARAM?
        JE      @@3                              ; YES
        CMP     AL, 20H                          ; NEW PARAM?
        JNE     @@2                              ; NO
        INC     SI                               ; SI -> COUNT OF PARAMS
        CALL    PRMTR
@@2:    INC     BX
        JMP     SHORT @@1                        ; END OF PARAMSTR?

@@3:    MOV     DH, _HELPF
        OR      DH, DH
        JNZ     @HELP
        JMP     @@4

@HELP:  LEA     DX, _HELP
        CALL    PRINTLN
        JMP     @QUIT
@LDR2:  LEA     DX, _UN_NO
        CALL    PRINTLN
        JMP     @QUIT

@@4:    MOV     DX, _FILENM
        OR      DX, DX
        JZ      @@5
        CALL    LOADCHR
@@5:    PUSHR   <DS, ES>
        XOR     AX, AX
        MOV     DS, AX
        MOV     ES, AX
        MOV     AX, 0BEBEH
        INT     10H
        MOV     INT09_SEG, AX
        MOV     INT09_OFS, BX
        MOV     INT10_SEG, CX
        MOV     INT10_OFS, DX
        MOV     TSR_CS, DS
        MOV     CX, ES
        POPR    <ES, DS>
        MOV     DL, _UNLOAD
        OR      DL, DL
        JZ      @LOAD
        JMP     @UNLD

@LOAD:  CMP     CX, 0BEBEH
        JNE     @NLOAD                           ; LOADED?
        LEA     DX, _UN_AL
        CALL    PRINTLN
        JMP     @QUIT

@NLOAD: MOV     AX, CS                           ; INIT TSR
        MOV     TSR_CS, AX
        CLI
        MOV     AH, 4AH                          ; CHANGE TSR BLOCK SIZE
        MOV     BX, 512
        INT     21H

        MOV     AX, ES:[2CH]                     ; FREE THE BLOCK,
        MOV     ES, AX                           ; ALLOCATED FOR
        MOV     AH, 49H                          ; ENVIRONMENT
        INT     21H

        MOV     AX, 3509H                        ; GET INT 09H
        INT     21H                              ; CURRENT ADDRESS
        MOV     INT09_SEG, ES
        MOV     INT09_OFS, BX

        MOV     AX, 3510H                        ; GET INT 10H
        INT     21H                              ; CURRENT ADDRESS
        MOV     INT10_SEG, ES
        MOV     INT10_OFS, BX

        MOV     AX, 2509H                        ; REDIRECT INT09H
        LEA     DX, INT09
        INT     21H

        MOV     AX, 2510H                        ; REDIRECT INT10H
        LEA     DX, INT10
        INT     21H

        CALL    SETFONT                          ; INIT FONT

        LEA     DX, START                        ; TERMINATE AND STAY
        INT     27H                              ; RESIDENT

@UNLD:  CMP     CX, 0BEBEH
        JE      @LDR1
        JMP     @LDR2
@LDR1:  MOV     AX, 3509H                        ; CHECK IF @INT09H=@TSR
        INT     21H
        MOV     AX, ES
        CMP     AX, TSR_CS
        JE      @OKU1
        LEA     DX, _UN_CU
        CALL    PRINTLN
        JMP     @QUIT

        MOV     AX, 3510H                        ; CHECK IF @INT10H=@TSR
        INT     21H
        MOV     AX, ES
        CMP     AX, TSR_CS
        JE      @OKU1
        LEA     DX, _UN_CU
        CALL    PRINTLN
        JMP     @QUIT

@OKU1:  PUSH    DS
        MOV     AX, 2509H
        MOV     DS, INT09_SEG
        MOV     DX, INT09_OFS
        INT     21H
        MOV     AX, 2510H
        MOV     DS, INT10_SEG
        MOV     DX, INT10_OFS
        INT     21H
        POP     DS

        MOV     ES, TSR_CS                       ; FREE THE BLOCK ALLOCATED
        MOV     AH, 49H                          ; FOR TSR
        INT     21H

        MOV     AX, 1130H                        ; RETURN ORIGINAL
        MOV     BH, 06H                          ; FONT
        INT     10H
        MOV     AX, 1100H
        MOV     CX, 256
        XOR     DX, DX
        MOV     BX, 1000H
        INT     10H

        STI
        LEA     DX, _UN_UN
        CALL    PRINTLN

@QUIT:  STI
        MOV     AX, 4C00H
        INT     21H

; ----- SUBROUTINES -------------------------------------------------------

PRINTLN PROC    NEAR
        PUSHR   <AX, BX, SI, DX>
        XOR     SI, SI
        MOV     AH, 09H
        LEA     DX, _LN
        INT     21H
        POP     BX
        MOV     AH, 0EH
@WRITE: MOV     AL, BYTE PTR DS:[BX+SI]
        CMP     AL, '$'
        JE      @WOUT1
        INC     SI
        INT     10H
        JMP     SHORT @WRITE
@WOUT1: POPR    <SI, BX, AX>
        RET
PRINTLN ENDP

ERROR   PROC    NEAR
        XOR     BH, BH
        LEA     DX, _ERR+BX
        CALL    PRINTLN
        MOV     AX, 4C01H
        INT     21H
        RET
ERROR   ENDP

PRMTR   PROC    NEAR
        PUSHR   <AX, BX, DX>
        INC     BX
        MOV     AL, ES:[BX+81H]
        CMP     AL, '-'
        JE      @OPT
        MOV     DX, _FILENM                      ; GET FIRST NOT BEGINNING WITH
        OR      DX, DX                           ; '-' PARAMETER FOR FILE NAME
        JNZ     @ERR1
        MOV     _FILENM, BX                      ; _FILENM <- PARAM OFFSET
        JMP     SHORT @FLOUT
@OPT:   CMP     BYTE PTR ES:[BX+83H], 20H        ; PARAM LENGTH > 2
        JBE     @OP_B                            ; NO
@ERR1:  XOR     BX, BX
        CALL    ERROR                            ; UNRECOGNIZED
@OP_B:  MOV     AL, ES:[BX+82H]
        CMP     AL, 'B'                          ; UNLOAD
        JNE     @OP_U
        NOT     _ORDER                           ; SET BDS KEYBOARD
        JMP     SHORT @FLOUT
@OP_U:  CMP     AL, 'U'
        JNE     @OP_H
        NOT     _UNLOAD
        JMP     SHORT @FLOUT
@OP_H:  CMP     AL, '?'
        JNE     @ERR1
        NOT     _HELPF
@FLOUT: POPR    <DX, BX, AX>
        RET
PRMTR   ENDP

LOADCHR PROC    NEAR
        MOV     BX, _FILENM
        PUSH    BX
@LOP1:  MOV     AL, ES:[BX+81H]
        CMP     AL, 20H
        JA      @LOP2
        MOV     BYTE PTR ES:[BX+81H], 0
        JMP     SHORT @LOP3
@LOP2:  INC     BX
        JMP     SHORT @LOP1
@LOP3:  POP     DX
        ADD     DX, 81H
        MOV     AX, 3D00H
        INT     21H
        JNC     @LOP4
@ERR2:  MOV     BL, _ERRMSG
        CALL    ERROR
@LOP4:  MOV     BX, AX
        MOV     AH, 3FH
        MOV     CX, 1000H
        LEA     DX, FONT
        INT     21H
        JNC     @LOP5
@ERR3:  MOV     BL, _ERRMSG+2
        CALL    ERROR
@LOP5:  CMP     AX, CX
        JB      @ERR3
        MOV     AH, 3EH
        INT     21H
        JC      @ERR2
        RET
LOADCHR ENDP

        END     BEGIN