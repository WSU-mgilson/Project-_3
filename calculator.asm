; CEG 3310 Project 3 - Calculator
; Subroutines: GETNUM, GETOP, CALC, DISPLAY
; Registers are used for inputs/outputs (no stack)

        .ORIG x3000

; ------------- main loop -------------
START
        LEA R0, PROMPT1
        PUTS
        JSR GETNUM          ; R0 = first number
        ST R0, NUM1

        LEA R0, PROMPT2
        PUTS
        JSR GETOP           ; R0 = operation
        ST R0, OPER

        LEA R0, PROMPT3
        PUTS
        JSR GETNUM          ; R0 = second number
        ADD R1, R0, #0      ; R1 = second number
        LD R0, NUM1         ; R0 = first number
        LD R2, OPER         ; R2 = operation
        JSR CALC            ; R0 = result
        ST R0, RESULT

        LEA R0, RESULTMSG
        PUTS
        LD R0, RESULT
        JSR DISPLAY
        LD R0, NEWLINE
        OUT

        BRnzp START          ; do it again forever

; ------------- GETNUM -------------
; gets a number 0-99 from keyboard, returns it in R0
GETNUM
        ST R7, SAVE_R7_NUM  ; save R7 because GETC/OUT change it

        GETC                ; first digit
        OUT
        LD R1, NEG_ZERO
        ADD R2, R0, R1      ; R2 = first digit as number

        GETC                ; second digit (or enter)
        OUT
        ADD R3, R0, #-10    ; was it enter?
        BRz NUM_END
        ADD R3, R0, #-13
        BRz NUM_END

        LD R1, NEG_ZERO
        ADD R1, R0, R1      ; R1 = second digit as number

        ; R2 = R2 * 10
        ADD R3, R2, R2      ; x2
        ADD R3, R3, R3      ; x4
        ADD R3, R3, R2      ; x5
        ADD R3, R3, R3      ; x10
        ADD R2, R3, R1      ; add second digit

        LD R0, NEWLINE
        OUT
NUM_END
        ADD R0, R2, #0      ; put answer in R0
        LD R7, SAVE_R7_NUM
        RET

; ------------- GETOP -------------
; gets + - or * from keyboard, returns it in R0
GETOP
        ST R7, SAVE_R7_OP
OP_AGAIN
        GETC
        OUT
        ADD R3, R0, #0      ; copy of the character

        LD R1, NEG_PLUS
        ADD R2, R3, R1
        BRz OP_GOOD

        LD R1, NEG_MINUS
        ADD R2, R3, R1
        BRz OP_GOOD

        LD R1, NEG_STAR
        ADD R2, R3, R1
        BRz OP_GOOD

        BRnzp OP_AGAIN      ; bad key so try again
OP_GOOD
        LD R0, NEWLINE
        OUT
        ADD R0, R3, #0
        LD R7, SAVE_R7_OP
        RET

; ------------- CALC -------------
; R0 = first number, R1 = second number, R2 = operation
; result is returned in R0
CALC
        LD R3, NEG_PLUS
        ADD R3, R2, R3
        BRz DO_ADD

        LD R3, NEG_MINUS
        ADD R3, R2, R3
        BRz DO_SUB

        ; if not + or - then it is multiply
        AND R3, R3, #0      ; total = 0
MULT_LOOP
        ADD R1, R1, #0
        BRz MULT_DONE
        ADD R3, R3, R0
        ADD R1, R1, #-1
        BRnzp MULT_LOOP
MULT_DONE
        ADD R0, R3, #0
        RET

DO_ADD
        ADD R0, R0, R1
        RET

DO_SUB
        NOT R1, R1
        ADD R1, R1, #1      ; R1 = -R1
        ADD R0, R0, R1
        RET

; ------------- DISPLAY -------------
; R0 = number to print (can be negative, up to 4 digits)
DISPLAY
        ST R7, SAVE_R7_DISP
        ADD R1, R0, #0      ; R1 = the number
        BRzp DISP_START
        LD R0, MINUS        ; negative so print a minus sign
        OUT
        NOT R1, R1
        ADD R1, R1, #1      ; make it positive

DISP_START
        AND R4, R4, #0      ; R4 = 0 until we print a digit

        ; ---- thousands place ----
        AND R0, R0, #0
        LD R3, NEG1000
THOU_LOOP
        ADD R2, R1, R3
        BRn THOU_DONE
        ADD R1, R2, #0
        ADD R0, R0, #1
        BRnzp THOU_LOOP
THOU_DONE
        ADD R0, R0, #0
        BRz HUND_START      ; skip leading zero
        LD R5, ASCII_ZERO
        ADD R0, R0, R5
        OUT
        ADD R4, R4, #1

        ; ---- hundreds place ----
HUND_START
        AND R0, R0, #0
        LD R3, NEG100
HUND_LOOP
        ADD R2, R1, R3
        BRn HUND_DONE
        ADD R1, R2, #0
        ADD R0, R0, #1
        BRnzp HUND_LOOP
HUND_DONE
        ADD R0, R0, #0
        BRp HUND_PRINT
        ADD R4, R4, #0
        BRz TENS_START      ; leading zero so skip
HUND_PRINT
        LD R5, ASCII_ZERO
        ADD R0, R0, R5
        OUT
        ADD R4, R4, #1

        ; ---- tens place ----
TENS_START
        AND R0, R0, #0
        LD R3, NEG10
TENS_LOOP
        ADD R2, R1, R3
        BRn TENS_DONE
        ADD R1, R2, #0
        ADD R0, R0, #1
        BRnzp TENS_LOOP
TENS_DONE
        ADD R0, R0, #0
        BRp TENS_PRINT
        ADD R4, R4, #0
        BRz ONES_START
TENS_PRINT
        LD R5, ASCII_ZERO
        ADD R0, R0, R5
        OUT

        ; ---- ones place (always print) ----
ONES_START
        LD R5, ASCII_ZERO
        ADD R0, R1, R5
        OUT

        LD R7, SAVE_R7_DISP
        RET

; ------------- data -------------
PROMPT1     .STRINGZ "Enter first number (0 - 99): "
PROMPT2     .STRINGZ "Enter an operation (+, -, *): "
PROMPT3     .STRINGZ "Enter second number (0 - 99): "
RESULTMSG   .STRINGZ "Result: "

NEWLINE     .FILL x000A
MINUS       .FILL x002D
ASCII_ZERO  .FILL x0030
NEG_ZERO    .FILL xFFD0     ; -x30
NEG_PLUS    .FILL xFFD5     ; -x2B
NEG_MINUS   .FILL xFFD3     ; -x2D
NEG_STAR    .FILL xFFD6     ; -x2A
NEG1000     .FILL #-1000
NEG100      .FILL #-100
NEG10       .FILL #-10

NUM1          .BLKW 1
OPER          .BLKW 1
RESULT        .BLKW 1
SAVE_R7_NUM   .BLKW 1
SAVE_R7_OP    .BLKW 1
SAVE_R7_DISP  .BLKW 1

        .END
