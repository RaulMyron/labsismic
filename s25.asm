.cdecls "msp430.h"
        .global main
        .text

main:
        mov.w   #(WDTPW|WDTHOLD), &WDTCTL  ; desliga o watchdog (ele reseta o chip se nao fizer isso)
        mov     #matriz, R12        ; R12 = &matriz[0][0]  (em C++: int* ptr = matriz;)
        mov     #3,      R13        ; R13 = rows = 3
        mov     #3,      R14        ; R14 = cols = 3
        call    #SUM_SUB            ; chama a funcao, igual a:  SUM_SUB(ptr, rows, cols);
        jmp     $                   ; trava aqui pra sempre (sem isso o PC sai voando pela memoria)
        nop                         ; NOP apos JMP por causa de errata do silicio do MSP430

; ===========================================================
; SUM_SUB(int* mat, int rows, int cols)
;
; em C++ seria mais ou menos:
;   void SUM_SUB(short* mat, int rows, int cols,
;                int& r12, int& r13, int& r14, int& r15)
;   {
;       r12 = r13 = r14 = r15 = 0;
;       for (int i = 0; i < rows; i++)
;           for (int j = 0; j < cols; j++) {
;               short v = mat[i*cols + j];
;               if (i > 0        && j > 0       ) r12 += v;
;               if (i > 0        && j < cols - 1) r13 += v;
;               if (i < rows - 1 && j > 0       ) r14 += v;
;               if (i < rows - 1 && j < cols - 1) r15 += v;
;           }
;   }
;
; Entradas: R12=ponteiro, R13=rows, R14=cols
; Saídas:   R12, R13, R14, R15 com as 4 somas
;
; R4-R11 sao callee-saved (a gente que tem que salvar/restaurar)
; R12-R15 sao os retornos entao nao precisam ser salvos
; ===========================================================
SUM_SUB:
        ; --- salvar tudo que vamos usar (convencao: R4-R11 sao nossos pra usar, mas temos que devolver) ---
        ; tipo um "emprestimo" da pilha
        push    R4                  ; vai guardar o ponteiro corrente (ptr)
        push    R5                  ; vai ser o i (linha atual)
        push    R6                  ; vai ser o j (coluna atual)
        push    R7                  ; acumulador do resultado R12
        push    R8                  ; acumulador do resultado R13
        push    R9                  ; acumulador do resultado R14
        push    R10                 ; acumulador do resultado R15
        push    R11                 ; vai salvar rows (porque R13 vai ser sobrescrito no retorno)

        ; --- copiar parametros antes de perder ---
        ; R12 e R14 podemos usar direto por enquanto
        ; mas R13 (rows) vai virar saida no final, entao salvamos em R11
        mov     R12, R4             ; R4 = ptr  (em C++: short* ptr = mat;)
        mov     R13, R11            ; R11 = rows (backup! R13 vai ser destruido no fim)
        ; R14 = cols (fica em R14 mesmo por enquanto)

        ; --- zerar os 4 acumuladores (em C++: int acc0=0, acc1=0, acc2=0, acc3=0;) ---
        clr     R7                  ; acum pra R12 = 0
        clr     R8                  ; acum pra R13 = 0
        clr     R9                  ; acum pra R14 = 0
        clr     R10                 ; acum pra R15 = 0

        ; =========================================================
        ; for (int i = 0; i < rows; i++)
        ; =========================================================
        clr     R5                  ; i = 0
LOOP_ROW:
        cmp     R11, R5             ; i == rows? (em C++: i < rows virou negacao: pula se i==rows)
        jeq     END_LOOP            ; sim -> acabou o loop externo

        ; =========================================================
        ;     for (int j = 0; j < cols; j++)
        ; =========================================================
        clr     R6                  ; j = 0
