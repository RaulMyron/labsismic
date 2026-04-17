 .cdecls "msp430.h"
 .global main

 .data

matriz: 
    .word 1, 2, 3
    .word 4, 5, 6
    .word 7, 8, 9

 .text

main:
    mov.w   #(WDTPW|WDTHOLD), &WDTCTL
    mov #matriz, R12;R12 = ponteiro p matriz
    mov #2,  R13;R13 = row
    mov #3,  R14;R14 = col
    call #SUM_SUB
    jmp $; stop no finalll
    nop

; ----------------------------------------------------------
SUM_SUB:

    push R4  
    push R5;i
    push R6;j
    push R7
    push R8
    push R9
    push R10
    push R11
    mov R12, R4; ptr = mat
    mov R13, R11; salva linha antes de perder R13
    clr R7
    clr R8
    clr R9
    clr R10
    clr R5
    ; for (int i = 0; i < rows; i++)

LOOP_ROW: ; vms começar a percorrer por linhs 
    cmp R11, R5; i == rows?
    jeq END_LOOP
    clr R6
    ; for (int j = 0; j < cols; j++)

LOOP_COL: ; vmamos começar a percorrer por colunas 
    cmp R14, R6; j == cols?
    jeq NEXT_ROW

 ; if (i > 0 && j > 0) -> acum R12
    tst R5
    jeq SKIP_R7
    tst R6
    jeq SKIP_R7
    add @R4, R7;@R4 le sem mover o ponteiro (diferente de @R4+)

SKIP_R7:

    ; if (i > 0 && j < cols-1) -> acum R13
    tst R5
    jeq SKIP_R8
    mov R14, R15; R15 = cols-1 (usando R15 como temp, eh saida entao ok)
    dec R15
    cmp R15, R6; j == cols-1?
    jeq SKIP_R8
    add @R4, R8
SKIP_R8:

    ;if (i < rows-1 && j > 0) -> acum R14
    mov R11, R15; R15 = rows-1
    dec R15
    cmp R15, R5; i == rows-1?
    jeq SKIP_R9
    tst R6
    jeq SKIP_R9
    add @R4, R9
SKIP_R9:
    ;if (i < rows-1 && j < cols-1) -> acum R15
    mov R11, R15
    dec R15
    cmp R15, R5; i == rows-1?
    jeq SKIP_R10
    mov R14, R15
    dec R15
    cmp R15, R6 ; j == cols-1?
    jeq SKIP_R10
    add @R4, R10
SKIP_R10:

    incd R4; ptr += 2
    inc R6;: j++
    jmp LOOP_COL

NEXT_ROW:
    inc R5; i++
    jmp LOOP_ROW

END_LOOP:
    mov R7,  R12
    mov R8,  R13
    mov R9,  R14
    mov R10, R15

    pop R11
    pop R10
    pop R9
    pop R8
    pop R7
    pop R6
    pop R5
    pop R4

    ret
