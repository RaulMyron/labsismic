  # Hello World — MSP430 Assembly no CCS

---

## 1. Criando o Projeto no CCS

1. `File → Create New Project`
2. No filtro, digite **F5529** e selecione a placa **MSPEXP430F5529LP**
3. Escolha o exemplo `MSP430F55xx_1.c` (LED piscando) como base
4. Renomeie a **pasta** do projeto (ex: `m1ex01`) pressionando **F2**
5. Renomeie o arquivo fonte de `.c` para `.asm` — ex: `m1ex01.asm`

> O CCS detecta automaticamente a extensão `.asm` e usa o montador em vez do compilador C.

---

## 2. Configurando o Memory Model → **Small**

Acesse as propriedades do projeto:

```
Botão direito na pasta do projeto → Properties
  Build → Tools → MSP430 Compiler → Processor Options
    Code model:  small
    Data model:  small
```

**Por que small?**  
O modelo *small* restringe o endereçamento a **16 bits** (primeira página de 64 KB).  
- Código (Flash) → até `0xFFFF`  
- RAM → começa em `0x2400`  
- Ponteiros e endereços cabem em 1 word → instruções mais simples, sem extensões de 20 bits (MSP430X)

---

## 3. Estrutura de Pastas no CCS

Após criar e compilar, o CCS gera automaticamente:

```
m1ex01/                    ← pasta raiz do projeto
├── m1ex01.asm             ← seu código fonte assembly
├── lnk_msp430f5529.cmd    ← linker script (gerado pelo CCS)
├── msp430.h               ← header com símbolos do chip (importado via .cdecls)
│
└── Debug/                 ← gerado no build
    ├── m1ex01.out         ← ELF binário (o que é gravado no chip)
    ├── m1ex01.map         ← mapa de memória (endereços de cada símbolo)
    └── m1ex01.asm         ← listagem assembly (se habilitada)
```

> **Não mexa** nos arquivos dentro de `Debug/` — eles são regenerados a cada build.

---

## 4. O Código — Hello World em Assembly

Em sistemas embarcados sem display, o "Hello World" clássico é **piscar o LED**.  
No MSP430F5529, o LED vermelho está no pino **P1.0**.

```asm
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
```

### Linha a linha — o que cada coisa faz

| Diretiva / Instrução | Significado |
|---|---|
| `.cdecls C,LIST,"msp430.h"` | Importa os `#define` do chip (ex: `WDTPW`, `BIT0`, `P1DIR`) |
| `.global main` | Exporta o símbolo `main` para o linker encontrar o entry point |
| `.text` | Tudo abaixo vai para a **Flash** (memória de programa) |
| `.data` | Tudo abaixo vai para a **RAM** (a partir de `0x2400`) |
| `MOV.W #WDTPW\|WDTHOLD, &WDTCTL` | Para o Watchdog — sem isso ele reseta o chip em ~32ms |
| `BIS.B #BIT0, &P1DIR` | Set bit 0 de P1DIR → pino P1.0 vira saída |
| `XOR.B #BIT0, &P1OUT` | Toggle do bit 0 → inverte o LED a cada iteração |
| `PUSH R4` / `POP R4` | R4–R11 são **callee-saved**: quem usa deve salvar/restaurar |
| `RET` | Retorna ao endereço salvo na pilha pelo `CALL` |

---

## 5. Rodando no CCS

```
1. Build:    CTRL + B   (ou botão ⚙️ "Build")
             → Sem erros: arquivo Debug/m1ex01.out gerado

2. Debug:    F11        (ou botão 🐛 "Debug")
             → CCS grava o .out no chip via USB e para no main

3. Run:      F8         (ou botão ▶ "Resume")
             → Programa executa → LED começa a piscar

4. Suspend:  F6         → Pausa para inspecionar registradores

5. Terminate: CTRL+F2  → Encerra sessão de debug
```

> **Dica:** Na view `Registers` você consegue acompanhar R4, SP, PC em tempo real enquanto executa passo a passo com **F6 (step over)** ou **F5 (step into)**.

---

## 6. Resumo do Fluxo

```
.asm  →  [Montador]  →  .obj  →  [Linker + .cmd]  →  .out (ELF)  →  [Gravador USB]  →  Flash do chip
```

O linker script `.cmd` é quem define **onde cada seção vai na memória**:  
- `.text` → Flash  
- `.data` → RAM (`0x2400`)  
- Stack → fim da RAM (`0x43FF` decrescendo)
