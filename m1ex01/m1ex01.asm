; m1ex01.asm — Hello World MSP430 Assembly
; Pisca LED vermelho (P1.0) com delay por software

    .cdecls C,LIST,"msp430.h"   ; Importa símbolos do chip (WDTPW, P1DIR, etc.)
    .global main                 ; Exporta 'main' para o linker saber onde iniciar

    .text                        ; Código vai para a Flash (ROM)

main:
    MOV.W   #WDTPW|WDTHOLD, &WDTCTL  ; Desliga o Watchdog Timer
    BIS.B   #BIT0, &P1DIR             ; P1.0 = saída (configura o pino do LED)

loop:
    XOR.B   #BIT0, &P1OUT             ; Inverte o LED (toggle)
    CALL    #delay                    ; Chama subrotina de delay
    JMP     loop                      ; Laço infinito

; -------------------------------------------------------
; Subrotina: delay por software (~50ms @ 1MHz MCLK)
; Usa R4 (callee-saved → push/pop obrigatório)
; -------------------------------------------------------
delay:
    PUSH    R4                  ; Salva R4 (preservado por convenção)
    MOV.W   #50000, R4          ; Carrega contador

delay_loop:
    DEC     R4                  ; R4 = R4 - 1  →  seta flag Z se chegar a 0
    JNZ     delay_loop          ; Se Z=0, continua o loop

    POP     R4                  ; Restaura R4
    RET                         ; Retorna ao caller

    .data                       ; Variáveis na RAM (a partir de 0x2400)
    ; (neste exemplo não usamos variáveis em RAM)