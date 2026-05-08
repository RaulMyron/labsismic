#include <msp430.h>

#define S1   BIT1   // P2.1
#define S2   BIT1   // P1.1
#define LED1 BIT0   // P1.0 – LED vermelho

// Estados das chaves
#define ABT 0  // Aberta
#define FEC 1  // Fechada

// ---- Debounce -------------------------------------------------------
void debounce(void) {
    volatile int aux = 20000;
    while (aux--);
}

// ---- Programa principal ---------------------------------------------
void main(void) {

    WDTCTL = WDTPW | WDTHOLD;

    // S1 (P2.1) – entrada com pull-up
    P2DIR &= ~S1;
    P2REN |=  S1;
    P2OUT |=  S1;

    // S2 (P1.1) – entrada com pull-up
    P1DIR &= ~S2;
    P1REN |=  S2;
    P1OUT |=  S2;

    // LED vermelho (P1.0) – saída, começa apagado
    P1DIR |=  LED1;
    P1OUT &= ~LED1;

    // Estados anteriores das chaves
    int ps1 = ABT;
    int ps2 = ABT;

    while (1) {

        // --- Verificar S1 ---
        if ((P2IN & S1) == 0) {      // S1 fechada agora
            if (ps1 == ABT) {        // Veio de aberta: A --> F
                debounce();
                P1OUT ^= LED1;       // Alterna o LED
                ps1 = FEC;
            }
            // se ps1 == FEC: F-->F, não faz nada
        } else {                     // S1 aberta agora
            if (ps1 == FEC) {        // Veio de fechada: F --> A
                debounce();
                ps1 = ABT;
            }
            // se ps1 == ABT: A-->A, não faz nada
        }

        // --- Verificar S2 ---
        if ((P1IN & S2) == 0) {      // S2 fechada agora
            if (ps2 == ABT) {        // A --> F
                debounce();
                P1OUT ^= LED1;       // Alterna o LED
                ps2 = FEC;
            }
        } else {                     // S2 aberta agora
            if (ps2 == FEC) {        // F --> A
                debounce();
                ps2 = ABT;
            }
        }
    }
}
