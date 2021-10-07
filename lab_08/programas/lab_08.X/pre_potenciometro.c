/*
 * File:   pre_potenciometro.c
 * Dispositivo:     PIC16F887
 * Compilador:  pic.as (v2.31) MPLAB (5.50)
 * 
 * Programa: Tiene una entrada analogica la cual cambia con un potenciometro
 * y el voltaje se ve reflejado en un contador de 8 bits
 * Hardware: Potenciometro, LEDs, varias resistencias
 * 
 * Creado: 04/10/2021
 * Modificado: XX/10/2021
 * 
 * Author: NicoU
 *
 * Created on 4 de octubre de 2021, 10:04 AM
 */


#include <xc.h>
#include <stdint.h>

#define _XTAL_FREQ 4000000
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

void setup          (void);
void config_io      (void);
void config_clock   (void);
void config_ie      (void);
void config_ADC     (void);

void setup (void){
    config_io();
    config_clock();
    config_ie();
    config_ADC ();
    return;
}

/*
--------------------------------------------------------------------------------
 *                              Interrupcion
--------------------------------------------------------------------------------
 */
void __interrupt() isr (void){
    if (PIR1bits.ADIF)
    {
        PORTC = ADRESH;
        PIR1bits.ADIF = 0;
    }
    
     return;
}

void main(void) 
{
    setup();
    ADCON0bits.GO   = 1;
    
    while (1)
    {
        if (ADCON0bits.GO == 0)
        {
            __delay_us(50);
            ADCON0bits.GO = 1;
        }
      //mientras el go esta en 1 significa que esta en progreso
    }
         
}

/*
--------------------------------------------------------------------------------
 *                              Configuracion
--------------------------------------------------------------------------------
 */
void config_io(void){
    ANSEL   = 0b00100000;  //RE0 como analogico
    ANSELH  = 0;
    TRISE   = 0b1;  //RE0 como entrada
    
    TRISC   = 0;    //puerto D como salida
    
    PORTC   = 0;    //donde van los LEDs
    PORTE   = 0;
    return;
}

void config_clock (void){
    OSCCONbits.IRCF = 0b110; //4MHz
    OSCCONbits.SCS  = 1;     //usar el reloj interno
    return;
}

void config_ie (void){
    PIR1bits.ADIF   = 0;
    PIE1bits.ADIE   = 1;
    
    INTCONbits.PEIE = 1;
    INTCONbits.GIE  = 1; //interrupciones globales
    
    return;
}

void config_ADC (void){
    ADCON1  = 0;
    ADCON0bits.ADCS = 0b01; //refresco de 2.0 us
    ADCON0bits.ADON = 1; //habilitar el ADC
    ADCON0bits.CHS  = 5;
    __delay_us(50);
    return;
}