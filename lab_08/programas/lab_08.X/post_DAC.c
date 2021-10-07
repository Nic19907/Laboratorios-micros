/*
 * File:   pre_potenciometro.c
 * Dispositivo:     PIC16F887
 * Compilador:  pic.as (v2.31) MPLAB (5.50)
 * 
 * Programa: Tiene una entrada analogica la cual cambia con un potenciometro
 * y el voltaje se ve reflejado en un contador de 8 bits
 * Hardware: Potenciometro, LEDs, varias resistencias
 * 
 * Creado: 06/10/2021
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

/*
--------------------------------------------------------------------------------
 *                              Variables
--------------------------------------------------------------------------------
 */
uint16_t voltaje;

uint8_t cen;    //centenas
uint8_t dec;    //decenas
uint8_t uni;    //unidades

uint8_t display2;    //valor centenas multiplexado
uint8_t display1;    //valor decenas multiplexado
uint8_t display0;    //valor unidades multiplexado

uint8_t transistor;//variable para cambiar de transistor
uint8_t pepa; //variable del switch para main

/*
--------------------------------------------------------------------------------
 *                       Prototipo de funciones
--------------------------------------------------------------------------------
 */
void setup          (void);
void config_io      (void);
void config_clock   (void);
void config_ie      (void);
void config_ADC     (void);
void config_tmr0    (void);

void setup (void){
    config_io();
    config_clock();
    config_ie();
    config_ADC ();
    config_tmr0 ();
    return;
}

//void divizion (uint8_t coso); //codigo para dividir la variable en centenas,
//decenas y unidades

void divizion_m (uint16_t kak);

uint8_t tabla_7seg (uint8_t uwu); //tabla para transofrmar un valor a un display
// de 7 segmentos

/*
--------------------------------------------------------------------------------
 *                                 Main/loop
--------------------------------------------------------------------------------
 */
void main (void){
    setup();
    
    ADCON0bits.GO   = 1;
    
    while (1){
        if (ADCON0bits.GO == 0){
            switch (pepa){
                case 0:
                    ADCON0bits.CHS = 5;
                    __delay_us(50);
                    pepa = 1;
                    break;
                case 1:
                    ADCON0bits.CHS = 6;
                    __delay_us(50);
                    pepa = 0;
                    break;
                default:
                    ADCON0bits.CHS = 5;
                    __delay_us(50);
                    pepa = 1;
                    break;
            }
                                
            ADCON0bits.GO   = 1;
            PIR1bits.ADIF = 0;
        }
        divizion_m(voltaje);        
        
        display2 = tabla_7seg (cen); //centenas multiplexadas
        display1 = tabla_7seg (dec); //decenas multiplexadas
        display0 = tabla_7seg (uni); //unidades multiplexadas
        
    }
}

/*
--------------------------------------------------------------------------------
 *                              Interrupcion
--------------------------------------------------------------------------------
 */
//el AN5 controla los leds
void __interrupt() isr (void){
    if (PIR1bits.ADIF == 1){
        if (ADCON0bits.CHS == 6){
            //voltaje = ADRESH;
            voltaje = ADRESH;
        }
        else if (ADCON0bits.CHS == 5){
            PORTA = ADRESH;
        }
        PIR1bits.ADIF = 0;
    }
    
    else if (INTCONbits.T0IF) { //la del tmr0
        INTCONbits.T0IF = 0;
        PORTD = 0b000;
        switch (transistor){
            case 0:
                transistor = 1;
                PORTC = display2;
                TMR0 = 131;
                PORTD = 0b001;
                break;
            case 1:
                transistor = 2;
                PORTC = display1;
                TMR0 = 131;
                PORTD = 0b010;
                break;
            case 2:
                transistor = 0;
                PORTC = display0;
                TMR0 = 131;
                PORTD = 0b100;
                break;
            default:
                transistor = 1;
                PORTC = display2;
                TMR0 = 131;
                PORTD = 0b001;
                break;
        }
    }
    return;
}

/*
--------------------------------------------------------------------------------
 *                              Configuracion
--------------------------------------------------------------------------------
 */

void config_io(void){
    ANSEL   = 0b01100000;  //RE0 y RE1 como analogico
    ANSELH  = 0;
    
    TRISA   = 0;    //LEDs
    TRISC   = 0;    //puerto C display
    TRISD   = 0b000;//puerto D transistores
    TRISE   = 0b11; //RE0 y RE1 como entradas
    
    PORTA   = 0;
    PORTC   = 0;
    PORTD   = 0b000;
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
    
    INTCONbits.GIE  = 1; //interrupciones globales
    INTCONbits.PEIE = 1; //interr. perifericas
    INTCONbits.T0IE = 1; //interr. tmr0 activada
    INTCONbits.T0IF = 0; //interr. del tmr0 empieza apagada
    
    
    return;
}

void config_ADC (void){
    ADCON1  = 0;
    
    ADCON0bits.ADCS = 0b01; //refresco de 2.0 us
    ADCON0bits.ADON = 1;    //habilitar el ADC
    ADCON0bits.CHS  = 5;    //empezar por el AN5
    __delay_us(50);
    return;
}

void config_tmr0(void){
    OPTION_REGbits.T0CS = 0;    // Reloj interno
    OPTION_REGbits.T0SE = 0;    // Flancos positivos
    OPTION_REGbits.PSA = 0;     // Prescaler a Timer0
    OPTION_REGbits.PS = 0b011;  // Prescaler (011 = 1:16)
    TMR0 = 131;                 // Preload para 2 ms
    return;
}
/*
--------------------------------------------------------------------------------
 *                              Division
--------------------------------------------------------------------------------
 */

void divizion_m (uint16_t kak){
    uint8_t redivisor_m;
    kak = kak*100/51;
    
    int cen = (int) kak/100;
    redivisor_m = kak%100;
    dec = redivisor_m/10;
    uni = redivisor_m%10;
    return;
}
/*
--------------------------------------------------------------------------------
 *                               Multiplex
--------------------------------------------------------------------------------
 */
uint8_t tabla_7seg (uint8_t uwu) //cambia valores binarios a numeros 0-9 para display
{
    switch(uwu)
    {
        case 0:
            return 0b00111111;
            break;
        case 1:
            return 0b00000110;
            break;
        case 2:
            return 0b01011011;
            break;
        case 3:
            return 0b01001111;
            break;
        case 4:
            return 0b01100110;
            break;
        case 5:
            return 0b01101101;
            break;
        case 6:
            return 0b01111101;
            break;
        case 7:
            return 0b00000111;
            break;
        case 8:
            return 0b01111111;
            break;
        case 9:
            return 0b01100111;
            break;
        default:
            return 0b00111111;
            break;
    }
}