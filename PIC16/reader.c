// CONFIG
#pragma config FOSC = HS        // Oscillator Selection bits (HS oscillator)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled)
#pragma config PWRTE = ON       // Power-up Timer Enable bit (PWRT enabled)
#pragma config CP = OFF         // FLASH Program Memory Code Protection bits (Code protection off)
#pragma config BOREN = ON       // Brown-out Reset Enable bit (BOR enabled)
#pragma config LVP = OFF        // Low Voltage In-Circuit Serial Programming Enable bit (RB3 is digital I/O, HV on MCLR must be used for programming)
#pragma config CPD = OFF        // Data EE Memory Code Protection (Code Protection off)
#pragma config WRT = ON         // FLASH Program Memory Write Enable (Unprotected program memory may be written to by EECON control)

// #pragma config statements should precede project file includes.

#include <xc.h>

// PE0 -> LED0
// PE1 -> LED1
// PB0 <- Clock from VIA0
// PB1 -> Data to VIA0
// PB2 -> Reset to 65C02

void main(void) {
    uint16_t a, b;
    
    // Port B Pullups by latch values
    OPTION_REG = 0x1F;
    
    TRISBbits.TRISB0 = 1; // Clock In 
    TRISBbits.TRISB1 = 0; // Data Out

    TRISBbits.TRISB2 = 0; // Reset

    TRISEbits.TRISE0 = 0; // LED0
    TRISEbits.TRISE1 = 0; // LED1

    // Select Digital I/O on all ports
    ADCON1 = 0x06;
    
    PORTE = 0x04;

    // Delay a short period while flashing the LEDs to allow voltages to settle
    for(a = 0; a < 3; a++) {
        PORTEbits.RE0 = 1;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE0 = 0;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE1 = 1;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE1 = 0;
        for(b = 0; b < 12500; b++);
    }

    // Pull 65C02 Reset (PB2) Low and change the flashing pattern
    PORTBbits.RB2 = 0;
    for(a = 0; a < 3; a++) {
        PORTEbits.RE0 = 1;
        PORTEbits.RE1 = 0;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE0 = 0;
        PORTEbits.RE1 = 1;
        for(b = 0; b < 12500; b++);
    }

  // Release 65C02 Reset (PB2) and change the flashing pattern again
    PORTBbits.RB2 = 1;
    for(a = 0; a < 3; a++) {
        PORTEbits.RE0 = 1;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE1 = 1;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE0 = 0;
        for(b = 0; b < 12500; b++);
        PORTEbits.RE1 = 0;
        for(b = 0; b < 12500; b++);
    }
   
    // Blink LEDs slower once idle
    for(;;) {
        PORTEbits.RE0 = 1;
        for(a = 0; a < 25000; a++);
        PORTEbits.RE0 = 0;
        for(a = 0; a < 50000; a++);
        PORTEbits.RE1 = 1;
        for(a = 0; a < 25000; a++);
        PORTEbits.RE1 = 0;
        for(a = 0; a < 50000; a++);
    }

    return;
}
