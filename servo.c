#include <msp430.h>

// pinos
#define MOTOR   BIT0    // P2.0 sai o PWM
#define S1      BIT1    // P2.1 botão que diminui
#define S2      BIT1    // P1.1 botão que aumenta

// limites do pulso (1 contagem = 1us porque SMCLK ta em ~1MHz)
#define PULSO_MIN     500    // 0,5 ms = 0 graus
#define PULSO_CENTRO 1500    // 1,5 ms = 90 graus
#define PULSO_MAX    2500    // 2,5 ms = 180 graus
#define PULSO_PASSO   100    // cada aperto mexe 0,1 ms

// janela de debounce: 50 ms (cabe num CCR0 de 16 bits a ~1MHz)
#define DEBOUNCE_TICKS 50000

// recebe angulo de 0 a 180 e joga no PWM
void set_servo_angulo(unsigned int angulo){
    if (angulo > 180) angulo = 180;
    unsigned int pulso = PULSO_MIN + ((unsigned long)angulo * (PULSO_MAX - PULSO_MIN)) / 180;
    TA1CCR1 = pulso;
}

// se preferir mexer direto no pulso em us
void set_servo_pulso_us(unsigned int pulso){
    if (pulso < PULSO_MIN) pulso = PULSO_MIN;
    if (pulso > PULSO_MAX) pulso = PULSO_MAX;
    TA1CCR1 = pulso;
}

// arma o cooldown e tira os dois botões do ar até o timer estourar
static inline void arma_debounce(void){
    P1IE &= ~S2;
    P2IE &= ~S1;
    TA0CTL = TASSEL__SMCLK | MC__UP | TACLR;    // liga e zera o timer
}

void main(void){
    WDTCTL = WDTPW | WDTHOLD;

    // timer A1 fazendo o PWM
    TA1CTL   = TASSEL__SMCLK | MC__UP | TACLR;
    TA1CCR0  = 20000 - 1;                       // periodo de 20 ms
    TA1CCTL1 = OUTMOD_7;                        // sobe no 0 e desce no CCR1
    TA1CCR1  = PULSO_CENTRO;                    // começa no meio (90 graus)

    // timer A0 fica de cooldown pro debounce, configurado mas parado
    TA0CCR0  = DEBOUNCE_TICKS - 1;
    TA0CCTL0 = CCIE;                            // libera interrupção do CCR0
    TA0CTL   = TASSEL__SMCLK;                   // MC=0, parado por enquanto

    // pino do servo
    P2DIR |=  MOTOR;
    P2SEL |=  MOTOR;

    // botão S1 (P2.1) - diminui
    P2DIR &= ~S1;
    P2REN |=  S1;
    P2OUT |=  S1;           // pull-up ligado
    P2IES |=  S1;           // começa esperando borda de descida (aperto)
    P2IFG &= ~S1;
    P2IE  |=  S1;

    // botão S2 (P1.1) - aumenta
    P1DIR &= ~S2;
    P1REN |=  S2;
    P1OUT |=  S2;
    P1IES |=  S2;
    P1IFG &= ~S2;
    P1IE  |=  S2;

    __bis_SR_register(GIE);

    for(;;){
        __no_operation();
    }
}

// botão S2 -> aumenta
#pragma vector = PORT1_VECTOR
__interrupt void Port1_ISR(void){
    if (P1IFG & S2){
        // se IES ta em descida (=1), foi um aperto de verdade -> faz a ação
        // se ta em subida (=0), foi a soltura -> ignora, só vira a borda
        if (P1IES & S2){
            if (TA1CCR1 + PULSO_PASSO <= PULSO_MAX){
                TA1CCR1 += PULSO_PASSO;
            } else {
                TA1CCR1 = PULSO_MAX;
            }
        }
        P1IES ^= S2;        // troca a borda esperada (descida <-> subida)
        P1IFG &= ~S2;
        arma_debounce();
    }
}

// botão S1 -> diminui
#pragma vector = PORT2_VECTOR
__interrupt void Port2_ISR(void){
    if (P2IFG & S1){
        if (P2IES & S1){
            if (TA1CCR1 >= PULSO_MIN + PULSO_PASSO){
                TA1CCR1 -= PULSO_PASSO;
            } else {
                TA1CCR1 = PULSO_MIN;
            }
        }
        P2IES ^= S1;
        P2IFG &= ~S1;
        arma_debounce();
    }
}

// timer do debounce estourou -> bounce já passou, reabilita tudo
#pragma vector = TIMER0_A0_VECTOR
__interrupt void Timer0_A0_ISR(void){
    TA0CTL = TASSEL__SMCLK;     // para o timer (MC=0)
    P1IFG &= ~S2;               // limpa flag que possa ter setado durante o cooldown
    P2IFG &= ~S1;
    P1IE  |=  S2;
    P2IE  |=  S1;
}
