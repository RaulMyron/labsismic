        .cdecls C,LIST,"msp430.h"
        .global main

        .data
vetor:    .word -10, 20, -500, 40, 50, 100
tamanho:  .word 6

        .text
main:
        MOV     #vetor,   R12
        MOV     &tamanho, R13
        CALL    #procura
        JMP     $

procura:
        PUSH    R4
        PUSH    R5
        PUSH    R6
        PUSH    R7

        MOV     R12,  R4
        MOV     R13,  R5
        MOV     @R4+, R6
        MOV     R6,   R7
        DEC     R5

loop:
        CMP     #0,   R5
        JEQ     fim
        MOV     @R4+, R14

        CMP     R14,  R6
        JGE     nao_eh_min
        MOV     R14,  R6
nao_eh_min:
        CMP     R7,   R14
        JL      nao_eh_maximo
        MOV     R14,  R7
nao_eh_maximo:
        DEC     R5
        JMP     loop

fim:
        MOV     R6, R12
        MOV     R7, R13
        POP     R7
        POP     R6
        POP     R5
        POP     R4
        RET

        .end