LOOP_COL:
        cmp     R14, R6             ; j == cols?
        jeq     NEXT_ROW            ; sim -> proxima linha

        ; nesse ponto: R4 aponta pra mat[i][j]
        ; em C++ seria: short v = mat[i*cols + j];
        ; mas aqui nao precisamos multiplicar! o ponteiro ja avanca sozinho (incd R4 no fim)

        ; ---------------------------------------------------------
        ; if (i > 0 && j > 0)  R7 += mat[i][j]
        ; ou seja: nao eh primeira linha E nao eh primeira coluna
        ; ---------------------------------------------------------
        tst     R5                  ; i == 0? (TST faz CMP com 0, seta flags)
        jeq     SKIP_R7             ; eh primeira linha -> pula
        tst     R6                  ; j == 0?
        jeq     SKIP_R7             ; eh primeira coluna -> pula
        add     @R4, R7             ; R7 += *ptr  (@R4 = leitura indireta, sem mover o ponteiro)
SKIP_R7:

        ; ---------------------------------------------------------
        ; if (i > 0 && j < cols-1)  R8 += mat[i][j]
        ; nao eh primeira linha E nao eh ULTIMA coluna
        ; ---------------------------------------------------------
        tst     R5                  ; i == 0?
        jeq     SKIP_R8
        mov     R14, R15            ; R15 = cols  (usando R15 como temp aqui, ok pois eh saida)
        dec     R15                 ; R15 = cols - 1
        cmp     R15, R6             ; j == cols-1?
        jeq     SKIP_R8             ; eh ultima coluna -> pula
        add     @R4, R8
SKIP_R8:

        ; ---------------------------------------------------------
        ; if (i < rows-1 && j > 0)  R9 += mat[i][j]
        ; nao eh ULTIMA linha E nao eh primeira coluna
        ; ---------------------------------------------------------
        mov     R11, R15            ; R15 = rows
        dec     R15                 ; R15 = rows - 1
        cmp     R15, R5             ; i == rows-1?
        jeq     SKIP_R9             ; eh ultima linha -> pula
        tst     R6                  ; j == 0?
        jeq     SKIP_R9
        add     @R4, R9
SKIP_R9:

        ; ---------------------------------------------------------
        ; if (i < rows-1 && j < cols-1)  R10 += mat[i][j]
        ; nao eh ultima linha E nao eh ultima coluna
        ; (canto superior esquerdo da matriz, excluindo bordas do fim)
        ; ---------------------------------------------------------
        mov     R11, R15            ; R15 = rows
        dec     R15                 ; R15 = rows - 1
        cmp     R15, R5             ; i == rows-1?
        jeq     SKIP_R10
        mov     R14, R15            ; R15 = cols
        dec     R15                 ; R15 = cols - 1
        cmp     R15, R6             ; j == cols-1?
        jeq     SKIP_R10
        add     @R4, R10
SKIP_R10:

        ; --- avanca ponteiro e coluna ---
        incd    R4                  ; ptr += 2  (word = 2 bytes, igual a ptr++ em C++ com short*)
        inc     R6                  ; j++
        jmp     LOOP_COL

NEXT_ROW:
        inc     R5                  ; i++
        jmp     LOOP_ROW

END_LOOP:
        ; --- mover acumuladores pros registradores de saida ---
        ; em C++: return {acc0, acc1, acc2, acc3};
        ; assembly nao tem "return multiplo", entao a convencao eh usar R12-R15
        mov     R7,  R12            ; resultado final R12
        mov     R8,  R13            ; resultado final R13
        mov     R9,  R14            ; resultado final R14
        mov     R10, R15            ; resultado final R15

        ; --- restaurar pilha NA ORDEM INVERSA do push (LIFO!) ---
        ; se errar a ordem aqui, os registradores voltam com valores trocados -> bug sutil
        pop     R11
        pop     R10
        pop     R9
        pop     R8
        pop     R7
        pop     R6
        pop     R5
        pop     R4

        ret                         ; PC = endereco de retorno (que estava no topo da pilha)

; ===========================================================
; dados na secao .data (memoria RAM inicializada)
; em C++: short matriz[3][3] = {{1,2,3},{4,5,6},{7,8,9}};
; na memoria fica flat: 0001 0002 0003 0004 0005 0006 0007 0008 0009
; ===========================================================
        .data
matriz: .word   1, 2, 3
        .word   4, 5, 6
        .word   7, 8, 9
