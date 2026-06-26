
#include <msp430.h>

#define MEU_NOME "Myron\r\n"

// buffer circular de 32 chars
#define RX_BUF_SIZE     32
#define RX_MASK         (RX_BUF_SIZE - 1)

volatile char rx_buf[RX_BUF_SIZE];
volatile unsigned char head = 0;
volatile unsigned char tail = 0;

static inline int rxDisponivel(void) {
    return head != tail;
}

static char rxGet(void) {
    char c = rx_buf[tail];
    tail = (tail + 1) & RX_MASK;
    return c;
}

void clockInit(void) {
    UCSCTL3 = SELREF__REFOCLK;
    UCSCTL4 = SELA__REFOCLK | SELS__DCOCLKDIV | SELM__DCOCLKDIV;

    __bis_SR_register(SCG0);
    UCSCTL0 = 0x0000;
    UCSCTL1 = DCORSEL_2;
    UCSCTL2 = FLLD_1 | 31;
    __bic_SR_register(SCG0);

    do {
        UCSCTL7 &= ~(XT2OFFG | XT1LFOFFG | DCOFFG);
        SFRIFG1 &= ~OFIFG;
    } while (SFRIFG1 & OFIFG);
}
void uartInit(void) {
    P4SEL |= BIT4 | BIT5;               // P4.4=TX, P4.5=RX

    UCA1CTL1 |= UCSWRST;
    UCA1CTL1 |= UCSSEL__ACLK;           // usa ACLK = REFOCLK = 32768 Hz
    UCA1BR0 = 3;
    UCA1BR1 = 0;
    UCA1MCTL = UCBRS_3 | UCBRF_0;       // UCBRSx=3, sem OS16
    UCA1CTL1 &= ~UCSWRST;

    UCA1IE |= UCRXIE;
}

void uartPrint(char *str) {
    while (*str) {
        while (!(UCA1IFG & UCTXIFG));
        UCA1TXBUF = *str++;
    }
}

// =========================================================
// main
// =========================================================
int main(void) {
    WDTCTL = WDTPW | WDTHOLD;

    clockInit();
    uartInit();

    __bis_SR_register(GIE);

    uartPrint("\r\n=== MSP430 ligou ===\r\n");
    uartPrint("Meu nome eh: ");
    uartPrint(MEU_NOME);
    uartPrint("Digite algo e eu ecoo de volta:\r\n");

    while (1) {
        if (rxDisponivel()) {
            char c = rxGet();
            while (!(UCA1IFG & UCTXIFG));
            UCA1TXBUF = c;
        }
    }
}

// =========================================================
// ISR da USCI_A1 - poe os bytes recebidos no buffer circular
// =========================================================
#pragma vector = USCI_A1_VECTOR
__interrupt void USCI_A1_ISR(void) {
    switch (__even_in_range(UCA1IV, USCI_UCTXIFG)) {
        case USCI_NONE: break;

        case USCI_UCRXIFG: {
            unsigned char next = (head + 1) & RX_MASK;
            if (next != tail) {
                rx_buf[head] = UCA1RXBUF;
                head = next;
            } else {
                (void)UCA1RXBUF;        // buffer cheio, descarta
            }
            break;
        }

        case USCI_UCTXIFG: break;
        default: break;
    }
}
